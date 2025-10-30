import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart' show AppLocalizations;
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

  const AshaDashboardSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    this.onBottomGridTap,
    this.onRoutineTap,
    this.mainGridActions,
    this.bottomGridActions,
    this.householdCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> mainGridItems = [
      {"image": 'assets/images/plus.png', "label": l10n.gridRegisterNewHousehold},
      {"image": 'assets/images/home.png', "label": l10n.gridAllHousehold, "count": householdCount ?? 0},
      {"image": 'assets/images/dashboard.png', "label": l10n.gridAllBeneficiaries, "count": 5},
      {"image": 'assets/images/beneficiaries.png', "label": l10n.gridMyBeneficiaries},
      {"image": 'assets/images/id-card.png', "label": l10n.gridAbhaGeneration},
      {"image": 'assets/images/work-in-progress.png', "label": l10n.gridWorkProgress},
      {"image": 'assets/images/couple.png', "label": l10n.gridEligibleCoupleASHA, "count": 5},
      {"image": 'assets/images/mother.png', "label": l10n.gridMotherCare, "count": 1},
      {"image": 'assets/images/toddler.png', "label": l10n.gridChildCare, "count": 5},
      {"image": 'assets/images/pregnant-woman.png', "label": l10n.gridHighRisk, "count": 7},
      {"image": 'assets/images/video.png', "label": l10n.gridAshaKiDuniya},
      {"image": 'assets/images/inventory.png', "label": l10n.gridTraining},
    ];

    final Map<String, dynamic> middleBox = {
      "image": 'assets/images/capsule2.png',
      "label": l10n.routine,
    };

    final List<Map<String, dynamic>> bottomGridItems = [
      {"image": 'assets/images/announcement.png', "label": l10n.announcement},
      {"image": 'assets/images/help-icon.png', "label": l10n.help},
      {"image": 'assets/images/autoimmune-disease.png', "label": l10n.ncd},
    ];


    
    return SafeArea(
      child: Stack(
        children: [
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: Image.asset(
          //     'assets/images/sakhi-bg.png',
          //     width: 120, // adjust size
          //     height: 120,
          //     fit: BoxFit.contain,
          //     color: Colors.grey.withOpacity(0.2),
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Main Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mainGridItems.length,
                  gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 0.5.h,
                    crossAxisSpacing: 0.5.w,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = mainGridItems[index];
                    final hasCount = item.containsKey('count');

                    return InkWell(
                      onTap: () => _onMainGridTap(context, index),
                      child: Card(
                        elevation: 3,
                        color: AppColors.surface,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.5.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.asset(
                                    item['image'],
                                    width: 7.w,
                                    height: 7.w,
                                    fit: BoxFit.contain,
                                  ),
                                  if (hasCount)
                                    Text(
                                      "${item['count']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                        fontSize: 16.sp
                                      ),
                                    ),
                                ],
                              ),
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
                                      fontSize: 15.5.sp,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                    color: AppColors.surface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1.5.h)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            middleBox['image'],
                            width: 7.w,
                            height: 7.w,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            middleBox['label'],
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5.sp,
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
                    mainAxisSpacing: 0.5.h,
                    crossAxisSpacing: 0.5.w,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = bottomGridItems[index];
                    return InkWell(
                      onTap: () => _onBottomGridTap(context, index),
                      child: Card(
                        elevation: 3,
                        color: AppColors.surface,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                item['image'],
                                width: 7.w,
                                height: 7.w,
                              ),
                              SizedBox(height: 1.h),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item['label'],
                                    textAlign: TextAlign.left,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15.5.sp,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      Navigator.pushNamed(context, Route_Names.ChildCareHomeScreen);
      return;
    }else if (index == 11) {
      Navigator.pushNamed(context, Route_Names.TrainingHomeScreen);
      return;
    }

    onGridTap(index);
  }

  void _onBottomGridTap(BuildContext context, int index) {
    if (bottomGridActions != null && index < bottomGridActions!.length) {
      final action = bottomGridActions![index];
      if (action != null) {
        action();
        return;
      }
    }

    // handle navigation for each bottom grid item
    switch (index) {
      case 0:
      // Announcement
        Navigator.pushNamed(context, Route_Names.Annoucement);
        break;
      case 1:
      // Help
        Navigator.pushNamed(context, Route_Names.HelpScreen);
        break;
      case 2:
      // NCD
        Navigator.pushNamed(context, Route_Names.NCDHome);
        break;
      default:
        if (onBottomGridTap != null) onBottomGridTap!(index);
    }
  }
}
