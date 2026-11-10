import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../core/output/speech_strings.dart';
import '../../../core/settings/settings_service.dart';
import '../../widgets/ca_widgets.dart';

/// First-run flow.
///
/// Three short pages: what the app does, which accessibility needs to turn on
/// by default, and what is already working without a download. Every choice on
/// the second page can be changed later in Settings, and the last page says so
/// instead of pretending the setup is permanent.
class CaOnboardingScreen extends StatefulWidget {
  /// Create the flow.
  const CaOnboardingScreen({
    super.key,
    required this.services,
    this.onComplete,
  });

  /// Application services.
  final AppServices services;

  /// Called when the user finishes or skips onboarding.
  final VoidCallback? onComplete;

  @override
  State<CaOnboardingScreen> createState() => _CaOnboardingScreenState();
}

class _CaOnboardingScreenState extends State<CaOnboardingScreen> {
  final PageController _pages = PageController();
  final Set<AccessibilityNeed> _needs = <AccessibilityNeed>{};
  int _index = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _needs.addAll(widget.services.settings.needs);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.services.isFullyInitialized) return;
      final s = SpeechStrings(widget.services.settings.speechLanguage);
      widget.services.announcer.speakDirect(s.welcome());
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 2) {
      await _pages.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await widget.services.settings.setNeeds(_needs);
    await widget.services.settings.setOnboardingComplete(true);
    if (!mounted) return;
    if (widget.services.isFullyInitialized) {
      final s = SpeechStrings(widget.services.settings.speechLanguage);
      await widget.services.announcer.speakDirect(s.setupDone());
    }
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: <Widget>[
                  const CaLogo(size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'C Around',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_index < 2)
                    TextButton(
                      onPressed: _saving ? null : _finish,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (int value) => setState(() => _index = value),
                children: <Widget>[
                  _WelcomePage(index: _index),
                  _NeedsPage(
                    selected: _needs,
                    onChanged: (Set<AccessibilityNeed> value) =>
                        setState(() => _needs
                          ..clear()
                          ..addAll(value)),
                  ),
                  const _ReadyPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CaActionButton(
                    icon: _index == 2
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    label: _index == 2 ? 'Start using C Around' : 'Continue',
                    busy: _saving,
                    onPressed: _next,
                  ),
                  if (_index == 1) ...<Widget>[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () {
                              setState(() => _needs.clear());
                              _next();
                            },
                      child: const Text('I would rather set this up later'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      children: <Widget>[
        const Center(child: CaLogo(size: 108)),
        const SizedBox(height: 22),
        Text(
          'The World,\nExplained.',
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 40,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'C Around describes what is ahead, reads text aloud, hears alarms, '
          'captions speech and recognises people you know.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        const _Point(
          icon: Icons.wifi_off_rounded,
          title: 'No internet needed',
          message: 'No account, no cloud, no telemetry. The camera, sound and '
              'text stay on this device.',
        ),
        const SizedBox(height: 12),
        const _Point(
          icon: Icons.sos_rounded,
          title: 'Emergency is always one tap away',
          message: 'The red SOS button opens the alarm, your medical card and '
              'your contact.',
        ),
        const SizedBox(height: 12),
        const _Point(
          icon: Icons.record_voice_over_rounded,
          title: 'Built for your needs',
          message: 'Choose what you need on the next page. Every output can be '
              'changed later.',
        ),
        if (index != 0) const SizedBox(height: 12),
      ],
    );
  }
}

class _NeedsPage extends StatelessWidget {
  const _NeedsPage({required this.selected, required this.onChanged});

  final Set<AccessibilityNeed> selected;
  final ValueChanged<Set<AccessibilityNeed>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      children: <Widget>[
        Text('What should C Around turn on?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'This is not a diagnosis. It only picks sensible defaults for speech, '
          'large text, vibration and flash. You can select more than one.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final need in AccessibilityNeed.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NeedCard(
              need: need,
              selected: selected.contains(need),
              onTap: () {
                final next = Set<AccessibilityNeed>.from(selected);
                if (!next.add(need)) next.remove(need);
                onChanged(next);
              },
            ),
          ),
        const SizedBox(height: 8),
        const CaBanner(
          icon: Icons.info_outline_rounded,
          message: 'Nothing here is permanent. Settings has the same choices and '
              'every individual switch.',
        ),
      ],
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.need,
    required this.selected,
    required this.onTap,
  });

  final AccessibilityNeed need;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (IconData icon, String message) = switch (need) {
      AccessibilityNeed.blind => (
          Icons.visibility_off_rounded,
          'Speech and haptics carry the interface, with large text.',
        ),
      AccessibilityNeed.lowVision => (
          Icons.visibility_rounded,
          'Stronger contrast, larger text and clear touch targets.',
        ),
      AccessibilityNeed.deaf => (
          Icons.hearing_disabled_rounded,
          'Vibration, screen flash and captions instead of sound.',
        ),
      AccessibilityNeed.hardOfHearing => (
          Icons.hearing_rounded,
          'Captions on by default, with louder visual alerts.',
        ),
      AccessibilityNeed.nonVerbal => (
          Icons.keyboard_voice_rounded,
          'Phrases, spoken cards and text-to-speech ready to use.',
        ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${need.label}. $message',
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        need.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      children: <Widget>[
        Text('Ready when you are', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'These work immediately, with no download:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        const _Point(
          icon: Icons.category_outlined,
          title: 'Object and obstacle awareness',
          message: 'Bundled on-device detector names people, vehicles, steps and '
              'common obstacles.',
        ),
        const SizedBox(height: 12),
        const _Point(
          icon: Icons.graphic_eq_rounded,
          title: 'Sound alerts',
          message: 'Alarms, sirens, horns, glass, shouting and a baby crying.',
        ),
        const SizedBox(height: 12),
        const _Point(
          icon: Icons.people_outline_rounded,
          title: 'Face recognition',
          message: 'Add people in the People tab; their names stay on this '
              'device.',
        ),
        const SizedBox(height: 12),
        const _Point(
          icon: Icons.text_fields_rounded,
          title: 'Phrases and cards',
          message: 'Speak or show prepared sentences in very large text.',
        ),
        const SizedBox(height: 22),
        const CaBanner(
          icon: Icons.download_rounded,
          message: 'Two optional packs can be added later in Settings: '
              'Moondream 2 scene descriptions for Windows and Linux, and '
              'offline speech captions for every platform.',
        ),
        const SizedBox(height: 14),
        Text(
          'There is no sign-in. Nothing is uploaded. Uninstalling the app '
          'removes its local data.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 2),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
