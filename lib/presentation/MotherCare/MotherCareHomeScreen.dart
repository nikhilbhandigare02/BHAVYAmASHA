import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/utils/anc_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/Database/tables/mother_care_activities_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
import '../HomeScreen/HomeScreen.dart';
import 'package:medixcel_new/core/config/routes/Routes.dart' as AppRoutes;

class Mothercarehomescreen extends StatefulWidget {
  const Mothercarehomescreen({super.key});

  @override
  State<Mothercarehomescreen> createState() => _MothercarehomescreenState();
}

class _MothercarehomescreenState extends State<Mothercarehomescreen>
    with RouteAware {
  int _ancVisitCount = 0;
  int _deliveryOutcomeCount = 0;
  int _hbcnMotherCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAncVisitCount();
    _loadDeliveryOutcomeCount();
    _loadHBCNCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRoutes.Routes.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      AppRoutes.Routes.routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadAncVisitCount();
    _loadDeliveryOutcomeCount();
    _loadHBCNCount();
  }

  Future<Set<String>> _getDeliveredBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.query(
      'followup_form_data',
      where: '''
      forms_ref_key = ?
      AND (
        LOWER(form_json) LIKE ?
        OR LOWER(form_json) LIKE ?
      )
    ''',
      whereArgs: [
        'bt7gs9rl1a5d26mz',
        '%"gives_birth_to_baby":"yes"%',
      ],
      columns: ['beneficiary_ref_key'],
      distinct: true,
    );

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id!.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  Future<Set<String>> _getAncDueBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.rawQuery('''
    SELECT mca.*
FROM mother_care_activities mca
INNER JOIN (
    SELECT beneficiary_ref_key,
           MAX(created_date_time) AS max_date
    FROM mother_care_activities
    WHERE mother_care_state = 'anc_due'
    GROUP BY beneficiary_ref_key
) latest
  ON mca.beneficiary_ref_key = latest.beneficiary_ref_key
 AND mca.created_date_time = latest.max_date
INNER JOIN beneficiaries_new bn
  ON mca.beneficiary_ref_key = bn.unique_key
WHERE bn.is_deleted = 0;
  ''');

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id!.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  Future<void> _loadAncVisitCount() async {
    try {
      setState(() => _isLoading = true);
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final ancDueRows = ashaUniqueKey == null || ashaUniqueKey.isEmpty
          ? <Map<String, dynamic>>[]
          : await db.rawQuery('''
    WITH RankedMCA AS (
      SELECT
        mca.*,
        ROW_NUMBER() OVER (
          PARTITION BY mca.beneficiary_ref_key
          ORDER BY mca.created_date_time DESC, mca.id DESC
        ) AS rn
      FROM mother_care_activities mca
      WHERE
        mca.is_deleted = 0
        AND mca.current_user_key = ?
    )
    SELECT r.*
    FROM RankedMCA r
    INNER JOIN beneficiaries_new bn
      ON r.beneficiary_ref_key = bn.unique_key
    WHERE
      r.rn = 1
      AND r.mother_care_state = 'anc_due'
      AND bn.is_deleted = 0
      AND bn.is_migrated = 0
    ORDER BY r.created_date_time DESC;
      ''', [ashaUniqueKey]);

      final ancDueBeneficiaryIds = ancDueRows
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final Set<String> countedIds = {};

      for (final row in rows) {
        final rawInfo = row['beneficiary_info'];
        if (rawInfo == null) continue;

        final info = rawInfo is String
            ? jsonDecode(rawInfo)
            : Map<String, dynamic>.from(rawInfo);

        final beneficiaryId = row['unique_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty) continue;

        final gender = info['gender']?.toString().toLowerCase() ?? '';
        if (gender != 'f' && gender != 'female') continue;

        final isPregnant =
            info['isPregnant']?.toString().toLowerCase() == 'yes';
        final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

        if (isPregnant || isAncDue) {
          countedIds.add(beneficiaryId);
        }
      }

      setState(() {
        _ancVisitCount = countedIds.length;
        _isLoading = false;
      });

      print('✅ ANC Visit Count: $_ancVisitCount');
    } catch (e, s) {
      print('❌ ANC Count Error: $e');
      print(s);
      setState(() {
        _ancVisitCount = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeliveryOutcomeCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      const ancRefKey = 'bt7gs9rl1a5d26mz';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      print('🔍 Loading Delivery Outcome count (aligned with screen)...');

      final results = await db.rawQuery(
        '''
WITH LatestMCA AS (
  SELECT
    mca.*,
    ROW_NUMBER() OVER (
      PARTITION BY mca.beneficiary_ref_key
      ORDER BY mca.created_date_time DESC, mca.id DESC
    ) AS rn
  FROM ${MotherCareActivitiesTable.table} mca
  WHERE mca.is_deleted = 0
    AND mca.current_user_key = ?          -- ✅ ASHA filter
),

DeliveryOutcomeOnly AS (
  SELECT *
  FROM LatestMCA
  WHERE rn = 1
    AND mother_care_state = 'delivery_outcome'
),

LatestANC AS (
  SELECT
    f.beneficiary_ref_key,
    f.form_json,
    ROW_NUMBER() OVER (
      PARTITION BY f.beneficiary_ref_key
      ORDER BY f.created_date_time DESC, f.id DESC
    ) AS rn
  FROM ${FollowupFormDataTable.table} f
  WHERE f.forms_ref_key = ?
    AND f.is_deleted = 0
    AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
    AND f.current_user_key = ?            -- ✅ ASHA filter
)

SELECT
  d.beneficiary_ref_key
FROM DeliveryOutcomeOnly d
LEFT JOIN LatestANC a
  ON a.beneficiary_ref_key = d.beneficiary_ref_key
 AND a.rn = 1
ORDER BY d.created_date_time DESC
''',
        [
          ashaUniqueKey,
          ancRefKey,     // 🔑 LatestANC (forms_ref_key)
          ashaUniqueKey, // 🔑 LatestANC (ASHA)
        ],
      );


      print('✅ Delivery Outcome Count = ${results.length}');

      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = results.length;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in _loadDeliveryOutcomeCount: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = 0;
        });
      }
    }
  }

  Future<void> _loadHBCNCount() async {
    try {
      print('🔍 Loading HBNC count...');
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // First, get all beneficiary_ref_keys that have either pnc_mother or hbnc_visit state
      final validBeneficiaries = await db.rawQuery('''
      SELECT DISTINCT mca.beneficiary_ref_key 
      FROM mother_care_activities mca
      WHERE mca.mother_care_state IN ('pnc_mother', 'pnc_mother')
      AND mca.is_deleted = 0
      AND mca.current_user_key = ?
    ''', [ashaUniqueKey]);

      if (validBeneficiaries.isEmpty) {
        print('ℹ️ No beneficiaries found with pnc_mother or pnc_mother state');
        if (mounted) {
          setState(() => _hbcnMotherCount = 0);
        }
        return;
      }

      final beneficiaryKeys = validBeneficiaries.map((e) => e['beneficiary_ref_key'] as String).toList();
      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');

      // Get delivery outcome records only for valid beneficiaries
      /*final dbOutcomes = await db.rawQuery('''
      SELECT DISTINCT beneficiary_ref_key 
      FROM followup_form_data 
      WHERE forms_ref_key = ? 
      AND current_user_key = ?
      AND beneficiary_ref_key IN ($placeholders)
    ''', [deliveryOutcomeKey, ashaUniqueKey, ...beneficiaryKeys]);
*/

      final dbOutcomes = await db.rawQuery('''
  SELECT DISTINCT ffd.beneficiary_ref_key
  FROM followup_form_data ffd
  INNER JOIN beneficiaries_new bn
      ON bn.unique_key = ffd.beneficiary_ref_key
  WHERE ffd.forms_ref_key = ?
    AND ffd.current_user_key = ?
    AND bn.current_user_key = ?
    AND bn.is_deleted = 0
    AND ffd.beneficiary_ref_key IN ($placeholders)
''', [
        deliveryOutcomeKey,
        ashaUniqueKey,
        ashaUniqueKey,
        ...beneficiaryKeys
      ]);

      final count = dbOutcomes.length;
      print('\n✅ Final HBNC Count: $count');
      print('   - Valid unique beneficiaries with delivery outcomes: $count');

      if (mounted) {
        setState(() {
          _hbcnMotherCount = count;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in _loadHBCNCount: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _hbcnMotherCount = 0);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Constant for the space between cards (2 gaps of 4px = 8px total used in row)
    const double gapSize = 4.0;
    const double totalGap = gapSize * 2;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context,
            _ancVisitCount + _deliveryOutcomeCount + _hbcnMotherCount);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(
          screenTitle: l10n?.gridMotherCare ?? 'Mother Care',
          showBack: false,
          icon1Image: 'assets/images/home.png',
          onIcon1Tap: () => Navigator.pop(context,
              _ancVisitCount + _deliveryOutcomeCount + _hbcnMotherCount),
        ),
        drawer: const CustomDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            // 1. LayoutBuilder to get the safe available width
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 2. Calculate card width dynamically
                // (Available Width - Total Gaps) / 3 cards
                final double cardWidth =
                    (constraints.maxWidth - totalGap) / 3;

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureCard(
                          width: cardWidth,
                          title: (l10n?.motherAncVisitTitle ?? 'ANC Visit')
                              .toString(),
                          count: _isLoading ? 0 : _ancVisitCount,
                          image: 'assets/images/pregnant-woman.png',
                          onClick: () {
                            Navigator.pushNamed(
                                context, Route_Names.Ancvisitlistscreen);
                          },
                        ),
                        const SizedBox(width: gapSize),
                        _FeatureCard(
                          width: cardWidth,
                          title: (l10n?.deliveryOutcomeTitle ??
                              'Delivery\nOutcome')
                              .toString(),
                          count: _deliveryOutcomeCount,
                          image: 'assets/images/mother.png',
                          onClick: () {
                            Navigator.pushNamed(
                                context, Route_Names.DeliveryOutcomeScreen);
                          },
                        ),
                        const SizedBox(width: gapSize),
                        _FeatureCard(
                          width: cardWidth,
                          title: (l10n?.hbncMotherTitle ?? 'HBNC Mother')
                              .toString(),
                          count: _hbcnMotherCount,
                          image: 'assets/images/pnc-mother.png',
                          onClick: () {
                            Navigator.pushNamed(
                                context, Route_Names.HBNCScreen);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final int count;
  final String image;
  final VoidCallback onClick;
  final double width;
  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
    required this.width,
  });
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final double cardHeight =
    MediaQuery.of(context).orientation == Orientation.portrait
        ? 15.h
        : 25.h;
    final scaleFactor = MediaQuery.of(context).textScaleFactor;
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: cardHeight,
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(1.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 1.5.h,
                ),
                Text(
                  title,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline,
                    fontSize: 14.sp,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
