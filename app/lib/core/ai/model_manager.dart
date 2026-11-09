import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// One downloadable file.
class ModelFile {
  /// Create a file entry.
  const ModelFile({
    required this.url,
    required this.fileName,
    required this.bytes,
  });

  /// Direct HTTPS URL.
  final String url;

  /// Name inside the pack directory.
  final String fileName;

  /// Expected size, used to detect a truncated download.
  final int bytes;
}

/// A set of files that make one engine work.
class ModelPack {
  /// Create a pack.
  const ModelPack({
    required this.id,
    required this.title,
    required this.description,
    required this.files,
    this.requiredFiles,
    this.requiresDesktop = false,
  });

  /// Stable id, e.g. `moondream`.
  final String id;

  /// Shown in Settings.
  final String title;

  /// What it enables, in one sentence.
  final String description;

  /// Files to download.
  final List<ModelFile> files;

  /// Files that must exist for the pack to count as installed.
  ///
  /// Defaults to every downloaded file. Packs that unpack an archive list the
  /// extracted files instead, because the archive itself is deleted.
  final List<String>? requiredFiles;

  /// True when the pack only runs on Windows and Linux.
  final bool requiresDesktop;

  /// Names that must be present on disk.
  List<String> get requiredNames =>
      requiredFiles ?? files.map((ModelFile file) => file.fileName).toList();

  /// Total download size.
  int get totalBytes =>
      files.fold<int>(0, (int sum, ModelFile file) => sum + file.bytes);
}

/// Install state of one pack.
enum ModelInstallState { missing, installing, ready, failed }

/// Live progress for one pack.
class ModelStatus {
  /// Create a status.
  ModelStatus({
    required this.state,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.error,
    this.currentFile,
  });

  /// Current state.
  ModelInstallState state;

  /// Bytes downloaded so far.
  int receivedBytes;

  /// Bytes expected.
  int totalBytes;

  /// Last error.
  String? error;

  /// File being downloaded.
  String? currentFile;

  /// 0..1 progress.
  double get progress => totalBytes <= 0 ? 0 : receivedBytes / totalBytes;
}

/// Downloads and verifies the optional on-device engines.
///
/// Bundled models (object detector, sound classifier, face detector and face
/// embedder) are never touched here. These packs are large and optional:
/// nothing is downloaded until the user presses Install, and the app remains
/// usable with the bundled engines if they decline.
class ModelManager extends ChangeNotifier {
  ModelManager({required this.root});

  /// Directory that holds every pack.
  final Directory root;

  /// Pinned llama.cpp build. Bumping this changes the URL for both desktop
  /// platforms and must be tested against the current GGUF before release.
  static const String llamaBuild = 'b12224';

  /// Server executable name for the running platform.
  static String get serverExecutable =>
      Platform.isWindows ? 'llama-server.exe' : 'llama-server';

  /// Packs offered in Settings.
  static List<ModelPack> get packs => <ModelPack>[
        ModelPack(
          id: 'moondream',
          title: 'Moondream 2 vision',
          description:
              'Describes a scene, reads a sign and answers questions about a '
              'photo. 1.8 GB. Windows and Linux only: the model needs more '
              'memory than a phone can give it while the camera is running.',
          requiresDesktop: true,
          requiredFiles: <String>[
            'text.gguf',
            'mmproj.gguf',
            serverExecutable,
          ],
          files: <ModelFile>[
            const ModelFile(
              url: 'https://huggingface.co/salivosa/moondream2-gguf/'
                  'resolve/main/moondream2-q4_k.gguf',
              fileName: 'text.gguf',
              bytes: 919494048,
            ),
            const ModelFile(
              url: 'https://huggingface.co/moondream/moondream2-gguf/'
                  'resolve/main/moondream2-mmproj-f16.gguf',
              fileName: 'mmproj.gguf',
              bytes: 909777984,
            ),
            ModelFile(
              url: Platform.isWindows
                  ? 'https://github.com/ggml-org/llama.cpp/releases/download/'
                      '$llamaBuild/llama-$llamaBuild-bin-win-cpu-x64.zip'
                  : 'https://github.com/ggml-org/llama.cpp/releases/download/'
                      '$llamaBuild/llama-$llamaBuild-bin-ubuntu-x64.tar.gz',
              fileName: Platform.isWindows ? 'server.zip' : 'server.tar.gz',
              bytes: Platform.isWindows ? 24887408 : 23109432,
            ),
          ],
        ),
        const ModelPack(
          id: 'whisper',
          title: 'Offline captions',
          description:
              'Transcribes speech without a network. 103 MB. Runs on every '
              'platform through sherpa-onnx.',
          files: <ModelFile>[
            ModelFile(
              url: 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/'
                  'resolve/main/tiny-encoder.int8.onnx',
              fileName: 'tiny-encoder.int8.onnx',
              bytes: 12937772,
            ),
            ModelFile(
              url: 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/'
                  'resolve/main/tiny-decoder.int8.onnx',
              fileName: 'tiny-decoder.int8.onnx',
              bytes: 89855401,
            ),
            ModelFile(
              url: 'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/'
                  'resolve/main/tiny-tokens.txt',
              fileName: 'tiny-tokens.txt',
              bytes: 816730,
            ),
          ],
        ),
      ];

  final Map<String, ModelStatus> _status = <String, ModelStatus>{};
  bool _initialized = false;

  /// Current status of every pack.
  Map<String, ModelStatus> get status => Map<String, ModelStatus>.unmodifiable(
        _status,
      );

  /// True when the pack's files are present.
  bool isReady(String id) => _status[id]?.state == ModelInstallState.ready;

  /// True when the pack is being installed.
  bool isInstalling(String id) =>
      _status[id]?.state == ModelInstallState.installing;

  /// Directory for one pack.
  Directory directoryFor(String id) =>
      Directory('${root.path}${Platform.pathSeparator}$id');

  /// Absolute path of a file inside a pack.
  String pathFor(String id, String fileName) =>
      '${directoryFor(id).path}${Platform.pathSeparator}$fileName';

  /// Check which packs are already on disk.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await root.create(recursive: true);

    for (final pack in packs) {
      var ready = true;
      for (final name in pack.requiredNames) {
        final target = File(pathFor(pack.id, name));
        if (!await target.exists()) {
          ready = false;
          break;
        }
        // A partial download is smaller than the published size. Allow a
        // small margin because the server does not promise byte-identical
        // content, but reject anything that is clearly truncated.
        final published = _publishedBytes(pack, name);
        if (published != null) {
          final length = await target.length();
          if (length < (published * 0.97).floor()) {
            ready = false;
            break;
          }
        }
      }
      _status[pack.id] = ModelStatus(
        state: ready ? ModelInstallState.ready : ModelInstallState.missing,
        totalBytes: pack.totalBytes,
        receivedBytes: ready ? pack.totalBytes : 0,
      );
    }
    notifyListeners();
  }

  /// Download and unpack one pack.
  Future<void> install(String id) async {
    final pack = packs.firstWhere((ModelPack pack) => pack.id == id);
    if (pack.requiresDesktop && !(Platform.isWindows || Platform.isLinux)) {
      _status[id] = ModelStatus(
        state: ModelInstallState.failed,
        totalBytes: pack.totalBytes,
        error: 'This engine is only available on Windows and Linux.',
      );
      notifyListeners();
      return;
    }
    if (isInstalling(id)) return;

    final directory = directoryFor(pack.id);
    await directory.create(recursive: true);
    final status = ModelStatus(
      state: ModelInstallState.installing,
      totalBytes: pack.totalBytes,
    );
    _status[id] = status;
    notifyListeners();

    var received = 0;
    try {
      for (final file in pack.files) {
        status.currentFile = file.fileName;
        notifyListeners();
        final target = File(pathFor(pack.id, file.fileName));
        await _download(file, target, (int chunk) {
          received += chunk;
          status.receivedBytes = received;
          notifyListeners();
        });
      }

      if (pack.id == 'moondream') {
        status.currentFile = 'unpacking';
        notifyListeners();
        await _unpackServer(pack);
      }

      // The archives are only needed for extraction.
      for (final archiveName in <String>['server.zip', 'server.tar.gz']) {
        final archive = File(pathFor(pack.id, archiveName));
        if (await archive.exists()) await archive.delete();
      }

      status
        ..state = ModelInstallState.ready
        ..receivedBytes = pack.totalBytes
        ..currentFile = null
        ..error = null;
    } catch (error) {
      status
        ..state = ModelInstallState.failed
        ..error = error.toString()
        ..currentFile = null;
    }
    notifyListeners();
  }

  /// Delete a pack.
  Future<void> remove(String id) async {
    final directory = directoryFor(id);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final pack = packs.firstWhere((ModelPack pack) => pack.id == id);
    _status[id] = ModelStatus(
      state: ModelInstallState.missing,
      totalBytes: pack.totalBytes,
    );
    notifyListeners();
  }

  /// Published size for a pack file, if it has one.
  int? _publishedBytes(ModelPack pack, String name) {
    for (final file in pack.files) {
      if (file.fileName == name) return file.bytes;
    }
    return null;
  }

  Future<void> _download(
    ModelFile file,
    File target,
    void Function(int bytes) onChunk,
  ) async {
    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final request = await client.getUrl(Uri.parse(file.url));
      request.headers.set(HttpHeaders.userAgentHeader, 'C-Around/1.0');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}',
          uri: Uri.parse(file.url),
        );
      }
      final sink = partial.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          onChunk(chunk.length);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
    } finally {
      client.close(force: true);
    }
  }

  /// Extract only the files `llama-server` needs.
  ///
  /// The release archives contain a dozen command-line tools and their
  /// libraries. Copying all of them would waste about 60 MB, so this keeps the
  /// server executable and the libraries it links against. Linux entries can be
  /// symbolic links; those are copied from their target so the pack works on
  /// filesystems that do not allow links.
  Future<void> _unpackServer(ModelPack pack) async {
    final source = File(
      pathFor(pack.id, Platform.isWindows ? 'server.zip' : 'server.tar.gz'),
    );
    if (!await source.exists()) {
      throw StateError('The server archive did not download');
    }
    final bytes = await source.readAsBytes();
    final archive = Platform.isWindows
        ? ZipDecoder().decodeBytes(bytes)
        : TarDecoder().decodeBytes(const GZipDecoder().decodeBytes(bytes));

    final directory = directoryFor(pack.id);
    final links = <String, String>{};

    for (final entry in archive) {
      if (entry.isSymbolicLink) {
        final name = _baseName(entry.name);
        if (name.isNotEmpty && _wanted(name)) {
          links[name] = _baseName(entry.symbolicLink ?? '');
        }
        continue;
      }
      if (entry.isDirectory) continue;
      final name = _baseName(entry.name);
      if (name.isEmpty || !_wanted(name)) continue;

      final target = File('${directory.path}${Platform.pathSeparator}$name');
      await target.writeAsBytes(entry.content as List<int>, flush: true);
      if (!Platform.isWindows && name == 'llama-server') {
        await Process.run('chmod', <String>['+x', target.path]);
      }
    }

    for (final link in links.entries) {
      final resolved = await _resolveLink(directory, link.value, links);
      if (resolved == null) continue;
      await resolved.copy(
        '${directory.path}${Platform.pathSeparator}${link.key}',
      );
    }
  }

  /// Which archive entries the server needs.
  bool _wanted(String name) {
    if (Platform.isWindows) {
      return name == 'llama-server.exe' || name.endsWith('.dll');
    }
    return name == 'llama-server' ||
        name.startsWith('libggml') ||
        name.startsWith('libllama') ||
        name.startsWith('libmtmd');
  }

  static String _baseName(String path) =>
      path.replaceAll('\\', '/').split('/').last;

  /// Follow a chain of links to a real file that has already been written.
  Future<File?> _resolveLink(
    Directory directory,
    String start,
    Map<String, String> links,
  ) async {
    var current = start;
    for (var depth = 0; depth < 6; depth++) {
      if (current.isEmpty) return null;
      final file = File('${directory.path}${Platform.pathSeparator}$current');
      if (await file.exists()) return file;
      final next = links[current];
      if (next == null) return null;
      current = next;
    }
    return null;
  }
}
