import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/GeneralDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/MotherDetails.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/Tabs/ChildDetails.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/SuccessDialogbox/SuccessDialogbox.dart';

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
  late int _childCount;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    final bd = (widget as dynamic).beneficiaryData;
    final count = (bd?['child_tab_count'] as int?) ?? 1;
    _childCount = count <= 0 ? 1 : (count > 3 ? 3 : count);
    _tabController = TabController(length: 2 + _childCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First try using the form field approach
      final errorField = _findFirstErrorField();
      if (errorField != null && errorField.context != null) {
        Scrollable.ensureVisible(
          errorField.context!,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }


      _scrollToFirstErrorUsingKeys();
    });
  }

  // Scroll using GlobalKeys from MotherDetailsTab
  void _scrollToFirstErrorUsingKeys() {
    final currentTab = _tabController.index;

    // Only works for MotherDetailsTab (index 1)
    if (currentTab == 1) {
      // Get all field keys from MotherDetailsTab
      final fieldKeys = MotherDetailsTab.fieldKeys;

      // Try to find the first visible key with an error
      for (final entry in fieldKeys.entries) {
        final key = entry.value;
        final context = key.currentContext;

        if (context != null) {
          // Check if this field has an error by looking for FormField
          final widget = context.widget;
          if (widget is StatefulWidget) {
            final state = context as StatefulElement;
            final formFieldState = state.state;

            if (formFieldState is FormFieldState && formFieldState.hasError) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              return;
            }
          }
        }
      }
    }

    // For other tabs (GeneralDetails, ChildDetails), use the form field approach
  }

  FormFieldState<dynamic>? _findFirstErrorField() {
    FormFieldState<dynamic>? firstErrorField;
    final formContext = _formKey.currentContext;

    if (formContext == null) return null;

    void visitElement(Element element) {
      if (firstErrorField != null) return;

      if (element.widget is FormField) {
        final formField = element as StatefulElement;
        final field = formField.state as FormFieldState<dynamic>?;

        if (field?.hasError == true) {
          firstErrorField = field;
          return;
        }
      }

      element.visitChildren(visitElement);
    }

    formContext.visitChildElements(visitElement);
    return firstErrorField;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final beneficiaryData = (widget as dynamic).beneficiaryData;
    print(('from screen form',beneficiaryData?['child_tab_count'] as int?) ?? 1);

    return BlocProvider(
        create: (context) => HbncVisitBloc(),
        child: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              bottom: true,
              top: false,
              child: BlocListener<HbncVisitBloc, HbncVisitState>(
                listenWhen: (previous, current) =>
                (previous.validationTick != current.validationTick) ||
                    (previous.isSaving && !current.isSaving),
                listener: (context, state) {
                  final idx = _tabController.index;
                  if (state.lastValidatedIndex == idx && state.validationErrors.isNotEmpty) {
                    final t = AppLocalizations.of(context)!;
                    final first = state.validationErrors.first;
                    final localized = _mapErrorCodeToText(t, first);
                    showAppSnackBar(context, localized);

                    // Scroll to first error when validation fails
                    _scrollToFirstError();
                  }

                  if (state.saveSuccess && !state.isSaving) {
                    showAppSnackBar(context, 'Form saved successfully.');
                    if (mounted) {
                      final dynamic dayRaw = state.visitDetails['visitNumber'];
                      final int visitDay = dayRaw is int ? dayRaw : int.tryParse(dayRaw?.toString() ?? '') ?? 0;
                      if (visitDay == 42) {
                        if (!_navigationTriggered) {
                          _navigationTriggered = true;
                          CustomDialog.show(
                            context,
                            title:t?.formSavedSuccessfully ??  'Form has been saved successfully',
                            message:t?.postNatalMssg ?? 'The post natal care of beneficiary has been completed',
                            onOkPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Route_Names.HBNCScreen,
                                    (route) => false,
                              );
                            },
                          );
                        }
                      } else {
                        if (!_navigationTriggered) {
                          _navigationTriggered = true;
                          Future.delayed(const Duration(milliseconds: 2000), () {
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                Route_Names.HBNCScreen,
                                    (route) => false,
                              );
                            }
                          });
                        }
                      }
                    }
                  }

                  if (!state.isSaving && !state.saveSuccess && state.errorMessage != null) {
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

                  // Handle save after validation (only once per successful validation)
                  if (state.lastValidatedIndex == idx &&
                      state.lastValidationWasSave &&
                      state.validationErrors.isEmpty &&
                      !state.isSaving &&
                      !state.saveSuccess) {
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
                        final beneficiaryData = (widget as dynamic).beneficiaryData;
                        final beneficiaryId =
                            beneficiaryData?['unique_key']?.toString() ?? '';
                        Navigator.pushNamed(
                          context,
                          Route_Names.previousVisit,
                          arguments: {
                            'beneficiaryId': beneficiaryId,
                          },
                        );
                      },
                    ),
                    Container(
                      color: AppColors.primary,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
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
                          ...List.generate(_childCount, (i) => Tab(text: '${t.tabNewbornDetails} ${i + 1}')),
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
                            MotherDetailsTab(beneficiaryId: beneficiaryData?['unique_key']?.toString() ?? ''),
                            ...List.generate(_childCount, (i) => ChildDetailsTab(
                              beneficiaryId: beneficiaryData?['unique_key']?.toString() ?? '',
                              childTabCount: (beneficiaryData?['child_tab_count'] as int?) ?? 1,
                              childIndex: i + 1,
                            )),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    height: 34,
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
                                const SizedBox(width: 30),
                                Expanded(
                                  child: isLast
                                      ? BlocConsumer<HbncVisitBloc, HbncVisitState>(
                                    listener: (context, state) {},
                                    builder: (context, state) {
                                      return RoundButton(
                                        height: 34,
                                        title: t.saveButton,
                                        isLoading: state.isSaving,
                                        disabled: state.isSaving,
                                        onPress: () {
                                          if (!state.isSaving) {
                                            setState(() {
                                              _navigationTriggered = false;
                                            });

                                            final isValid = _formKey.currentState?.validate() ?? true;
                                            if (!isValid) {
                                              // Keep scroll-to-first-error behavior for inline validators
                                              _scrollToFirstError();
                                            }

                                            // Always delegate actual validation & messages to the BLoC,
                                            // so we get specific, per-question snackbars.
                                            context.read<HbncVisitBloc>().add(
                                              ValidateSection(
                                                _tabController.index,
                                                isSave: true,
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  )
                                      : RoundButton(
                                    height: 34,
                                    title: t.nextButton,
                                    onPress: () {
                                      final isValid = _formKey.currentState?.validate() ?? true;

                                      // Always run BLoC validation so we get
                                      // specific, per-question snackbar messages.
                                      if (!isValid) {
                                        // Keep scroll-to-first-error behavior
                                        _scrollToFirstError();
                                      }

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
                    ),
                  ],
                ),
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
      'err_mcp_mother_filled_required': t.err_mcp_mother_filled_required,
      'err_excessive_bleeding_required': t.err_excessive_bleeding_required,
      'err_unconscious_fits_required': t.err_unconscious_fits_required,
      'err_breastfeeding_problem_description_required': t.err_breastfeeding_problem_description_required,
      'err_breastfeeding_help_required': t.err_breastfeeding_help_required,
      'err_meals_per_day_required': t.err_meals_per_day_required,
      'err_paracetamol_given_required': t.err_paracetamol_given_required,
      'err_milk_counseling_advice_required': t.err_milk_counseling_advice_required,
      'err_refer_hospital_required': t.err_refer_hospital_required,
      'err_refer_to_required': t.err_refer_to_required,
      'err_date_of_death_required': t.err_date_of_death_required,
      'err_death_place_required': t.err_death_place_required,
      'err_reason_of_death_required': t.err_reason_of_death_required,
      'err_other_reason_of_death_required': t.err_other_reason_of_death_required,
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