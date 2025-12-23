import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart' show AppLocalizations;
import '../ClusterMeeting/ClusterMeeting/ClusterMeetingScreen.dart';
import '../High-Risk/High_Risk.dart';
import '../RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';

class AshaDashboardSection extends StatelessWidget {
  final int? selectedGridIndex;
  final Function(int) onGridTap;
  final Function(int)? onBottomGridTap;
  final VoidCallback? onRoutineTap;
  final List<VoidCallback?>? mainGridActions;
  final List<VoidCallback?>? bottomGridActions;
  final int? householdCount;
  final int? beneficiariesCount;
  final int? eligibleCouplesCount;
  final int? pregnantWomenCount;
  final int? ancVisitCount;
  final int? childRegisteredCount;
  final int? highRiskCount;
  final int? ncdCount;
  final int appRoleId;


  const AshaDashboardSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    this.onBottomGridTap,
    this.onRoutineTap,
    this.mainGridActions,
    this.bottomGridActions,
    this.householdCount,
    this.beneficiariesCount,
    this.eligibleCouplesCount,
    this.pregnantWomenCount,
    this.ancVisitCount,
    this.childRegisteredCount,
    this.highRiskCount,
    this.ncdCount,
    required this.appRoleId,

  });

  // Helper method to get responsive icon size
  double getIconSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // Use a combination of screen width and height to get a consistent size
    final baseSize = isLandscape 
        ? screenSize.height * 0.05  // Increased size in landscape (from 0.04)
        : screenSize.width * 0.07;  // Normal size in portrait
    
    // Ensure the icon size has reasonable bounds
    return baseSize.clamp(24.0, 36.0);  // Increased min and max sizes
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconSize = getIconSize(context);

    final List<Map<String, dynamic>> mainGridItems = [
      {"image": 'assets/images/plus.png', "label": l10n.gridRegisterNewHousehold},
      {"image": 'assets/images/home.png', "label": l10n.gridAllHousehold, "count": householdCount ?? 0},
      {"image": 'assets/images/dashboard.png', "label": l10n.gridAllBeneficiaries, "count": beneficiariesCount ?? 0},
      {"image": 'assets/images/beneficiaries.png', "label": l10n.gridMyBeneficiaries},
      {"image": 'assets/images/id-card.png', "label": l10n.gridAbhaGeneration},
      {"image": 'assets/images/work-in-progress.png', "label": l10n.gridWorkProgress},
      {"image": 'assets/images/couple.png', "label": l10n.gridEligibleCoupleASHA, "count": eligibleCouplesCount ?? 0},
      {"image": 'assets/images/mother.png', "label": l10n.gridMotherCare, "count": ancVisitCount ?? 0},
      {"image": 'assets/images/toddler.png', "label": l10n.gridChildCare, "count": childRegisteredCount ?? 0},
      {"image": 'assets/images/hrp.png', "label": l10n.gridHighRisk, "count": highRiskCount ?? 0},
      {"image": 'assets/images/video.png', "label": l10n.gridAshaKiDuniya},
      {"image": 'assets/images/inventory.png', "label": l10n.gridTraining},
    ];

    final Map<String, dynamic> middleBox = {
      "image": 'assets/images/capsule2.png',
      "label": l10n.routine,
    };

    final List<Map<String, dynamic>> bottomGridItems = [
      {"image": 'assets/images/announcement.png', "label": l10n.announcements},
      if (appRoleId == 4)
        {"image": 'assets/images/beneficiaries.png', "label": l10n.clusterMeetings},
      {"image": 'assets/images/help-icon.png', "label": '${l10n.help}\nनियम'},
      {"image": 'assets/images/autoimmune-disease.png', "label": l10n.ncd, "count": ncdCount ?? 0},
    ];



    return SafeArea(
      child: Stack(
        children: [
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: Image.asset(
          //     'assets/images/sakhi-bg.jpg',
          //     width: 25.h, // adjust size
          //     fit: BoxFit.cover,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mainGridItems.length,
                  gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 0.4.h,
                    crossAxisSpacing: 0.4.w,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final item = mainGridItems[index];
                    final hasCount = item.containsKey('count');

                    return InkWell(
                      onTap: () => _onMainGridTap(context, index),
                      child: Card(
                        elevation: 2,
                        color: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.8.h),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.5.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: iconSize,
                                      maxHeight: iconSize,
                                    ),
                                    child: Image.asset(
                                      item['image'],
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.contain,
                                      color: index == 0 ? AppColors.primary : null,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item['label'],
                                        textAlign: TextAlign.left,
                                        softWrap: true,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15.sp,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (hasCount)
                              Positioned(
                                top: 0.8.h,
                                right: 1.5.w,
                                child: Text(
                                  "${item['count']}",
                                  style: TextStyle(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );

                  },
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: () {

                      Navigator.pushNamed(context, Route_Names.Routinescreen);

                  },
                  child: Card(
                    color: AppColors.background,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.8.h)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: iconSize,
                              maxHeight: iconSize,
                            ),
                            child: Image.asset(
                              middleBox['image'],
                              width: iconSize,
                              height: iconSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            middleBox['label'],
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w400,
                              fontSize: 15.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 8),

                // Bottom Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bottomGridItems.length,
                  gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 0.4.h,
                    crossAxisSpacing: 0.4.w,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final item = bottomGridItems[index];
                    return InkWell(
                      onTap: () => _onBottomGridTap(context, index),
                      child: Card(
                        elevation: 2,
                        color: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.8.h),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.9.h),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: iconSize,
                                      maxHeight: iconSize,
                                    ),
                                    child: Image.asset(
                                      item['image'],
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Flexible(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        item['label'],
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15.sp,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (item.containsKey('count'))
                              Positioned(
                                top: 0.8.h,
                                right: 1.5.w,
                                child: Text(
                                  "${item['count']}",
                                  style: TextStyle(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );

                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMainGridTap(BuildContext context, int index) {
    if (mainGridActions != null && index < mainGridActions!.length) {
      final action = mainGridActions![index];
      if (action != null) {
        action();
        return;
      }
    }
    if (index == 0) {
      Navigator.pushNamed(context, Route_Names.RegisterNewHousehold);
      return;
    }else if (index == 1) {
      Navigator.pushNamed(context, Route_Names.AllHousehold);
      return;
    }else if (index == 2) {
      Navigator.pushNamed(context, Route_Names.AllBeneficiaryScreen);
      return;
    }else if (index == 3) {
      Navigator.pushNamed(context, Route_Names.Mybeneficiaries);
      return;
    }else if (index == 4) {
      Navigator.pushNamed(context, Route_Names.ABHAGeneration);
      return;
    }else if (index == 5) {
      Navigator.pushNamed(context, Route_Names.WorkProgress);
      return;
    }else if (index == 6) {
      Navigator.pushNamed(context, Route_Names.EligibleCoupleHomeScreen);
      return;
    }else if (index == 7) {
      Navigator.pushNamed(context, Route_Names.Mothercarehomescreen);
      return;
    }else if (index == 8) {
      Navigator.pushNamed(context, Route_Names.ChildCareHomeScreen);
      return;

    }else if (index == 9) {
      Navigator.pushNamed(context, Route_Names.HighRisk);
      return;
    }else if (index == 10) {
      Navigator.pushNamed(context, Route_Names.AshaKiDuniyaScreen);
      return;
    }else if (index == 11) {
      Navigator.pushNamed(context, Route_Names.TrainingHomeScreen);
      return;
    }

    onGridTap(index);
  }

  void _onBottomGridTap(BuildContext context, int index) {
    int dynamicIndex = index;

    bool hasCluster = appRoleId == 4;

    if (!hasCluster && index >= 1) {
      dynamicIndex = index + 1;
    }

    switch (dynamicIndex) {
      case 0:
        Navigator.pushNamed(context, Route_Names.Annoucement);
        break;
      case 1:
        if (hasCluster) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClusterMeetingScreen()),
          );
        }
        break;
      case 2:
        Navigator.pushNamed(context, Route_Names.HelpScreen);
        break;
      case 3:
        Navigator.pushNamed(context, Route_Names.NCDHome);
        break;
    }
  }}
