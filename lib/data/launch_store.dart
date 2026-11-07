/// Launch history in SQLite (spec-motore-contesto §5, `launch_event`).
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/boost.dart';
import '../core/categories.dart';
import '../core/contact.dart';
import '../core/places.dart';
import '../core/predictor.dart';

class LaunchStore {
  LaunchStore._(this._db);

  final Database _db;

  /// Retention in days (spec-motore-contesto §9).
  static const retentionDays = 180;

  static Future<LaunchStore> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'libreglide.db'),
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE launch_event (
            id        INTEGER PRIMARY KEY,
            ts        INTEGER NOT NULL,
            package   TEXT NOT NULL,
            source    TEXT NOT NULL,
            sample_id INTEGER,
            f_slot    TEXT,
            f_daytype TEXT,
            f_network TEXT,
            f_place   TEXT,
            f_audio   TEXT,
            f_motion  TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX launch_event_pkg ON launch_event(package, ts)',
        );
        await db.execute('CREATE INDEX launch_event_ts ON launch_event(ts)');
        await _createBoostTable(db);
        await _createContactTable(db);
        await _createPlaceTables(db);
      },
      onUpgrade: (db, from, to) async {
        if (from < 2) {
          await db.execute(
            'ALTER TABLE launch_event ADD COLUMN f_network TEXT',
          );
        }
        if (from < 3) await _createBoostTable(db);
        if (from < 4) await _createContactTable(db);
        if (from < 5) await _createPlaceTables(db);
      },
    );
    return LaunchStore._(db);
  }

  Future<void> insert(LaunchRecord r, {String source = 'launcher'}) =>
      _db.insert('launch_event', {
        'ts': r.ts.millisecondsSinceEpoch,
        'package': r.package,
        'source': source,
        'f_slot': r.features['slot'],
        'f_daytype': r.features['daytype'],
        'f_network': r.features['network'],
        'f_place': r.features['place'],
        'f_audio': r.features['audio'],
        'f_motion': r.features['motion'],
      });

  /// Deletes data older than the retention period and returns the rest.
  Future<List<LaunchRecord>> loadAndPrune({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final cutoff = t
        .subtract(const Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    await _db.delete('launch_event', where: 'ts < ?', whereArgs: [cutoff]);
    final rows = await _db.query(
      'launch_event',
      where: "source != 'card'",
      orderBy: 'ts',
    );
    return [
      for (final r in rows)
        LaunchRecord(
          ts: DateTime.fromMillisecondsSinceEpoch(r['ts']! as int),
          package: r['package']! as String,
          features: {
            'slot': r['f_slot'] as String?,
            'daytype': r['f_daytype'] as String?,
            'network': r['f_network'] as String?,
            'place': r['f_place'] as String?,
            'audio': r['f_audio'] as String?,
            'motion': r['f_motion'] as String?,
          },
        ),
    ];
  }

  /// Location samples and engine state (key-value).
  static Future<void> _createPlaceTables(Database db) async {
    await db.execute('''
      CREATE TABLE location_sample (
        id       INTEGER PRIMARY KEY,
        ts       INTEGER NOT NULL,
        lat      REAL,
        lon      REAL,
        accuracy REAL,
        wifi     TEXT,
        charging INTEGER NOT NULL,
        place_id INTEGER
      )
    ''');
    await db.execute('CREATE INDEX location_sample_ts ON location_sample(ts)');
    await db.execute('''
      CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT NOT NULL)
    ''');
  }

  /// Retention of location samples (spec-motore-contesto §9).
  static const sampleRetentionDays = 30;

  Future<void> insertSample(LocationSample s, int? placeId) =>
      _db.insert('location_sample', {...s.toMap(), 'place_id': placeId});

  /// Samples from the last 30 days (older ones are deleted).
  Future<(List<LocationSample>, List<int?>)> loadSamples(DateTime now) async {
    final cutoff = now
        .subtract(const Duration(days: sampleRetentionDays))
        .millisecondsSinceEpoch;
    await _db.delete('location_sample', where: 'ts < ?', whereArgs: [cutoff]);
    final rows = await _db.query('location_sample', orderBy: 'ts');
    return (
      [for (final r in rows) LocationSample.fromMap(r)],
      [for (final r in rows) r['place_id'] as int?],
    );
  }

  /// Times of the launches made by libreGLIDE since [since], per package (so
  /// that those also recorded by Android usage history aren't counted
  /// twice).
  Future<Map<String, List<int>>> launcherTimes(DateTime since) async {
    final rows = await _db.query(
      'launch_event',
      columns: ['package', 'ts'],
      where: "source = 'launcher' AND ts >= ?",
      whereArgs: [since.millisecondsSinceEpoch],
    );
    final out = <String, List<int>>{};
    for (final r in rows) {
      out.putIfAbsent(r['package']! as String, () => []).add(r['ts']! as int);
    }
    return out;
  }

  /// Bulk-saved launches (import from usage history).
  Future<void> insertAll(List<LaunchRecord> records, String source) async {
    final batch = _db.batch();
    for (final r in records) {
      batch.insert('launch_event', {
        'ts': r.ts.millisecondsSinceEpoch,
        'package': r.package,
        'source': source,
        'f_slot': r.features['slot'],
        'f_daytype': r.features['daytype'],
      });
    }
    await batch.commit(noResult: true);
  }

  /// Taps on the Space cards (source `card`, package = card name), with their
  /// context.
  Future<List<LaunchRecord>> loadCardEvents() async {
    final rows = await _db.query(
      'launch_event',
      where: "source = 'card'",
      orderBy: 'ts',
    );
    return [
      for (final r in rows)
        LaunchRecord(
          ts: DateTime.fromMillisecondsSinceEpoch(r['ts']! as int),
          package: r['package']! as String,
          features: {
            'slot': r['f_slot'] as String?,
            'daytype': r['f_daytype'] as String?,
            'network': r['f_network'] as String?,
            'place': r['f_place'] as String?,
            'audio': r['f_audio'] as String?,
            'motion': r['f_motion'] as String?,
          },
        ),
    ];
  }

  Future<void> deleteSource(String source) =>
      _db.delete('launch_event', where: 'source = ?', whereArgs: [source]);

  /// Launch count per source (`launcher`, `usage`), for diagnostics.
  Future<Map<String, int>> countBySource() async {
    final rows = await _db.rawQuery(
      'SELECT source, COUNT(*) AS n FROM launch_event GROUP BY source',
    );
    return {for (final r in rows) r['source']! as String: r['n']! as int};
  }

  Future<void> deleteKv(String key) =>
      _db.delete('kv', where: 'key = ?', whereArgs: [key]);

  Future<void> clearSamples() => _db.delete('location_sample');

  Future<String?> readKv(String key) async {
    final rows = await _db.query('kv', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> writeKv(String key, String value) => _db.insert('kv', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Usage of contacts opened from the panel: a weight that decays over time.
  static Future<void> _createContactTable(Database db) => db.execute('''
    CREATE TABLE contact_usage (
      lookup_key TEXT PRIMARY KEY,
      weight     REAL NOT NULL,
      updated    INTEGER NOT NULL
    )
  ''');

  /// Records a use of contact [lookupKey].
  Future<void> recordContact(String lookupKey, DateTime now) async {
    final rows = await _db.query(
      'contact_usage',
      where: 'lookup_key = ?',
      whereArgs: [lookupKey],
    );
    var weight = 1.0;
    if (rows.isNotEmpty) {
      final r = rows.first;
      weight =
          decayedWeight(
            (r['weight']! as num).toDouble(),
            DateTime.fromMillisecondsSinceEpoch(r['updated']! as int),
            now,
          ) +
          1;
    }
    await _db.insert('contact_usage', {
      'lookup_key': lookupKey,
      'weight': weight,
      'updated': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Most used contacts, most used first, with the weight decayed to [now].
  Future<List<(String, double)>> topContacts(DateTime now, {int n = 12}) async {
    final rows = await _db.query('contact_usage');
    final scored = [
      for (final r in rows)
        (
          r['lookup_key']! as String,
          decayedWeight(
            (r['weight']! as num).toDouble(),
            DateTime.fromMillisecondsSinceEpoch(r['updated']! as int),
            now,
          ),
        ),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.where((e) => e.$2 > 0.05).take(n).toList();
  }

  /// Initial boost of the favorite collections (onboarding).
  static Future<void> _createBoostTable(Database db) => db.execute('''
    CREATE TABLE category_boost (
      category TEXT PRIMARY KEY,
      weight   REAL NOT NULL,
      created  INTEGER NOT NULL
    )
  ''');

  Future<List<CategoryBoost>> loadBoosts() async {
    final rows = await _db.query('category_boost');
    return [
      for (final r in rows)
        if (AppCategory.tryParse(r['category'] as String?) case final c?)
          CategoryBoost(
            category: c,
            weight: (r['weight']! as num).toDouble(),
            created: DateTime.fromMillisecondsSinceEpoch(r['created']! as int),
          ),
    ];
  }

  /// Replaces all boosts with those in [boosts].
  Future<void> replaceBoosts(List<CategoryBoost> boosts) =>
      _db.transaction((txn) async {
        await txn.delete('category_boost');
        for (final b in boosts) {
          await txn.insert('category_boost', {
            'category': b.category.name,
            'weight': b.weight,
            'created': b.created.millisecondsSinceEpoch,
          });
        }
      });

  Future<void> deletePackage(String package) =>
      _db.delete('launch_event', where: 'package = ?', whereArgs: [package]);

  Future<void> clear() async {
    await _db.delete('launch_event');
    await _db.delete('contact_usage');
  }
}
