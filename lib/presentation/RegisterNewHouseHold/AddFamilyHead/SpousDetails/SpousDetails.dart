import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart';
import 'package:sizer/sizer.dart';
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

class _SpousdetailsState extends State<Spousdetails> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  Widget _section(Widget child) => Padding(
        padding: EdgeInsets.symmetric(vertical: 0.h),
        child: child,
      );

  @override
  void initState() {
    super.initState();
    // Prefill once on first mount using current AddHead state to avoid first-time partial sync.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final headBloc = context.read<AddFamilyHeadBloc>();
      final head = headBloc.state;
      final spBloc = context.read<SpousBloc>();
      final curr = spBloc.state;
      
      // Set relation based on head's gender
      if (head.gender != null) {
        final relation = head.gender == 'Male' ? 'Wife' : 'Husband';
        spBloc.add(SpUpdateRelation(relation));
      }
      
      final memberName = head.spouseName?.trim();
      final spouseName = head.headName?.trim();
      final currMember = curr.memberName ?? '';
      if (memberName != null && memberName.isNotEmpty &&
          (currMember.isEmpty || (memberName.length > currMember.length && memberName.startsWith(currMember)))) {
        spBloc.add(SpUpdateMemberName(memberName));
      }
      final currSpouse = curr.spouseName ?? '';
      if (spouseName != null && spouseName.isNotEmpty &&
          (currSpouse.isEmpty || (spouseName.length > currSpouse.length && spouseName.startsWith(currSpouse)))) {
        spBloc.add(SpUpdateSpouseName(spouseName));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
      listenWhen: (prev, curr) => prev.headName != curr.headName || prev.spouseName != curr.spouseName,
      listener: (ctx, st) {
        final spBloc = ctx.read<SpousBloc>();
        final curr = spBloc.state;
        final memberName = st.spouseName?.trim();
        final spouseName = st.headName?.trim();
        final currMember = curr.memberName ?? '';
        if (memberName != null && memberName.isNotEmpty &&
            (currMember.isEmpty || (memberName.length > currMember.length && memberName.startsWith(currMember)))) {
          spBloc.add(SpUpdateMemberName(memberName));
        }
        final currSpouse = curr.spouseName ?? '';
        if (spouseName != null && spouseName.isNotEmpty &&
            (currSpouse.isEmpty || (spouseName.length > currSpouse.length && spouseName.startsWith(currSpouse)))) {
          spBloc.add(SpUpdateSpouseName(spouseName));
        }
      },
      child: Form(
        key: _formKey,
        child: BlocBuilder<SpousBloc, SpousState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              children: [
                _section(
                  ApiDropdown<String>(
                    labelText: 'Relation with the family head',
                    items: const ['Husband', 'Wife'],
                    getLabel: (s) => s,
                    value: state.relation == 'Spouse' 
                        ? (state.gender == 'Female' ? 'Husband' : 'Wife')
                        : (state.relation ?? (state.gender == 'Female' ? 'Husband' : 'Wife')),
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateRelation(v)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Name of member *',
                    hintText: 'Name of member',
                    initialValue: state.memberName,
                    readOnly: false,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMemberName(v.trim())),
                    validator: (value) => Validations.validateNameofMember(l, value),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Age at the time of marriage',
                    hintText: 'Age at the time of marriage',
                    keyboardType: TextInputType.number,
                    initialValue: state.ageAtMarriage,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateAgeAtMarriage(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Spouse Name *',
                    hintText: 'Spouse Name',
                    initialValue: state.spouseName,
                    readOnly: false,
                    validator: (value) => Validations.validateSpousName(l, value),
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateSpouseName(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Father name',
                    initialValue: state.fatherName,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateFatherName(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                Padding(
                  padding: EdgeInsets.all(2.h),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: state.useDob,
                        onChanged: (_) => context.read<SpousBloc>().add(SpToggleUseDob()),
                      ),
                      Text(l.dobShort, style: TextStyle(fontSize: 14.sp),),
                      SizedBox(width: 4.w),
                      Radio<bool>(
                        value: false,
                        groupValue: state.useDob,
                        onChanged: (_) => context.read<SpousBloc>().add(SpToggleUseDob()),
                      ),
                      Text(l.ageApproximate, style: TextStyle(fontSize:14.sp),),
                    ],
                  ),
                ),
                if (state.useDob)
                  _section(

                    CustomDatePicker(
                      labelText: '${l.dobLabel} *',
                      hintText: l.dateHint,
                      onDateChanged: (d) => context.read<SpousBloc>().add(SpUpdateDob(d)),
                      validator: (date) => Validations.validateDOB(l, date),
                    ),
                  )
                else
                  _section(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 1.h, left: 1.3.h),
                          child: Text(
                            '${l.ageApproximate} *',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                labelText: 'Years',
                                hintText: 'Years',
                                initialValue: state.UpdateYears ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateYearsChanged(v.trim())),
                              ),
                            ),

                            // --- Divider between Years & Months ---
                            Container(
                              width: 1,
                              height: 4.h,
                              color: Colors.grey.shade300,
                              margin: EdgeInsets.symmetric(horizontal: 1.w),
                            ),

                            // --- Months ---
                            Expanded(
                              child: CustomTextField(
                                labelText: 'Months',
                                hintText: 'Months',
                                initialValue: state.UpdateMonths ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateMonthsChanged(v.trim())),
                              ),
                            ),

                            // --- Divider between Months & Days ---
                            Container(
                              width: 1,
                              height: 4.h,
                              color: Colors.grey.shade300,
                              margin: EdgeInsets.symmetric(horizontal: 1.w),
                            ),

                            // --- Days ---
                            Expanded(
                              child: CustomTextField(
                                labelText: 'Days',
                                hintText: 'Days',
                                initialValue: state.UpdateDays ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateDaysChanged(v.trim())),
                              ),
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: '${l.genderLabel} *',
                    items: const ['Male', 'Female', 'Transgender'],
                    getLabel: (s) {
                      switch (s) {
                        case 'Male':
                          return l.genderMale;
                        case 'Female':
                          return l.genderFemale;
                        case 'Transgender':
                          return l.transgender;
                        default:
                          return s;
                      }
                    },
                    value: state.gender,
                    onChanged: null,
                    validator: (value) => Validations.validateGender(l, value),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: l.occupationLabel,
                    items: const ['Unemployed', 'Housewife', 'Daily Wage Labor', 'Agriculture', 'Salaried', 'Business', 'Retired', 'Other'],
                    getLabel: (s) {
                      switch (s) {
                        case 'Unemployed':
                          return l.occupationUnemployed;
                        case 'Housewife':
                          return l.occupationHousewife;
                        case 'Daily Wage Labor':
                          return l.occupationDailyWageLabor;
                        case 'Agriculture':
                          return l.occupationAgriculture;
                        case 'Salaried':
                          return l.occupationSalaried;
                        case 'Business':
                          return l.occupationBusiness;
                        case 'Retired':
                          return l.occupationRetired;
                        case 'Other':
                          return l.occupationOther;
                        default:
                          return s;
                      }
                    },
                    value: state.occupation,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateOccupation(v)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: l.educationLabel,
                    items: const ['No Schooling', 'Primary', 'Secondary', 'High School', 'Intermediate', 'Diploma', 'Graduate and above'],
                    getLabel: (s) {
                      switch (s) {
                        case 'No Schooling':
                          return l.educationNoSchooling;
                        case 'Primary':
                          return l.educationPrimary;
                        case 'Secondary':
                          return l.educationSecondary;
                        case 'High School':
                          return l.educationHighSchool;
                        case 'Intermediate':
                          return l.educationIntermediate;
                        case 'Diploma':
                          return l.educationDiploma;
                        case 'Graduate and above':
                          return l.educationGraduateAndAbove;
                        default:
                          return s;
                      }
                    },
                    value: state.education,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateEducation(v)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: l.religionLabel,
                    items: const ['Do not want to disclose', 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhism', 'Jainism', 'Parsi', 'Other'],
                    getLabel: (s) {
                      switch (s) {
                        case 'Do not want to disclose':
                          return l.religionNotDisclosed;
                        case 'Hindu':
                          return l.religionHindu;
                        case 'Muslim':
                          return l.religionMuslim;
                        case 'Christian':
                          return l.religionChristian;
                        case 'Sikh':
                          return l.religionSikh;
                        case 'Buddhism':
                          return l.religionBuddhism;
                        case 'Jainism':
                          return l.religionJainism;
                        case 'Parsi':
                          return l.religionParsi;
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
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: l.categoryLabel,
                    items: const ['NotDisclosed', 'General', 'OBC', 'SC', 'ST', 'PichdaVarg1', 'PichdaVarg2', 'AtyantPichdaVarg', 'DontKnow', 'Other'],
                    getLabel: (s) {
                      switch (s) {
                        case 'NotDisclosed':
                          return l.categoryNotDisclosed;
                        case 'General':
                          return l.categoryGeneral;
                        case 'OBC':
                          return l.categoryOBC;
                        case 'SC':
                          return l.categorySC;
                        case 'ST':
                          return l.categoryST;
                        case 'PichdaVarg1':
                          return l.categoryPichdaVarg1;
                        case 'PichdaVarg2':
                          return l.categoryPichdaVarg2;
                        case 'AtyantPichdaVarg':
                          return l.categoryAtyantPichdaVarg;
                        case 'DontKnow':
                          return l.categoryDontKnow;
                        case 'Other':
                          return l.religionOther;
                        default:
                          return s;
                      }
                    },
                    value: state.category,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateCategory(v)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: l.abhaAddressLabel,
                          initialValue: state.abhaAddress,
                          onChanged: (v) =>
                              context.read<SpousBloc>().add(SpUpdateAbhaAddress(v.trim())),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        height: 3.5.h,
                        child: RoundButton(
                          title: l.linkAbha,
                          width: 15.h,
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
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),
                if (state.gender == 'Female') ...[
                  _section(
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: l.richIdLabel,
                            initialValue: state.RichIDChanged,
                            onChanged: (v) =>
                                context.read<SpousBloc>().add(RichIDChanged(v.trim())),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        SizedBox(
                          height: 3.5.h,
                          width: 15.h,
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
                ],
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

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
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    key: ValueKey('spouse_mobile_${state.mobileNo ?? ''}')
,
                    labelText: '${l.mobileLabel} *',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    initialValue: state.mobileNo,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMobileNo(v.trim())),
                    validator: (value) {
                      final owner = state.mobileOwner;
                      final headOwner = widget.headMobileOwner;
                      final headNo = widget.headMobileNo?.trim();

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
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Bank account number',
                    keyboardType: TextInputType.number,
                    initialValue: state.bankAcc,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateBankAcc(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'IFSC code',
                    initialValue: state.ifsc,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateIfsc(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Voter Id',
                    initialValue: state.voterId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateVoterId(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Ration Card Id',
                    initialValue: state.rationId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateRationId(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: 'Personal Health Id',
                    initialValue: state.phId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdatePhId(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  ApiDropdown<String>(
                    labelText: l.beneficiaryTypeLabel,
                    items: const ['StayingInHouse', 'SeasonalMigrant'],
                    getLabel: (s) {
                      switch (s) {
                        case 'StayingInHouse':
                          return l.migrationStayingInHouse;
                        case 'SeasonalMigrant':
                          return l.migrationSeasonalMigrant;
                        default:
                          return s;
                      }
                    },
                    value: state.beneficiaryType,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateBeneficiaryType(v)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),
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
                  SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                  if (state.isPregnant == 'Yes') ...[
                    _section(
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.lmp ?? now,
                            firstDate: DateTime(now.year - 5),
                            lastDate: now,
                          );
                          if (picked != null) {
                            context.read<SpousBloc>().add(SpLMPChange(picked));
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '${l.lmpDateLabel} *',
                            border: const UnderlineInputBorder(),
                          ),
                          child: Text(
                            state.lmp != null
                                ? '${state.lmp!.day.toString().padLeft(2, '0')}-${state.lmp!.month.toString().padLeft(2, '0')}-${state.lmp!.year}'
                                : 'dd-mm-yyyy',
                            style: TextStyle(
                              color: state.lmp != null ? Colors.black : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),

                    _section(
                      InkWell(
                        onTap: state.lmp == null 
                            ? null 
                            : () async {
                                final now = DateTime.now();
                                final firstDate = state.lmp?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1));
                                final lastDate = state.lmp?.add(const Duration(days: 280)) ?? now.add(const Duration(days: 280));
                                
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: state.edd ?? firstDate,
                                  firstDate: firstDate,
                                  lastDate: lastDate,
                                );
                                if (picked != null) {
                                  context.read<SpousBloc>().add(SpEDDChange(picked));
                                }
                              },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '${l.eddDateLabel} *',
                            border: const UnderlineInputBorder(),
                          ),
                          child: Text(
                            state.edd != null
                                ? '${state.edd!.day.toString().padLeft(2, '0')}-${state.edd!.month.toString().padLeft(2, '0')}-${state.edd!.year}'
                                : 'dd-mm-yyyy',
                            style: TextStyle(
                              color: state.edd != null ? Colors.black : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            );
        },
      ),
    ));
  }

  @override
  bool get wantKeepAlive => true;
}
