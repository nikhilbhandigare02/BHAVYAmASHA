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
import 'package:sizer/sizer.dart';

import '../../data/Database/tables/mother_care_activities_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/core/config/routes/Routes.dart' as AppRoutes;

class Mothercarehomescreen extends StatefulWidget {
  const Mothercarehomescreen({super.key});

  @override
  State<Mothercarehomescreen> createState() => _MothercarehomescreenState();
}

class _MothercarehomescreenState extends State<Mothercarehomescreen> with RouteAware {
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

  Future<void> _loadAncVisitCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // Get all beneficiaries that should be excluded
      final excludedStates = await db.query(
          'mother_care_activities',
          where: "mother_care_state IN ('delivery_outcome', 'hbnc_visit', 'pnc_mother')",
          columns: ['beneficiary_ref_key'],
          distinct: true
      );

      final Set<String> excludedBeneficiaryIds = excludedStates
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Get all anc_due records that are not in excluded states
      final ancDueRecords = await db.rawQuery('''
        SELECT DISTINCT mca.beneficiary_ref_key
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' 
          AND bn.is_deleted = 0
          AND mca.beneficiary_ref_key NOT IN (${excludedBeneficiaryIds.map((_) => '?').join(',')})
      ''', excludedBeneficiaryIds.toList());

      final Set<String> ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Get all beneficiaries
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final Set<String> uniqueBeneficiaries = {};

      for (final row in rows) {
        try {
          // Parse beneficiary info
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            continue;
          }

          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final beneficiaryId = row['unique_key']?.toString() ?? '';

          // Check if this beneficiary is in anc_due records
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

          // Skip if this beneficiary is in excluded states
          if (excludedBeneficiaryIds.contains(beneficiaryId)) {
            continue;
          }

          // Include if (pregnant OR anc_due) AND female
          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            if (beneficiaryId.isNotEmpty) {
              uniqueBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Add any anc_due records that weren't in the regular beneficiaries list
      for (final id in ancDueBeneficiaryIds) {
        if (id.isNotEmpty && !excludedBeneficiaryIds.contains(id)) {
          uniqueBeneficiaries.add(id);
        }
      }

      final count = uniqueBeneficiaries.length;

      if (mounted) {
        setState(() {
          _ancVisitCount = count;
          _isLoading = false;
        });
      }

    } catch (e, stackTrace) {
      print('❌ Error loading ANC visit count: $e');
      if (mounted) {
        setState(() {
          _ancVisitCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDeliveryOutcomeCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      const ancRefKey = 'bt7gs9rl1a5d26mz';

      final ancForms = await db.rawQuery('''
      SELECT DISTINCT
        f.beneficiary_ref_key,
        f.form_json,
        f.household_ref_key,
        f.forms_ref_key,
        f.created_date_time,
        f.id as form_id
      FROM ${FollowupFormDataTable.table} f
      LEFT JOIN ${MotherCareActivitiesTable.table} mca 
        ON f.beneficiary_ref_key = mca.beneficiary_ref_key
      WHERE 
        f.forms_ref_key = '$ancRefKey'
        AND f.is_deleted = 0
        AND (f.form_json LIKE '%"gives_birth_to_baby":"Yes"%' 
             AND mca.mother_care_state = 'delivery_outcome') 
      ORDER BY f.created_date_time DESC
    ''');

      if (ancForms.isEmpty) {
        if (mounted) {
          setState(() {
            _deliveryOutcomeCount = 0;
          });
        }
        return;
      }

      final Set<String> beneficiariesNeedingOutcome = {};
      final Set<String> processedBeneficiaries = {};

      for (final form in ancForms) {
        try {
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            continue;
          }

          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }
          processedBeneficiaries.add(beneficiaryRefKey);

          final deliveryOutcomeKey = FollowupFormDataTable.formUniqueKeys[
          FollowupFormDataTable.deliveryOutcome];
          final existingOutcome = await db.query(
            FollowupFormDataTable.table,
            where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
            whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
            limit: 1,
          );

          if (existingOutcome.isEmpty) {
            beneficiariesNeedingOutcome.add(beneficiaryRefKey);
          }
        } catch (e) {
          print('⚠️ Error processing form: $e');
        }
      }

      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = beneficiariesNeedingOutcome.length;
        });
      }

    } catch (e, stackTrace) {
      print('❌ Error in _loadDeliveryOutcomeCount: $e');
      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = 0;
        });
      }
    }
  }

  Future<void> _loadHBCNCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ? AND current_user_key = ?',
        whereArgs: [deliveryOutcomeKey, ashaUniqueKey],
      );

      if (dbOutcomes.isEmpty) {
        if (mounted) {
          setState(() => _hbcnMotherCount = 0);
        }
        return;
      }

      final Set<String> processedBeneficiaries = <String>{};

      for (final outcome in dbOutcomes) {
        try {
          final formJson = jsonDecode(outcome['form_json'] as String);
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            continue;
          }

          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }

          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiaryResults.isEmpty) {
            continue;
          }

          processedBeneficiaries.add(beneficiaryRefKey);

        } catch (e) {
          print('❌ Error processing outcome ${outcome['id']}: $e');
        }
      }

      final count = processedBeneficiaries.length;

      if (mounted) {
        setState(() {
          _hbcnMotherCount = count;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in _loadHBCNCount: $e');
      if (mounted) {
        setState(() => _hbcnMotherCount = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _ancVisitCount + _deliveryOutcomeCount + _hbcnMotherCount);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(
          screenTitle: l10n?.gridMotherCare ?? 'Mother Care',
          showBack: false,
          icon1Image: 'assets/images/home.png',
          onIcon1Tap: () => Navigator.pop(context, _ancVisitCount + _deliveryOutcomeCount + _hbcnMotherCount),
        ),
        drawer: const CustomDrawer(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        title: (l10n?.motherAncVisitTitle ?? 'ANC Visit').toString(),
                        count: _isLoading ? 0 : _ancVisitCount,
                        image: 'assets/images/pregnant-woman.png',
                        onClick: () {
                          Navigator.pushNamed(
                              context, Route_Names.Ancvisitlistscreen);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _FeatureCard(
                        title:
                        (l10n?.deliveryOutcomeTitle ?? 'Delivery\nOutcome')
                            .toString(),
                        count: _deliveryOutcomeCount,
                        image: 'assets/images/mother.png',
                        onClick: () {
                          Navigator.pushNamed(
                              context, Route_Names.DeliveryOutcomeScreen);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _FeatureCard(
                        title:
                        (l10n?.hbncMotherTitle ?? 'HBNC Mother').toString(),
                        count: _hbcnMotherCount,
                        image: 'assets/images/pnc-mother.png',
                        onClick: () {
                          Navigator.pushNamed(context, Route_Names.HBNCScreen);
                        },
                      ),
                    ),
                  ],
                ),
              ],
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

  // Width is no longer needed as Expanded handles the sizing
  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final double cardHeight = MediaQuery.of(context).orientation == Orientation.portrait
        ? 15.h
        : 25.h;
    final scaleFactor = MediaQuery.of(context).textScaleFactor;

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(10),
      // Removed SizedBox width constraint
      child: SizedBox(
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
                SizedBox(height: 1.5.h,),
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