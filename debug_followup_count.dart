import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';

void main() async {
  print('🔍 Debugging Follow-up Count Issue');
  print('=====================================');
  
  try {
    // Get database
    final db = await DatabaseProvider.instance.database;
    
    // Check total follow-up records without user filter
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0',
    );
    final totalCount = totalResult.first['count'] as int? ?? 0;
    print('📊 Total follow-up records (all users): $totalCount');
    
    // Check records with current user (you'll need to replace with actual user key)
    const currentUserKey = 'your_user_key_here'; // Replace with actual user key
    final userResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND current_user_key = ?',
      [currentUserKey],
    );
    final userCount = userResult.first['count'] as int? ?? 0;
    print('👤 Follow-up records for current user: $userCount');
    
    // Check records with NULL/empty current_user_key
    final nullResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND (current_user_key IS NULL OR current_user_key = "")',
    );
    final nullCount = nullResult.first['count'] as int? ?? 0;
    print('❓ Follow-up records with NULL/empty user key: $nullCount');
    
    // Check records belonging to other users
    final otherUsersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND current_user_key IS NOT NULL AND current_user_key != "" AND current_user_key != ?',
      [currentUserKey],
    );
    final otherUsersCount = otherUsersResult.first['count'] as int? ?? 0;
    print('👥 Follow-up records belonging to other users: $otherUsersCount');
    
    print('\n📋 Summary:');
    print('Expected total: $totalCount');
    print('Current user: $userCount');
    print('NULL/empty: $nullCount');
    print('Other users: $otherUsersCount');
    print('Sum check: ${userCount + nullCount + otherUsersCount}');
    
    if (totalCount != userCount) {
      print('\n⚠️  ISSUE FOUND: The app shows $userCount but database has $totalCount records');
      print('💡 SOLUTION: Remove current_user_key filter to show all records');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
