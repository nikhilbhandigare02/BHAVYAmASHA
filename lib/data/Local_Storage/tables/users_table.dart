class UsersTable {
  static const table = 'users';

  static const create = '''
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name TEXT,
    password TEXT,
    role_id INTEGER,
    details TEXT,
    created_date_time TEXT,
    modified_date_time TEXT,
    is_deleted INTEGER
  );
  ''';
}
