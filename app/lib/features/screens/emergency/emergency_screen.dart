import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_services.dart';
import '../../../core/data/models.dart';
import '../../widgets/ca_widgets.dart';
import '../talk/show_card_screen.dart';

/// The emergency screen: alarm, medical card, contact and location.
///
/// It is reachable from the SOS button on every screen. Nothing on this page
/// needs a network, and the medical card is stored in local preferences only.
class EmergencyScreen extends StatefulWidget {
  /// Create the screen.
  const EmergencyScreen({super.key, required this.services});

  /// Application services.
  final AppServices services;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _alarm = false;
  String? _error;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _services.announcer.speakDirect(
        'Emergency screen. The alarm, your medical card and your contact are '
        'here.',
      );
    });
  }

  @override
  void dispose() {
    if (_alarm) {
      _services.alerts.stopEmergency();
    }
    super.dispose();
  }

  Future<void> _toggleAlarm() async {
    if (_alarm) {
      await _services.alerts.stopEmergency();
      if (mounted) setState(() => _alarm = false);
      return;
    }
    await _services.alerts.startEmergency();
    if (!mounted) return;
    setState(() => _alarm = true);
    await _services.announcer.speakDirect(
      'Alarm on. It will keep sounding until you stop it.',
      interrupt: true,
    );
  }

  String _helpCardText() {
    final settings = _services.settings;
    final buffer = StringBuffer('I need help.');
    if (settings.medicalName.isNotEmpty) {
      buffer.write('\nMy name is ${settings.medicalName}.');
    }
    if (settings.medicalConditions.isNotEmpty) {
      buffer.write('\nConditions: ${settings.medicalConditions}.');
    }
    if (settings.medicalAllergies.isNotEmpty) {
      buffer.write('\nAllergies: ${settings.medicalAllergies}.');
    }
    if (settings.medicalMedications.isNotEmpty) {
      buffer.write('\nMedication: ${settings.medicalMedications}.');
    }
    if (settings.medicalBloodType.isNotEmpty) {
      buffer.write('\nBlood type: ${settings.medicalBloodType}.');
    }
    if (settings.contactName.isNotEmpty || settings.contactPhone.isNotEmpty) {
      buffer.write(
        '\nPlease call ${settings.contactName.isEmpty ? 'my contact' : settings.contactName}'
        '${settings.contactPhone.isEmpty ? '' : ' on ${settings.contactPhone}'}.',
      );
    }
    return buffer.toString();
  }

  void _showHelpCard() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => ShowCardScreen(
          services: _services,
          text: _helpCardText(),
        ),
      ),
    );
  }

  Future<void> _callContact() async {
    final phone = _services.settings.contactPhone;
    if (phone.isEmpty) {
      setState(() => _error = 'Add an emergency contact phone number first.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    final opened = await launchUrl(uri);
    if (!opened) {
      setState(() => _error = 'This device cannot start a phone call.');
    }
  }

  Future<void> _messageContact() async {
    final phone = _services.settings.contactPhone;
    if (phone.isEmpty) {
      setState(() => _error = 'Add an emergency contact phone number first.');
      return;
    }
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{'body': _helpCardText()},
    );
    final opened = await launchUrl(uri);
    if (!opened) {
      setState(() => _error = 'This device cannot open the messaging app.');
    }
  }

  Future<void> _shareLocation() async {
    setState(() => _error = null);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'Location is turned off in system settings.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission was denied.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final text = 'I am here: ${position.latitude.toStringAsFixed(5)}, '
          '${position.longitude.toStringAsFixed(5)} '
          '(accuracy about ${position.accuracy.round()} metres).';
      await Clipboard.setData(ClipboardData(text: text));
      await _services.announcer.speakDirect('$text Copied to the clipboard.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location copied to the clipboard')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _editMedicalCard() async {
    final settings = _services.settings;
    final name = TextEditingController(text: settings.medicalName);
    final conditions = TextEditingController(text: settings.medicalConditions);
    final allergies = TextEditingController(text: settings.medicalAllergies);
    final medications = TextEditingController(text: settings.medicalMedications);
    final blood = TextEditingController(text: settings.medicalBloodType);

    final saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Medical card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: conditions,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Conditions',
                  hintText: 'Asthma, epilepsy',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: allergies,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: medications,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Medication'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: blood,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Blood type'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await settings.setMedicalCard(
        name: name.text,
        conditions: conditions.text,
        allergies: allergies.text,
        medications: medications.text,
        bloodType: blood.text,
      );
      if (mounted) setState(() {});
    }
    name.dispose();
    conditions.dispose();
    allergies.dispose();
    medications.dispose();
    blood.dispose();
  }

  Future<void> _editContact() async {
    final settings = _services.settings;
    final name = TextEditingController(text: settings.contactName);
    final phone = TextEditingController(text: settings.contactPhone);

    final saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Emergency contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+20 100 000 0000',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await settings.setEmergencyContact(
        name: name.text,
        phone: phone.text,
      );
      if (mounted) setState(() {});
    }
    name.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _services.settings,
      builder: (BuildContext context, Widget? _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final settings = _services.settings;

        return CaPage(
          services: _services,
          title: 'Emergency',
          subtitle: 'Alarm, medical card and your contact. Works without a '
              'network.',
          showSosAction: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_error != null) ...<Widget>[
                CaBanner(
                  message: _error!,
                  level: AwarenessLevel.warning,
                  icon: Icons.error_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.error, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.sos_rounded, color: scheme.error, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _alarm ? 'Alarm is sounding' : 'Sound the alarm',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A loud tone, a repeating vibration and a screen flash. '
                      'Stop it with the same button.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _toggleAlarm,
                      icon: Icon(
                        _alarm
                            ? Icons.stop_circle_outlined
                            : Icons.campaign_rounded,
                      ),
                      label: Text(_alarm ? 'Stop the alarm' : 'Start the alarm'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _showHelpCard,
                      icon: const Icon(Icons.fullscreen_rounded),
                      label: const Text('Show "I need help" card'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CaSection(
                title: 'Medical card',
                trailing: TextButton(
                  onPressed: _editMedicalCard,
                  child: const Text('Edit'),
                ),
                child: settings.hasMedicalCard
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (settings.medicalName.isNotEmpty)
                            _InfoRow(
                              label: 'Name',
                              value: settings.medicalName,
                            ),
                          if (settings.medicalConditions.isNotEmpty)
                            _InfoRow(
                              label: 'Conditions',
                              value: settings.medicalConditions,
                            ),
                          if (settings.medicalAllergies.isNotEmpty)
                            _InfoRow(
                              label: 'Allergies',
                              value: settings.medicalAllergies,
                            ),
                          if (settings.medicalMedications.isNotEmpty)
                            _InfoRow(
                              label: 'Medication',
                              value: settings.medicalMedications,
                            ),
                          if (settings.medicalBloodType.isNotEmpty)
                            _InfoRow(
                              label: 'Blood type',
                              value: settings.medicalBloodType,
                            ),
                        ],
                      )
                    : const CaEmptyState(
                        icon: Icons.medical_information_outlined,
                        title: 'No medical card yet',
                        message: 'Add your name, conditions, allergies and blood '
                            'type so a responder can read them on this screen.',
                      ),
              ),
              const SizedBox(height: 14),
              CaSection(
                title: 'Emergency contact',
                trailing: TextButton(
                  onPressed: _editContact,
                  child: const Text('Edit'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (settings.contactName.isNotEmpty ||
                        settings.contactPhone.isNotEmpty) ...<Widget>[
                      Text(
                        '${settings.contactName}'
                        '${settings.contactPhone.isEmpty ? '' : ' · ${settings.contactPhone}'}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ] else
                      const CaEmptyState(
                        icon: Icons.contact_phone_outlined,
                        title: 'No contact saved',
                        message: 'Add someone to call or text in an emergency.',
                      ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CaActionButton(
                            icon: Icons.call_rounded,
                            label: 'Call',
                            onPressed: _callContact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CaActionButton(
                            icon: Icons.sms_outlined,
                            label: 'Text',
                            filled: false,
                            onPressed: _messageContact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CaActionButton(
                      icon: Icons.share_location_rounded,
                      label: 'Copy my location',
                      filled: false,
                      onPressed: _shareLocation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CaSection(
                title: 'What this does not do',
                child: Text(
                  'C Around does not call emergency services itself. It does '
                  'not send your location anywhere. In a real emergency, call '
                  'your local emergency number.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
