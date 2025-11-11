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
      developer.log('Getting registered child count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Check if beneficiaries table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      developer.log('Available tables: ${tables.map((e) => e['name']).toList()}', name: 'ChildCareCountProvider');
      
      final beneficiariesTable = tables.any((t) => t['name'] == 'beneficiaries');
      if (!beneficiariesTable) {
        developer.log('Beneficiaries table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // First, get the total count of non-deleted records
      final totalCount = await db.rawQuery('''
        SELECT COUNT(*) as count FROM beneficiaries WHERE is_deleted = 0
      ''');
      developer.log('Total non-deleted beneficiaries: ${totalCount.first['count']}', 
                   name: 'ChildCareCountProvider');
      
      // Get count of child beneficiaries
      final query = '''
        SELECT COUNT(*) as count, 
               SUM(CASE WHEN beneficiary_info LIKE '%"is_child":true%' OR 
                           beneficiary_info LIKE '%"is_child": true%' THEN 1 ELSE 0 END) as is_child_count,
               SUM(CASE WHEN beneficiary_info LIKE '%"date_of_birth":%' AND 
                           beneficiary_info NOT LIKE '%"date_of_birth":null%' THEN 1 ELSE 0 END) as has_dob_count
        FROM beneficiaries 
        WHERE is_deleted = 0
      ''';
      
      developer.log('Executing query: $query', name: 'ChildCareCountProvider');
      final count = await db.rawQuery(query);
      
      final result = count.first['count'] as int? ?? 0;
      final isChildCount = count.first['is_child_count'] as int? ?? 0;
      final hasDobCount = count.first['has_dob_count'] as int? ?? 0;
      
      developer.log('''
      Count results:
      - Total: $result
      - Has is_child: $isChildCount
      - Has date_of_birth: $hasDobCount
      ''', name: 'ChildCareCountProvider');
      
      // Return the count of records that match either condition
      final finalCount = isChildCount > 0 ? isChildCount : hasDobCount;
      developer.log('Final registered children count: $finalCount', name: 'ChildCareCountProvider');
      
      return finalCount;
      
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
    try {
      developer.log('Getting registration due count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Check if child_care_activities table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final childCareTable = tables.any((t) => t['name'] == 'child_care_activities');
      
      if (!childCareTable) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // First, check what states exist in the child_care_activities table
      final states = await db.rawQuery('''
        SELECT DISTINCT child_care_state, COUNT(*) as count 
        FROM child_care_activities 
        WHERE is_deleted = 0 OR is_deleted IS NULL
        GROUP BY child_care_state
      ''');
      
      developer.log('Available child care states:', name: 'ChildCareCountProvider');
      for (var state in states) {
        developer.log('- ${state['child_care_state']}: ${state['count']}', name: 'ChildCareCountProvider');
      }
      
      // Get count of children due for registration
      final query = '''
        SELECT COUNT(DISTINCT b.id) as count
        FROM beneficiaries b
        INNER JOIN child_care_activities c ON b.unique_key = c.beneficiary_ref_key
        WHERE b.is_deleted = 0 
        AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
        AND (c.child_care_state = 'REGISTRATION_DUE' OR c.child_care_state = 'registration_due' OR c.child_care_state LIKE '%registration%')
      ''';
      
      developer.log('Executing query: $query', name: 'ChildCareCountProvider');
      final count = await db.rawQuery(query);
      
      final result = count.first['count'] as int? ?? 0;
      developer.log('Found $result children due for registration', name: 'ChildCareCountProvider');
      
      return result;
      
    } catch (e, stackTrace) {
      developer.log('Error in getRegistrationDueCount: $e', 
                  name: 'ChildCareCountProvider',
                  error: e,
                  stackTrace: stackTrace);
      return 0;
    }
  }

  // Get count of child tracking due
  Future<int> getTrackingDueCount() async {
    try {
      developer.log('Getting tracking due count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Check if child_care_activities table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final childCareTable = tables.any((t) => t['name'] == 'child_care_activities');
      
      if (!childCareTable) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // First, check if next_visit_date column exists
      final columns = await db.rawQuery("PRAGMA table_info(child_care_activities)");
      final hasNextVisitDate = columns.any((col) => col['name'] == 'next_visit_date');
      
      String query;
      if (hasNextVisitDate) {
        query = '''
          SELECT COUNT(DISTINCT b.id) as count
          FROM beneficiaries b
          INNER JOIN child_care_activities c ON b.unique_key = c.beneficiary_ref_key
          WHERE b.is_deleted = 0 
          AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
          AND c.next_visit_date < DATE('now')
        ''';
      } else {
        // Fallback to using created_date_time if next_visit_date doesn't exist
        query = '''
          SELECT COUNT(DISTINCT b.id) as count
          FROM beneficiaries b
          INNER JOIN child_care_activities c ON b.unique_key = c.beneficiary_ref_key
          WHERE b.is_deleted = 0 
          AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
          AND c.created_date_time < DATE('now', '-7 day')  -- Default to 7 days after creation
        ''';
      }
      
      developer.log('Executing query: $query', name: 'ChildCareCountProvider');
      final count = await db.rawQuery(query);
      
      final result = count.first['count'] as int? ?? 0;
      developer.log('Found $result children with tracking due', name: 'ChildCareCountProvider');
      return result;
      
    } catch (e, stackTrace) {
      developer.log('Error in getTrackingDueCount: $e', 
                  name: 'ChildCareCountProvider',
                  error: e,
                  stackTrace: stackTrace);
      return 0;
    }
  }

  // Get count of HBYC (Home Based Young Child) list
  Future<int> getHBYCCount() async {
    try {
      developer.log('Getting HBYC count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Check if child_care_activities table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final childCareTable = tables.any((t) => t['name'] == 'child_care_activities');
      
      if (!childCareTable) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Get count of HBYC children
      final query = '''
        SELECT COUNT(DISTINCT b.id) as count
        FROM beneficiaries b
        INNER JOIN child_care_activities c ON b.unique_key = c.beneficiary_ref_key
        WHERE b.is_deleted = 0 
        AND (c.is_deleted = 0 OR c.is_deleted IS NULL)
        AND (c.child_care_state = 'HBYC' OR LOWER(c.child_care_state) = 'hbyc')
      ''';
      
      developer.log('Executing query: $query', name: 'ChildCareCountProvider');
      final count = await db.rawQuery(query);
      
      final result = count.first['count'] as int? ?? 0;
      developer.log('Found $result HBYC children', name: 'ChildCareCountProvider');
      return result;
      
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
      
      // First try to get from followup_form_data
      try {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
        if (tables.isNotEmpty) {
          final count = await db.rawQuery('''
            SELECT COUNT(DISTINCT beneficiary_ref_key) as count
            FROM followup_form_data 
            WHERE (form_json LIKE '%"reason_of_death":%' 
                  OR form_json LIKE '%"reason_of_death"%')
            AND is_deleted = 0
          ''');
          
          final result = count.first['count'] as int? ?? 0;
          if (result > 0) {
            developer.log('Found $result deceased children in followup_form_data', name: 'ChildCareCountProvider');
            return result;
          }
        }
      } catch (e) {
        developer.log('Error checking followup_form_data: $e', name: 'ChildCareCountProvider');
      }
      
      // Fallback to beneficiaries table
      try {
        final count = await db.rawQuery('''
          SELECT COUNT(*) as count 
          FROM beneficiaries 
          WHERE is_death = 1 
          AND is_deleted = 0
        ''');
        
        final result = count.first['count'] as int? ?? 0;
        developer.log('Found $result deceased children in beneficiaries table', name: 'ChildCareCountProvider');
        return result;
        
      } catch (e) {
        developer.log('Error checking beneficiaries table: $e', name: 'ChildCareCountProvider');
        return 0;
      }
      
    } catch (e, stackTrace) {
      developer.log('Error in getDeceasedCount: $e', 
                  name: 'ChildCareCountProvider',
                  error: e,
                  stackTrace: stackTrace);
      return 0;
    }
  }
}
