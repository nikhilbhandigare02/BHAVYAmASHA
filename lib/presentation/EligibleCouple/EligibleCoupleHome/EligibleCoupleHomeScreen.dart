import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart' show Sqflite, Database;
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart' show AppHeader;
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/repositories/EligibleCoupleRepository/EligibleCoupleRepository.dart';
import '../../HomeScreen/HomeScreen.dart';

class EligibleCoupleHomeScreen extends StatefulWidget {
  const EligibleCoupleHomeScreen({super.key});

  @override
  State<EligibleCoupleHomeScreen> createState() =>
      _EligibleCoupleHomeScreenState();
}

class _EligibleCoupleHomeScreenState extends State<EligibleCoupleHomeScreen> {
  int eligibleCouplesCount = 0;
  int updatedEligibleCouplesCount = 0;
  bool isLoading = true;
  final EligibleCoupleRepository _ecRepo = EligibleCoupleRepository();

  @override
  void initState() {
    super.initState();
    _loadCounts();
    // _printEligibleCoupleActivities();
  }


  final LocalStorageDao _localStorageDao = LocalStorageDao();

  int? _calculateAgeFromDob(String? dob) {
    if (dob == null || dob.isEmpty) return null;

    try {
      final DateTime dobDate = DateTime.parse(dob);
      final DateTime today = DateTime.now();

      int age = today.year - dobDate.year;

      if (today.month < dobDate.month ||
          (today.month == dobDate.month && today.day < dobDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _hasSterilizationRecord(
      Database db,
      String beneficiaryKey,
      String ashaUniqueKey,
      ) async {
    final rows = await db.query(
      FollowupFormDataTable.table,
      where: '''
      beneficiary_ref_key = ?
      AND current_user_key = ?
      AND is_deleted = 0
      AND forms_ref_key = ?
    ''',
      whereArgs: [
        beneficiaryKey,
        ashaUniqueKey,
        FollowupFormDataTable
            .formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue],
      ],
    );

    for (final row in rows) {
      try {
        final formJsonStr = row['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;

        final Map<String, dynamic> formJson =
        Map<String, dynamic>.from(jsonDecode(formJsonStr));

        final trackingDue =
        formJson['eligible_couple_tracking_due_from'];

        if (trackingDue is Map<String, dynamic>) {

          final method =
          trackingDue['method_of_contraception']
              ?.toString()
              .toLowerCase();

          if (
              (method == 'female_sterilization' ||
                  method == 'male_sterilization' || method == 'male sterilization' || method == 'female sterilization')) {
            return true;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }


  Future<void> _loadCounts() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        print('Error: Current user key not found');
        if (mounted) {
          setState(() {
            eligibleCouplesCount = 0;
            updatedEligibleCouplesCount = 0;
          });
        }
        return;
      }

      final query = '''
        SELECT DISTINCT b.*, 
       e.eligible_couple_state, 
       e.created_date_time as registration_date
FROM beneficiaries_new b
INNER JOIN eligible_couple_activities e 
        ON b.unique_key = e.beneficiary_ref_key
WHERE b.is_deleted = 0 
  AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
  AND (b.is_death = 0 OR b.is_death IS NULL)
  AND e.eligible_couple_state IN ('eligible_couple')
  AND e.current_user_key = ?
  AND b.current_user_key = ?
ORDER BY b.created_date_time DESC;

      ''';

      final rows = await db.rawQuery(query, [ashaUniqueKey,ashaUniqueKey]);

      int count = 0;
      final Set<String> countedBeneficiaries = {};

      for (final row in rows) {
        try {
          final beneficiaryKey = row['unique_key']?.toString();
          if (beneficiaryKey == null || beneficiaryKey.isEmpty) continue;

          if (countedBeneficiaries.contains(beneficiaryKey)) {
            continue;
          }

          final beneficiaryInfo = row['beneficiary_info']?.toString() ?? '{}';
          final Map<String, dynamic> info = beneficiaryInfo.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(beneficiaryInfo))
              : <String, dynamic>{};

          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final maritalStatus =
              info['maritalStatus']?.toString().toLowerCase() ?? '';
          final gender =
              info['gender']?.toString().toLowerCase() ?? '';

          int? age;
          if (info['age'] != null) {
            age = int.tryParse(info['age'].toString());
          }
          age ??= _calculateAgeFromDob(info['dob']?.toString());

          if (memberType == 'child' ||
              maritalStatus != 'married' ||
              age == null ||
              age < 15 ||
              age > 49) {
            continue;
          }

          final hasSterilization = await _hasSterilizationRecord(
            db,
            beneficiaryKey,
            ashaUniqueKey,
          );

          if (hasSterilization) {
            continue;
          }

          countedBeneficiaries.add(beneficiaryKey);
          count++;
        } catch (_) {
          continue;
        }
      }

      final updatedCouples = await _localStorageDao.getUpdatedEligibleCouples();

      if (mounted) {
        setState(() {
          eligibleCouplesCount = count;
          updatedEligibleCouplesCount = updatedCouples.length;
        });
      }
    } catch (e) {
      print('Error loading counts: $e');
      if (mounted) {
        setState(() {
          eligibleCouplesCount = 0;
          updatedEligibleCouplesCount = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<Map<String, int>> getTrackingDueCounts() async {
    final db = await DatabaseProvider.instance.database;
    final currentUser = await SecureStorageService.getCurrentUserData();
    final currentUserKey = currentUser?['unique_key']?.toString() ?? '';

    if (currentUserKey.isEmpty) {
      return {
        'total': 0,
        'protected': 0,
        'unprotected': 0,
      };
    }

    try {
      // Get total tracking due count
      final totalCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(DISTINCT e.beneficiary_ref_key)
      FROM eligible_couple_activities e
      INNER JOIN beneficiaries_new b ON e.beneficiary_ref_key = b.unique_key
      WHERE e.eligible_couple_state = 'tracking_due'
        AND e.is_deleted = 0
        AND b.is_deleted = 0
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND (b.is_death = 0 OR b.is_death IS NULL)
        AND e.current_user_key = ?
        AND (b.beneficiary_info IS NULL OR b.beneficiary_info NOT LIKE '%"gender":"male"%')
    ''', [currentUserKey])) ?? 0;

      // Get protected count (has family planning)
      final protectedCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(DISTINCT e.beneficiary_ref_key)
      FROM eligible_couple_activities e
      INNER JOIN beneficiaries_new b ON e.beneficiary_ref_key = b.unique_key
      WHERE e.eligible_couple_state = 'tracking_due'
        AND e.is_deleted = 0
        AND b.is_deleted = 0
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND (b.is_death = 0 OR b.is_death IS NULL)
        AND e.current_user_key = ?
        AND (b.is_family_planning = 1 OR b.is_family_planning = '1' OR b.is_family_planning = 'true')
        AND (b.beneficiary_info IS NULL OR b.beneficiary_info NOT LIKE '%"gender":"male"%')
    ''', [currentUserKey])) ?? 0;

      return {
        'total': totalCount,
        'protected': protectedCount,
        'unprotected': totalCount - protectedCount,
      };
    } catch (e) {
      print('Error getting tracking due counts: $e');
      return {
        'total': 0,
        'protected': 0,
        'unprotected': 0,
      };
    }
  }



  @override
  void dispose() {
    _ecRepo.stopAutoSyncEligibleCoupleActivities();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final cards = [
      {
        'image': 'assets/images/couple.png',
        'count': isLoading ? '...' : eligibleCouplesCount.toString(),
        'title': l10n?.gridEligibleCouple ?? 'Eligible Couple',
        'route': Route_Names.EligibleCoupleIdentified,
      },
      {
        'image': 'assets/images/npcb-refer.png',
        'count': isLoading ? '...' : updatedEligibleCouplesCount.toString(),
        'title': l10n?.updatedEligibleCoupleListTitle ??
            'Updated Eligible Couple List',
        'route': Route_Names.UpdatedEligibleCoupleScreen,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: l10n?.gridEligibleCoupleASHA ?? 'Eligible Couple',
        showBack: false,
        icon1Image: 'assets/images/home.png',

        onIcon1Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 3;
          final padding = 12.0 * 2;
          final spacing = 12.0 * (crossAxisCount - 1);
          final itemWidth = ((screenWidth - padding - spacing) / crossAxisCount) * 1.1;
          final scaleFactor = MediaQuery.of(context).textScaleFactor;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: LayoutBuilder(
                builder: (context, _) {
                  double maxHeight = 0;
                  final cardHeights = <double>[];

                  for (var item in cards) {
                    final textSpan = TextSpan(
                      text: item['title'],
                      style: TextStyle(
                        fontSize: 13.sp * scaleFactor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                    final tp = TextPainter(
                      text: textSpan,
                      maxLines: 3,
                      textDirection: TextDirection.ltr,
                    )..layout(maxWidth: itemWidth - 24);

                    // Height = base image + text height + padding (responsive)
                    double cardHeight = tp.size.height + (90 * scaleFactor);
                    cardHeights.add(cardHeight);
                  }

                  maxHeight = cardHeights.reduce((a, b) => a > b ? a : b);

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: cards.map((item) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: itemWidth,
                          maxWidth: itemWidth,
                          minHeight: 120,
                          maxHeight: 120,
                        ),
                        child: _DashboardCard(
                          image: item['image']!,
                          count: item['count']!,
                          title: item['title']!,
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, item['route']!);
                            if (result == true && mounted) {
                              await _loadCounts();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          );
        },
      ),

    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String image;
  final String count;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.image,
    required this.count,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).textScaleFactor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        color: AppColors.background,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(1.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Top Row (icon + count)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    image,
                    width: 28 * scaleFactor,
                    height: 28 * scaleFactor,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Text(
                    count,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Title
              Text(
                title,
                textAlign: TextAlign.start,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp * scaleFactor,
                  fontWeight: FontWeight.w500,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
