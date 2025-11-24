import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
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

  // Matches ANCVisitListScreen._loadPregnantWomen logic, but only counts rows
  Future<void> _loadAncVisitCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      int count = 0;

      for (final row in rows) {
        try {
          // Parse the beneficiary info
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            continue;
          }

          // Match ANC list filter: isPregnant == 'yes' and female
          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final gender = info['gender']?.toString().toLowerCase() ?? '';
          if (gender != 'f' && gender != 'female') continue;

          count++;
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      if (mounted) {
        setState(() {
          _ancVisitCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading eligible pregnant women count: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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

  // Matches DeliveryOutcomeScreen._loadPregnancyOutcomeeCouples logic for counting
  Future<void> _loadDeliveryOutcomeCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // Same ANC ref key used in DeliveryOutcomeScreen
      const ancRefKey = 'bt7gs9rl1a5d26mz';

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
      ''');

      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = ancForms.length;
        });
      }
    } catch (e) {
      print('Error loading delivery outcome count: $e');
      if (mounted) {
        setState(() {
          _deliveryOutcomeCount = 0;
        });
      }
    }
  }

  Future<void> _loadHBCNCount() async {
    try {
      // Align with HBNCListScreen: count delivery outcomes with valid beneficiaries
      final db = await DatabaseProvider.instance.database;
      const deliveryOutcomeKey = '4r7twnycml3ej1vg';

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ?',
        whereArgs: [deliveryOutcomeKey],
      );

      int count = 0;

      for (final outcome in dbOutcomes) {
        try {
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            continue;
          }

          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ? AND is_deleted = 0',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiaryResults.isEmpty) {
            continue;
          }

          count++;
        } catch (e) {
          print('Error processing HBNC outcome for count: $e');
        }
      }

      if (mounted) {
        setState(() {
          _hbcnMotherCount = count;
        });
      }
    } catch (e) {
      print('Error loading HBCN count: $e');
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: l10n?.gridMotherCare ?? 'Mother Care',
        showBack: false,
        icon1Image: 'assets/images/home.png',

        onIcon1Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
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
    final double cardHeight = 15.h; // uniform height

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
            padding: const EdgeInsets.all(8),
            child: Column(

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      image,
                      width: 28.sp,
                      height: 28.sp,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.5.h,),
                Text(
                  title,
                  textAlign: TextAlign.center,
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
