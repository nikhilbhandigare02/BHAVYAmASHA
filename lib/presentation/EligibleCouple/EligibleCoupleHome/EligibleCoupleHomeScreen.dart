import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
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
    _printEligibleCoupleActivities();
  }


  final LocalStorageDao _localStorageDao = LocalStorageDao();

  Future<void> _loadCounts() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final counts = await _localStorageDao.getEligibleCoupleCounts();
      if (mounted) {
        setState(() {
          eligibleCouplesCount = counts['total'] ?? 0;
          updatedEligibleCouplesCount = counts['tracking_due'] ?? 0;
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


  Future<void> _printEligibleCoupleActivities() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'eligible_couple_activities',
        orderBy: 'created_date_time DESC',
      );
      print('eligible_couple_activities rows: ${rows.length}');
      for (final row in rows) {
        try {
          print(jsonEncode(row));
        } catch (_) {
          print(row.toString());
        }
      }
    } catch (e) {
      print('Error reading eligible_couple_activities: $e');
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
