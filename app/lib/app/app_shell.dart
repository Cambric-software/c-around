import 'package:flutter/material.dart';

import '../features/screens/around/around_screen.dart';
import '../features/screens/emergency/emergency_screen.dart';
import '../features/screens/navigate/navigate_screen.dart';
import '../features/screens/people/people_screen.dart';
import '../features/screens/settings/settings_screen.dart';
import '../features/screens/talk/talk_screen.dart';
import 'app_services.dart';

enum _Dest {
  around(   'Around',    Icons.visibility_outlined,   Icons.visibility_rounded),
  talk(     'Talk',      Icons.chat_bubble_outline,   Icons.chat_bubble_rounded),
  people(   'People',    Icons.people_outline,        Icons.people_rounded),
  navigate( 'Navigate',  Icons.explore_outlined,      Icons.explore_rounded),
  emergency('Emergency', Icons.emergency_outlined,    Icons.emergency_rounded),
  settings( 'Settings',  Icons.settings_outlined,     Icons.settings_rounded);

  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

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
  _Dest get _dest => _Dest.values[_index];

  Widget _screen() {
    // Some screens access platform services (camera, awareness, announcer)
    // that are only initialized after AppServices.initialize() completes.
    // Show a simple loading view if they are not ready yet.
    if (!widget.services.isFullyInitialized) {
      switch (_dest) {
        case _Dest.around:
        case _Dest.talk:
        case _Dest.people:
        case _Dest.emergency:
          return _NotReadyScreen(label: _dest.label);
        default:
          break;
      }
    }

    // Extra guard: awareness/announcer/database may not be set in test mode
    // even when isFullyInitialized is true (markReadyForTest was called).
    try {
      switch (_dest) {
        case _Dest.around:
          return AroundScreen(services: widget.services);
        case _Dest.talk:
          return TalkScreen(services: widget.services);
        case _Dest.people:
          return PeopleScreen(services: widget.services);
        case _Dest.navigate:
          return NavigateScreen(services: widget.services);
        case _Dest.emergency:
          return EmergencyScreen(services: widget.services);
        case _Dest.settings:
          return SettingsScreen(
            services:           widget.services,
            themeMode:          widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            onReplayOnboarding: widget.onReplayOnboarding,
            onLocaleChanged:    widget.onLocaleChanged,
          );
      }
    } catch (_) {
      return _NotReadyScreen(label: _dest.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _Dest.values.map((_Dest d) =>
      NavigationDestination(
        icon: Icon(d.icon),
        selectedIcon: Icon(d.selectedIcon),
        label: d.label,
      ),
    ).toList();

    return Scaffold(
      body: _screen(),
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
            Text(
              'Starting $label…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading models and services',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
