import 'package:sqflite/sqflite.dart';
class TrainingDataTable {
  static const table = 'training_form';


  static const create = '''
  CREATE TABLE IF NOT EXISTS training_form (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT,
    forms_ref_key TEXT,
    household_ref_key TEXT,
    beneficiary_ref_key TEXT,
    mother_key TEXT,
    father_key TEXT,
    child_care_state TEXT,
    device_details TEXT,
    app_details TEXT,
    parent_user TEXT,
    current_user_key TEXT,
    facility_id INTEGER,
    form_json TEXT, 
    created_date_time TEXT,
    modified_date_time TEXT,
    is_synced INTEGER,
    is_deleted INTEGER
  );
  ''';

  static Future<void> createTable(Database db) async {
    await db.execute(create);
    print("Table created → $table");
  }
}
