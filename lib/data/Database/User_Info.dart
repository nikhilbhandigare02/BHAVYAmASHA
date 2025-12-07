import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'tables/users_table.dart';

class UserInfo {
  static String _hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

 
  static Future<bool> isUserExists(String username) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'm_aasha.db');
      
      final database = await openDatabase(path);
      
      final existingUser = await database.query(
        UsersTable.table,
        where: 'user_name = ? AND is_deleted = 0',
        whereArgs: [username],
      );
      
      // await database.close();
      return existingUser.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>?> getCurrentUser() async {
    Database? db;
    try {
      db = await openDatabase(
        join(await getDatabasesPath(), 'm_aasha.db'),
        onCreate: (db, version) async {
          await db.execute(UsersTable.create);
        },
        version: 1,
      );
      
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
      );
      
      if (tables.isEmpty) {
        print('Users table does not exist yet');
        return null;
      }
      
      final result = await db.query(
        'users',
        where: 'is_deleted = 0',
        orderBy: 'modified_date_time DESC',
        limit: 1,
      );
      
      if (result.isEmpty) {
        print('No active users found in the database');
        return null;
      }
      
      final user = Map<String, dynamic>.from(result.first);
      
      if (user['details'] is String) {
        try {
          user['details'] = jsonDecode(user['details']);
        } catch (e) {
          print('Error parsing user details: $e');
        }
      }
      
   //   print('Successfully retrieved user: ${user['user_name']}');
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    } finally {
      // Close the database connection when done
      // if (db != null && db.isOpen) {
      //   await db.close();
      // }
    }
  }
  
  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final db = await database;
      
 
      // await db.execute('''
      //   CREATE TABLE IF NOT EXISTS users (
      //     id INTEGER PRIMARY KEY AUTOINCREMENT,
      //     user_name TEXT,
      //     password TEXT,
      //     role_id INTEGER,
      //     details TEXT,
      //     created_date_time TEXT,
      //     modified_date_time TEXT,
      //     is_deleted INTEGER DEFAULT 0
      //   )
      // ''');
      
      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'user_name = ? AND is_deleted = 0',
        whereArgs: [username],
      );
      
      if (users.isNotEmpty) {
        return users.first;
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'm_aasha.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(UsersTable.create);
        print('Users table created successfully');
      },
    );
  }

  static Future<Map<String, dynamic>> storeUserData({
    required String username,
    required String password,
    required int roleId,
    required Map<String, dynamic> userDetails,
  }) async {
    Database? db;
    try {
      db = await openDatabase(
        join(await getDatabasesPath(), 'm_aasha.db'),
        onCreate: (db, version) async {
          await db.execute(UsersTable.create);
        },
        version: 1,
      );
      
      // Ensure the table exists with the correct schema
      await db.execute(UsersTable.create);
      
      // Check if user exists
      final existingUser = await db.query(
        'users',
        where: 'user_name = ? AND is_deleted = 0',
        whereArgs: [username],
      );
      
      final hashedPassword = _hashPassword(password);
      final detailsJson = jsonEncode(userDetails);
      final now = DateTime.now().toIso8601String();
      
      if (existingUser.isNotEmpty) {
        // Update existing user
        await db.update(
          'users',
          {
            'password': hashedPassword,
            'role_id': roleId,
            'details': detailsJson,
            'modified_date_time': now,
          },
          where: 'user_name = ?',
          whereArgs: [username],
        );
        print('User $username updated in the database');
        return {'isNewUser': false, 'user': existingUser.first};
      } else {

        await db.insert(
          'users',
          {
            'user_name': username,
            'password': hashedPassword,
            'role_id': roleId,
            'details': detailsJson,
            'created_date_time': now,
            'modified_date_time': now,
            'is_deleted': 0,
          },
        );
        print('New user $username added to the database');
      }
      
      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setInt('roleId', roleId);
      
      print('User data stored successfully');
    } catch (e) {
      print('Error in storeUserData: $e');
      rethrow;
    } finally {
      // if (db != null && db.isOpen) {
      //   await db.close();
      // }
    }
    return {'isNewUser': true};
  }

  static Future<void> updatePopulationCovered(String populationCovered) async {
    Database? db;
    try {
      db = await openDatabase(
        join(await getDatabasesPath(), 'm_aasha.db'),
      );

      // Get the current user directly from this database instance
      final result = await db.query(
        'users',
        where: 'is_deleted = 0',
        orderBy: 'modified_date_time DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        final user = result.first;
        
        // Parse the details JSON
        final details = user['details'] is String
            ? jsonDecode(user['details'] as String)
            : user['details'];

        // Update the population_covered_by_asha field
        details['population_covered_by_asha'] = populationCovered;

        final detailsJson = jsonEncode(details);
        final now = DateTime.now().toIso8601String();

        // Update the database
        await db.update(
          'users',
          {
            'details': detailsJson,
            'modified_date_time': now,
          },
          where: 'user_name = ?',
          whereArgs: [user['user_name']],
        );
        log('User population covered updated in the database: $populationCovered');
      } else {
        log('No active user found to update');
      }
    } catch (e) {
      log('Error in updatePopulationCovered: $e');
      rethrow;
    } finally {
      // if (db != null && db.isOpen) {
      //   await db.close();
      // }
    }
  }


  

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'm_aasha.db');
      
      final database = await openDatabase(path);
      
      final List<Map<String, dynamic>> users = await database.query(
        UsersTable.table,
        limit: 1,
      );
      
      // await database.close();
      
      if (users.isNotEmpty) {
        return users.first;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  

  static Future<void> clearUserData() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'm_aasha.db');
      
      final database = await openDatabase(path);
      await database.delete(UsersTable.table);
      // await database.close();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }


  static Future<void> printUserData() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'm_aasha.db');
      
      final database = await openDatabase(path);
      
      final List<Map<String, dynamic>> users = await database.query(UsersTable.table);
      
      if (users.isEmpty) {
        print('No user data found in the database.');
        return;
      }
      
      print('\n=== USER DATA IN DATABASE ===');
      for (var user in users) {
        print('\nUser ID: ${user['id']}');
        print('Username: ${user['user_name']}');
        print('Role ID: ${user['role_id']}');
        print('Password Hash: ${user['password']}');
        print('Created: ${user['created_date_time']}');
        print('Modified: ${user['modified_date_time']}');
        print('Is Deleted: ${user['is_deleted'] == 1 ? 'Yes' : 'No'}');
        print('Details (raw): ${user['details']}');
        
        try {
          final detailsRaw = user['details'];
          print('Details (raw type): ${detailsRaw.runtimeType}');
          
          if (detailsRaw is String) {
            print('Details is String, attempting to parse...');
            final details = jsonDecode(detailsRaw);
            print('Details (parsed type): ${details.runtimeType}');
            print('Details (parsed keys): ${(details as Map<String, dynamic>).keys.toList()}');
            
            if (details.containsKey('data')) {
              print('Found "data" key in details');
              final dataContent = details['data'];
              print('Data content type: ${dataContent.runtimeType}');
              if (dataContent is Map) {
                print('Data keys: ${(dataContent as Map<String, dynamic>).keys.toList()}');
                if (dataContent.containsKey('working_location')) {
                  print('Working location: ${dataContent['working_location']}');
                }
              }
            } else {
              print('No "data" key found, top-level keys: ${details.keys.toList()}');
            }
          } else {
            print('Details is not a String: $detailsRaw');
          }
        } catch (e) {
          print('Could not parse details JSON: $e');
          print('Raw details value: ${user['details']}');
        }
        print('-' * 40);
      }
      
      // await database.close();
    } catch (e) {
      print('Error reading user data: $e');
      rethrow;
    }
  }
}