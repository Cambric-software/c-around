import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'model_manager.dart';

/// Raised when the local vision server cannot answer.
class MoondreamException implements Exception {
  /// Create an exception.
  const MoondreamException(this.message);

  /// What went wrong, in a sentence the UI can show.
  final String message;

  @override
  String toString() => message;
}

/// Runs Moondream 2 through a local `llama-server` process.
///
/// The model is the official Q4_K build with a separate F16 vision projector.
/// It is started on demand, answers over `127.0.0.1`, and is stopped when the
/// app closes. No request leaves the machine: the server binds to loopback and
/// the client never calls anything else.
class MoondreamClient {
  MoondreamClient(this._models);

  final ModelManager _models;

  Process? _process;
  bool _starting = false;
  String? _lastError;
  final List<String> _log = <String>[];

  /// Loopback port. Fixed so a second window can reuse a running server.
  static const int port = 18420;

  /// Chat template Moondream 2 was trained with.
  ///
  /// llama.cpp's built-in templates put the image after the question, but
  /// Moondream expects the image first, then `Question: ... Answer:`. This
  /// template reads the media marker llama.cpp inserts for the image and
  /// places it before the question. It is written beside the model so the
  /// server can load it with `--chat-template-file`.
  static const String chatTemplate = '''
{% for message in messages %}{% if message['role'] == 'user' %}{% for part in message['content'] %}{% if part['type'] == 'media_marker' %}{{ part['text'] }}{% endif %}{% endfor %}

Question: {% for part in message['content'] %}{% if part['type'] == 'text' %}{{ part['text'] }}{% endif %}{% endfor %}

Answer:{% endif %}{% endfor %}
''';

  /// File name of the template inside the pack directory.
  static const String templateFileName = 'moondream.jinja';

  /// True when the server answered a health check.
  bool get isRunning => _process != null;

  /// Last start-up error, shown in Settings.
  String? get lastError => _lastError;

  /// Tail of the server log, for diagnostics.
  List<String> get log => List<String>.unmodifiable(_log);

  /// Start the server if it is not already answering.
  Future<bool> start() async {
    // Moondream requires running llama-server — desktop only.
    if (Platform.isAndroid || Platform.isIOS) {
      _lastError = 'Scene description requires the desktop version of C Around.';
      return false;
    }
    if (await _healthy()) {
      return true;
    }
    if (_starting) return false;
    if (!_models.isReady('moondream')) {
      _lastError = 'Install the Moondream vision pack first.';
      return false;
    }

    _starting = true;
    try {
      final directory = _models.directoryFor('moondream');
      final exe = File(
        '${directory.path}${Platform.pathSeparator}${ModelManager.serverExecutable}',
      );
      if (!await exe.exists()) {
        throw const MoondreamException('The vision server is missing.');
      }

      final template = File(
        '${directory.path}${Platform.pathSeparator}$templateFileName',
      );
      if (!await template.exists()) {
        await template.writeAsString(chatTemplate, flush: true);
      }

      final threads = (Platform.numberOfProcessors - 1).clamp(2, 8);
      final process = await Process.start(
        exe.path,
        <String>[
          '-m',
          _models.pathFor('moondream', 'text.gguf'),
          '--mmproj',
          _models.pathFor('moondream', 'mmproj.gguf'),
          '--chat-template-file',
          template.path,
          '-c',
          '2048',
          '-np',
          '1',
          '-t',
          '$threads',
          '--host',
          '127.0.0.1',
          '--port',
          '$port',
          '--no-webui',
        ],
        workingDirectory: directory.path,
        environment: <String, String>{
          // Without this the server cannot match the template's media marker
          // to the image part and rejects the request.
          'LLAMA_MEDIA_MARKER': '<__media__>',
        },
        runInShell: false,
      );
      _process = process;
      process.stdout
          .transform(utf8.decoder)
          .listen((String line) => _remember(line));
      process.stderr
          .transform(utf8.decoder)
          .listen((String line) => _remember(line));
      process.exitCode.then((int code) {
        _process = null;
        _remember('llama-server exited with $code');
      });

      // Loading 1.8 GB from disk takes a while on a hard drive; 90 seconds is
      // generous enough to avoid a false failure, short enough to report one.
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (DateTime.now().isBefore(deadline)) {
        if (await _healthy()) {
          _lastError = null;
          return true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      _lastError = 'The vision server did not become ready in 90 seconds.';
      await stop();
      return false;
    } catch (error) {
      _lastError = error.toString();
      await stop();
      return false;
    } finally {
      _starting = false;
    }
  }

  /// Describe the scene in one short sentence.
  Future<String> describe(Uint8List jpeg) => ask(
        jpeg,
        'Describe what is directly ahead for a blind person. Name only the '
        'important objects, people and obstacles, and say where they are. '
        'Use one short sentence. Do not guess.',
        maxTokens: 96,
      );

  /// Read the words visible in the image.
  Future<String> readText(Uint8List jpeg) => ask(
        jpeg,
        'What words are visible in this image? Return only the words.',
        maxTokens: 64,
      );

  /// Ask a free-form question about an image.
  Future<String> ask(
    Uint8List jpeg,
    String question, {
    int maxTokens = 160,
  }) async {
    final ready = await start();
    if (!ready) {
      throw MoondreamException(
        _lastError ?? 'The vision server is not available.',
      );
    }

    final body = jsonEncode(<String, Object?>{
      'messages': <Object?>[
        <String, Object?>{
          'role': 'user',
          'content': <Object?>[
            // The image must come first: Moondream was trained with the image
            // before the question, and the chat template relies on it.
            <String, Object?>{
              'type': 'image_url',
              'image_url': <String, String>{
                'url': 'data:image/jpeg;base64,${base64Encode(jpeg)}',
              },
            },
            <String, Object?>{'type': 'text', 'text': question},
          ],
        },
      ],
      'max_tokens': maxTokens,
      'temperature': 0.2,
    });

    final response = await http
        .post(
          Uri.parse('http://127.0.0.1:$port/v1/chat/completions'),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw MoondreamException(
        'The vision server returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MoondreamException('The vision server sent an invalid reply.');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const MoondreamException('The vision server returned no answer.');
    }
    final first = choices.first;
    final message = first is Map ? first['message'] : null;
    final content = message is Map ? message['content'] : null;
    final text = content?.toString().trim() ?? '';
    if (text.isEmpty) {
      throw const MoondreamException(
        'The vision server returned an empty answer.',
      );
    }
    return text;
  }

  /// Stop the server.
  Future<void> stop() async {
    final process = _process;
    _process = null;
    if (process == null) return;
    try {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () => -1,
      );
    } catch (_) {
      // The process is already gone.
    }
  }

  Future<bool> _healthy() async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:$port/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _remember(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    _log.add(trimmed);
    if (_log.length > 120) _log.removeAt(0);
    debugPrint('[moondream] $trimmed');
  }
}
