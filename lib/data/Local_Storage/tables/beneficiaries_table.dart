class BeneficiariesTable {
  static const table = 'beneficiaries';

  static const create = '''
  CREATE TABLE IF NOT EXISTS beneficiaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    server_id TEXT,
    household_ref_key TEXT,
    unique_key TEXT,
    beneficiary_state TEXT,
    pregnancy_count INTEGER, 
    beneficiary_info TEXT,
    geo_location TEXT,
    spouse_key TEXT,
    mother_key TEXT,
    father_key TEXT,
    is_family_planning INTEGER,
    is_adult INTEGER,
    is_guest INTEGER,
    is_death INTEGER,
    death_details TEXT,
    is_migrated INTEGER,
    is_separated INTEGER,
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
