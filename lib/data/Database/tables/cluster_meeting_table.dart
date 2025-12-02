class ClusterMeetingsTable {
  static const String table = 'cluster_meetings';

  static const create = '''
  CREATE TABLE IF NOT EXISTS $table (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unique_key TEXT NOT NULL,
    form_json TEXT NOT NULL,
    created_date_time TEXT NOT NULL,
    created_by TEXT NOT NULL,
    modified_date_time TEXT,
    modified_by TEXT,
    is_synced INTEGER DEFAULT 0,
    is_deleted INTEGER DEFAULT 0
  );
  ''';
}