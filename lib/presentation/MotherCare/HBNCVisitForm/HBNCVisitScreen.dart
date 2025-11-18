import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/GeneralDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/MotherDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/ChildDetails.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class HbncVisitScreen extends StatefulWidget {
  final Map<String, dynamic>? beneficiaryData;
  
  const HbncVisitScreen({super.key, this.beneficiaryData});

  @override
  State<HbncVisitScreen> createState() => _HbncVisitScreenState();
}

class _HbncVisitScreenState extends State<HbncVisitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final beneficiaryData = (widget as dynamic).beneficiaryData;
    
    return BlocProvider(
      create: (context) => HbncVisitBloc(),
      child: Builder(
        builder: (context) => Scaffold(
          body: BlocListener<HbncVisitBloc, HbncVisitState>(
            listenWhen: (previous, current) => 
                (previous.validationTick != current.validationTick) ||
                (previous.isSaving && !current.isSaving && current.saveSuccess),
            listener: (context, state) {
              // Handle validation errors
              final idx = _tabController.index;
              if (state.lastValidatedIndex == idx && state.validationErrors.isNotEmpty) {
                final t = AppLocalizations.of(context)!;
                final first = state.validationErrors.first;
                final localized = _mapErrorCodeToText(t, first);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localized)),
                );
              }
              
              // Handle successful save
              if (state.saveSuccess && !state.isSaving) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.dataSavedSuccessfully),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                if (mounted) {
                  Future.delayed(const Duration(milliseconds: 2200), () {
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, Route_Names.HBNCScreen,  (route) => false,);
                    }
                  });
                }
              }
              
              if (state.lastValidatedIndex == idx &&
                  !state.lastValidationWasSave && 
                  state.validationErrors.isEmpty) {
                final newIndex = idx + 1;
                if (newIndex < _tabController.length) {
                  _tabController.animateTo(newIndex);
                  context.read<HbncVisitBloc>().add(TabChanged(newIndex));
                }
              }
              
              // Handle save after validation
              if (state.lastValidatedIndex == idx && 
                  state.lastValidationWasSave && 
                  state.validationErrors.isEmpty) {
                final beneficiaryData = (widget as dynamic).beneficiaryData;
                context.read<HbncVisitBloc>().add(
                  SaveHbncVisit(beneficiaryData: beneficiaryData),
                );
              }
            },
            child: Column(
              children: [
                AppHeader(
                  screenTitle: t.hbncListTitle,
                  showBack: true,
                  icon1Widget: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          t.previousVisits,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onIcon1Tap: () {
                    Navigator.pushNamed(context, Route_Names.previousVisit);
                  },
                ),
                Container(
                  color: AppColors.primary,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true, // ✅ makes the tabs scrollable
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: t.tabGeneralDetails),
                      Tab(text: t.tabMotherDetails),
                      Tab(text: t.tabNewbornDetails),
                    ],
                    onTap: (index) =>
                        context.read<HbncVisitBloc>().add(TabChanged(index)),
                  ),
                ),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        GeneralDetailsTab(beneficiaryId: beneficiaryData?['unique_key']?.toString() ?? ''),
                        const MotherDetailsTab(),
                        const ChildDetailsTab(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final idx = _tabController.index;
                      final isLast = idx >= _tabController.length - 1;
                      final t = AppLocalizations.of(context)!;
                      return Row(
                        children: [
                          Expanded(
                            child: RoundButton(
                              title: t.previousButton,
                              onPress: () {
                                final newIndex = idx - 1;
                                _tabController.animateTo(newIndex);
                                context
                                    .read<HbncVisitBloc>()
                                    .add(TabChanged(newIndex));
                              },
                              disabled: idx == 0,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isLast
                                ? BlocConsumer<HbncVisitBloc, HbncVisitState>(
                              listener: (context, state) {
                                // Handle any state changes after save
                                if (state.saveSuccess) {
                                  // Reset form or navigate away
                                  Navigator.pop(context, true);
                                }
                              },
                              builder: (context, state) {
                                return RoundButton(
                                  title: t.saveButton,
                                  isLoading: state.isSaving,
                                  onPress: () {
                                    if (!state.isSaving) {
                                      if (_formKey.currentState?.validate() ?? true) {
                                        context.read<HbncVisitBloc>().add(
                                          ValidateSection(
                                            _tabController.index,
                                            isSave: true,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            )
                                : RoundButton(
                              title: t.nextButton,
                              onPress: () {
                                context
                                    .read<HbncVisitBloc>()
                                    .add(ValidateSection(idx));
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
  }

  String _mapErrorCodeToText(AppLocalizations t, String code) {
    final m = <String, String>{
      'err_visit_day_required': t.err_visit_day_required,
      'err_visit_date_required': t.err_visit_date_required,
      'err_mother_status_required': t.err_mother_status_required,
      'err_mcp_mother_required': t.err_mcp_mother_required,
      'err_post_delivery_problems_required': t.err_post_delivery_problems_required,
      'err_breastfeeding_problems_required': t.err_breastfeeding_problems_required,
      'err_pads_per_day_required': t.err_pads_per_day_required,
      'err_mothers_temperature_required': t.err_mothers_temperature_required,
      'err_foul_discharge_high_fever_required': t.err_foul_discharge_high_fever_required,
      'err_abnormal_speech_or_seizure_required': t.err_abnormal_speech_or_seizure_required,
      'err_counseling_advice_required': t.err_counseling_advice_required,
      'err_milk_not_producing_or_less_required': t.err_milk_not_producing_or_less_required,
      'err_nipple_cracks_pain_or_engorged_required': t.err_nipple_cracks_pain_or_engorged_required,
      'err_baby_condition_required': t.err_baby_condition_required,
      'err_baby_name_required': t.err_baby_name_required,
      'err_baby_gender_required': t.err_baby_gender_required,
      'err_baby_weight_required': t.err_baby_weight_required,
      'err_newborn_temperature_required': t.err_newborn_temperature_required,
      'err_infant_temp_unit_required': t.err_infant_temp_unit_required,
      'err_weight_color_match_required': t.err_weight_color_match_required,
      'err_weighing_scale_color_required': t.err_weighing_scale_color_required,
      'err_mother_reports_temp_or_chest_indrawing_required': t.err_mother_reports_temp_or_chest_indrawing_required,
      'err_bleeding_umbilical_cord_required': t.err_bleeding_umbilical_cord_required,
      'err_pus_in_navel_required': t.err_pus_in_navel_required,
      'err_routine_care_done_required': t.err_routine_care_done_required,
      'err_breathing_rapid_required': t.err_breathing_rapid_required,
      'err_congenital_abnormalities_required': t.err_congenital_abnormalities_required,
      'err_eyes_normal_required': t.err_eyes_normal_required,
      'err_eyes_swollen_or_pus_required': t.err_eyes_swollen_or_pus_required,
      'err_skin_fold_redness_required': t.err_skin_fold_redness_required,
      'err_newborn_jaundice_required': t.err_newborn_jaundice_required,
      'err_pus_bumps_or_boil_required': t.err_pus_bumps_or_boil_required,
      'err_newborn_seizures_required': t.err_newborn_seizures_required,
      'err_crying_constant_or_less_urine_required': t.err_crying_constant_or_less_urine_required,
      'err_crying_softly_required': t.err_crying_softly_required,
      'err_stopped_crying_required': t.err_stopped_crying_required,
      'err_referred_by_asha_required': t.err_referred_by_asha_required,
      'err_birth_registered_required': t.err_birth_registered_required,
      'err_birth_certificate_issued_required': t.err_birth_certificate_issued_required,
      'err_birth_dose_vaccination_required': t.err_birth_dose_vaccination_required,
      'err_mcp_child_required': t.err_mcp_child_required,
      'err_exclusive_breastfeeding_started_required': t.err_exclusive_breastfeeding_started_required,
      'err_first_breastfeed_timing_required': t.err_first_breastfeed_timing_required,
      'err_how_was_breastfed_required': t.err_how_was_breastfed_required,
      'err_first_feed_given_after_birth_required': t.err_first_feed_given_after_birth_required,
      'err_adequately_fed_seven_eight_required': t.err_adequately_fed_seven_eight_required,
      'err_baby_drinking_less_milk_required': t.err_baby_drinking_less_milk_required,
      'err_breastfeeding_stopped_required': t.err_breastfeeding_stopped_required,
      'err_bloated_or_frequent_vomit_required': t.err_bloated_or_frequent_vomit_required,
    };
    return m[code] ?? code;
  }
}
