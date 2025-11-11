import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/hbyc_child_care_bloc.dart';

class HBYCChildCareFormScreen extends StatelessWidget {
  final String hhid;
  final String name;
  final String beneficiaryId;

  const HBYCChildCareFormScreen({
    super.key,
    required this.hhid,
    required this.name,
    required this.beneficiaryId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HbycChildCareBloc(),
      child: _HbycFormView(
        hhid: hhid,
        name: name,
        beneficiaryId: beneficiaryId,
      ),
    );
  }
}

class _HbycFormView extends StatefulWidget {
  final String hhid;
  final String name;
  final String beneficiaryId;

  const _HbycFormView({
    required this.hhid,
    required this.name,
    required this.beneficiaryId,
  });

  @override
  State<_HbycFormView> createState() => _HbycFormViewState();
}

class _HbycFormViewState extends State<_HbycFormView> {
  final _formKey = GlobalKey<FormState>();

 final _yesNoOptions = const [
    'Yes',
    'No',
  ];


  // Controllers for additional input fields
  final _additionalInfoController = TextEditingController();
  final _sicknessDetailsController = TextEditingController();
  final _referralDetailsController = TextEditingController();
  final _developmentDelaysDetailsController = TextEditingController();

  @override
  void dispose() {
    _additionalInfoController.dispose();
    _sicknessDetailsController.dispose();
    _referralDetailsController.dispose();
    _developmentDelaysDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppHeader(screenTitle: 'Home Based Care For Young Child', showBack: true,),
      body: BlocListener<HbycChildCareBloc, HbycChildCareState>(
        listener: (context, state) {
          if (state.status == HbycFormStatus.failure && state.error != null) {
            final key = state.error!;
            final localized = key == 'hbycBhramanRequired' ? l10n.hbycBhramanRequired : key;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localized)),
            );
          }
          if (state.status == HbycFormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.saveButton)),
            );
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    const SizedBox(height: 8),
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('is Beneficiary absent', style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.beneficiaryAbsent.isNotEmpty ? state.beneficiaryAbsent : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(BeneficiaryAbsentChanged(v ?? '')),
                              validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.requiredField : null,
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                    const SizedBox(height: 1),
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycBhramanLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.hbycBhraman.isNotEmpty ? state.hbycBhraman : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(HbycBhramanChanged(v ?? '')),
                              validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.requiredField : null,
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    // Is Child Sick Section with conditional input
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycIsChildSickLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.isChildSick.isNotEmpty ? state.isChildSick : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(IsChildSickChanged(v ?? '')),
                            ),
                            if (state.isChildSick == 'Yes')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CustomTextField(
                                  controller: _sicknessDetailsController,
                                  hintText: 'Please provide details of sickness',
                                  maxLines: 3,
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycBreastfeedingContinuingLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.breastfeedingContinuing.isNotEmpty ? state.breastfeedingContinuing : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(BreastfeedingContinuingChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycCompleteDietProvidedLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.completeDietProvided.isNotEmpty ? state.completeDietProvided : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(CompleteDietProvidedChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycWeighedByAwwLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.weighedByAww.isNotEmpty ? state.weighedByAww : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(WeighedByAwwChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycLengthHeightRecordedLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.lengthHeightRecorded.isNotEmpty ? state.lengthHeightRecorded : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(LengthHeightRecordedChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    // Weight Less Than 3SD Section with conditional input
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycWeightLessThan3sdLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.weightLessThan3sdReferred.isNotEmpty ? state.weightLessThan3sdReferred : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(WeightLessThan3sdReferredChanged(v ?? '')),
                            ),
                            if (state.weightLessThan3sdReferred == 'Yes')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CustomTextField(
                                  controller: _referralDetailsController,
                                  hintText: 'Please provide referral details',
                                  maxLines: 3,
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    // Development Delays Observed Section with conditional input
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycDevelopmentDelaysObservedLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.developmentDelaysObserved.isNotEmpty ? state.developmentDelaysObserved : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(DevelopmentDelaysObservedChanged(v ?? '')),
                            ),
                            if (state.developmentDelaysObserved == 'Yes')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: CustomTextField(
                                  controller: _developmentDelaysDetailsController,
                                  hintText: 'Please provide details of development delays',
                                  maxLines: 3,
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycFullyVaccinatedLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.fullyVaccinatedAsPerMcp.isNotEmpty ? state.fullyVaccinatedAsPerMcp : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(FullyVaccinatedAsPerMcpChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycMeaslesVaccineGivenLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.measlesVaccineGiven.isNotEmpty ? state.measlesVaccineGiven : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(MeaslesVaccineGivenChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycVitaminADosageGivenLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.vitaminADosageGiven.isNotEmpty ? state.vitaminADosageGiven : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(VitaminADosageGivenChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycOrsPacketAvailableLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.orsPacketAvailable.isNotEmpty ? state.orsPacketAvailable : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(OrsPacketAvailableChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycIronFolicSyrupAvailableLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.ironFolicSyrupAvailable.isNotEmpty ? state.ironFolicSyrupAvailable : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(IronFolicSyrupAvailableChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycCounselingExclusiveBf6mLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.counselingExclusiveBf6m.isNotEmpty ? state.counselingExclusiveBf6m : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(CounselingExclusiveBf6mChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycAdviceComplementaryFoodsLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.adviceComplementaryFoods.isNotEmpty ? state.adviceComplementaryFoods : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceComplementaryFoodsChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycAdviceHandWashingHygieneLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.adviceHandWashingHygiene.isNotEmpty ? state.adviceHandWashingHygiene : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceHandWashingHygieneChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycAdviceParentingSupportLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.adviceParentingSupport.isNotEmpty ? state.adviceParentingSupport : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceParentingSupportChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycCounselingFamilyPlanningLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.counselingFamilyPlanning.isNotEmpty ? state.counselingFamilyPlanning : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(CounselingFamilyPlanningChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.hbycAdvicePreparingAdministeringOrsLabel, style: TextStyle(fontSize: 14.sp),),
                            ApiDropdown<String>(
                              items: _yesNoOptions,
                              getLabel: (s) => s,
                              value: state.advicePreparingAdministeringOrs.isNotEmpty ? state.advicePreparingAdministeringOrs : null,
                              hintText: AppLocalizations.of(context)!.select,
                              onChanged: (v) => context.read<HbycChildCareBloc>().add(AdvicePreparingAdministeringOrsChanged(v ?? '')),
                            ),
                          ],
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdviceAdministeringIfaSyrupLabel, style: TextStyle(fontSize: 14.sp),),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceAdministeringIfaSyrupChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                    Text(AppLocalizations.of(context)!.hbycCompletionDateLabel, style: TextStyle(fontSize: 14.sp),),
                    CustomDatePicker(
                      labelText: '',
                      hintText: AppLocalizations.of(context)!.dateHint,
                      onDateChanged: (dt) {
                        if (dt == null) return;
                        final str = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
                        context.read<HbycChildCareBloc>().add(CompletionDateChanged(str));
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    const SizedBox(height: 80), // Space for the fixed buttons at the bottom

                  ],
                ),
              ),
            ),
          ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                    builder: (context, state) {
                      final busy = state.status == HbycFormStatus.submitting;
                      return Row(
                        children: [
                          Expanded(
                            child: RoundButton(
                              title: 'Previous',
                              onPress: () {
                                Navigator.of(context).pushNamed(
                                    Route_Names.PreviousVisitsScreenHBYC,
                                    arguments: {
                                      'beneficiaryId': widget.beneficiaryId
                                    });
                              },
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: RoundButton(
                              title: 'Save Form',
                              isLoading: busy,
                              disabled: busy,
                              onPress: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  final state = context.read<HbycChildCareBloc>().state;
                                  context.read<HbycChildCareBloc>().add(SubmitForm(
                                    beneficiaryRefKey: widget.beneficiaryId,
                                    householdRefKey: widget.hhid,
                                    sicknessDetails: state.isChildSick == 'Yes' ? _sicknessDetailsController.text : null,
                                    referralDetails: state.weightLessThan3sdReferred == 'Yes' ? _referralDetailsController.text : null,
                                    developmentDelaysDetails: state.developmentDelaysObserved == 'Yes' ? _developmentDelaysDetailsController.text : null,
                                  ));
                                }
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
    );
  }
}





