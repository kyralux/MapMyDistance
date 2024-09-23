import 'dart:async';

import 'package:mapgoal/src/data/goal.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String databasePath = 'goaltracker.db';

  static Future<Database> getDBConnector() async {
    return _database ?? await _initDatabase();
  }

  static Future<Database> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), databasePath),
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('''
          CREATE TABLE goals(id INTEGER PRIMARY KEY, name TEXT, 
            description TEXT, latStart REAL, longStart REAL,
            latEnd REAL, longEnd REAL, finished TEXT, 
            totalDistance REAL, curDistance REAL);
        ''');
      },
      version: 1,
    );

    return _database!;
  }

  static Future<void> deleteDatabase() =>
      databaseFactory.deleteDatabase(databasePath);

  // Goals
  static Future<void> insertGoal(Goal goal) async {
    final Database db = await getDBConnector();

    goal.id ??= await db.insert('goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Goal> getGoal(int id) async {
    final Database db = await getDBConnector();
    List<Map<String, Object?>> goalMap =
        await db.query('goals', where: 'goalId = ?', whereArgs: [id]);
    var tmp = goalMap.first;

    return Goal(
        id: int.parse(tmp['id'].toString()),
        name: tmp['name'].toString(),
        description: tmp['description'].toString(),
        latStart: double.parse(tmp['latStart'].toString()),
        longStart: double.parse(tmp['longStart'].toString()),
        latEnd: double.parse(tmp['latEnd'].toString()),
        longEnd: double.parse(tmp['longEnd'].toString()),
        finished: bool.parse(tmp['finished'].toString()),
        totalDistance: double.parse(tmp['totalDistance'].toString()),
        curDistance: double.parse(tmp['curDistance'].toString()));
  }

  static Future<List<Goal>> getGoals() async {
    final Database db = await getDBConnector();

    final List<Map<String, Object?>> goalMaps = await db.query('goals');

    return [
      for (final goalMap in goalMaps)
        Goal(
            id: int.parse(goalMap['id'].toString()),
            name: goalMap['name'].toString(),
            description: goalMap['description'].toString(),
            latStart: double.parse(goalMap['latStart'].toString()),
            longStart: double.parse(goalMap['longStart'].toString()),
            latEnd: double.parse(goalMap['latEnd'].toString()),
            longEnd: double.parse(goalMap['longEnd'].toString()),
            finished: goalMap['finished'].toString().toLowerCase() == 'true',
            totalDistance: double.parse(goalMap['totalDistance'].toString()),
            curDistance: double.parse(goalMap['curDistance'].toString())),
    ];
  }

  static Future<void> updateGoal(Goal goal) async {
    final Database db = await getDBConnector();

    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  static Future<void> deleteGoal(int id) async {
    final Database db = await getDBConnector();

    await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAllGoals() async {
    final Database db = await getDBConnector();

    await db.delete(
      'goals',
    );
  }
}
