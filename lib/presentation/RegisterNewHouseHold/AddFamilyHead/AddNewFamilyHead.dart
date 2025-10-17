import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'bloc/add_family_head_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';

class AddNewFamilyHeadScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, String>? initial;
  const AddNewFamilyHeadScreen({super.key, this.isEdit = false, this.initial});

  @override
  State<AddNewFamilyHeadScreen> createState() => _AddNewFamilyHeadScreenState();
}

class _AddNewFamilyHeadScreenState extends State<AddNewFamilyHeadScreen> {
  final _formKey = GlobalKey<FormState>();

  int _ageFromDob(DateTime dob) {
    return DateTime.now().year - dob.year;
  }

  Widget _Section({required Widget child}) {
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => AddFamilyHeadBloc(),
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showConfirmationDialog(
            context: context,
            title: 'Attention !',
            message: 'Do you want to close this form?',
            yesText: 'Yes',
            noText: 'No',
          );
          return shouldExit ?? false;
        },
        child: Scaffold(
          appBar: AppHeader(
            screenTitle: l.familyHeadDetailsTitle,
            showBack: true,
            onBackTap: () async {
              final shouldExit = await showConfirmationDialog(
                context: context,
                title: 'Attention !',
                message: 'Do you want to close this form?',
                yesText: 'Yes, Exit',
                noText: 'No',
              );
              if (shouldExit ?? false) {
                Navigator.of(context).pop();
              }
            },
          ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
                    builder: (context, state) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        children: [
                          // Row 1
                          _Section(
                            child: CustomTextField(
                              labelText: '${l.houseNoLabel} *',
                              hintText: l.houseNoHint,
                              onChanged: (v) => context
                                  .read<AddFamilyHeadBloc>()
                                  .add(AfhUpdateHouseNo(v.trim())),
                              validator: (value) => Validations.validateHouseNo(l, value),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          _Section(
                            child: CustomTextField(
                              labelText: '${l.nameOfFamilyHeadLabel} *',
                              hintText: l.nameOfFamilyHeadHint,
                              onChanged: (v) => context
                                  .read<AddFamilyHeadBloc>()
                                  .add(AfhUpdateHeadName(v.trim())),
                              validator: (value) => Validations.validateFamilyHead(l, value),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          _Section(
                            child: CustomTextField(
                              labelText: l.fatherNameLabel,
                              hintText: l.fatherNameLabel,
                              onChanged: (v) => context
                                  .read<AddFamilyHeadBloc>()
                                  .add(AfhUpdateFatherName(v.trim())),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // DOB vs Age
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: state.useDob,
                                  onChanged: (_) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhToggleUseDob()),
                                ),
                                Text(l.dobShort),
                                const SizedBox(width: 16),
                                Radio<bool>(
                                  value: false,
                                  groupValue: state.useDob,
                                  onChanged: (_) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhToggleUseDob()),
                                ),
                                Text(l.ageApproximate),
                              ],
                            ),
                          ),
                          if (state.useDob)
                            _Section(
                              child: CustomDatePicker(
                                labelText: '${l.dobLabel} *',
                                hintText: l.dateHint,
                                onDateChanged: (d) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateDob(d)),
                                validator: (date) => Validations.validateDOB(l, date),

                              ),
                            )
                          else
                            _Section(
                              child: CustomTextField(
                                labelText: '${l.ageLabel} *',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateApproxAge(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: '${l.genderLabel} *',
                                items: const ['Male', 'Female', 'Other'],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Male':
                                      return l.genderMale;
                                    case 'Female':
                                      return l.genderFemale;
                                    case 'Other':
                                      return l.genderOther;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.gender,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateGender(v)),
                                validator: (value) => Validations.validateGender(l, value),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: l.occupationLabel,
                                items: const [
                                  'Employed',
                                  'Self-employed',
                                  'Student',
                                  'Unemployed',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Employed':
                                      return l.occupationEmployed;
                                    case 'Self-employed':
                                      return l.occupationSelfEmployed;
                                    case 'Student':
                                      return l.occupationStudent;
                                    case 'Unemployed':
                                      return l.occupationUnemployed;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.occupation,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateOccupation(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: l.educationLabel,
                                items: const [
                                  'Primary',
                                  'Secondary',
                                  'Graduate',
                                  'Postgraduate',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Primary':
                                      return l.educationPrimary;
                                    case 'Secondary':
                                      return l.educationSecondary;
                                    case 'Graduate':
                                      return l.educationGraduate;
                                    case 'Postgraduate':
                                      return l.educationPostgraduate;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.education,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateEducation(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: l.religionLabel,
                                items: const [
                                  'Hindu',
                                  'Muslim',
                                  'Christian',
                                  'Sikh',
                                  'Other',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Hindu':
                                      return l.religionHindu;
                                    case 'Muslim':
                                      return l.religionMuslim;
                                    case 'Christian':
                                      return l.religionChristian;
                                    case 'Sikh':
                                      return l.religionSikh;
                                    case 'Other':
                                      return l.religionOther;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.religion,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateReligion(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: l.categoryLabel,
                                items: const ['General', 'OBC', 'SC', 'ST'],
                                getLabel: (s) => s,
                                value: state.category,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateCategory(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            // Mobile
                            _Section(
                              child: ApiDropdown<String>(
                                labelText: '${l.whoseMobileLabel} *',
                                items: const [
                                  'Self',
                                  'Spouse',
                                  'Father',
                                  'Mother',
                                  'Other',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Self':
                                      return l.self;
                                    case 'Spouse':
                                      return l.spouse;
                                    case 'Father':
                                      return l.father;
                                    case 'Mother':
                                      return l.mother;
                                    case 'Other':
                                      return l.other;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.mobileOwner,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateMobileOwner(v)),
                                validator: (value) => Validations.validateWhoMobileNo(l, value),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: '${l.mobileLabel} *',
                                keyboardType: TextInputType.number,
                                maxLength: 10, // optional, shows counter
                                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMobileNo(v.trim())),
                                validator: (value) => Validations.validateMobileNo(l, value),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly, // allows only digits
                                ],
                              ),
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.villageNameLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateVillage(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.wardNoLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateWard(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.mohallaTolaNameLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateMohalla(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.accountNumberLabel,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateBankAcc(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.ifscLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateIfsc(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.voterIdLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateVoterId(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.rationCardIdLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateRationId(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: CustomTextField(
                                labelText: l.personalHealthIdLabel,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdatePhId(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: l.beneficiaryTypeLabel,
                                items: const ['APL', 'BPL', 'Antyodaya'],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'APL':
                                      return l.beneficiaryTypeAPL;
                                    case 'BPL':
                                      return l.beneficiaryTypeBPL;
                                    case 'Antyodaya':
                                      return l.beneficiaryTypeAntyodaya;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.beneficiaryType,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateBeneficiaryType(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _Section(
                              child: ApiDropdown<String>(
                                labelText: '${l.maritalStatusLabel} *',
                                items: const [
                                  'Married',
                                  'Unmarried',
                                  'Widowed',
                                  'Separated',
                                  'Divorced',
                                ],
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Married':
                                      return l.married;
                                    case 'Unmarried':
                                      return l.unmarried;
                                    case 'Widowed':
                                      return l.widowed;
                                    case 'Separated':
                                      return l.separated;
                                    case 'Divorced':
                                      return l.divorced;
                                    default:
                                      return s;
                                  }
                                },
                                value: state.maritalStatus,
                                onChanged: (v) => context
                                    .read<AddFamilyHeadBloc>()
                                    .add(AfhUpdateMaritalStatus(v)),
                                validator: (value) => Validations.validateMaritalStatus(l, value),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            if (state.maritalStatus == 'Married') ...[
                              _Section(
                                child: CustomTextField(
                                  labelText: l.ageAtMarriageLabel,
                                  hintText: l.ageAtMarriageHint,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhUpdateAgeAtMarriage(v.trim())),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              _Section(
                                child: CustomTextField(
                                  labelText: '${l.spouseNameLabel} *',
                                  hintText: l.spouseNameHint,
                                  onChanged: (v) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhUpdateSpouseName(v.trim())),
                                  validator: (value) => Validations.validateSpousName(l, value),

                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              _Section(
                                child: ApiDropdown<String>(
                                  labelText: l.haveChildrenQuestion,
                                  items: const ['Yes', 'No'],
                                  getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                  value: state.hasChildren,
                                  onChanged: (v) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhUpdateHasChildren(v)),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              _Section(
                                child: ApiDropdown<String>(
                                  labelText: '${l.isWomanPregnantQuestion} *',
                                  items: const ['Yes', 'No'],
                                  getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                  value: state.isPregnant,
                                  onChanged: (v) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(AfhUpdateIsPregnant(v)),
                                  validator: (value) => Validations.validateIsPregnant(l, value),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            ] else if (state.maritalStatus != null &&
                                ['Unmarried', 'Widowed', 'Separated', 'Divorced']
                                    .contains(state.maritalStatus)) ...[
                              _Section(
                                child: CustomTextField(
                                  labelText: l.haveChildrenQuestion,
                                  hintText: l.haveChildrenQuestion,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => context
                                      .read<AddFamilyHeadBloc>()
                                      .add(ChildrenChanged(v.trim())),
                                ),

                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            ],
                          ],

                        );
                      },
                    ),
                  ),
                ),

                BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
                  listenWhen: (p, c) => p.postApiStatus != c.postApiStatus,
                  listener: (context, state) {
                    if (state.postApiStatus == PostApiStatus.error &&
                        state.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.errorMessage!)),
                      );
                    }

                    if (state.postApiStatus == PostApiStatus.success) {
                      final Map<String, String> result = {
                        'Name': (state.headName ?? '').toString(),
                        'Age': ((state.useDob && state.dob != null)
                                ? _ageFromDob(state.dob!)
                                : (state.approxAge ?? ''))
                            .toString(),
                        'Gender': (state.gender ?? '').toString(),
                        'Relation': 'Self',
                        'Father': (state.fatherName ?? '').toString(),
                        'Spouse': (state.spouseName ?? '').toString(),
                        'Total Children': state.hasChildren == 'Yes' ? '1+' : '0',
                        'Marital Status': (state.maritalStatus ?? '').toString(),
                        'Beneficiary Type': (state.beneficiaryType ?? '').toString(),
                        'Is Pregnant': (state.isPregnant ?? '').toString(),
                      };
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (widget.isEdit) {
                          final members = <Map<String, String>>[
                            {
                              '#': '1',
                              'Type': 'Adult',
                              'Name': result['Name'] ?? '',
                              'Age': result['Age'] ?? '',
                              'Gender': result['Gender'] ?? '',
                              'Relation': result['Relation'] ?? 'Self',
                              'Father': result['Father'] ?? '',
                              'Spouse': result['Spouse'] ?? '',
                              'Total Children': result['Total Children'] ?? '',
                            }
                          ];
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RegisterNewHouseHoldScreen(
                                initialMembers: members,
                                headAddedInit: true,
                                hideAddMemberButton: true,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop<Map<String, String>>(result);
                        }
                      });
                    }
                  },
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
                        builder: (context, state) {
                          final isLoading =
                              state.postApiStatus == PostApiStatus.loading;

                          return Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 120,
                              height: 44,
                              child: RoundButton(
                                title: isLoading
                                    ? (widget.isEdit ? 'UPDATING...' : l.addingButton)
                                    : (widget.isEdit ? 'UPDATE' : l.addButton),
                                color: AppColors.primary,
                                borderRadius: 8,
                                height: 44,
                                isLoading: isLoading,
                                onPress: () {
                                  final formState = _formKey.currentState;
                                  if (formState == null) return;

                                  final isValid = formState.validate();
                                  if (!isValid) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please correct the highlighted errors before continuing.'),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return; // Stop here if form is invalid
                                  }

                                  context.read<AddFamilyHeadBloc>().add(AfhSubmit());
                                },
                              )

                            ),
                          );
                        },
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
