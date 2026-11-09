import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/app_services.dart';
import '../../../core/data/models.dart';
import '../../widgets/ca_widgets.dart';

/// Offline navigation help: distance and direction to places the user saved.
///
/// It deliberately does not pretend to be a map. There is no map data on the
/// device, so the screen gives a straight-line distance and a compass bearing,
/// and says so. A wrong turn-by-turn instruction would be worse than none.
class NavigateScreen extends StatefulWidget {
  /// Create the screen.
  const NavigateScreen({super.key, required this.services});

  /// Application services.
  final AppServices services;

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  Position? _position;
  List<SavedPlace> _places = const <SavedPlace>[];
  bool _locating = false;
  String? _error;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await _services.database.places();
      if (!mounted) return;
      setState(() => _places = places);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<bool> _locate({bool askPermission = true}) async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'Location is turned off in system settings.');
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && askPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(
          () => _error = 'Location permission was denied. C Around only uses '
              'your position to measure distance to places you saved.',
        );
        return false;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return true;
      setState(() {
        _position = position;
        _error = null;
      });
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() => _error = error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _savePlace() async {
    if (_position == null) {
      final ok = await _locate();
      if (!ok || _position == null) return;
    }
    if (!mounted) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Save this place'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Home, pharmacy, bus stop',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    await _services.database.insertPlace(
      SavedPlace(
        name: trimmed,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        createdAt: DateTime.now(),
      ),
    );
    await _loadPlaces();
    if (!mounted) return;
    await _services.announcer.speakDirect('$trimmed saved.');
  }

  Future<void> _deletePlace(SavedPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete ${place.name}?'),
        content: const Text('The saved position is removed from this device.'),
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
    final id = place.id;
    if (id != null) await _services.database.deletePlace(id);
    await _loadPlaces();
  }

  Future<void> _speakPlace(SavedPlace place) async {
    if (_position == null) {
      final ok = await _locate();
      if (!ok || _position == null) return;
    }
    final distance = Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      place.latitude,
      place.longitude,
    );
    final bearing = _bearing(
      _position!.latitude,
      _position!.longitude,
      place.latitude,
      place.longitude,
    );
    final sentence =
        '${place.name} is ${_formatDistance(distance)} to the ${_compass(bearing)}.';
    await _services.announcer.speakDirect(sentence);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CaPage(
      services: _services,
      title: 'Navigate',
      subtitle: 'Straight-line distance and compass direction to places you '
          'save. No map, no network, no invented turn-by-turn instructions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_error != null) ...<Widget>[
            CaBanner(
              message: _error!,
              level: AwarenessLevel.warning,
              icon: Icons.location_off_outlined,
            ),
            const SizedBox(height: 12),
          ],
          CaSection(
            title: 'Your position',
            trailing: _position == null
                ? null
                : const CaPill(
                    label: 'Found',
                    icon: Icons.gps_fixed_rounded,
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_position == null)
                  Text(
                    'C Around needs your position to measure distance. It is '
                    'used on this device only and is never uploaded.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Text(
                    'Position found. Accuracy about '
                    '${_position!.accuracy.round()} metres.',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                CaActionButton(
                  icon: Icons.my_location_rounded,
                  label: _position == null ? 'Find my position' : 'Update position',
                  busy: _locating,
                  onPressed: _locate,
                ),
                const SizedBox(height: 10),
                CaActionButton(
                  icon: Icons.bookmark_add_outlined,
                  label: 'Save this place',
                  filled: false,
                  onPressed: _savePlace,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CaSection(
            title: 'Saved places',
            trailing: CaPill(label: '${_places.length}'),
            child: _places.isEmpty
                ? const CaEmptyState(
                    icon: Icons.place_outlined,
                    title: 'No places saved',
                    message: 'Save home, a pharmacy or a bus stop while you are '
                        'there. Later, ask for the distance and direction.',
                  )
                : Column(
                    children: <Widget>[
                      for (final place in _places)
                        CaTile(
                          icon: Icons.place_rounded,
                          title: place.name,
                          subtitle: _position == null
                              ? 'Tap to hear the direction'
                              : _describePlace(place),
                          onTap: () => _speakPlace(place),
                          trailing: IconButton(
                            tooltip: 'Delete ${place.name}',
                            onPressed: () => _deletePlace(place),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          CaSection(
            title: 'How this works',
            child: Text(
              'Distance is measured in a straight line between two points. '
              'The direction is a compass bearing, not a walking route. Use a '
              'cane, a guide dog or a sighted guide as you normally would, and '
              'treat this as one more piece of information.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _describePlace(SavedPlace place) {
    final position = _position;
    if (position == null) return 'Tap to hear the direction';
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.latitude,
      place.longitude,
    );
    final bearing = _bearing(
      position.latitude,
      position.longitude,
      place.latitude,
      place.longitude,
    );
    return '${_formatDistance(distance)} to the ${_compass(bearing)}';
  }

  static String _formatDistance(double metres) {
    if (metres < 1000) {
      final rounded = (metres / 10).round() * 10;
      return '$rounded metres';
    }
    return '${(metres / 1000).toStringAsFixed(1)} kilometres';
  }

  static String _compass(double bearing) {
    const directions = <String>[
      'north',
      'north-east',
      'east',
      'south-east',
      'south',
      'south-west',
      'west',
      'north-west',
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  static double _bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final delta = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(delta) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(delta);
    final degrees = math.atan2(y, x) * 180 / math.pi;
    return (degrees + 360) % 360;
  }
}
