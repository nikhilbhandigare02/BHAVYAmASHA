import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/utils/Validations.dart' show Validations;
import '../../../core/utils/enums.dart';
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'bloc/addnewfamilymember_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class AddNewFamilyMemberScreen extends StatefulWidget {
  final bool isEdit;
  const AddNewFamilyMemberScreen({super.key, this.isEdit = false});

  @override
  State<AddNewFamilyMemberScreen> createState() => _AddNewFamilyMemberScreenState();
}

class _AddNewFamilyMemberScreenState extends State<AddNewFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _argsHandled = false;

  int _ageFromDob(DateTime dob) => DateTime.now().year - dob.year;

  Widget _section(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 4), child: child);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (!_argsHandled) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final dynamic flagA = args['isBeneficiary'];
        final dynamic flagB = args['isEdit'];
        final dynamic flagC = args['edit'];
        _isEdit = (flagA == true) || (flagB == true) || (flagC == true);
      } else if (args is bool) {
        _isEdit = args == true;
      }
      _argsHandled = true;
    }
    _isEdit = _isEdit || widget.isEdit;
    return BlocProvider(
      create: (_) => AddnewfamilymemberBloc(),
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
            screenTitle: l.newMemberDetailsTitle,
            showBack: true,
            onBackTap: () async {
              final shouldExit = await showConfirmationDialog(
                context: context,
                title: 'Attention !',
                message: 'Do you want to close this form?',
                yesText: 'Yes',
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
                  child: BlocBuilder<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                    builder: (context, state) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        children: [
                          // Member type
                          _section(
                            ApiDropdown<String>(
                              labelText: l.memberTypeLabel,
                              items: const ['Adult', 'Child', 'Infant'],
                              getLabel: (s) {
                                switch (s) {
                                  case 'Adult':
                                    return l.memberTypeAdult;
                                  case 'Child':
                                    return l.memberTypeChild;
                                  case 'Infant':
                                    return l.memberTypeInfant;
                                  default:
                                    return s;
                                }
                              },
                              value: state.memberType,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMemberType(v ?? 'Adult')),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Relation with head
                          _section(
                            ApiDropdown<String>(
                              labelText: '${l.relationWithHeadLabel} ',
                              items: const ['Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'],
                              getLabel: (s) {
                                switch (s) {
                                  case 'Spouse':
                                    return l.relationSpouse;
                                  case 'Son':
                                    return l.relationSon;
                                  case 'Daughter':
                                    return l.relationDaughter;
                                  case 'Father':
                                    return l.relationFather;
                                  case 'Mother':
                                    return l.relationMother;
                                  case 'Brother':
                                    return l.relationBrother;
                                  case 'Sister':
                                    return l.relationSister;
                                  case 'Other':
                                    return l.relationOther;
                                  default:
                                    return s;
                                }
                              },
                              value: state.relation,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateRelation(v ?? '')),
                              validator: (value) => Validations.validateFamilyHead(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Name
                          _section(
                            CustomTextField(
                              labelText: '${l.nameOfMemberLabel} *',
                              hintText: l.nameOfMemberHint,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateName(v.trim())),
                              validator: (value) => Validations.validateNameofMember(l, value),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                          _section(
                            CustomTextField(
                              labelText: '${l.fatherGuardianNameLabel} *',
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(v.trim())),
                              validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            CustomTextField(
                              labelText: l.motherNameLabel,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(v.trim())),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: state.useDob,
                                  onChanged: (_) => context.read<AddnewfamilymemberBloc>().add(AnmToggleUseDob()),
                                ),
                                Text(l.dobShort),
                                const SizedBox(width: 16),
                                Radio<bool>(
                                  value: false,
                                  groupValue: state.useDob,
                                  onChanged: (_) => context.read<AddnewfamilymemberBloc>().add(AnmToggleUseDob()),
                                ),
                                Text(l.ageApproximate),
                              ],
                            ),
                          ),
                          if (state.useDob)
                            _section(
                              CustomDatePicker(
                                labelText: '${l.dobLabel} *',
                                hintText: l.dateHint,
                                onDateChanged: (d) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateDob(d!)),
                                validator: (date) => Validations.validateDOB(l, date),

                              ),
                            )
                          else
                            _section(
                              CustomTextField(
                                labelText: '${l.ageLabel} *',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateApproxAge(v.trim())),
                                validator: (v) => (state.useDob || (v != null && v.trim().isNotEmpty)) ? null : l.requiredField,
                              ),
                            ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                          _section(
                            ApiDropdown<String>(
                              labelText: l.birthOrderLabel,
                              items: const ['1', '2', '3', '4', '5+'],
                              getLabel: (s) {
                                switch (s) {
                                  case '1':
                                    return l.birthOrder1;
                                  case '2':
                                    return l.birthOrder2;
                                  case '3':
                                    return l.birthOrder3;
                                  case '4':
                                    return l.birthOrder4;
                                  case '5+':
                                    return l.birthOrder5Plus;
                                  default:
                                    return s;
                                }
                              },
                              value: state.birthOrder,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBirthOrder(v ?? '')),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Gender
                          _section(
                            ApiDropdown<String>(
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateGender(v!)),
                              validator: (value) => Validations.validateGender(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Bank account
                          _section(
                            CustomTextField(
                              labelText: l.accountNumberLabel,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBankAcc(v.trim())),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            CustomTextField(
                              labelText: l.ifscLabel,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateIfsc(v.trim())),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Occupation, Education, Religion, Category
                          _section(
                            ApiDropdown<String>(
                              labelText: l.occupationLabel,
                              items: const ['Employed', 'Self-employed', 'Student', 'Unemployed'],
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateOccupation(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            ApiDropdown<String>(
                              labelText: l.educationLabel,
                              items: const ['Primary', 'Secondary', 'Graduate', 'Postgraduate'],
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateEducation(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            ApiDropdown<String>(
                              labelText: l.religionLabel,
                              items: const ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Other'],
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateReligion(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            ApiDropdown<String>(
                              labelText: l.categoryLabel,
                              items: const ['General', 'OBC', 'SC', 'ST'],
                              getLabel: (s) => s,
                              value: state.category,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateCategory(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // ABHA address
                          _section(
                            CustomTextField(
                              labelText: l.abhaAddressLabel,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateAbhaAddress(v.trim())),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Mobile
                          _section(
                            ApiDropdown<String>(
                              labelText: '${l.whoseMobileLabel} *',
                              items: const ['Self', 'Spouse', 'Father', 'Mother', 'Other'],
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileOwner(v!)),
                              validator: (value) => Validations.validateWhoMobileNo(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            CustomTextField(
                              labelText: '${l.mobileLabel} *',
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileNo(v.trim())),
                              validator: (value) => Validations.validateMobileNo(l, value),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // IDs
                          _section(CustomTextField(labelText: l.voterIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateVoterId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(CustomTextField(labelText: l.rationCardIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateRationId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(CustomTextField(labelText: l.personalHealthIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdatePhId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          // Beneficiary Type & Marital Status
                          _section(
                            ApiDropdown<String>(
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBeneficiaryType(v!)),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            ApiDropdown<String>(
                              labelText: '${l.maritalStatusLabel} *',
                              items: const ['Married', 'Unmarried', 'Widowed', 'Separated', 'Divorced'],
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMaritalStatus(v!)),
                              validator: (value) => Validations.validateMaritalStatus(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          if (state.maritalStatus == 'Married') ...[
                            _section(
                              CustomTextField(
                                labelText: l.ageAtMarriageLabel,
                                hintText: l.ageAtMarriageHint,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateAgeAtMarriage(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _section(
                              CustomTextField(
                                labelText: '${l.spouseNameLabel} *',
                                hintText: l.spouseNameHint,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateSpouseName(v.trim())),
                                validator: (value) => Validations.validateSpousName(l, value),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _section(
                              ApiDropdown<String>(
                                labelText: l.haveChildrenQuestion,
                                items: const ['Yes', 'No'],
                                getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                value: state.hasChildren,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateHasChildren(v!)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            _section(
                              ApiDropdown<String>(
                                labelText: '${l.isWomanPregnantQuestion} *',
                                items: const ['Yes', 'No'],
                                getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                value: state.isPregnant,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateIsPregnant(v!)),
                                validator: (value) => Validations.validateIsPregnant(l, value),

                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ]
                          else if (state.maritalStatus != null &&
                              ['Unmarried', 'Widowed', 'Separated', 'Divorced']
                                  .contains(state.maritalStatus)) ...[
                            _section(
                              CustomTextField(
                                labelText: l.haveChildrenQuestion,
                                hintText: l.haveChildrenQuestion,
                                keyboardType: TextInputType.text,
                                onChanged: (v) {
                                  if (v != null) {
                                    context.read<AddnewfamilymemberBloc>().add(ChildrenChanged(v.trim()));
                                  }
                                },

                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              BlocListener<AddnewfamilymemberBloc, AddnewfamilymemberState>(
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
                      'Type': (state.memberType ?? '').toString(),
                      'Name': (state.name ?? '').toString(),
                      'Age': ((state.useDob && state.dob != null)
                          ? _ageFromDob(state.dob!)
                          : (state.approxAge ?? ''))
                          .toString(),
                      'Gender': (state.gender ?? '').toString(),
                      'Relation': (state.relation ?? '').toString(),
                      'Father': (state.fatherName ?? '').toString(),
                      'Spouse': (state.spouseName ?? '').toString(),
                      'Total Children': state.hasChildren == 'Yes' ? '1+' : '0',
                      'Marital Status': (state.maritalStatus ?? '').toString(),
                      'Beneficiary Type': (state.beneficiaryType ?? '').toString(),
                      'Is Pregnant': (state.isPregnant ?? '').toString(),
                    };
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pop<Map<String, String>>(result);
                      }
                    });
                  }
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: BlocBuilder<AddnewfamilymemberBloc, AddnewfamilymemberState>(
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
                                    ? (_isEdit ? 'UPDATING...' : l.addingButton)
                                    : (_isEdit ? 'UPDATE' : l.addButton),
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
                                    return;
                                  }

                                  if (_isEdit) {
                                    context.read<AddnewfamilymemberBloc>().add(const AnmUpdateSubmit());
                                  } else {
                                    context.read<AddnewfamilymemberBloc>().add(const AnmSubmit());
                                  }
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
        ),)
      ),
    );
  }
}

