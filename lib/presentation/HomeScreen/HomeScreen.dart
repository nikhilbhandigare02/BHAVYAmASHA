import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

import '../../core/widgets/AppDrawer/Drawer.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../data/Local_Storage/local_storage_dao.dart';
import '../../l10n/app_localizations.dart';
import '../GuestBeneficiarySearch/GuestBeneficiarySearch.dart';
import 'TodaysProgramm.dart';
import 'AshaDashboardSection.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int? selectedGridIndex;

  Map<String, List<String>> apiData = {
    "Family Survey List": [],
    "Eligible Couple Due List": [],
    "ANC List": [],
    "HBNC List": [],
    "Routine Immunization (RI)": [],
  };

  bool isLoading = true;
  int householdCount = 0;
  int beneficiariesCount = 0;
  int eligibleCouplesCount = 0;
  int pregnantWomenCount = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
    fetchApiData();
    _loadHouseholdCount();
    _loadBeneficiariesCount();
    _loadEligibleCouplesCount();
    _loadPregnantWomenCount();
  }

  Future<void> _loadHouseholdCount() async {
    try {
      final count = await LocalStorageDao.instance.getHouseholdCount();
      if (mounted) {
        setState(() {
          householdCount = count;
        });
      }
    } catch (e) {
      print('Error loading household count: $e');
    }
  }

  Future<void> _loadBeneficiariesCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      int count = 0;
      for (final row in rows) {
        final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
        final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
        final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});
        // Head card
        if (head.isNotEmpty) count += 1;
        // Spouse card
        if (spouse.isNotEmpty) count += 1;
        // Children cards (+ father card per child)
        final children = (head['childrenDetails'] as List?) ?? const [];
        count += (children.length * 2);
      }
      if (mounted) {
        setState(() {
          beneficiariesCount = count;
        });
      }
    } catch (e) {
      print('Error loading beneficiaries count: $e');
    }
  }

  Future<void> _loadEligibleCouplesCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      int count = 0;
      
      for (final row in rows) {
        final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
        final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
        final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});
        
        // Check if head is eligible female
        if (_isEligibleFemale(head)) {
          count++;
        }
        
        // Check if spouse is eligible female
        if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
          count++;
        }
      }
      
      if (mounted) {
        setState(() {
          eligibleCouplesCount = count;
        });
      }
    } catch (e) {
      print('Error loading eligible couples count: $e');
    }
  }
  
  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    
    // Check gender
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    if (genderRaw != 'f' && genderRaw != 'female') return false;
    
    // Check marital status (use head's marital status if person is spouse)
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? 
                           person['marital_status']?.toString().toLowerCase() ??
                           head?['maritalStatus']?.toString().toLowerCase() ??
                           head?['marital_status']?.toString().toLowerCase() ??
                           '';
    if (maritalStatusRaw != 'married' && maritalStatusRaw != 'm') return false;
    
    // Check if pregnant
    final isPregnant = person['isPregnant']?.toString().toLowerCase() == 'true' ||
        person['isPregnant']?.toString().toLowerCase() == 'yes' ||
        person['pregnancyStatus']?.toString().toLowerCase() == 'pregnant';
    
    if (!isPregnant) return false;
    
    // Check age (15-49 years)
    final dob = person['dob']?.toString() ?? person['dateOfBirth']?.toString();
    if (dob != null && dob.isNotEmpty) {
      try {
        String dateStr = dob.toString();
        if (dateStr.contains('T')) {
          dateStr = dateStr.split('T')[0];
        }
        final birthDate = DateTime.tryParse(dateStr);
        if (birthDate != null) {
          final now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
            age--;
          }
          return age >= 15 && age <= 49;
        }
      } catch (e) {
        print('Error parsing date of birth: $e');
        return false;
      }
    }
    
    // If we can't determine age, assume eligible
    return true;
  }
  
  Future<void> _loadPregnantWomenCount() async {
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
            info = rawInfo is String 
                ? Map<String, dynamic>.from(jsonDecode(rawInfo) as Map) 
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
          if (_isEligibleFemale(head, head: head)) {
            count++;
          }

          // Check if spouse is eligible pregnant woman
          if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
            count++;
          }
        } catch (e) {
          print('Error processing beneficiary for pregnant women count: $e');
        }
      }

      if (mounted) {
        setState(() {
          pregnantWomenCount = count;
        });
      }
    } catch (e) {
      print('Error loading pregnant women count: $e');
    }
  }

  Future<void> fetchApiData() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      apiData = {
        l10n.listFamilySurvey: ["Family 1", "Family 2", "Family 3"],
        l10n.listEligibleCoupleDue: ["Couple 1", "Couple 2"],
        l10n.listANC: ["ANC 1", "ANC 2", "ANC 3", "ANC 4"],
        l10n.listHBNC: ["HBNC 1", "HBNC 2"],
        l10n.listRoutineImmunization: ["Child 1", "Child 2", "Child 3"],
      };
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
        onWillPop: () async {
          final shouldExit = await showConfirmationDialog(
            context: context,
            title: l10n.exitAppTitle, // Add to l10n: "Exit Application"
            message: l10n.exitAppMessage, // Add to l10n: "Are you sure you want to exit?"
            yesText: l10n.yes,
            noText: l10n.no,
          );
          return shouldExit ?? false;
        },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        screenTitle: l10n.homeTitle,
        showBack: false,
        icon1Image: 'assets/images/search.png',
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.GuestBeneficiarySearch),
        icon2Image: 'assets/images/img_1.png',
        onIcon2Tap: () => print("Notifications tapped"),
        icon3Image: 'assets/images/home.png',
        onIcon3Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          // Tabs
          Material(
            color: AppColors.background,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedIndex = 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.today,
                                color:AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.tabTodaysProgram,
                                style: TextStyle(
                                      fontSize: 15.sp,
                                  color: selectedIndex == 0
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 3,
                          color: selectedIndex == 0
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 50, color: AppColors.divider),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => selectedIndex = 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apps_sharp,
                                color: AppColors.primary

                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.tabAshaDashboard,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: selectedIndex == 1
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 3,
                          color: selectedIndex == 1
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: selectedIndex == 0
                ? isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: TodayProgramSection(
                selectedGridIndex: selectedGridIndex,
                onGridTap: (index) =>
                    setState(() => selectedGridIndex = index),
                apiData: apiData,
              ),
            )
                : SingleChildScrollView(
              child: AshaDashboardSection(
                householdCount: householdCount,
                beneficiariesCount: beneficiariesCount,
                eligibleCouplesCount: eligibleCouplesCount,
                pregnantWomenCount: pregnantWomenCount,
                selectedGridIndex: selectedGridIndex,
                onGridTap: (index) =>
                    setState(() => selectedGridIndex = index),
              ),
            ),
          ),

        ],
      ),
    ));
  }
}
