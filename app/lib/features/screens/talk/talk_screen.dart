import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../core/data/ca_database.dart';
import '../../../core/data/models.dart';
import '../../widgets/ca_widgets.dart';
import '../../widgets/model_pack_card.dart';
import 'show_card_screen.dart';

enum _TalkMode { captions, phrases }

/// Captions for deaf and hard-of-hearing users, and spoken phrases for
/// non-verbal users. Both work offline.
class TalkScreen extends StatefulWidget {
  /// Create the screen.
  const TalkScreen({super.key, required this.services});

  /// Application services.
  final AppServices services;

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  _TalkMode _mode = _TalkMode.captions;
  List<Phrase> _phrases = const <Phrase>[];
  String? _error;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
    _services.captions.loadHistory();
  }

  Future<void> _loadPhrases() async {
    try {
      final phrases = await _services.database.phrases();
      if (!mounted) return;
      setState(() {
        _phrases = phrases;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _speakPhrase(Phrase phrase) async {
    await _services.announcer.speakDirect(phrase.text);
    final id = phrase.id;
    if (id != null) {
      await _services.database.bumpPhraseUse(id);
      await _loadPhrases();
    }
  }

  void _showCard(String text) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ShowCardScreen(
          services: _services,
          text: text,
        ),
      ),
    );
  }

  Future<void> _typeMessage() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Type a message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Please give me a moment.',
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
            child: const Text('Speak'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await _services.announcer.speakDirect(trimmed);
    if (!mounted) return;
    _showCard(trimmed);
  }

  Future<void> _editPhrase([Phrase? existing]) async {
    final textController = TextEditingController(text: existing?.text ?? '');
    final categoryController =
        TextEditingController(text: existing?.category ?? 'general');
    var quick = existing?.quick ?? false;

    final saved = await showDialog<Phrase>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(existing == null ? 'Add a phrase' : 'Edit phrase'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: textController,
                  autofocus: true,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Phrase'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'general, needs, medical',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show on the quick list'),
                  value: quick,
                  onChanged: (bool value) => setState(() => quick = value),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                final category = categoryController.text.trim();
                Navigator.of(context).pop(
                  Phrase(
                    id: existing?.id,
                    text: text,
                    category: category.isEmpty ? 'general' : category,
                    quick: quick,
                    useCount: existing?.useCount ?? 0,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
    categoryController.dispose();

    if (saved == null) return;
    if (saved.id == null) {
      await _services.database.insertPhrase(saved);
    } else {
      await _services.database.updatePhrase(saved);
    }
    await _loadPhrases();
  }

  Future<void> _deletePhrase(Phrase phrase) async {
    final id = phrase.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this phrase?'),
        content: Text(phrase.text),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _services.database.deletePhrase(id);
    await _loadPhrases();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable?>[
        _services.captions,
        _services.models,
      ]),
      builder: (BuildContext context, Widget? _) {
        return CaPage(
          services: _services,
          title: 'Talk',
          subtitle: 'Live captions for what people say, and phrases you can '
              'speak or show. Both work without a network.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SegmentedButton<_TalkMode>(
                segments: const <ButtonSegment<_TalkMode>>[
                  ButtonSegment<_TalkMode>(
                    value: _TalkMode.captions,
                    icon: Icon(Icons.closed_caption_rounded),
                    label: Text('Captions'),
                  ),
                  ButtonSegment<_TalkMode>(
                    value: _TalkMode.phrases,
                    icon: Icon(Icons.record_voice_over_rounded),
                    label: Text('Phrases'),
                  ),
                ],
                selected: <_TalkMode>{_mode},
                onSelectionChanged: (Set<_TalkMode> value) =>
                    setState(() => _mode = value.first),
              ),
              const SizedBox(height: 14),
              if (_error != null) ...<Widget>[
                CaBanner(
                  message: _error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.error_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],
              if (_mode == _TalkMode.captions)
                _buildCaptions(context)
              else
                _buildPhrases(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCaptions(BuildContext context) {
    final theme = Theme.of(context);
    final captions = _services.captions;
    final installed = captions.isInstalled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CaSection(
          title: 'Live captions',
          trailing: CaPill(
            label: captions.isRunning
                ? (captions.isTranscribing ? 'Transcribing' : 'Listening')
                : 'Off',
            icon: captions.isRunning
                ? Icons.graphic_eq_rounded
                : Icons.mic_off_rounded,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Holds a few seconds of speech, transcribes it on this device '
                'and writes it here. Nothing is uploaded.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              CaActionButton(
                icon: captions.isRunning
                    ? Icons.stop_circle_outlined
                    : Icons.mic_rounded,
                label: captions.isRunning ? 'Stop captions' : 'Start captions',
                onPressed: installed ? captions.toggle : null,
              ),
              if (captions.error != null) ...<Widget>[
                const SizedBox(height: 10),
                CaBanner(
                  message: captions.error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.mic_off_outlined,
                ),
              ],
            ],
          ),
        ),
        if (!installed) ...<Widget>[
          const SizedBox(height: 14),
          ModelPackCard(services: _services, packId: 'whisper'),
        ],
        const SizedBox(height: 14),
        CaSection(
          title: 'Transcript',
          trailing: TextButton(
            onPressed: captions.lines.isEmpty
                ? null
                : () async {
                    await captions.clear();
                  },
            child: const Text('Clear'),
          ),
          child: captions.lines.isEmpty
              ? CaEmptyState(
                  icon: Icons.closed_caption_disabled_rounded,
                  title: 'No captions yet',
                  message: installed
                      ? 'Start captions and the words will appear here.'
                      : 'Install the Offline captions pack to turn speech into '
                          'text without a network.',
                )
              : Column(
                  children: <Widget>[
                    for (final CaptionLine line in captions.lines.take(40))
                      _CaptionRow(line: line),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPhrases(BuildContext context) {
    final theme = Theme.of(context);
    final quick = _phrases.where((Phrase phrase) => phrase.quick).toList();
    final rest = _phrases.where((Phrase phrase) => !phrase.quick).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CaSection(
          title: 'Quick phrases',
          description: 'Tap to speak. Use the card button to show the sentence '
              'on screen in very large text.',
          trailing: IconButton(
            tooltip: 'Add a phrase',
            onPressed: () => _editPhrase(),
            icon: const Icon(Icons.add_rounded),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (quick.isEmpty)
                const CaEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'No quick phrases',
                  message: 'Add the sentences you use most, or mark an existing '
                      'phrase as quick.',
                )
              else
                for (final phrase in quick)
                  _PhraseRow(
                    phrase: phrase,
                    onSpeak: () => _speakPhrase(phrase),
                    onShow: () => _showCard(phrase.text),
                    onEdit: () => _editPhrase(phrase),
                    onDelete: () => _deletePhrase(phrase),
                  ),
              const SizedBox(height: 8),
              CaActionButton(
                icon: Icons.keyboard_rounded,
                label: 'Type a message',
                filled: false,
                onPressed: _typeMessage,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        CaSection(
          title: 'All phrases',
          trailing: CaPill(label: '${_phrases.length}'),
          child: rest.isEmpty
              ? Text(
                  'Every phrase is on the quick list.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: <Widget>[
                    for (final phrase in rest)
                      _PhraseRow(
                        phrase: phrase,
                        onSpeak: () => _speakPhrase(phrase),
                        onShow: () => _showCard(phrase.text),
                        onEdit: () => _editPhrase(phrase),
                        onDelete: () => _deletePhrase(phrase),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        CaSection(
          title: 'Showing a card',
          child: Text(
            'The card fills the screen with black and white text. Hand the '
            'device to the person you are talking to, or hold it up. They do '
            'not need to touch anything except the close button.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptionRow extends StatelessWidget {
  const _CaptionRow({required this.line});

  final CaptionLine line;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(line.createdAt).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(
            line.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({
    required this.phrase,
    required this.onSpeak,
    required this.onShow,
    required this.onEdit,
    required this.onDelete,
  });

  final Phrase phrase;
  final VoidCallback onSpeak;
  final VoidCallback onShow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              phrase.text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  label: const Text('Speak'),
                ),
                OutlinedButton.icon(
                  onPressed: onShow,
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text('Show'),
                ),
                IconButton(
                  tooltip: 'Edit phrase',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete phrase',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
