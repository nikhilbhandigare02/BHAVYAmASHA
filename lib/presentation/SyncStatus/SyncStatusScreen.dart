import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/Database/database_provider.dart';

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

      // Get counts directly from database tables
      // Update household counts
      _householdTotal = await _getTotalCount('households');
      _householdSynced = await _getSyncedCount('households', await _getIdsFromTable('households'));

      // Update beneficiary counts
      _beneficiaryTotal = await _getTotalCount('beneficiaries_new');
      _beneficiarySynced = await _getSyncedCount('beneficiaries_new',
          await _getIdsFromTable('beneficiaries_new'));

      // Update eligible couple counts
      _eligibleCoupleTotal = await _getTotalCount('eligible_couple_activities');
      _eligibleCoupleSynced = await _getSyncedCount('eligible_couple_activities',
          await _getIdsFromTable('eligible_couple_activities'));

      // Update mother care counts
      _motherCareTotal = await _getTotalCount('mother_care_activities');
      _motherCareSynced = await _getSyncedCount('mother_care_activities',
          await _getIdsFromTable('mother_care_activities'));

      // Update child care counts
      _childCareTotal = await _getTotalCount('child_care_activities');
      _childCareSynced = await _getSyncedCount('child_care_activities',
          await _getIdsFromTable('child_care_activities'));

      // Followup counts (kept as is since it's not in dashboard)
      _followupTotal = await dao.getFollowupTotalCountLocal();
      _followupSynced = await dao.getFollowupSyncedCountLocal();

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

  // Helper method to get total count from a table
  Future<int> _getTotalCount(String tableName) async {
    try {
      final db = await DatabaseProvider.instance.database;
      // For child_care_activities, get all records regardless of is_deleted status
      if (tableName == 'child_care_activities') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        return result.first['count'] as int? ?? 0;
      } else {
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
      final placeholders = List.filled(ids.length, '?').join(',');
      // For child_care_activities, don't filter by is_deleted
      if (tableName == 'child_care_activities') {
        final result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableName WHERE id IN ($placeholders) AND is_synced = 1',
          ids,
        );
        return result.first['count'] as int? ?? 0;
      } else {
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
      // For child_care_activities, get all IDs regardless of is_deleted status
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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Text(
              'Sync Status',
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
                              'Sync Status',
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
                                SyncCard(title: 'Household', total: _householdTotal, synced: _householdSynced),
                                SyncCard(title: 'Beneficiary', total: _beneficiaryTotal, synced: _beneficiarySynced),
                                SyncCard(title: 'Follow Up', total: _followupTotal, synced: _followupSynced),
                                SyncCard(title: 'Eligible Couple', total: _eligibleCoupleTotal, synced: _eligibleCoupleSynced),
                                SyncCard(title: 'Mother Care', total: _motherCareTotal, synced: _motherCareSynced),
                                SyncCard(title: 'Child Care', total: _childCareTotal, synced: _childCareSynced),
                              ],
                            ),

                            SizedBox(height: 2.h),
                            if (_lastSyncedAt != null)
                              Row(
                                children: [
                                  Text(
                                    'Last synced: ${_formatDateTime(_lastSyncedAt!)}',
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

class SyncCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              title,
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
                    text: 'Total: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$total',
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
                    text: 'Synced: ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: '$synced',
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
