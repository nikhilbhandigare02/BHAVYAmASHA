import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart' show AppHeader;
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
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

      // === Count for Eligibl eCoupleIdentifiedScreen ===
      final identifiedRows = await LocalStorageDao.instance.getAllBeneficiaries();
      final identifiedHouseholds = <String, List<Map<String, dynamic>>>{};
      for (final row in identifiedRows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        if (hhKey.isEmpty) continue;
        identifiedHouseholds.putIfAbsent(hhKey, () => []).add(row);
      }

      const allowedRelations = <String>{
        'self',
        'spouse',
        'husband',
        'son',
        'daughter',
        'father',
        'mother',
        'brother',
        'sister',
        'wife',
        'nephew',
        'niece',
        'grand father',
        'grand mother',
        'father in law',
        'mother in low',
        'grand son',
        'grand daughter',
        'son in law',
        'daughter in law',
        'other',
      };

      int totalIdentified = 0;
      final trackingFormKeyForIdentified =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ?? '';
      final Set<String> sterilizedBeneficiariesIdentified = <String>{};
      if (trackingFormKeyForIdentified.isNotEmpty) {
        final trackingRows = await db.query(
          FollowupFormDataTable.table,
          columns: ['beneficiary_ref_key', 'form_json', 'created_date_time', 'id'],
          where: 'forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
          whereArgs: [trackingFormKeyForIdentified],
          orderBy: 'created_date_time DESC, id DESC',
        );
        final Map<String, String> latestFpMethod = {};
        for (final row in trackingRows) {
          final key = row['beneficiary_ref_key']?.toString() ?? '';
          if (key.isEmpty) continue;
          if (latestFpMethod.containsKey(key)) continue;
          final s = row['form_json']?.toString() ?? '';
          if (s.isEmpty) continue;
          try {
            final decoded = jsonDecode(s);
            Map<String, dynamic> formData = decoded is Map<String, dynamic>
                ? Map<String, dynamic>.from(decoded)
                : <String, dynamic>{};
            if (decoded is Map && decoded['form_data'] is Map) {
              formData = Map<String, dynamic>.from(decoded['form_data'] as Map);
            }
            final fp = formData['fp_method']?.toString().toLowerCase().trim();
            if (fp != null) latestFpMethod[key] = fp;
          } catch (_) {}
        }
        sterilizedBeneficiariesIdentified.addAll(
          latestFpMethod.entries
              .where((e) => e.value == 'male sterilization' || e.value == 'female sterilization')
              .map((e) => e.key),
        );
      }
      for (final household in identifiedHouseholds.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        // First pass: find head and spouse
        for (final member in household) {
          final info = _toStringMap(member['beneficiary_info']);
          String rawRelation =
              (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
          rawRelation = rawRelation.replaceAll('_', ' ');
          if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
            rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
          }

          final relation = () {
            if (rawRelation == 'self' || rawRelation == 'head' || rawRelation == 'family head') {
              return 'self';
            }
            if (rawRelation == 'spouse' || rawRelation == 'wife' || rawRelation == 'husband') {
              return 'spouse';
            }
            return rawRelation;
          }();

          if (relation == 'self') {
            head = info;
          } else if (relation == 'spouse') {
            spouse = info;
          }
        }

        // Second pass: count all eligible females with allowed relations
        for (final member in household) {
          final info = _toStringMap(member['beneficiary_info']);
          String rawRelation =
              (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
          rawRelation = rawRelation.replaceAll('_', ' ');
          if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
            rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
          }

          if (!allowedRelations.contains(rawRelation)) continue;
          if (!_isIdentifiedEligibleFemale(info, head: head)) continue;
          final memberUniqueKey = member['unique_key']?.toString() ?? '';
          if (memberUniqueKey.isNotEmpty && sterilizedBeneficiariesIdentified.contains(memberUniqueKey)) {
            continue;
          }

          totalIdentified++;
        }
      }

      // === Count for UpdatedEligibleCoupleListScreen (All tab) ===
      final trackingFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ?? '';
      final Set<String> sterilizedBeneficiaries = <String>{};
      if (trackingFormKey.isNotEmpty) {
        final trackingRows = await db.query(
          FollowupFormDataTable.table,
          columns: ['beneficiary_ref_key', 'form_json', 'created_date_time', 'id'],
          where: 'forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
          whereArgs: [trackingFormKey],
          orderBy: 'created_date_time DESC, id DESC',
        );
        final Map<String, String> latestFp = {};
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
            final fp = formData['fp_method']?.toString().toLowerCase().trim();
            final key = row['beneficiary_ref_key']?.toString() ?? '';
            if (key.isNotEmpty && fp != null && !latestFp.containsKey(key)) {
              latestFp[key] = fp;
            }
          } catch (_) {}
        }
        sterilizedBeneficiaries.addAll(
          latestFp.entries
              .where((e) => e.value == 'male sterilization' || e.value == 'female sterilization')
              .map((e) => e.key),
        );
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

        // First pass: find head and spouse (do not pre-filter by tracking pregnancy/sterilization)
        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});
            String rawRelation =
                (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
            rawRelation = rawRelation.replaceAll('_', ' ');
            if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
              rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
            }

            final relation = () {
              if (rawRelation == 'self' || rawRelation == 'head' || rawRelation == 'family head') {
                return 'self';
              }
              if (rawRelation == 'spouse' || rawRelation == 'wife' || rawRelation == 'husband') {
                return 'spouse';
              }
              return rawRelation;
            }();

            if (relation == 'self') {
              head = info;
            } else if (relation == 'spouse') {
              spouse = info;
            }
          } catch (e) {
            print('Error processing household member for updated count: $e');
          }
        }

        // Second pass: count all updated eligible females with allowed relations
        for (final member in household) {
          try {
            final memberUniqueKey = member['unique_key']?.toString() ?? '';

            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            String rawRelation =
                (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
            rawRelation = rawRelation.replaceAll('_', ' ');
            if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
              rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
            }

            if (!allowedRelations.contains(rawRelation)) continue;
            if (!_isUpdatedEligibleFemale(info, head: head)) continue;
            if (memberUniqueKey.isNotEmpty && sterilizedBeneficiaries.contains(memberUniqueKey)) continue;

            totalUpdatedEligible++;
          } catch (e) {
            print('Error processing member for updated count (second pass): $e');
          }
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

  bool _isIdentifiedEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;

    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    if (!isFemale) return false;

    final maritalStatusRaw =
        person['maritalStatus']?.toString().toLowerCase() ??
            head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isMarried = maritalStatusRaw == 'married';
    if (!isMarried) return false;

    final dob = person['dob'];
    final age = _calculateAge(dob);
    final fpMethodRaw = person['fpMethod']?.toString().toLowerCase().trim() ?? '';
    final hpMethodRaw = person['hpMethod']?.toString().toLowerCase().trim() ?? '';
    final isSterilized = fpMethodRaw == 'female sterilization' || fpMethodRaw == 'male sterilization' || hpMethodRaw == 'female sterilization' || hpMethodRaw == 'male sterilization';
    return age >= 15 && age <= 49 && !isSterilized;
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
    final isPregnantRaw = person['isPregnant']?.toString().toLowerCase() ?? '';
    final isPregnant = isPregnantRaw == 'yes' || isPregnantRaw == 'true' || isPregnantRaw == '1';
    final fpMethodRaw = person['fpMethod']?.toString().toLowerCase().trim() ?? '';
    final hpMethodRaw = person['hpMethod']?.toString().toLowerCase().trim() ?? '';
    final isSterilized = fpMethodRaw == 'female sterilization' || fpMethodRaw == 'male sterilization' || hpMethodRaw == 'female sterilization' || hpMethodRaw == 'male sterilization';
    return isFemale && isMarried && age >= 15 && age <= 49 && !isPregnant && !isSterilized;
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
