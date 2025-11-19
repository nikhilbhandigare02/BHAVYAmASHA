class NotificationDetailsTable {
  static const table = 'notification_details';

  static const create = '''
  CREATE TABLE IF NOT EXISTS notification_details (
    id INTEGER PRIMARY KEY,
    _id TEXT,
    unique_key TEXT,
    added_date_time TEXT,
    announcement_end_period TEXT,
    announcement_for TEXT,
    announcement_start_period TEXT,
    announcement_type TEXT,
    block_id INTEGER,
    block_name TEXT,
    content_en TEXT,
    content_hi TEXT,
    district_id INTEGER,
    district_name TEXT,
    state_id INTEGER,
    state_name TEXT,
    title_en TEXT,
    title_hi TEXT,
    modified_date_time TEXT,
    option TEXT,
    is_deleted INTEGER,
    is_published INTEGER,
    __v INTEGER,
    is_read INTEGER,
    is_synced INTEGER
  );
  ''';
}
