import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';

import '../../../core/config/themes/CustomColors.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/hbyc_child_care_bloc.dart';

class HBYCChildCareFormScreen extends StatelessWidget {
  const HBYCChildCareFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HbycChildCareBloc(),
      child: const _HbycFormView(),
    );
  }
}

class _HbycFormView extends StatefulWidget {
  const _HbycFormView();

  @override
  State<_HbycFormView> createState() => _HbycFormViewState();
}

class _HbycFormViewState extends State<_HbycFormView> {
  final _formKey = GlobalKey<FormState>();

  final _mobileOwnerOptions = const [
    'परिवार के मुखिया का',
    'माता',
    'अन्य',
  ];
  final _yesNoOptions = const [
    'हाँ',
    'नहीं',
  ];
  final _religionOptions = const [
    'हिन्दू',
    'मुस्लिम',
    'ईसाई',
    'सिख',
    'अन्य',
  ];
  final _casteOptions = const [
    'सामान्य',
    'ओबीसी',
    'एससी',
    'एसटी',
    'अन्य',
  ];
  final _genderOptions = const [
    'पुरुष',
    'महिला',
    'अन्य',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppHeader(screenTitle: l10n.registrationDue, showBack: true,),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(child: Text(l10n.hbycTitleDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),)),
                    Divider(color: AppColors.primary, thickness: 1, height: 0),

                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.hbycBhramanLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(HbycBhramanChanged(v ?? '')),
                      validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.requiredField : null,
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycIsChildSickLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(IsChildSickChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycBreastfeedingContinuingLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(BreastfeedingContinuingChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycCompleteDietProvidedLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(CompleteDietProvidedChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycWeighedByAwwLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(WeighedByAwwChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycLengthHeightRecordedLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(LengthHeightRecordedChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycWeightLessThan3sdLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(WeightLessThan3sdReferredChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycDevelopmentDelaysObservedLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(DevelopmentDelaysObservedChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycFullyVaccinatedLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(FullyVaccinatedAsPerMcpChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycMeaslesVaccineGivenLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(MeaslesVaccineGivenChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycVitaminADosageGivenLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(VitaminADosageGivenChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycOrsPacketAvailableLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(OrsPacketAvailableChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycIronFolicSyrupAvailableLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(IronFolicSyrupAvailableChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycCounselingExclusiveBf6mLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(CounselingExclusiveBf6mChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdviceComplementaryFoodsLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceComplementaryFoodsChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdviceHandWashingHygieneLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceHandWashingHygieneChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdviceParentingSupportLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceParentingSupportChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycCounselingFamilyPlanningLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(CounselingFamilyPlanningChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdvicePreparingAdministeringOrsLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdvicePreparingAdministeringOrsChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    Text(AppLocalizations.of(context)!.hbycAdviceAdministeringIfaSyrupLabel),
                    ApiDropdown<String>(
                      items: _yesNoOptions,
                      getLabel: (s) => s,
                      hintText: AppLocalizations.of(context)!.select,
                      onChanged: (v) => context.read<HbycChildCareBloc>().add(AdviceAdministeringIfaSyrupChanged(v ?? '')),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                    Text(AppLocalizations.of(context)!.hbycCompletionDateLabel),
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

                    const SizedBox(height: 16),
                    BlocBuilder<HbycChildCareBloc, HbycChildCareState>(
                      builder: (context, state) {
                        final busy = state.status == HbycFormStatus.submitting;
                        return ElevatedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    context.read<HbycChildCareBloc>().add(const SubmitForm());
                                  }
                                },
                          child: busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('संरक्षित करें'),
                        );
                      },
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





