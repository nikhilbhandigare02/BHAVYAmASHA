import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import '../../core/widgets/AppDrawer/Drawer.dart';
import '../../core/widgets/AppHeader/AppHeader.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
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
  int householdCount = 0;

  Map<String, List<String>> apiData = {
    "Family Survey List": [],
    "Eligible Couple Due List": [],
    "ANC List": [],
    "HBNC List": [],
    "Routine Immunization (RI)": [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
    fetchApiData();
    _loadHouseholdCount();
  }

  Future<void> _loadHouseholdCount() async {
    try {
      final households = await LocalStorageDao.instance.getAllHouseholds();
      if (mounted) {
        setState(() {
          householdCount = households.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load household count')),
        );
      }
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
          title: l10n.exitAppTitle,
          message: l10n.exitAppMessage,
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
          icon1: Icons.search,
          onIcon1Tap: () =>
              Navigator.pushNamed(context, Route_Names.GuestBeneficiarySearch),
          icon2: Icons.notifications,
          onIcon2Tap: () => debugPrint("Notifications tapped"),
          icon3: Icons.home,
          onIcon3Tap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
        drawer: const CustomDrawer(),
        body: Column(
          children: [
            // Tabs
            Material(
              elevation: 3,
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
                                Icon(Icons.calendar_month_outlined,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.tabTodaysProgram,
                                  style: TextStyle(
                                    color: selectedIndex == 0
                                        ? AppColors.primary
                                        : AppColors.outline,
                                    fontWeight: FontWeight.bold,
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
                                Icon(Icons.apps_sharp, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.tabAshaDashboard,
                                  style: TextStyle(
                                    color: selectedIndex == 1
                                        ? AppColors.primary
                                        : AppColors.outline,
                                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 8),

            Expanded(
              child: selectedIndex == 0
                  ? (isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: TodayProgramSection(
                  selectedGridIndex: selectedGridIndex,
                  onGridTap: (index) =>
                      setState(() => selectedGridIndex = index),
                  apiData: apiData,
                ),
              ))
                  : SingleChildScrollView(
                child: AshaDashboardSection(
                  selectedGridIndex: selectedGridIndex,
                  onGridTap: (index) =>
                      setState(() => selectedGridIndex = index),
                  householdCount: householdCount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
