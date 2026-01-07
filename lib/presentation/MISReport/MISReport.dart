import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/Database/User_Info.dart';
import 'dart:convert';

import '../../data/Database/database_provider.dart';
import '../../data/Database/tables/child_care_activities_table.dart';
import '../../data/Database/tables/mother_care_activities_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
class Misreport extends StatefulWidget {
  const Misreport({super.key});

  @override
  State<Misreport> createState() => _MisreportState();
}

class _MisreportState extends State<Misreport> {
  int? appRoleId;
  int ashaCount = 0;

  Future<void> loadUserData() async {
    try {
      final Map<String, dynamic>? userData =
      await UserInfo.getCurrentUser();

      if (userData != null) {
        final details = userData['details'];

        setState(() {
          appRoleId = int.tryParse(details!['app_role_id'].toString());
          ashaCount = (details?['asha_list'] as List?)?.length ?? 0;
        });

        debugPrint('App Role ID: $appRoleId');
        debugPrint('ASHA Count: $ashaCount');
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    }
  }


  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late String _selectedMonth;

  int pregnantWomen = 0;
  int newborns = 0;
  int abhaGenerated = 0;
  int abhaFetched = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
    getCurrentMonthChildCareDueCounts();
    getCurrentMonthAncDueMotherCareCount();
    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
  }

  Future<int> getCurrentMonthAncDueMotherCareCount() async {
    try {
      print('🔍 [getCurrentMonthAncDueMotherCareCount] Querying ANC due count (unique beneficiaries)...');

      // 1. Get the current user key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final db = await DatabaseProvider.instance.database;

      // 2. Prepare the WHERE clause parts
      String whereClause = '''
      mother_care_state = ?
      AND is_deleted = 0
      AND beneficiary_ref_key IS NOT NULL
      AND (
        strftime('%Y-%m', created_date_time) = strftime('%Y-%m', 'now')
        OR
        strftime('%Y-%m', modified_date_time) = strftime('%Y-%m', 'now')
      )
    ''';

      List<dynamic> args = ['anc_due'];

      // 3. Apply the ASHA Unique Key filter if it exists
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT beneficiary_ref_key) AS total_count
      FROM ${MotherCareActivitiesTable.table}
      WHERE $whereClause
    ''', args);

      final int count = Sqflite.firstIntValue(result) ?? 0;

      print('✅ [getCurrentMonthAncDueMotherCareCount] Unique ANC Due Count: $count');
      return count;
    } catch (e, stackTrace) {
      print('❌ [getCurrentMonthAncDueMotherCareCount] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, int>> getCurrentMonthChildCareDueCounts() async {
    try {
      print('🔍 [getCurrentMonthChildCareDueCounts] Querying child care due counts (state-wise total)...');


      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final db = await DatabaseProvider.instance.database;


      String whereClause = '''
      is_deleted = 0
      AND beneficiary_ref_key IS NOT NULL
      AND (
        strftime('%Y-%m', created_date_time) = strftime('%Y-%m', 'now')
        OR
        strftime('%Y-%m', modified_date_time) = strftime('%Y-%m', 'now')
      )
    ''';

      List<dynamic> args = [];

      // 3. Apply the ASHA Unique Key filter if it exists
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      final result = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT CASE 
          WHEN child_care_state = 'tracking_due'
          THEN beneficiary_ref_key
        END) AS tracking_due_count,

        COUNT(DISTINCT CASE 
          WHEN child_care_state = 'child_registration_due'
          THEN beneficiary_ref_key
        END) AS child_registration_due_count
      FROM ${ChildCareActivitiesTable.table}
      WHERE $whereClause
    ''', args);

      final row = result.isNotEmpty ? result.first : <String, Object?>{};

      final int trackingDue = (row['tracking_due_count'] as int?) ?? 0;
      final int registrationDue = (row['child_registration_due_count'] as int?) ?? 0;
      final int total = trackingDue + registrationDue;

      print(
        '✅ [getCurrentMonthChildCareDueCounts] '
            'Tracking Due: $trackingDue, '
            'Registration Due: $registrationDue, '
            'TOTAL: $total',
      );

      return {
        'tracking_due': trackingDue,
        'child_registration_due': registrationDue,
        'total_due': total,
      };
    } catch (e, stackTrace) {
      print('❌ [getCurrentMonthChildCareDueCounts] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n?.monthJanuary ?? 'January',
      l10n?.monthFebruary ?? 'February',
      l10n?.monthMarch ?? 'March',
      l10n?.monthApril ?? 'April',
      l10n?.monthMay ?? 'May',
      l10n?.monthJune ?? 'June',
      l10n?.monthJuly ?? 'July',
      l10n?.monthAugust ?? 'August',
      l10n?.monthSeptember ?? 'September',
      l10n?.monthOctober ?? 'October',
      l10n?.monthNovember ?? 'November',
      l10n?.monthDecember ?? 'December',
    ];
    final displayMonth = monthNames[DateTime.now().month - 1];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppHeader(screenTitle: l10n?.drawerMisReport ?? 'MIS Report', showBack: true,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appRoleId == 4)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          'No. of ASHA under facilitator :',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ashaCount.toString(), // ✅ SHOW COUNT HERE
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          l10n?.misMonthLabel ?? 'Month : ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 10,),
                        Text(
                          displayMonth,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      FutureBuilder<int>(
                        future: getCurrentMonthAncDueMotherCareCount(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;

                          return _statRow(
                            l10n?.misStatPregnantWomen ?? 'Number of total Pregnant Women :',
                            count.toString(),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Map<String, int>>(
                        future: getCurrentMonthChildCareDueCounts(),
                        builder: (context, snapshot) {
                          final total = snapshot.data?['total_due'] ?? 0;

                          return _statRow(
                            l10n?.misStatNewborns ?? 'Total number of newborns :',
                            total.toString(), // ✅ SHOW TOTAL HERE
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _statRow(l10n?.misStatAbhaGenerated ?? 'Total number of ABHA generated by user :', abhaGenerated.toString()),
                      const SizedBox(height: 10),
                      _statRow(l10n?.misStatAbhaFetched ?? 'Total number of Exisiting ABHA fetched by user :', abhaFetched.toString()),
                    ],
                  ),
                ),
              ],
            )



          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

