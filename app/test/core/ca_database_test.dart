import 'dart:io';
import 'dart:typed_data';

import 'package:cambric_app/core/data/ca_database.dart';
import 'package:cambric_app/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CaDatabase database;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('c_around_db_test');
    database = CaDatabase();
    await database.open(path: p.join(temp.path, 'test.db'));
  });

  tearDown(() async {
    await database.close();
    try {
      await temp.delete(recursive: true);
    } catch (_) {
      // Windows can keep the file handle briefly; the temp folder is disposable.
    }
  });

  test('first run seeds phrases, quick ones first', () async {
    final phrases = await database.phrases();
    expect(phrases, hasLength(10));
    expect(phrases.first.quick, isTrue);
    expect(
      phrases.map((Phrase phrase) => phrase.text),
      contains('I need help.'),
    );
    expect(
      (await database.phrases(quickOnly: true)).every((Phrase p) => p.quick),
      isTrue,
    );
  });

  test('phrases can be added, edited, used and deleted', () async {
    final id = await database.insertPhrase(
      Phrase(
        text: 'Please write it down.',
        category: 'deaf',
        quick: true,
        createdAt: DateTime.now(),
      ),
    );
    var phrases = await database.phrases();
    final added = phrases.firstWhere((Phrase phrase) => phrase.id == id);
    expect(added.text, 'Please write it down.');
    expect(added.quick, isTrue);

    await database.bumpPhraseUse(id);
    phrases = await database.phrases();
    expect(
      phrases.firstWhere((Phrase phrase) => phrase.id == id).useCount,
      1,
    );

    await database.updatePhrase(
      Phrase(
        id: id,
        text: 'Please type it.',
        category: 'deaf',
        quick: false,
        useCount: 1,
        createdAt: DateTime.now(),
      ),
    );
    phrases = await database.phrases();
    final edited = phrases.firstWhere((Phrase phrase) => phrase.id == id);
    expect(edited.text, 'Please type it.');
    expect(edited.quick, isFalse);

    await database.deletePhrase(id);
    expect(
      (await database.phrases()).any((Phrase phrase) => phrase.id == id),
      isFalse,
    );
  });

  test('people store an embedding that decodes back', () async {
    final vector = Float32List.fromList(<double>[0.1, 0.2, 0.3]);
    final id = await database.insertPerson(
      KnownPerson(
        name: 'Mariam',
        relationship: 'Sister',
        embedding: CaDatabase.encodeEmbedding(vector),
        createdAt: DateTime.now(),
      ),
    );
    final people = await database.people();
    final person = people.firstWhere((KnownPerson value) => value.id == id);
    expect(person.name, 'Mariam');
    final decoded = CaDatabase.decodeEmbedding(person.embedding);
    expect(decoded, isNotNull);
    expect(decoded![0], closeTo(0.1, 1e-6));
    expect(decoded[2], closeTo(0.3, 1e-6));

    await database.deletePerson(id);
    expect(await database.people(), isEmpty);
  });

  test('tracked items keep the last place they were seen', () async {
    final id = await database.insertItem(
      TrackedItem(name: 'Keys', createdAt: DateTime.now()),
    );
    var items = await database.items();
    expect(items.single.lastSeenPlace, isNull);

    await database.markItemSeen(id, 'Kitchen drawer');
    items = await database.items();
    expect(items.single.lastSeenPlace, 'Kitchen drawer');
    expect(items.single.lastSeenAt, isNotNull);

    await database.deleteItem(id);
    expect(await database.items(), isEmpty);
  });

  test('places round-trip coordinates', () async {
    final id = await database.insertPlace(
      SavedPlace(
        name: 'Pharmacy',
        latitude: 30.1,
        longitude: 31.2,
        createdAt: DateTime.now(),
      ),
    );
    final places = await database.places();
    final place = places.firstWhere((SavedPlace value) => value.id == id);
    expect(place.name, 'Pharmacy');
    expect(place.latitude, closeTo(30.1, 1e-9));

    await database.deletePlace(id);
    expect(await database.places(), isEmpty);
  });

  test('events and captions are newest first', () async {
    await database.insertEvent(
      AwarenessEvent(
        kind: 'car',
        message: 'Car ahead.',
        level: AwarenessLevel.warning,
        source: 'vision',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      ),
    );
    await database.insertEvent(
      AwarenessEvent(
        kind: 'siren',
        message: 'Siren nearby.',
        level: AwarenessLevel.danger,
        source: 'sound',
        createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
      ),
    );
    final events = await database.events();
    expect(events.first.kind, 'siren');
    expect(events.first.level, AwarenessLevel.danger);

    await database.insertCaption('First line');
    await database.insertCaption('Second line');
    final captions = await database.captions();
    expect(captions.first.text, 'Second line');

    await database.clearCaptions();
    expect(await database.captions(), isEmpty);
    await database.clearEvents();
    expect(await database.events(), isEmpty);
  });

  test('eraseUserData clears rows and restores the seed phrases', () async {
    await database.insertPerson(
      KnownPerson(name: 'Omar', relationship: '', createdAt: DateTime.now()),
    );
    await database.insertItem(
      TrackedItem(name: 'Wallet', createdAt: DateTime.now()),
    );
    await database.insertCaption('secret');
    await database.eraseUserData();

    expect(await database.people(), isEmpty);
    expect(await database.items(), isEmpty);
    expect(await database.captions(), isEmpty);
    expect(await database.phrases(), hasLength(10));
  });

  test('sizeBytes reports a real file size', () async {
    final bytes = await database.sizeBytes();
    expect(bytes, greaterThan(0));
  });
}
