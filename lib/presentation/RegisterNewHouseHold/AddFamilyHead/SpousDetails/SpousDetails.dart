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

final GlobalKey<FormState> spousFormKey = GlobalKey<FormState>();

String? spousLastFormError;

void clearSpousFormError() {
  spousLastFormError = null;
}

String? captureSpousError(String? message) {
  if (message != null && spousLastFormError == null) {
    spousLastFormError = message;
  }
  return message;
}

class Spousdetails extends StatefulWidget {
  final SpousState? initial;
  final String? headMobileOwner;
  final String? headMobileNo;
  // When true, this widget listens to AddFamilyHeadBloc and mirrors
  // head form fields into SpousBloc. For member flows we set this to
  // false so that only member-specific spouse data is shown.
  final bool syncFromHead;
  
  const Spousdetails({
    super.key, 
    this.initial, 
    this.headMobileOwner, 
    this.headMobileNo,
    this.syncFromHead = true,
  });

  @override
  State<Spousdetails> createState() => _SpousdetailsState();
}

class _SpousdetailsState extends State<Spousdetails> with AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> _formKey = spousFormKey;

  Widget _section(Widget child) => Padding(
        padding: EdgeInsets.symmetric(vertical: 0.h),
        child: child,
      );

  @override
  void initState() {
    super.initState();
    // Prefill once on first mount using current AddHead state to avoid
    // first-time partial sync. This is only needed when used inside the
    // head form; for member flows we skip it.
    if (widget.syncFromHead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final headBloc = context.read<AddFamilyHeadBloc>();
        final head = headBloc.state;
        final spBloc = context.read<SpousBloc>();
        final curr = spBloc.state;
        
        // Set relation and opposite gender based on head's gender
        if (head.gender != null) {
          final isMale = head.gender == 'Male';
          final relation = isMale ? 'Wife' : 'Husband';
          final oppositeGender = isMale ? 'Female' : 'Male';
          
          spBloc.add(SpUpdateRelation(relation));
          spBloc.add(SpUpdateGender(oppositeGender));
        }
        
        final memberName = head.spouseName?.trim() ?? '';
        final spouseName = head.headName?.trim() ?? '';
        final currMember = curr.memberName?.trim() ?? '';
        // Only overwrite existing values when the new value is non-empty.
        if (memberName.isNotEmpty && memberName != currMember) {
          spBloc.add(SpUpdateMemberName(memberName));
        }
        final currSpouse = curr.spouseName?.trim() ?? '';
        if (spouseName.isNotEmpty && spouseName != currSpouse) {
          spBloc.add(SpUpdateSpouseName(spouseName));
        }
        
        // Auto-fill mobile number if head's mobile is available and mobile owner is 'Family Head'
        if (head.mobileNo != null && head.mobileNo!.isNotEmpty) {
          if (widget.headMobileOwner == 'Family Head' || curr.mobileOwner == 'Family Head') {
            spBloc.add(SpUpdateMobileNo(head.mobileNo!));
            spBloc.add(SpUpdateMobileOwner('Family Head'));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    // When used inside AddNewFamilyHeadScreen we wrap the form in a
    // BlocListener to mirror head changes. For member flows we just
    // return the plain form driven by SpousBloc.
    if (widget.syncFromHead) {
      return BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
        listenWhen: (previous, current) =>
            previous.headName != current.headName ||
            previous.spouseName != current.spouseName ||
            previous.gender != current.gender ||
            previous.mobileNo != current.mobileNo ||
            previous.mobileOwner != current.mobileOwner,
        listener: (ctx, st) {
          final spBloc = ctx.read<SpousBloc>();
          final curr = spBloc.state;

          // Update gender and relation when head's gender changes
          if (st.gender != null) {
            final isMale = st.gender == 'Male';
            final relation = isMale ? 'Wife' : 'Husband';
            final oppositeGender = isMale ? 'Female' : 'Male';

            if (curr.relation != relation) {
              spBloc.add(SpUpdateRelation(relation));
            }
            if (curr.gender != oppositeGender) {
              spBloc.add(SpUpdateGender(oppositeGender));
            }
          }

          final previous = context.read<AddFamilyHeadBloc>().state;
          if ((st.mobileNo != null && st.mobileNo != previous.mobileNo) ||
              (st.mobileOwner != null && st.mobileOwner != previous.mobileOwner)) {
            if (st.mobileOwner == 'Family Head' && st.mobileNo != null && st.mobileNo!.isNotEmpty) {
              spBloc.add(SpUpdateMobileNo(st.mobileNo!));
              spBloc.add(SpUpdateMobileOwner('Family Head'));
            } else if (st.mobileOwner != 'Family Head' && curr.mobileOwner == 'Family Head') {
              spBloc.add(SpUpdateMobileNo(''));
            }
          }

          // Update names from head form only when non-empty, so that
          // member-flow prefilled values are not wiped out by blanks.
          final memberName = st.spouseName?.trim() ?? '';
          final spouseName = st.headName?.trim() ?? '';
          final currMember = curr.memberName?.trim() ?? '';
          if (memberName.isNotEmpty && memberName != currMember) {
            spBloc.add(SpUpdateMemberName(memberName));
          }
          final currSpouse = curr.spouseName?.trim() ?? '';
          if (spouseName.isNotEmpty && spouseName != currSpouse) {
            spBloc.add(SpUpdateSpouseName(spouseName));
          }
        },
        child: _buildForm(l),
      );
    }

    return _buildForm(l);
  }

  Widget _buildForm(AppLocalizations l) {
    return Form(
      key: _formKey,
      child: BlocBuilder<SpousBloc, SpousState>(
        builder: (context, state) {
          final spBloc = context.read<SpousBloc>();
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            children: [
                _section(
                  ApiDropdown<String>(
                    labelText: l.relationWithFamilyHead,
                    items: const ['Husband', 'Wife'],
                    getLabel: (s) => s == 'Husband' ? l.husbandLabel : l.wife,
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
                    labelText: '${l.nameOfMember} *',
                    hintText: l.nameOfMemberHint,
                    initialValue: state.memberName,
                    readOnly: false,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMemberName(v.trim())),
                    validator: (value) => captureSpousError(Validations.validateNameofMember(l, value)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: l.ageAtMarriage,
                    hintText: l.ageAtMarriageHint,
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
                    labelText: '${l.spouseName} *',
                    hintText: l.spouseNameHint,
                    initialValue: state.spouseName,
                    readOnly: false,
                    validator: (value) => captureSpousError(Validations.validateSpousName(l, value)),
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateSpouseName(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: l.fatherName,
                    hintText: l.fatherName,
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
                      initialDate: state.dob,
                      onDateChanged: (d) => context.read<SpousBloc>().add(SpUpdateDob(d)),
                      validator: (date) => captureSpousError(Validations.validateDOB(l, date)),
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
                                labelText: l.years,
                                hintText: '0',
                                maxLength: 3,
                                initialValue: state.UpdateYears ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateYearsChanged(v.trim())),
                                validator: (value) => captureSpousError(
                                  Validations.validateApproxAge(
                                    l,
                                    value,
                                    state.UpdateMonths,
                                    state.UpdateDays,
                                  ),
                                ),
                              ),
                            ),

                            // Container(
                            //   width: 1,
                            //   height: 4.h,
                            //   color: Colors.grey.shade300,
                            //   margin: EdgeInsets.symmetric(horizontal: 1.w),
                            // ),

                            // --- Months ---
                            Expanded(
                              child: CustomTextField(
                                labelText: l.months,
                                hintText: '0',
                                maxLength: 2,
                                initialValue: state.UpdateMonths ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateMonthsChanged(v.trim())),
                                validator: (value) => captureSpousError(
                                  Validations.validateApproxAge(
                                    l,
                                    state.UpdateYears,
                                    value,
                                    state.UpdateDays,
                                  ),
                                ),
                              ),
                            ),

                            // --- Divider between Months & Days ---
                            // Container(
                            //   width: 1,
                            //   height: 4.h,
                            //   color: Colors.grey.shade300,
                            //   margin: EdgeInsets.symmetric(horizontal: 1.w),
                            // ),

                            // --- Days ---
                            Expanded(
                              child: CustomTextField(
                                labelText: l.days,
                                hintText: '0',
                                maxLength: 2,
                                initialValue: state.UpdateDays ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<SpousBloc>().add(UpdateDaysChanged(v.trim())),
                                validator: (value) => captureSpousError(
                                  Validations.validateApproxAge(
                                    l,
                                    state.UpdateYears,
                                    state.UpdateMonths,
                                    value,
                                  ),
                                ),
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
                if (state.occupation == 'Other')
                  SizedBox(height: 1.h),
                if (state.occupation == 'Other')
                  _section(
                    CustomTextField(
                      labelText: 'Enter Occupation',
                      hintText: 'Enter Occupation',
                      initialValue: state.otherOccupation,
                      onChanged: (v) => context
                          .read<SpousBloc>()
                          .add(SpUpdateOtherOccupation(v.trim())),
                    ),
                  ),
                if (state.occupation == 'Other')
                  SizedBox(height: 1.h),
                if (state.occupation == 'Other')
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
                if (state.religion == 'Other')
                  SizedBox(height: 1.h),
                if (state.religion == 'Other')
                  _section(
                    CustomTextField(
                      labelText: 'Enter Religion',
                      hintText: 'Enter Religion',
                      initialValue: state.otherReligion,
                      onChanged: (v) => context
                          .read<SpousBloc>()
                          .add(SpUpdateOtherReligion(v.trim())),
                    ),
                  ),
                if (state.religion == 'Other')
                  SizedBox(height: 1.h),
                if (state.religion == 'Other')
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
                if (state.category == 'Other')
                  SizedBox(height: 1.h),
                if (state.category == 'Other')
                  _section(
                    CustomTextField(
                      labelText: 'Enter Category',
                      hintText: 'Enter Category',
                      initialValue: state.otherCategory,
                      onChanged: (v) => context
                          .read<SpousBloc>()
                          .add(SpUpdateOtherCategory(v.trim())),
                    ),
                  ),
                if (state.category == 'Other')
                  SizedBox(height: 1.h),
                if (state.category == 'Other')
                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: l.abhaAddressLabel,
                          hintText: l.abhaAddressLabel,
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
                          fontSize: 14.sp,
                          onPress: () {
                            Navigator.pushNamed(context, Route_Names.Abhalinkscreen);

                          },
                        ),
                      ),
                    ],
                  ),
                ),

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
                      final spBloc = context.read<SpousBloc>();
                      spBloc.add(SpUpdateMobileOwner(v));

                      if (v == 'Family Head') {
                        final headNo = (widget.headMobileNo?.trim() ??
                            context.read<AddFamilyHeadBloc>().state.mobileNo?.trim());
                        if (headNo != null && headNo.isNotEmpty) {
                          spBloc.add(SpUpdateMobileNo(headNo));
                        }
                      } else {
                        spBloc.add(const SpUpdateMobileNo(''));
                      }
                    },
                    validator: (value) => captureSpousError(Validations.validateWhoMobileNo(l, value)),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.mobileOwner == 'Other')
                  SizedBox(height: 1.h),
                if (state.mobileOwner == 'Other')
                  _section(
                    CustomTextField(
                      labelText: 'Relation with mobile no. holder *',
                      hintText: 'Relation with mobile no. holder',
                      initialValue: state.mobileOwnerOtherRelation,
                      onChanged: (v) => context
                          .read<SpousBloc>()
                          .add(SpUpdateMobileOwnerOtherRelation(v.trim())),
                      validator: (value) => state.mobileOwner == 'Other'
                          ? captureSpousError(
                              (value == null || value.trim().isEmpty)
                                  ? 'Relation with mobile no. holder is required'
                                  : null,
                            )
                          : null,
                    ),
                  ),
                if (state.mobileOwner == 'Other')
                  SizedBox(height: 1.h),
                if (state.mobileOwner == 'Other')
                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    key: ValueKey('spouse_mobile'),
                    labelText: '${l.mobileLabel} *',
                    hintText: '${l.mobileLabel} *',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    initialValue: state.mobileNo,
                    readOnly: state.mobileOwner == 'Family Head',
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateMobileNo(v.trim())),
                    validator: (value) {
                      final owner = state.mobileOwner;
                      final headOwner = widget.headMobileOwner;
                      final headNo = widget.headMobileNo?.trim();

                      if (owner == null || owner.isEmpty) {
                        return captureSpousError(Validations.validateMobileNo(l, value));
                      }

                      final spouseSelectedFamilyHead = owner == 'Family Head';
                      final matchesHeadOwner = (spouseSelectedFamilyHead && headOwner == 'Self') || (headOwner != null && owner == headOwner);

                      if (matchesHeadOwner && (headNo == null || headNo.isEmpty)) {
                        return captureSpousError('Enter mobile number');
                      }

                      return captureSpousError(Validations.validateMobileNo(l, value));
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
                    labelText: l.bankAccountNumber,
                    hintText: l.bankAccountNumberHint,
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
                    labelText: l.ifscCode,
                    hintText: l.ifscCodeHint,
                    initialValue: state.ifsc,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateIfsc(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: l.voterId,
                    hintText: l.voterIdHint,
                    initialValue: state.voterId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateVoterId(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: l.rationCardId,
                    hintText: l.rationCardIdHint,
                    initialValue: state.rationId,
                    onChanged: (v) => context.read<SpousBloc>().add(SpUpdateRationId(v.trim())),
                  ),
                ),
                SizedBox(height: 1.h),
                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                SizedBox(height: 1.h),

                _section(
                  CustomTextField(
                    labelText: l.personalHealthId,
                    hintText: l.personalHealthIdHint,
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
                          return captureSpousError(Validations.validateIsPregnant(l, value));
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
                SizedBox(height: 1.h),

                  if (state.isPregnant == 'Yes') ...[
                    _section(
                      CustomDatePicker(
                        labelText: '${l.lmpDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.lmp,
                        onDateChanged: (d) {
                          final bloc = context.read<SpousBloc>();
                          bloc.add(SpLMPChange(d));
                          if (d != null) {
                            final edd = DateTime(d.year, d.month + 9, d.day + 5);
                            bloc.add(SpEDDChange(edd));
                          } else {
                            bloc.add(const SpEDDChange(null));
                          }
                        },
                        validator: (date) => captureSpousError(Validations.validateLMP(l, date)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      ),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

                    _section(
                      CustomDatePicker(
                        labelText: '${l.eddDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.edd,
                        onDateChanged: (d) => context.read<SpousBloc>().add(SpEDDChange(d)),
                        validator: (date) => captureSpousError(Validations.validateEDD(l, date)),
                        readOnly: true,
                      ),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

                  ],
                  
                  if (state.isPregnant == 'No') ...[
                    ApiDropdown<String>(
                      labelText: 'Are you/your partner adopting family planning? *',
                      items: const ['Select', 'Yes', 'No'],
                      getLabel: (s) {
                        switch (s) {
                          case 'Yes':
                            return l.yes;
                          case 'No':
                            return l.no;
                          default:
                            return s;
                        }
                      },
                      value: state.familyPlanningCounseling ?? 'Select',
                      onChanged: (v) {
                        if (v == null) return;
                        spBloc.add(FamilyPlanningCounselingChanged(v));
                      },
                      validator: (value) => captureSpousError(
                        Validations.validateAdoptingPlan(l, value),
                      ),
                    ),
                    Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                    SizedBox(height: 1.h),
                    if (state.familyPlanningCounseling == 'Yes') ...[
                      const SizedBox(height: 8),
                      ApiDropdown<String>(
                        labelText: '${l.methodOfContra} *',
                        items: const [
                          'Select',
                          'Condom',
                          'Mala -N (Daily Contraceptive pill)',
                          'Antra injection',
                          'Copper -T (IUCD)',
                          'Chhaya (Weekly Contraceptive pill)',
                          'ECP (Emergency Contraceptive pill)',
                          'Male Sterilization',
                          'Female Sterilization',
                          'Any Other Specify'
                        ],
                        getLabel: (value) => value,
                        value: state.fpMethod ?? 'Select',
                        onChanged: (value) {
                          if (value != null) {
                            spBloc.add(FpMethodChanged(value));
                          }
                        },
                        validator: (value) => captureSpousError(Validations.validateAntra(l, value)),

                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),
                    ],


                    if(state.fpMethod == 'Antra injection') ...[
                      CustomDatePicker(
                        labelText: 'Date of Antra',
                        initialDate: state.antraDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            spBloc.add(DateofAntraChanged(date));
                          }
                        },

                      ),
                    ],
                    if (state.fpMethod == 'Copper -T (IUCD)') ...[
                      CustomDatePicker(
                        labelText: 'Removal Date',
                        initialDate: state.removalDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            spBloc.add(RemovalDateChanged(date));
                          }
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),
                      CustomTextField(
                        labelText: 'Reason',
                        hintText: 'reason ',
                        initialValue: state.removalReason,
                        onChanged: (value) {
                          spBloc.add(RemovalReasonChanged(value ?? ''));
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),
                    ],

                    if (state.fpMethod == 'Condom') ...[
                      CustomTextField(
                        labelText: 'Quantity of Condoms',
                        hintText: 'Quantity of Condoms',
                        keyboardType: TextInputType.number,
                        initialValue: state.condomQuantity,
                        onChanged: (value) {
                          spBloc.add(CondomQuantityChanged(value ?? ''));
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),                    ],

                    if (state.fpMethod == 'Mala -N (Daily Contraceptive pill)') ...[
                      CustomTextField(
                        labelText: 'Quantity of Mala -N (Daily Contraceptive pill)',
                        hintText: 'Quantity of Mala -N (Daily Contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.malaQuantity,
                        onChanged: (value) {
                          spBloc.add(MalaQuantityChanged(value ?? ''));
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),                    ],

                    if (state.fpMethod == 'Chhaya (Weekly Contraceptive pill)') ...[
                      CustomTextField(
                        labelText: 'Quantity of Chhaya (Weekly Contraceptive pill)',
                        hintText: 'Quantity of quantity',
                        keyboardType: TextInputType.number,
                        initialValue: state.chhayaQuantity,
                        onChanged: (value) {
                          spBloc.add(ChhayaQuantityChanged(value ?? ''));
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),                    ],

                    if (state.fpMethod == 'ECP (Emergency Contraceptive pill)') ...[
                      CustomTextField(
                        labelText: 'Quantity of ECP (Emergency Contraceptive pill)',
                        hintText: 'Quantity of ECP (Emergency Contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.ecpQuantity,
                        onChanged: (value) {
                          spBloc.add(ECPQuantityChanged(value ?? ''));
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      SizedBox(height: 1.h),
                    ],
                  ]
                ],
              ],
            );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
