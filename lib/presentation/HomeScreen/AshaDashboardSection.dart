import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import '../../l10n/app_localizations.dart' show AppLocalizations;
import '../RegisterNewHouseHold/RegisterNewHouseHold.dart';

class AshaDashboardSection extends StatelessWidget {
  final int? selectedGridIndex;
  final Function(int) onGridTap;
  final Function(int)? onBottomGridTap;
  final VoidCallback? onRoutineTap;
  final List<VoidCallback?>? mainGridActions;
  final List<VoidCallback?>? bottomGridActions;

  const AshaDashboardSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    this.onBottomGridTap,
    this.onRoutineTap,
    this.mainGridActions,
    this.bottomGridActions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> mainGridItems = [
      {"image": 'assets/images/plus.png', "label": l10n.gridRegisterNewHousehold},
      {"image": 'assets/images/home.png', "label": l10n.gridAllHousehold, "count": 3},
      {"image": 'assets/images/dashboard.png', "label": l10n.gridAllBeneficiaries, "count": 5},
      {"image": 'assets/images/beneficiaries.png', "label": l10n.gridMyBeneficiaries},
      {"image": 'assets/images/id-card.png', "label": l10n.gridAbhaGeneration},
      {"image": 'assets/images/work-in-progress.png', "label": l10n.gridWorkProgress},
      {"image": 'assets/images/couple.png', "label": l10n.gridEligibleCouple, "count": 5},
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Main Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mainGridItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
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
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.asset(
                                    item['image'],
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                  if (hasCount)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${item['count']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    item['label'],
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
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

                // Middle Box
                InkWell(
                  onTap: onRoutineTap,
                  child: Card(
                    color: AppColors.surface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            middleBox['image'],
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            middleBox['label'],
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = bottomGridItems[index];
                    return InkWell(
                      onTap: () => _onBottomGridTap(index),
                      child: Card(
                        elevation: 3,
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                item['image'],
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  item['label'],
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: AppColors.onSurface,
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
    }

    onGridTap(index);
  }

  void _onBottomGridTap(int index) {
    if (bottomGridActions != null && index < bottomGridActions!.length) {
      final action = bottomGridActions![index];
      if (action != null) {
        action();
        return;
      }
    }
    if (onBottomGridTap != null) {
      onBottomGridTap!(index);
    }
  }
}
