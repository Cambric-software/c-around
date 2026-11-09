import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/app_services.dart';
import '../../../core/ai/face_recognizer.dart';
import '../../../core/data/ca_database.dart';
import '../../../core/data/models.dart';
import '../../widgets/ca_widgets.dart';

/// People the app can recognise, and objects the user wants to find again.
///
/// Enrolment is a local photo: the face detector finds the largest face, the
/// embedder turns it into 512 numbers, and only those numbers and the photo
/// path are stored. There is no face template leaving the device and no
/// recognition service anywhere in the code path.
class PeopleScreen extends StatefulWidget {
  /// Create the screen.
  const PeopleScreen({super.key, required this.services});

  /// Application services.
  final AppServices services;

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<KnownPerson> _people = const <KnownPerson>[];
  List<TrackedItem> _items = const <TrackedItem>[];
  bool _loading = true;
  bool _enrolling = false;
  String? _error;
  String? _status;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final people = await _services.database.people();
      final items = await _services.database.items();
      if (!mounted) return;
      setState(() {
        _people = people;
        _items = items;
        _loading = false;
        _error = null;
      });
      await _services.awareness.refreshPeople();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _addPerson() async {
    setState(() {
      _error = null;
      _status = null;
    });

    final source = await _pickSource();
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 92,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final details = await _askPersonDetails();
    if (details == null) return;
    if (!mounted) return;

    setState(() => _enrolling = true);
    try {
      await _services.faces.load();
      if (!_services.faces.isReady) {
        throw StateError(
          _services.faces.error ?? 'The face model could not be loaded.',
        );
      }
      final boxes = await _services.faces.detect(bytes);
      if (boxes.isEmpty) {
        throw StateError(
          'No face was found in that photo. Use a clear, front-facing photo '
          'with one person.',
        );
      }
      final largest = boxes.reduce(
        (FaceBox a, FaceBox b) => a.width * a.height >= b.width * b.height ? a : b,
      );
      if (largest.width < 0.08) {
        throw StateError(
          'That face is too small to enrol. Move closer and try again.',
        );
      }
      final vector = await _services.faces.embed(bytes, largest);
      final photoPath = await _storePhoto(bytes);
      final id = await _services.database.insertPerson(
        KnownPerson(
          name: details.name,
          relationship: details.relationship,
          embedding: CaDatabase.encodeEmbedding(vector),
          photoPath: photoPath,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _status = '${details.name} added as person $id.');
      await _services.awareness.refreshPeople();
      await _load();
      await _services.announcer.speakDirect(
        '${details.name} can now be recognised. This photo and the face '
        'numbers stay on this device.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      await _services.announcer.speakDirect(error.toString());
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
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
                  'Add a photo of the person',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            CaTile(
              icon: Icons.photo_camera_rounded,
              title: 'Take a photo',
              subtitle: 'Best in even light, facing the camera.',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            CaTile(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              subtitle: 'Pick a clear photo with one face.',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<({String name, String relationship})?> _askPersonDetails() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final result = await showDialog<({String name, String relationship})>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Who is this?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Mariam',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
                hintText: 'Sister, caregiver, neighbour',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop(
                (
                  name: name,
                  relationship: relationshipController.text.trim(),
                ),
              );
            },
            child: const Text('Add person'),
          ),
        ],
      ),
    );
    nameController.dispose();
    relationshipController.dispose();
    return result;
  }

  Future<String?> _storePhoto(Uint8List bytes) async {
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory(p.join(support.path, 'people'));
      await directory.create(recursive: true);
      final file = File(
        p.join(directory.path, 'person_${DateTime.now().microsecondsSinceEpoch}.jpg'),
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      // The embedding is what recognition needs; a missing photo is not fatal.
      return null;
    }
  }

  Future<void> _deletePerson(KnownPerson person) async {
    final id = person.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Remove ${person.name}?'),
        content: const Text(
          'The face data and the photo are deleted from this device. C Around '
          'will not recognise them again.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _services.database.deletePerson(id);
    final photoPath = person.photoPath;
    if (photoPath != null) {
      try {
        await File(photoPath).delete();
      } catch (_) {
        // The file may already be gone.
      }
    }
    await _load();
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Track an item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'What is it?',
            hintText: 'Keys, wallet, medicine box',
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await _services.database.insertItem(
      TrackedItem(name: trimmed, createdAt: DateTime.now()),
    );
    await _load();
  }

  Future<void> _markItemSeen(TrackedItem item) async {
    final id = item.id;
    if (id == null) return;
    final controller = TextEditingController(text: item.lastSeenPlace ?? '');
    final place = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Where is ${item.name}?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Place',
            hintText: 'Kitchen drawer, coat pocket',
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
    final trimmed = place?.trim() ?? '';
    if (trimmed.isEmpty) return;
    await _services.database.markItemSeen(id, trimmed);
    await _load();
    await _services.announcer.speakDirect('${item.name} is in $trimmed.');
  }

  Future<void> _deleteItem(TrackedItem item) async {
    final id = item.id;
    if (id == null) return;
    await _services.database.deleteItem(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _people.length;
    return CaPage(
      services: _services,
      title: 'People',
      subtitle: 'Add the people you meet often. C Around learns their face from '
          'one photo and says their name when the camera sees them.',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
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
                if (_status != null) ...<Widget>[
                  CaBanner(
                    message: _status!,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                CaSection(
                  title: 'People you know',
                  trailing: CaPill(
                    label: count == 1 ? '1 person' : '$count people',
                    icon: Icons.people_rounded,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_people.isEmpty)
                        const CaEmptyState(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'No one enrolled yet',
                          message: 'Add a family member or caregiver. Recognition '
                              'runs on this device and the photo is never '
                              'uploaded.',
                        )
                      else
                        for (final person in _people)
                          CaTile(
                            icon: Icons.person_rounded,
                            title: person.name,
                            subtitle: person.relationship.isEmpty
                                ? 'Recognised on this device'
                                : person.relationship,
                            onTap: () => _services.announcer.speakDirect(
                              '${person.name}'
                              '${person.relationship.isEmpty ? '' : ', ${person.relationship}'}.',
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove ${person.name}',
                              onPressed: () => _deletePerson(person),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                      const SizedBox(height: 14),
                      CaActionButton(
                        icon: Icons.add_a_photo_outlined,
                        label: _enrolling ? 'Enrolling' : 'Add a person',
                        busy: _enrolling,
                        onPressed: _enrolling ? null : _addPerson,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CaSection(
                  title: 'How recognition works',
                  child: Text(
                    'C Around finds the face, turns it into a numeric '
                    'fingerprint and compares it with the people you added. It '
                    'does not guess when the match is weak, and it never sends '
                    'the photo anywhere. Recognition works best in even light '
                    'and with the face turned towards the camera.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                CaSection(
                  title: 'Things you misplace',
                  description: 'Keep a note of where you last put something, '
                      'and ask C Around to read it back.',
                  trailing: CaPill(label: '${_items.length}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_items.isEmpty)
                        const CaEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Nothing tracked',
                          message: 'Add keys, a wallet or medication, then save '
                              'where you put it.',
                        )
                      else
                        for (final item in _items)
                          CaTile(
                            icon: Icons.inventory_2_rounded,
                            title: item.name,
                            subtitle: item.lastSeenPlace == null
                                ? 'No place saved yet'
                                : 'In ${item.lastSeenPlace}',
                            onTap: () => _markItemSeen(item),
                            trailing: IconButton(
                              tooltip: 'Delete ${item.name}',
                              onPressed: () => _deleteItem(item),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                      const SizedBox(height: 14),
                      CaActionButton(
                        icon: Icons.add_rounded,
                        label: 'Track an item',
                        filled: false,
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const CaBanner(
                  icon: Icons.lock_outline_rounded,
                  message: 'Face data and item notes are stored in the local '
                      'database. Settings can erase all of it in one step.',
                ),
              ],
            ),
    );
  }
}
