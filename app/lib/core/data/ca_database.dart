import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

/// One line of offline captioning history.
class CaptionLine {
  /// Create a line.
  const CaptionLine({
    required this.text,
    required this.createdAt,
    this.id,
  });

  /// Database id.
  final int? id;

  /// Transcribed text.
  final String text;

  /// When it was said.
  final DateTime createdAt;

  /// Row form.
  Map<String, Object?> toMap() => <String, Object?>{
        'text': text,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  /// Build from a row.
  factory CaptionLine.fromMap(Map<String, Object?> map) => CaptionLine(
        id: map['id'] as int?,
        text: map['text'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['created_at'] as int?) ?? 0,
        ),
      );
}

/// The single local SQLite database.
///
/// Everything the user creates - phrases, people, items, places, history - is
/// here and nowhere else. There is no sync, no account and no upload path in
/// the codebase, which is why the privacy statement can be short.
class CaDatabase {
  /// Singleton instance for production use.
  static final CaDatabase instance = CaDatabase._internal();

  /// Private constructor for singleton.
  CaDatabase._internal();

  /// Public constructor for testing — creates an independent instance.
  CaDatabase();

  Database? _db;

  /// The open database, for tests that need to assert on rows directly.
  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('CaDatabase.open() has not completed');
    }
    return db;
  }

  /// True once [open] has finished.
  bool get isOpen => _db != null;

  /// Open the database, creating and seeding it on first run.
  Future<void> open({String? path}) async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final resolved = path ?? await _defaultPath();
    _db = await openDatabase(
      resolved,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createSchema(db);
        await _seed(db);
      },
    );
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return p.join(directory.path, 'c_around.db');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE phrases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'general',
        quick INTEGER NOT NULL DEFAULT 0,
        use_count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE people (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL DEFAULT '',
        embedding BLOB,
        photo_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        last_seen_place TEXT,
        last_seen_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        message TEXT NOT NULL,
        level TEXT NOT NULL,
        source TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE captions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX events_created_at ON events (created_at DESC)',
    );
    await db.execute(
      'CREATE INDEX captions_created_at ON captions (created_at DESC)',
    );
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const seeded = <List<Object?>>[
      <Object?>['I need help.', 'emergency', 1],
      <Object?>['I need water.', 'needs', 1],
      <Object?>['I am in pain.', 'medical', 1],
      <Object?>['Please call my family.', 'emergency', 1],
      <Object?>['Thank you.', 'social', 1],
      <Object?>['I need medical assistance.', 'medical', 1],
      <Object?>['Please speak slowly.', 'social', 0],
      <Object?>['Where is the restroom?', 'needs', 0],
      <Object?>['I cannot hear you. Please write it down.', 'deaf', 0],
      <Object?>['I am blind. Please tell me what is in front of me.', 'blind', 0],
    ];
    final batch = db.batch();
    for (final row in seeded) {
      batch.insert('phrases', <String, Object?>{
        'text': row[0],
        'category': row[1],
        'quick': row[2],
        'use_count': 0,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Close the database. Used by tests.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---------------------------------------------------------------- phrases

  /// All phrases, quick ones first, then most used.
  Future<List<Phrase>> phrases({bool quickOnly = false}) async {
    final rows = await database.query(
      'phrases',
      where: quickOnly ? 'quick = 1' : null,
      orderBy: 'quick DESC, use_count DESC, created_at ASC',
    );
    return rows.map(Phrase.fromMap).toList();
  }

  /// Insert a phrase and return its id.
  Future<int> insertPhrase(Phrase phrase) =>
      database.insert('phrases', phrase.toMap());

  /// Update a phrase.
  Future<void> updatePhrase(Phrase phrase) async {
    final id = phrase.id;
    if (id == null) return;
    await database.update(
      'phrases',
      phrase.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Delete a phrase.
  Future<void> deletePhrase(int id) =>
      database.delete('phrases', where: 'id = ?', whereArgs: <Object?>[id]);

  /// Record that a phrase was spoken.
  Future<void> bumpPhraseUse(int id) async {
    await database.rawUpdate(
      'UPDATE phrases SET use_count = use_count + 1 WHERE id = ?',
      <Object?>[id],
    );
  }

  // ----------------------------------------------------------------- people

  /// Everyone enrolled.
  Future<List<KnownPerson>> people() async {
    final rows = await database.query('people', orderBy: 'name COLLATE NOCASE');
    return rows.map(KnownPerson.fromMap).toList();
  }

  /// Add a person.
  Future<int> insertPerson(KnownPerson person) =>
      database.insert('people', person.toMap());

  /// Delete a person.
  Future<void> deletePerson(int id) =>
      database.delete('people', where: 'id = ?', whereArgs: <Object?>[id]);

  // ------------------------------------------------------------------ items

  /// Every tracked item.
  Future<List<TrackedItem>> items() async {
    final rows = await database.query(
      'items',
      orderBy: 'last_seen_at DESC, name COLLATE NOCASE',
    );
    return rows.map(TrackedItem.fromMap).toList();
  }

  /// Add an item.
  Future<int> insertItem(TrackedItem item) =>
      database.insert('items', item.toMap());

  /// Record where an item was last seen.
  Future<void> markItemSeen(int id, String place) async {
    await database.update(
      'items',
      <String, Object?>{
        'last_seen_place': place,
        'last_seen_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Delete an item.
  Future<void> deleteItem(int id) =>
      database.delete('items', where: 'id = ?', whereArgs: <Object?>[id]);

  // ----------------------------------------------------------------- places

  /// Saved destinations.
  Future<List<SavedPlace>> places() async {
    final rows = await database.query('places', orderBy: 'created_at DESC');
    return rows.map(SavedPlace.fromMap).toList();
  }

  /// Add a destination.
  Future<int> insertPlace(SavedPlace place) =>
      database.insert('places', place.toMap());

  /// Delete a destination.
  Future<void> deletePlace(int id) =>
      database.delete('places', where: 'id = ?', whereArgs: <Object?>[id]);

  // ----------------------------------------------------------------- events

  /// Recent awareness events, newest first.
  Future<List<AwarenessEvent>> events({int limit = 50}) async {
    final rows = await database.query(
      'events',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AwarenessEvent.fromMap).toList();
  }

  /// Store an event.
  Future<int> insertEvent(AwarenessEvent event) =>
      database.insert('events', event.toMap());

  /// Remove all history.
  Future<void> clearEvents() => database.delete('events');

  // --------------------------------------------------------------- captions

  /// Recent caption lines, newest first.
  Future<List<CaptionLine>> captions({int limit = 200}) async {
    final rows = await database.query(
      'captions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(CaptionLine.fromMap).toList();
  }

  /// Store a caption line.
  Future<int> insertCaption(String text) => database.insert(
        'captions',
        CaptionLine(text: text, createdAt: DateTime.now()).toMap(),
      );

  /// Clear caption history.
  Future<void> clearCaptions() => database.delete('captions');

  /// Total bytes used by the database file, or 0 when it cannot be read.
  Future<int> sizeBytes() async {
    try {
      final path = database.path;
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  /// Delete every user row. Models and the database file stay in place.
  Future<void> eraseUserData() async {
    await database.transaction((Transaction txn) async {
      await txn.delete('phrases');
      await txn.delete('people');
      await txn.delete('items');
      await txn.delete('places');
      await txn.delete('events');
      await txn.delete('captions');
    });
    await _seed(database);
  }

  /// Raw embedding bytes for a person, used by the matcher.
  static Float32List? decodeEmbedding(Uint8List? bytes) {
    if (bytes == null || bytes.lengthInBytes % 4 != 0) return null;
    final view = ByteData.sublistView(bytes);
    final count = bytes.lengthInBytes ~/ 4;
    final values = Float32List(count);
    for (var i = 0; i < count; i++) {
      values[i] = view.getFloat32(i * 4, Endian.little);
    }
    return values;
  }

  /// Encode an embedding for storage.
  static Uint8List encodeEmbedding(Float32List values) {
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setFloat32(i * 4, values[i], Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
