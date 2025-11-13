import 'dart:convert';

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

      // First, get all child beneficiaries
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries',
        where: 'is_deleted = ? AND is_adult = ?',
        whereArgs: [0, 0], // 0 for false, 1 for true
      );

      int childCount = 0;

      for (final row in rows) {
        try {
          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          // Match the exact same criteria as RegisterChildListScreen
          final memberType = (info['memberType']?.toString() ?? '').toLowerCase();
          final relation = (info['relation']?.toString() ?? '').toLowerCase();
          final name = info['name']?.toString() ??
                      info['memberName']?.toString() ??
                      info['member_name']?.toString() ?? '';

          // Only count if it's a child and has a name
          if ((memberType == 'child' ||
               relation == 'child' ||
               relation == 'son' ||
               relation == 'daughter') &&
              name.isNotEmpty) {
            childCount++;
          }
        } catch (e) {
          developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
          continue;
        }
      }

      developer.log('Found $childCount registered child beneficiaries', name: 'ChildCareCountProvider');
      return childCount;

    } catch (e, stackTrace) {
      developer.log('Error in getRegisteredChildCount: $e', 
                  name: 'ChildCareCountProvider',
                  error: e,
                  stackTrace: stackTrace);
      return 0;
    }
  }

  Future<int> getRegistrationDueCount() async {
    try {
      developer.log('Getting registration due count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
       final rows = await db.query(
        'beneficiaries',
        where: 'is_deleted = ? AND beneficiary_state = ?',
        whereArgs: [0, 'registration_due'],
      );

      int count = 0;
      for (final row in rows) {
        try {
          // Parse beneficiary_info to check if it's a child
          dynamic info;
          if (row['beneficiary_info'] is String) {
            info = jsonDecode(row['beneficiary_info'] as String);
          } else {
            info = row['beneficiary_info'];
          }

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          if (memberType == 'child') {
            count++;
          }
        } catch (e) {
          developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
          continue;
        }
      }
      
      developer.log('Found $count children due for registration', name: 'ChildCareCountProvider');
      return count;
      
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
      
      // Check if followup_form_data table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
      if (tables.isEmpty) {
        developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Query followup_form_data for child tracking due forms
      final results = await db.query(
        'followup_form_data',
        where: 'form_json LIKE ? OR forms_ref_key = ?',
        whereArgs: ['%child_registration_due%', '30bycxe4gv7fqnt6'],
      );
      
      int count = 0;
      for (final row in results) {
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) continue;
          
          final formData = jsonDecode(formJson);
          final formType = formData['form_type']?.toString() ?? '';
          final formsRefKey = row['forms_ref_key']?.toString() ?? '';
          
          // Count if it's a child registration or child tracking due form
          final isChildRegistration = formType.toLowerCase().contains('child_registration_due');
          final isChildTracking = formsRefKey == '30bycxe4gv7fqnt6' || 
                                formType.toLowerCase().contains('child_tracking_due');
          
          if (isChildRegistration || isChildTracking) {
            count++;
          }
        } catch (e) {
          developer.log('Error processing form data: $e', name: 'ChildCareCountProvider');
          continue;
        }
      }
      
      developer.log('Found $count child tracking due records', name: 'ChildCareCountProvider');
      return count;
      
    } catch (e, stackTrace) {
      developer.log('Error in getTrackingDueCount: $e', 
                  name: 'ChildCareCountProvider',
                  error: e,
                  stackTrace: stackTrace);
      return 0;
    }
  }

  // Calculate age in months from date of birth
  int _calculateAgeInMonths(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 0;
    
    try {
      final dob = DateTime.parse(dobStr);
      final now = DateTime.now();
      final months = (now.year - dob.year) * 12 + now.month - dob.month;
      return months;
    } catch (e) {
      developer.log('Error calculating age for DOB: $dobStr - $e', name: 'ChildCareCountProvider');
      return 0;
    }
  }

  // Check if age is between 3 and 15 months
  bool _isAgeInRange(String? dobStr) {
    final months = _calculateAgeInMonths(dobStr);
    return months >= 3 && months <= 15;
  }

  // Get count of HBYC (Home Based Young Child) list
  Future<int> getHBYCCount() async {
    try {
      developer.log('Getting HBYC count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // First, get all child beneficiaries
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries',
        where: 'is_deleted = ? AND is_adult = ?',
        whereArgs: [0, 0],
      );

      int hbycCount = 0;

      for (final row in rows) {
        try {
          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString() ?? '';
          final dob = info['dob']?.toString();
          
          // Count only child members with age between 3-15 months
          if (memberType == 'Child' && _isAgeInRange(dob)) {
            hbycCount++;
          }
        } catch (e) {
          developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
          continue;
        }
      }
      
      developer.log('Found $hbycCount HBYC children', name: 'ChildCareCountProvider');
      return hbycCount;
      
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
