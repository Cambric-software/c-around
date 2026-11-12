import 'package:flutter/material.dart';

import '../features/screens/around/around_screen.dart';
import '../features/screens/emergency/emergency_screen.dart';
import '../features/screens/navigate/navigate_screen.dart';
import '../features/screens/people/people_screen.dart';
import '../features/screens/settings/settings_screen.dart';
import '../features/screens/talk/talk_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_services.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.services,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onReplayOnboarding,
    this.onLocaleChanged,
  });

  final AppServices services;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback onReplayOnboarding;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Widget _screen(int index) {
    switch (index) {
      case 0: return AroundScreen(services: widget.services);
      case 1: return TalkScreen(services: widget.services);
      case 2: return PeopleScreen(services: widget.services);
      case 3: return NavigateScreen(services: widget.services);
      case 4: return EmergencyScreen(services: widget.services);
      case 5: return SettingsScreen(
          services:           widget.services,
          themeMode:          widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onReplayOnboarding: widget.onReplayOnboarding,
          onLocaleChanged:    widget.onLocaleChanged,
        );
      default: return AroundScreen(services: widget.services);
    }
  }

  Widget _buildScreen() {
    // Guard: if services not fully ready, show loading for hardware screens
    if (!widget.services.isFullyInitialized) {
      if (_index < 4) return _NotReadyScreen(label: _label(_index));
    }
    try {
      return _screen(_index);
    } catch (_) {
      return _NotReadyScreen(label: _label(_index));
    }
  }

  String _label(int index) {
    final l = AppLocalizations.of(context);
    switch (index) {
      case 0: return l.navAround;
      case 1: return l.navTalk;
      case 2: return l.navPeople;
      case 3: return l.navNavigate;
      case 4: return l.navEmergency;
      case 5: return l.navSettings;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final destinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.visibility_outlined),    selectedIcon: const Icon(Icons.visibility_rounded),     label: l.navAround),
      NavigationDestination(icon: const Icon(Icons.chat_bubble_outline),     selectedIcon: const Icon(Icons.chat_bubble_rounded),    label: l.navTalk),
      NavigationDestination(icon: const Icon(Icons.people_outline),          selectedIcon: const Icon(Icons.people_rounded),         label: l.navPeople),
      NavigationDestination(icon: const Icon(Icons.explore_outlined),        selectedIcon: const Icon(Icons.explore_rounded),        label: l.navNavigate),
      NavigationDestination(icon: const Icon(Icons.emergency_outlined),      selectedIcon: const Icon(Icons.emergency_rounded),      label: l.navEmergency),
      NavigationDestination(icon: const Icon(Icons.settings_outlined),       selectedIcon: const Icon(Icons.settings_rounded),       label: l.navSettings),
    ];

    return Scaffold(
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}

class _NotReadyScreen extends StatelessWidget {
  const _NotReadyScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Starting $label…', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
