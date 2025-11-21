import 'dart:async';
import 'dart:io';

import 'package:medixcel_new/data/Local_Storage/tables/notification_table.dart';
import 'package:medixcel_new/data/Local_Storage/tables/training_data_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'DB_Migration/DB_Migration.dart';
import 'tables/users_table.dart';
import 'tables/households_table.dart';
import 'tables/beneficiaries_table.dart';
import 'tables/eligible_couple_activities_table.dart';
import 'tables/mother_care_activities_table.dart';
import 'tables/child_care_activities_table.dart';
import 'tables/followup_form_data_table.dart';

class DatabaseProvider {
  DatabaseProvider._();
  static final DatabaseProvider instance = DatabaseProvider._();

  static const _dbName = 'm_aasha.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();

    // Run migration after DB is ready
    // await migrateAppUsers(_db!);

    return _db!;
  }

  Future<Database> _initDb() async {
    final String dbDirPath = await getDatabasesPath();
    final String dbPath = p.join(dbDirPath, _dbName);
    return await openDatabase(dbPath, version: _dbVersion, onCreate: _onCreate,);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(UsersTable.create);
    await db.execute(HouseholdsTable.create);
    await db.execute(BeneficiariesTable.create);
    await db.execute(EligibleCoupleActivitiesTable.create);
    await db.execute(MotherCareActivitiesTable.create);
    await db.execute(ChildCareActivitiesTable.create);
    await db.execute(FollowupFormDataTable.create);
    await db.execute(TrainingDataTable.create);
    await db.execute(NotificationDetailsTable.create);
  }

  Future<void> ensureTablesExist(Database db) async {
    await db.execute(UsersTable.create);
    await db.execute(HouseholdsTable.create);
    await db.execute(BeneficiariesTable.create);
    await db.execute(EligibleCoupleActivitiesTable.create);
    await db.execute(MotherCareActivitiesTable.create);
    await db.execute(ChildCareActivitiesTable.create);
    await db.execute(FollowupFormDataTable.create);
    await db.execute(TrainingDataTable.create);
    await db.execute(NotificationDetailsTable.create);
  }

  Future<void> runMigration(Database db) async {
    try {
      DbMigration.runUserTableMigration(db);
      DbMigration.runBeneficiaryTableMigration(db);
      DbMigration.runHouseholdTableMigration(db);
      DbMigration.runFollowUpTableMigration(db);
      DbMigration.runEligileCoupleTableMigration(db);
      DbMigration.runMotherCareTableMigration(db);
      // DbMigration.runEligibleChildTableMigration(db);

    } catch (e) {
      print("❌ Migration error: $e");
    }
  }


}
