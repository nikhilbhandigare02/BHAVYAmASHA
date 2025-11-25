class MotherCareActivitiesTable {
  static const table = 'mother_care_activities';

  static const create = '''
  CREATE TABLE IF NOT EXISTS mother_care_activities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT,
    household_ref_key TEXT,
    beneficiary_ref_key TEXT,
    mother_care_state TEXT,
    device_details TEXT,
    app_details TEXT,
    parent_user TEXT,
    current_user_key TEXT,
    facility_id INTEGER,
    created_date_time TEXT,
    modified_date_time TEXT,
    is_synced INTEGER,
    is_deleted INTEGER
  );
  ''';
}
