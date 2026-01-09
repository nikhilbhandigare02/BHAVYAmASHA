import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../core/config/Constant/constant.dart';
import '../../data/Database/database_provider.dart';
import '../../l10n/app_localizations.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _isLoading = true;
  DateTime? _lastSyncedAt;

  String _formatDateTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.day)}-${_twoDigits(dateTime.month)}-${dateTime.year} ${_formatTime(dateTime)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'am' : 'pm';
    return '${_twoDigits(hour)}:${_twoDigits(dateTime.minute)}$period';
  }

  int _householdTotal = 0;
  int _householdSynced = 0;
  int _beneficiaryTotal = 0;
  int _beneficiarySynced = 0;
  int _followupTotal = 0;
  int _followupSynced = 0;
  int _eligibleCoupleTotal = 0;
  int _eligibleCoupleSynced = 0;
  int _motherCareTotal = 0;
  int _motherCareSynced = 0;
  int _childCareTotal = 0;
  int _childCareSynced = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

// In SyncStatusScreen.dart
  Future<void> _loadCounts() async {
    try {
      final dao = LocalStorageDao();
      final lastSyncTime = await dao.getLastSyncTime();
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Get household counts directly from households table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        _loadHouseholdCount();
        // Get total household count for current user
      /*  final householdTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _householdTotal = householdTotalResult.first['count'] as int? ?? 0;
*/
        // Get synced household count for current user
        /*final householdSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _householdSynced = householdSyncedResult.first['count'] as int? ?? 0;*/
      }
      // else {
      //   // Get total household count for all users
      //   final householdTotalResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0',
      //   );
      //   _householdTotal = householdTotalResult.first['count'] as int? ?? 0;
      //
      //   // Get synced household count for all users
      //   final householdSyncedResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND is_synced = 1',
      //   );
      //   _householdSynced = householdSyncedResult.first['count'] as int? ?? 0;
      // }

      // Get beneficiary counts directly from beneficiaries_new table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        // Get total beneficiary count for current user
        final beneficiaryTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND current_user_key = ? AND is_migrated == 0',
          [ashaUniqueKey],
        );
        _beneficiaryTotal = beneficiaryTotalResult.first['count'] as int? ?? 0;

        // Get synced beneficiary count for current user
        final beneficiarySyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ? AND is_migrated == 0',
          [ashaUniqueKey],
        );
        _beneficiarySynced = beneficiarySyncedResult.first['count'] as int? ?? 0;
      }
      // else {
      //   // Get total beneficiary count for all users
      //   final beneficiaryTotalResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0',
      //   );
      //   _beneficiaryTotal = beneficiaryTotalResult.first['count'] as int? ?? 0;
      //
      //   // Get synced beneficiary count for all users
      //   final beneficiarySyncedResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND is_synced = 1',
      //   );
      //   _beneficiarySynced = beneficiarySyncedResult.first['count'] as int? ?? 0;
      // }

      // Get eligible couple counts directly from the table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        _loadEligibleCouplesCount();
        /*final eligibleTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _eligibleCoupleTotal = eligibleTotalResult.first['count'] as int? ?? 0;
sfgfdd
        // Get synced count
        final eligibleSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _eligibleCoupleSynced = eligibleSyncedResult.first['count'] as int? ?? 0;*/
      }
      // else {
      //   final eligibleTotalResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0',
      //   );
      //   _eligibleCoupleTotal = eligibleTotalResult.first['count'] as int? ?? 0;
      //
      //   final eligibleSyncedResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND is_synced = 1',
      //   );
      //   _eligibleCoupleSynced = eligibleSyncedResult.first['count'] as int? ?? 0;
      // }

      // Get mother care counts directly from the table
      // Get total count
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
       // getMotherCareTotalCount();
        final totalResult = await db.rawQuery(
          'SELECT COUNT(*) AS count FROM ( SELECT DISTINCT beneficiary_ref_key, mother_care_state FROM mother_care_activities WHERE is_deleted = 0 AND current_user_key = ?) AS t;',
          [ashaUniqueKey],
        );
        _motherCareTotal = totalResult.first['count'] as int? ?? 0;

        // Get synced count
        final syncedResult = await db.rawQuery(
          'SELECT COUNT(*) AS count FROM ( SELECT DISTINCT beneficiary_ref_key, mother_care_state FROM mother_care_activities WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?) AS t;',
          [ashaUniqueKey],
        );
        _motherCareSynced = syncedResult.first['count'] as int? ?? 0;
      }

      // else {
      //   final totalResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0',
      //   );
      //   _motherCareTotal = totalResult.first['count'] as int? ?? 0;
      //
      //   final syncedResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0 AND is_synced = 1',
      //   );
      //   _motherCareSynced = syncedResult.first['count'] as int? ?? 0;
      // }

      // Get child care counts directly from the table
      // Get total count
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        final childTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _childCareTotal = childTotalResult.first['count'] as int? ?? 0;

        // Get synced count
        final childSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities WHERE is_deleted = 0 AND  is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _childCareSynced = childSyncedResult.first['count'] as int? ?? 0;
      }
      // else {
      //   final childTotalResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM child_care_activities',
      //   );
      //   _childCareTotal = childTotalResult.first['count'] as int? ?? 0;
      //
      //   final childSyncedResult = await db.rawQuery(
      //     'SELECT COUNT(*) as count FROM child_care_activities WHERE is_synced = 1',
      //   );
      //   _childCareSynced = childSyncedResult.first['count'] as int? ?? 0;
      // }

      // Get follow-up counts from all records (not filtered by user)
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        // Followup total
        final followupTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE current_user_key = ?',
          [ashaUniqueKey],
        );
        _followupTotal = followupTotalResult.first['count'] as int? ?? 0;

        // Followup synced
        final followupSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _followupSynced = followupSyncedResult.first['count'] as int? ?? 0;
      }


      if (!mounted) return;

      setState(() {
        _lastSyncedAt = lastSyncTime;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sync status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //  Future<int> getMotherCareTotalCount() async {
  //   try {
  //     final db = await DatabaseProvider.instance.database;
  //
  //     final ancDueRecords = await db.rawQuery('''
  //       SELECT DISTINCT mca.beneficiary_ref_key
  //       FROM mother_care_activities mca
  //       INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
  //       WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
  //     ''');
  //
  //     final ancAllRecords = await db.rawQuery('''
  //       SELECT DISTINCT mca.beneficiary_ref_key
  //       FROM mother_care_activities mca
  //       INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
  //       WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
  //     ''');
  //
  //     final Set<String> ancDueBeneficiaryIds = ancDueRecords
  //         .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
  //         .where((id) => id.isNotEmpty)
  //         .toSet();
  //
  //     final deliveryOutcomes = await db.query(
  //       'followup_form_data',
  //       where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND form_json LIKE '%\"gives_birth_to_baby\":\"Yes\"%'",
  //       columns: ['beneficiary_ref_key'],
  //     );
  //
  //     final Set<String?> deliveredBeneficiaryIds = deliveryOutcomes
  //         .map((e) => e['beneficiary_ref_key']?.toString())
  //         .where((id) => id != null && id.isNotEmpty)
  //         .toSet();
  //
  //     final rows = await LocalStorageDao.instance.getAllBeneficiaries();
  //     final Set<String> ancUniqueBeneficiaries = {};
  //     for (final row in rows) {
  //       try {
  //         final dynamic rawInfo = row['beneficiary_info'];
  //         if (rawInfo == null) continue;
  //         Map<String, dynamic> info = rawInfo is String
  //             ? jsonDecode(rawInfo) as Map<String, dynamic>
  //             : Map<String, dynamic>.from(rawInfo as Map);
  //         final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
  //         final gender = info['gender']?.toString().toLowerCase() ?? '';
  //         final beneficiaryId = row['unique_key']?.toString() ?? '';
  //         final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);
  //         if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
  //           continue;
  //         }
  //         if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
  //           if (beneficiaryId.isNotEmpty) {
  //             ancUniqueBeneficiaries.add(beneficiaryId);
  //           }
  //         }
  //       } catch (_) {}
  //     }
  //     for (final id in ancDueBeneficiaryIds) {
  //       if (id.isNotEmpty && !deliveredBeneficiaryIds.contains(id)) {
  //         ancUniqueBeneficiaries.add(id);
  //       }
  //     }
  //     final int ancCount = ancUniqueBeneficiaries.length;
  //
  //     final int ancCountSync = rows.where((r) {
  //       final id = r['unique_key']?.toString() ?? '';
  //       final isSynced = (r['is_synced'] ?? 0) == 1;
  //
  //       return ancUniqueBeneficiaries.contains(id) && isSynced;
  //     }).length;
  //
  //     const ancRefKey = 'bt7gs9rl1a5d26mz';
  //     final ancForms = await db.rawQuery('''
  //       SELECT f.beneficiary_ref_key, f.form_json, f.household_ref_key, f.forms_ref_key, f.created_date_time, f.id as form_id, f.is_synced
  //       FROM followup_form_data f
  //       WHERE f.forms_ref_key = '$ancRefKey' AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%' AND f.is_deleted = 0
  //       ORDER BY f.created_date_time DESC
  //     ''');
  //     final String deliveryOutcomeKey = '4r7twnycml3ej1vg';
  //     final Set<String> beneficiariesNeedingOutcome = {};
  //     final Set<String> beneficiariesProcessed = {};
  //     for (final form in ancForms) {
  //       try {
  //         final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
  //         if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
  //         if (beneficiariesProcessed.contains(beneficiaryRefKey)) continue;
  //         beneficiariesProcessed.add(beneficiaryRefKey);
  //         final existingOutcome = await db.query(
  //           'followup_form_data',
  //           where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
  //           whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
  //           limit: 1,
  //         );
  //         if (existingOutcome.isNotEmpty) continue;
  //         beneficiariesNeedingOutcome.add(beneficiaryRefKey);
  //       } catch (_) {}
  //     }
  //     final int deliveryOutcomeCount = beneficiariesNeedingOutcome.length;
  //
  //     final int deliveryOutcomeSyncedCount = ancDueRecords.where((r) {
  //       final id = (r['unique_key'] ?? '').toString();
  //       final isSynced = (r['is_synced'] ?? 0) == 1;
  //
  //       return beneficiariesNeedingOutcome.contains(id) && isSynced;
  //     }).length;
  //
  //
  //     final dbOutcomes = await db.query(
  //       'followup_form_data',
  //       where: 'forms_ref_key = ?',
  //       whereArgs: [deliveryOutcomeKey],
  //     );
  //     final Set<String> processedBeneficiaries = <String>{};
  //     for (final outcome in dbOutcomes) {
  //       try {
  //         final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();
  //         if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;
  //         if (processedBeneficiaries.contains(beneficiaryRefKey)) continue;
  //         final beneficiaryResults = await db.query(
  //           'beneficiaries_new',
  //           where: 'unique_key = ?',
  //           whereArgs: [beneficiaryRefKey],
  //         );
  //         if (beneficiaryResults.isEmpty) continue;
  //         final beneficiaryInfoRaw = beneficiaryResults.first['beneficiary_info'] as String? ?? '{}';
  //         try {
  //           jsonDecode(beneficiaryInfoRaw) as Map<String, dynamic>;
  //           processedBeneficiaries.add(beneficiaryRefKey);
  //         } catch (_) {}
  //       } catch (_) {}
  //     }
  //     final int hbcnMotherCount = processedBeneficiaries.length;
  //
  //     final int hbcnMotherSyncedCount = dbOutcomes.where((r) {
  //       final id = (r['unique_key'] ?? '').toString();
  //       if (id.isEmpty) return false;
  //
  //       final isSynced = (r['is_synced'] ?? 0) == 1;
  //
  //       return processedBeneficiaries.contains(id) && isSynced;
  //     }).length;
  //
  //     _motherCareSynced = ancCountSync + deliveryOutcomeSyncedCount +hbcnMotherSyncedCount;
  //     _motherCareTotal = ancCount + deliveryOutcomeCount + hbcnMotherCount;
  //
  //
  //     setState(() {
  //       _motherCareSynced;
  //       _motherCareTotal;
  //     });
  //     return ancCount + deliveryOutcomeCount + hbcnMotherCount;
  //   } catch (e) {
  //     return 0;
  //   }
  // }


  Future<void> _loadHouseholdCount() async {
    try {
      // Use households table count directly so the dashboard value
      // matches the total number of household records shown in the
      // All Household screen.
      // Mirror AllHouseholdScreen logic so that the dashboard count is
      // based on the same derived family-head list.
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          final configuredHeadKey = headKeyByHousehold[householdRefKey];
          if (configuredHeadKey == null || configuredHeadKey.isEmpty) return false;

          final isDeath = r['is_death'] == 1;
          final isMigrated = r['is_migrated'] == 1;

          return configuredHeadKey == uniqueKey && !isDeath && !isMigrated;
        } catch (_) {
          return false;
        }
      }).toList();

      final syncedCount = familyHeads.where(
            (r) => (r['is_synced'] ?? 0) == 1,
      ).length;

      if (mounted) {
        setState(() {
          _householdTotal = familyHeads.length;
          _householdSynced = syncedCount;
        });
      }
    } catch (e) {
      print('Error loading household count: $e');
    }
  }

  Future<void> _loadEligibleCouplesCount() async {
    try {
      print('🔍 Starting to load eligible couples count...');
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        if (mounted) {
          setState(() {
            _eligibleCoupleTotal = 0;
            _eligibleCoupleSynced = 0;
          });
        }
        return;
      }

      final query = '''
        SELECT DISTINCT b.*, e.eligible_couple_state, 
               e.created_date_time as registration_date,
               e.is_synced as e_is_synced
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND b.is_death = 0
          AND e.current_user_key = ?
      ''';

      final rows = await db.rawQuery(query, [ashaUniqueKey]);
      
      int totalCount = 0;
      int syncedCount = 0;
      
      for (final row in rows) {
        try {
          final beneficiaryInfo = row['beneficiary_info']?.toString() ?? '{}';
          final Map<String, dynamic> info = beneficiaryInfo.isNotEmpty 
              ? Map<String, dynamic>.from(jsonDecode(beneficiaryInfo))
              : <String, dynamic>{};
          
          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          if (memberType != 'child') {
            totalCount++;
            
            // Check if synced
            final isSynced = (row['e_is_synced'] ?? 0) == 1;
            if (isSynced) {
              syncedCount++;
            }
          }
        } catch (_) {
          totalCount++;
          // If there's an error parsing beneficiary_info, still count it
          // and check sync status from the activity record
          final isSynced = (row['e_is_synced'] ?? 0) == 1;
          if (isSynced) {
            syncedCount++;
          }
        }
      }
      
      print('✅ Setting counts - Total: $totalCount, Synced: $syncedCount');

      if (mounted) {
        setState(() {
          _eligibleCoupleTotal = totalCount;
          _eligibleCoupleSynced = syncedCount;
        });
      }
    } catch (e) {
      print('❌ Error loading eligible couples count: $e');
      if (mounted) {
        setState(() {
          _eligibleCoupleTotal = 0;
          _eligibleCoupleSynced = 0;
        });
      }
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Text(
             l10n?.syncStatus ?? 'Sync Status',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.background),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: _isLoading
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.syncStatus ?? 'Sync Status',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.h),

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 1.h,
                            crossAxisSpacing: 3.w,
                            childAspectRatio: 1.7,
                            children: [
                              SyncCard(title:l10n?.household ?? 'Household', total: Constant.householdTotal, synced: Constant.householdTotalSync),
                              SyncCard(title:l10n?.beneficiary ?? 'Beneficiary', total: _beneficiaryTotal, synced: _beneficiarySynced),
                              SyncCard(title:l10n?.followUpLabel ?? 'Follow Up', total: _followupTotal, synced: _followupSynced),
                              SyncCard(title:l10n?.gridEligibleCoupleASHA ?? 'Eligible Couple', total: _eligibleCoupleTotal, synced: _eligibleCoupleSynced),
                              SyncCard(title:l10n?.gridMotherCare ?? 'Mother Care', total: Constant.motherCareTotal, synced: Constant.motherCareSynced),
                              SyncCard(title:l10n?.gridChildCare ?? 'Child Care', total: Constant.childRegisteredtotal, synced: Constant.childRegisteredtotalSync),],
                          ),

                          // SizedBox(height: 2.h),
                          if (_lastSyncedAt != null)
                            Row(
                              children: [
                                Text(
                                  '${l10n?.lastSynced ??"Last synced at: "}: ${_formatDateTime(_lastSyncedAt!)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

class SyncCard extends StatefulWidget {
  final String title;
  final int total;
  final int synced;

  const SyncCard({
    super.key,
    required this.title,
    required this.total,
    required this.synced,
  });
  @override
  State<SyncCard> createState() => _SyncCardState();
}

class _SyncCardState extends State<SyncCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(

      color: AppColors.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal:3.w, vertical: 1.5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 0.8.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n?.totalLabel ?? "Total"}: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.total}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 0.5.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n?.synced ?? "Synced"}: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.synced}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold ,
                    ),
                  ),
                ],
              ),
            )

          ],
        ),
      ),
    );
  }
}
