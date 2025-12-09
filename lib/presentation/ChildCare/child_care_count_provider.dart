import 'dart:convert';

import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';

class ChildCareCountProvider {
  static final ChildCareCountProvider _instance = ChildCareCountProvider._internal();
  factory ChildCareCountProvider() => _instance;
  ChildCareCountProvider._internal();

  // Get count of all registered child beneficiaries
  Future<int> getRegisteredChildCount() async {
    try {
      developer.log('Getting registered child count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Check if beneficiaries table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      developer.log('Available tables: ${tables.map((e) => e['name']).toList()}', name: 'ChildCareCountProvider');

      final beneficiariesTable = tables.any((t) => t['name'] == 'beneficiaries_new');
      if (!beneficiariesTable) {
        developer.log('Beneficiaries table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }

      // First, get all child beneficiaries
      String whereClause = 'is_deleted = ? AND is_adult = ?';
      List<Object?> whereArgs = [0, 0];
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // First check if child_care_activities table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='child_care_activities'"
      );
      
      if (tables.isEmpty) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      // Get count of children with registration_due status from child_care_activities
      String sql = '''
        SELECT COUNT(DISTINCT cca.beneficiary_ref_key) as count
        FROM child_care_activities cca
        INNER JOIN beneficiaries_new bn ON cca.beneficiary_ref_key = bn.unique_key
        WHERE cca.child_care_state = ?
        AND IFNULL(cca.is_deleted, 0) = 0
        AND IFNULL(bn.is_deleted, 0) = 0
      ''';
      List<Object?> args = ['registration_due'];
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        sql += ' AND cca.current_user_key = ?';
        args.add(ashaUniqueKey);
      }
      final results = await db.rawQuery(sql, args);
      
      final count = results.first['count'] as int? ?? 0;
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // Check if followup_form_data table exists
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
      if (tables.isEmpty) {
        developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }
      
      String whereClause;
      List<Object?> whereArgs;
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause = '(form_json LIKE ? OR forms_ref_key = ?) AND current_user_key = ?';
        whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6', ashaUniqueKey];
      } else {
        whereClause = 'form_json LIKE ? OR forms_ref_key = ?';
        whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
      }

      final results = await db.query(
        'followup_form_data',
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      int count = 0;
      final Set<String> seenBeneficiaries = <String>{};
      for (final row in results) {
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) continue;

          final formData = jsonDecode(formJson);
          final formType = formData['form_type']?.toString() ?? '';
          final formsRefKey = row['forms_ref_key']?.toString() ?? '';

          final isChildRegistration = formType == FollowupFormDataTable.childRegistrationDue;
          final isChildTracking = formsRefKey == '30bycxe4gv7fqnt6' || formType == FollowupFormDataTable.childTrackingDue;
          if (!isChildRegistration && !isChildTracking) {
            continue;
          }

          final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';
          if (beneficiaryRefKey.isNotEmpty && seenBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }

          if (beneficiaryRefKey.isNotEmpty) {
            String ccWhere;
            List<Object?> ccArgs;
            if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
              ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?';
              ccArgs = [beneficiaryRefKey, '%case_closure%', ashaUniqueKey];
            } else {
              ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
              ccArgs = [beneficiaryRefKey, '%case_closure%'];
            }
            final caseClosureRecords = await db.query(
              'followup_form_data',
              where: ccWhere,
              whereArgs: ccArgs,
            );
            bool hasCaseClosure = false;
            for (final ccRecord in caseClosureRecords) {
              try {
                final ccFormJson = ccRecord['form_json'] as String?;
                if (ccFormJson != null) {
                  final ccFormData = jsonDecode(ccFormJson);
                  final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
                  final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
                  if (caseClosure['is_case_closure'] == true) {
                    hasCaseClosure = true;
                    break;
                  }
                }
              } catch (_) {}
            }
            if (hasCaseClosure) {
              continue;
            }
          }

          if (beneficiaryRefKey.isNotEmpty) {
            seenBeneficiaries.add(beneficiaryRefKey);
          }
          count++;
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // First, get all child beneficiaries
      String whereClause = 'is_deleted = ? AND is_adult = ?';
      List<Object?> whereArgs = [0, 0];
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
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
            final beneficiaryRefKey = row['unique_key']?.toString() ?? '';
            if (beneficiaryRefKey.isNotEmpty) {
              String ccWhere;
              List<Object?> ccArgs;
              if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
                ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?';
                ccArgs = [beneficiaryRefKey, '%case_closure%', ashaUniqueKey];
              } else {
                ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
                ccArgs = [beneficiaryRefKey, '%case_closure%'];
              }
              final caseClosureRecords = await db.query(
                'followup_form_data',
                where: ccWhere,
                whereArgs: ccArgs,
              );
              bool hasCaseClosure = false;
              for (final ccRecord in caseClosureRecords) {
                try {
                  final ccFormJson = ccRecord['form_json'] as String?;
                  if (ccFormJson != null) {
                    final ccFormData = jsonDecode(ccFormJson);
                    final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
                    final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
                    if (caseClosure['is_case_closure'] == true) {
                      hasCaseClosure = true;
                      break;
                    }
                  }
                } catch (_) {}
              }
              if (hasCaseClosure) {
                continue;
              }
            }
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // First try to get from followup_form_data
      try {
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
        if (tables.isNotEmpty) {
          String sql = '''
            SELECT COUNT(DISTINCT beneficiary_ref_key) as count
            FROM followup_form_data 
            WHERE (form_json LIKE '%"reason_of_death":%' 
                  OR form_json LIKE '%"reason_of_death"%')
            AND is_deleted = 0
          ''';
          List<Object?> args = [];
          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            sql += ' AND current_user_key = ?';
            args.add(ashaUniqueKey);
          }
          final count = await db.rawQuery(sql, args);
          
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
        String sql = '''
          SELECT COUNT(*) as count 
          FROM beneficiaries_new 
          WHERE is_death = 1 
          AND is_deleted = 0
        ''';
        List<Object?> args = [];
        if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
          sql += ' AND current_user_key = ?';
          args.add(ashaUniqueKey);
        }
        final count = await db.rawQuery(sql, args);
        
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
