import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;

class ChildCareCountProvider {
  static final ChildCareCountProvider _instance = ChildCareCountProvider._internal();
  factory ChildCareCountProvider() => _instance;
  ChildCareCountProvider._internal();

  // Get count of all registered child beneficiaries
  Future<int> getRegisteredChildCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First, check if the table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='beneficiaries'");
      if (tables.isEmpty) {
        developer.log('Beneficiaries table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Get total count first
      final totalCount = await db.query('beneficiaries', 
        where: 'is_deleted = ?', 
        whereArgs: [0],
        columns: ['COUNT(*) as count']
      );
      
      developer.log('Total beneficiaries: ${totalCount.first['count']}', name: 'ChildCareCountProvider');
      
      // Try different queries to find children
      // First try: Check for is_child in beneficiary_info
      var count = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(*) FROM beneficiaries 
        WHERE is_deleted = 0 
        AND (beneficiary_info LIKE '%"is_child":true%' 
             OR beneficiary_info LIKE '%"is_child": true%')
      '''));
      
      if (count == 0) {
        // If no results, try alternative approach - check for age < 18
        final now = DateTime.now();
        final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day).toIso8601String();
        
        count = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM beneficiaries 
          WHERE is_deleted = 0 
          AND (beneficiary_info LIKE '%"date_of_birth":%' 
               AND beneficiary_info NOT LIKE '%"date_of_birth":null%')
        '''));
        
        developer.log('Found $count beneficiaries with date_of_birth', name: 'ChildCareCountProvider');
      }
      
      return count ?? 0;
    } catch (e, stackTrace) {
      developer.log('Error in getRegisteredChildCount: $e', 
                   name: 'ChildCareCountProvider',
                   error: e,
                   stackTrace: stackTrace);
      return 0;
    }
  }

  // Get count of child registration due
  Future<int> getRegistrationDueCount() async {
    // This is a placeholder. You'll need to implement the actual logic
    // based on your business rules for what makes a registration due
    return 0;
  }

  // Get count of child tracking due
  Future<int> getTrackingDueCount() async {
    // This is a placeholder. You'll need to implement the actual logic
    // based on your business rules for what makes a tracking due
    return 0;
  }

  // Get count of HBYC (Home Based Young Child) list
  Future<int> getHBYCCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First check if child_care_activities table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='child_care_activities'");
      if (tables.isEmpty) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Try with exact match first
      var count = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(DISTINCT b.id) 
        FROM beneficiaries b
        INNER JOIN child_care_activities c ON b.beneficiary_ref_key = c.beneficiary_ref_key
        WHERE b.is_deleted = 0 
        AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
        AND c.child_care_state = 'HBYC'
      '''));
      
      // If no results, try case-insensitive search
      if (count == 0) {
        count = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(DISTINCT b.id) 
          FROM beneficiaries b
          INNER JOIN child_care_activities c ON b.beneficiary_ref_key = c.beneficiary_ref_key
          WHERE b.is_deleted = 0 
          AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
          AND LOWER(c.child_care_state) = 'hbyc'
        '''));
      }
      
      developer.log('Found $count HBYC records', name: 'ChildCareCountProvider');
      return count ?? 0;
    } catch (e, stackTrace) {
      developer.log('Error in getHBYCCount: $e', 
                   name: 'ChildCareCountProvider',
                   error: e,
                   stackTrace: stackTrace);
      return 0;
    }
  }

  // Get count of deceased children
  Future<int> getDeceasedCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First check if followup_form_data table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
      if (tables.isEmpty) {
        developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Try different patterns for reason_of_death
      var count = Sqflite.firstIntValue(await db.rawQuery('''
        SELECT COUNT(DISTINCT beneficiary_ref_key) 
        FROM followup_form_data 
        WHERE (form_json LIKE '%"reason_of_death":%' 
               OR form_json LIKE '%"reason_of_death"%')
        AND is_deleted = 0
      '''));
      
      // If no results, try alternative approach - check for any death records
      if (count == 0) {
        count = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM beneficiaries 
          WHERE is_death = 1 AND is_deleted = 0
        '''));
      }
      
      developer.log('Found $count deceased records', name: 'ChildCareCountProvider');
      return count ?? 0;
    } catch (e, stackTrace) {
      developer.log('Error in getDeceasedCount: $e', 
                   name: 'ChildCareCountProvider',
                   error: e,
                   stackTrace: stackTrace);
      return 0;
    }
  }
}
