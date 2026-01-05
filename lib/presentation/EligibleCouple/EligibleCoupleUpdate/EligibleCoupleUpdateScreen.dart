import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'bloc/eligible_coule_update_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import '../../../core/utils/Validations.dart';

class EligibleCoupleUpdateScreen extends StatelessWidget {
  const EligibleCoupleUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the navigation arguments
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return BlocProvider(
      create: (_) => EligibleCouleUpdateBloc()..add(InitializeForm(args ?? {})),
      child: const _EligibleCoupleUpdateView(),
    );
  }
}

class _CountBox extends StatelessWidget {
  final Widget child;
  const _CountBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Center(child: child),
    );
  }
}

class _EligibleCoupleUpdateView extends StatefulWidget {
  const _EligibleCoupleUpdateView();

  @override
  State<_EligibleCoupleUpdateView> createState() => _EligibleCoupleUpdateViewState();
}

class _EligibleCoupleUpdateViewState extends State<_EligibleCoupleUpdateView> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  TextEditingController _controllerFor(String key, String value) {
    final existing = _controllers[key];
    if (existing == null) {
      final c = TextEditingController(text: value);
      _controllers[key] = c;
      return c;
    }
    if (existing.text != value) {
      existing.value = existing.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    }
    return existing;
  }

  FocusNode _focusFor(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add this to ensure the widget rebuilds when the state changes
    return BlocBuilder<EligibleCouleUpdateBloc, EligibleCouleUpdateState>(
      builder: (context, state) {
        final t = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppHeader(
            screenTitle: t?.gridEligibleCoupleASHA ?? 'Eligible Couple',
            showBack: true,
          ),
          body: SafeArea(
            child: BlocConsumer<EligibleCouleUpdateBloc, EligibleCouleUpdateState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.error!)));
                }
                if (state.isSuccess) {
                  showAppSnackBar(
                    context,
                    t?.formUpdatedSuccessfully ?? 'Form Updated successfully',
                  );

                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pop(true); // Pass true to indicate success
                    }
                  });
                }
              },
              builder: (context, state) {
                final bloc = context.read<EligibleCouleUpdateBloc>();
                final live = int.tryParse(state.totalLiveChildren) ?? 0;
                final male = int.tryParse(state.totalMaleChildren) ?? 0;
                final female = int.tryParse(state.totalFemaleChildren) ?? 0;
                final showMaleFemaleError = live > 0 && (male + female) != live;
                String? youngestAgeInlineError;
                final rawYoungestAge = state.youngestChildAge;
                final unitYoungestAge = state.youngestChildAgeUnit;
                if (rawYoungestAge.trim().isNotEmpty) {
                  if (unitYoungestAge.isEmpty) {
                    youngestAgeInlineError = 'Please select age unit';
                  } else {
                    final msg = Validations.validateYoungestChildAge(AppLocalizations.of(context)!, rawYoungestAge, unitYoungestAge);
                    if (msg != null) {
                      if (msg.startsWith('Please enter age of Youngest Child')) {
                        youngestAgeInlineError = null;
                      } else {
                        youngestAgeInlineError = 'Please enter valid age for selected unit';
                      }
                    }
                  }
                }

                Widget _buildCountBoxField(
                  String fieldKey,
                  String value,
                  Function(String) onChanged,
                ) {
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: _CountBox(
                      child: TextField(
                        controller: _controllerFor(fieldKey, value),
                        focusNode: _focusFor(fieldKey),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t?.registrationThroughTitle ??
                                  'Registration through',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              key: const ValueKey('rchIdField'),
                              labelText: t?.rchIdLabel ?? 'RCH ID',
                              hintText: t?.rchIdLabel ?? 'RCH ID',
                              controller: TextEditingController(
                                text: state.rchId,
                              ),
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(RchIdChanged(v)),
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                            // Divider(color: AppColors.divider, thickness: 0.5, height: 0,),
                            // CustomDatePicker(
                            //   labelText: t?.registrationDateLabel ?? 'Registration Date',
                            //   initialDate: state.registrationDate,
                            //   onDateChanged: (d) => bloc.add(RegistrationDateChanged(d)),
                            // ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: const ValueKey('womanNameField'),
                              labelText:
                                  (t?.nameOfWomanLabel ?? 'Name of woman') +
                                  ' *',
                              hintText:
                                  (t?.nameOfWomanLabel ?? 'Name of woman') +
                                  ' *',
                              controller: TextEditingController(
                                text: state.womanName,
                              ),
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(WomanNameChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: const ValueKey('currentAgeField'),
                              labelText:
                                  (t?.currentAgeLabel ??
                                      'Current age (in years)') +
                                  ' *',
                              hintText:
                                  (t?.currentAgeLabel ??
                                      'Current age (in years)') +
                                  ' *',
                              controller: TextEditingController(
                                text: state.currentAge,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(CurrentAgeChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: const ValueKey('ageAtMarriageField'),
                              labelText:
                                  t?.ageAtMarriageInYearsLabel ??
                                  'Age at marriage (in years)',
                              hintText:
                                  t?.ageAtMarriageInYearsLabel ??
                                  'Age at marriage (in years)',
                              controller: TextEditingController(
                                text: state.ageAtMarriage,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(AgeAtMarriageChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: const ValueKey('addressField'),
                              labelText: t?.addressLabel ?? 'Address',
                              hintText: t?.addressLabel ?? 'Address',
                              initialValue: state.address,
                              maxLines: 2,
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(AddressChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            IgnorePointer(
                              child: ApiDropdown<String>(
                                key: const ValueKey('whoseMobileField'),
                                labelText:
                                    "${t?.whoseMobileNumberLabel} *" ??
                                    'Whose mobile no.',
                                items: const [
                                  'Self',
                                  'Wife',
                                  'Father',
                                  'Mother',
                                  'Son',
                                  'Daughter',
                                  'Father in Law',
                                  'Mother in Law',
                                  'Neighbour',
                                  'Relative',
                                  'Other',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Self':
                                      return t!.self;
                                    case 'Wife':
                                      return t!.wife;
                                    case 'Father':
                                      return t!.father;
                                    case 'Mother':
                                      return t!.mother;
                                    case 'Son':
                                      return t!.son;
                                    case 'Daughter':
                                      return t!.daughter;
                                    case 'Father in Law':
                                      return t!.fatherInLaw;
                                    case 'Mother in Law':
                                      return t!.motherInLaw;
                                    case 'Neighbour':
                                      return t!.neighbour;
                                    case 'Relative':
                                      return t!.relative;
                                    case 'Other':
                                      return t!.other;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.whoseMobile.isEmpty
                                    ? null
                                    : state.whoseMobile,
                                onChanged: null, // Readonly
                                hintText: t?.select ?? 'Select',
                              ),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: const ValueKey('mobileNoField'),
                              labelText:
                                  (t?.mobileLabelSimple ?? 'Mobile no.') + ' *',
                              hintText:
                                  (t?.mobileLabelSimple ?? 'Mobile no.') + ' *',
                              controller: TextEditingController(
                                text: state.mobileNo,
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(MobileNoChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            IgnorePointer(
                              child: ApiDropdown<String>(
                                key: const ValueKey('religionField'),
                                labelText: t?.religionLabel ?? 'Religion',
                                items: const [
                                  'Do not want to disclose',
                                  'Hindu',
                                  'Muslim',
                                  'Christian',
                                  'Sikh',
                                  'Buddhism',
                                  'Jainism',
                                  'Parsi',
                                  'Other',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Do not want to disclose':
                                      return t!.doNotWantToDisclose;
                                    case 'Hindu':
                                      return t!.religionHindu;
                                    case 'Muslim':
                                      return t!.religionMuslim;
                                    case 'Christian':
                                      return t!.religionChristian;
                                    case 'Sikh':
                                      return t!.religionSikh;
                                    case 'Buddhism':
                                      return t!.religionBuddhism;
                                    case 'Jainism':
                                      return t!.religionJainism;
                                    case 'Parsi':
                                      return t!.religionParsi;
                                    case 'Other':
                                      return t!.religionOther;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.religion.isEmpty ? null : state.religion,
                                onChanged: null, // Readonly
                                hintText: t?.select ?? 'Select',
                              ),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            if (state.religion == 'Other' &&
                                state.otherReligion.trim().isNotEmpty) ...[
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),
                              CustomTextField(
                                labelText: t!.enter_religion,
                                hintText: t!.enter_religion,
                                initialValue: state.otherReligion,
                                readOnly: true,
                              ),
                            ],

                           
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            // Category Field
                            CustomTextField(
                              labelText: t?.categoryLabel ?? 'Category',
                              hintText: t?.enterCategory ?? 'Enter category',
                              initialValue: state.category,
                              onChanged: (value) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(CategoryChanged(value)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            if (state.category == 'Other' &&
                                state.otherCategory.trim().isNotEmpty) ...[
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),
                              CustomTextField(
                                labelText: t?.enterCategory,
                                hintText: t?.enterCategory,
                                initialValue: state.otherCategory,
                                readOnly: true,
                              ),
                            ],

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            const SizedBox(height: 16),

                            Text(
                              t?.childrenDetailsTitle ?? 'Children Details',
                              style: TextStyle(fontWeight:FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Total Children Born
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t?.totalChildrenBornLabel ??
                                        'Total number of children born',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildCountBoxField(
                                  'totalChildrenBorn',
                                  state.totalChildrenBorn,
                                  (v) => context
                                      .read<EligibleCouleUpdateBloc>()
                                      .add(TotalChildrenBornChanged(v)),
                                ),
                              ],
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            // Total Live Children
                            BlocBuilder<
                              EligibleCouleUpdateBloc,
                              EligibleCouleUpdateState
                            >(
                              builder: (context, state) => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t?.totalLiveChildrenLabel ??
                                          'Total live children',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildCountBoxField(
                                    'totalLiveChildren',
                                    state.totalLiveChildren,
                                    (v) => context
                                        .read<EligibleCouleUpdateBloc>()
                                        .add(TotalLiveChildrenChanged(v)),
                                  ),
                                ],
                              ),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            // Total Male Children
                            BlocBuilder<
                              EligibleCouleUpdateBloc,
                              EligibleCouleUpdateState
                            >(
                              builder: (context, state) => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t?.totalMaleChildrenLabel ??
                                          'Total male children',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildCountBoxField(
                                    'totalMaleChildren',
                                    state.totalMaleChildren,
                                    (v) => context
                                        .read<EligibleCouleUpdateBloc>()
                                        .add(TotalMaleChildrenChanged(v)),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            // Total Female Children
                            BlocBuilder<
                              EligibleCouleUpdateBloc,
                              EligibleCouleUpdateState
                            >(
                              builder: (context, state) => Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t?.totalFemaleChildrenLabel ??
                                          'Total female children',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildCountBoxField(
                                    'totalFemaleChildren',
                                    state.totalFemaleChildren,
                                    (v) => context
                                        .read<EligibleCouleUpdateBloc>()
                                        .add(TotalFemaleChildrenChanged(v)),
                                  ),
                                ],
                              ),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            // Youngest Child Details

                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t?.youngestChildAgeLabel ??
                                        'Age of youngest child',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildCountBoxField(
                                  'youngestChildAge',
                                  state.youngestChildAge,
                                  (v) => context
                                      .read<EligibleCouleUpdateBloc>()
                                      .add(YoungestChildAgeChanged(v)),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 8,
                                ),


                                /* Expanded(
                                  child: ApiDropdown<String>(
                                    key: ValueKey('youngestChildAgeUnit'),
                                    labelText: '',
                                    items: const ['Years', 'Months', 'Days'],
                                    value: state.youngestChildAgeUnit.isEmpty
                                        ? null
                                        : state.youngestChildAgeUnit,
                                    getLabel: (s) => s,
                                    onChanged: (v) => context
                                        .read<EligibleCouleUpdateBloc>()
                                        .add(
                                          YoungestChildAgeUnitChanged(v ?? ''),
                                        ),
                                    hintText: t?.select ?? 'Select',
                                  ),
                                ),*/
                              ],
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            ApiDropdown<String>(
                              key: const ValueKey('youngestChildAgeUnit'),
                              labelText: t?.youngestChildAgeLabel,
                              items: const ['Years', 'Months', 'Days'],
                              value: state.youngestChildAgeUnit.isEmpty
                                  ? null
                                  : state.youngestChildAgeUnit,
                              getLabel: (s) {
                                switch (s) {
                                  case 'Years':
                                    return t!.years;
                                  case 'Months':
                                    return t!.months;
                                  case 'Days':
                                    return t!.days;
                                  default:
                                    return s;
                                }
                              },
                              onChanged: (v) => context.read<EligibleCouleUpdateBloc>().add(
                                YoungestChildAgeUnitChanged(v ?? ''),
                              ),
                              hintText: t?.select ?? 'Select',
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 8,
                            ),
                            // Youngest Child Gender '//////
                            ApiDropdown<String>(
                              key: const ValueKey('youngestChildGender'),
                              labelText:
                                  t?.youngestChildGenderLabel ??
                                  'Gender of youngest child',
                              items: const ['Male', 'Female', 'Transgender'],
                              value: state.youngestChildGender.isEmpty
                                  ? null
                                  : state.youngestChildGender,
                              getLabel: (s) {
                                switch (s) {
                                  case 'Male':
                                    return t?.genderMale ?? 'Male';
                                  case 'Female':
                                    return t?.genderFemale ?? 'Female';
                                  case 'Transgender':
                                    return t?.transgender ?? 'Transgender';
                                  default:
                                    return s;
                                    
                                }
                              },
                              onChanged: (v) => context
                                  .read<EligibleCouleUpdateBloc>()
                                  .add(YoungestChildGenderChanged(v ?? '')),
                              hintText: t?.select ?? 'Select',
                            ),
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
                            offset: const Offset(0, 0), // TOP shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 4.5.h,
                            child: RoundButton(
                              title: state.isSubmitting
                                  ? ''
                                  : (t?.updateButton ?? 'UPDATE'),
                              isLoading: state.isSubmitting,
                              onPress: () {
                                if (state.isSubmitting) return;

                                // Children count validations (same as AddNewFamilyHead)
                                final born = int.tryParse(state.totalChildrenBorn) ?? 0;
                                final live = int.tryParse(state.totalLiveChildren) ?? 0;
                                final male = int.tryParse(state.totalMaleChildren) ?? 0;
                                final female = int.tryParse(state.totalFemaleChildren) ?? 0;

                                // 1) total live children must not be greater than total born children
                                if (live > born) {
                                  showAppSnackBar(
                                    context,
                                    t?.totalLiveChildrenval ?? 'Total live children can\'t be more than total born children',
                                  );
                                  return;
                                }

                                // 2) total male children must not be greater than total live children
                                if (male > live) {
                                  showAppSnackBar(
                                    context,
                                    t?.totalMaleChildrenval ?? 'Total male children can\'t be more than total live children',
                                  );
                                  return;
                                }

                                // 3) total female children must not be greater than total live children
                                if (female > live) {
                                  showAppSnackBar(
                                    context,
                                    t?.totalFemaleChildrenval ?? 'Total female children can\'t be more than total live children',
                                  );
                                  return;
                                }

                                // 4) sum of male and female children must be equal to total live children
                                if (live > 0 && (male + female) != live) {
                                  showAppSnackBar(
                                    context,
                                    t?.malePlusFemaleError ?? 'Some of total male and female must equal total live children',
                                  );
                                  return;
                                }

                                // Youngest child gender vs counts validation (same logic as _validateYoungestGender)
                                final youngestGender = state.youngestChildGender;
                                if (youngestGender == 'Male' && male == 0) {
                                  showAppSnackBar(
                                    context,
                                    t?.invalidGenderMaleZero ?? 'Selected youngest child gender is Male but total male children is 0',
                                  );
                                  return;
                                }
                                if (youngestGender == 'Female' && female == 0) {
                                  showAppSnackBar(
                                    context,
                                    t?.invalidGenderFemaleZero ?? 'Selected youngest child gender is Female but total female children is 0',
                                  );
                                  return;
                                }

                              final unit = state.youngestChildAgeUnit;
                              final ageStr = state.youngestChildAge;
                              if (ageStr.trim().isNotEmpty && unit.isEmpty) {
                                showAppSnackBar(context, 'Please select age unit');
                                return;
                              }
                              final age = int.tryParse(ageStr);
                              String? message;
                              if (unit == 'Years') {
                                if (age == null || age < 1 || age > 90) {
                                  message =
                                      t?.yearRangeValidation ??
                                      'Year: only 1 to 90 allowed';
                                }
                              } else if (unit == 'Months') {
                                if (age == null || age < 1 || age > 11) {
                                  message =
                                      t?.monthRangeValidation ??
                                      'Month: only 1 to 11 allowed';
                                }
                              } else if (unit == 'Days') {
                                if (age == null || age < 1 || age > 30) {
                                  message =
                                      t?.daysRangeValidation ??
                                      'Days: only 1 to 30 allowed';
                                }
                              }
                              if (message != null) {
                                showAppSnackBar(context, message);
                                return;
                              }
                              if (!state.isSubmitting) {
                                context.read<EligibleCouleUpdateBloc>().add(
                                  const SubmitPressed(),
                                );
                              }
                            },
                              disabled: state.isSubmitting,
                            ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
