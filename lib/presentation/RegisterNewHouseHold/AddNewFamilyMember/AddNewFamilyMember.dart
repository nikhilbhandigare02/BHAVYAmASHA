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
import '../../../core/utils/enums.dart';
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'bloc/addnewfamilymember_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class AddNewFamilyMemberScreen extends StatefulWidget {
  final bool isEdit;
  final String? headName;
  final String? spouseName;
  final String? headGender; // 'Male' | 'Female' | 'Other'
  final String? headMobileNo;
  const AddNewFamilyMemberScreen({super.key, this.isEdit = false, this.headName, this.spouseName, this.headGender, this.headMobileNo});

  @override
  State<AddNewFamilyMemberScreen> createState() => _AddNewFamilyMemberScreenState();
}

class _AddNewFamilyMemberScreenState extends State<AddNewFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _argsHandled = false;
  String _fatherOption = 'Other';
  String _motherOption = 'Other';

  int _ageFromDob(DateTime dob) => DateTime.now().year - dob.year;

  Widget _section(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 4), child: child);

  @override
  void initState() {
    super.initState();
    // Initialize parent dropdowns with derived names if available so textfields stay hidden until 'Other' is selected
    final String? maleParentName = (widget.headGender == 'Male')
        ? widget.headName
        : ((widget.headGender == 'Female') ? widget.spouseName : (widget.headName ?? widget.spouseName));
    final String? femaleParentName = (widget.headGender == 'Female')
        ? widget.headName
        : ((widget.headGender == 'Male') ? widget.spouseName : widget.spouseName ?? widget.headName);

    _fatherOption = (maleParentName != null && maleParentName.isNotEmpty) ? maleParentName : 'Other';
    _motherOption = (femaleParentName != null && femaleParentName.isNotEmpty) ? femaleParentName : 'Other';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<AddnewfamilymemberBloc>();
      if (_fatherOption != 'Other') {
        bloc.add(AnmUpdateFatherName(_fatherOption));
      }
      if (_motherOption != 'Other') {
        bloc.add(AnmUpdateMotherName(_motherOption));
      }
    });
  }

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
    // Derive parent names from head/spouse and headGender
    final String? maleParentName = (widget.headGender == 'Male') ? widget.headName : ((widget.headGender == 'Female') ? widget.spouseName : (widget.headName ?? widget.spouseName));
    final String? femaleParentName = (widget.headGender == 'Female') ? widget.headName : ((widget.headGender == 'Male') ? widget.spouseName : widget.spouseName ?? widget.headName);
    return BlocProvider(
      create: (_) => AddnewfamilymemberBloc(),
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
        child: Scaffold(
          appBar: AppHeader(
            screenTitle: l.newMemberDetailsTitle,
            showBack: true,
            onBackTap: () async {
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
                          if (state.memberType == 'Child') ...[
                            _section(
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      labelText: l.richIdLabel,
                                      initialValue: state.RichIDChanged,
                                      onChanged: (v) =>
                                          context.read<AddnewfamilymemberBloc>().add(RichIDChanged(v.trim())
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
                          // Relation with head
                          _section(
                            ApiDropdown<String>(
                              labelText: '${l.relationWithHeadLabel} *',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ApiDropdown<String>(
                                  labelText: "${l.motherNameLabel} *",
                                  items: [
                                    'Other',
                                    if ((femaleParentName ?? '').isNotEmpty) femaleParentName!,
                                  ],
                                  getLabel: (s) => s,
                                  value: _motherOption,
                                  onChanged: (v) {
                                    setState(() {
                                      _motherOption = v ?? 'Other';
                                    });
                                    if (v != null && v != 'Other') {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(v));
                                    } else {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(''));
                                    }
                                  },
                                ),
                                if (_motherOption == 'Other')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: CustomTextField(
                                      labelText: l.motherNameLabel,
                                      onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(v.trim())),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          _section(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ApiDropdown<String>(
                                  labelText: '${l.fatherGuardianNameLabel} *',
                                  items: [
                                    'Other',
                                    if ((maleParentName ?? '').isNotEmpty) maleParentName!,
                                  ],
                                  getLabel: (s) => s,
                                  value: _fatherOption,
                                  onChanged: (v) {
                                    setState(() {
                                      _fatherOption = v ?? 'Other';
                                    });
                                    if (v != null && v != 'Other') {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(v));
                                    } else {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(''));
                                    }
                                  },
                                  validator: (_) {
                                    // If 'Other', ensure user inputs a name below via textfield
                                    if (_fatherOption == 'Other') return null; // textfield below has its own validator
                                    return null;
                                  },
                                ),
                                if (_fatherOption == 'Other')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: CustomTextField(
                                      labelText: l.fatherGuardianNameLabel,
                                      onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(v.trim())),
                                      validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          // Gender
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateGender(v!)),
                              validator: (value) => Validations.validateGender(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          // Mobile
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
                              onChanged: (v) {
                                if (v == null) return;
                                final bloc = context.read<AddnewfamilymemberBloc>();
                                bloc.add(AnmUpdateMobileOwner(v));
                                if (v == 'Family Head') {
                                  final headNo = widget.headMobileNo ?? '';
                                  if (headNo.isNotEmpty) {
                                    bloc.add(AnmUpdateMobileNo(headNo));
                                  }
                                }
                              },
                              validator: (value) => Validations.validateWhoMobileNo(l, value),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(
                            CustomTextField(
                              key: ValueKey('member_mobile_${state.mobileNo ?? ''}'),
                              labelText: '${l.mobileLabel} *',
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              initialValue: state.mobileNo,
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileNo(v.trim())),
                              validator: (value) => Validations.validateMobileNo(l, value),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
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
                                          initialValue: state.updateYear ?? '',
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateYearChanged(v.trim())),
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
                                          initialValue: state.updateMonth ?? '',
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateMonthChanged(v.trim())),
                                        ),
                                      ),

                                      // --- Divider between Months & Days ---
                                      Container(
                                        width: 1,
                                        height: 4.h,
                                        color: Colors.grey.shade300,
                                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                                      ),

                                      Expanded(
                                        child: CustomTextField(
                                          labelText: 'Days',
                                          hintText: 'Days',
                                          initialValue: state.updateDay ?? '',
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateDayChanged(v.trim())),
                                        ),
                                      ),
                                    ],
                                  )

                                ],
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


                          if(state.memberType == 'Child')...[
                            _section(
                              CustomTextField(
                                labelText: 'Weight (1.2-90)Kg',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(WeightChange(v.trim())),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            _section(
                              ApiDropdown<String>(
                                labelText: 'is birth certificate issued?',
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
                                value: state.BirthCertificateChange,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(BirthCertificateChange(v!)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            _section(
                              ApiDropdown<String>(
                                labelText: 'is He/She school going child',
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
                                value: state.occupation,
                                onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(ChildSchoolChange(v!)),
                              ),
                            ),
                          ],
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateReligion(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateCategory(v!)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),_section(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        labelText: l.abhaAddressLabel,
                                        initialValue: state.abhaAddress,
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmUpdateAbhaAddress(v.trim())),
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
                                        onPress: () {
                                          Navigator.pushNamed(context, Route_Names.Abhalinkscreen);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                      if (state.memberType == 'Adult') ...[
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
                            onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateOccupation(v!)),
                          ),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
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
                            onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateEducation(v!)),
                          ),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                      ],

                          // IDs
                          _section(CustomTextField(labelText: l.voterIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateVoterId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(CustomTextField(labelText: l.rationCardIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateRationId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          _section(CustomTextField(labelText: l.personalHealthIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdatePhId(v.trim())),)),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

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
                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBeneficiaryType(v!)),

                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          if(state.memberType== 'Adult')...[
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
                          ],


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
                              ['Widowed', 'Separated', 'Divorced']
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
                    final Map<String, dynamic> result = state.toJson();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.of(context).pop<Map<String, dynamic>>(result);
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

