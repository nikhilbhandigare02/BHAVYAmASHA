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
    _loadCountsUpdated();
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

  Future<int> _getEligibleCoupleCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return 0;

      final query = '''
      SELECT DISTINCT b.*, e.eligible_couple_state, 
               e.created_date_time as registration_date
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND (b.is_death = 0 OR b.is_death IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND e.current_user_key = ?
    ''';

      final rows = await db.rawQuery(query, [ashaUniqueKey]);

      int count = 0;

      for (final row in rows) {
        try {
          final beneficiaryInfo =
              row['beneficiary_info']?.toString() ?? '{}';

          final Map<String, dynamic> info =
          beneficiaryInfo.isNotEmpty
              ? Map<String, dynamic>.from(
              jsonDecode(beneficiaryInfo))
              : <String, dynamic>{};

          /// -------- SKIP CHILD --------
          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          if (memberType == 'child') continue;

          /// -------- AGE CALCULATION --------
          final dob = info['dob']?.toString();
          final age = _calculateAgeFromDob(dob);
          if (age == null) continue;

          final gender =
              info['gender']?.toString().toLowerCase() ?? '';

          /// -------- AGE ELIGIBILITY --------
          /*if (gender == 'female' && (age < 15 || age > 49)) continue;
          if (gender == 'male' && (age < 15 || age > 54)) continue;
*/
          /// -------- STERILIZATION CHECK --------
          final beneficiaryKey = row['unique_key']?.toString() ?? '';
          final hasSterilization =
          await _hasSterilizationRecord(
            db,
            beneficiaryKey,
            ashaUniqueKey,
          );

          if (hasSterilization) continue;

          /// -------- COUNT VALID ELIGIBLE --------
          count++;
        } catch (_) {
          // Ignore malformed rows safely
          continue;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }


  Future<void> _loadCounts() async {
    try {
      //setState(() => _isLoading = true);

      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      if (currentUserKey.isEmpty) {
        print('❌ Error: Current user key not found');
        setState(() {
          /*_filtered = [];
          _isLoading = false;*/
        });
        return;
      }

      final query = '''
      SELECT 
        b.*, 
        e.eligible_couple_state,
        e.created_date_time AS registration_date
      FROM beneficiaries_new b
      INNER JOIN eligible_couple_activities e
        ON b.unique_key = e.beneficiary_ref_key
      WHERE b.is_deleted = 0
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND (b.is_death = 0 OR b.is_death IS NULL)
        AND e.eligible_couple_state = 'eligible_couple'
        AND e.is_deleted = 0
        AND e.current_user_key = ?
      ORDER BY b.created_date_time DESC
    ''';

      final rows = await db.rawQuery(query, [currentUserKey]);
      print('🔍 Raw eligible couple rows: ${rows.length}');

      if (rows.isEmpty) {
        setState(() {
         // eligibleCouplesCount = [];
          //_isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> couples = [];
      final Set<String> seenBeneficiaries = {};

      for (final row in rows) {
        final Map<String, dynamic> member =
        Map<String, dynamic>.from(row);

        Map<String, dynamic> info = {};
        try {
          final raw = member['beneficiary_info'];
          if (raw is String && raw.isNotEmpty) {
            info = jsonDecode(raw) as Map<String, dynamic>;
          } else if (raw is Map) {
            info = Map<String, dynamic>.from(raw);
          }
        } catch (e) {
          print('⚠️ JSON parse error: $e');
          continue;
        }

        final String beneficiaryKey =
            member['unique_key']?.toString() ?? '';

        if (beneficiaryKey.isEmpty) {
          print('⚠️ Beneficiary unique_key missing');
          continue;
        }

        final String memberType =
            info['memberType']?.toString().toLowerCase() ?? '';

        // 🚫 Skip children
        if (memberType == 'child') {
          print('⛔ Skipping child record');
          continue;
        }

        final beneficiaryKeya = row['unique_key']?.toString() ?? '';
        final hasSterilization =
        await _hasSterilizationRecord(
          db,
          beneficiaryKeya,
          currentUserKey,
        );

        if (hasSterilization) continue;

        // 🚫 Skip duplicate beneficiary
        if (seenBeneficiaries.contains(beneficiaryKey)) {
          print('⛔ Duplicate beneficiary skipped: $beneficiaryKey');
          continue;
        }

        seenBeneficiaries.add(beneficiaryKey);

        couples.add(
          _formatCoupleData(
            _toStringMap(member),
            info,
            <String, dynamic>{},
            isHead: true,
            shouldShowGuestBadge: false,
          ),
        );
      }

      print('✅ Final eligible couples (unique beneficiaries): ${couples.length}');

      setState(() {
        eligibleCouplesCount = couples.length;
       // _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error in _loadEligibleCouples: $e');
      print(stackTrace);
      setState(() {
        //eligibleCouplesCount = 0;
       // _isLoading = false;
      });
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


  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead, bool shouldShowGuestBadge = false}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['registration_date']?.toString() ?? '';
    final info = _toStringMap(row['beneficiary_info']);
    final head = _toStringMap(info['head_details']);
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender?.isNotEmpty == true ? gender![0].toUpperCase() + gender!.substring(1) : 'Not Available';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? '';
    final mobile = female['mobile_no']?.toString() ?? female['mobileNo']?.toString() ?? 'Not Available';
    final husbandName = female['spouseName']?.toString() ??
        (isHead
            ? (headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString())
            : (headOrSpouse['headName']?.toString() ?? headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString()))
        ?? '';

    final dynamic childrenRaw = info['children_details'] ?? head['childrendetails'] ?? head['childrenDetails'];
    String last11(String s) => s.length > 11 ? s.substring(s.length - 11) : s;

    Map<String, dynamic>? childrenSummary;
    if (childrenRaw != null) {
      final childrenMap = _toStringMap(childrenRaw);
      childrenSummary = {
        'totalBorn': childrenMap['totalBorn'],
        'totalLive': childrenMap['totalLive'],
        'totalMale': childrenMap['totalMale'],
        'totalFemale': childrenMap['totalFemale'],
        'youngestAge': childrenMap['youngestAge'],
        'ageUnit': childrenMap['ageUnit'],
        'youngestGender': childrenMap['youngestGender'],
      }..removeWhere((k, v) => v == null);
    }
    return {
      'hhId': hhId,
      'hhIdShort': last11(hhId),
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': uniqueKey,
      'BeneficiaryIDShort': last11(uniqueKey) ,
      'Name': name,
      'age': age > 0 ? '$age Y | $displayGender' : 'N/A',
      'RCH ID': richId.isNotEmpty ? richId : 'Not Available',
      'mobileno': mobile,
      'HusbandName': husbandName.isNotEmpty ? husbandName : 'Not Available',
      'childrenSummary': childrenSummary,
      '_rawRow': row,
      'fullHhId': hhId,
      'fullBeneficiaryId': uniqueKey,
      'shouldShowGuestBadge': shouldShowGuestBadge,
    };
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
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

  Future<void> _loadCountsUpdated() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
     /* final db = await DatabaseProvider.instance.database;
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

      // Use same logic as myBeneficiaries.dart _getEligibleCoupleCount()
      final query = '''
        SELECT DISTINCT b.*, e.eligible_couple_state, 
               e.created_date_time as registration_date
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND (b.is_death = 0 OR b.is_death IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND e.current_user_key = ?
      ''';

      final rows = await db.rawQuery(query, [ashaUniqueKey]);

      int count = 0;
      for (final row in rows) {
        try {
          final beneficiaryInfo = row['beneficiary_info']?.toString() ?? '{}';
          final Map<String, dynamic> info = beneficiaryInfo.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(beneficiaryInfo))
              : <String, dynamic>{};

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          if (memberType != 'child') {
            count++;
          }
        } catch (_) {
          count++;
        }
      }

      count = await _getEligibleCoupleCount();
*/
      final updatedCouples = await _localStorageDao.getUpdatedEligibleCouples();

      if (mounted) {
        setState(() {
         // eligibleCouplesCount = count;
          updatedEligibleCouplesCount = updatedCouples.length;
        });
      }
    } catch (e) {
      print('Error loading counts: $e');
      if (mounted) {
        setState(() {
         // eligibleCouplesCount = 0;
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
