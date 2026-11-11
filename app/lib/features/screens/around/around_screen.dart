import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_services.dart';
import '../../../core/data/models.dart';
import '../../widgets/ca_widgets.dart';
import '../../widgets/model_pack_card.dart';

/// The main screen: describe, read, scan and listen.
class AroundScreen extends StatefulWidget {
  /// Create the screen.
  const AroundScreen({super.key, required this.services});

  /// Application services.
  final AppServices services;

  @override
  State<AroundScreen> createState() => _AroundScreenState();
}

class _AroundScreenState extends State<AroundScreen> {
  String? _lastAnswer;
  String? _lastAnswerLabel;
  String? _actionError;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    // Start awareness after the first frame so platform channels are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_services.awareness.isRunning) {
        _services.awareness.start();
      }
    });
  }

  Future<void> _describe() => _run(
        'Scene description',
        _services.awareness.describeScene,
      );

  Future<void> _read() => _run(
        'Read text',
        _services.awareness.readText,
      );

  Future<void> _run(String label, Future<String> Function() action) async {
    setState(() => _actionError = null);
    try {
      final answer = await action();
      if (!mounted) return;
      setState(() {
        _lastAnswer = answer;
        _lastAnswerLabel = label;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      setState(() => _actionError = message);
      await _services.announcer.speakDirect(message);
    }
  }

  Future<void> _pickPhoto() async {
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Use a photo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            for (final value in _PhotoAction.values)
              CaTile(
                icon: value.icon,
                title: value.title,
                subtitle: value.subtitle,
                onTap: () => Navigator.of(context).pop(value),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    switch (action) {
      case _PhotoAction.describe:
        await _run('Photo description', () => _services.awareness.describeImage(bytes));
      case _PhotoAction.read:
        await _run('Text in photo', () => _services.awareness.readImage(bytes));
      case _PhotoAction.objects:
        await _findObjects(bytes);
      case _PhotoAction.ask:
        final question = await _askQuestion();
        if (question == null || question.trim().isEmpty) return;
        await _run(
          'Answer',
          () => _services.awareness.askImage(bytes, question.trim()),
        );
    }
  }

  Future<void> _findObjects(Uint8List bytes) async {
    setState(() => _actionError = null);
    try {
      final vision = await _services.awareness.analyseImage(bytes);
      final labels = <String>{};
      for (final detection in vision.detections.take(8)) {
        labels.add(detection.label);
      }
      final answer = labels.isEmpty
          ? 'I did not recognise any objects in that photo.'
          : 'I found ${labels.join(', ')}.';
      if (!mounted) return;
      setState(() {
        _lastAnswer = answer;
        _lastAnswerLabel = 'Objects in photo';
      });
      await _services.announcer.speakDirect(answer);
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error.toString());
    }
  }

  Future<String?> _askQuestion() async {
    final controller = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ask about the photo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Question',
            hintText: 'What is on the label?',
          ),
          onSubmitted: (String value) => Navigator.of(context).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ask'),
          ),
        ],
      ),
    );
    controller.dispose();
    return question;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[
        _services.awareness,
        _services.announcer,
        _services.models,
        _services.soundMonitor,
      ]),
      builder: (BuildContext context, Widget? _) {
        final theme = Theme.of(context);
        final awareness = _services.awareness;
        final camera = _services.camera;
        final moondreamReady = _services.models.isReady('moondream');
        final desktop = Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux;

        return CaPage(
          services: _services,
          title: 'Around',
          subtitle: 'Point the camera, or use a photo, and C Around explains '
              'what is there. Everything runs on this device.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_actionError != null) ...<Widget>[
                CaBanner(
                  message: _actionError!,
                  level: AwarenessLevel.warning,
                  icon: Icons.error_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],
              if (awareness.error != null) ...<Widget>[
                CaBanner(
                  message: awareness.error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.videocam_off_outlined,
                ),
                const SizedBox(height: 12),
              ],
              if (camera.error != null && !awareness.isRunning) ...<Widget>[
                CaBanner(
                  message: camera.error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.videocam_off_outlined,
                ),
                const SizedBox(height: 12),
              ],

              CaSection(
                title: 'Camera',
                trailing: CaPill(
                  label: awareness.isRunning ? 'Scanning' : 'Off',
                  icon: awareness.isRunning
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            if (camera.isReady)
                              camera.preview()
                            else
                              ColoredBox(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.photo_camera_outlined,
                                        size: 38,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        awareness.isRunning
                                            ? 'Starting the camera'
                                            : 'Camera preview appears here',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (awareness.isBusy)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Continuous awareness',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Scans every ${(awareness.interval.inMilliseconds / 1000).toStringAsFixed(1)} seconds and '
                                'speaks people, vehicles and obstacles.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: awareness.isRunning,
                          onChanged: (bool _) => awareness.toggle(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Sound alerts',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hears alarms, sirens, horns, glass and a baby '
                                'crying.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _services.soundMonitor.isRunning,
                          onChanged: (bool _) => _services.soundMonitor.toggle(),
                        ),
                      ],
                    ),
                    if (_services.soundMonitor.error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      CaBanner(
                        message: _services.soundMonitor.error!,
                        level: AwarenessLevel.warning,
                        icon: Icons.mic_off_outlined,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              CaSection(
                title: 'Describe the scene',
                description: desktop
                    ? 'Uses Moondream 2 for detailed descriptions on desktop. '
                        'On Android, uses the bundled YOLO model.'
                    : 'Uses the bundled object detector to describe what is in '
                        'front of you. Tap the button — the app will speak the result.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final wide = constraints.maxWidth > 560;
                        final buttons = <Widget>[
                          CaActionButton(
                            icon: Icons.visibility_rounded,
                            label: 'Describe what is ahead',
                            busy: awareness.isDescribing,
                            onPressed: _describe,
                          ),
                          CaActionButton(
                            icon: Icons.text_fields_rounded,
                            label: 'Read text',
                            filled: false,
                            busy: awareness.isReading,
                            onPressed: _read,
                          ),
                        ];
                        if (wide) {
                          return Row(
                            children: <Widget>[
                              Expanded(child: buttons[0]),
                              const SizedBox(width: 12),
                              Expanded(child: buttons[1]),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            buttons[0],
                            const SizedBox(height: 10),
                            buttons[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    CaActionButton(
                      icon: Icons.image_search_rounded,
                      label: 'Use a photo instead',
                      filled: false,
                      onPressed: _pickPhoto,
                    ),
                    if (desktop && !moondreamReady) ...<Widget>[
                      const SizedBox(height: 10),
                      const CaBanner(
                        message: 'Install the Moondream 2 pack in Settings → '
                            'Model packs for richer scene descriptions on desktop.',
                      ),
                    ],
                  ],
                ),
              ),
              if (desktop && !moondreamReady) ...<Widget>[
                const SizedBox(height: 14),
                ModelPackCard(services: _services, packId: 'moondream'),
              ],

              if (_lastAnswer != null) ...<Widget>[
                const SizedBox(height: 14),
                CaSection(
                  title: _lastAnswerLabel ?? 'Last answer',
                  trailing: IconButton(
                    tooltip: 'Speak again',
                    onPressed: () => _services.announcer.speakDirect(_lastAnswer!),
                    icon: const Icon(Icons.volume_up_rounded),
                  ),
                  child: SelectableText(
                    _lastAnswer!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              if (awareness.hazards.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                CaSection(
                  title: 'In front of you',
                  trailing: CaPill(label: '${awareness.hazards.length}'),
                  child: Column(
                    children: <Widget>[
                      for (final hazard in awareness.hazards.take(6))
                        _HazardRow(
                          message: hazard.message,
                          level: hazard.level,
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              _EmergencyCard(services: _services),
              const SizedBox(height: 14),
              CaSection(
                title: 'Recent announcements',
                trailing: TextButton(
                  onPressed: _services.announcer.recent.isEmpty
                      ? null
                      : _services.announcer.clearFeed,
                  child: const Text('Clear'),
                ),
                child: _services.announcer.recent.isEmpty
                    ? const CaEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'Nothing announced yet',
                        message: 'Turn on awareness, or describe a scene, and '
                            'what C Around notices will appear here.',
                      )
                    : Column(
                        children: <Widget>[
                          for (final event in _services.announcer.recent.take(6))
                            _EventRow(event: event),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              CaSection(
                title: 'Keep it private',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'There is no account and no cloud. Camera frames, sound '
                      'and text stay on this device. Model packs are the only '
                      'downloads, and only when you ask for one.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _PhotoAction {
  describe('Describe the photo', 'One short sentence about what is there.', Icons.visibility_outlined),
  read('Read the text', 'Read the words in the photo aloud.', Icons.text_fields_rounded),
  objects('Find objects', 'Name the objects the detector recognises.', Icons.category_outlined),
  ask('Ask a question', 'Type a question about the photo.', Icons.help_outline_rounded);

  const _PhotoAction(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class _HazardRow extends StatelessWidget {
  const _HazardRow({required this.message, required this.level});

  final String message;
  final AwarenessLevel level;

  @override
  Widget build(BuildContext context) {
    final style = LevelStyle.of(context, level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Icon(style.icon, color: style.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final AwarenessEvent event;

  @override
  Widget build(BuildContext context) {
    final style = LevelStyle.of(context, event.level);
    final time = TimeOfDay.fromDateTime(event.createdAt).format(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: style.container,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(style.icon, color: style.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  event.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$time · ${event.source}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.sos_rounded, color: scheme.error, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Show your medical card, sound the alarm and call your contact.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => openEmergency(context, services),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open emergency screen'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
          ),
        ],
      ),
    );
  }
}
