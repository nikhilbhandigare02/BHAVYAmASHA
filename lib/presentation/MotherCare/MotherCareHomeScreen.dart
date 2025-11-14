import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
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
  int _hbcnMotherCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEligiblePregnantWomenCount();
    _loadHBCNCount();
  }

  Future<void> _loadEligiblePregnantWomenCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      int count = 0;

      for (final row in rows) {
        try {
          // Check if is_family_planning is set
          final isFamilyPlanning = row['is_family_planning'] == 1 || 
                                 row['is_family_planning'] == '1' ||
                                 (row['is_family_planning']?.toString().toLowerCase() == 'true');
          
          if (!isFamilyPlanning) continue;

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

          // Process head and spouse
          final head = (info['head_details'] is Map)
              ? Map<String, dynamic>.from(info['head_details'] as Map)
              : <String, dynamic>{};

          final spouse = (info['spouse_details'] is Map)
              ? Map<String, dynamic>.from(info['spouse_details'] as Map)
              : <String, dynamic>{};

          // Check if head is eligible pregnant woman
          if (_isEligiblePregnantWoman(head, spouse)) {
            count++;
          }

          // Check if spouse is eligible pregnant woman
          if (spouse.isNotEmpty && _isEligiblePregnantWoman(spouse, head)) {
            count++;
          }
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

  bool _isEligiblePregnantWoman(Map<String, dynamic> person, Map<String, dynamic> otherPerson) {
    try {
      final gender = (person['gender']?.toString().toLowerCase()?.trim() ?? '');
      
      final maritalStatus = (person['maritalStatus']?.toString().toLowerCase()?.trim() ??
          person['marital_status']?.toString().toLowerCase()?.trim() ??
          otherPerson['maritalStatus']?.toString().toLowerCase()?.trim() ??
          otherPerson['marital_status']?.toString().toLowerCase()?.trim() ??
          '');

      final isPregnant = person['isPregnant']?.toString().toLowerCase() == 'true' ||
          person['isPregnant']?.toString().toLowerCase() == 'yes' ||
          person['pregnancyStatus']?.toString().toLowerCase() == 'pregnant';

      final dob = person['dob'] ?? person['dateOfBirth'];
      final age = _calculateAge(dob);

      return (gender == 'f' || gender == 'female') &&
          (maritalStatus == 'married' || maritalStatus == 'm') &&
          (age != null && age >= 15 && age <= 49) &&
          isPregnant;
    } catch (e) {
      print('Error checking eligibility: $e');
      return false;
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

  Future<void> _loadHBCNCount() async {
    try {
      // Get all delivery outcomes
      final deliveryOutcomes = await SecureStorageService.getDeliveryOutcomes();
      
      // Count only submitted outcomes
      int count = 0;
      for (var outcome in deliveryOutcomes) {
        if (outcome['isSubmit'] == true) {
          count++;
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
                    count: 0,
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
