import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scheduled_sms.dart';
import '../models/sms_status.dart';

/// Database handler for scheduled SMS messages
class SmsDatabase {
  static final SmsDatabase _instance = SmsDatabase._internal();
  static Database? _database;
  static final _InMemorySmsStore _webStore = _InMemorySmsStore();

  factory SmsDatabase() => _instance;

  SmsDatabase._internal();

  /// Get the database instance
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'The sqflite database is not available on web. Use SchedulerSmsWeb '
        'for web-compatible scheduling.',
      );
    }

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'schedulersms.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scheduled_sms (
        id TEXT PRIMARY KEY,
        customerId TEXT,
        customerName TEXT,
        recipient TEXT NOT NULL,
        message TEXT NOT NULL,
        scheduledDate TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        sentAt TEXT,
        errorMessage TEXT,
        retryCount INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        priority INTEGER NOT NULL DEFAULT 3,
        senderName TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_scheduled_date ON scheduled_sms(scheduledDate)
    ''');

    await db.execute('''
      CREATE INDEX idx_status ON scheduled_sms(status)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN customerId TEXT",
      );
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN customerName TEXT",
      );
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN retryCount INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN tags TEXT",
      );
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN priority INTEGER NOT NULL DEFAULT 3",
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE scheduled_sms ADD COLUMN senderName TEXT",
      );
    }
  }

  /// Insert a new scheduled SMS
  Future<int> insertScheduledSms(ScheduledSMS sms) async {
    if (kIsWeb) {
      _webStore.insertOrReplace(sms);
      return 1;
    }

    final db = await database;
    return await db.insert(
      'scheduled_sms',
      sms.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing scheduled SMS
  Future<int> updateScheduledSms(ScheduledSMS sms) async {
    if (kIsWeb) {
      return _webStore.updateScheduledSms(sms);
    }

    final db = await database;
    return await db.update(
      'scheduled_sms',
      sms.toMap(),
      where: 'id = ?',
      whereArgs: [sms.id],
    );
  }

  /// Delete a scheduled SMS
  Future<int> deleteScheduledSms(String id) async {
    if (kIsWeb) {
      return _webStore.deleteScheduledSms(id);
    }

    final db = await database;
    return await db.delete(
      'scheduled_sms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get a scheduled SMS by ID
  Future<ScheduledSMS?> getScheduledSms(String id) async {
    if (kIsWeb) {
      return _webStore.getScheduledSms(id);
    }

    final db = await database;
    final maps = await db.query(
      'scheduled_sms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ScheduledSMS.fromMap(maps.first);
  }

  /// Get all scheduled SMS messages
  Future<List<ScheduledSMS>> getAllScheduledSms() async {
    if (kIsWeb) {
      return _webStore.getAllScheduledSms();
    }

    final db = await database;
    final maps = await db.query(
      'scheduled_sms',
      orderBy: 'scheduledDate ASC',
    );

    return maps.map((map) => ScheduledSMS.fromMap(map)).toList();
  }

  /// Get active scheduled SMS messages
  Future<List<ScheduledSMS>> getActiveScheduledSms() async {
    if (kIsWeb) {
      return _webStore.getActiveScheduledSms();
    }

    final db = await database;
    final maps = await db.query(
      'scheduled_sms',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'scheduledDate ASC',
    );

    return maps.map((map) => ScheduledSMS.fromMap(map)).toList();
  }

  /// Get pending SMS messages that are due to be sent
  Future<List<ScheduledSMS>> getPendingSms() async {
    if (kIsWeb) {
      return _webStore.getPendingSms();
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'scheduled_sms',
      where: 'active = ? AND status = ? AND scheduledDate <= ?',
      whereArgs: [1, 'pending', now],
      orderBy: 'scheduledDate ASC',
    );

    return maps.map((map) => ScheduledSMS.fromMap(map)).toList();
  }

  /// Get SMS messages by status
  Future<List<ScheduledSMS>> getSmsByStatus(SmsStatus status) async {
    if (kIsWeb) {
      return _webStore.getSmsByStatus(status);
    }

    final db = await database;
    final maps = await db.query(
      'scheduled_sms',
      where: 'status = ?',
      whereArgs: [status.toString().split('.').last],
      orderBy: 'scheduledDate DESC',
    );

    return maps.map((map) => ScheduledSMS.fromMap(map)).toList();
  }

  /// Update SMS status
  Future<int> updateSmsStatus(
    String id,
    SmsStatus status, {
    String? errorMessage,
    DateTime? sentAt,
  }) async {
    if (kIsWeb) {
      return _webStore.updateSmsStatus(
        id,
        status,
        errorMessage: errorMessage,
        sentAt: sentAt,
      );
    }

    final db = await database;
    final updateData = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (errorMessage != null) {
      updateData['errorMessage'] = errorMessage;
    }

    if (sentAt != null) {
      updateData['sentAt'] = sentAt.toIso8601String();
    }

    return await db.update(
      'scheduled_sms',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Toggle active status of a scheduled SMS
  Future<int> toggleActive(String id, bool active) async {
    if (kIsWeb) {
      final sms = await getScheduledSms(id);
      if (sms == null) {
        return 0;
      }
      final updated = sms.copyWith(
        active: active,
        updatedAt: DateTime.now(),
      );
      return updateScheduledSms(updated);
    }

    final db = await database;
    return await db.update(
      'scheduled_sms',
      {
        'active': active ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all scheduled SMS messages
  Future<int> deleteAll() async {
    if (kIsWeb) {
      return _webStore.clear();
    }

    final db = await database;
    return await db.delete('scheduled_sms');
  }

  /// Close the database
  Future<void> close() async {
    if (kIsWeb) {
      _webStore.clear();
      return;
    }

    final db = await database;
    await db.close();
  }
}

class _InMemorySmsStore {
  final Map<String, ScheduledSMS> _items = {};

  void insertOrReplace(ScheduledSMS sms) {
    _items[sms.id] = sms;
  }

  int updateScheduledSms(ScheduledSMS sms) {
    if (!_items.containsKey(sms.id)) {
      return 0;
    }
    _items[sms.id] = sms;
    return 1;
  }

  int deleteScheduledSms(String id) {
    return _items.remove(id) == null ? 0 : 1;
  }

  ScheduledSMS? getScheduledSms(String id) {
    return _items[id];
  }

  List<ScheduledSMS> getAllScheduledSms() {
    final sorted = _items.values.toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return List.unmodifiable(sorted);
  }

  List<ScheduledSMS> getActiveScheduledSms() {
    final filtered = _items.values
        .where((sms) => sms.active)
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return List.unmodifiable(filtered);
  }

  List<ScheduledSMS> getPendingSms() {
    final now = DateTime.now();
    final filtered = _items.values
        .where(
          (sms) => sms.active &&
              sms.status == SmsStatus.pending &&
              !sms.scheduledDate.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return List.unmodifiable(filtered);
  }

  List<ScheduledSMS> getSmsByStatus(SmsStatus status) {
    final filtered = _items.values
        .where((sms) => sms.status == status)
        .toList()
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return List.unmodifiable(filtered);
  }

  int updateSmsStatus(
    String id,
    SmsStatus status, {
    String? errorMessage,
    DateTime? sentAt,
  }) {
    final existing = _items[id];
    if (existing == null) {
      return 0;
    }

    final updated = existing.copyWith(
      status: status,
      updatedAt: DateTime.now(),
      errorMessage: errorMessage,
      sentAt: sentAt,
      retryCount: status == SmsStatus.failed
          ? existing.retryCount + 1
          : existing.retryCount,
    );

    _items[id] = updated;
    return 1;
  }

  int clear() {
    final count = _items.length;
    _items.clear();
    return count;
  }
}
