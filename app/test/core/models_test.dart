import 'dart:typed_data';

import 'package:cambric_app/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AwarenessEvent round-trips through a row', () {
    final event = AwarenessEvent(
      kind: 'stairs',
      message: 'Steps ahead.',
      level: AwarenessLevel.warning,
      source: 'vision',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final restored = AwarenessEvent.fromMap(event.toMap());
    expect(restored.kind, event.kind);
    expect(restored.message, event.message);
    expect(restored.level, event.level);
    expect(restored.source, event.source);
    expect(restored.createdAt, event.createdAt);
  });

  test('unknown levels fall back to info', () {
    final restored = AwarenessEvent.fromMap(<String, Object?>{
      'kind': 'x',
      'message': 'y',
      'level': 'not-a-level',
      'source': 'system',
      'created_at': 0,
    });
    expect(restored.level, AwarenessLevel.info);
  });

  test('Phrase round-trips through a row', () {
    final phrase = Phrase(
      text: 'Please speak slowly.',
      category: 'social',
      quick: true,
      useCount: 4,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final restored = Phrase.fromMap(phrase.toMap());
    expect(restored.text, phrase.text);
    expect(restored.category, phrase.category);
    expect(restored.quick, isTrue);
    expect(restored.useCount, 4);
    expect(restored.createdAt, phrase.createdAt);
  });

  test('KnownPerson keeps the embedding bytes', () {
    final embedding = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final person = KnownPerson(
      name: 'Mariam',
      relationship: 'Sister',
      embedding: embedding,
      photoPath: 'people/1.jpg',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final restored = KnownPerson.fromMap(person.toMap());
    expect(restored.name, 'Mariam');
    expect(restored.relationship, 'Sister');
    expect(restored.embedding, embedding);
    expect(restored.photoPath, 'people/1.jpg');
  });

  test('TrackedItem handles a missing last-seen time', () {
    final item = TrackedItem(
      name: 'Keys',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final restored = TrackedItem.fromMap(item.toMap());
    expect(restored.name, 'Keys');
    expect(restored.lastSeenPlace, isNull);
    expect(restored.lastSeenAt, isNull);
  });

  test('SavedPlace round-trips coordinates', () {
    final place = SavedPlace(
      name: 'Home',
      latitude: 30.0444,
      longitude: 31.2357,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    final restored = SavedPlace.fromMap(place.toMap());
    expect(restored.name, 'Home');
    expect(restored.latitude, closeTo(30.0444, 1e-9));
    expect(restored.longitude, closeTo(31.2357, 1e-9));
  });
}
