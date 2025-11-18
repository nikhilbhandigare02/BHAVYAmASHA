import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart' show AppHeader;
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../../../data/Local_Storage/tables/followup_form_data_table.dart';
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

  Future<void> _loadCounts() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // === Count for EligibleCoupleIdentifiedScreen ===
      final identifiedRows = await LocalStorageDao.instance.getAllBeneficiaries();
      final identifiedHouseholds = <String, List<Map<String, dynamic>>>{};
      for (final row in identifiedRows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        if (hhKey.isEmpty) continue;
        identifiedHouseholds.putIfAbsent(hhKey, () => []).add(row);
      }

      int totalIdentified = 0;
      for (final household in identifiedHouseholds.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in household) {
          final info = _toStringMap(member['beneficiary_info']);
          final relation = (info['relation_to_head'] as String?)?.toLowerCase() ?? '';
          if (relation == 'self') {
            head = info;
          } else if (relation == 'spouse') {
            spouse = info;
          }
        }

        if (head != null && _isIdentifiedEligibleFemale(head)) {
          totalIdentified++;
        }
        if (spouse != null && _isIdentifiedEligibleFemale(spouse)) {
          totalIdentified++;
        }
      }

      // === Count for UpdatedEligibleCoupleListScreen (All tab) ===
      final trackingFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ?? '';
      final Set<String> pregnantBeneficiaries = <String>{};
      if (trackingFormKey.isNotEmpty) {
        final trackingRows = await db.query(
          FollowupFormDataTable.table,
          columns: ['beneficiary_ref_key', 'form_json'],
          where: 'forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
          whereArgs: [trackingFormKey],
        );
        for (final row in trackingRows) {
          try {
            final formJsonStr = row['form_json']?.toString() ?? '';
            if (formJsonStr.isEmpty) continue;
            final decoded = jsonDecode(formJsonStr);
            if (decoded is! Map<String, dynamic>) continue;
            Map<String, dynamic> formData = decoded;
            if (decoded['form_data'] is Map) {
              formData = Map<String, dynamic>.from(decoded['form_data']);
            }
            final isPregnant = formData['is_pregnant'];
            if (isPregnant == true) {
              final key = row['beneficiary_ref_key']?.toString() ?? '';
              if (key.isNotEmpty) {
                pregnantBeneficiaries.add(key);
              }
            }
          } catch (_) {}
        }
      }

      final updatedRows = await LocalStorageDao.instance.getAllBeneficiaries();
      final updatedHouseholds = <String, List<Map<String, dynamic>>>{};
      for (final row in updatedRows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        if (hhKey.isEmpty) continue;
        updatedHouseholds.putIfAbsent(hhKey, () => []).add(row);
      }

      int totalUpdatedEligible = 0;
      for (final household in updatedHouseholds.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in household) {
          try {
            final memberUniqueKey = member['unique_key']?.toString() ?? '';
            if (memberUniqueKey.isNotEmpty &&
                pregnantBeneficiaries.contains(memberUniqueKey)) {
              continue;
            }

            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});
            final relation = (info['relation_to_head'] as String?)?.toLowerCase() ?? '';
            if (relation == 'self') {
              head = info;
            } else if (relation == 'spouse') {
              spouse = info;
            }
          } catch (e) {
            print('Error processing household member for updated count: $e');
          }
        }

        if (head != null && _isUpdatedEligibleFemale(head, head: head)) {
          totalUpdatedEligible++;
        }
        if (spouse != null && _isUpdatedEligibleFemale(spouse, head: head)) {
          totalUpdatedEligible++;
        }
      }

      if (mounted) {
        setState(() {
          eligibleCouplesCount = totalIdentified;
          updatedEligibleCouplesCount = totalUpdatedEligible;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading counts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _toStringMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    return {};
  }

  bool _isIdentifiedEligibleFemale(Map<String, dynamic> person) {
    if (person.isEmpty) return false;

    final gender = person['gender']?.toString().toLowerCase();
    final isFemale = gender == 'f' || gender == 'female';
    if (!isFemale) return false;

    final maritalStatus = person['maritalStatus']?.toString().toLowerCase();
    if (maritalStatus != 'married') return false;

    final dob = person['dob'];
    final age = _calculateAge(dob);
    return age >= 15 && age <= 49;
  }

  bool _isUpdatedEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ??
        head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    final isMarried = maritalStatusRaw == 'married';
    final dob = person['dob'];
    final age = _calculateAge(dob);
    return isFemale && isMarried && age >= 15 && age <= 49;
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
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
                          onTap: () => Navigator.pushNamed(context, item['route']!),
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
