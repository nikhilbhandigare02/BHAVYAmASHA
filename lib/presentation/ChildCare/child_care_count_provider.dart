import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
  // Future<int> getRegisteredChildCount() async {
  //   try {
  //     developer.log('Getting registered child count...', name: 'ChildCareCountProvider');
  //     final db = await DatabaseProvider.instance.database;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // Check if beneficiaries table exists
  //     final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  //     developer.log('Available tables: ${tables.map((e) => e['name']).toList()}', name: 'ChildCareCountProvider');
  //
  //     final beneficiariesTable = tables.any((t) => t['name'] == 'beneficiaries_new');
  //     if (!beneficiariesTable) {
  //       developer.log('Beneficiaries table does not exist', name: 'ChildCareCountProvider');
  //       return 0;
  //     }
  //
  //     // First, get all child beneficiaries
  //     String whereClause = 'is_deleted = ? AND is_adult = ?';
  //     List<Object?> whereArgs = [0, 0];
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause += ' AND current_user_key = ?';
  //       whereArgs.add(ashaUniqueKey);
  //     }
  //
  //     final List<Map<String, dynamic>> rows = await db.query(
  //       'beneficiaries_new',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //     );
  //
  //     int childCount = 0;
  //
  //     for (final row in rows) {
  //       try {
  //         final info = row['beneficiary_info'] is String
  //             ? jsonDecode(row['beneficiary_info'] as String)
  //             : row['beneficiary_info'];
  //
  //         if (info is! Map) continue;
  //
  //         // Match the exact same criteria as RegisterChildListScreen
  //         final memberType = (info['memberType']?.toString() ?? '').toLowerCase();
  //         final relation = (info['relation']?.toString() ?? '').toLowerCase();
  //         final name = info['name']?.toString() ??
  //                     info['memberName']?.toString() ??
  //                     info['member_name']?.toString() ?? '';
  //
  //         // Only count if it's a child and has a name
  //         if ((memberType == 'child' ||
  //              relation == 'child' ||
  //              relation == 'son' ||
  //              relation == 'daughter') &&
  //             name.isNotEmpty) {
  //           childCount++;
  //         }
  //       } catch (e) {
  //         developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
  //         continue;
  //       }
  //     }
  //
  //     developer.log('Found $childCount registered child beneficiaries', name: 'ChildCareCountProvider');
  //     return childCount;
  //
  //   } catch (e, stackTrace) {
  //     developer.log('Error in getRegisteredChildCount: $e',
  //                 name: 'ChildCareCountProvider',
  //                 error: e,
  //                 stackTrace: stackTrace);
  //     return 0;
  //   }
  // }
  //
  // Future<int> getRegistrationDueCount() async {
  //   try {
  //     developer.log('Getting registration due count...', name: 'ChildCareCountProvider');
  //     final db = await DatabaseProvider.instance.database;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // First check if child_care_activities table exists
  //     final tables = await db.rawQuery(
  //       "SELECT name FROM sqlite_master WHERE type='table' AND name='child_care_activities'"
  //     );
  //
  //     if (tables.isEmpty) {
  //       developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
  //       return 0;
  //     }
  //
  //     // Get count of children with registration_due status from child_care_activities
  //     String sql = '''
  //       SELECT COUNT(DISTINCT cca.beneficiary_ref_key) as count
  //       FROM child_care_activities cca
  //       INNER JOIN beneficiaries_new bn ON cca.beneficiary_ref_key = bn.unique_key
  //       WHERE cca.child_care_state = ?
  //       AND IFNULL(cca.is_deleted, 0) = 0
  //       AND IFNULL(bn.is_deleted, 0) = 0
  //     ''';
  //     List<Object?> args = ['registration_due'];
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       sql += ' AND cca.current_user_key = ?';
  //       args.add(ashaUniqueKey);
  //     }
  //     final results = await db.rawQuery(sql, args);
  //
  //     final count = results.first['count'] as int? ?? 0;
  //     developer.log('Found $count children due for registration', name: 'ChildCareCountProvider');
  //     return count;
  //
  //   } catch (e, stackTrace) {
  //     developer.log('Error in getRegistrationDueCount: $e',
  //                 name: 'ChildCareCountProvider',
  //                 error: e,
  //                 stackTrace: stackTrace);
  //     return 0;
  //   }
  // }
  //
  // // Get count of child tracking due
  // Future<int> getTrackingDueCount() async {
  //   try {
  //     developer.log('Getting tracking due count...', name: 'ChildCareCountProvider');
  //     final db = await DatabaseProvider.instance.database;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // Check if followup_form_data table exists
  //     final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
  //     if (tables.isEmpty) {
  //       developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
  //       return 0;
  //     }
  //
  //     String whereClause;
  //     List<Object?> whereArgs;
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause = '(form_json LIKE ? OR forms_ref_key = ?) AND current_user_key = ?';
  //       whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6', ashaUniqueKey];
  //     } else {
  //       whereClause = 'form_json LIKE ? OR forms_ref_key = ?';
  //       whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
  //     }
  //
  //     final results = await db.query(
  //       'followup_form_data',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //     );
  //
  //     int count = 0;
  //     final Set<String> seenBeneficiaries = <String>{};
  //     for (final row in results) {
  //       try {
  //         final formJson = row['form_json'] as String?;
  //         if (formJson == null || formJson.isEmpty) continue;
  //
  //         final formData = jsonDecode(formJson);
  //         final formType = formData['form_type']?.toString() ?? '';
  //         final formsRefKey = row['forms_ref_key']?.toString() ?? '';
  //
  //         final isChildRegistration = formType == FollowupFormDataTable.childRegistrationDue;
  //         final isChildTracking = formsRefKey == '30bycxe4gv7fqnt6' || formType == FollowupFormDataTable.childTrackingDue;
  //         if (!isChildRegistration && !isChildTracking) {
  //           continue;
  //         }
  //
  //         final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';
  //         if (beneficiaryRefKey.isNotEmpty && seenBeneficiaries.contains(beneficiaryRefKey)) {
  //           continue;
  //         }
  //
  //         if (beneficiaryRefKey.isNotEmpty) {
  //           String ccWhere;
  //           List<Object?> ccArgs;
  //           if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //             ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?';
  //             ccArgs = [beneficiaryRefKey, '%case_closure%', ashaUniqueKey];
  //           } else {
  //             ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
  //             ccArgs = [beneficiaryRefKey, '%case_closure%'];
  //           }
  //           final caseClosureRecords = await db.query(
  //             'followup_form_data',
  //             where: ccWhere,
  //             whereArgs: ccArgs,
  //           );
  //           bool hasCaseClosure = false;
  //           for (final ccRecord in caseClosureRecords) {
  //             try {
  //               final ccFormJson = ccRecord['form_json'] as String?;
  //               if (ccFormJson != null) {
  //                 final ccFormData = jsonDecode(ccFormJson);
  //                 final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
  //                 final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
  //                 if (caseClosure['is_case_closure'] == true) {
  //                   hasCaseClosure = true;
  //                   break;
  //                 }
  //               }
  //             } catch (_) {}
  //           }
  //           if (hasCaseClosure) {
  //             continue;
  //           }
  //         }
  //
  //         if (beneficiaryRefKey.isNotEmpty) {
  //           seenBeneficiaries.add(beneficiaryRefKey);
  //         }
  //         count++;
  //       } catch (e) {
  //         developer.log('Error processing form data: $e', name: 'ChildCareCountProvider');
  //         continue;
  //       }
  //     }
  //
  //     developer.log('Found $count child tracking due records', name: 'ChildCareCountProvider');
  //     return count;
  //
  //   } catch (e, stackTrace) {
  //     developer.log('Error in getTrackingDueCount: $e',
  //                 name: 'ChildCareCountProvider',
  //                 error: e,
  //                 stackTrace: stackTrace);
  //     return 0;
  //   }
  // }
  //
  // Future<int> getHBYCCount() async {
  //   try {
  //     developer.log('Getting HBYC count...', name: 'ChildCareCountProvider');
  //     final db = await DatabaseProvider.instance.database;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // First, get all child beneficiaries
  //     String whereClause = 'is_deleted = ? AND is_adult = ?';
  //     List<Object?> whereArgs = [0, 0];
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause += ' AND current_user_key = ?';
  //       whereArgs.add(ashaUniqueKey);
  //     }
  //     final List<Map<String, dynamic>> rows = await db.query(
  //       'beneficiaries_new',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //     );
  //
  //     int hbycCount = 0;
  //
  //     for (final row in rows) {
  //       try {
  //         final info = row['beneficiary_info'] is String
  //             ? jsonDecode(row['beneficiary_info'] as String)
  //             : row['beneficiary_info'];
  //
  //         if (info is! Map) continue;
  //
  //         final memberType = info['memberType']?.toString() ?? '';
  //         final dob = info['dob']?.toString();
  //
  //         // Count only child members with age between 3-15 months
  //         if (memberType == 'Child' && _isAgeInRange(dob)) {
  //           final beneficiaryRefKey = row['unique_key']?.toString() ?? '';
  //           if (beneficiaryRefKey.isNotEmpty) {
  //             String ccWhere;
  //             List<Object?> ccArgs;
  //             if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //               ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?';
  //               ccArgs = [beneficiaryRefKey, '%case_closure%', ashaUniqueKey];
  //             } else {
  //               ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
  //               ccArgs = [beneficiaryRefKey, '%case_closure%'];
  //             }
  //             final caseClosureRecords = await db.query(
  //               'followup_form_data',
  //               where: ccWhere,
  //               whereArgs: ccArgs,
  //             );
  //             bool hasCaseClosure = false;
  //             for (final ccRecord in caseClosureRecords) {
  //               try {
  //                 final ccFormJson = ccRecord['form_json'] as String?;
  //                 if (ccFormJson != null) {
  //                   final ccFormData = jsonDecode(ccFormJson);
  //                   final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
  //                   final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
  //                   if (caseClosure['is_case_closure'] == true) {
  //                     hasCaseClosure = true;
  //                     break;
  //                   }
  //                 }
  //               } catch (_) {}
  //             }
  //             if (hasCaseClosure) {
  //               continue;
  //             }
  //           }
  //           hbycCount++;
  //         }
  //       } catch (e) {
  //         developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
  //         continue;
  //       }
  //     }
  //
  //     developer.log('Found $hbycCount HBYC children', name: 'ChildCareCountProvider');
  //     return hbycCount;
  //
  //   } catch (e, stackTrace) {
  //     developer.log('Error in getHBYCCount: $e',
  //         name: 'ChildCareCountProvider',
  //         error: e,
  //         stackTrace: stackTrace);
  //     return 0;
  //   }
  // }
  //
  // // Get count of deceased children
  // Future<int> getDeceasedCount() async {
  //   try {
  //     final db = await DatabaseProvider.instance.database;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // First try to get from followup_form_data
  //     try {
  //       final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
  //       if (tables.isNotEmpty) {
  //         String sql = '''
  //           SELECT COUNT(DISTINCT beneficiary_ref_key) as count
  //           FROM followup_form_data
  //           WHERE (form_json LIKE '%"reason_of_death":%'
  //                 OR form_json LIKE '%"reason_of_death"%')
  //           AND is_deleted = 0
  //         ''';
  //         List<Object?> args = [];
  //         if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //           sql += ' AND current_user_key = ?';
  //           args.add(ashaUniqueKey);
  //         }
  //         final count = await db.rawQuery(sql, args);
  //
  //         final result = count.first['count'] as int? ?? 0;
  //         if (result > 0) {
  //           developer.log('Found $result deceased children in followup_form_data', name: 'ChildCareCountProvider');
  //           return result;
  //         }
  //       }
  //     } catch (e) {
  //       developer.log('Error checking followup_form_data: $e', name: 'ChildCareCountProvider');
  //     }
  //
  //     // Fallback to beneficiaries table
  //     try {
  //       String sql = '''
  //         SELECT COUNT(*) as count
  //         FROM beneficiaries_new
  //         WHERE is_death = 1
  //         AND is_deleted = 0
  //       ''';
  //       List<Object?> args = [];
  //       if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //         sql += ' AND current_user_key = ?';
  //         args.add(ashaUniqueKey);
  //       }
  //       final count = await db.rawQuery(sql, args);
  //
  //       final result = count.first['count'] as int? ?? 0;
  //       developer.log('Found $result deceased children in beneficiaries table', name: 'ChildCareCountProvider');
  //       return result;
  //
  //     } catch (e) {
  //       developer.log('Error checking beneficiaries table: $e', name: 'ChildCareCountProvider');
  //       return 0;
  //     }
  //
  //   } catch (e, stackTrace) {
  //     developer.log('Error in getDeceasedCount: $e',
  //         name: 'ChildCareCountProvider',
  //         error: e,
  //         stackTrace: stackTrace);
  //     return 0;
  //   }
  // }


   Future<Map<String, int>> getRegisteredChildCountTotalAndSync() async {
    try {
      developer.log('Getting registered child count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String whereClause = 'is_deleted = ? AND is_adult = ?';
      List<dynamic> whereArgs = [0, 0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
      );

      int childCount = 0;
      int childCountIsSync = 0;

      for (final row in rows) {
        try {
          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = (info['memberType']?.toString() ?? '').toLowerCase();
          final relation = (info['relation']?.toString() ?? '').toLowerCase();
          final name = info['name']?.toString() ??
              info['memberName']?.toString() ??
              info['member_name']?.toString() ??
              '';

          final isSynced = row['is_synced'] ?? 0;

          if ((memberType == 'child' ||
              relation == 'child' ||
              relation == 'son' ||
              relation == 'daughter') &&
              name.isNotEmpty) {

            childCount++;
            if (isSynced == 1) {
              childCountIsSync++;
            }
          }
        } catch (e) {
          developer.log('Error processing beneficiary: $e',
              name: 'ChildCareCountProvider');
        }
      }

      return {
        'total': childCount,
        'synced': childCountIsSync,
      };

    } catch (e, stackTrace) {
      developer.log('Error in getRegisteredChildCount: $e',
          name: 'ChildCareCountProvider',
          error: e,
          stackTrace: stackTrace);

      return {
        'total': 0,
        'synced': 0,
      };
    }
  }

   Future<int> getRegisteredChildCount() async {
    try {
      developer.log('Getting registered child count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Get current user's unique key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // Build where clause based on whether we have a user key
      String whereClause = 'is_deleted = ? AND is_adult = ?';
      List<dynamic> whereArgs = [0, 0]; // is_deleted = 0, is_adult = 0 (child)
      
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      // Get child beneficiaries for current user
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
      );

      int childCount = 0;
      int childCountIsSync = 0;

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
  //////

  Future<int> getRegistrationDueCount() async {
    try {
      developer.log('Getting registration due count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;

      // Get current user's unique key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Check if table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='child_care_activities'"
      );
      if (tables.isEmpty) {
        developer.log('child_care_activities table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }

      // Build WHERE clause like _loadChildBeneficiaries
      String whereClause = 'child_care_state = ? AND is_deleted = ?';
      List<dynamic> whereArgs = ['registration_due', 0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final List<Map<String, dynamic>> childActivities = await db.query(
        'child_care_activities',
        where: whereClause,
        whereArgs: whereArgs,
      );

      developer.log('Found ${childActivities.length} child care activities with registration_due status',
          name: 'ChildCareCountProvider');

      if (childActivities.isEmpty) return 0;

      int validChildCount = 0;

      // Process each activity
      for (final activity in childActivities) {
        final beneficiaryRefKey = activity['beneficiary_ref_key']?.toString();
        if (beneficiaryRefKey == null) continue;

        final List<Map<String, dynamic>> beneficiaryRows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ?',
          whereArgs: [beneficiaryRefKey],
          limit: 1,
        );

        if (beneficiaryRows.isEmpty) continue;

        final row = beneficiaryRows.first;

        dynamic info;
        try {
          info = (row['beneficiary_info'] is String)
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];
        } catch (e) {
          developer.log('Error parsing beneficiary_info: $e', name: 'ChildCareCountProvider');
          continue;
        }

        if (info is! Map) continue;

        final memberData = Map<String, dynamic>.from(info);
        final memberType = (memberData['memberType']?.toString() ?? '').trim().toLowerCase();

        if (memberType != 'child') continue;

        final name = memberData['memberName']?.toString() ??
            memberData['name']?.toString() ??
            memberData['member_name']?.toString() ??
            memberData['memberNameLocal']?.toString() ??
            memberData['Name']?.toString() ??
            '';

        if (name.isEmpty) continue;

        // ✅ Use beneficiaryRefKey instead of householdRefKey
        final isAlreadyRegistered = await _isChildRegistered(db, beneficiaryRefKey, name);

        if (!isAlreadyRegistered) validChildCount++;
      }

      developer.log('FINAL REGISTRATION DUE COUNT = $validChildCount', name: 'ChildCareCountProvider');
      return validChildCount;

    } catch (e, stackTrace) {
      developer.log('Error in getRegistrationDueCount: $e',
          name: 'ChildCareCountProvider',
          error: e,
          stackTrace: stackTrace);
      return 0;
    }
  }


  Future<bool> _isChildRegistered(Database db, String beneficiaryRefKey, String childName) async {
    try {
      final normalizedSearchName = childName.trim().toLowerCase();
      debugPrint('\n🔍 Checking registration for child: "$childName" with beneficiary_ref_key: "$beneficiaryRefKey"');

      // Query followup_form_data only for this beneficiary_ref_key
      final results = await db.query(
        'followup_form_data',
        where: 'beneficiary_ref_key = ? AND (form_json LIKE ? OR form_json LIKE ?)',
        whereArgs: [
          beneficiaryRefKey,
          '%"form_type":"child_registration_due"%',
          '%"child_registration_due_form"%'
        ],
      );

      debugPrint('📊 Found ${results.length} child registration forms for beneficiary: $beneficiaryRefKey');

      if (results.isNotEmpty) {
        for (final row in results) {
          try {
            final formJson = row['form_json'] as String?;
            if (formJson == null || formJson.isEmpty) continue;

            final formData = jsonDecode(formJson);
            final formType = (formData['form_type']?.toString() ?? '').toLowerCase();
            final hasChildRegistrationForm = formData['child_registration_due_form'] is Map;

            if (formType != 'child_registration_due' && !hasChildRegistrationForm) continue;

            Map<String, dynamic> formDataMap;
            if (hasChildRegistrationForm) {
              formDataMap = formData['child_registration_due_form'] as Map<String, dynamic>;
            } else if (formData['form_data'] is Map) {
              formDataMap = formData['form_data'] as Map<String, dynamic>;
            } else {
              continue;
            }

            final childNameInForm = formDataMap['name_of_child']?.toString() ??
                formDataMap['child_name']?.toString() ?? '';

            if (childNameInForm.trim().toLowerCase() == normalizedSearchName) {
              debugPrint('✅ MATCH FOUND! Child already registered');
              return true;
            }
          } catch (e) {
            debugPrint('❌ Error parsing form data: $e');
            continue;
          }
        }
      }

      debugPrint('✅ No existing registration found for child: "$childName"');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking registration: $e');
      return false;
    }
  }
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Future<int> getTrackingDueCount() async {
  //   try {
  //     developer.log('Getting tracking due count...', name: 'ChildCareCountProvider');
  //
  //     final db = await DatabaseProvider.instance.database;
  //
  //     // Check if table exists
  //     final tables = await db.rawQuery(
  //         "SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
  //     if (tables.isEmpty) {
  //       developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
  //       return 0;
  //     }
  //
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     /// Match filtering logic from _loadChildTrackingData()
  //     String whereClause;
  //     List<Object?> whereArgs;
  //
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause = '(form_json LIKE ? OR forms_ref_key = ?)';
  //       whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
  //     } else {
  //       whereClause = 'form_json LIKE ? OR forms_ref_key = ?';
  //       whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
  //     }
  //
  //     final results = await db.query(
  //       'followup_form_data',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //       orderBy: 'id DESC',
  //     );
  //
  //     int count = 0;
  //     final Set<String> seenBeneficiaries = <String>{};
  //
  //     for (final row in results) {
  //       try {
  //         final formJsonStr = row['form_json'] as String?;
  //         if (formJsonStr == null || formJsonStr.isEmpty) continue;
  //
  //         final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';
  //         if (beneficiaryRefKey.isEmpty) {
  //           continue;
  //         }
  //
  //         // Check if beneficiary is marked as deceased in beneficiaries_new table
  //         final beneficiary = await db.query(
  //           'beneficiaries_new',
  //           where: 'unique_key = ? AND (is_death IS NULL OR is_death = 0)',
  //           whereArgs: [beneficiaryRefKey],
  //           limit: 1,
  //         );
  //
  //         // Skip if beneficiary not found or is marked as deceased (is_death = 1)
  //         if (beneficiary.isEmpty) {
  //           developer.log('Skipping deceased or non-existent beneficiary: $beneficiaryRefKey',
  //               name: 'ChildCareCountProvider');
  //           continue;
  //         }
  //
  //         final formJson = jsonDecode(formJsonStr);
  //
  //         // Rest of your existing form processing logic...
  //         String formType = '';
  //         final formsRefKey = row['forms_ref_key']?.toString() ?? '';
  //
  //         if (formJson['form_type'] != null) {
  //           formType = formJson['form_type'].toString();
  //         } else if (formJson['child_registration_due_form'] is Map) {
  //           formType = 'child_registration_due';
  //         } else if (formJson is Map && formJson.isNotEmpty) {
  //           final firstKey = formJson.keys.first;
  //           if (firstKey.toString().contains('child_registration') ||
  //               firstKey.toString().contains('child_tracking')) {
  //             formType = firstKey.toString();
  //           }
  //         }
  //
  //         // Apply registration/tracking filtering like load function
  //         final isChildRegistration =
  //             formType == FollowupFormDataTable.childRegistrationDue ||
  //                 formType == 'child_registration_due';
  //
  //         final isChildTracking =
  //             formsRefKey == '30bycxe4gv7fqnt6' ||
  //                 formType == FollowupFormDataTable.childTrackingDue ||
  //                 formType == 'child_tracking_due';
  //
  //         if (!isChildRegistration && !isChildTracking) {
  //           continue;
  //         }
  //
  //         if (beneficiaryRefKey.isNotEmpty && seenBeneficiaries.contains(beneficiaryRefKey)) {
  //           continue;
  //         }
  //
  //         // Case closure check
  //         if (beneficiaryRefKey.isNotEmpty) {
  //           final caseClosureWhere =
  //           (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
  //               ? 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?'
  //               : 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
  //
  //           final caseClosureArgs =
  //           (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
  //               ? [beneficiaryRefKey, '%case_closure%', ashaUniqueKey]
  //               : [beneficiaryRefKey, '%case_closure%'];
  //
  //           final caseClosureRecords = await db.query(
  //             'followup_form_data',
  //             where: caseClosureWhere,
  //             whereArgs: caseClosureArgs,
  //           );
  //
  //           bool hasCaseClosure = false;
  //
  //           for (final ccRecord in caseClosureRecords) {
  //             try {
  //               final ccJson = ccRecord['form_json'] as String?;
  //               if (ccJson != null) {
  //                 final ccForm = jsonDecode(ccJson);
  //                 final ccData = ccForm['form_data'] as Map<String, dynamic>? ?? {};
  //                 final closure = ccData['case_closure'] as Map<String, dynamic>? ?? {};
  //
  //                 if (closure['is_case_closure'] == true) {
  //                   hasCaseClosure = true;
  //                   break;
  //                 }
  //               }
  //             } catch (_) {}
  //           }
  //
  //           if (hasCaseClosure) {
  //             continue;
  //           }
  //         }
  //
  //         // Mark beneficiary as counted
  //         if (beneficiaryRefKey.isNotEmpty) {
  //           seenBeneficiaries.add(beneficiaryRefKey);
  //         }
  //
  //         count++;
  //
  //       } catch (e) {
  //         developer.log('Error parsing record: $e', name: 'ChildCareCountProvider');
  //       }
  //     }
  //
  //     developer.log('Final due count = $count', name: 'ChildCareCountProvider');
  //
  //     return count;
  //
  //   } catch (e, stackTrace) {
  //     developer.log(
  //       'Error in getTrackingDueCount: $e',
  //       name: 'ChildCareCountProvider',
  //       error: e,
  //       stackTrace: stackTrace,
  //     );
  //     return 0;
  //   }
  // }
  Future<int> getTrackingDueCount() async {
    try {
      developer.log('Getting tracking due count...', name: 'ChildCareCountProvider');

      final db = await DatabaseProvider.instance.database;

      // Check if table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'");
      if (tables.isEmpty) {
        developer.log('followup_form_data table does not exist', name: 'ChildCareCountProvider');
        return 0;
      }

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      /// Match filtering logic from _loadChildTrackingData()
      String whereClause;
      List<Object?> whereArgs;

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause = '(form_json LIKE ? OR forms_ref_key = ?)';
        whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
      } else {
        whereClause = 'form_json LIKE ? OR forms_ref_key = ?';
        whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];
      }

      final results = await db.query(
        'followup_form_data',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'id DESC',
      );

      developer.log('Found ${results.length} child registration/tracking records after filtering',
          name: 'ChildCareCountProvider');

      int count = 0;
      final Set<String> seenBeneficiaries = <String>{};

      for (final row in results) {
        try {
          final formJsonStr = row['form_json'] as String?;
          if (formJsonStr == null || formJsonStr.isEmpty) {
            continue;
          }

          final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';
          if (beneficiaryRefKey.isEmpty) {
            continue;
          }

          // CRITICAL: Check if beneficiary is marked as deceased AND belongs to current user
          // This matches the load function exactly
          final beneficiaryWhere = (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
              ? 'unique_key = ? AND (is_death IS NULL OR is_death = 0) AND current_user_key = ?'
              : 'unique_key = ? AND (is_death IS NULL OR is_death = 0)';

          final beneficiaryArgs = (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
              ? [beneficiaryRefKey, ashaUniqueKey]
              : [beneficiaryRefKey];

          final beneficiary = await db.query(
            'beneficiaries_new',
            where: beneficiaryWhere,
            whereArgs: beneficiaryArgs,
            limit: 1,
          );

          // Skip if beneficiary not found or is marked as deceased (is_death = 1)
          if (beneficiary.isEmpty) {
            continue;
          }

          final formJson = jsonDecode(formJsonStr);

          // Determine form type
          String formType = '';
          final formsRefKey = row['forms_ref_key']?.toString() ?? '';

          if (formJson['form_type'] != null) {
            formType = formJson['form_type'].toString();
          } else if (formJson['child_registration_due_form'] is Map) {
            formType = 'child_registration_due';
          } else if (formJson is Map && formJson.isNotEmpty) {
            final firstKey = formJson.keys.first;
            if (firstKey.toString().contains('child_registration') ||
                firstKey.toString().contains('child_tracking')) {
              formType = firstKey.toString();
            }
          }

          // Apply registration/tracking filtering like load function
          final isChildRegistration =
              formType == FollowupFormDataTable.childRegistrationDue ||
                  formType == 'child_registration_due';

          final isChildTracking =
              formsRefKey == '30bycxe4gv7fqnt6' ||
                  formType == FollowupFormDataTable.childTrackingDue ||
                  formType == 'child_tracking_due';

          if (!isChildRegistration && !isChildTracking) {
            continue;
          }

          // Extract child name to match load function's validation
          Map<String, dynamic> formDataMap = {};

          if (formJson['form_data'] is String) {
            try {
              formDataMap = jsonDecode(formJson['form_data']);
            } catch (e) {
              // Try parsing from nested structure
              if (formJson is Map && formJson.isNotEmpty) {
                if (formJson['child_registration_due_form'] is Map) {
                  formDataMap = Map<String, dynamic>.from(formJson['child_registration_due_form']);
                } else {
                  final firstKey = formJson.keys.first;
                  if (firstKey != null && formJson[firstKey] is Map) {
                    formDataMap = Map<String, dynamic>.from(formJson[firstKey]);
                  }
                }
              }
            }
          } else if (formJson['form_data'] is Map) {
            formDataMap = Map<String, dynamic>.from(formJson['form_data'] as Map);
          } else if (formJson.containsKey('child_name')) {
            formDataMap = Map<String, dynamic>.from(formJson);
          } else if (formJson['formData'] is Map) {
            formDataMap = Map<String, dynamic>.from(formJson['formData'] as Map);
          } else if (formJson is Map && formJson.isNotEmpty) {
            if (formJson['child_registration_due_form'] is Map) {
              formDataMap = Map<String, dynamic>.from(formJson['child_registration_due_form']);
            } else {
              final firstKey = formJson.keys.first;
              if (firstKey != null && formJson[firstKey] is Map) {
                formDataMap = Map<String, dynamic>.from(formJson[firstKey]);
              }
            }
          }

          // Extract child name exactly like load function
          final childName = formDataMap['name_of_child']?.toString()?.trim() ??
              formDataMap['child_name']?.toString()?.trim() ?? '';

          // Skip if child name is empty (matches load function)
          if (childName.isEmpty) {
            continue;
          }

          // De-duplicate check
          if (beneficiaryRefKey.isNotEmpty && seenBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }

          // Case closure check
          if (beneficiaryRefKey.isNotEmpty) {
            final caseClosureWhere =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
                ? 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?'
                : 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';

            final caseClosureArgs =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
                ? [beneficiaryRefKey, '%case_closure%', ashaUniqueKey]
                : [beneficiaryRefKey, '%case_closure%'];

            final caseClosureRecords = await db.query(
              'followup_form_data',
              where: caseClosureWhere,
              whereArgs: caseClosureArgs,
            );

            bool hasCaseClosure = false;

            for (final ccRecord in caseClosureRecords) {
              try {
                final ccJson = ccRecord['form_json'] as String?;
                if (ccJson != null) {
                  final ccForm = jsonDecode(ccJson);
                  final ccData = ccForm['form_data'] as Map<String, dynamic>? ?? {};
                  final closure = ccData['case_closure'] as Map<String, dynamic>? ?? {};

                  if (closure['is_case_closure'] == true) {
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

          // Mark beneficiary as counted and increment
          if (beneficiaryRefKey.isNotEmpty) {
            seenBeneficiaries.add(beneficiaryRefKey);
          }

          count++;

        } catch (e) {
          developer.log('Error parsing record: $e', name: 'ChildCareCountProvider');
        }
      }

      developer.log('FINAL TRACKING DUE COUNT = $count', name: 'ChildCareCountProvider');

      return count;

    } catch (e, stackTrace) {
      developer.log(
        'Error in getTrackingDueCount: $e',
        name: 'ChildCareCountProvider',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  // Future<int> getHBYCCount() async {
  //   try {
  //     final db = await DatabaseProvider.instance.database;
  //
  //     // Get current user's unique key
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     // Build where clause based on whether we have a user key
  //     String whereClause = 'is_deleted = ? AND is_adult = ?';
  //     List<dynamic> whereArgs = [0, 0];
  //
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause += ' AND current_user_key = ?';
  //       whereArgs.add(ashaUniqueKey);
  //     }
  //
  //     final rows = await db.query(
  //       'beneficiaries_new',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //     );
  //
  //     int hbycCount = 0;
  //
  //     for (final row in rows) {
  //       try {
  //         final info = row['beneficiary_info'] is String
  //             ? jsonDecode(row['beneficiary_info'] as String)
  //             : row['beneficiary_info'];
  //
  //         if (info is! Map) continue;
  //
  //         final memberType = info['memberType']?.toString().toLowerCase() ?? '';
  //         final dob = info['date_of_birth']?.toString() ?? info['dob']?.toString();
  //
  //         // Add debug logging
  //         developer.log('HBYC Check - Member: ${info['name'] ?? 'No name'}, '
  //             'Type: $memberType, DOB: $dob',
  //             name: 'HBYCCount');
  //
  //         // Count only child members with age between 3-15 months
  //         if (memberType == 'child' && _isAgeInRange(dob)) {
  //           hbycCount++;
  //           developer.log('HBYC Count incremented. Current count: $hbycCount',
  //               name: 'HBYCCount');
  //         }
  //       } catch (e) {
  //         developer.log('Error in HBYC count: $e', name: 'HBYCCount');
  //       }
  //     }
  //
  //     return hbycCount;
  //   } catch (e) {
  //     developer.log('Error in getHBYCCount: $e', name: 'HBYCCount');
  //     return 0;
  //   }
  // }

// Add this helper method if not exists

  Future<int> getHBYCCount() async {
    try {
      developer.log('Getting HBYC count...', name: 'ChildCareCountProvider');

      final db = await DatabaseProvider.instance.database;

      // Get current user's unique key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Build where clause exactly like _loadHBYCChildren
      String whereClause = 'is_deleted = ? AND is_adult = ?';
      List<dynamic> whereArgs = [0, 0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      // Get child beneficiaries for current user
      final rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
      );

      developer.log('Found ${rows.length} child beneficiaries in database', name: 'ChildCareCountProvider');

      int hbycCount = 0;

      for (final row in rows) {
        try {
          // Check household_ref_key like load function does
          final rowHhId = row['household_ref_key']?.toString();
          if (rowHhId == null || rowHhId.isEmpty) {
            continue;
          }

          // Parse beneficiary info exactly like load function
          Map<String, dynamic> info = {};
          try {
            if (row['beneficiary_info'] is String) {
              info = jsonDecode(row['beneficiary_info'] as String);
            } else if (row['beneficiary_info'] is Map) {
              info = Map<String, dynamic>.from(row['beneficiary_info'] as Map);
            }
          } catch (e) {
            developer.log('Error parsing beneficiary_info: $e', name: 'ChildCareCountProvider');
            continue;
          }

          // Get child details
          final dob = info['date_of_birth']?.toString() ??
              info['dob']?.toString();

          // Only count children between 3-15 months
          if (!_isAgeInRange(dob)) {
            continue;
          }

          // Get beneficiary ID
          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) {
            continue;
          }

          // Check if case is closed for this beneficiary (inline implementation)
          final caseClosureWhere = (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
              ? 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?'
              : 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';

          final caseClosureArgs = (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
              ? [beneficiaryId, '%case_closure%', ashaUniqueKey]
              : [beneficiaryId, '%case_closure%'];

          final caseClosureRecords = await db.query(
            'followup_form_data',
            where: caseClosureWhere,
            whereArgs: caseClosureArgs,
          );

          bool isCaseClosed = false;
          for (final ccRecord in caseClosureRecords) {
            try {
              final ccFormJson = ccRecord['form_json'] as String?;
              if (ccFormJson != null) {
                final ccFormData = jsonDecode(ccFormJson);
                final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
                final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
                if (caseClosure['is_case_closure'] == true) {
                  isCaseClosed = true;
                  break;
                }
              }
            } catch (e) {
              developer.log('Error checking case closure: $e', name: 'ChildCareCountProvider');
            }
          }

          if (isCaseClosed) {
            developer.log('Skipping closed case for beneficiary: $beneficiaryId', name: 'ChildCareCountProvider');
            continue;
          }

          // Get name from multiple possible fields (inline implementation)
          String name = '';
          final nameFields = ['name', 'child_name', 'memberName', 'member_name', 'memberNameLocal'];
          for (final field in nameFields) {
            if (info[field] != null && info[field].toString().trim().isNotEmpty) {
              name = info[field].toString().trim();
              break;
            }
          }

          // Load function creates card with 'Unnamed Child' as fallback,
          // so we count children even without names

          // Increment count
          hbycCount++;

          developer.log('HBYC child counted: ${name.isNotEmpty ? name : "Unnamed Child"} (ID: $beneficiaryId)',
              name: 'ChildCareCountProvider');

        } catch (e) {
          developer.log('Error processing beneficiary: $e', name: 'ChildCareCountProvider');
        }
      }

      developer.log('FINAL HBYC COUNT = $hbycCount', name: 'ChildCareCountProvider');
      return hbycCount;

    } catch (e, stackTrace) {
      developer.log('Error in getHBYCCount: $e',
          name: 'ChildCareCountProvider',
          error: e,
          stackTrace: stackTrace);
      return 0;
    }
  }

  bool _isAgeInRange(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return false;

    try {
      final dob = DateTime.tryParse(dobStr);
      if (dob == null) return false;

      final now = DateTime.now();
      final ageInMonths = (now.year - dob.year) * 12 + (now.month - dob.month);

      // Check if age is between 3 and 15 months
      final isInRange = ageInMonths >= 3 && ageInMonths <= 15;
      developer.log('Age check - DOB: $dobStr, Age in months: $ageInMonths, In range (3-15): $isInRange',
          name: 'AgeCheck');
      return isInRange;
    } catch (e) {
      developer.log('Error in _isAgeInRange: $e', name: 'AgeCheck');
      return false;
    }
  }
  // // Helper method to check if age is in HBYC range (3-15 months)
  // bool _isAgeInRange(String? dobStr) {
  //   if (dobStr == null || dobStr.isEmpty) return false;
  //
  //   try {
  //     final dob = DateTime.tryParse(dobStr);
  //     if (dob == null) return false;
  //
  //     final now = DateTime.now();
  //     final ageInMonths = (now.year - dob.year) * 12 + (now.month - dob.month);
  //
  //     // Check if age is between 3 and 15 months
  //     return ageInMonths >= 3 && ageInMonths <= 15;
  //   } catch (e) {
  //     developer.log('Error calculating age: $e', name: 'ChildCareCountProvider');
  //     return false;
  //   }
  // }

  // Get count of deceased children
  Future<int> getDeceasedCount() async {
    try {
      developer.log('Getting deceased count...', name: 'ChildCareCountProvider');
      final db = await DatabaseProvider.instance.database;
      
      // Get current user's unique key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      // Build where clause based on whether we have a user key
      String whereClause = 'is_deleted = ? AND is_adult = ? AND is_death = ?';
      List<dynamic> whereArgs = [0, 0, 1]; // is_deleted = 0, is_adult = 0, is_death = 1
      
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      // Get count of deceased children for current user
      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
      );

      int deceasedCount = 0;

      for (final row in rows) {
        try {
          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString() ?? '';
          final relation = info['relation']?.toString() ?? '';
          final name = info['name']?.toString() ??
              info['memberName']?.toString() ??
              info['member_name']?.toString() ?? '';

          // Only count if it's a child and has a name
          if ((memberType.toLowerCase() == 'child' ||
              relation.toLowerCase() == 'child' ||
              relation.toLowerCase() == 'son' ||
              relation.toLowerCase() == 'daughter') &&
              name.isNotEmpty) {
            deceasedCount++;
          }
        } catch (e) {
          developer.log('Error processing deceased beneficiary: $e', name: 'ChildCareCountProvider');
          continue;
        }
      }

      developer.log('Found $deceasedCount deceased children', name: 'ChildCareCountProvider');
      return deceasedCount;

    } catch (e, stackTrace) {
      developer.log('Error in getDeceasedCount: $e',
          name: 'ChildCareCountProvider',
          error: e,
          stackTrace: stackTrace);
      return 0;
    }
  }
  // Calculate age in months from date of birth
  // int _calculateAgeInMonths(String? dobStr) {
  //   if (dobStr == null || dobStr.isEmpty) return 0;
  //
  //   try {
  //     final dob = DateTime.parse(dobStr);
  //     final now = DateTime.now();
  //     final months = (now.year - dob.year) * 12 + now.month - dob.month;
  //     return months;
  //   } catch (e) {
  //     developer.log('Error calculating age for DOB: $dobStr - $e', name: 'ChildCareCountProvider');
  //     return 0;
  //   }
  // }

  // Check if age is between 3 and 15 months
  // bool _isAgeInRange(String? dobStr) {
  //   final months = _calculateAgeInMonths(dobStr);
  //   return months >= 3 && months <= 15;
  // }

  // Get count of HBYC (Home Based Young Child) list

}
