import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/utils/Validations.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart';

import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/SpousDetails.dart'
    show
        spousFormKey,
        clearSpousFormError,
        spousLastFormError,
        scrollToFirstError,
        Spousdetails,
        validateAllSpousFields;

import '../../../../data/Database/User_Info.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';
import '../../../../data/repositories/RegisterNewHouseHoldController/register_new_house_hold.dart';
import '../Children_Details/ChildrenDetaills.dart';
import '../Children_Details/bloc/children_bloc.dart';
import '../SpousDetails/bloc/spous_bloc.dart';
import 'bloc/add_family_head_bloc.dart';

import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/utils/enums.dart';
import 'package:medixcel_new/core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/RegisterNewHouseHold/bloc/registernewhousehold_bloc.dart';
import 'package:sizer/sizer.dart';
class MaxValueFormatter extends TextInputFormatter {
  final int max;

  MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null || value > max) {
      return oldValue;
    }
    return newValue;
  }
}

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
  final _formKey = GlobalKey<FormState>();
  final now = DateTime.now();

  bool _syncingNames = false;

  static String? _lastFormError;

  static void _clearFormError() {
    _lastFormError = null;
  }

  static String? _captureError(String? message) {
    debugPrint(
      '_captureError called with: $message (${DateTime.now().toIso8601String()})',
    );
    if (message != null && message.isNotEmpty) {
      debugPrint('❌ Validation Error: $message');
      // Only update if we don't have an error yet
      if (_lastFormError == null) {
        _lastFormError = message;
        debugPrint('📌 Setting first validation error: $message');
      } else {
        debugPrint(
          'ℹ️ Not updating error message, already have: $_lastFormError',
        );
      }
      return message;
    }
    debugPrint('✅ Validation passed for field');
    // Don't clear _lastFormError here to preserve the first error
    return null;
  }

  // Helper to find and scroll to the first error field in head form
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorField = _findFirstErrorField();
      if (errorField != null) {
        Scrollable.ensureVisible(
          errorField.context,
          alignment: 0.1,
          duration: Duration(milliseconds: 300),
        );
      }
    });
  }

  void _handleAbhaProfileResult(
    Map<String, dynamic> profile,
    BuildContext context,
  ) {
    debugPrint("Filling ABHA data into form...");

    final bloc = context.read<AddFamilyHeadBloc>();

    // ABHA Address
    final abha = profile['abhaAddress']?.toString().trim();
    if (abha != null && abha.isNotEmpty) {
      bloc.add(AfhABHAChange(abha));
    }

    // Full Name
    final nameParts = [
      profile['firstName'],
      profile['middleName'],
      profile['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
    if (nameParts.isNotEmpty) {
      bloc.add(AfhUpdateHeadName(nameParts.trim()));
    }

    // DOB
    try {
      final day = profile['dayOfBirth']?.toString();
      final month = profile['monthOfBirth']?.toString();
      final year = profile['yearOfBirth']?.toString();
      if (day != null && month != null && year != null) {
        final dob = DateTime(int.parse(year), int.parse(month), int.parse(day));
        bloc.add(AfhToggleUseDob());
        bloc.add(AfhUpdateDob(dob));
      }
    } catch (e) {
      debugPrint("DOB parse error: $e");
    }

    // Gender
    final g = profile['gender']?.toString().toUpperCase();
    String? gender;
    if (g == 'M') gender = 'Male';
    if (g == 'F') gender = 'Female';
    if (g == 'O' || g == 'T') gender = 'Transgender';
    if (gender != null) bloc.add(AfhUpdateGender(gender));

    // Mobile
    final mobile = profile['mobile']?.toString().trim();
    if (mobile != null && mobile.length == 10) {
      bloc.add(AfhUpdateMobileNo(mobile));
      bloc.add(AfhUpdateMobileOwner('Self'));
    }

    showAppSnackBar(context, "ABHA details filled successfully!");
  }

  // Helper method to find the first field with an error in head form
  FormFieldState<dynamic>? _findFirstErrorField() {
    FormFieldState<dynamic>? firstErrorField;

    void visitElement(Element element) {
      if (firstErrorField != null) return;

      if (element.widget is FormField) {
        final formField = element as StatefulElement;
        final field = formField.state as FormFieldState<dynamic>?;

        if (field?.hasError == true) {
          firstErrorField = field;
          return;
        }
      }

      element.visitChildren(visitElement);
    }

    // First check in the current form
    final form = _formKey.currentState;
    if (form != null && form.context != null) {
      form.context.visitChildElements(visitElement);
    }

    // If no error found in main form, check in spouse form if it exists
    if (firstErrorField == null && spousFormKey.currentState?.context != null) {
      spousFormKey.currentState!.context.visitChildElements(visitElement);
    }

    return firstErrorField;
  }

  int _ageFromDob(DateTime dob) {
    return DateTime.now().year - dob.year;
  }
  bool useDob = true;

  DateTime? dob;

  final TextEditingController yearsCtrl = TextEditingController();
  final TextEditingController monthsCtrl = TextEditingController();
  final TextEditingController daysCtrl = TextEditingController();

  String? _validateYoungestChild(ChildrenState s, AppLocalizations l) {
    // Check if age unit is selected but age is empty
    if ((s.ageUnit != null && s.ageUnit!.isNotEmpty) &&
        (s.youngestAge == null || s.youngestAge!.trim().isEmpty)) {
      return 'Please enter age of youngest child';
    }

    // Existing validation for age ranges
    return Validations.validateYoungestChildAge(l, s.youngestAge, s.ageUnit);
  }

  String? _validateYoungestGender(ChildrenState s, AppLocalizations l) {
    if (s.youngestGender == 'Male' && s.totalMale == 0) {
      return l.invalidGenderMaleZero;
    }
    if (s.youngestGender == 'Female' && s.totalFemale == 0) {
      return l.invalidGenderFemaleZero;
    }
    return null;
  }

  Widget _Section({required Widget child}) {
    return child;
  }

  final RegisterNewHouseHold repository = RegisterNewHouseHold();

  Future<Map<String, dynamic>?> fetchRCHDataForScreen(
    int rchId, {
    required int requestFor,
  }) async {
    try {
      print('Calling API: getRCHData(rchId: $rchId, requestFor: $requestFor)');

      final result = await repository.getRCHData(
        requestFor: requestFor,
        rchId: rchId,
      );

      print('RCH API Raw Response: $result');

      return result;
    } catch (e) {
      print('RCH API Exception: $e');
      return null;
    }
  }

  List<String> _getMobileOwnerList(String gender) {
    const common = [];

    gender = gender.toLowerCase();

    if (gender == 'female') {
      return [
        'Self',
        'Husband',
        'Father',
        'Mother',
        'Son',
        'Daughter',
        'Father In Law',
        'Mother In Law',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    if (gender == 'male') {
      return [
        'Self',
        'Wife',
        'Father',
        'Mother',
        'Son',
        'Daughter',
        'Father In Law',
        'Mother In Law',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    if (gender == 'transgender') {
      return [
        'Self',
        'Husband',
        'Wife',
        'Father',
        'Mother',
        'Son',
        'Daughter',
        'Father In Law',
        'Mother In Law',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    // Fallback if gender is unknown
    return [
      'Self',
      'Husband',
      'Wife',
      'Father',
      'Mother',
      'Son',
      'Daughter',
      'Father In Law',
      'Mother In Law',
      'Neighbour',
      'Relative',
      'Other',
      ...common,
    ];
  }
  void updateDobFromAge() {
    final now = DateTime.now();
    final y = int.tryParse(yearsCtrl.text) ?? 0;
    final m = int.tryParse(monthsCtrl.text) ?? 0;
    final d = int.tryParse(daysCtrl.text) ?? 0;

    setState(() {
      dob = DateTime(
        now.year - y,
        now.month - m,
        now.day - d,
      );
    });
  }

  void updateAgeFromDob(DateTime date) {
    final now = DateTime.now();

    int years = now.year - date.year;
    int months = now.month - date.month;
    int days = now.day - date.day;

    if (days < 0) {
      months--;
      days += 30;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    yearsCtrl.text = years.toString();
    monthsCtrl.text = months.toString();
    daysCtrl.text = days.toString();
  }
  Widget _buildFamilyHeadForm(
    BuildContext context,
    AddFamilyHeadState state,
    AppLocalizations l,
  ) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,

      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 1.5.h),
        child: Column(
          children: [
            _Section(
              child: CustomTextField(
                labelText: '${l.houseNoHint} *',
                hintText: l.houseNoHint,
                initialValue: state.houseNo,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateHouseNo(v.trim()),
                ),
                validator: (value) =>
                    _captureError(Validations.validateHouseNo(l, value)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: '${l.nameOfFamilyHeadLabel} *',
                hintText: l.nameOfFamilyHeadHint,
                initialValue: state.headName,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateHeadName(v.trim()),
                ),
                validator: (value) =>
                    _captureError(Validations.validateFamilyHead(l, value)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.fatherNameLabel,
                hintText: l.fatherNameLabel,
                initialValue: state.fatherName,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateFatherName(v.trim()),
                ),
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
                    onChanged: widget.isEdit
                        ? null
                        : (_) => context.read<AddFamilyHeadBloc>().add(
                            AfhToggleUseDob(),
                          ),
                  ),
                  Text(l.dobShort, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 2.w),
                  Radio<bool>(
                    value: false,
                    groupValue: state.useDob,
                    onChanged: widget.isEdit
                        ? null
                        : (_) => context.read<AddFamilyHeadBloc>().add(
                            AfhToggleUseDob(),
                          ),
                  ),
                  Text(l.ageApproximate, style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
            if (state.useDob)
              _Section(
                child: CustomDatePicker(
                  labelText: '${l.dobLabel} *',
                  hintText: l.dateHint,
                  initialDate: dob,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 110)),
                  lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
                  onDateChanged: (date) {
                    if (date != null) {
                      setState(() {
                        dob = date;
                      });
                      updateAgeFromDob(date);
                    }
                  },
                )
              )
            else
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 1.h, left: 1.3.h),
                      child: RichText(
                        text: TextSpan(
                          text: "${l.ageApproximate}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(
                                color: Colors.red, // Make asterisk red
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // YEARS
                        Expanded(
                          child: CustomTextField(
                            controller: yearsCtrl,
                            labelText: l.years,
                            hintText: l.years,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              MaxValueFormatter(110),
                            ],
                            onChanged: (_) => updateDobFromAge(),
                          ),
                        ),

                        // MONTHS
                        Expanded(
                          child: CustomTextField(
                            controller: monthsCtrl,
                            labelText: l.months,
                            hintText: l.months,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              MaxValueFormatter(11),
                            ],
                            onChanged: (_) => updateDobFromAge(),
                          ),
                        ),

                        // DAYS
                        Expanded(
                          child: CustomTextField(
                            controller: daysCtrl,
                            labelText: l.days,
                            hintText: l.days,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              MaxValueFormatter(30),
                            ],
                            onChanged: (_) => updateDobFromAge(),
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: IgnorePointer(
                ignoring: widget.isEdit,
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
                  onChanged: widget.isEdit
                      ? null
                      : (v) => context.read<AddFamilyHeadBloc>().add(
                          AfhUpdateGender(v),
                        ),
                  validator: (v) =>
                      _captureError(v == null ? l.genderRequired : null),
                ),
              ),
            ),

            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: IgnorePointer(
                ignoring: widget.isEdit,
                child: ApiDropdown<String>(
                  labelText: l.occupationLabel,
                  items: const [
                    'Unemployed',
                    'Housewife',
                    'Daily Wage Labor',
                    'Agriculture',
                    'Salaried',
                    'Business',
                    'Retired',
                    'Other',
                  ],
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
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateOccupation(v),
                  ),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            if (state.occupation == 'Other')
              _Section(
                child: CustomTextField(
                  labelText: l.enterOccupationOther,
                  hintText: l.enterOccupationOther,
                  initialValue: state.otherOccupation,
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateOtherOccupation(v.trim()),
                  ),
                ),
              ),
            if (state.occupation == 'Other')
              Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: ApiDropdown<String>(
                labelText: l.educationLabel,
                items: const [
                  'No Schooling',
                  'Primary',
                  'Secondary',
                  'High School',
                  'Intermediate',
                  'Diploma',
                  'Graduate and above',
                ],
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
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateEducation(v),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: ApiDropdown<String>(
                labelText: l.religionLabel,
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
                onChanged: (v) =>
                    context.read<AddFamilyHeadBloc>().add(AfhUpdateReligion(v)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            if (state.religion == 'Other')
              _Section(
                child: CustomTextField(
                  labelText: l.enter_religion,
                  hintText: l.enter_religion,
                  initialValue: state.otherReligion,
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateOtherReligion(v.trim()),
                  ),
                ),
              ),
            if (state.religion == 'Other')
              Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: ApiDropdown<String>(
                labelText: l.categoryLabel,
                items: const [
                  'Not Disclosed',
                  'General',
                  'OBC',
                  'SC',
                  'ST',
                  'Pichda Varg 1',
                  'Pichda Varg 2',
                  'Atyant Pichda Varg',
                  'Do not Know',
                  'Other',
                ],
                getLabel: (s) {
                  switch (s) {
                    case 'Not Disclosed':
                      return l.categoryNotDisclosed;
                    case 'General':
                      return l.categoryGeneral;
                    case 'OBC':
                      return l.categoryOBC;
                    case 'SC':
                      return l.categorySC;
                    case 'ST':
                      return l.categoryST;
                    case 'Pichda Varg 1':
                      return l.categoryPichdaVarg1;
                    case 'Pichda Varg 2':
                      return l.categoryPichdaVarg2;
                    case 'Atyant Pichda Varg':
                      return l.categoryAtyantPichdaVarg;
                    case 'Do not Know':
                      return l.categoryDontKnow;
                    case 'Other':
                      return l.religionOther;
                    default:
                      return s;
                  }
                },
                value: state.category,
                onChanged: (v) =>
                    context.read<AddFamilyHeadBloc>().add(AfhUpdateCategory(v)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            if (state.category == 'Other')
              _Section(
                child: CustomTextField(
                  labelText: l.enterCategory,
                  hintText: l.enterCategory,
                  initialValue: state.otherCategory,
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateOtherCategory(v.trim()),
                  ),
                ),
              ),
            if (state.category == 'Other')
              Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
            _Section(
              child: IgnorePointer(
                ignoring: widget.isEdit,

                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        labelText: l.abhaAddressLabel,
                        hintText: l.abhaAddressLabel,
                        initialValue: state.AfhABHAChange,
                        onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                          AfhABHAChange(v.trim()),
                        ),
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
                        onPress: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            Route_Names.Abhalinkscreen,
                          );

                          if (result is Map<String, dynamic>) {
                            if (!mounted) return;
                            _handleAbhaProfileResult(
                              result,
                              context,
                            ); // pass context safely
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
            if (state.gender == 'Female') ...[
              _Section(
                child: IgnorePointer(
                  ignoring: widget.isEdit,

                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: l.rchIdLabel,
                          hintText: l.enter_12_digit_rch_id,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],

                          onChanged: (v) {
                            ScaffoldMessenger.of(
                              context,
                            ).removeCurrentSnackBar();

                            // Filter out non-digit characters (for copy-paste scenarios)
                            final filteredValue = v.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final value = filteredValue.trim();

                            context.read<AddFamilyHeadBloc>().add(
                              AfhRichIdChange(value),
                            );

                            if (value.isNotEmpty && value.length != 12) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  showAppSnackBar(
                                    context,
                                    l.rch_id_must_be_12_digits,
                                  );
                                }
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Field is optional
                            }
                            if (value.length != 12) {
                              return l.rch_id_must_be_12_digits;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 3.h,
                        width: 15.h,
                        child: RoundButton(
                          title: l.verify,
                          width: 40.w,
                          borderRadius: 1.h,
                          fontSize: 14.sp,
                          disabled: !state.isRchIdButtonEnabled,
                          onPress: () async {
                            // Remove previous
                            ScaffoldMessenger.of(
                              context,
                            ).removeCurrentSnackBar();

                            final rchId = state?.AfhRichIdChange?.trim() ?? "";

                            // Validate
                            if (rchId.isEmpty) {
                              showAppSnackBar(
                                context,
                                l.please_enter_rch_id_first,
                              );
                              return;
                            }

                            if (rchId.length != 12) {
                              showAppSnackBar(
                                context,
                                l.rch_id_must_be_12_digits,
                              );
                              return;
                            }

                            final response = await fetchRCHDataForScreen(
                              int.parse(rchId),
                              requestFor: 1, // FEMALE
                            );

                            print("API Response → $response");

                            if (response == null) {
                              showAppSnackBar(
                                context,
                                l.failedTo_fetch_rch_data,
                              );
                            } else {
                              showAppSnackBar(
                                context,
                                l.rchVerifiedSuccessfully,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
            ],

            _Section(
              child: _Section(
                child: ApiDropdown<String>(
                  labelText: '${l.whoseMobileLabel} *',
                  items: _getMobileOwnerList(state.gender ?? ''),
                  getLabel: (s) {
                    switch (s) {
                      case 'Self':
                        return "${l.self}";

                      case 'Husband':
                        return '${l.husbandLabel} ';

                      case 'Mother':
                        return '${l.mother} ';

                      case 'Father':
                        return '${l.father}';

                      case 'Wife':
                        return '${l.wife} ';

                      case 'Son':
                        return '${l.son}';

                      case 'Daughter':
                        return '${l.daughter} ';

                      case 'Mother In Law':
                        return '${l.motherInLaw} ';

                      case 'Father In Law':
                        return '${l.fatherInLaw}';

                      case 'Neighbour':
                        return '${l.neighbour} ';

                      case 'Relative':
                        return "${l.relative} ";

                      case 'Other':
                        return '${l.otherDropdown} ';

                      default:
                        return s;
                    }
                  },

                  value: state.mobileOwner,
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateMobileOwner(v),
                  ),
                  validator: (value) =>
                      _captureError(Validations.validateWhoMobileNo(l, value)),
                ),
              ),
            ),

            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            if (state.mobileOwner == 'Other')
              _Section(
                child: CustomTextField(
                  labelText: '${l.relationWithMobileHolder} *',
                  hintText: l.relationWithMobileHolder,
                  initialValue: state.mobileOwnerOtherRelation,
                  onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                    AfhUpdateMobileOwnerOtherRelation(v.trim()),
                  ),
                  validator: (value) => state.mobileOwner == 'Other'
                      ? _captureError(
                          (value == null || value.trim().isEmpty)
                              ? l.relation_with_mobile_holder_required
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
                hintText: '${l.mobileLabel}',
                keyboardType: TextInputType.number,
                maxLength: 10,
                initialValue: state.mobileNo,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateMobileNo(v.trim()),
                ),
                validator: (value) =>
                    _captureError(Validations.validateMobileNo(l, value)),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.villageNameLabel,
                hintText: l.villageNameLabel,
                initialValue: state.village,
                readOnly: !widget.isEdit,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateVillage(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.wardNoLabel,
                hintText: l.wardNoLabel,
                initialValue: state.wardNo,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateWard(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
            _Section(
              child: CustomTextField(
                labelText: l.wardName,
                hintText: l.wardName,
                initialValue: state.ward,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateWardName(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.mohallaTolaNameLabel,
                hintText: l.mohallaTolaNameLabel,
                initialValue: state.mohalla,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateMohalla(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            BlocBuilder<AddFamilyHeadBloc, AddFamilyHeadState>(
              buildWhen: (previous, current) =>
                  previous.bankAcc != current.bankAcc,
              builder: (contxt, state) {
                final bankAcc = state.bankAcc ?? '';
                final isValid =
                    bankAcc.isEmpty ||
                    bankAcc.replaceAll(RegExp(r'[^0-9]'), '').length >= 10;

                return Column(
                  children: [
                    _Section(
                      child: CustomTextField(
                        labelText: l.bankAccountNumber,
                        hintText: l.bankAccountNumber,
                        keyboardType: TextInputType.number,
                        initialValue: state.bankAcc,
                        onChanged: (v) {
                          final value = v.trim();
                          context.read<AddFamilyHeadBloc>().add(
                            AfhUpdateBankAcc(value),
                          );
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // Field is optional
                          }

                          final digitsOnly = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );

                          if (digitsOnly.length < 11 ||
                              digitsOnly.length > 18) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                showAppSnackBar(
                                  context,
                                  l.bank_account_length_error,
                                );
                              }
                            });
                            return 'Invalid length';
                          }

                          return null;
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(18),
                        ],
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
                hintText: l.ifscLabel,
                maxLength: 11,
                initialValue: state.ifsc,
                onChanged: (v) {
                  final value = v.trim().toUpperCase();
                  context.read<AddFamilyHeadBloc>().add(AfhUpdateIfsc(value));
                  // Clear previous snackbar
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Field is optional
                  }

                  String? error;
                  if (value.length != 11) {
                    error = l.validIfscCode;
                  } else if (!RegExp(r'^[A-Z]{4}0\d{6}$').hasMatch(value)) {
                    error = '${l.validIfscCode}';
                  }

                  if (error != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        showAppSnackBar(context, error!);
                      }
                    });
                  }

                  return error;
                },
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.voterIdLabel,
                hintText: l.voterIdLabel,
                initialValue: state.voterId,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateVoterId(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.rationCardIdLabel,
                hintText: l.rationCardIdLabel,
                initialValue: state.rationId,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateRationId(v.trim()),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: CustomTextField(
                labelText: l.personalHealthIdLabel,
                hintText: l.personalHealthIdLabel,
                initialValue: state.phId,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdatePhId(v.trim()),
                ),
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
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateBeneficiaryType(v),
                ),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            _Section(
              child: ApiDropdown<String>(
                labelText: '${l.maritalStatusLabel} *',
                items: const [
                  'Unmarried',
                  'Married',
                  'Divorced',
                  'Separated',
                  'Widow',
                  'Widower',
                ],
                getLabel: (s) {
                  switch (s) {
                    case 'Married':
                      return l.maritalStatusMarried;
                    case 'Unmarried':
                      return l.maritalStatusUnmarried;
                    case 'Widow':
                      return l.maritalStatusWidowed;
                    case 'Widower':
                      return l.maritalStatusWidower;
                    case 'Separated':
                      return l.separatedMarried;
                    case 'Divorced':
                      return l.maritalStatusDivorced;
                    default:
                      return s;
                  }
                },
                value: state.maritalStatus,
                onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                  AfhUpdateMaritalStatus(v),
                ),
                validator: (value) =>
                    _captureError(Validations.validateMaritalStatus(l, value)),
              ),
            ),
            Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

            if (widget.isEdit == false) ...[
              if (state.maritalStatus == 'Married') ...[
                _Section(
                  child: CustomTextField(
                    labelText: l.ageAtMarriageLabel,
                    hintText: l.ageAtMarriageLabel,
                    keyboardType: TextInputType.number,
                    initialValue: state.ageAtMarriage,
                    onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                      AfhUpdateAgeAtMarriage(v.trim()),
                    ),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),

                _Section(
                  child: CustomTextField(
                    labelText: '${l.spouseNameLabel} *',
                    hintText: l.spouseNameLabel,
                    initialValue: state.spouseName,
                    onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                      AfhUpdateSpouseName(v.trim()),
                    ),
                    validator: (value) =>
                        _captureError(Validations.validateSpousName(l, value)),
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
                        if (state.gender == 'Female' &&
                            state.maritalStatus == 'Married') {
                          return _captureError(
                            Validations.validateIsPregnant(l, value),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  Divider(
                    color: AppColors.divider,
                    thickness: 0.1.h,
                    height: 0,
                  ),

                  Divider(
                    color: AppColors.divider,
                    thickness: 0.1.h,
                    height: 0,
                  ),
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
                            final edd = d.add(const Duration(days: 277));
                            bloc.add(EDDChange(edd));
                          } else {
                            bloc.add(EDDChange(null));
                          }
                        },
                        validator: (date) =>
                            _captureError(Validations.validateLMP(l, date)),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 276),
                        ),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 31),
                        ),
                      ),
                    ),
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.1.h,
                      height: 0,
                    ),

                    _Section(
                      child: CustomDatePicker(
                        labelText: '${l.eddDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.edd,
                        onDateChanged: (d) =>
                            context.read<AddFamilyHeadBloc>().add(EDDChange(d)),
                        validator: (date) =>
                            _captureError(Validations.validateEDD(l, date)),
                        readOnly: true,
                      ),
                    ),
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.1.h,
                      height: 0,
                    ),
                  ] else if (state.isPregnant == 'No') ...[
                    _Section(
                      child: ApiDropdown<String>(
                        labelText: '${l.fpAdoptingLabel} *',
                        items: const ['Yes', 'No'],
                        getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                        value: state.hpfamilyPlanningCounseling,
                        onChanged: (v) {
                          context.read<AddFamilyHeadBloc>().add(
                            HeadFamilyPlanningCounselingChanged(v!),
                          );
                        },
                        validator: (value) => _captureError(
                          Validations.validateAdoptingPlan(l, value),
                        ),
                      ),
                    ),
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.1.h,
                      height: 0,
                    ),

                    if (state.hpfamilyPlanningCounseling == 'Yes') ...[
                      _Section(
                        child: ApiDropdown<String>(
                          labelText: '${l.methodOfContra} *',
                          items: const [
                            'Condom',
                            'Mala -N (Daily Contraceptive pill)',
                            'Antra injection',
                            'Copper -T (IUCD)',
                            'Chhaya (Weekly Contraceptive pill)',
                            'ECP (Emergency Contraceptive pill)',
                            'Male Sterilization',
                            'Female Sterilization',
                            'Any Other Specify',
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'Condom':
                                return l.condom;

                              case 'Mala -N (Daily Contraceptive pill)':
                                return l.malaN;

                              case 'Antra injection':
                                return l.atraInjection;

                              case 'Copper -T (IUCD)':
                                return l.copperT;

                              case 'Chhaya (Weekly Contraceptive pill)':
                                return l.chhaya;

                              case 'ECP (Emergency Contraceptive pill)':
                                return l.ecp;

                              case 'Male Sterilization':
                                return l.maleSterilization;

                              case 'Female Sterilization':
                                return l.femaleSterilization;

                              case 'Any Other Specify':
                                return l.anyOtherSpecifyy;
                              default:
                                return s;
                            }
                          },
                          value: state.hpMethod,
                          onChanged: (v) {
                            if (v != null) {
                              context.read<AddFamilyHeadBloc>().add(
                                hpMethodChanged(v),
                              );
                            }
                          },
                          validator: (value) => _captureError(
                            Validations.validateAntra(l, value),
                          ),
                        ),
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.1.h,
                        height: 0,
                      ),

                      if (state.hpMethod == 'Antra injection') ...[
                        _Section(
                          child: CustomDatePicker(
                            labelText: l.dateOfAntra,
                            initialDate: state.hpantraDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            onDateChanged: (date) {
                              if (date != null) {
                                context.read<AddFamilyHeadBloc>().add(
                                  hpDateofAntraChanged(date),
                                );
                              }
                            },
                          ),
                        ),
                        Divider(
                          color: AppColors.divider,
                          thickness: 0.1.h,
                          height: 0,
                        ),
                      ],

                      if (state.hpMethod == 'Copper -T (IUCD)') ...[
                        _Section(
                          child: CustomDatePicker(
                            labelText: l.removalDate,
                            initialDate: state.hpremovalDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            onDateChanged: (date) {
                              if (date != null) {
                                context.read<AddFamilyHeadBloc>().add(
                                  hpRemovalDateChanged(date),
                                );
                              }
                            },
                          ),
                        ),
                        Divider(
                          color: AppColors.divider,
                          thickness: 0.1.h,
                          height: 0,
                        ),

                        _Section(
                          child: CustomTextField(
                            labelText: l.reasonForRemoval,
                            hintText: l.reasonForRemoval,
                            initialValue: state.hpremovalReason,
                            onChanged: (value) {
                              context.read<AddFamilyHeadBloc>().add(
                                hpRemovalReasonChanged(value ?? ''),
                              );
                            },
                          ),
                        ),
                        Divider(
                          color: AppColors.divider,
                          thickness: 0.1.h,
                          height: 0,
                        ),
                      ],

                      if (state.hpMethod == 'Condom') ...[
                        _Section(
                          child: CustomTextField(
                            labelText: l.quantityOfCondoms,
                            hintText: l.quantityOfCondoms,
                            keyboardType: TextInputType.number,
                            initialValue: state.hpcondomQuantity,
                            onChanged: (value) {
                              context.read<AddFamilyHeadBloc>().add(
                                hpCondomQuantityChanged(value ?? ''),
                              );
                            },
                          ),
                        ),
                        Divider(
                          color: AppColors.divider,
                          thickness: 0.1.h,
                          height: 0,
                        ),
                      ],
                    ],
                  ],
                ],
              ],
              if (state.maritalStatus != null &&
                  state.maritalStatus != 'Unmarried') ...[
                _Section(
                  child: ApiDropdown<String>(
                    labelText: l.haveChildrenQuestion,
                    items: const ['Yes', 'No'],
                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                    value: state.hasChildren,
                    onChanged: (v) => context.read<AddFamilyHeadBloc>().add(
                      AfhUpdateHasChildren(v),
                    ),
                  ),
                ),
                Divider(color: AppColors.divider, thickness: 0.1.h, height: 0),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String? _normalizeGender(String? gender) {
    if (gender == null || gender.isEmpty) return null;

    final normalized = gender.toLowerCase().trim();
    switch (normalized) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'transgender':
        return 'Transgender';
      default:
        return gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return MultiBlocProvider(
      providers: [
        BlocProvider<AddFamilyHeadBloc>(
          create: (_) {
            final b = AddFamilyHeadBloc();
            final m = widget.initial;
            if (m != null && m.isNotEmpty) {
              DateTime? _parseDate(String? iso) =>
                  (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

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
                    gender: _normalizeGender(m['gender']),
                    occupation: m['occupation'] == 'Other'
                        ? 'Other'
                        : m['occupation'],
                    otherOccupation: m['occupation'] == 'Other'
                        ? m['other_occupation']
                        : null,
                    education: m['education'],
                    religion: m['religion'] == 'Other'
                        ? 'Other'
                        : m['religion'],
                    otherReligion: m['religion'] == 'Other'
                        ? m['other_religion']
                        : null,
                    category: m['category'] == 'Other'
                        ? 'Other'
                        : m['category'],
                    otherCategory: m['category'] == 'Other'
                        ? m['other_category']
                        : null,
                    mobileOwner: m['mobileOwner'],
                    mobileOwnerOtherRelation:
                        m['mobile_owner_relation'] == 'Other'
                        ? m['mobile_owner_relation']
                        : m['mobile_owner_relation'],
                    mobileNo: m['mobileNo'],
                    village: m['village'],
                    ward: m['ward'],
                    mohalla: m['mohalla'],
                    bankAcc:
                        m['bankAcc'] ??
                        m['bankAccountNumber'] ??
                        m['account_number'] ??
                        m['bank_account_number'],
                    ifsc: m['ifsc'] ?? m['ifscCode'] ?? m['ifsc_code'],
                    voterId: m['voterId'] ?? m['voter_id'],
                    rationId:
                        m['rationId'] ??
                        m['rationCardId'] ??
                        m['ration_card_id'] ??
                        m['ration_card_number'],
                    phId:
                        m['phId'] ??
                        m['personalHealthId'] ??
                        m['personal_health_id'] ??
                        m['health_id'],
                    beneficiaryType:
                        m['beneficiaryType'] ??
                        m['type_of_beneficiary'] ??
                        m['ben_type'],
                    maritalStatus: m['maritalStatus'],
                    ageAtMarriage: m['ageAtMarriage'],
                    spouseName:
                        (m['spouseName'] != null &&
                            m['spouseName'].toString().trim().isNotEmpty)
                        ? m['spouseName']
                        : null,
                    AfhRichIdChange: m['AfhRichIdChange'],
                    hasChildren: m['hasChildren'],
                    isPregnant: m['isPregnant'],
                    householdRefKey: m['hh_unique_key'],
                    headUniqueKey: m['head_unique_key'],
                    spouseUniqueKey: m['spouse_unique_key'],
                    hpfamilyPlanningCounseling: m['hpfamilyPlanningCounseling'],
                    hpMethod: m['hpMethod'],
                    hpantraDate: _parseDate(m['hpantraDate'] as String?),
                    hpremovalDate: _parseDate(m['hpremovalDate'] as String?),
                    hpremovalReason: m['hpremovalReason'],
                    hpcondomQuantity: m['hpcondomQuantity'],
                  ),
                ),
              );
            } else {
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
          },
        ),
        BlocProvider<SpousBloc>(
          create: (_) {
            final m = widget.initial;
            if (m == null || m.isEmpty) return SpousBloc();

            // Use specific accessors to prevent leaking Head data into Spouse form
            dynamic getSpouseVal(String key) {
              // Try with sp_ prefix first
              if (m.containsKey('sp_$key')) return m['sp_$key'];

              // Try alternative keys if specific fields
              if (key == 'bankAcc') {
                return m['sp_bankAccountNumber'] ??
                    m['sp_account_number'] ??
                    m['sp_bank_account_number'];
              }
              if (key == 'ifsc') {
                return m['sp_ifscCode'] ?? m['sp_ifsc_code'];
              }
              if (key == 'rationId') {
                return m['sp_rationCardId'] ??
                    m['sp_ration_card_id'] ??
                    m['sp_ration_card_number'];
              }
              if (key == 'phId') {
                return m['sp_personalHealthId'] ??
                    m['sp_personal_health_id'] ??
                    m['sp_health_id'];
              }
              if (key == 'beneficiaryType') {
                return m['sp_type_of_beneficiary'] ?? m['sp_ben_type'];
              }

              return m['sp_$key'];
            }

            dynamic getHeadVal(String key) => m[key];

            DateTime? _parseDate(String? iso) =>
                (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

            String? _approxPart(String? approx, int index) {
              if (approx == null) return null;
              final s = approx.trim();
              if (s.isEmpty) return null;
              final matches = RegExp(r'\d+').allMatches(s).toList();
              if (matches.length <= index) return null;
              return matches[index].group(0);
            }

            final approx = getSpouseVal('approxAge');
            final updateYears = _approxPart(approx, 0);
            final updateMonths = _approxPart(approx, 1);
            final updateDays = _approxPart(approx, 2);

            final occupation = getSpouseVal('occupation');
            final otherOccupation = getSpouseVal('other_occupation');
            final religion = getSpouseVal('religion');
            final otherReligion = getSpouseVal('other_religion');
            final category = getSpouseVal('category');
            final otherCategory = getSpouseVal('other_category');
            final mobileOwner = getSpouseVal('mobileOwner');
            final mobileOwnerOtherRelation = getSpouseVal(
              'mobile_owner_relation',
            );

            final familyPlanningCounseling = getSpouseVal(
              'familyPlanningCounseling',
            );
            final fpMethod = getSpouseVal('fpMethod');
            final removalDate = getSpouseVal('removalDate');
            final removalReason = getSpouseVal('removalReason');
            final condomQuantity = getSpouseVal('condomQuantity');
            final malaQuantity = getSpouseVal('malaQuantity');
            final chhayaQuantity = getSpouseVal('chhayaQuantity');
            final ecpQuantity = getSpouseVal('ecpQuantity');
            final antraDate = getSpouseVal('antraDate');

            final spState = SpousState(
              relation: getSpouseVal('relation') ?? 'spouse',
              memberName:
                  getSpouseVal('memberName') ?? getHeadVal('spouseName'),
              ageAtMarriage: getSpouseVal('ageAtMarriage'),
              RichIDChanged: getSpouseVal('RichIDChanged'),
              spouseName:
                  getSpouseVal('spouseName') ??
                  getHeadVal('headName') ??
                  getHeadVal('memberName'),
              fatherName: getSpouseVal('fatherName'),
              useDob:
                  (getSpouseVal('useDob') == true ||
                  getSpouseVal('useDob') == 'true'),
              dob: _parseDate(getSpouseVal('dob')?.toString()),
              edd: _parseDate(getSpouseVal('edd')?.toString()),
              lmp: _parseDate(getSpouseVal('lmp')?.toString()),
              approxAge: approx,
              UpdateYears: updateYears,
              UpdateMonths: updateMonths,
              UpdateDays: updateDays,
              gender:
                  getSpouseVal('gender') ??
                  ((getHeadVal('gender') == 'Male')
                      ? 'Female'
                      : (getHeadVal('gender') == 'Female')
                      ? 'Male'
                      : null),

              // Occupation fields
              occupation: occupation,
              otherOccupation: otherOccupation,

              education: getSpouseVal('education'),

              // Religion fields
              religion: religion,
              otherReligion: otherReligion,

              // Category fields
              category: category,
              otherCategory: otherCategory,

              abhaAddress: getSpouseVal('abhaAddress'),

              // Mobile owner fields
              mobileOwner: mobileOwner,
              mobileOwnerOtherRelation: mobileOwnerOtherRelation,

              mobileNo: getSpouseVal('mobileNo'),
              bankAcc: getSpouseVal('bankAcc'),
              ifsc: getSpouseVal('ifsc'),
              voterId: getSpouseVal('voterId'),
              rationId: getSpouseVal('rationId'),
              phId: getSpouseVal('phId'),
              beneficiaryType: getSpouseVal('beneficiaryType'),
              isPregnant: getSpouseVal('isPregnant'),

              // Family planning fields
              familyPlanningCounseling: familyPlanningCounseling,
              fpMethod: fpMethod,

              // Removal related fields
              removalDate: _parseDate(
                removalDate is String ? removalDate : removalDate?.toString(),
              ),
              removalReason: removalReason,

              // Quantity fields
              condomQuantity: condomQuantity,
              malaQuantity: malaQuantity,
              chhayaQuantity: chhayaQuantity,
              ecpQuantity: ecpQuantity,

              // Antra date field
              antraDate: _parseDate(
                antraDate is String ? antraDate : antraDate?.toString(),
              ),
            );

            return SpousBloc(initial: spState);
          },
        ),
        BlocProvider<ChildrenBloc>(
          create: (_) {
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
          },
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showConfirmationDialog(
            context: context,
            title: l.confirmAttentionTitle,
            message: l.confirmCloseFormMsg,
            yesText: l.yes,
            noText: l.confirmNo,
          );
          return shouldExit ?? false;
        },
        child: BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
          listenWhen: (p, c) => p.postApiStatus != c.postApiStatus,
          listener: (context, state) {
            if (state.postApiStatus == PostApiStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                  if (widget.initial![key] != null &&
                      !result.containsKey(key)) {
                    result[key] = widget.initial![key];
                  }
                }
              }
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
                      'Age':
                          ((state.useDob && state.dob != null)
                                  ? _ageFromDob(state.dob!)
                                  : (state.approxAge ?? ''))
                              .toString(),
                      'Gender': (state.gender ?? '').toString(),
                      'Relation': 'Self',
                      'Father': (state.fatherName ?? '').toString(),
                      'Spouse': (state.spouseName ?? '').toString(),
                      'Total Children':
                          (state.children != null && state.children!.isNotEmpty)
                          ? state.children!
                          : (state.hasChildren == 'Yes' ? '1+' : '0'),
                      'isSpouseRow': '0',
                    },
                  ];
                  if (((state.maritalStatus?.toLowerCase() == 'married') ||
                          (state.maritalStatus?.toLowerCase() == 'Married')) &&
                      (state.spouseName != null) &&
                      state.spouseName!.isNotEmpty) {
                    final spouseGender = (state.gender == 'Male')
                        ? 'Female'
                        : (state.gender == 'Female')
                        ? 'Male'
                        : '';

                    String spouseAge = '';
                    String spouseFather = '';
                    try {
                      final sp = context.read<SpousBloc>().state;
                      spouseAge =
                          ((sp.useDob && sp.dob != null)
                                  ? _ageFromDob(sp.dob!)
                                  : (sp.approxAge ?? ''))
                              .toString();
                      spouseFather = (sp.fatherName ?? '').toString();
                    } catch (e) {
                      debugPrint('Error fetching spouse details: $e');
                    }

                    final spouseRelation = (state.gender == 'Male')
                        ? 'Wife'
                        : 'Husband';

                    members.add({
                      '#': '2',
                      'Type': 'Adult',
                      'Name': state.spouseName!,
                      'Age': spouseAge,
                      'Gender': spouseGender,
                      'Relation': spouseRelation,
                      'Father': spouseFather,
                      'Spouse': (state.headName ?? '').toString(),
                      'Total Children':
                          (state.children != null && state.children!.isNotEmpty)
                          ? state.children!
                          : (state.hasChildren == 'Yes' ? '1+' : '0'),
                      'isSpouseRow': '1',
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
            backgroundColor: Colors.white,
            appBar: AppHeader(
              screenTitle: l.familyHeadDetailsTitle,
              showBack: true,
              onBackTap: () async {
                final shouldExit = await showConfirmationDialog(
                  context: context,
                  title: l.confirmAttentionTitle,
                  message: l.confirmCloseFormMsg,
                  yesText: l.yes,
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
                  yesText: l.yes,
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
                        final tabs = [Tab(text: l.familyHeadDetailsTitle)];
                        final views = <Widget>[
                          Form(
                            key: _formKey,
                            child: _buildFamilyHeadForm(context, state, l),
                          ),
                        ];

                        final showSpouse =
                            state.maritalStatus == 'Married' ||
                            state.maritalStatus == 'married';
                        final showChildren =
                            state.hasChildren == 'Yes' ||
                            state.hasChildren == 'yes';

                        if (showSpouse) {
                          final spBloc = context.read<SpousBloc>();
                          final current = spBloc.state;

                          final bool isSpouseStateEmpty =
                              (current.relation == null ||
                                  current.relation!.trim().isEmpty) &&
                              (current.memberName == null ||
                                  current.memberName!.trim().isEmpty) &&
                              (current.spouseName == null ||
                                  current.spouseName!.trim().isEmpty) &&
                              current.dob == null &&
                              (current.UpdateYears == null ||
                                  current.UpdateYears!.trim().isEmpty) &&
                              (current.UpdateMonths == null ||
                                  current.UpdateMonths!.trim().isEmpty) &&
                              (current.UpdateDays == null ||
                                  current.UpdateDays!.trim().isEmpty);

                          if (isSpouseStateEmpty) {
                            final g = (state.gender == 'Male')
                                ? 'Female'
                                : (state.gender == 'Female')
                                ? 'Male'
                                : null;

                            spBloc.add(
                              SpHydrate(
                                SpousState(
                                  relation: 'Spouse',
                                  memberName: state.spouseName,
                                  ageAtMarriage: state.ageAtMarriage,
                                  spouseName: state.headName,
                                  gender: g,
                                ),
                              ),
                            );
                          } else {
                            final headName = state.headName?.trim();
                            final spouseName = state.spouseName?.trim();
                            if ((current.memberName == null ||
                                    current.memberName!.isEmpty) &&
                                (spouseName != null && spouseName.isNotEmpty)) {
                              spBloc.add(SpUpdateMemberName(spouseName));
                            }
                            if ((current.spouseName == null ||
                                    current.spouseName!.isEmpty) &&
                                (headName != null && headName!.isNotEmpty)) {
                              spBloc.add(SpUpdateSpouseName(headName));
                            }
                          }
                          tabs.add(Tab(text: l.spousDetails));
                          views.add(
                            MultiBlocListener(
                              listeners: [
                                // Head -> Spouse: keep spouse tab prefilled
                                BlocListener<
                                  AddFamilyHeadBloc,
                                  AddFamilyHeadState
                                >(
                                  listenWhen: (prev, curr) =>
                                      prev.headName != curr.headName ||
                                      prev.spouseName != curr.spouseName,
                                  listener: (ctx, st) {
                                    if (_syncingNames) return;
                                    final spBloc = ctx.read<SpousBloc>();
                                    final memberName = st.spouseName?.trim();
                                    final spouseName = st.headName?.trim();
                                    if (memberName != null &&
                                        memberName.isNotEmpty) {
                                      spBloc.add(
                                        SpUpdateMemberName(memberName),
                                      );
                                    }
                                    if (spouseName != null &&
                                        spouseName.isNotEmpty) {
                                      spBloc.add(
                                        SpUpdateSpouseName(spouseName),
                                      );
                                    }
                                  },
                                ),

                                BlocListener<SpousBloc, SpousState>(
                                  listenWhen: (p, c) =>
                                      p.memberName != c.memberName ||
                                      p.spouseName != c.spouseName,
                                  listener: (ctx, sp) {
                                    if (_syncingNames) return;
                                    _syncingNames = true;
                                    try {
                                      final headBloc = ctx
                                          .read<AddFamilyHeadBloc>();
                                      final newSpouseName =
                                          (sp.memberName ?? '').trim();
                                      final newHeadName = (sp.spouseName ?? '')
                                          .trim();

                                      if (newSpouseName.isNotEmpty &&
                                          (headBloc.state.spouseName ?? '')
                                                  .trim() !=
                                              newSpouseName) {
                                        headBloc.add(
                                          AfhUpdateSpouseName(newSpouseName),
                                        );
                                      }
                                      if (newHeadName.isNotEmpty &&
                                          (headBloc.state.headName ?? '')
                                                  .trim() !=
                                              newHeadName) {
                                        headBloc.add(
                                          AfhUpdateHeadName(newHeadName),
                                        );
                                      }
                                    } finally {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _syncingNames = false;
                                          });
                                    }
                                  },
                                ),
                              ],
                              child: Spousdetails(
                                syncFromHead: true,
                                isEdit: widget.isEdit,
                              ),
                            ),
                          );
                        }
                        if (showChildren) {
                          tabs.add(Tab(text: l.childrenDetailsTitle));
                          views.add(const Childrendetaills());
                        }

                        final int safeInitialIndex = widget.initialTab.clamp(
                          0,
                          tabs.length - 1,
                        );

                        return DefaultTabController(
                          key: ValueKey<int>(tabs.length),
                          length: tabs.length,
                          initialIndex: widget.initialTab.clamp(
                            0,
                            tabs.length - 1,
                          ),
                          child: Column(
                            children: [
                              Container(
                                color: Theme.of(context).colorScheme.primary,
                                child: TabBar(
                                  isScrollable: true,
                                  labelColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  unselectedLabelColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withOpacity(0.7),
                                  indicatorColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  indicatorWeight: 3.0,
                                  tabs: tabs,
                                ),
                              ),
                              Expanded(child: TabBarView(children: views)),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4.w,
                                    vertical: 1.h,
                                  ).copyWith(bottom: 2.h),
                                  child: Builder(
                                    builder: (ctx) {
                                      final controller =
                                          DefaultTabController.of(ctx)!;
                                      return AnimatedBuilder(
                                        animation: controller.animation!,
                                        builder: (context, _) {
                                          final showNav = tabs.length > 1;
                                          return BlocBuilder<
                                            AddFamilyHeadBloc,
                                            AddFamilyHeadState
                                          >(
                                            builder: (context, state) {
                                              final isLoading =
                                                  state.postApiStatus ==
                                                  PostApiStatus.loading;
                                              if (!showNav) {
                                                return Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: SizedBox(
                                                    width: 25.5.w,
                                                    height: 4.5.h,
                                                    child: RoundButton(
                                                      title: isLoading
                                                          ? (widget.isEdit
                                                                ? 'UPDATING...'
                                                                : l.addingButton)
                                                          : (widget.isEdit
                                                                ? 'UPDATE'
                                                                : l.addButton),
                                                      color: AppColors.primary,
                                                      borderRadius: 4,
                                                      height: 4.5.h,
                                                      isLoading: isLoading,
                                                      onPress: () {
                                                        _clearFormError();
                                                        final formState =
                                                            _formKey
                                                                .currentState;
                                                        if (formState == null)
                                                          return;
                                                        final isValid =
                                                            formState
                                                                .validate();
                                                        if (!isValid) {
                                                          if (_lastFormError !=
                                                              null) {
                                                            showAppSnackBar(
                                                              context,
                                                              _lastFormError!,
                                                            );
                                                          }
                                                          _scrollToFirstError();
                                                          return;
                                                        }
                                                        context
                                                            .read<
                                                              AddFamilyHeadBloc
                                                            >()
                                                            .add(
                                                              AfhSubmit(
                                                                context:
                                                                    context,
                                                              ),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }

                                              final i = controller.index;
                                              final last = tabs.length - 1;
                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  if (i > 0)
                                                    SizedBox(
                                                      height: 4.5.h,
                                                      width: 25.5.w,
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          minimumSize: Size(
                                                            25.w,
                                                            4.5.h,
                                                          ),
                                                          backgroundColor:
                                                              AppColors.primary,
                                                          foregroundColor:
                                                              Colors.white,
                                                          side: BorderSide(
                                                            color: AppColors
                                                                .primary,
                                                            width: 0.2.w,
                                                          ), // 👈 matching border
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ), // rounded edges
                                                          ),
                                                          elevation:
                                                              0.5, // subtle elevation for depth
                                                          shadowColor: AppColors
                                                              .primary
                                                              .withOpacity(0.4),
                                                        ),
                                                        onPressed: () =>
                                                            controller
                                                                .animateTo(
                                                                  i - 1,
                                                                ),
                                                        child: Text(
                                                          l.previousButton,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 0.5,
                                                            fontSize: 14.sp,
                                                          ),
                                                        ),
                                                      ),
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
                                                          bool canProceed =
                                                              true;
                                                          if (i == 0) {
                                                            _clearFormError();
                                                            final headForm = _formKey.currentState;
                                                            if (headForm == null || !headForm.validate()) {
                                                              canProceed =
                                                                  false;
                                                              final msg =
                                                                  _lastFormError ??
                                                                  'Please correct the highlighted errors before continuing.';
                                                              showAppSnackBar(
                                                                context,
                                                                msg,
                                                              );
                                                              _scrollToFirstError();
                                                            }

                                                          } else if (i == 1) {
                                                            clearSpousFormError();
                                                            final spouseForm =
                                                                spousFormKey
                                                                    .currentState;
                                                            final spousState =
                                                                context
                                                                    .read<
                                                                      SpousBloc
                                                                    >()
                                                                    .state;

                                                            final isFormValid =
                                                                spouseForm
                                                                    ?.validate() ??
                                                                false;

                                                            final areAllFieldsValid =
                                                                validateAllSpousFields(
                                                                  spousState,
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!,
                                                                  isEdit: widget
                                                                      .isEdit,
                                                                );

                                                            if (!isFormValid ||
                                                                !areAllFieldsValid) {
                                                              canProceed =
                                                                  false;
                                                              final msg =
                                                                  spousLastFormError ??
                                                                  'Please correct the highlighted errors before continuing.';
                                                              showAppSnackBar(
                                                                context,
                                                                msg,
                                                              );

                                                              scrollToFirstError();
                                                            }
                                                          }
                                                          if (!canProceed)
                                                            return;
                                                          controller.animateTo(
                                                            i + 1,
                                                          );
                                                        } else {
                                                          if (last == 1) {
                                                            clearSpousFormError();
                                                            final spouseForm =
                                                                spousFormKey
                                                                    .currentState;
                                                            final spousState =
                                                                context
                                                                    .read<
                                                                      SpousBloc
                                                                    >()
                                                                    .state;

                                                            // First validate the form fields
                                                            final isFormValid =
                                                                spouseForm
                                                                    ?.validate() ??
                                                                false;

                                                            final areAllFieldsValid =
                                                                validateAllSpousFields(
                                                                  spousState,
                                                                  AppLocalizations.of(
                                                                    context,
                                                                  )!,
                                                                  isEdit: widget
                                                                      .isEdit,
                                                                );

                                                            if (!isFormValid ||
                                                                !areAllFieldsValid) {
                                                              final msg =
                                                                  spousLastFormError ??
                                                                  'Please correct the highlighted errors before continuing.';
                                                              showAppSnackBar(
                                                                context,
                                                                msg,
                                                              );

                                                              // Scroll to the first error in the form
                                                              scrollToFirstError();

                                                              return;
                                                            }
                                                          }

                                                          if (last == 2) {
                                                            // Children tab present, validate children details
                                                            try {
                                                              final ch = context
                                                                  .read<
                                                                    ChildrenBloc
                                                                  >()
                                                                  .state;

                                                              // 1) total live children must not be greater than total born children
                                                              if (ch.totalLive >
                                                                  ch.totalBorn) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  l.totalLiveChildrenval,
                                                                );
                                                                return;
                                                              }

                                                              // 2) total male children must not be greater than total live children
                                                              if (ch.totalMale >
                                                                  ch.totalLive) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  l.totalMaleChildrenval,
                                                                );
                                                                return;
                                                              }

                                                              // 3) total female children must not be greater than total live children
                                                              if (ch.totalFemale >
                                                                  ch.totalLive) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  l.totalFemaleChildrenval,
                                                                );
                                                                return;
                                                              }

                                                              // 4) sum of male and female children must not be greater than total live children
                                                              if ((ch.totalMale +
                                                                      ch.totalFemale) !=
                                                                  ch.totalLive) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  l.malePlusFemaleError,
                                                                );
                                                                return;
                                                              }

                                                              final youngestGenderErr =
                                                                  _validateYoungestGender(
                                                                    ch,
                                                                    l,
                                                                  );
                                                              if (youngestGenderErr !=
                                                                  null) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  youngestGenderErr,
                                                                );
                                                                return;
                                                              }

                                                              final youngestErr =
                                                                  _validateYoungestChild(
                                                                    ch,
                                                                    l,
                                                                  );
                                                              if (youngestErr !=
                                                                  null) {
                                                                showAppSnackBar(
                                                                  context,
                                                                  youngestErr,
                                                                );
                                                                return;
                                                              }
                                                            } catch (_) {}
                                                          }

                                                          context
                                                              .read<
                                                                AddFamilyHeadBloc
                                                              >()
                                                              .add(
                                                                AfhSubmit(
                                                                  context:
                                                                      context,
                                                                ),
                                                              );
                                                        }
                                                      },
                                                      color: AppColors.primary,
                                                      borderRadius: 4,
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
