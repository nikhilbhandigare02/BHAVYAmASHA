import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:developer' as developer;
import '../../data/repositories/ChildCareRepository/ChildCareRepository.dart';
import 'child_care_count_provider.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';

import '../HomeScreen/HomeScreen.dart';

class ChildCareHomeScreen extends StatefulWidget {
  const ChildCareHomeScreen({super.key});

  @override
  State<ChildCareHomeScreen> createState() => _ChildCareHomeScreenState();
}

class _ChildCareHomeScreenState extends State<ChildCareHomeScreen> {
  final ChildCareCountProvider _countProvider = ChildCareCountProvider();
  late Future<Map<String, int>> _countsFuture;
  final ChildCareRepository _ccRepo = ChildCareRepository();

  @override
  void initState() {
    super.initState();
    developer.log('Initializing ChildCareHomeScreen', name: 'ChildCareHomeScreen');
    _countsFuture = Future.value({
      'registered': 0,
      'registrationDue': 0,
      'trackingDue': 0,
      'hbyc': 0,
      'deceased': 0,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCounts();
      _startCcScheduler();
      _printChildCareActivities();
    });
  }

  Future<void> _loadCounts() async {
    try {
      developer.log('Loading counts...', name: 'ChildCareHomeScreen');

      if (!mounted) return;

      setState(() {
        _countsFuture = Future.wait([
          _countProvider.getRegisteredChildCount(),
          _countProvider.getRegistrationDueCount(),
          _countProvider.getTrackingDueCount(),
          _countProvider.getHBYCCount(),
          _countProvider.getDeceasedCount(),
        ]).then((counts) {
          final result = {
            'registered': counts[0],
            'registrationDue': counts[1],
            'trackingDue': counts[2],
            'hbyc': counts[3],
            'deceased': counts[4],
          };

          developer.log('Counts loaded: $result', name: 'ChildCareHomeScreen');
          return result;
        }).catchError((error, stackTrace) {
          developer.log('Error in loading counts: $error',
              name: 'ChildCareHomeScreen',
              error: error,
              stackTrace: stackTrace);
          // Return default values in case of error
          return {
            'registered': 0,
            'registrationDue': 0,
            'trackingDue': 0,
            'hbyc': 0,
            'deceased': 0,
          };
        });
      });

    } catch (e, stackTrace) {
      developer.log('Error in _loadCounts: $e',
          name: 'ChildCareHomeScreen',
          error: e,
          stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _countsFuture = Future.value({
            'registered': 0,
            'registrationDue': 0,
            'trackingDue': 0,
            'hbyc': 0,
            'deceased': 0,
          });
        });
      }
    }
  }

  Future<void> _startCcScheduler() async {
    await _ccRepo.startAutoSyncChildCareActivitiesFromCurrentUser(
      lastId: '68ef7de137950f6821205f81',
      limit: 20,
    );
  }

  Future<void> _printChildCareActivities() async {
    final db = await DatabaseProvider.instance.database;
    final rows = await db.query('child_care_activities', orderBy: 'created_date_time DESC');
    developer.log('child_care_activities rows: ${rows.length}', name: 'ChildCareHomeScreen');
    for (final row in rows) {
      developer.log(jsonEncode(row), name: 'ChildCareHomeScreen');
    }
  }
  @override
  void dispose() {
    _ccRepo.stopAutoSyncChildCareActivities();
    super.dispose();
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String countKey,
    required String image,
    required String routeName,
    required Map<String, int> counts,
    // Removed width parameter
  }) {
    return _FeatureCard(
      // Removed width argument
      title: title,
      count: counts[countKey] ?? 0,
      image: image,
      onClick: () {
        Navigator.pushNamed(context, routeName).then((_) => _loadCounts());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Removed manual cardWidth calculations

    return FutureBuilder<Map<String, int>>(
      future: _countsFuture,
      builder: (context, snapshot) {

        final counts = snapshot.data ?? {
          'registered': 0,
          'registrationDue': 0,
          'trackingDue': 0,
          'hbyc': 0,
          'deceased': 0,
        };

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppHeader(
            screenTitle: (l10n?.gridChildCare ?? 'Child Care').toString(),
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
                      Expanded(
                        child: _buildCard(
                          context: context,
                          title: (l10n?.childRegisteredBeneficiaryListTitle ??
                              'Registered Child\nBeneficiary List')
                              .toString(),
                          countKey: 'registered',
                          image: 'assets/images/toddler.png',
                          routeName: Route_Names.RegisterChildScreen,
                          counts: counts,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCard(
                          context: context,
                          title: (l10n?.childRegisteredDueListTitle ??
                              'Child Registered\nDue List')
                              .toString(),
                          countKey: 'registrationDue',
                          image: 'assets/images/family.png',
                          routeName: Route_Names.RegisterChildDueList,
                          counts: counts,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCard(
                          context: context,
                          title: (l10n?.childTrackingDueListTitle ??
                              'Child Tracking\nDue List')
                              .toString(),
                          countKey: 'trackingDue',
                          image: 'assets/images/notes.png',
                          routeName: Route_Names.CHildTrackingDueList,
                          counts: counts,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildCard(
                          context: context,
                          title: (l10n?.hbycListTitle ?? 'HBYC List').toString(),
                          countKey: 'hbyc',
                          image: 'assets/images/pnc-mother.png',
                          routeName: Route_Names.HBYCList,
                          counts: counts,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildCard(
                          context: context,
                          title: (l10n?.deceasedChildTitle ?? 'Deceased Child')
                              .toString(),
                          countKey: 'deceased',
                          image: 'assets/images/death2.png',
                          routeName: Route_Names.DeseasedList,
                          counts: counts,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Empty placeholder Expanded for alignment
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final int count;
  final String image;
  final VoidCallback onClick;
  // Removed width property

  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    final scaleFactor = MediaQuery.of(context).textScaleFactor;
    final double cardHeight = MediaQuery.of(context).orientation == Orientation.portrait
        ? 15.h
        : 25.h;

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(12),
      // Removed width constraint from SizedBox
      child: SizedBox(
        height: cardHeight,
        child: Card(
          color: AppColors.background,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: EdgeInsets.all(1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
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
                SizedBox(height: 1.h),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.outline,
                        fontSize: 14.sp,
                      ),
                    ),
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