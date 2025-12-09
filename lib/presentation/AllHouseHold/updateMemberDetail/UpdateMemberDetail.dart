import 'dart:convert';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart' show Route_Names;
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/utils/Validations.dart' show Validations;
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import 'bloc/update_member_detail_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class UpdateMemberDetailScreen extends StatefulWidget {
  final int memberId;
  final String? hhId;

  const UpdateMemberDetailScreen({Key? key, required this.memberId, this.hhId})
    : super(key: key);

  @override
  State<UpdateMemberDetailScreen> createState() =>
      _UpdateMemberDetailScreenState();
}

class _UpdateMemberDetailScreenState extends State<UpdateMemberDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fatherOption = 'Select';
  String _motherOption = 'Select';
  late final UpdateMemberDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = UpdateMemberDetailBloc(databaseProvider: DatabaseProvider.instance);
    _bloc.add(UpdateMemberDetailInitialEvent(widget.memberId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Widget _section(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 4), child: child);
  void _handleAbhaProfileResult(Map<String, dynamic> profile, BuildContext context) {
    debugPrint("ABHA Profile Received in Update Member Details: $profile");

    final bloc = context.read<UpdateMemberDetailBloc>();

    // 1. ABHA Address
    final abhaAddress = profile['abhaAddress']?.toString().trim();
    if (abhaAddress != null && abhaAddress.isNotEmpty) {
      bloc.add(UpdateMemberDetailAbhaAddressChanged(abhaAddress));
    }

    // 2. Full Name
    final nameParts = [
      profile['firstName'],
      profile['middleName'],
      profile['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
    if (nameParts.isNotEmpty) {
      bloc.add(UpdateMemberDetailNameChanged(nameParts.trim()));
    }

    // 3. DOB → Switch to DOB mode + fill
    try {
      final day = profile['dayOfBirth']?.toString();
      final month = profile['monthOfBirth']?.toString();
      final year = profile['yearOfBirth']?.toString();
      if (day != null && month != null && year != null) {
        final dob = DateTime(int.parse(year), int.parse(month), int.parse(day));
        bloc.add(const UpdateMemberDetailToggleUseDob());
        bloc.add(UpdateMemberDetailDobChanged(dob));
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
      bloc.add(UpdateMemberDetailGenderChanged(gender));
    }

    // 5. Mobile Number + Owner = Self
    final mobile = profile['mobile']?.toString().trim();
    if (mobile != null && mobile.length == 10) {
      bloc.add(UpdateMemberDetailMobileNumberChanged(mobile));
      bloc.add(UpdateMemberDetailMobileOwnerChanged('Self'));
    }

    showAppSnackBar(context, "ABHA details updated successfully!");
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    _motherOption = l.select;
    _fatherOption = l.select;
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<UpdateMemberDetailBloc, UpdateMemberDetailState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member updated successfully')),
            );
            Navigator.of(context).pop(true);
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: WillPopScope(
          onWillPop: () async {
            if (_bloc.state.isSubmitting) return false;
            final shouldExit = await showConfirmationDialog(
              context: context,
              title: l.confirmAttentionTitle,
              message: l.confirmCloseFormMsg,
              yesText: l.yes,
              noText: l.confirmNo,
            );
            return shouldExit ?? false;
          },
          child: Scaffold(
            appBar: AppHeader(
              screenTitle: l.updateMemberDetails ?? 'Update Member Details',
              showBack: true,
              onBackTap: () async {
                if (_bloc.state.isSubmitting) return;
                final shouldExit = await showConfirmationDialog(
                  context: context,
                  title: l.confirmAttentionTitle,
                  message: l.confirmCloseFormMsg,
                  yesText: l.confirmYes,
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
                    child: Form(
                      key: _formKey,
                      child: BlocBuilder<UpdateMemberDetailBloc, UpdateMemberDetailState>(
                        builder: (context, state) {
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                            children: [
                              // Member Type
                              _section(
                                ApiDropdown<String>(
                                  labelText: '${l.memberTypeLabel} *',
                                  items: const ['Adult', 'Child'],
                                  getLabel: (s) {
                                    switch (s) {
                                      case 'Adult':
                                        return l.memberTypeAdult;
                                      case 'Child':
                                        return l.memberTypeChild;
                                      default:
                                        return s;
                                    }
                                  },
                                  value: state.memberType,
                                  onChanged: (v) {
                                    if (v != null) {
                                      context
                                          .read<UpdateMemberDetailBloc>()
                                          .add(
                                            UpdateMemberDetailMemberTypeChanged(
                                              v,
                                            ),
                                          );
                                      // Clear marital status when changing to Child
                                      if (v == 'Child') {
                                        context.read<UpdateMemberDetailBloc>().add(
                                          const UpdateMemberDetailMaritalStatusChanged(
                                            '',
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  validator: (value) =>
                                      Validations.validateMemberType(l, value),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // RICH ID for Child
                              if (state.memberType == 'Child') ...[
                                _section(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: l.richId ?? "RICH ID",
                                              hintText: l.richId ?? 'RICH ID',
                                              initialValue: state.richID,
                                              onChanged: (v) {
                                                context
                                                    .read<
                                                      UpdateMemberDetailBloc
                                                    >()
                                                    .add(
                                                      UpdateMemberDetailRichIDChanged(
                                                        v ?? '',
                                                      ),
                                                    );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 30,
                                            child: RoundButton(
                                              title: l.verifyLabel ?? 'VERIFY',
                                              width: 100,
                                              borderRadius: 8,
                                              fontSize: 12,
                                              onPress: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  Route_Names.Abhalinkscreen,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                              ],

                              // Relation with Head
                              _section(
                                ApiDropdown<String>(
                                  labelText: '${l.relationWithHeadLabel} *',
                                  items: const [
                                    'Spouse',
                                    'Son',
                                    'Daughter',
                                    'Father',
                                    'Mother',
                                    'Brother',
                                    'Sister',
                                    'Other',
                                  ],
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailRelationChanged(
                                          v ?? '',
                                        ),
                                      ),
                                  validator: (value) =>
                                      Validations.validateFamilyHead(l, value),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Name
                              _section(
                                CustomTextField(
                                  labelText: '${l.nameOfMemberLabel} *',
                                  hintText: l.nameOfMemberHint,
                                  initialValue: state.name,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailNameChanged(v ?? ''),
                                      ),
                                  validator: (value) =>
                                      Validations.validateNameofMember(
                                        l,
                                        value,
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Mother's Name
                              _section(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ApiDropdown<String>(
                                      labelText: "${l.motherNameLabel} *",
                                      hintText: "${l.motherNameLabel} *",
                                      items: ['Select', 'Other'],
                                      getLabel: (s) => s,
                                      value: _motherOption,
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() {
                                          _motherOption = v;
                                        });
                                        if (v != 'Select' && v != 'Other') {
                                          context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                UpdateMemberDetailMotherNameChanged(
                                                  v,
                                                ),
                                              );
                                        } else {
                                          context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                const UpdateMemberDetailMotherNameChanged(
                                                  '',
                                                ),
                                              );
                                        }
                                      },
                                    ),
                                    if (_motherOption == 'Other')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: CustomTextField(
                                          labelText: l.motherNameLabel,
                                          hintText: l.motherNameLabel,
                                          initialValue: state.motherName,
                                          onChanged: (v) => context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                UpdateMemberDetailMotherNameChanged(
                                                  v ?? '',
                                                ),
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Father's Name
                              _section(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ApiDropdown<String>(
                                      labelText:
                                          '${l.fatherGuardianNameLabel} *',
                                      items: ['Select', 'Other'],
                                      getLabel: (s) => s,
                                      value: _fatherOption,
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() {
                                          _fatherOption = v;
                                        });
                                        if (v != 'Select' && v != 'Other') {
                                          context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                UpdateMemberDetailFatherNameChanged(
                                                  v,
                                                ),
                                              );
                                        } else {
                                          context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                const UpdateMemberDetailFatherNameChanged(
                                                  '',
                                                ),
                                              );
                                        }
                                      },
                                      validator: (_) {
                                        if (_fatherOption == 'Select')
                                          return l.select;
                                        return null;
                                      },
                                    ),
                                    if (_fatherOption == 'Other')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: CustomTextField(
                                          labelText: l.fatherGuardianNameLabel,
                                          hintText: l.fatherGuardianNameLabel,
                                          initialValue: state.fatherName,
                                          onChanged: (v) => context
                                              .read<UpdateMemberDetailBloc>()
                                              .add(
                                                UpdateMemberDetailFatherNameChanged(
                                                  v ?? '',
                                                ),
                                              ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? l.requiredField
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Gender
                              _section(
                                ApiDropdown<String>(
                                  labelText: '${l.genderLabel} *',
                                  items: const [
                                    'Male',
                                    'Female',
                                    'Transgender',
                                  ],
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailGenderChanged(
                                          v ?? '',
                                        ),
                                      ),
                                  validator: (value) =>
                                      Validations.validateGender(l, value),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Whose Mobile
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
                                      case 'Family Head':
                                        return l.headOfFamily;
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailMobileOwnerChanged(
                                          v ?? '',
                                        ),
                                      ),
                                  validator: (value) =>
                                      Validations.validateWhoMobileNo(l, value),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Mobile Number
                              _section(
                                CustomTextField(
                                  key: ValueKey(
                                    'member_mobile_${state.mobileOwner ?? ''}',
                                  ),
                                  controller:
                                      TextEditingController(
                                          text: state.mobileNumber ?? '',
                                        )
                                        ..selection = TextSelection.collapsed(
                                          offset:
                                              state.mobileNumber?.length ?? 0,
                                        ),
                                  hintText: '${l.mobileLabel} *',
                                  labelText: '${l.mobileLabel} *',
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  onChanged: (value) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailMobileNumberChanged(
                                          value ?? '',
                                        ),
                                      ),
                                  validator: (value) =>
                                      Validations.validateMobileNo(l, value),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // DOB or Age Toggle
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Radio<bool>(
                                      value: true,
                                      groupValue: state.useDob,
                                      onChanged: (_) => context
                                          .read<UpdateMemberDetailBloc>()
                                          .add(
                                            const UpdateMemberDetailToggleUseDob(),
                                          ),
                                    ),
                                    Text(l.dobShort),
                                    const SizedBox(width: 16),
                                    Radio<bool>(
                                      value: false,
                                      groupValue: state.useDob,
                                      onChanged: (_) => context
                                          .read<UpdateMemberDetailBloc>()
                                          .add(
                                            const UpdateMemberDetailToggleUseDob(),
                                          ),
                                    ),
                                    Text(l.ageApproximate),
                                  ],
                                ),
                              ),

                              // Date of Birth or Age Fields
                              if (state.useDob ?? true)
                                _section(
                                  CustomDatePicker(
                                    labelText: '${l.dobLabel} *',
                                    hintText: l.dateHint,
                                    initialDate:
                                        state.dob ??
                                        DateTime.now().subtract(
                                          const Duration(days: 365 * 20),
                                        ),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    onDateChanged: (date) {
                                      if (date != null) {
                                        context
                                            .read<UpdateMemberDetailBloc>()
                                            .add(
                                              UpdateMemberDetailDobChanged(
                                                date,
                                              ),
                                            );
                                      }
                                    },
                                    validator: (date) =>
                                        Validations.validateDOB(l, date),
                                  ),
                                )
                              else
                                _section(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: 1.h,
                                          left: 1.3.h,
                                        ),
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
                                              labelText:
                                                  l.yearsSuffix ?? 'Years',
                                              hintText:
                                                  l.yearsSuffix ?? 'Years',
                                              initialValue:
                                                  state.updateYear ?? '',
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (v) => context
                                                  .read<
                                                    UpdateMemberDetailBloc
                                                  >()
                                                  .add(
                                                    UpdateMemberDetailYearChanged(
                                                      v ?? '',
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 4.h,
                                            color: Colors.grey.shade300,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 1.w,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: l.months ?? 'Months',
                                              hintText: l.months ?? 'Months',
                                              initialValue:
                                                  state.updateMonth ?? '',
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (v) => context
                                                  .read<
                                                    UpdateMemberDetailBloc
                                                  >()
                                                  .add(
                                                    UpdateMemberDetailMonthChanged(
                                                      v ?? '',
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 4.h,
                                            color: Colors.grey.shade300,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 1.w,
                                            ),
                                          ),
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: l.days ?? 'Days',
                                              hintText: l.days ?? 'Days',
                                              initialValue:
                                                  state.updateDay ?? '',
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (v) => context
                                                  .read<
                                                    UpdateMemberDetailBloc
                                                  >()
                                                  .add(
                                                    UpdateMemberDetailDayChanged(
                                                      v ?? '',
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Birth Order
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailBirthOrderChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Child-specific fields
                              if (state.memberType == 'Child') ...[
                                _section(
                                  CustomTextField(
                                    labelText:
                                        l.weightRange ?? 'Weight (1.2-90)Kg',
                                    keyboardType: TextInputType.number,
                                    initialValue: state.weight,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailWeightChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                _section(
                                  ApiDropdown<String>(
                                    labelText:
                                        l.isBirthCertificateIssued ??
                                        'is birth certificate issued?',
                                    items: const ['Yes', 'No'],
                                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                    value: state.birthCertificate,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailBirthCertificateChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                _section(
                                  ApiDropdown<String>(
                                    labelText:
                                        l.isSchoolGoingChild ??
                                        'is He/She school going child',
                                    items: const ['Yes', 'No'],
                                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                    value: state.childSchool,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailChildSchoolChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                              ],

                              // Religion
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailReligionChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Category
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailCategoryChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // ABHA Address
                              _section(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextField(
                                            labelText: l.abhaAddressLabel,
                                            hintText: l.abhaAddressLabel,
                                            initialValue: state.abhaAddress,
                                            onChanged: (v) => context
                                                .read<UpdateMemberDetailBloc>()
                                                .add(
                                                  UpdateMemberDetailAbhaAddressChanged(
                                                    v ?? '',
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 30,
                                          child: RoundButton(
                                            title: l.linkAbha,
                                            width: 140,
                                            borderRadius: 8,
                                            fontSize: 12,
                                            onPress: () async {
                                              final result = await Navigator.pushNamed(
                                                context,
                                                Route_Names.Abhalinkscreen,
                                              );

                                              debugPrint("BACK FROM ABHA (Update Member)");
                                              debugPrint("RESULT: $result");

                                              if (result is Map<String, dynamic> && mounted) {
                                                _handleAbhaProfileResult(result, context);
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Bank Account
                              _section(
                                CustomTextField(
                                  labelText: l.accountNumberLabel,
                                  hintText: l.accountNumberLabel,
                                  keyboardType: TextInputType.number,
                                  initialValue: state.bankAccount,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailBankAccountChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // IFSC Code
                              _section(
                                CustomTextField(
                                  labelText: l.ifscLabel,
                                  hintText: l.ifscLabel,
                                  initialValue: state.ifsc,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailIfscChanged(v ?? ''),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Adult-specific fields
                              if (state.memberType == 'Adult') ...[
                                _section(
                                  ApiDropdown<String>(
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
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailOccupationChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
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
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailEducationChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                              ],

                              // IDs
                              _section(
                                CustomTextField(
                                  labelText: l.voterIdLabel,
                                  hintText: l.voterIdLabel,
                                  initialValue: state.voterId,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailVoterIdChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              _section(
                                CustomTextField(
                                  labelText: l.rationCardIdLabel,
                                  hintText: l.rationCardIdLabel,
                                  initialValue: state.rationId,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailRationIdChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              _section(
                                CustomTextField(
                                  labelText: l.personalHealthIdLabel,
                                  hintText: l.personalHealthIdLabel,
                                  initialValue: state.phId,
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailPhIdChanged(v ?? ''),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Beneficiary Type
                              _section(
                                ApiDropdown<String>(
                                  labelText: l.beneficiaryTypeLabel,
                                  items: const [
                                    'StayingInHouse',
                                    'SeasonalMigrant',
                                  ],
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
                                  onChanged: (v) => context
                                      .read<UpdateMemberDetailBloc>()
                                      .add(
                                        UpdateMemberDetailBeneficiaryTypeChanged(
                                          v ?? '',
                                        ),
                                      ),
                                ),
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              // Marital Status (only for Adult)
                              if (state.memberType != 'Child')
                                _section(
                                  ApiDropdown<String>(
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
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailMaritalStatusChanged(
                                            v ?? '',
                                          ),
                                        ),
                                    validator: (value) =>
                                        Validations.validateMaritalStatus(
                                          l,
                                          value,
                                        ),
                                  ),
                                ),
                              if (state.memberType != 'Child')
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                              // Married-specific fields
                              if (state.maritalStatus == 'Married') ...[
                                _section(
                                  CustomTextField(
                                    labelText: l.ageAtMarriageLabel,
                                    hintText: l.ageAtMarriageHint,
                                    keyboardType: TextInputType.number,
                                    initialValue: state.ageAtMarriage,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailAgeAtMarriageChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                _section(
                                  CustomTextField(
                                    labelText: '${l.spouseNameLabel} *',
                                    hintText: l.spouseNameHint,
                                    initialValue: state.spouseName,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailSpouseNameChanged(
                                            v ?? '',
                                          ),
                                        ),
                                    validator: (value) =>
                                        Validations.validateSpousName(l, value),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                _section(
                                  ApiDropdown<String>(
                                    labelText: l.haveChildrenQuestion,
                                    items: const ['Yes', 'No'],
                                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                    value: state.hasChildren,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailHasChildrenChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                _section(
                                  ApiDropdown<String>(
                                    labelText: '${l.isWomanPregnantQuestion} *',
                                    items: const ['Yes', 'No'],
                                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                    value: state.isPregnant,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailIsPregnantChanged(
                                            v ?? '',
                                          ),
                                        ),
                                    validator: (value) =>
                                        Validations.validateIsPregnant(
                                          l,
                                          value,
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                              ] else if (state.maritalStatus != null &&
                                  [
                                    'Widowed',
                                    'Separated',
                                    'Divorced',
                                  ].contains(state.maritalStatus)) ...[
                                _section(
                                  CustomTextField(
                                    labelText: l.haveChildrenQuestion,
                                    hintText: l.haveChildrenQuestion,
                                    keyboardType: TextInputType.text,
                                    initialValue: state.children,
                                    onChanged: (v) => context
                                        .read<UpdateMemberDetailBloc>()
                                        .add(
                                          UpdateMemberDetailChildrenChanged(
                                            v ?? '',
                                          ),
                                        ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                              ],

                              if (state.errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Text(
                                    state.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  // Submit Button
                  BlocBuilder<UpdateMemberDetailBloc, UpdateMemberDetailState>(
                    builder: (context, state) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: RoundButton(
                          title: state.isSubmitting
                              ? (l.saving ?? 'Saving...')
                              : (l.finalizeSave ?? 'Save'),
                          onPress: state.isSubmitting
                              ? () {}
                              : () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    context.read<UpdateMemberDetailBloc>().add(
                                      const UpdateMemberDetailSubmitEvent(),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l.correctHighlightedErrors ??
                                              'Please correct the highlighted errors before continuing.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                          isLoading: state.isSubmitting,
                        ),
                      );
                    },
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
