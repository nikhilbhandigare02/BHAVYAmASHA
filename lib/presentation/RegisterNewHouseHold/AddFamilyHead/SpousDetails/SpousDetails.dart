import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import 'bloc/spous_bloc.dart';

class Spousdetails extends StatefulWidget {
  final SpousState? initial;
  final String? headMobileOwner;
  final String? headMobileNo;
  const Spousdetails({super.key, this.initial, this.headMobileOwner, this.headMobileNo});

  @override
  State<Spousdetails> createState() => _SpousdetailsState();
}

class _SpousdetailsState extends State<Spousdetails> {
  final _formKey = GlobalKey<FormState>();

  Widget _section(Widget child) => child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (_) => SpousBloc(initial: widget.initial),
      child: Form(
        key: _formKey,
        child: BlocBuilder<SpousBloc, SpousState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              children: [
                _section(
                  ApiDropdown<String>(
                    labelText: 'Relation with the family head',
                    items: const ['Spouse'],
                    getLabel: (s) => s,
                    value: state.relation,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateRelation(v)),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Name of member *',
                    hintText: 'Name of member',
                    initialValue: state.memberName,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMemberName(v.trim())),
                    validator: (value) => Validations.validateNameofMember(l, value),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Age at the time of marriage',
                    hintText: 'Age at the time of marriage',
                    keyboardType: TextInputType.number,
                    initialValue: state.ageAtMarriage,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateAgeAtMarriage(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Spouse Name *',
                    hintText: 'Spouse Name',
                    initialValue: state.spouseName,
                    validator: (value) => Validations.validateSpousName(l, value),
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateSpouseName(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Father name',
                    initialValue: state.fatherName,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateFatherName(v.trim())),
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
                        onChanged: (_) => context.read<SpousBloc>().add(SpToggleUseDob()),
                      ),
                      const Text('DOB'),
                      const SizedBox(width: 16),
                      Radio<bool>(
                        value: false,
                        groupValue: state.useDob,
                        onChanged: (_) => context.read<SpousBloc>().add(SpToggleUseDob()),
                      ),
                      const Text('Age/Approximate Age'),
                    ],
                  ),
                ),
                if (state.useDob)
                  _section(
                    CustomDatePicker(
                      labelText: '${l.dobLabel} *',
                      hintText: l.dateHint,
                      initialDate: state.dob,
                      onDateChanged: (d) => context.read<SpousBloc>().add(SpUpdateDob(d)),
                      validator: (date) => Validations.validateDOB(l, date),
                    ),
                  )
                else
                  _section(
                    CustomTextField(
                      labelText: '${l.ageLabel} *',
                      keyboardType: TextInputType.number,
                      initialValue: state.approxAge,
                      onChanged: (v) => context.read<SpousBloc>().add(SpUpdateApproxAge(v.trim())),
                    ),
                  ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

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
                    onChanged: null,
                    validator: (value) => Validations.validateGender(l, value),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),



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
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateOccupation(v)),
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
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateEducation(v)),
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
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateReligion(v)),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  ApiDropdown<String>(
                    labelText: l.categoryLabel,
                    items: const ['General', 'OBC', 'SC', 'ST'],
                    getLabel: (s) => s,
                    value: state.category,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateCategory(v)),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: 'ABHA address',
                          initialValue: state.abhaAddress,
                          onChanged: (v) =>
                              context.read<SpousBloc>().add(SpUpdateAbhaAddress(v.trim())),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 25,
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
                )
,
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.gender == 'Female') ...[
                  _section(
                   Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: l.richIdLabel,
                            initialValue: state.RichIDChanged,
                            onChanged: (v) =>
                                context.read<SpousBloc>().add(RichIDChanged(v.trim())
                                ),
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
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  ApiDropdown<String>(
                    labelText: '${l.whoseMobileLabel} *',
                    items: const [
                      'Self',
                      'Family Head',
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
                    onChanged: (v) {
                      final bloc = context.read<SpousBloc>();
                      bloc.add(SpUpdateMobileOwner(v));
                      final headOwner = widget.headMobileOwner;
                      final headNo = widget.headMobileNo?.trim();

                      bool matchesHeadOwner = false;
                      if (v != null) {
                        // 'Family Head' in spouse corresponds to 'Self' in head form
                        if (v == 'Family Head' && headOwner == 'Self') {
                          matchesHeadOwner = true;
                        } else if (headOwner != null && v == headOwner) {
                          matchesHeadOwner = true;
                        }
                      }

                      if (matchesHeadOwner && headNo != null && headNo.isNotEmpty) {
                        bloc.add(SpUpdateMobileNo(headNo));
                      } else {
                        // Clear to allow manual entry when not matched or head has no number
                        bloc.add(const SpUpdateMobileNo(''));
                      }
                    },
                    validator: (value) => Validations.validateWhoMobileNo(l, value),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    key: ValueKey('spouse_mobile_${state.mobileNo ?? ''}'),
                    labelText: '${l.mobileLabel} *',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    initialValue: state.mobileNo,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMobileNo(v.trim())),
                    validator: (value) {
                      final owner = state.mobileOwner;
                      final headOwner = widget.headMobileOwner;
                      final headNo = widget.headMobileNo?.trim();

                      // If owner not chosen, leave this to the owner dropdown validator.
                      if (owner == null || owner.isEmpty) {
                        return Validations.validateMobileNo(l, value);
                      }

                      final spouseSelectedFamilyHead = owner == 'Family Head';
                      final matchesHeadOwner = (spouseSelectedFamilyHead && headOwner == 'Self') || (headOwner != null && owner == headOwner);

                      if (matchesHeadOwner && (headNo == null || headNo.isEmpty)) {
                        return 'Enter mobile number';
                      }

                      return Validations.validateMobileNo(l, value);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Bank account number',
                    keyboardType: TextInputType.number,
                    initialValue: state.bankAcc,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateBankAcc(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'IFSC code',
                    initialValue: state.ifsc,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateIfsc(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Voter Id',
                    initialValue: state.voterId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateVoterId(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Ration Card Id',
                    initialValue: state.rationId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateRationId(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: 'Personal Health Id',
                    initialValue: state.phId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdatePhId(v.trim())),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

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
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateBeneficiaryType(v)),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.gender == 'Female') ...[
                  _section(
                    ApiDropdown<String>(
                      key: ValueKey('spouse_isPreg_${state.gender}_${state.isPregnant ?? ''}'),
                      labelText: '${l.isWomanPregnantQuestion} *',
                      items: const ['Yes', 'No'],
                      getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                      value: state.isPregnant,
                      onChanged: (v) {
                        final bloc = context.read<SpousBloc>();
                        bloc.add(SpUpdateIsPregnant(v));
                        if (v == 'No') {
                          bloc.add(const SpLMPChange(null));
                          bloc.add(const SpEDDChange(null));
                        }
                      },
                      validator: (value) {
                        if (state.gender == 'Female') {
                          return Validations.validateIsPregnant(l, value);
                        }
                        return null;
                      },
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                  if (state.isPregnant == 'Yes') ...[
                    _section(
                      CustomDatePicker(
                        labelText: '${l.lmpDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.lmp,
                        onDateChanged: (d) => context.read<SpousBloc>().add(SpLMPChange(d)),
                        validator: (date) => Validations.validateLMP(l, date),
                      ),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                    _section(
                      CustomDatePicker(
                        labelText: '${l.eddDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.edd,
                        onDateChanged: (d) => context.read<SpousBloc>().add(SpEDDChange(d)),
                        validator: (date) => Validations.validateEDD(l, date),
                      ),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
