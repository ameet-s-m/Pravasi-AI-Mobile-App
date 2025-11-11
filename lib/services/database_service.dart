// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Database? get database => _database;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pravasi_ai.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Trips table
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        origin TEXT,
        destination TEXT,
        distance REAL,
        duration INTEGER,
        start_time INTEGER,
        end_time INTEGER,
        mode TEXT,
        safety_status TEXT,
        route_data TEXT,
        created_at INTEGER
      )
    ''');

    // Incidents table
    await db.execute('''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        type TEXT,
        latitude REAL,
        longitude REAL,
        description TEXT,
        timestamp INTEGER,
        reported_by TEXT
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        latitude REAL,
        longitude REAL,
        timestamp INTEGER,
        trip_id TEXT,
        speed REAL,
        accuracy REAL
      )
    ''');

    // Analytics table
    await db.execute('''
      CREATE TABLE analytics (
        id TEXT PRIMARY KEY,
        metric_name TEXT,
        metric_value REAL,
        timestamp INTEGER,
        metadata TEXT
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        trip_id TEXT,
        category TEXT,
        amount REAL,
        currency TEXT,
        description TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> saveTrip(Map<String, dynamic> tripData) async {
    await _database?.insert('trips', tripData);
  }

  Future<List<Map<String, dynamic>>> getAllTrips() async {
    return await _database?.query('trips', orderBy: 'created_at DESC') ?? [];
  }

  Future<void> saveLocation(Map<String, dynamic> locationData) async {
    await _database?.insert('locations', locationData);
  }

  Future<List<Map<String, dynamic>>> getTripLocations(String tripId) async {
    return await _database?.query(
      'locations',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    ) ?? [];
  }

  Future<void> saveIncident(Map<String, dynamic> incidentData) async {
    await _database?.insert('incidents', incidentData);
  }

  Future<List<Map<String, dynamic>>> getAllIncidents() async {
    return await _database?.query('incidents', orderBy: 'timestamp DESC') ?? [];
  }

  Future<void> saveExpense(Map<String, dynamic> expenseData) async {
    await _database?.insert('expenses', expenseData);
  }

  Future<List<Map<String, dynamic>>> getTripExpenses(String tripId) async {
    return await _database?.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    ) ?? [];
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final trips = await getAllTrips();
    final incidents = await getAllIncidents();
    
    return {
      'total_trips': trips.length,
      'total_incidents': incidents.length,
      'total_distance': trips.fold<double>(0, (sum, trip) => sum + (trip['distance'] as num).toDouble()),
      'total_duration': trips.fold<int>(0, (sum, trip) => sum + (trip['duration'] as int)),
    };
  }

  Future<String> exportDataAsJSON() async {
    final data = {
      'trips': await getAllTrips(),
      'incidents': await getAllIncidents(),
      'analytics': await getAnalytics(),
      'exported_at': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  Future<String> exportDataAsCSV(String tableName) async {
    final rows = await _database?.query(tableName) ?? [];
    if (rows.isEmpty) return '';

    final headers = rows.first.keys.join(',');
    final csvRows = rows.map((row) => 
      row.values.map((v) => v.toString()).join(',')
    ).toList();

    return [headers, ...csvRows].join('\n');
  }
}

