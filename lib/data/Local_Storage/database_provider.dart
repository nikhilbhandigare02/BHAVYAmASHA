import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'tables/users_table.dart';
import 'tables/households_table.dart';
import 'tables/beneficiaries_table.dart';
import 'tables/eligible_couple_activities_table.dart';
import 'tables/mother_care_activities_table.dart';
import 'tables/child_care_activities_table.dart';
import 'tables/followup_form_data_table.dart';
import 'tables/training_data_table.dart';

class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider instance = DatabaseProvider._();

  static const _dbName = 'medixcel.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(dir.path, _dbName);
    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(UsersTable.create);
    await db.execute(HouseholdsTable.create);
    await db.execute(BeneficiariesTable.create);
    await db.execute(EligibleCoupleActivitiesTable.create);
    await db.execute(MotherCareActivitiesTable.create);
    await db.execute(ChildCareActivitiesTable.create);
    await db.execute(FollowupFormDataTable.create);
    await TrainingDataTable.createTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await TrainingDataTable.createTable(db);
    }
  }
}
