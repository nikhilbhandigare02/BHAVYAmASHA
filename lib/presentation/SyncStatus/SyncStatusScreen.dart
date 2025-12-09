import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

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
        // Get total household count for current user
        final householdTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _householdTotal = householdTotalResult.first['count'] as int? ?? 0;

        // Get synced household count for current user
        final householdSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _householdSynced = householdSyncedResult.first['count'] as int? ?? 0;
      } else {
        // Get total household count for all users
        final householdTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0',
        );
        _householdTotal = householdTotalResult.first['count'] as int? ?? 0;

        // Get synced household count for all users
        final householdSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM households WHERE is_deleted = 0 AND is_synced = 1',
        );
        _householdSynced = householdSyncedResult.first['count'] as int? ?? 0;
      }

      // Get beneficiary counts directly from beneficiaries_new table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        // Get total beneficiary count for current user
        final beneficiaryTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _beneficiaryTotal = beneficiaryTotalResult.first['count'] as int? ?? 0;

        // Get synced beneficiary count for current user
        final beneficiarySyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _beneficiarySynced = beneficiarySyncedResult.first['count'] as int? ?? 0;
      } else {
        // Get total beneficiary count for all users
        final beneficiaryTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0',
        );
        _beneficiaryTotal = beneficiaryTotalResult.first['count'] as int? ?? 0;

        // Get synced beneficiary count for all users
        final beneficiarySyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM beneficiaries_new WHERE is_deleted = 0 AND is_synced = 1',
        );
        _beneficiarySynced = beneficiarySyncedResult.first['count'] as int? ?? 0;
      }

      // Get eligible couple counts directly from the table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        final eligibleTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _eligibleCoupleTotal = eligibleTotalResult.first['count'] as int? ?? 0;

        // Get synced count
        final eligibleSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _eligibleCoupleSynced = eligibleSyncedResult.first['count'] as int? ?? 0;
      } else {
        final eligibleTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0',
        );
        _eligibleCoupleTotal = eligibleTotalResult.first['count'] as int? ?? 0;

        final eligibleSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM eligible_couple_activities WHERE is_deleted = 0 AND is_synced = 1',
        );
        _eligibleCoupleSynced = eligibleSyncedResult.first['count'] as int? ?? 0;
      }

      // Get mother care counts directly from the table
      // Get total count
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        final totalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _motherCareTotal = totalResult.first['count'] as int? ?? 0;

        // Get synced count
        final syncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _motherCareSynced = syncedResult.first['count'] as int? ?? 0;
      } else {
        final totalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0',
        );
        _motherCareTotal = totalResult.first['count'] as int? ?? 0;

        final syncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM mother_care_activities WHERE is_deleted = 0 AND is_synced = 1',
        );
        _motherCareSynced = syncedResult.first['count'] as int? ?? 0;
      }

      // Get child care counts directly from the table
      // Get total count
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        final childTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities WHERE current_user_key = ?',
          [ashaUniqueKey],
        );
        _childCareTotal = childTotalResult.first['count'] as int? ?? 0;

        // Get synced count
        final childSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities WHERE is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _childCareSynced = childSyncedResult.first['count'] as int? ?? 0;
      } else {
        final childTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities',
        );
        _childCareTotal = childTotalResult.first['count'] as int? ?? 0;

        final childSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM child_care_activities WHERE is_synced = 1',
        );
        _childCareSynced = childSyncedResult.first['count'] as int? ?? 0;
      }

      // Get followup counts directly from followup_form_data table
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        // Get total followup count for current user
        final followupTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _followupTotal = followupTotalResult.first['count'] as int? ?? 0;

        // Get synced followup count for current user
        final followupSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
          [ashaUniqueKey],
        );
        _followupSynced = followupSyncedResult.first['count'] as int? ?? 0;
      } else {
        // Get total followup count for all users
        final followupTotalResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0',
        );
        _followupTotal = followupTotalResult.first['count'] as int? ?? 0;

        // Get synced followup count for all users
        final followupSyncedResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM followup_form_data WHERE is_deleted = 0 AND is_synced = 1',
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

  Future<int> _getTotalCount(String tableName) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      // For child_care_activities, get all records regardless of is_deleted status
      if (tableName == 'child_care_activities') {
        if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName WHERE current_user_key = ?',
            [ashaUniqueKey],
          );
          return result.first['count'] as int? ?? 0;
        }
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        return result.first['count'] as int? ?? 0;
      } else {
        if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName WHERE is_deleted = 0 AND current_user_key = ?',
            [ashaUniqueKey],
          );
          return result.first['count'] as int? ?? 0;
        }
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE is_deleted = 0');
        return result.first['count'] as int? ?? 0;
      }
    } catch (e) {
      print('Error getting total count from $tableName: $e');
      return 0;
    }
  }

  // Helper method to get synced count for a specific table and IDs
  Future<int> _getSyncedCount(String tableName, List<int> ids) async {
    if (ids.isEmpty) return 0;

    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final placeholders = List.filled(ids.length, '?').join(',');
      // For child_care_activities, don't filter by is_deleted
      if (tableName == 'child_care_activities') {
        if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName WHERE id IN ($placeholders) AND is_synced = 1 AND current_user_key = ?',
            [...ids, ashaUniqueKey],
          );
          return result.first['count'] as int? ?? 0;
        }
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableName WHERE id IN ($placeholders) AND is_synced = 1',
          ids,
        );
        return result.first['count'] as int? ?? 0;
      } else {
        if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName WHERE id IN ($placeholders) AND is_deleted = 0 AND is_synced = 1 AND current_user_key = ?',
            [...ids, ashaUniqueKey],
          );
          return result.first['count'] as int? ?? 0;
        }
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableName WHERE id IN ($placeholders) AND is_deleted = 0 AND is_synced = 1',
          ids,
        );
        return result.first['count'] as int? ?? 0;
      }
    } catch (e) {
      print('Error getting synced count from $tableName: $e');
      return 0;
    }
  }

  // Helper method to get IDs from a table
  Future<List<int>> _getIdsFromTable(String tableName) async {
    try {
      final db = await DatabaseProvider.instance.database;

      if (tableName == 'child_care_activities') {
        final result = await db.rawQuery('SELECT id FROM $tableName');
        return result.map((e) => e['id'] as int).toList();
      } else {
        final result = await db.rawQuery('SELECT id FROM $tableName WHERE is_deleted = 0');
        return result.map((e) => e['id'] as int).toList();
      }
    } catch (e) {
      print('Error getting IDs from $tableName: $e');
      return [];
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
              Expanded(
                child: SingleChildScrollView(
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
                              mainAxisSpacing: 1.5.h,
                              crossAxisSpacing: 3.w,
                              childAspectRatio: 1.5,
                              children: [
                                SyncCard(title:l10n?.household ?? 'Household', total: _householdTotal, synced: _householdSynced),
                                SyncCard(title:l10n?.beneficiary ?? 'Beneficiary', total: _beneficiaryTotal, synced: _beneficiarySynced),
                                SyncCard(title:l10n?.followUpLabel ?? 'Follow Up', total: _followupTotal, synced: _followupSynced),
                                SyncCard(title:l10n?.gridEligibleCoupleASHA ?? 'Eligible Couple', total: _eligibleCoupleTotal, synced: _eligibleCoupleSynced),
                                SyncCard(title:l10n?.gridMotherCare ?? 'Mother Care', total: _motherCareTotal, synced: _motherCareSynced),
                                SyncCard(title:l10n?.gridChildCare ?? 'Child Care', total: _childCareTotal, synced: _childCareSynced),
                              ],
                            ),

                            SizedBox(height: 2.h),
                            if (_lastSyncedAt != null)
                              Row(
                                children: [
                                  Text(
                                    '${l10n?.lastSynced ??"Last synced"}: ${_formatDateTime(_lastSyncedAt!)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
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
              ),
              // // Logout button at the bottom
              // Container(
              //   width: double.infinity,
              //   padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       // Add your logout logic here
              //       // For example:
              //       // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              //     },
              //     icon: Icon(Icons.logout, color: Colors.white),
              //     label: Text(
              //       'Logout',
              //       style: TextStyle(fontSize: 16, color: Colors.white),
              //     ),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.primary,
              //       padding: EdgeInsets.symmetric(vertical: 15),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //   ),
              // ),
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
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.total}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '${widget.synced}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
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
