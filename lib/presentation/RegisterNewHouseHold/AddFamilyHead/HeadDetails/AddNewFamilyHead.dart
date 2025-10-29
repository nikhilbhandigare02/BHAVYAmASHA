import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/SpousDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/bloc/spous_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/ChildrenDetaills.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/bloc/children_bloc.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';

import 'bloc/add_family_head_bloc.dart';



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

  Widget _buildFamilyHeadForm(BuildContext context, AddFamilyHeadState state, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      children: [
        _Section(
          child: CustomTextField(
            labelText: '${l.houseNoLabel} *',
            hintText: l.houseNoHint,
            initialValue: state.houseNo,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateHouseNo(v.trim())),
            validator: (value) => Validations.validateHouseNo(l, value),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: '${l.nameOfFamilyHeadLabel} *',
            hintText: l.nameOfFamilyHeadHint,
            initialValue: state.headName,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateHeadName(v.trim())),
            validator: (value) => Validations.validateFamilyHead(l, value),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.fatherNameLabel,
            hintText: l.fatherNameLabel,
            initialValue: state.fatherName,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateFatherName(v.trim())),
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
                onChanged: (_) => context.read<AddFamilyHeadBloc>().add(AfhToggleUseDob()),
              ),
              Text(l.dobShort),
              const SizedBox(width: 16),
              Radio<bool>(
                value: false,
                groupValue: state.useDob,
                onChanged: (_) => context.read<AddFamilyHeadBloc>().add(AfhToggleUseDob()),
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
              onDateChanged: (d) => context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(d)),
              validator: (date) => Validations.validateDOB(l, date),
            ),
          )
        else
          _Section(
            child: CustomTextField(
              labelText: '${l.ageLabel} *',
              keyboardType: TextInputType.number,
              initialValue: state.approxAge,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateApproxAge(v.trim())),
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
            onChanged: (v) {
              final bloc = context.read<AddFamilyHeadBloc>();
              bloc.add(AfhUpdateGender(v));
              if (v != 'Female') {
                // Clear pregnancy-related fields if not applicable
                bloc.add( AfhUpdateIsPregnant(null));
                bloc.add( LMPChange(null));
                bloc.add( EDDChange(null));
              }
            },
            validator: (value) => Validations.validateGender(l, value),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: ApiDropdown<String>(
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
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateOccupation(v)),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: ApiDropdown<String>(
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
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateEducation(v)),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: ApiDropdown<String>(
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
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateReligion(v)),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: ApiDropdown<String>(
            labelText: l.categoryLabel,
            items: const ['General', 'OBC', 'SC', 'ST'],
            getLabel: (s) => s,
            value: state.category,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateCategory(v)),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        _Section(
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  labelText: l.abhaAddressLabel,
                  onChanged: (v) =>
                      context.read<AddFamilyHeadBloc>().add(AfhABHAChange(v.trim())),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 25,
                width: 120,
                child: RoundButton(
                  title: l.linkAbha,
                  width: 160,
                  borderRadius: 8,
                  fontSize: 12,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.Abhalinkscreen);
                  },
                ),
              ),
            ],
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.gender == 'Female') ...[
          _Section(
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: l.richIdLabel,
                    onChanged: (v) =>
                        context.read<AddFamilyHeadBloc>().add(AfhABHAChange(v.trim())),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 25,
                  width: 120,
                  child: RoundButton(
                    title: 'VERIFY',
                    width: 160,
                    borderRadius: 8,
                    fontSize: 12,
                    onPress: () {
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],

        _Section(
          child: _Section(
            child: ApiDropdown<String>(
              labelText: '${l.whoseMobileLabel} *',
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
                    return l.self;
                  case 'Wife':
                    return l.wife;
                  case 'Father':
                    return l.father;
                  case 'Mother':
                    return l.mother;
                  case 'Son':
                    return l.son;
                  case 'Daughter':
                    return l.daughter;
                  case 'Father in Law':
                    return l.fatherInLaw;
                  case 'Mother in Law':
                    return l.motherInLaw;
                  case 'Neighbour':
                    return l.neighbour;
                  case 'Relative':
                    return l.relative;
                  case 'Other':
                    return l.other;
                  default:
                    return s;
                }
              },
              value: state.mobileOwner,
              onChanged: (v) =>
                  context.read<AddFamilyHeadBloc>().add(AfhUpdateMobileOwner(v)),
              validator: (value) => Validations.validateWhoMobileNo(l, value),
            ),
          ),

        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: '${l.mobileLabel} *',
            keyboardType: TextInputType.number,
            maxLength: 10,
            initialValue: state.mobileNo,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMobileNo(v.trim())),
            validator: (value) => Validations.validateMobileNo(l, value),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.villageNameLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateVillage(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.wardNoLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateWard(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.mohallaTolaNameLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMohalla(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.accountNumberLabel,
            keyboardType: TextInputType.number,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateBankAcc(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.ifscLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateIfsc(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.voterIdLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateVoterId(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.rationCardIdLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateRationId(v.trim())),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        _Section(
          child: CustomTextField(
            labelText: l.personalHealthIdLabel,
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdatePhId(v.trim())),
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
            onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateBeneficiaryType(v)),
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
            onChanged: (v) {
              final bloc = context.read<AddFamilyHeadBloc>();
              bloc.add(AfhUpdateMaritalStatus(v));
              if (v != 'Married') {
                // Clear pregnancy-related state when section becomes inapplicable
                bloc.add(AfhUpdateIsPregnant(null));
                bloc.add(LMPChange(null));
                bloc.add(EDDChange(null));
              }
            },
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
              initialValue: state.ageAtMarriage,
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
              initialValue: state.spouseName,
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

          if (state.gender == 'Female') ...[
            _Section(
              child: ApiDropdown<String>(
                labelText: '${l.isWomanPregnantQuestion} *',
                items: const ['Yes', 'No'],
                getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                value: state.isPregnant,
                onChanged: (v) {
                  final bloc = context.read<AddFamilyHeadBloc>();
                  bloc.add(AfhUpdateIsPregnant(v));
                  if (v == 'No') {
                    bloc.add( LMPChange(null));
                    bloc.add( EDDChange(null));
                  }
                },
                validator: (value) {
                  if (state.gender == 'Female' && state.maritalStatus == 'Married') {
                    return Validations.validateIsPregnant(l, value);
                  }
                  return null;
                },
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            if (state.isPregnant == 'Yes') ...[
              _Section(
                child: CustomDatePicker(
                  labelText: '${l.lmpDateLabel} *',
                  hintText: l.dateHint,
                  initialDate: state.lmp,
                  onDateChanged: (d) => context.read<AddFamilyHeadBloc>().add(LMPChange(d)),
                  validator: (date) => Validations.validateLMP(l, date),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _Section(
                child: CustomDatePicker(
                  labelText: '${l.eddDateLabel} *',
                  hintText: l.dateHint,
                  initialDate: state.edd,
                  onDateChanged: (d) => context.read<AddFamilyHeadBloc>().add(EDDChange(d)),
                  validator: (date) => Validations.validateEDD(l, date),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

            ] else if (state.isPregnant == 'No') ...[
              _Section(
                child: CustomTextField(
                  labelText: '${l.fpAdoptingLabel} *',
                  hintText: l.select,
                  onChanged: (v) => context
                      .read<AddFamilyHeadBloc>()
                      .add(AfhUpdateSpouseName(v.trim())),
                  validator: (value) => Validations.validateAdoptingPlan(l, value),
                ),

              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

            ],
          ],
        ] else if (state.maritalStatus != null &&
            [ 'Widowed', 'Separated', 'Divorced']
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
  }



  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MultiBlocProvider(
      providers: [
        BlocProvider<AddFamilyHeadBloc>(create: (_) {
          final b = AddFamilyHeadBloc();
          final m = widget.initial;
          if (m != null && m.isNotEmpty) {
            DateTime? _parseDate(String? iso) => (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);
            b.add(
              AfhHydrate(
                AddFamilyHeadState(
                  houseNo: m['houseNo'],
                  headName: m['headName'],
                  fatherName: m['fatherName'],
                  AfhABHAChange: m['AfhABHAChange'],
                  children: m['children'],
                  useDob: m['useDob'] == 'true' || m['useDob'] == true,
                  dob: _parseDate(m['dob'] as String?),
                  edd: _parseDate(m['edd'] as String?),
                  lmp: _parseDate(m['lmp'] as String?),
                  approxAge: m['approxAge'],
                  gender: m['gender'],
                  occupation: m['occupation'],
                  education: m['education'],
                  religion: m['religion'],
                  category: m['category'],
                  mobileOwner: m['mobileOwner'],
                  mobileNo: m['mobileNo'],
                  village: m['village'],
                  ward: m['ward'],
                  mohalla: m['mohalla'],
                  bankAcc: m['bankAcc'],
                  ifsc: m['ifsc'],
                  voterId: m['voterId'],
                  rationId: m['rationId'],
                  phId: m['phId'],
                  beneficiaryType: m['beneficiaryType'],
                  maritalStatus: m['maritalStatus'],
                  ageAtMarriage: m['ageAtMarriage'],
                  spouseName: m['spouseName'],
                  AfhRichIdChange: m['AfhRichIdChange'],
                  hasChildren: m['hasChildren'],
                  isPregnant: m['isPregnant'],
                ),
              ),
            );
          }
          return b;
        }),
        BlocProvider<SpousBloc>(create: (_) => SpousBloc()),
        BlocProvider<ChildrenBloc>(create: (_) => ChildrenBloc()),
      ],
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showConfirmationDialog(
            context: context,
            title: l.confirmAttentionTitle,
            message: l.confirmCloseFormMsg,
            yesText: l.confirmYes,
            noText: l.confirmNo,
          );
          return shouldExit ?? false;
        },
        child: BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
          listenWhen: (p, c) => p.postApiStatus != c.postApiStatus,
          listener: (context, state) {
            if (state.postApiStatus == PostApiStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
            if (state.postApiStatus == PostApiStatus.success) {
              final Map<String, dynamic> result = state.toJson();
              // Attach spouse and children details JSON if available
              try {
                final sp = context.read<SpousBloc>().state;
                result['spousedetails'] = sp.toJson();
              } catch (_) {}
              try {
                final ch = context.read<ChildrenBloc>().state;
                result['childrendetails'] = ch.toJson();
              } catch (_) {}
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (widget.isEdit) {
                  final members = <Map<String, String>>[
                    {
                      '#': '1',
                      'Type': 'Adult',
                      'Name': (state.headName ?? '').toString(),
                      'Age': ((state.useDob && state.dob != null) ? _ageFromDob(state.dob!) : (state.approxAge ?? '')).toString(),
                      'Gender': (state.gender ?? '').toString(),
                      'Relation': 'Self',
                      'Father': (state.fatherName ?? '').toString(),
                      'Spouse': (state.spouseName ?? '').toString(),
                      'Total Children': (state.children != null && state.children!.isNotEmpty)
                          ? state.children!
                          : (state.hasChildren == 'Yes' ? '1+' : '0'),
                    }
                  ];
                  // Add spouse row when available
                  if ((state.maritalStatus == 'Married') && (state.spouseName != null) && state.spouseName!.isNotEmpty) {
                    final spouseGender = (state.gender == 'Male')
                        ? 'Female'
                        : (state.gender == 'Female')
                            ? 'Male'
                            : '';
                    members.add({
                      '#': '2',
                      'Type': 'Adult',
                      'Name': state.spouseName!,
                      'Age': '',
                      'Gender': spouseGender,
                      'Relation': 'Wife',
                      'Father': '',
                      'Spouse': (state.headName ?? '').toString(),
                      'Total Children': (state.children != null && state.children!.isNotEmpty)
                          ? state.children!
                          : (state.hasChildren == 'Yes' ? '1+' : '0'),
                    });
                  }
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
                  Navigator.of(context).pop<Map<String, dynamic>>(result);
                }
              });
            }
          },
          child: Scaffold(
            appBar: AppHeader(
              screenTitle: l.familyHeadDetailsTitle,
              showBack: true,
              onBackTap: () async {
                final shouldExit = await showConfirmationDialog(
                  context: context,
                  title: l.confirmAttentionTitle,
                  message: l.confirmCloseFormMsg,
                  yesText: l.confirmYesExit,
                  noText: l.confirmNo,
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
                    child: BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
                      builder: (context, state) {
                        final tabs = [const Tab(text: 'FAMILY HEAD DETAILS')];
                        final views = <Widget>[
                          Form(key: _formKey, child: _buildFamilyHeadForm(context, state, l)),
                        ];

                        final showSpouse = state.maritalStatus == 'Married';
                        final showChildren = showSpouse && state.hasChildren == 'Yes';

                        if (showSpouse) {
                          final spBloc = context.read<SpousBloc>();
                          if (spBloc.state.relation == null) {
                            final g = (state.gender == 'Male')
                                ? 'Female'
                                : (state.gender == 'Female')
                                    ? 'Male'
                                    : null;
                            spBloc.add(SpHydrate(SpousState(
                              relation: 'Spouse',
                              memberName: state.spouseName,
                              ageAtMarriage: state.ageAtMarriage,
                              spouseName: state.headName,
                              gender: g,
                              religion: state.religion,
                              category: state.category,
                              abhaAddress: state.AfhABHAChange,
                              bankAcc: state.bankAcc,
                              ifsc: state.ifsc,
                              voterId: state.voterId,
                              rationId: state.rationId,
                              phId: state.phId,
                              beneficiaryType: state.beneficiaryType,
                              RichIDChanged: state.AfhRichIdChange,
                            )));
                          } else {
                            final current = spBloc.state;
                            final headName = state.headName?.trim();
                            final spouseName = state.spouseName?.trim();
                            if ((current.memberName == null || current.memberName!.isEmpty) && (spouseName != null && spouseName.isNotEmpty)) {
                              spBloc.add(SpUpdateMemberName(spouseName));
                            }
                            if ((current.spouseName == null || current.spouseName!.isEmpty) && (headName != null && headName.isNotEmpty)) {
                              spBloc.add(SpUpdateSpouseName(headName));
                            }
                          }
                          tabs.add(const Tab(text: 'SPOUSE DETAILS'));
                          views.add(
                            BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
                              listenWhen: (prev, curr) => prev.headName != curr.headName || prev.spouseName != curr.spouseName,
                              listener: (ctx, st) {
                                final spBloc = ctx.read<SpousBloc>();
                                final memberName = st.spouseName?.trim();
                                final spouseName = st.headName?.trim();
                                if (memberName != null && memberName.isNotEmpty) {
                                  spBloc.add(SpUpdateMemberName(memberName));
                                }
                                if (spouseName != null && spouseName.isNotEmpty) {
                                  spBloc.add(SpUpdateSpouseName(spouseName));
                                }
                              },
                              child: Spousdetails(
                                key: ValueKey(state.gender ?? 'none'),
                                headMobileOwner: state.mobileOwner,
                                headMobileNo: state.mobileNo,
                              ),
                            ),
                          );
                        }
                        if (showChildren) {
                          tabs.add(const Tab(text: 'CHILDREN DETAILS'));
                          views.add(const Childrendetaills());
                        }

                        return DefaultTabController(
                          key: ValueKey<int>(tabs.length),
                          length: tabs.length,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TabBar(
                                  isScrollable: true,
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: Colors.black87,
                                  indicatorColor: AppColors.primary,
                                  tabs: tabs,
                                ),
                              ),
                              Expanded(
                                child: TabBarView(children: views),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                child: Builder(
                                  builder: (ctx) {
                                    final controller = DefaultTabController.of(ctx)!;
                                    return AnimatedBuilder(
                                      animation: controller.animation!,
                                      builder: (context, _) {
                                        final showNav = tabs.length > 1; // show when spouse or children tabs present
                                        return BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
                                          builder: (context, state) {
                                            final isLoading = state.postApiStatus == PostApiStatus.loading;
                                            if (!showNav) {
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
                                                        return;
                                                      }
                                                      context.read<AddFamilyHeadBloc>().add(AfhSubmit());
                                                    },
                                                  ),
                                                ),
                                              );
                                            }

                                            final i = controller.index;
                                            final last = tabs.length - 1;
                                            return Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if (i > 0)
                                                  SizedBox(
                                                    height: 44,
                                                    child:SizedBox(
                                                      height: 44,
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize: const Size(120, 44),
                                                          backgroundColor: AppColors.primary, // 👈 filled background
                                                          foregroundColor: Colors.white, // 👈 white text/icon
                                                          side: BorderSide(color: AppColors.primary, width: 1.5), // 👈 matching border
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8), // rounded edges
                                                          ),
                                                          elevation: 3, // subtle elevation for depth
                                                          shadowColor: AppColors.primary.withOpacity(0.4),
                                                        ),
                                                        onPressed: () => controller.animateTo(i - 1),
                                                        child: const Text(
                                                          'PREVIOUS',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    )

                                                  )
                                                else
                                                  const SizedBox.shrink(),
                                                SizedBox(
                                                  height: 44,
                                                  child:SizedBox(
                                                    height: 44,
                                                    child: RoundButton(
                                                      title: i < last
                                                          ? 'NEXT'
                                                          : (isLoading
                                                          ? (widget.isEdit ? 'UPDATING...' : l.addingButton)
                                                          : (widget.isEdit ? 'UPDATE' : l.addButton)),
                                                      onPress: () {
                                                        if (i < last) {
                                                          controller.animateTo(i + 1);
                                                        } else {
                                                          // last tab → submit
                                                          context.read<AddFamilyHeadBloc>().add(AfhSubmit());
                                                        }
                                                      },
                                                      color: AppColors.primary,
                                                      borderRadius: 8,
                                                      height: 44,
                                                      width: 120,
                                                      isLoading: isLoading,
                                                    ),
                                                  )

                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
