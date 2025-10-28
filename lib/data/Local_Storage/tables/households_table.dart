class HouseholdsTable {
  static const table = 'households';

  static const create = '''
  CREATE TABLE IF NOT EXISTS households (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT,
    unique_key TEXT,
    address TEXT,
    geo_location TEXT,
    head_id TEXT,
    household_info TEXT,
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
