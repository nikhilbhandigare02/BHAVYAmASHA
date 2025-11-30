import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/SpousDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/bloc/spous_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/ChildrenDetaills.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/bloc/children_bloc.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:sizer/sizer.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/bloc/registernewhousehold_bloc.dart';

import 'bloc/add_family_head_bloc.dart';



class AddNewFamilyHeadScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, String>? initial;
  final int initialTab;

  const AddNewFamilyHeadScreen({
    super.key,
    this.isEdit = false,
    this.initial,
    this.initialTab = 0,
  });

  @override
  State<AddNewFamilyHeadScreen> createState() => _AddNewFamilyHeadScreenState();
}

class _AddNewFamilyHeadScreenState extends State<AddNewFamilyHeadScreen>
    with SingleTickerProviderStateMixin {
  // Calculate DOB based on entered years, months, and days
  void _updateDobFromAge(String years, String months, String days) {
    // If any field is empty, clear the DOB and return
    if (years.trim().isEmpty || months.trim().isEmpty || days.trim().isEmpty) {
      context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(null));
      return;
    }
    
    // If all fields are empty, clear the DOB and return
    if (years.trim().isEmpty && months.trim().isEmpty && days.trim().isEmpty) {
      context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(null));
      return;
    }
    
    // Parse the values, defaulting to 0 if parsing fails
    final y = int.tryParse(years.trim()) ?? 0;
    final m = int.tryParse(months.trim()) ?? 0;
    final d = int.tryParse(days.trim()) ?? 0;

    // If all values are 0, clear the DOB
    if (y == 0 && m == 0 && d == 0) {
      context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(null));
      return;
    }

    final now = DateTime.now();
    var calculatedDob = DateTime(
      now.year - y,
      now.month - m,
      now.day - d,
    );

    // Handle month overflow
    if (calculatedDob.day != now.day) {
      // Adjust for months with different number of days
      calculatedDob = DateTime(calculatedDob.year, calculatedDob.month + 1, 0);
    }

    // Update the DOB in the state if it's different
    final currentDob = context.read<AddFamilyHeadBloc>().state.dob;
    if (currentDob == null || 
        currentDob.year != calculatedDob.year || 
        currentDob.month != calculatedDob.month || 
        currentDob.day != calculatedDob.day) {
      context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(calculatedDob));
    }
  }
  final _formKey = GlobalKey<FormState>();

  // Guard to avoid infinite loops when syncing names between
  // head form and spouse details tab.
  bool _syncingNames = false;


  static String? _lastFormError;

  static void _clearFormError() {
    _lastFormError = null;
  }

  static String? _captureError(String? message) {
    if (message != null && _lastFormError == null) {
      _lastFormError = message;
    }
    return message;
  }

  int _ageFromDob(DateTime dob) {
    return DateTime.now().year - dob.year;
  }

  String? _validateYoungestChild(ChildrenState s, AppLocalizations l) {
    return Validations.validateYoungestChildAge(l, s.youngestAge, s.ageUnit);
  }

  Widget _Section({required Widget child}) {
    return child;
  }

  Widget _buildFamilyHeadForm(BuildContext context, AddFamilyHeadState state, AppLocalizations l) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.5.h),
        children: [
          _Section(
            child: CustomTextField(
              labelText: '${l.houseNoLabel} *',
              hintText: l.houseNoHint,
              initialValue: state.houseNo,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateHouseNo(v.trim())),
              validator: (value) => _captureError(Validations.validateHouseNo(l, value)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: '${l.nameOfFamilyHeadLabel} *',
              hintText: l.nameOfFamilyHeadHint,
              initialValue: state.headName,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateHeadName(v.trim())),
              validator: (value) => _captureError(Validations.validateFamilyHead(l, value)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.fatherNameLabel,
              hintText: l.fatherNameLabel,
              initialValue: state.fatherName,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateFatherName(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: state.useDob,
                  onChanged: (_) => context.read<AddFamilyHeadBloc>().add(AfhToggleUseDob()),
                ),
                Text(l.dobShort, style: TextStyle(fontSize: 14.sp),),
                SizedBox(width: 2.w),
                Radio<bool>(
                  value: false,
                  groupValue: state.useDob,
                  onChanged: (_) => context.read<AddFamilyHeadBloc>().add(AfhToggleUseDob()),
                ),
                Text(l.ageApproximate, style: TextStyle(fontSize:14.sp),),
              ],
            ),
          ),
          if (state.useDob)
            _Section(
              child: CustomDatePicker(
                labelText: '${l.dobLabel} *',
                hintText: l.dateHint,
                initialDate: state.dob,
                firstDate: DateTime.now().subtract(const Duration(days: 110 * 365)),
                lastDate: DateTime.now().subtract(const Duration(days: 15 * 365)),
                onDateChanged: (d) =>
                    context.read<AddFamilyHeadBloc>().add(AfhUpdateDob(d)),
                validator: (date) =>
                    _captureError(Validations.validateDOB(l, date)),
              ),
            )
          else
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 1.h, left: 1.3.h),
                    child: Text(
                      '${l.ageApproximate} *',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      // --- Years ---
                      Expanded(
                        child: CustomTextField(
                          labelText: l.years,
                          hintText: l.years,
                          maxLength: 3,
                          initialValue: state.years ?? '',
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            context.read<AddFamilyHeadBloc>().add(UpdateYears(v.trim()));
                            final state = context.read<AddFamilyHeadBloc>().state;
                            _updateDobFromAge(v.trim(), state.months ?? '', state.days ?? '');
                          },
                          validator: (value) => _captureError(
                            Validations.validateApproxAge(
                              l,
                              value,
                              state.months,
                              state.days,
                            ),
                          ),
                        ),
                      ),

                      // // --- Divider between Years & Months ---
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
                          hintText: l.months,
                          maxLength: 2,
                          initialValue: state.months ?? '',
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            context.read<AddFamilyHeadBloc>().add(UpdateMonths(v.trim()));
                            final state = context.read<AddFamilyHeadBloc>().state;
                            _updateDobFromAge(state.years ?? '', v.trim(), state.days ?? '');
                          },
                          validator: (value) => _captureError(
                            Validations.validateApproxAge(
                              l,
                              state.years,
                              value,
                              state.days,
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
                          hintText: l.days,
                          initialValue: state.days ?? '',
                          keyboardType: TextInputType.number,
                          maxLength: 2,
                          onChanged: (v) {
                            context.read<AddFamilyHeadBloc>().add(UpdateDays(v.trim()));
                            final state = context.read<AddFamilyHeadBloc>().state;
                            _updateDobFromAge(state.years ?? '', state.months ?? '', v.trim());
                          },
                          validator: (value) => _captureError(
                            Validations.validateApproxAge(
                              l,
                              state.years,
                              state.months,
                              value,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  )

                ],
              ),
            ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateGender(v)),
              validator: (v) => _captureError(v == null ? '${l.genderLabel} ${l.requiredField}' : null),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateOccupation(v)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          if (state.occupation == 'Other')
            _Section(
              child: CustomTextField(
                labelText: 'Enter occupation',
                hintText: 'Enter occupation',
                initialValue: state.otherOccupation,
                onChanged: (v) => context
                    .read<AddFamilyHeadBloc>()
                    .add(AfhUpdateOtherOccupation(v.trim())),
              ),
            ),
          if (state.occupation == 'Other')
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateEducation(v)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateReligion(v)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          if (state.religion == 'Other')
            _Section(
              child: CustomTextField(
                labelText: 'Enter Religion',
                hintText: 'Enter Religion',
                initialValue: state.otherReligion,
                onChanged: (v) => context
                    .read<AddFamilyHeadBloc>()
                    .add(AfhUpdateOtherReligion(v.trim())),
              ),
            ),
          if (state.religion == 'Other')
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateCategory(v)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          if (state.category == 'Other')
            _Section(
              child: CustomTextField(
                labelText: 'Enter Category',
                hintText: 'Enter Category',
                initialValue: state.otherCategory,
                onChanged: (v) => context
                    .read<AddFamilyHeadBloc>()
                    .add(AfhUpdateOtherCategory(v.trim())),
              ),
            ),
          if (state.category == 'Other')
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
          _Section(
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    labelText: l.abhaAddressLabel,
                    hintText: l.abhaAddressLabel,
                    initialValue: state.AfhABHAChange,
                    onChanged: (v) =>
                        context.read<AddFamilyHeadBloc>().add(AfhABHAChange(v.trim())),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 3.h,
                  width: 15.h,
                  child: RoundButton(
                    title: l.linkAbha,
                    width: 40.w,
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
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
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
                    height: 3.h,
                    width: 15.h,
                    child: RoundButton(
                      title: 'VERIFY',
                      width: 40.w,
                      borderRadius: 1.h,
                      fontSize: 14.sp,
                      onPress: () {
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
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
                validator: (value) => _captureError(Validations.validateWhoMobileNo(l, value)),
              ),
            ),

          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          if (state.mobileOwner == 'Other')
            _Section(
              child: CustomTextField(
                labelText: 'Enter Relation with mobile no. holder *' ,
                hintText: 'Enter Relation with mobile no. holder',
                initialValue: state.mobileOwnerOtherRelation,
                onChanged: (v) => context
                    .read<AddFamilyHeadBloc>()
                    .add(AfhUpdateMobileOwnerOtherRelation(v.trim())),
                validator: (value) => state.mobileOwner == 'Other'
                    ? _captureError(
                        (value == null || value.trim().isEmpty)
                            ? 'Relation with mobile no. holder is required'
                            : null,
                      )
                    : null,
              ),
            ),
          if (state.mobileOwner == 'Other')
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: '${l.mobileLabel} *',
              hintText: '${l.mobileLabel} *',
              keyboardType: TextInputType.number,
              maxLength: 10,
              initialValue: state.mobileNo,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMobileNo(v.trim())),
              validator: (value) => _captureError(Validations.validateMobileNo(l, value)),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.villageNameLabel,
              hintText: l.villageNameLabel,
              initialValue: state.village,
              readOnly: !widget.isEdit,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateVillage(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.wardNoLabel,
              hintText: l.wardNoLabel,
              initialValue: state.ward,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateWard(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.mohallaTolaNameLabel,
              hintText: l.mohallaTolaNameLabel,
              initialValue: state.mohalla,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMohalla(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
            buildWhen: (previous, current) => previous.bankAcc != current.bankAcc,
            builder: (contxt, state) {
              final bankAcc = state.bankAcc ?? '';
              final isValid = bankAcc.isEmpty || bankAcc.replaceAll(RegExp(r'[^0-9]'), '').length >= 10;

              return Column(
                children: [
                  _Section(
                    child: CustomTextField(
                      labelText: l.accountNumberLabel,
                      hintText: l.accountNumberLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      initialValue: state.bankAcc,
                      onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateBankAcc(v.trim())),
                    ),
                  ),
                  Divider(
                    color: !isValid ? Colors.red : AppColors.divider,
                    thickness: !isValid ? 1.0 : 0.1.h,
                    height: 0,
                  ),
                ],
              );
            },
          ),

          _Section(
            child: CustomTextField(
              labelText: l.ifscLabel,
              hintText:l.ifscLabel,
              initialValue: state.ifsc,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateIfsc(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.voterIdLabel,
              hintText: l.voterIdLabel,
              initialValue: state.voterId,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateVoterId(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.rationCardIdLabel,
              hintText: l.rationCardIdLabel,
              initialValue: state.rationId,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateRationId(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: CustomTextField(
              labelText: l.personalHealthIdLabel,
              hintText:  l.personalHealthIdLabel,
              initialValue: state.phId,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdatePhId(v.trim())),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
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
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateBeneficiaryType(v)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

          _Section(
            child: ApiDropdown<String>(
              labelText: '${l.maritalStatusLabel} *',
              items: const [
                'Married',
                'Unmarried',
                'Widowed',
                'Widower',
                'Separated',
                'Divorced',
              ],
              getLabel: (s) {
                switch (s) {
                  case 'Married':
                    return l.maritalStatusMarried;
                  case 'Unmarried':
                    return l.maritalStatusUnmarried;
                  case 'Widowed':
                    return l.maritalStatusWidowed;
                  case 'Widower':
                    return l.maritalStatusWidower;
                  case 'Separated':
                    return l.maritalStatusSeparated;
                  case 'Divorced':
                    return l.maritalStatusDivorced;
                  default:
                    return s;
                }
              },
              value: state.maritalStatus,
              onChanged: (v) => context.read<AddFamilyHeadBloc>().add(AfhUpdateMaritalStatus(v)),
              validator: (value) => _captureError(Validations.validateMaritalStatus(l, value)),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

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
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: '${l.spouseNameLabel} *',
                hintText: l.spouseNameHint,
                initialValue: state.spouseName,
                onChanged: (v) => context
                    .read<AddFamilyHeadBloc>()
                    .add(AfhUpdateSpouseName(v.trim())),
                validator: (value) => _captureError(Validations.validateSpousName(l, value)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

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
                      bloc.add(LMPChange(null));
                      bloc.add(EDDChange(null));
                    }
                  },
                  validator: (value) {
                    if (state.gender == 'Female' && state.maritalStatus == 'Married') {
                      return _captureError(Validations.validateIsPregnant(l, value));
                    }
                    return null;
                  },
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
              if (state.isPregnant == 'Yes') ...[
                _Section(
                  child: CustomDatePicker(
                    labelText: '${l.lmpDateLabel} *',
                    hintText: l.dateHint,
                    initialDate: state.lmp,
                    onDateChanged: (d) {
                      final bloc = context.read<AddFamilyHeadBloc>();
                      bloc.add(LMPChange(d));
                      if (d != null) {
                        final edd = DateTime(d.year, d.month + 9, d.day + 5);
                        bloc.add(EDDChange(edd));
                      } else {
                        bloc.add(EDDChange(null));
                      }
                    },
                    validator: (date) => _captureError(Validations.validateLMP(l, date)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

                _Section(
                  child: CustomDatePicker(
                    labelText: '${l.eddDateLabel} *',
                    hintText: l.dateHint,
                    initialDate: state.edd,
                    onDateChanged: (d) => context.read<AddFamilyHeadBloc>().add(EDDChange(d)),
                    validator: (date) => _captureError(Validations.validateEDD(l, date)),
                    readOnly: true,
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
              ] else if (state.isPregnant == 'No') ...[

                Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
              ],
            ],
          ],


          if (state.maritalStatus != null && state.maritalStatus != 'Unmarried') ...[
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
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
          ],
          ],

      ),
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
            DateTime? _parseDate(String? iso) =>
                (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

            // Extract years, months, days from stored approximate age string, e.g.
            // "35 years 2 months 10 days" -> ("35","2","10")
            String? _approxPart(String? approx, int index) {
              if (approx == null) return null;
              final s = approx.trim();
              if (s.isEmpty) return null;
              final matches = RegExp(r'\d+').allMatches(s).toList();
              if (matches.length <= index) return null;
              return matches[index].group(0);
            }

            final approx = m['approxAge'] as String?;
            final years = _approxPart(approx, 0);
            final months = _approxPart(approx, 1);
            final days = _approxPart(approx, 2);

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
                  approxAge: approx,
                  years: years,
                  months: months,
                  days: days,
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
                  householdRefKey: m['hh_unique_key'],
                  headUniqueKey: m['head_unique_key'],
                  spouseUniqueKey: m['spouse_unique_key'],
                ),
              ),
            );
          } else {
            // New insert: prefill village from the same source as AppDrawer
            // using secure storage user data. Fallback to legacy format if needed.
            SecureStorageService.getCurrentUserData().then((data) async {
              Map<String, dynamic>? user = data;
              if (user == null || user.isEmpty) {
                try {
                  final legacyRaw = await SecureStorageService.getUserData();
                  if (legacyRaw != null && legacyRaw.isNotEmpty) {
                    final parsed = jsonDecode(legacyRaw);
                    if (parsed is Map<String, dynamic>) {
                      user = parsed;
                    }
                  }
                } catch (_) {}
              }

              try {
                final working = user?['working_location'];
                if (working is Map) {
                  final village = (working['village'] ?? '').toString();
                  if (village.isNotEmpty) {
                    b.add(AfhUpdateVillage(village));
                    return;
                  }
                }
              } catch (_) {}

              // Fallback to DB user details when secure storage lacks data
              try {
                final dbUser = await UserInfo.getCurrentUser();
                final details = dbUser?['details'];
                if (details is Map<String, dynamic>) {
                  final data = details['data'];
                  if (data is Map<String, dynamic>) {
                    final working2 = data['working_location'];
                    if (working2 is Map<String, dynamic>) {
                      final village2 = (working2['village'] ?? '').toString();
                      if (village2.isNotEmpty) {
                        b.add(AfhUpdateVillage(village2));
                      }
                    }
                  }
                }
              } catch (_) {}
            });
          }
          return b;
        }),
        BlocProvider<SpousBloc>(create: (_) {
          final m = widget.initial;
          if (m == null || m.isEmpty) return SpousBloc();

          DateTime? _parseDate(String? iso) =>
              (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

          // Extract years, months, days from stored approximate age string, e.g.
          // "15 years 2 months 10 days" -> ("15","2","10")
          String? _approxPart(String? approx, int index) {
            if (approx == null) return null;
            final s = approx.trim();
            if (s.isEmpty) return null;
            final matches = RegExp(r'\d+').allMatches(s).toList();
            if (matches.length <= index) return null;
            return matches[index].group(0);
          }

          final approx = m['sp_approxAge'];
          final updateYears = _approxPart(approx, 0);
          final updateMonths = _approxPart(approx, 1);
          final updateDays = _approxPart(approx, 2);

          final spState = SpousState(
            relation: m['sp_relation'],
            memberName: m['sp_memberName'],
            ageAtMarriage: m['sp_ageAtMarriage'],
            RichIDChanged: m['sp_RichIDChanged'],
            spouseName: m['sp_spouseName'],
            fatherName: m['sp_fatherName'],
            useDob: m['sp_useDob'] == 'true' || m['sp_useDob'] == true,
            dob: _parseDate(m['sp_dob']),
            edd: _parseDate(m['sp_edd']),
            lmp: _parseDate(m['sp_lmp']),
            approxAge: approx,
            UpdateYears: updateYears,
            UpdateMonths: updateMonths,
            UpdateDays: updateDays,
            gender: m['sp_gender'],
            occupation: m['sp_occupation'],
            education: m['sp_education'],
            religion: m['sp_religion'],
            category: m['sp_category'],
            abhaAddress: m['sp_abhaAddress'],
            mobileOwner: m['sp_mobileOwner'],
            otherOccupation: m['sp_otherOccupation'],
            otherReligion: m['sp_otherReligion'],
            otherCategory: m['sp_otherCategory'],
            mobileOwnerOtherRelation: m['sp_mobileOwnerOtherRelation'],
            mobileNo: m['sp_mobileNo'],
            bankAcc: m['sp_bankAcc'],
            ifsc: m['sp_ifsc'],
            voterId: m['sp_voterId'],
            rationId: m['sp_rationId'],
            phId: m['sp_phId'],
            beneficiaryType: m['sp_beneficiaryType'],
            isPregnant: m['sp_isPregnant'],
            familyPlanningCounseling: m['sp_familyPlanningCounseling'],
            fpMethod: m['sp_fpMethod'],
            removalDate: _parseDate(m['sp_removalDate']),
            removalReason: m['sp_removalReason'],
            condomQuantity: m['sp_condomQuantity'],
            malaQuantity: m['sp_malaQuantity'],
            chhayaQuantity: m['sp_chhayaQuantity'],
            ecpQuantity: m['sp_ecpQuantity'],
          );

          return SpousBloc(initial: spState);
        }),
        BlocProvider<ChildrenBloc>(create: (_) {
          final m = widget.initial;
          if (m == null || m.isEmpty) return ChildrenBloc();

          int _parseInt(String? v) => int.tryParse(v ?? '') ?? 0;

          final chState = ChildrenState(
            totalBorn: _parseInt(m['totalBorn']),
            totalLive: _parseInt(m['totalLive']),
            totalMale: _parseInt(m['totalMale']),
            totalFemale: _parseInt(m['totalFemale']),
            youngestAge: m['youngestAge'],
            ageUnit: m['ageUnit'],
            youngestGender: m['youngestGender'],
          );

          return ChildrenBloc()..emit(chState);
        }),
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

              // Preserve technical keys from initial map (used for updates)
              if (widget.initial != null) {
                for (final key in [
                  'hh_unique_key',
                  'head_unique_key',
                  'spouse_unique_key',
                  'head_id_pk',
                  'spouse_id_pk',
                ]) {
                  if (widget.initial![key] != null && !result.containsKey(key)) {
                    result[key] = widget.initial![key];
                  }
                }
              }
              // Attach spouse and children details JSON if available
              try {
                final sp = context.read<SpousBloc>().state;
                result['spousedetails'] = sp.toJson();
                result['spouseUseDob'] = sp.useDob;
                result['spouseDob'] = sp.dob?.toIso8601String();
                result['spouseApproxAge'] = sp.approxAge;
              } catch (_) {}
              try {
                final ch = context.read<ChildrenBloc>().state;
                result['childrendetails'] = ch.toJson();
                // Also flatten children summary fields into the head form so
                // they are persisted in DB and available for future prefill.
                result['totalBorn'] = ch.totalBorn.toString();
                result['totalLive'] = ch.totalLive.toString();
                result['totalMale'] = ch.totalMale.toString();
                result['totalFemale'] = ch.totalFemale.toString();
                result['youngestAge'] = ch.youngestAge;
                result['ageUnit'] = ch.ageUnit;
                result['youngestGender'] = ch.youngestGender;
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
                      builder: (_) => BlocProvider<RegisterNewHouseholdBloc>(
                        create: (_) => RegisterNewHouseholdBloc(),
                        child: RegisterNewHouseHoldScreen(
                          initialMembers: members,
                          headAddedInit: true,

                          hideAddMemberButton: false,
                          isEdit: widget.isEdit,

                          showSuccessOnSave: false,
                          initialHeadForm: result,
                        ),
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
              icon1: Icons.close_rounded,
              onIcon1Tap: () async {
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
                        final tabs = [ Tab(text: l.familyHeadDetailsTitle)];
                        final views = <Widget>[
                          Form(key: _formKey, child: _buildFamilyHeadForm(context, state, l)),
                        ];

                        final showSpouse = state.maritalStatus == 'Married';
                        final showChildren = state.hasChildren == 'Yes';

                        if (showSpouse) {
                          final spBloc = context.read<SpousBloc>();
                          final current = spBloc.state;

                          final bool isSpouseStateEmpty =
                              (current.relation == null || current.relation!.trim().isEmpty) &&
                              (current.memberName == null || current.memberName!.trim().isEmpty) &&
                              (current.spouseName == null || current.spouseName!.trim().isEmpty) &&
                              current.dob == null &&
                              (current.UpdateYears == null || current.UpdateYears!.trim().isEmpty) &&
                              (current.UpdateMonths == null || current.UpdateMonths!.trim().isEmpty) &&
                              (current.UpdateDays == null || current.UpdateDays!.trim().isEmpty);

                          if (isSpouseStateEmpty) {
                            final g = (state.gender == 'Male')
                                ? 'Female'
                                : (state.gender == 'Female')
                                    ? 'Male'
                                    : null;
                            // Hydrate only minimal shared fields so spouse
                            // record stays independent from head record, and
                            // only when there is no existing DB state.
                            spBloc.add(SpHydrate(SpousState(
                              relation: 'Spouse',
                              memberName: state.spouseName,
                              ageAtMarriage: state.ageAtMarriage,
                              spouseName: state.headName,
                              gender: g,
                            )));
                          } else {
                            final headName = state.headName?.trim();
                            final spouseName = state.spouseName?.trim();
                            if ((current.memberName == null || current.memberName!.isEmpty) && (spouseName != null && spouseName.isNotEmpty)) {
                              spBloc.add(SpUpdateMemberName(spouseName));
                            }
                            if ((current.spouseName == null || current.spouseName!.isEmpty) && (headName != null && headName!.isNotEmpty)) {
                              spBloc.add(SpUpdateSpouseName(headName));
                            }
                          }
                          tabs.add( Tab(text: l.spousDetails));
                          views.add(
                            MultiBlocListener(
                              listeners: [
                                // Head -> Spouse: keep spouse tab prefilled
                                BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
                                  listenWhen: (prev, curr) =>
                                      prev.headName != curr.headName ||
                                      prev.spouseName != curr.spouseName,
                                  listener: (ctx, st) {
                                    if (_syncingNames) return;
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
                                ),
                                // Spouse -> Head: when names are edited on
                                // spouse tab, push them back to head form.
                                BlocListener<SpousBloc, SpousState>(
                                  listenWhen: (p, c) =>
                                      p.memberName != c.memberName ||
                                      p.spouseName != c.spouseName,
                                  listener: (ctx, sp) {
                                    if (_syncingNames) return;
                                    _syncingNames = true;
                                    try {
                                      final headBloc = ctx.read<AddFamilyHeadBloc>();
                                      final newSpouseName = (sp.memberName ?? '').trim();
                                      final newHeadName = (sp.spouseName ?? '').trim();

                                      if (newSpouseName.isNotEmpty &&
                                          (headBloc.state.spouseName ?? '').trim() != newSpouseName) {
                                        headBloc.add(AfhUpdateSpouseName(newSpouseName));
                                      }
                                      if (newHeadName.isNotEmpty &&
                                          (headBloc.state.headName ?? '').trim() != newHeadName) {
                                        headBloc.add(AfhUpdateHeadName(newHeadName));
                                      }
                                    } finally {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _syncingNames = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                              child: const Spousdetails(syncFromHead: true),
                            ),
                          );
                        }
                        if (showChildren) {
                          tabs.add( Tab(text: l.childrenDetailsTitle));
                          views.add(const Childrendetaills());
                        }

                        final int safeInitialIndex = widget.initialTab.clamp(0, tabs.length - 1);

                        return DefaultTabController(
                          key: ValueKey<int>(tabs.length),
                          length: tabs.length,
                          initialIndex: widget.initialTab.clamp(0, tabs.length - 1),
                          child: Column(
                            children: [
                              Container(
                                color: Theme.of(context).colorScheme.primary,
                                child: TabBar(
                                  isScrollable: true,
                                  labelColor: Theme.of(context).colorScheme.onPrimary,
                                  unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  indicatorColor: Theme.of(context).colorScheme.onPrimary,
                                  indicatorWeight: 3.0,
                                  tabs: tabs,
                                ),
                              ),
                              Expanded(
                                child: TabBarView(children: views),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h).copyWith(bottom: 2.h),
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
                                                  width: 25.5.w,
                                                  height: 4.5.h,
                                                  child: RoundButton(
                                                    title: isLoading
                                                        ? (widget.isEdit ? 'UPDATING...' : l.addingButton)
                                                        : (widget.isEdit ? 'UPDATE' : l.addButton),
                                                    color: AppColors.primary,
                                                    borderRadius: 4,
                                                    height: 4.5.h,
                                                    isLoading: isLoading,
                                                    onPress: () {
                                                      _clearFormError();
                                                      final formState = _formKey.currentState;
                                                      if (formState == null) return;
                                                      final isValid = formState.validate();
                                                      if (!isValid) {
                                                        if (_lastFormError != null) {
                                                          showAppSnackBar(context, _lastFormError!);
                                                        }
                                                        return;
                                                      }
                                                      context.read<AddFamilyHeadBloc>().add(AfhSubmit(context: context));
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
                                                      height: 4.5.h,
                                                      width: 25.5.w,
                                                      child: OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            minimumSize: Size(25.w, 4.5.h),
                                                            backgroundColor: AppColors.primary,
                                                            foregroundColor: Colors.white,
                                                            side: BorderSide(color: AppColors.primary, width: 0.2.w), // 👈 matching border
                                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(4), // rounded edges
                                                            ),
                                                            elevation: 0.5, // subtle elevation for depth
                                                            shadowColor: AppColors.primary.withOpacity(0.4),
                                                          ),
                                                          onPressed: () => controller.animateTo(i - 1),
                                                          child: Text(
                                                            l.previousButton,
                                                            style:  TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              letterSpacing: 0.5,
                                                              fontSize: 14.sp
                                                            ),
                                                          ),
                                                        )
                                                  )
                                                else
                                                  const SizedBox.shrink(),
                                                SizedBox(
                                                  height: 4.5.h,
                                                  width: 25.5.w,
                                                  child: RoundButton(
                                                    title: i < last
                                                        ? l.nextButton
                                                        : (isLoading
                                                            ? l.addingButton
                                                            : l.addButton),
                                                    onPress: () {
                                                      if (i < last) {
                                                        bool canProceed = true;
                                                        if (i == 0) {
                                                          _clearFormError();
                                                          final headForm = _formKey.currentState;
                                                          if (headForm == null || !headForm.validate()) {
                                                            canProceed = false;
                                                            final msg = _lastFormError ?? 'Please correct the highlighted errors before continuing.';
                                                            showAppSnackBar(context, msg);
                                                          }
                                                        } else if (i == 1) {
                                                          clearSpousFormError();
                                                          final spouseForm = spousFormKey.currentState;
                                                          if (spouseForm == null || !spouseForm.validate()) {
                                                            canProceed = false;
                                                            final msg = spousLastFormError ?? 'Please correct the highlighted errors before continuing.';
                                                            showAppSnackBar(context, msg);
                                                            }
                                                        }
                                                        if (!canProceed) return;
                                                        controller.animateTo(i + 1);
                                                      } else {

                                                        if (last == 1) {
                                                          clearSpousFormError();
                                                          final spouseForm = spousFormKey.currentState;
                                                          if (spouseForm == null || !spouseForm.validate()) {
                                                            final msg = spousLastFormError ??
                                                                'Please correct the highlighted errors before continuing.';
                                                            showAppSnackBar(context, msg);
                                                            return;
                                                            }
                                                        }

                                                        if (last == 2) {
                                                          // Children tab present, validate children details
                                                          try {
                                                            final ch = context.read<ChildrenBloc>().state;

                                                            if (ch.totalLive > 0 &&
                                                                (ch.totalMale + ch.totalFemale) !=
                                                                    ch.totalLive) {
                                                              showAppSnackBar(
                                                                  context, l.malePlusFemaleError);
                                                              return;
                                                            }

                                                            final youngestErr =
                                                                _validateYoungestChild(ch, l);
                                                            if (youngestErr != null) {
                                                              showAppSnackBar(context, youngestErr);
                                                              return;
                                                            }
                                                          } catch (_) {}
                                                          }

                                                        context
                                                            .read<AddFamilyHeadBloc>()
                                                            .add(AfhSubmit(context: context));
                                                      }
                                                    },
                                                    color: AppColors.primary,
                                                    borderRadius:4,
                                                    isLoading: isLoading,
                                                    fontSize: 14.sp,
                                                  ),
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
