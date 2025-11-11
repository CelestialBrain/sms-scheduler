import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/customer.dart';

/// Database handler for customer data
class CustomerDatabase {
  static final CustomerDatabase _instance = CustomerDatabase._internal();
  static Database? _database;
  static final _InMemoryCustomerStore _webStore = _InMemoryCustomerStore();

  factory CustomerDatabase() => _instance;

  CustomerDatabase._internal();

  /// Get the database instance
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'The sqflite database is not available on web. Customer data will be stored in memory.',
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
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT,
        notes TEXT,
        tags TEXT,
        metadata TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_customer_phone ON customers(phoneNumber)
    ''');

    await db.execute('''
      CREATE INDEX idx_customer_active ON customers(active)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Customer table was added in version 2
    if (oldVersion < 2) {
      await _onCreate(db, newVersion);
    }

    if (oldVersion < 3) {
      // No schema changes for version 3. This block ensures the database
      // version stays aligned with [SmsDatabase] when both are opened
      // separately.
    }
  }

  /// Insert a new customer
  Future<int> insertCustomer(Customer customer) async {
    if (kIsWeb) {
      _webStore.insertOrReplace(customer);
      return 1;
    }

    final db = await database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing customer
  Future<int> updateCustomer(Customer customer) async {
    if (kIsWeb) {
      return _webStore.updateCustomer(customer);
    }

    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// Delete a customer
  Future<int> deleteCustomer(String id) async {
    if (kIsWeb) {
      return _webStore.deleteCustomer(id);
    }

    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get a customer by ID
  Future<Customer?> getCustomer(String id) async {
    if (kIsWeb) {
      return _webStore.getCustomer(id);
    }

    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Get a customer by phone number
  Future<Customer?> getCustomerByPhone(String phoneNumber) async {
    if (kIsWeb) {
      return _webStore.getCustomerByPhone(phoneNumber);
    }

    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );

    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Get all customers
  Future<List<Customer>> getAllCustomers() async {
    if (kIsWeb) {
      return _webStore.getAllCustomers();
    }

    final db = await database;
    final maps = await db.query(
      'customers',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Get active customers
  Future<List<Customer>> getActiveCustomers() async {
    if (kIsWeb) {
      return _webStore.getActiveCustomers();
    }

    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Search customers by name or phone number
  Future<List<Customer>> searchCustomers(String query) async {
    if (kIsWeb) {
      return _webStore.searchCustomers(query);
    }

    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'name LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Toggle customer active status
  Future<int> toggleActive(String id, bool active) async {
    if (kIsWeb) {
      final customer = await getCustomer(id);
      if (customer == null) {
        return 0;
      }
      final updated = customer.copyWith(
        active: active,
        updatedAt: DateTime.now(),
      );
      return updateCustomer(updated);
    }

    final db = await database;
    return await db.update(
      'customers',
      {
        'active': active ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all customers
  Future<int> deleteAll() async {
    if (kIsWeb) {
      return _webStore.clear();
    }

    final db = await database;
    return await db.delete('customers');
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

/// In-memory store for web platform
class _InMemoryCustomerStore {
  final Map<String, Customer> _items = {};

  void insertOrReplace(Customer customer) {
    _items[customer.id] = customer;
  }

  int updateCustomer(Customer customer) {
    if (!_items.containsKey(customer.id)) {
      return 0;
    }
    _items[customer.id] = customer;
    return 1;
  }

  int deleteCustomer(String id) {
    return _items.remove(id) == null ? 0 : 1;
  }

  Customer? getCustomer(String id) {
    return _items[id];
  }

  Customer? getCustomerByPhone(String phoneNumber) {
    return _items.values.firstWhere(
      (customer) => customer.phoneNumber == phoneNumber,
      orElse: () => throw StateError('No customer found'),
    );
  }

  List<Customer> getAllCustomers() {
    final sorted = _items.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(sorted);
  }

  List<Customer> getActiveCustomers() {
    final filtered = _items.values
        .where((customer) => customer.active)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(filtered);
  }

  List<Customer> searchCustomers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = _items.values
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(lowerQuery) ||
              customer.phoneNumber.contains(query),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(filtered);
  }

  int clear() {
    final count = _items.length;
    _items.clear();
    return count;
  }
}
