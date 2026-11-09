import 'dart:typed_data';

/// Severity of something the app noticed.
///
/// The order matters: the awareness controller keeps the highest level seen in
/// a short window, so a staircase is not drowned out by a chair.
enum AwarenessLevel {
  /// Useful context, not a risk.
  info,

  /// Worth acting on soon.
  warning,

  /// Stop and react now.
  danger;

  /// Higher is more urgent.
  int get weight => index;
}

/// One thing the app told the user about.
class AwarenessEvent {
  /// Create an event.
  const AwarenessEvent({
    required this.kind,
    required this.message,
    required this.level,
    required this.source,
    required this.createdAt,
    this.id,
  });

  /// Database id, null before it is stored.
  final int? id;

  /// Stable machine name, e.g. `person`, `stairs`, `fire_alarm`.
  final String kind;

  /// The sentence shown and spoken.
  final String message;

  /// Severity.
  final AwarenessLevel level;

  /// Which engine produced it: vision, sound, navigation or system.
  final String source;

  /// When it happened.
  final DateTime createdAt;

  /// Row form for SQLite.
  Map<String, Object?> toMap() => <String, Object?>{
        'kind': kind,
        'message': message,
        'level': level.name,
        'source': source,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a SQLite row.
  factory AwarenessEvent.fromMap(Map<String, Object?> map) => AwarenessEvent(
        id: map['id'] as int?,
        kind: map['kind'] as String? ?? 'unknown',
        message: map['message'] as String? ?? '',
        level: AwarenessLevel.values.firstWhere(
          (AwarenessLevel value) => value.name == map['level'],
          orElse: () => AwarenessLevel.info,
        ),
        source: map['source'] as String? ?? 'system',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}

/// A phrase the user can speak with one tap.
class Phrase {
  /// Create a phrase.
  const Phrase({
    required this.text,
    this.id,
    this.category = 'general',
    this.quick = false,
    this.useCount = 0,
    required this.createdAt,
  });

  /// Database id.
  final int? id;

  /// What is spoken.
  final String text;

  /// Grouping shown in the library.
  final String category;

  /// Whether it appears on the quick grid.
  final bool quick;

  /// How often it has been used, for ordering.
  final int useCount;

  /// Creation time.
  final DateTime createdAt;

  /// Row form.
  Map<String, Object?> toMap() => <String, Object?>{
        'text': text,
        'category': category,
        'quick': quick ? 1 : 0,
        'use_count': useCount,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a row.
  factory Phrase.fromMap(Map<String, Object?> map) => Phrase(
        id: map['id'] as int?,
        text: map['text'] as String? ?? '',
        category: map['category'] as String? ?? 'general',
        quick: (map['quick'] as int? ?? 0) == 1,
        useCount: map['use_count'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}

/// A person the app can recognise.
class KnownPerson {
  /// Create a person.
  const KnownPerson({
    required this.name,
    required this.relationship,
    this.id,
    this.embedding,
    this.photoPath,
    required this.createdAt,
  });

  /// Database id.
  final int? id;

  /// Display name.
  final String name;

  /// Relationship, e.g. "Sister" or "Caregiver".
  final String relationship;

  /// Face embedding, stored locally as raw float32 bytes.
  final Uint8List? embedding;

  /// Path to the enrolment photo.
  final String? photoPath;

  /// When they were added.
  final DateTime createdAt;

  /// Row form.
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'relationship': relationship,
        'embedding': embedding,
        'photo_path': photoPath,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a row.
  factory KnownPerson.fromMap(Map<String, Object?> map) => KnownPerson(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        relationship: map['relationship'] as String? ?? '',
        embedding: map['embedding'] as Uint8List?,
        photoPath: map['photo_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}

/// An object the user wants to find again.
class TrackedItem {
  /// Create an item.
  const TrackedItem({
    required this.name,
    this.id,
    this.photoPath,
    this.lastSeenPlace,
    this.lastSeenAt,
    required this.createdAt,
  });

  /// Database id.
  final int? id;

  /// What it is.
  final String name;

  /// Enrolment photo.
  final String? photoPath;

  /// Human description of where it was last seen.
  final String? lastSeenPlace;

  /// When it was last seen.
  final DateTime? lastSeenAt;

  /// When it was added.
  final DateTime createdAt;

  /// Row form.
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'photo_path': photoPath,
        'last_seen_place': lastSeenPlace,
        'last_seen_at': lastSeenAt?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a row.
  factory TrackedItem.fromMap(Map<String, Object?> map) => TrackedItem(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        photoPath: map['photo_path'] as String?,
        lastSeenPlace: map['last_seen_place'] as String?,
        lastSeenAt: map['last_seen_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['last_seen_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}

/// A place the user navigates back to.
class SavedPlace {
  /// Create a place.
  const SavedPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.id,
    required this.createdAt,
  });

  /// Database id.
  final int? id;

  /// Label, e.g. "Home".
  final String name;

  /// Latitude in degrees.
  final double latitude;

  /// Longitude in degrees.
  final double longitude;

  /// When it was saved.
  final DateTime createdAt;

  /// Row form.
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a row.
  factory SavedPlace.fromMap(Map<String, Object?> map) => SavedPlace(
        id: map['id'] as int?,
        name: map['name'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}
