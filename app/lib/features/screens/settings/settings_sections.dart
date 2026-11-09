import 'package:flutter/material.dart';

import 'package:cambric_app/app/app_services.dart';
import 'package:cambric_app/features/widgets/ca_widgets.dart';

/// Settings sections widget that displays all settings grouped by category.
class SettingsSections extends StatelessWidget {
  const SettingsSections({
    super.key,
    required this.services,
  });

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _autoUpdateSection(),
        _appLockSection(),
        _featureFlagsSection(),
        _diagnosticsSection(),
      ],
    );
  }

  Widget _autoUpdateSection() {
    return CaSection(
      title: 'Automatic Updates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            title: const Text('Check for updates automatically'),
            subtitle: const Text('Automatically check for new versions'),
            value: services.settings.autoUpdateCheck,
            onChanged: (bool value) async {
              await services.settings.setAutoUpdateCheck(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _appLockSection() {
    return CaSection(
      title: 'App Lock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            title: const Text('Require PIN on launch'),
            subtitle: const Text('Secure your app with a 6-digit PIN'),
            value: services.settings.appLockEnabled,
            onChanged: (bool value) async {
              await services.settings.setAppLockEnabled(value);
            },
          ),
          if (services.settings.appLockEnabled)
            ListTile(
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to PIN change screen
              },
            ),
        ],
      ),
    );
  }

  Widget _featureFlagsSection() {
    return CaSection(
      title: 'Feature Flags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: services.settings.featureFlags.entries.map((MapEntry<String, bool> entry) {
          return SwitchListTile(
            title: Text(entry.key),
            value: entry.value,
            onChanged: (bool value) async {
              await services.settings.setFeatureFlag(entry.key, value);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _diagnosticsSection() {
    return CaSection(
      title: 'Diagnostics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: const Text('View diagnostic report'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to diagnostics screen
            },
          ),
          ListTile(
            title: const Text('Clear diagnostics'),
            trailing: const Icon(Icons.delete),
            onTap: () {
              services.diagnostics.reportError('Diagnostics cleared by user');
            },
          ),
        ],
      ),
    );
  }
}
