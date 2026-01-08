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
import '../../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/repositories/RegisterNewHouseHoldController/register_new_house_hold.dart';
import '../../AddNewFamilyMember/bloc/addnewfamilymember_bloc.dart';
import 'bloc/spous_bloc.dart';

final GlobalKey<FormState> spousFormKey = GlobalKey<FormState>();
String? spousLastFormError;

void clearSpousFormError() {
  spousLastFormError = null;
}

String? captureSpousError(String? message) {
  if (message != null && message.isNotEmpty) {
    spousLastFormError = message;
    return message;
  }
  return null;
}

bool validateAllSpousFields(
  SpousState state,
  AppLocalizations l, {
  bool isEdit = false,
}) {
  final form = spousFormKey.currentState;
  bool isValid = true;

  spousLastFormError = null;

  if (form != null) {
    isValid = form.validate();
  }

  if (state.mobileOwner == null || state.mobileOwner!.isEmpty) {
    spousLastFormError = l.whoseMobileNumberRequired;
    if (isValid) {
      scrollToFirstError();
    }
    isValid = false;
  }

  if (state.mobileOwner == 'Other' &&
      (state.mobileOwnerOtherRelation == null ||
          state.mobileOwnerOtherRelation!.trim().isEmpty)) {
    spousLastFormError = l.relation_with_mobile_holder_required;
    if (isValid) {
      scrollToFirstError();
    }
    isValid = false;
  }

  if (state.mobileOwner != 'Family Head') {
    if (state.mobileNo == null || state.mobileNo!.trim().isEmpty) {
      spousLastFormError = l.mobileNumberRequired;
      if (isValid) {
        scrollToFirstError();
      }
      isValid = false;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(state.mobileNo!)) {
      spousLastFormError = l.mobileNo10DigitsStart6To9;
      if (isValid) {
        scrollToFirstError();
      }
      isValid = false;
    }
  }

  if (!isEdit &&
      state.gender == 'Female' &&
      (state.isPregnant == null || state.isPregnant!.isEmpty)) {
    spousLastFormError = l.pleaseEnterIsWomanPregnant;
    if (isValid) {
      scrollToFirstError();
    }
    isValid = false;
  }

  if (!isEdit && state.isPregnant == 'Yes') {
    if (state.lmp == null) {
      spousLastFormError = l.pleaseEnterLMP;
      if (isValid) {
        scrollToFirstError();
      }
      isValid = false;
    }
    if (state.edd == null) {
      spousLastFormError = l.pleaseEnterExpectedDeliveryDate;
      if (isValid) {
        scrollToFirstError();
      }
      isValid = false;
    }
  }

  return isValid;
}

void scrollToFirstError() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final errorField = _findFirstErrorField();
    if (errorField != null && errorField.context != null) {
      Scrollable.ensureVisible(
        errorField.context!,
        alignment: 0.1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}

FormFieldState<dynamic>? _findFirstErrorField() {
  FormFieldState<dynamic>? firstErrorField;
  BuildContext? formContext = spousFormKey.currentContext;

  if (formContext == null) return null;

  void visitElement(Element element) {
    if (firstErrorField != null) return;

    if (element.widget is FormField) {
      final formField = element as StatefulElement;
      final field = formField.state as FormFieldState<dynamic>?;

      if (field != null && field.hasError) {
        firstErrorField = field;
        return;
      }
    }

    element.visitChildren(visitElement);
  }

  // Start visiting from the form's context
  formContext.visitChildElements(visitElement);
  return firstErrorField;
}

class Spousdetails extends StatefulWidget {
  final SpousState? initial;
  final String? headMobileOwner;
  final String? headMobileNo;
  final String? hhId;
  final bool isMemberDetails;
  final bool syncFromHead;
  final bool isAddMember;
  final String? headGender;
  final String? otherOccupation;
  final String? otherCategory;
  final String? otherReligion;
  final String? occupation;
  final String? category;
  final String? religion;
  final bool isEdit;

  const Spousdetails({
    super.key,
    this.initial,
    this.headMobileOwner,
    this.headMobileNo,
    this.hhId,
    this.isMemberDetails = false,
    this.syncFromHead = true,
    this.isAddMember = false,
    this.headGender,
    this.otherOccupation,
    this.otherCategory,
    this.otherReligion,
    this.occupation,
    this.category,
    this.religion,
    this.isEdit = false,
  });

  @override
  State<Spousdetails> createState() => _SpousdetailsState();
}

List<String> _getMobileOwnerList(String gender) {
  const common = [];

  gender = gender.toLowerCase();

  if (gender == 'female') {
    return [
      'Self',
      'Family Head',
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
      'Family Head',
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
      'Family Head',
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

class _SpousdetailsState extends State<Spousdetails>
    with AutomaticKeepAliveClientMixin {
  void _updateDobFromAge(String years, String months, String days) {
    // If any field is empty, clear the DOB and return
    if (years.trim().isEmpty || months.trim().isEmpty || days.trim().isEmpty) {
      context.read<SpousBloc>().add(SpUpdateDob(null));
      return;
    }

    // If all fields are empty, clear the DOB and return
    if (years.trim().isEmpty && months.trim().isEmpty && days.trim().isEmpty) {
      context.read<SpousBloc>().add(SpUpdateDob(null));
      return;
    }

    // Parse the values, defaulting to 0 if parsing fails
    final y = int.tryParse(years.trim()) ?? 0;
    final m = int.tryParse(months.trim()) ?? 0;
    final d = int.tryParse(days.trim()) ?? 0;

    // If all values are 0, clear the DOB
    if (y == 0 && m == 0 && d == 0) {
      context.read<SpousBloc>().add(SpUpdateDob(null));
      return;
    }

    final now = DateTime.now();
    var calculatedDob = DateTime(now.year - y, now.month - m, now.day - d);

    // Handle month overflow
    if (calculatedDob.day != now.day) {
      // Adjust for months with different number of days
      calculatedDob = DateTime(calculatedDob.year, calculatedDob.month + 1, 0);
    }

    // Update the DOB in the state if it's different
    final currentDob = context.read<SpousBloc>().state.dob;
    if (currentDob == null ||
        currentDob.year != calculatedDob.year ||
        currentDob.month != calculatedDob.month ||
        currentDob.day != calculatedDob.day) {
      context.read<SpousBloc>().add(SpUpdateDob(calculatedDob));
    }
  }

  final GlobalKey<FormState> _formKey = spousFormKey;

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

  Widget _section(Widget child) => Padding(
    padding: EdgeInsets.symmetric(vertical: 0.h),
    child: child,
  );

  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isAddMember && widget.headMobileNo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final spBloc = context.read<SpousBloc>();
          // spBloc.add(SpUpdateMobileNo(widget.headMobileNo!));
          // spBloc.add(SpUpdateMobileOwner('Family Head'));
        }
      });
    } else if (widget.syncFromHead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final headBloc = context.read<AddFamilyHeadBloc>();
        final head = headBloc.state;
        final spBloc = context.read<SpousBloc>();
        final curr = spBloc.state;

        if (head.gender != null) {
          final isMale = head.gender == 'Male';
          final relation = isMale ? 'Wife' : 'Husband';
          final oppositeGender = isMale ? 'Female' : 'Male';

          spBloc.add(SpUpdateRelation(relation));
          spBloc.add(SpUpdateGender(oppositeGender));
        }

        // Only sync names if NOT in edit mode, to prevent overwriting existing data with potentially incorrect Head data
        if (!widget.isEdit) {
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
        }

        // Auto-fill mobile number if head's mobile is available and mobile owner is 'Family Head'
        if (head.mobileNo != null && head.mobileNo!.isNotEmpty) {
          if (widget.headMobileOwner == 'Family Head' ||
              curr.mobileOwner == 'Family Head') {
            spBloc.add(SpUpdateMobileNo(head.mobileNo!));
            spBloc.add(SpUpdateMobileOwner('Family Head'));
          }
        }

        final headReligion = head.religion?.trim();
        if ((curr.religion == null || curr.religion!.isEmpty) &&
            headReligion != null &&
            headReligion.isNotEmpty) {
          spBloc.add(SpUpdateReligion(headReligion));
          if (headReligion == 'Other') {
            final or = head.otherReligion?.trim();
            if (or != null && or.isNotEmpty) {
              spBloc.add(SpUpdateOtherReligion(or));
            }
          }
        }

        final headCategory = head.category?.trim();
        if ((curr.category == null || curr.category!.isEmpty) &&
            headCategory != null &&
            headCategory.isNotEmpty) {
          spBloc.add(SpUpdateCategory(headCategory));
          if (headCategory == 'Other') {
            final oc = head.otherCategory?.trim();
            if (oc != null && oc.isNotEmpty) {
              spBloc.add(SpUpdateOtherCategory(oc));
            }
          }
        }

        if (curr.occupation != null && curr.occupation!.isNotEmpty) {
          spBloc.add(SpUpdateOccupation(curr.occupation!));
          if (curr.occupation == 'Other' &&
              curr.otherOccupation != null &&
              curr.otherOccupation!.isNotEmpty) {
            spBloc.add(SpUpdateOtherOccupation(curr.otherOccupation!));
          }
        }

        if (curr.religion != null && curr.religion!.isNotEmpty) {
          spBloc.add(SpUpdateReligion(curr.religion!));
          if (curr.religion == 'Other' &&
              curr.otherReligion != null &&
              curr.otherReligion!.isNotEmpty) {
            spBloc.add(SpUpdateOtherReligion(curr.otherReligion!));
          }
        }

        if (curr.category != null && curr.category!.isNotEmpty) {
          spBloc.add(SpUpdateCategory(curr.category!));
          if (curr.category == 'Other' &&
              curr.otherCategory != null &&
              curr.otherCategory!.isNotEmpty) {
            spBloc.add(SpUpdateOtherCategory(curr.otherCategory!));
          }
        }

        if (curr.mobileOwnerOtherRelation != null &&
            curr.mobileOwnerOtherRelation!.isNotEmpty) {
          spBloc.add(
            SpUpdateMobileOwnerOtherRelation(curr.mobileOwnerOtherRelation!),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;

    if (widget.syncFromHead) {
      return BlocListener<AddFamilyHeadBloc, AddFamilyHeadState>(
        listenWhen: (previous, current) =>
            previous.headName != current.headName ||
            previous.spouseName != current.spouseName ||
            previous.gender != current.gender ||
            previous.mobileNo != current.mobileNo ||
            previous.mobileOwner != current.mobileOwner ||
            previous.religion != current.religion ||
            previous.category != current.category ||
            previous.otherReligion != current.otherReligion ||
            previous.otherCategory != current.otherCategory,
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
              (st.mobileOwner != null &&
                  st.mobileOwner != previous.mobileOwner)) {
            if (st.mobileOwner == 'Family Head' &&
                st.mobileNo != null &&
                st.mobileNo!.isNotEmpty) {
              spBloc.add(SpUpdateMobileNo(st.mobileNo!));
              spBloc.add(SpUpdateMobileOwner('Family Head'));
            } else if (st.mobileOwner != 'Family Head' &&
                curr.mobileOwner == 'Family Head') {
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
          if ((curr.religion == null || curr.religion!.isEmpty) &&
              st.religion != null &&
              st.religion!.isNotEmpty) {
            spBloc.add(SpUpdateReligion(st.religion!));
            if (st.religion == 'Other' &&
                st.otherReligion != null &&
                st.otherReligion!.isNotEmpty) {
              spBloc.add(SpUpdateOtherReligion(st.otherReligion!.trim()));
            }
          }
          if ((curr.category == null || curr.category!.isEmpty) &&
              st.category != null &&
              st.category!.isNotEmpty) {
            spBloc.add(SpUpdateCategory(st.category!));
            if (st.category == 'Other' &&
                st.otherCategory != null &&
                st.otherCategory!.isNotEmpty) {
              spBloc.add(SpUpdateOtherCategory(st.otherCategory!.trim()));
            }
          }
        },
        child: _buildForm(l),
      );
    }

    return _buildForm(l);
  }

  void _handleAbhaProfileResult(
    Map<String, dynamic> profile,
    BuildContext context,
  ) {
    debugPrint("ABHA Profile Received in Spouse Tab: $profile");

    final spBloc = context.read<SpousBloc>();

    // 1. ABHA Address (Spouse)
    final abhaAddress = profile['abhaAddress']?.toString().trim();
    if (abhaAddress != null && abhaAddress.isNotEmpty) {
      spBloc.add(SpUpdateAbhaAddress(abhaAddress));
    }

    // 2. Full Name → Member Name (Spouse's own name)
    final nameParts = [
      profile['firstName'],
      profile['middleName'],
      profile['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
    if (nameParts.isNotEmpty) {
      spBloc.add(SpUpdateMemberName(nameParts.trim()));
    }

    // 3. DOB → Switch to DOB mode + fill
    try {
      final day = profile['dayOfBirth']?.toString();
      final month = profile['monthOfBirth']?.toString();
      final year = profile['yearOfBirth']?.toString();
      if (day != null && month != null && year != null) {
        final dob = DateTime(int.parse(year), int.parse(month), int.parse(day));
        spBloc.add(SpToggleUseDob()); // Switch to DOB mode
        spBloc.add(SpUpdateDob(dob));
      }
    } catch (e) {
      debugPrint("DOB parse error: $e");
    }

    // 4. Gender
    final g = profile['gender']?.toString().toUpperCase();
    String? gender;
    if (g == 'M') gender = 'Male';
    if (g == 'F') gender = 'Female';
    if (g == 'O' || g == 'T') gender = 'Transgender';

    if (gender != null) {
      spBloc.add(SpUpdateGender(gender));
      final headGender = context.read<AddFamilyHeadBloc>().state.gender;
      final expectedRelation = headGender == 'Male' ? 'Wife' : 'Husband';
      if (gender == 'Female' && headGender == 'Male') {
        spBloc.add(SpUpdateRelation('Wife'));
      } else if (gender == 'Male' && headGender == 'Female') {
        spBloc.add(SpUpdateRelation('Husband'));
      }
    }

    // 5. Mobile Number + Owner = Self
    final mobile = profile['mobile']?.toString().trim();
    if (mobile != null && mobile.length == 10) {
      spBloc.add(SpUpdateMobileNo(mobile));
      spBloc.add(SpUpdateMobileOwner('Self'));
    }

    // Success message
    showAppSnackBar(context, "ABHA details filled for Spouse successfully!");
  }

  Widget _buildForm(AppLocalizations l) {
    return Form(
      key: spousFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,

      child: BlocBuilder<SpousBloc, SpousState>(
        builder: (context, state) {
          final spBloc = context.read<SpousBloc>();

          // Debug logging for LMP state
          print(
            '🔄 [SpousDetails] BlocBuilder called - LMP: ${state.lmp}, EDD: ${state.edd}, isPregnant: ${state.isPregnant}',
          );

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            child: Column(
              children: [
                _section(
                  IgnorePointer(
                    ignoring: widget.isEdit,
                    child: ApiDropdown<String>(
                      key: const ValueKey('relation_with_head'),
                      labelText: '${l.relationWithFamilyHead} *',
                      readOnly: true,
                      items: widget.isMemberDetails
                          ? [
                              'Self',
                              'Father',
                              'Mother',
                              'Husband',
                              'Wife',
                              'Brother',
                              'Sister',
                              'Nephew',
                              'Niece',
                              'Son',
                              'Daughter',
                              'Grand Father',
                              'Grand Mother',
                              'Father In Law',
                              'Mother In Law',
                              'Grand Son',
                              'Grand Daughter',
                              'Son In Law',
                              'Daughter In Law',
                              'Other',
                            ]
                          : const ['Husband', 'Wife'],
                      validator: (value) => captureSpousError(
                        value == null || value.isEmpty
                            ? l.relationWithFamilyHeadRequired
                            : null,
                      ),

                      getLabel: (s) {
                        if (!widget.isMemberDetails) {
                          return s == 'Husband' ? l.husbandLabel : l.wife;
                        }

                        switch (s) {
                          case 'Self':
                            return l.self ?? 'Self';
                          case 'Father':
                            return l.father ?? 'Father';
                          case 'Mother':
                            return l.mother ?? 'Mother';
                          case 'Husband':
                            return 'Husband';
                          case 'Wife':
                            return l.wife ?? 'Wife';
                          case 'Brother':
                            return 'Brother';
                          case 'Sister':
                            return 'Sister';
                          case 'Nephew':
                            return 'Nephew';
                          case 'Niece':
                            return 'Niece';
                          case 'Son':
                            return l.son ?? 'Son';
                          case 'Daughter':
                            return l.daughter ?? 'Daughter';
                          case 'Grand Father':
                            return 'Grand Father';
                          case 'Grand Mother':
                            return 'Grand Mother';
                          case 'Father In Law':
                            return l.fatherInLaw ?? 'Father In Law';
                          case 'Mother In Law':
                            return l.motherInLaw ?? 'Mother In Law';
                          case 'Grand Son':
                            return 'Grand Son';
                          case 'Grand Daughter':
                            return 'Grand Daughter';
                          case 'Son In Law':
                            return 'Son In Law';
                          case 'Daughter In Law':
                            return 'Daughter In Law';
                          case 'Other':
                            return l.other ?? 'Other';

                          default:
                            return s;
                        }
                      },

                      value: widget.isMemberDetails
                          ? state.relation
                          : (state.relation == 'Spouse'
                                ? (state.gender == 'Female'
                                      ? 'Husband'
                                      : 'Wife')
                                : (state.relation ??
                                      (state.gender == 'Female'
                                          ? 'Husband'
                                          : 'Wife'))),
                      onChanged: widget.isEdit
                          ? null
                          : (v) => context.read<SpousBloc>().add(
                              SpUpdateRelation(v),
                            ),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    key: const ValueKey('member_name'),
                    labelText: '${l.nameOfMemberLabel} *',
                    hintText: l.nameOfMemberHint,
                    initialValue: state.memberName,
                    readOnly: false,
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateMemberName(v.trim()),
                    ),
                    // validator: (value) => captureSpousError(
                    //   value == null || value.trim().isEmpty ? 'Name of member is required' : null,
                    // ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.pleaseEnterNameOfMember;
                      }
                      return null;
                    },
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.ageAtMarriage,
                    hintText: l.ageAtMarriage,
                    keyboardType: TextInputType.number,
                    initialValue: state.ageAtMarriage,
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateAgeAtMarriage(v.trim()),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    key: const ValueKey('spouse_name'),
                    labelText: '${l.spouseNameLabel} *',
                    hintText: l.spouseNameHint,
                    initialValue: state.spouseName,
                    readOnly: widget.isEdit,
                    // validator: (value) => captureSpousError(
                    //   value == null || value.trim().isEmpty ? 'Spouse name is required' : null,
                    // ),
                    onChanged: widget.isEdit
                        ? null
                        : (v) => context.read<SpousBloc>().add(
                            SpUpdateSpouseName(v.trim()),
                          ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l.pleaseEnterSpouseName;
                      }
                      return null;
                    },
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.fatherName,
                    hintText: l.fatherName,
                    initialValue: state.fatherName,
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateFatherName(v.trim()),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: state.useDob,
                      onChanged: widget.isEdit
                          ? null
                          : (_) =>
                                context.read<SpousBloc>().add(SpToggleUseDob()),
                    ),
                    Text(l.dobShort, style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 4.w),
                    Radio<bool>(
                      value: false,
                      groupValue: state.useDob,
                      onChanged: widget.isEdit
                          ? null
                          : (_) =>
                                context.read<SpousBloc>().add(SpToggleUseDob()),
                    ),
                    Text(l.ageApproximate, style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
                if (state.useDob)
                  _section(
                    CustomDatePicker(
                      labelText: '${l.dobLabel} *',
                      hintText: l.dateHint,
                      initialDate: state.dob,
                      firstDate: DateTime(
                        now.year - 110,
                        now.month,
                        now.day,
                      ), // exactly 110 years ago
                      lastDate: DateTime(now.year - 15, now.month, now.day),
                      onDateChanged: (date) {
                        if (date != null) {
                          context.read<SpousBloc>().add(SpUpdateDob(date));
                        }
                      },
                      validator: (date) =>
                          captureSpousError(Validations.validateDOB(l, date)),
                      readOnly: widget.isEdit,
                    ),
                  )
                else
                  _section(
                    Column(
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
                            Expanded(
                              child: CustomTextField(
                                labelText: l.years,
                                hintText: '0',
                                maxLength: 3,
                                initialValue: state.UpdateYears ?? '',
                                keyboardType: TextInputType.number,
                                readOnly: widget.isEdit,
                                onChanged: widget.isEdit
                                    ? null
                                    : (v) {
                                        context.read<SpousBloc>().add(
                                          UpdateYearsChanged(v.trim()),
                                        );
                                        final state = context
                                            .read<SpousBloc>()
                                            .state;
                                        _updateDobFromAge(
                                          v.trim(),
                                          state.UpdateMonths ?? '',
                                          state.UpdateDays ?? '',
                                        );
                                      },
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
                                readOnly: widget.isEdit,
                                onChanged: widget.isEdit
                                    ? null
                                    : (v) {
                                        context.read<SpousBloc>().add(
                                          UpdateMonthsChanged(v.trim()),
                                        );
                                        final state = context
                                            .read<SpousBloc>()
                                            .state;
                                        _updateDobFromAge(
                                          state.UpdateYears ?? '',
                                          v.trim(),
                                          state.UpdateDays ?? '',
                                        );
                                      },
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
                                readOnly: widget.isEdit,
                                onChanged: widget.isEdit
                                    ? null
                                    : (v) {
                                        context.read<SpousBloc>().add(
                                          UpdateDaysChanged(v.trim()),
                                        );
                                        final state = context
                                            .read<SpousBloc>()
                                            .state;
                                        _updateDobFromAge(
                                          state.UpdateYears ?? '',
                                          state.UpdateMonths ?? '',
                                          v.trim(),
                                        );
                                      },
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
                        ),
                      ],
                    ),
                  ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  AbsorbPointer(
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
                      onChanged: null,
                      validator: (value) =>
                          Validations.validateGender(l, value),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  IgnorePointer(
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
                      onChanged: (v) =>
                          context.read<SpousBloc>().add(SpUpdateOccupation(v)),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.occupation == 'Other')
                  if (state.occupation == 'Other')
                    _section(
                      CustomTextField(
                        labelText: l.enterOccupationOther,
                        hintText: l.enterOccupationOther,
                        initialValue: state.otherOccupation,
                        onChanged: (v) => context.read<SpousBloc>().add(
                          SpUpdateOtherOccupation(v.trim()),
                        ),
                      ),
                    ),
                if (state.occupation == 'Other')
                  if (state.occupation == 'Other')
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.5,
                      height: 0,
                    ),

                _section(
                  ApiDropdown<String>(
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
                    onChanged: (v) =>
                        context.read<SpousBloc>().add(SpUpdateEducation(v)),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  ApiDropdown<String>(
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
                        context.read<SpousBloc>().add(SpUpdateReligion(v)),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.religion == 'Other')
                  if (state.religion == 'Other')
                    _section(
                      CustomTextField(
                        labelText: l.enter_religion,
                        hintText: l.enter_religion,
                        initialValue: state.otherReligion,
                        onChanged: (v) => context.read<SpousBloc>().add(
                          SpUpdateOtherReligion(v.trim()),
                        ),
                      ),
                    ),
                if (state.religion == 'Other')
                  if (state.religion == 'Other')
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.5,
                      height: 0,
                    ),
                _section(
                  ApiDropdown<String>(
                    labelText: l.categoryLabel,
                    items: const [
                      'NotDisclosed',
                      'General',
                      'OBC',
                      'SC',
                      'ST',
                      'PichdaVarg1',
                      'PichdaVarg2',
                      'AtyantPichdaVarg',
                      'DontKnow',
                      'Other',
                    ],
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
                    onChanged: (v) =>
                        context.read<SpousBloc>().add(SpUpdateCategory(v)),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.category == 'Other')
                  if (state.category == 'Other')
                    _section(
                      CustomTextField(
                        labelText: l.enterCategory,
                        hintText: l.enterCategory,
                        initialValue: state.otherCategory,
                        onChanged: (v) => context.read<SpousBloc>().add(
                          SpUpdateOtherCategory(v.trim()),
                        ),
                      ),
                    ),
                if (state.category == 'Other')
                  if (state.category == 'Other')
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.5,
                      height: 0,
                    ),

                _section(
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: l.abhaAddressLabel,
                          hintText: l.abhaAddressLabel,
                          initialValue: state.abhaAddress,
                          onChanged: (v) => context.read<SpousBloc>().add(
                            SpUpdateAbhaAddress(v.trim()),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 3.5.h,
                        child: RoundButton(
                          title: l.linkAbha,
                          width: 15.h,
                          borderRadius: 8,
                          fontSize: 14.sp,
                          onPress: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              Route_Names.Abhalinkscreen,
                            );

                            debugPrint("BACK FROM ABHA SCREEN (Spouse Tab)");
                            if (result is Map<String, dynamic> && mounted) {
                              _handleAbhaProfileResult(result, context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (!widget.isEdit && state.gender == 'Female') ...[
                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                  _section(
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            labelText: l.rchIdLabel,
                            hintText: l.rchIdLabel,
                            keyboardType: TextInputType.number,
                            initialValue: state.RichIDChanged,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(12),
                            ],
                            onChanged: (v) {
                              // Clear previous snackbar
                              ScaffoldMessenger.of(
                                context,
                              ).removeCurrentSnackBar();

                              // Filter out non-digit characters (for copy-paste scenarios)
                              final filteredValue = v.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              final value = filteredValue.trim();

                              context.read<SpousBloc>().add(
                                RchIDChanged(value),
                              );

                              // Show error if not empty and not exactly 12 digits
                              if (value.isNotEmpty && value.length != 12) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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

                        SizedBox(
                          height: 3.5.h,
                          width: 15.h,
                          child: RoundButton(
                            title: l.verify,
                            width: 160,
                            borderRadius: 8,
                            fontSize: 12,
                            disabled: !state.isRchIdButtonEnabled,
                            onPress: () async {
                              final rchIdText =
                                  state.RichIDChanged?.trim() ?? '';
                              if (rchIdText.isEmpty) {
                                showAppSnackBar(
                                  context,
                                  l.enter_12_digit_rch_id,
                                );
                                return;
                              }
                              if (rchIdText.length != 12) {
                                showAppSnackBar(
                                  context,
                                  l.rch_id_must_be_12_digits,
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.verifying_rch_id),
                                  duration: Duration(seconds: 10),
                                ),
                              );
                              if (state.gender == 'Female') {
                                final result = await fetchRCHDataForScreen(
                                  int.tryParse(rchIdText) ?? 0,
                                  requestFor: 1,
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).removeCurrentSnackBar();

                                if (result != null &&
                                    result['status'] == true) {
                                  final data = result['data'];
                                  context.read<SpousBloc>().add(
                                    SpUpdateMemberName(data['name'] ?? ''),
                                  );
                                  context.read<SpousBloc>().add(
                                    SpUpdateDob(
                                      data['dob'] != null
                                          ? DateTime.tryParse(data['dob'])
                                          : null,
                                    ),
                                  );

                                  showAppSnackBar(
                                    context,
                                    l.rchIdVerifiedSuccess,
                                  );
                                } else {
                                  final message =
                                      result?['message'] ??
                                      l.failed_to_fetch_rch_data;
                                  showAppSnackBar(context, message);
                                }
                              } else {
                                showAppSnackBar(context, l.rchIdFemaleOnly);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  ApiDropdown<String>(
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
                    onChanged: (v) async {
                      if (v == null) return;
                      final spBloc = context.read<SpousBloc>();
                      spBloc.add(SpUpdateMobileOwner(v));

                      if (v == 'Husband' || v == 'Wife') {
                        try {
                          if (widget.isAddMember) {
                            final memberBloc = context
                                .read<AddnewfamilymemberBloc>();
                            final memberState = memberBloc.state;
                            if (memberState.mobileNo?.isNotEmpty == true) {
                              print(
                                '📱 [SpousDetails] Using mobile from AddNewFamilyMember: ${memberState.mobileNo}',
                              );
                              spBloc.add(
                                SpUpdateMobileNo(memberState.mobileNo!),
                              );
                              return;
                            }
                          }

                          final headNo =
                              (widget.headMobileNo?.trim() ??
                              context
                                  .read<AddFamilyHeadBloc>()
                                  .state
                                  .mobileNo
                                  ?.trim());
                          if (headNo != null && headNo.isNotEmpty) {
                            print(
                              '📱 [SpousDetails] Using head mobile: $headNo',
                            );
                            spBloc.add(SpUpdateMobileNo(headNo));
                          } else {
                            print('ℹ️ [SpousDetails] No mobile number found');
                            spBloc.add(const SpUpdateMobileNo(''));
                          }
                        } catch (e) {
                          print('❌ [SpousDetails] Error getting mobile: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error loading mobile number'),
                              ),
                            );
                          }
                          spBloc.add(const SpUpdateMobileNo(''));
                        }
                      }
                      // Keep existing logic for Family Head and Father
                      else if (v == 'Family Head' || v == 'Father') {
                        if (widget.headMobileNo?.isNotEmpty == true) {
                          print(
                            '📱 [SpousDetails] Using head mobile from props: ${widget.headMobileNo}',
                          );
                          spBloc.add(SpUpdateMobileNo(widget.headMobileNo!));
                        } else if (widget.hhId != null) {
                          try {
                            final headMobile = await LocalStorageDao.instance
                                .getHeadMobileNumber(widget.hhId!);
                            print(
                              '📱 [SpousDetails] Fetched mobile from DB: $headMobile',
                            );
                            if (headMobile != null && headMobile.isNotEmpty) {
                              spBloc.add(SpUpdateMobileNo(headMobile));
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No mobile number found for the head of family',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print(
                              '❌ [SpousDetails] Error fetching from DB: $e',
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Error loading head of family mobile number',
                                  ),
                                ),
                              );
                            }
                          }
                        } else {
                          if (v == 'Family Head' || v == 'Husband') {
                            final headNo = context
                                .read<AddFamilyHeadBloc>()
                                .state
                                .mobileNo
                                ?.trim();
                            if (headNo != null && headNo.isNotEmpty) {
                              spBloc.add(SpUpdateMobileNo(headNo));
                            }
                          }
                        }
                      } else {
                        spBloc.add(const SpUpdateMobileNo(''));
                      }
                    },
                    // validator: (value) => captureSpousError(
                    //   value == null || value.isEmpty ? 'Relation with family head is required' : null,
                    // ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return captureSpousError(l.whoseMobileNumberRequired);
                      }
                      return captureSpousError(null);
                    },
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                if (state.mobileOwner == 'Other')
                  if (state.mobileOwner == 'Other')
                    _section(
                      CustomTextField(
                        labelText: '${l.relationWithMobileHolder} *',
                        hintText: l.relationWithMobileHolder,
                        initialValue: state.mobileOwnerOtherRelation,
                        onChanged: (v) => context.read<SpousBloc>().add(
                          SpUpdateMobileOwnerOtherRelation(v.trim()),
                        ),
                        validator: (value) {
                          if (state.mobileOwner == 'Other') {
                            if (value == null || value.trim().isEmpty) {
                              return captureSpousError(
                                l.relation_with_mobile_holder_required,
                              );
                            }
                            return captureSpousError(null);
                          }
                          return null;
                        },
                      ),
                    ),
                if (state.mobileOwner == 'Other')
                  if (state.mobileOwner == 'Other')
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.5,
                      height: 0,
                    ),

                _section(
                  CustomTextField(
                    key: const ValueKey('spouse_mobile'),
                    labelText: '${l.mobileLabel} *',
                    hintText: '${l.mobileLabel}',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    initialValue: state.mobileNo,
                    readOnly: state.mobileOwner == 'Family Head',
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateMobileNo(v.trim()),
                    ),
                    validator: (value) {
                      if (state.mobileOwner == 'Family Head') {
                        return null;
                      }

                      if (value == null || value.trim().isEmpty) {
                        return captureSpousError(l.mobileNumberRequired);
                      }

                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                        return captureSpousError(l.mobileNo10DigitsStart6To9);
                      }

                      // Clear any previous error if validation passes
                      return captureSpousError(null);
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.bankAccountNumber,
                    hintText: l.bankAccountNumber,
                    keyboardType: TextInputType.number,
                    initialValue: state.bankAcc,
                    onChanged: (v) {
                      final value = v.trim();
                      context.read<SpousBloc>().add(SpUpdateBankAcc(value));
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

                      if (digitsOnly.length < 11 || digitsOnly.length > 18) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            showAppSnackBar(
                              context,
                              l.bank_account_length_error,
                            );
                          }
                        });
                        return l.bank_account_length_error;
                      }

                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(18),
                    ],
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.ifscLabel,
                    hintText: l.ifscHint,
                    keyboardType: TextInputType.text,
                    initialValue: state.ifsc,
                    maxLength: 11,
                    onChanged: (v) {
                      final value = v.trim();
                      context.read<SpousBloc>().add(SpUpdateIfsc(value));
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Field is optional
                      }

                      String? error;
                      if (value.length != 11) {
                        error = l.ifscValidationMessage;
                      } else if (!RegExp(r'^[A-Z]{4}0\d{6}$').hasMatch(value)) {
                        error = l.ifscValidationMessage;
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
                    // inputFormatters: [
                    //   FilteringTextInputFormatter.digitsOnly,
                    //   LengthLimitingTextInputFormatter(18),
                    // ],
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.voterIdLabel,
                    hintText: l.voterIdLabel,
                    initialValue: state.voterId,
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateVoterId(v.trim()),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.rationCardId,
                    hintText: l.rationCardIdHint,
                    initialValue: state.rationId,
                    onChanged: (v) => context.read<SpousBloc>().add(
                      SpUpdateRationId(v.trim()),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  CustomTextField(
                    labelText: l.personalHealthId,
                    hintText: l.personalHealthIdHint,
                    initialValue: state.phId,
                    onChanged: (v) =>
                        context.read<SpousBloc>().add(SpUpdatePhId(v.trim())),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                _section(
                  IgnorePointer(
                    ignoring: widget.isEdit,
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
                      onChanged: (v) => context.read<SpousBloc>().add(
                        SpUpdateBeneficiaryType(v),
                      ),
                    ),
                  ),
                ),

                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                if (!widget.isEdit && state.gender == 'Female') ...[
                  _section(
                    ApiDropdown<String>(
                      key: ValueKey(
                        'spouse_isPreg_${state.gender}_${state.isPregnant ?? ''}',
                      ),
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
                        // Trigger validation after change
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          spousFormKey.currentState?.validate();
                        });
                      },
                      // validator: (value) => captureSpousError(
                      //   value == null || value.isEmpty ? 'Pregnancy status is required' : null,
                      // ),
                      validator: (value) {
                        if (state.gender == 'Female' &&
                            (value == null || value.isEmpty)) {
                          return captureSpousError(
                            l.pleaseEnterIsWomanPregnant,
                          );
                        }
                        return captureSpousError(null);
                      },
                    ),
                  ),

                  Divider(
                    color: AppColors.divider,
                    thickness: 0.1.h,
                    height: 0,
                  ),

                  if (state.isPregnant == 'Yes')
                    _section(
                      CustomDatePicker(
                        key: const ValueKey('lmp_date'),
                        labelText: '${l.lmpDateLabel}',
                        hintText: l.dateHint,
                        initialDate: state.lmp, // Add initial date from state
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 276),
                        ),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 31),
                        ),
                        onDateChanged: (d) {
                          print('📅 [SpousDetails] LMP date changed to: $d');
                          final bloc = context.read<SpousBloc>();
                          bloc.add(SpLMPChange(d));
                          if (d != null) {
                            final edd = d.add(const Duration(days: 277));
                            bloc.add(SpEDDChange(edd));
                          } else {
                            bloc.add(const SpEDDChange(null));
                          }
                          // Trigger validation after change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            spousFormKey.currentState?.validate();
                          });
                        },
                        validator: (date) {
                          if (state.isPregnant == 'Yes' && date == null) {
                            return captureSpousError(l.pleaseEnterLMP);
                          }
                          return captureSpousError(null);
                        },
                      ),
                    ),
                  Divider(
                    color: AppColors.divider,
                    thickness: 0.1.h,
                    height: 0,
                  ),

                  // For EDD when pregnant
                  if (state.isPregnant == 'Yes')
                    _section(
                      CustomDatePicker(
                        key: const ValueKey('edd_date'),
                        labelText: '${l.eddDateLabel} *',
                        hintText: l.dateHint,
                        initialDate: state.edd,
                        onDateChanged: (d) {
                          context.read<SpousBloc>().add(SpEDDChange(d));
                          // Trigger validation after change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            spousFormKey.currentState?.validate();
                          });
                        },
                        validator: (date) {
                          if (state.isPregnant == 'Yes' && date == null) {
                            return captureSpousError(
                              l.pleaseEnterExpectedDeliveryDate,
                            );
                          }
                          return captureSpousError(null);
                        },
                        readOnly: true,
                      ),
                    ),

                  if (state.isPregnant == 'No') ...[
                    ApiDropdown<String>(
                      labelText: '${l.fpAdoptingLabel} *',
                      items: const ['Yes', 'No'],
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
                      value: state.familyPlanningCounseling ?? '${l.select}',
                      onChanged: (v) {
                        if (v == null) return;
                        spBloc.add(FamilyPlanningCounselingChanged(v));
                      },
                      validator: (value) => captureSpousError(
                        Validations.validateAdoptingPlan(l, value),
                      ),
                    ),
                    Divider(
                      color: AppColors.divider,
                      thickness: 0.5,
                      height: 0,
                    ),

                    if (state.familyPlanningCounseling == 'Yes') ...[
                      const SizedBox(height: 8),
                      ApiDropdown<String>(
                        labelText: '${l.methodOfContra} *',
                        items: const [
                          'Antra injection',
                          'Copper -T (IUCD)',
                          'Condom',
                          'Mala -N (Daily Contraceptive pill)',

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
                        value: state.fpMethod ?? '${l.select}',
                        onChanged: (value) {
                          if (value != null) {
                            spBloc.add(FpMethodChanged(value));
                          }
                        },
                        validator: (value) => captureSpousError(
                          Validations.validateAntra(l, value),
                        ),
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                    ],

                    if (state.fpMethod == 'Antra injection') ...[
                      CustomDatePicker(
                        labelText: l.dateOfAntra,
                        initialDate: state.antraDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            spBloc.add(DateofAntraChanged(date));
                          }
                        },
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                    ],
                    if (state.fpMethod == 'Copper -T (IUCD)') ...[
                      CustomDatePicker(
                        labelText: l.removalDate,
                        initialDate: state.removalDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            spBloc.add(RemovalDateChanged(date));
                          }
                        },
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      CustomTextField(
                        labelText: l.reasonForRemoval,
                        hintText: l.reasonForRemoval,
                        initialValue: state.removalReason,
                        onChanged: (value) {
                          spBloc.add(RemovalReasonChanged(value ?? ''));
                        },
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                    ],

                    if (state.fpMethod == 'Condom') ...[
                      CustomTextField(
                        labelText: l.quantityOfCondoms,
                        hintText: l.quantityOfCondoms,
                        keyboardType: TextInputType.number,
                        initialValue: state.condomQuantity,
                        onChanged: (value) {
                          spBloc.add(CondomQuantityChanged(value ?? ''));
                        },
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                    ],
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
