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

import '../HomeScreen/HomeScreen.dart';

class Mothercarehomescreen extends StatefulWidget {
  const Mothercarehomescreen({super.key});

  @override
  State<Mothercarehomescreen> createState() => _MothercarehomescreenState();
}

class _MothercarehomescreenState extends State<Mothercarehomescreen> {
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

  Future<void> _loadAncVisitCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // Step 1: Get all anc_due beneficiary IDs
      final ancDueRecords = await db.rawQuery('''
      SELECT DISTINCT mca.beneficiary_ref_key
      FROM mother_care_activities mca
      INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
      WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
    ''');

      final Set<String> ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Step 2: Get all beneficiaries with delivery outcomes (CRITICAL - matches exact query from _loadPregnantWomen)
      final deliveryOutcomes = await db.query(
          'followup_form_data',
          where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND form_json LIKE '%\"gives_birth_to_baby\":\"Yes\"%'",
          columns: ['beneficiary_ref_key']
      );

      final Set<String?> deliveredBeneficiaryIds = deliveryOutcomes
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      // Step 3: Process all beneficiaries
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

          // CRITICAL: Skip if has delivery outcome
          if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
            continue;
          }

          // Include if (pregnant OR anc_due) AND female AND no delivery outcome
          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            if (beneficiaryId.isNotEmpty) {
              uniqueBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (e) {
          // Skip problematic records
          continue;
        }
      }


      for (final id in ancDueBeneficiaryIds) {
        if (id.isNotEmpty && !deliveredBeneficiaryIds.contains(id)) {
          uniqueBeneficiaries.add(id);
        }
      }

      // Final count
      final count = uniqueBeneficiaries.length;

      if (mounted) {
        setState(() {
          _ancVisitCount = count;
          _isLoading = false;
        });
      }

      print('✅ ANC Visit Count: $count (Total unique pregnant women without delivery outcome)');

    } catch (e, stackTrace) {
      print('❌ Error loading ANC visit count: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _ancVisitCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    try {
      String dateStr = dob.toString();
      if (dateStr.contains('T')) {
        dateStr = dateStr.split('T')[0];
      }
      final birthDate = DateTime.tryParse(dateStr);
      if (birthDate == null) return null;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }


  Future<void> _loadDeliveryOutcomeCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // CRITICAL: Same ANC ref key used in DeliveryOutcomeScreen
      const ancRefKey = 'bt7gs9rl1a5d26mz';

      print('🔍 Loading Delivery Outcome count...');

      // Step 1: Get all ANC forms with gives_birth_to_baby = "Yes"
      final ancForms = await db.rawQuery('''
      SELECT 
        f.beneficiary_ref_key,
        f.form_json,
        f.household_ref_key,
        f.forms_ref_key,
        f.created_date_time,
        f.id as form_id
      FROM ${FollowupFormDataTable.table} f
      WHERE 
        f.forms_ref_key = '$ancRefKey'
        AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
        AND f.is_deleted = 0
      ORDER BY f.created_date_time DESC
    ''');

      print('📊 Found ${ancForms.length} ANC forms with gives_birth_to_baby: Yes');

      if (ancForms.isEmpty) {
        print('ℹ️ No ANC forms found with gives_birth_to_baby: Yes');
        if (mounted) {
          setState(() {
            _deliveryOutcomeCount = 0;
          });
        }
        return;
      }

      // Step 2: Get the delivery outcome form key
      final deliveryOutcomeKey = FollowupFormDataTable.formUniqueKeys[
      FollowupFormDataTable.deliveryOutcome];

      print('🔑 Delivery Outcome Key: $deliveryOutcomeKey');

      // Step 3: Track unique beneficiaries that need delivery outcome
      final Set<String> beneficiariesNeedingOutcome = {};
      final Set<String> beneficiariesProcessed = {};

      for (final form in ancForms) {
        try {
          // Get beneficiary reference key
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            print('⚠️ Skipping form - missing beneficiary_ref_key');
            continue;
          }

          // Skip if we've already processed this beneficiary
          // (handles duplicates from multiple ANC forms)
          if (beneficiariesProcessed.contains(beneficiaryRefKey)) {
            print('⏩ Already processed beneficiary: $beneficiaryRefKey');
            continue;
          }

          beneficiariesProcessed.add(beneficiaryRefKey);

          // Check if delivery outcome already exists for this beneficiary
          final existingOutcome = await db.query(
            FollowupFormDataTable.table,
            where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
            whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
            limit: 1,
          );

          if (existingOutcome.isNotEmpty) {
            print('✅ Delivery outcome already exists for: $beneficiaryRefKey');
            continue; // Skip - already has outcome
          }

          // CRITICAL: Check if beneficiary exists in beneficiaries_new table
          // This matches the logic in _loadPregnancyOutcomeeCouples where
          // it tries to fetch beneficiary data
          Map<String, dynamic>? beneficiaryRow;
          try {
            beneficiaryRow = await LocalStorageDao.instance
                .getBeneficiaryByUniqueKey(beneficiaryRefKey);

            // If not found in new table, try legacy table
            if (beneficiaryRow == null) {
              final results = await db.query(
                'beneficiaries_new',
                where: 'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
                whereArgs: [beneficiaryRefKey],
                limit: 1,
              );

              if (results.isNotEmpty) {
                beneficiaryRow = Map<String, dynamic>.from(results.first);
              }
            }
          } catch (e) {
            print('⚠️ Error fetching beneficiary $beneficiaryRefKey: $e');
          }

          // Even if beneficiary not found, still count it
          // (matches screen behavior where it processes the form anyway)
          beneficiariesNeedingOutcome.add(beneficiaryRefKey);
          print('📝 Added to count: $beneficiaryRefKey (Total: ${beneficiariesNeedingOutcome.length})');

        } catch (e) {
          print('❌ Error processing form: $e');
          continue;
        }
      }

      final count = beneficiariesNeedingOutcome.length;
      print('✅ Final Delivery Outcome Count: $count');
      print('   - Total ANC forms with birth: ${ancForms.length}');
      print('   - Unique beneficiaries needing outcome: $count');

      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = count;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading delivery outcome count: $e');
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
      const deliveryOutcomeKey = '4r7twnycml3ej1vg';

      print('🔑 Using delivery outcome key: $deliveryOutcomeKey');

      // Step 1: Get all delivery outcome records
      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ?',
        whereArgs: [deliveryOutcomeKey],
      );

      print('📊 Found ${dbOutcomes.length} delivery outcome records');

      if (dbOutcomes.isEmpty) {
        print('ℹ️ No delivery outcomes found');
        if (mounted) {
          setState(() {
            _hbcnMotherCount = 0;
          });
        }
        return;
      }

      // Step 2: Track unique beneficiaries (matches screen's deduplication logic)
      final Set<String> processedBeneficiaries = <String>{};

      // Step 3: Process each outcome (exactly matching screen logic)
      for (final outcome in dbOutcomes) {
        try {
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          print('\n📋 Processing outcome ID: ${outcome['id']}');
          print('   Beneficiary Ref Key: $beneficiaryRefKey');

          // CRITICAL: Skip if beneficiary_ref_key is null or empty
          // (matches screen: "if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty)")
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            print('   ⚠️ Missing beneficiary_ref_key - SKIPPING');
            continue;
          }

          // CRITICAL: Skip duplicates (matches screen's processedBeneficiaries logic)
          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            print('   ℹ️ Already processed - SKIPPING duplicate');
            continue;
          }

          // CRITICAL: Check if beneficiary exists in beneficiaries_new table
          // (matches screen: "await db.query('beneficiaries_new', where: 'unique_key = ?')")
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );

          // CRITICAL: Skip if no beneficiary found
          // (matches screen: "if (beneficiaryResults.isEmpty) { continue; }")
          if (beneficiaryResults.isEmpty) {
            print('   ⚠️ No beneficiary found - SKIPPING');
            continue;
          }

          print('   ✅ Found beneficiary: ${beneficiaryResults.first['id']}');

          // CRITICAL: Parse beneficiary_info to ensure it's valid
          // (matches screen's parsing logic)
          final beneficiaryInfoRaw = beneficiaryResults.first['beneficiary_info'] as String? ?? '{}';

          try {
            final beneficiaryInfo = jsonDecode(beneficiaryInfoRaw) as Map<String, dynamic>;
            print('   ✅ Valid beneficiary_info parsed');

            // Successfully parsed - add to processed set
            processedBeneficiaries.add(beneficiaryRefKey);
            print('   ✅ Added to count (Total: ${processedBeneficiaries.length})');

          } catch (e) {
            // CRITICAL: Skip if beneficiary_info can't be parsed
            // (matches screen: "catch (e) { print('Error parsing beneficiary info: $e'); continue; }")
            print('   ❌ Error parsing beneficiary_info - SKIPPING: $e');
            continue;
          }

        } catch (e) {
          print('   ❌ Error processing outcome: $e');
          continue;
        }
      }

      final count = processedBeneficiaries.length;
      print('\n✅ Final HBNC Count: $count');
      print('   - Total delivery outcomes: ${dbOutcomes.length}');
      print('   - Valid unique beneficiaries: $count');

      if (mounted) {
        setState(() {
          _hbcnMotherCount = count;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading HBNC count: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hbcnMotherCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 🔹 3 cards per row (with even spacing)
    final double totalHorizontalPadding = 12 * 2;
    final double spacingBetweenCards = 4 * 2;
    final double cardWidth = (MediaQuery.of(context).size.width -
        totalHorizontalPadding -
        spacingBetweenCards) /
        3;

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
                    _FeatureCard(
                      width: cardWidth,
                      title: (l10n?.motherAncVisitTitle ?? 'ANC Visit').toString(),
                      count: _isLoading ? 0 : _ancVisitCount,
                      image: 'assets/images/pregnant-woman.png',
                      onClick: () {
                        Navigator.pushNamed(
                            context, Route_Names.Ancvisitlistscreen);
                      },
                    ),
                    const SizedBox(width: 4),
                    _FeatureCard(
                      width: cardWidth,
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
                    const SizedBox(width: 4),
                    _FeatureCard(
                      width: cardWidth,
                      title:
                      (l10n?.hbncMotherTitle ?? 'HBNC Mother').toString(),
                      count: _hbcnMotherCount,
                      image: 'assets/images/pnc-mother.png',
                      onClick: () {
                        Navigator.pushNamed(context, Route_Names.HBNCScreen);
                      },
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
    final double cardHeight = 15.h;
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
