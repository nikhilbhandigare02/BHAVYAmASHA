import 'dart:convert';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart' show Route_Names;
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/utils/Validations.dart' show Validations;
import '../../../core/utils/enums.dart';
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'bloc/addnewfamilymember_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show MultiBlocProvider;
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/SpousDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/bloc/spous_bloc.dart' hide RichIDChanged;
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/ChildrenDetaills.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/bloc/children_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart' hide ChildrenChanged;
import 'package:medixcel_new/l10n/app_localizations.dart';

class AddNewFamilyMemberScreen extends StatefulWidget {
  final bool isEdit;
  final String? hhId;
  final String? headName;
  final String? headGender;
  final String? spouseName;
  final String? spouseGender;

  const AddNewFamilyMemberScreen({
    super.key,
    this.isEdit = false,
    this.hhId,
    this.headName,
    this.headGender,
    this.spouseName,
    this.spouseGender,
  });

  @override
  State<AddNewFamilyMemberScreen> createState() => _AddNewFamilyMemberScreenState();
}

class _AddNewFamilyMemberScreenState extends State<AddNewFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _argsHandled = false;
  // When true, this screen was opened directly from AllBeneficiary or
  // HouseHold_Beneficiery and member details should be saved/updated
  // immediately on the Add button. When false, data is returned to the
  // RegisterNewHouseHold flow and persisted on its final Save button.
  bool _isMemberDetails = false;
  String _fatherOption = 'Select';
  String _motherOption = 'Select';
  int _currentStep = 0; // 0: member, 1: spouse, 2: children
  bool _tabListenerAttached = false;
  bool _syncingGender = false;

  // Collects the first validation error message for the member step
  // so the Next/Add button can show it in a SnackBar.
  static String? _anmLastFormError;

  static void _clearAnmFormError() {
    _anmLastFormError = null;
  }

  static String? _captureAnmError(String? message) {
    if (message != null && _anmLastFormError == null) {
      _anmLastFormError = message;
    }
    return message;
  }

  String? _headName;
  String? _headGender;
  String? _spouseName;
  String? _spouseGender;

  List<String> _maleAdultNames = [];
  List<String> _femaleAdultNames = [];

  int _ageFromDob(DateTime dob) => DateTime.now().year - dob.year;

  Widget _section(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 4), child: child);

  late final AddnewfamilymemberBloc _bloc;
  late final SpousBloc _spousBloc;
  late final ChildrenBloc _childrenBloc;
  late final AddFamilyHeadBloc _dummyHeadBloc;

  // Form controllers
  bool _isLoading = false;
  bool _isFirstLoad = true;

  // Controllers for form fields
  final TextEditingController _memberTypeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _maritalStatusController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _beneficiaryTypeController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _memberStatusController = TextEditingController();

  String _formatGender(String? gender) {
    if (gender == null) return 'Other';
    final g = gender.toString().toLowerCase();
    if (g == 'm' || g == 'male') return 'Male';
    if (g == 'f' || g == 'female') return 'Female';
    return 'Other';
  }

  String _oppositeGender(String? gender) {
    final g = _formatGender(gender);
    if (g == 'Male') return 'Female';
    if (g == 'Female') return 'Male';
    return 'Other';
  }
  Future<void> _loadBeneficiaryData(String beneficiaryId) async {
    try {
      // Load beneficiary data through bloc
      _bloc.add(LoadBeneficiaryData(beneficiaryId));

      // Show loading indicator
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Hide loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading beneficiary data: $e')),
        );
      }
    }
  }

    @override
  void initState() {
    super.initState();
    _bloc = AddnewfamilymemberBloc();
    _spousBloc = SpousBloc();
    _childrenBloc = ChildrenBloc();
    _dummyHeadBloc = AddFamilyHeadBloc();

    print('HHID passed to AddNewFamilyMember: ${widget.hhId}');

    _fatherOption = 'Select';
    _motherOption = 'Select';

    _headName = widget.headName;
    _headGender = widget.headGender;
    _spouseName = widget.spouseName;
    _spouseGender = widget.spouseGender;

    print('=== RECEIVED HOUSEHOLD DATA ===');
    print('Head: $_headName ($_headGender)');
    print('Spouse: $_spouseName ($_spouseGender)');
    print('==============================');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final hh = widget.hhId?.toString() ?? '';
        if (hh.isNotEmpty) {
          final rows = await LocalStorageDao.instance.getBeneficiariesByHousehold(hh);
          final male = <String>{};
          final female = <String>{};
          for (final row in rows) {
            final isAdult = (row['is_adult'] is num) ? (row['is_adult'] as num).toInt() == 1 : false;
            if (!isAdult) continue;
            dynamic infoRaw = row['beneficiary_info'];
            Map<String, dynamic> info;
            if (infoRaw is Map<String, dynamic>) {
              info = infoRaw;
            } else if (infoRaw is String && infoRaw.isNotEmpty) {
              try {
                info = Map<String, dynamic>.from(jsonDecode(infoRaw));
              } catch (_) {
                info = {};
              }
            } else {
              info = {};
            }
            final g = _formatGender(info['gender']?.toString());
            final name = (info['memberName'] ?? info['headName'] ?? info['name'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            if (g == 'Male') {
              male.add(name);
            } else if (g == 'Female') {
              female.add(name);
            }
          }
          setState(() {
            _maleAdultNames = male.toList();
            _femaleAdultNames = female.toList();
            if ((_headName == null || _headName!.isEmpty) && _maleAdultNames.isNotEmpty) {
              _headName = _maleAdultNames.first;
              _headGender = 'Male';
            }
            if ((_spouseName == null || _spouseName!.isEmpty) && _femaleAdultNames.isNotEmpty) {
              _spouseName = _femaleAdultNames.first;
              _spouseGender = 'Female';
            }
          });
        }
      } catch (_) {}

      // Handle beneficiary data loading if in edit mode
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['isBeneficiary'] == true && args['beneficiaryId'] != null) {
        await _loadBeneficiaryData(args['beneficiaryId']);
      }

      if (_fatherOption != 'Other') {
        _bloc.add(AnmUpdateFatherName(_fatherOption));
      }
      if (_motherOption != 'Other') {
        _bloc.add(AnmUpdateMotherName(_motherOption));
      }
    });
  }


  void _updateParentNames(String relation) {
    // Determine father and mother based on head and spouse
    String? fatherName;
    String? motherName;

    if (_maleAdultNames.isNotEmpty) {
      fatherName = _maleAdultNames.first;
    }
    if (_femaleAdultNames.isNotEmpty) {
      motherName = _femaleAdultNames.first;
    }
    if (fatherName == null) {
      if (_headGender == 'Male') {
        fatherName = _headName;
      } else if (_spouseGender == 'Male') {
        fatherName = _spouseName;
      }
    }
    if (motherName == null) {
      if (_headGender == 'Female') {
        motherName = _headName;
      } else if (_spouseGender == 'Female') {
        motherName = _spouseName;
      }
    }

    if (relation == 'Father' && fatherName != null) {
      setState(() {
        _fatherOption = fatherName!;
      });
      _bloc.add(AnmUpdateFatherName(fatherName));
    } else if (relation == 'Mother' && motherName != null) {
      setState(() {
        _motherOption = motherName!;
      });
      _bloc.add(AnmUpdateMotherName(motherName));
    }
  }

  @override
  void dispose() {
    // Close all BLoCs
    _bloc.close();
    _spousBloc.close();
    _childrenBloc.close();
    _dummyHeadBloc.close();

    // Dispose all controllers
    _memberTypeController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _religionController.dispose();
    _categoryController.dispose();
    _beneficiaryTypeController.dispose();
    _relationController.dispose();
    _memberStatusController.dispose();

    super.dispose();
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

        // Standalone member details flow (from AllBeneficiary or
        // HouseHold_Beneficiery) sets this flag so we save immediately
        // on Add button.
        final dynamic memberFlag = args['isMemberDetails'];
        _isMemberDetails = memberFlag == true;

        // Use relation passed from previous screen to prefill relation dropdown.
        final relArg = args['relation']?.toString().trim();
        if (relArg != null && relArg.isNotEmpty) {
          String normalized;
          final rl = relArg.toLowerCase();
          if (rl == 'Head' || rl == 'self') {
            normalized = 'Self';
          } else {
            normalized = relArg;
          }
          // Directly update bloc so that dropdown shows correct initial value.
          _bloc.add(AnmUpdateRelation(normalized));
        }
      } else if (args is bool) {
        _isEdit = args == true;
      }
      _argsHandled = true;
    }
    _isEdit = _isEdit || widget.isEdit;
    final bool hideFamilyTabs = _isEdit;
    final int tabCount = hideFamilyTabs ? 1 : 3;
    return DefaultTabController(
      length: tabCount,
      initialIndex: _currentStep.clamp(0, tabCount - 1),
      child: MultiBlocProvider(
      providers: [
        BlocProvider<AddnewfamilymemberBloc>.value(value: _bloc),
        BlocProvider<SpousBloc>.value(value: _spousBloc),
        BlocProvider<ChildrenBloc>.value(value: _childrenBloc),
        BlocProvider<AddFamilyHeadBloc>.value(value: _dummyHeadBloc),
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
              child: MultiBlocListener(
                listeners: [
                  BlocListener<SpousBloc, SpousState>(
                    listenWhen: (p, c) => p.gender != c.gender,
                    listener: (context, sp) {
                      if (_syncingGender) return;
                      _syncingGender = true;
                      try {
                        final desired = _oppositeGender(sp.gender);
                        final mb = context.read<AddnewfamilymemberBloc>();
                        if (mb.state.gender != desired) {
                          mb.add(AnmUpdateGender(desired));
                        }
                      } finally {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _syncingGender = false;
                        });
                      }
                    },
                  ),
                  BlocListener<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                    listenWhen: (p, c) => p.spouseName != c.spouseName,
                    listener: (context, st) {
                      final name = (st.spouseName ?? '').trim();
                      if (name.isEmpty) return;
                      final spBloc = context.read<SpousBloc>();
                      if ((spBloc.state.memberName ?? '') != name) {
                        spBloc.add(SpUpdateMemberName(name));
                      }
                    },
                  ),
                ],
                child: Column(
                children: [
                  // Top Tabs
                  SizedBox(
                    height: 44,
                    child: Builder(
                      builder: (ctx) {
                        final ctrl = DefaultTabController.of(ctx);
                        if (!_tabListenerAttached && ctrl != null) {
                          _tabListenerAttached = true;
                          ctrl.addListener(() {
                            if (!mounted) return;
                            setState(() { _currentStep = ctrl.index; });
                          });
                        }
                        return BlocBuilder<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                          builder: (ctx2, st) {
                            final bool spouseAllowed = !hideFamilyTabs && st.memberType != 'Child' && st.maritalStatus == 'Married';
                            final bool childrenAllowed = !hideFamilyTabs && spouseAllowed && st.hasChildren == 'Yes';
                            final String firstTabTitle = (st.memberType == 'Child')
                                ? 'Child Details'
                                : 'Member Details';
                            Widget buildTabs(Widget tabBar) {
                              return Container(
                                color: AppColors.primary,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    indicatorColor: Colors.white,
                                    splashColor: Colors.white24,
                                  ),
                                  child: tabBar,
                                ),
                              );
                            }

                            if (hideFamilyTabs) {
                              return buildTabs(
                                TabBar(
                                  isScrollable: true,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white70,
                                  indicator: const UnderlineTabIndicator(
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                  ),
                                  tabs: [
                                    Tab(text: firstTabTitle),
                                  ],
                                ),
                              );
                            }
                            return buildTabs(
                              TabBar(
                                isScrollable: true,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white70,
                                indicator: const UnderlineTabIndicator(
                                  borderSide: BorderSide(color: Colors.white, width: 2),
                                ),
                                onTap: (i) {
                                final ctrl = DefaultTabController.of(ctx);
                                int target = i;
                                if (i == 1 && !spouseAllowed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Set Marital Status = Married to fill Spouse details.')),
                                  );
                                  target = 0;
                                } else if (i == 2 && !childrenAllowed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Select Have Children = Yes to fill Children details.')),
                                  );
                                  target = spouseAllowed ? 1 : 0;
                                }
                                setState(() { _currentStep = target; });
                                ctrl?.animateTo(target);
                              },
                                tabs: [
                                  Tab(text: firstTabTitle),
                                  Tab(child: Opacity(opacity: spouseAllowed ? 1.0 : 0.0, child: const Text('Spouse Details'))),
                                  Tab(child: Opacity(opacity: childrenAllowed ? 1.0 : 0.0, child: const Text('Children Details'))),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: BlocBuilder<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                        builder: (context, state) {
                          if (_currentStep == 1) {
                            return SizedBox.expand(child: Spousdetails());
                          }
                          if (_currentStep == 2) {
                            return SizedBox.expand(child: Childrendetaills());
                          }
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                            children: [
                              _section(
                                ApiDropdown<String>(
                                  labelText: l.memberTypeLabel,
                                  items: const ['Adult', 'Child', ],
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
                                    final bloc = context.read<AddnewfamilymemberBloc>();
                                    bloc.add(AnmUpdateMemberType(v ?? ''));
                                    // Clear marital status when changing to Child
                                    if (v == 'Child') {
                                      bloc.add(const AnmUpdateMaritalStatus(''));
                                      // Clear relation if it's 'Spouse' (not valid for children)
                                      if (state.relation == 'Spouse') {
                                        bloc.add(AnmUpdateRelation(''));
                                      }
                                    }
                                  },
                                  validator: (value) => _captureAnmError(Validations.validateMemberType(l, value)),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              if (state.mobileOwner == 'Other')
                                _section(
                                  CustomTextField(
                                    labelText: 'Relation with mobile holder *',
                                    hintText: 'Enter relation with mobile holder',
                                    initialValue: state.mobileOwnerRelation ?? '',
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileOwnerRelation(v.trim())),
                                  ),
                                ),
                              if (state.mobileOwner == 'Other')
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              // Member Status (only shown in edit mode)
                              if (_isEdit) ...[
                                _section(
                                  ApiDropdown<String>(
                                    labelText: 'Member Status *',
                                    items: const ['Alive', 'Death'],
                                    getLabel: (s) => s,
                                    value: state.memberStatus ?? 'Alive',
                                    onChanged: (v) {
                                      if (v != null) {
                                        context.read<AddnewfamilymemberBloc>().add(UpdateIsMemberStatus(v));
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select member status';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),                                if (state.memberStatus == 'Death') ...[
                                  _section(
                                    CustomDatePicker(
                                      labelText: 'Date of Death *',
                                      initialDate: state.dateOfDeath ?? DateTime.now(),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      onDateChanged: (date) {
                                        context.read<AddnewfamilymemberBloc>().add(UpdateDateOfDeath(date!));
                                      },
                                      validator: (value) {
                                        if (state.memberStatus == 'Death' && value == null) {
                                          return 'Please select date of death';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                  _section(
                                    CustomTextField(
                                      labelText: 'Place of Death *',
                                      hintText: 'Enter place of death',
                                      onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateDatePlace(v ?? '')),
                                      validator: (value) {
                                        if (state.memberStatus == 'Death' && (value == null || value.isEmpty)) {
                                          return 'Please enter place of death';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                  _section(
                                    ApiDropdown<String>(
                                      labelText: 'Reason of Death *',
                                      items: const [
                                        'Natural Causes',
                                        'Illness',
                                        'Accident',
                                        'Other',
                                      ],
                                      getLabel: (s) => s,
                                      value: state.deathReason,
                                      onChanged: (v) {
                                        if (v != null) {
                                          context.read<AddnewfamilymemberBloc>().add(UpdateReasonOfDeath(v));
                                        }
                                      },
                                      validator: (value) {
                                        if (state.memberStatus == 'Death' && (value == null || value.isEmpty)) {
                                          return 'Please select reason of death';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                  if (state.deathReason == 'Other')
                                    _section(
                                      CustomTextField(
                                        labelText: 'Specify Reason *',
                                        hintText: 'Enter reason of death',
                                        onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateOtherReasonOfDeath(v ?? '')),
                                        validator: (value) {
                                          if (state.memberStatus == 'Death' && state.deathReason == 'Other' && (value == null || value.isEmpty)) {
                                            return 'Please specify reason of death';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              ],

                              if (state.memberType == 'Child') ...[
                                _section(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: "RICH ID",
                                              hintText: 'RICH ID',
                                              initialValue: state.RichIDChanged,
                                              onChanged: (v) => context
                                                  .read<AddnewfamilymemberBloc>()
                                                  .add(RichIDChanged(v ?? '')),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            height: 30,
                                            child: RoundButton(
                                              title: 'VERIFY',
                                              width: 100,
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
                              ],

                              _section(
                                ApiDropdown<String>(
                                  labelText: '${l.relationWithHeadLabel} *',
                                  items: state.memberType == 'Child'
                                      ? const ['Father', 'Mother', 'Brother', 'Sister','Grand Father','Grand Mother', 'Other']
                                      : const [
                                    'Self',
                                    'Spouse',
                                    'Husband',
                                    'Son',
                                    'Daughter',
                                    'Father',
                                    'Mother',
                                    'Brother',
                                    'Sister',
                                    'Wife',
                                    'Nephew',
                                    'Niece',
                                    'Grand Father',
                                    'Grand Mother',
                                    'Father In Law',
                                    'Mother In Low',
                                    'Grand Son',
                                    'Grand Daughter',
                                    'Son In Law',
                                    'Daughter In Law',
                                    'Other',
                                  ],
                                  getLabel: (s) {
                                    switch (s) {
                                      case 'Self':
                                        return l.self;
                                      case 'Spouse':
                                        return l.relationSpouse;
                                      case 'Husband':
                                        return l.husbandLabel;
                                      case 'Wife':
                                        return l.wife;
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
                                      case 'Nephew':
                                        return l.relationNephew;
                                      case 'Niece':
                                        return l.relationNiece;
                                      case 'Grand Father':
                                        return l.relationGrandFather;
                                      case 'Grand Mother':
                                        return l.relationGrandMother;
                                      case 'Father In Law':
                                        return l.relationFatherInLaw;
                                      case 'Mother In Low': // check spelling Low → Law
                                        return l.relationMotherInLaw;
                                      case 'Grand Son':
                                        return l.relationGrandSon;
                                      case 'Grand Daughter':
                                        return l.relationGrandDaughter;
                                      case 'Son In Law':
                                        return l.relationSonInLaw;
                                      case 'Daughter In Law':
                                        return l.relationDaughterInLaw;
                                      case 'Other':
                                        return l.relationOther;
                                      default:
                                        return s;
                                    }
                                  },

                                  value: state.relation,
                                  onChanged: (v) {
                                    context.read<AddnewfamilymemberBloc>().add(AnmUpdateRelation(v ?? ''));
                                    // Auto-populate father/mother names based on relation
                                    if (state.memberType == 'Child' && (v == 'Father' || v == 'Mother')) {
                                      _updateParentNames(v!);
                                    }
                                  },
                                  validator: (value) => _captureAnmError(Validations.validateFamilyHeadRelation(l, value)),

                                ),
                              ),
                              if (state.relation == 'Other')
                                _section(
                                  CustomTextField(
                                    labelText: 'Enter Relation *',
                                    hintText: 'Enter Relation',
                                    initialValue: state.otherRelation ?? '',
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateOtherRelation(v.trim())),
                                  ),
                                ),
                              if (state.relation == 'Other')
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              // Name
                              _section(
                                CustomTextField(
                                  labelText: '${l.nameOfMemberLabel} *',
                                  hintText: l.nameOfMemberHint,
                                  initialValue: state.name ?? '',
                                  onChanged: (v) {
                                    final name = v.trim();
                                    context.read<AddnewfamilymemberBloc>().add(AnmUpdateName(name));
                                    // Auto-fill spouse details' spouseName with member name
                                    try {
                                      final spBloc = context.read<SpousBloc>();
                                      if ((spBloc.state.memberName ?? '') != name) {
                                        spBloc.add(SpUpdateSpouseName(name));
                                      }
                                    } catch (_) {}
                                  },
                                  validator: (value) => _captureAnmError(Validations.validateNameofMember(l, value)),

                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Builder(
                                        builder: (context) {
                                        final motherItems = [
                                          'Select',
                                          ..._femaleAdultNames,
                                          'Other',
                                        ];
                                        print('Mother dropdown items: $motherItems');
                                        print('Current mother option: $_motherOption');

                                        return ApiDropdown<String>(
                                          labelText: "${l.motherNameLabel} ",
                                          hintText: "${l.motherNameLabel} ",
                                          items: motherItems,
                                          getLabel: (s) => s,
                                          value: _motherOption,
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() {
                                              _motherOption = v;
                                            });
                                            if (v != 'Select' && v != 'Other') {
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(v));
                                            } else {
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(''));
                                            }
                                          },
                                        );
                                      },
                                      ),
                                    if (_motherOption == 'Other')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: CustomTextField(
                                          labelText: l.motherNameLabel,
                                          hintText: l.motherNameLabel,
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
                                      Builder(
                                        builder: (context) {
                                        final fatherItems = [
                                          'Select',
                                          ..._maleAdultNames,
                                          'Other',
                                        ];
                                        print('Father dropdown items: $fatherItems');
                                        print('Current father option: $_fatherOption');

                                        return ApiDropdown<String>(
                                          labelText: '${l.fatherGuardianNameLabel} ',
                                          items: fatherItems,
                                          getLabel: (s) => s,
                                          value: _fatherOption,
                                          onChanged: (v) {
                                            if (v == null) return;
                                            setState(() {
                                              _fatherOption = v;
                                            });
                                            if (v != 'Select' && v != 'Other') {
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(v));
                                            } else {
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(''));
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    if (_fatherOption == 'Other')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: CustomTextField(
                                          labelText: l.fatherGuardianNameLabel,
                                          hintText: l.fatherGuardianNameLabel,
                                          onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(v.trim())),
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
                                  onChanged: (v) {
                                    if (v == null) return;
                                    final memberGender = v;
                                    context.read<AddnewfamilymemberBloc>().add(AnmUpdateGender(memberGender));
                                    // Auto set spouse gender opposite
                                    try {
                                      if (_syncingGender) return;
                                      _syncingGender = true;
                                      final opposite = _oppositeGender(memberGender);
                                      final spBloc = context.read<SpousBloc>();
                                      if (spBloc.state.gender != opposite) {
                                        spBloc.add(SpUpdateGender(opposite));
                                      }
                                    } finally {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _syncingGender = false;
                                      });
                                    }
                                  },
                                  validator: (value) => _captureAnmError(Validations.validateGender(l, value)),

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
                                    if (v      == 'Family Head') {
                                      // final headNo = widget. ?? '';
                                      // if (headNo.isNotEmpty) {
                                      //   bloc.add(AnmUpdateMobileNo(headNo));
                                      // }
                                    }
                                  },
                                  validator: (value) => _captureAnmError(Validations.validateWhoMobileNo(l, value)),

                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(
                                CustomTextField(
                                  key: ValueKey('member_mobile_${state.mobileOwner ?? ''}'),
                                  controller: TextEditingController(text: state.mobileNo ?? '')
                                    ..selection = TextSelection.collapsed(offset: state.mobileNo?.length ?? 0),
                                  labelText: '${l.mobileLabel} *',
                                  hintText: '${l.mobileLabel} *',
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileNo(v.trim())),
                                  validator: (value) => _captureAnmError(Validations.validateMobileNo(l, value)),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
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
                                    initialDate: state.dob,
                                    labelText: '${l.dobLabel} *',
                                    hintText: l.dateHint,
                                    onDateChanged: (d) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateDob(d!)),
                                    validator: (date) {
                                      if (date == null) {
                                        return _captureAnmError('Date of birth is required');
                                      }

                                      final today = DateTime.now();
                                      final dobDate = DateTime(date.year, date.month, date.day);
                                      final todayDate = DateTime(today.year, today.month, today.day);

                                      if (dobDate.isAfter(todayDate)) {
                                        return _captureAnmError('Date of birth cannot be in the future');
                                      }

                                      // Apply the 1 day–15 years rule only when member type is Child
                                      final memberType = (state.memberType ?? '').trim().toLowerCase();
                                      if (memberType == 'child') {
                                        final diffDays = todayDate.difference(dobDate).inDays;

                                        const int minDays = 1;
                                        const int maxDays = 15 * 365;

                                        if (diffDays < minDays || diffDays > maxDays) {
                                          return _captureAnmError('For Child: Age should be between 1 day to 15 years.');
                                        }
                                      }

                                      // For adults, no extra age-range restriction beyond not-future
                                      return null;
                                    },

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
                                              hintText: '0',
                                              initialValue: state.updateYear ?? '',
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateYearChanged(v.trim())),
                                            ),
                                          ),

                                          // --- Divider between Years & Months ---
                                          // Container(
                                          //   width: 1,
                                          //   height: 4.h,
                                          //   color: Colors.grey.shade300,
                                          //   margin: EdgeInsets.symmetric(horizontal: 1.w),
                                          // ),

                                          // --- Months ---
                                          Expanded(
                                            child: CustomTextField(
                                              labelText: 'Months',
                                              hintText: '0',
                                              initialValue: state.updateMonth ?? '',
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateMonthChanged(v.trim())),
                                            ),
                                          ),

                                          // --- Divider between Months & Days ---
                                          // Container(
                                          //   width: 1,
                                          //   height: 4.h,
                                          //   color: Colors.grey.shade300,
                                          //   margin: EdgeInsets.symmetric(horizontal: 1.w),
                                          // ),

                                          Expanded(
                                            child: CustomTextField(
                                              labelText: 'Days',
                                              hintText: '0',
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
                                  items: const ['1', '2', '3', '4', '5','6','7','8','9','10'],
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
                                    hintText: 'Weight (1.2-90)Kg',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(WeightChange(v.trim())),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return _captureAnmError('Weight is required');
                                      }

                                      final parsed = double.tryParse(value.trim());
                                      if (parsed == null) {
                                        return _captureAnmError('Please enter a valid weight');
                                      }

                                      if (parsed < 1.2 || parsed > 90) {
                                        return _captureAnmError('Weight must be between 1.2 and 90 Kg');
                                      }

                                      return null;
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                _section(
                                  CustomTextField(
                                    labelText: 'Birth Weight (1200-4000)gms',
                                    hintText: 'Birth Weight (1200-4000)gms',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(BirthWeightChange(v?.trim() ?? '')),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return _captureAnmError('Birth weight is required');
                                      }

                                      final parsed = int.tryParse(value.trim());
                                      if (parsed == null) {
                                        return _captureAnmError('Please enter a valid birth weight');
                                      }

                                      if (parsed < 1200 || parsed > 4000) {
                                        return _captureAnmError('Birth weight must be between 1200 and 4000 gms');
                                      }

                                      return null;
                                    },
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
                                  onChanged: (v) {
                                    if (v == null) return;
                                    context.read<AddnewfamilymemberBloc>().add(AnmUpdateReligion(v));
                                  },
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              if (state.religion == 'Other')
                                _section(
                                  CustomTextField(
                                    labelText: 'Enter Religion',
                                    hintText: 'Enter Religion',
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateOtherReligion(v.trim())),
                                  ),
                                ),
                              if (state.religion == 'Other')
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
                                  onChanged: (v) {
                                    if (v == null) return;
                                    context.read<AddnewfamilymemberBloc>().add(AnmUpdateCategory(v));
                                  },
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              if (state.category == 'Other')
                                _section(
                                  CustomTextField(
                                    labelText: 'Enter Category',
                                    hintText: 'Enter Category',
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateOtherCategory(v.trim())),
                                  ),
                                ),
                              if (state.category == 'Other')
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),
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
                                  hintText: l.accountNumberLabel,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBankAcc(v.trim())),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(
                                CustomTextField(
                                  labelText: l.ifscLabel,
                                  hintText: l.ifscLabel,
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
                              _section(CustomTextField(labelText: l.voterIdLabel,hintText: l.voterIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateVoterId(v.trim())),)),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(CustomTextField(labelText: l.rationCardIdLabel, hintText: l.rationCardIdLabel,onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateRationId(v.trim())),)),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(CustomTextField(labelText: l.personalHealthIdLabel,hintText: l.personalHealthIdLabel, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdatePhId(v.trim())),)),
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
                              if(state.memberType != 'Child')
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
                                    onChanged: (v) {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateMaritalStatus(v!));
                                      // Reset step when marital status changes
                                      setState(() { _currentStep = 0; });
                                      final ctrl = DefaultTabController.of(context);
                                      ctrl?.animateTo(0);
                                    },
                                    validator: (value) {
                                      // Skip validation for children
                                      if (state.memberType == 'Child') return null;
                                      return _captureAnmError(Validations.validateMaritalStatus(l, value));
                                    },

                                  ),
                                ),
                              if(state.memberType != 'Child')
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                              // Spouse/Children conditional sections
                              if (!_isEdit && state.maritalStatus == 'Married') ...[
                                _section(
                                  CustomTextField(
                                    labelText: l.ageAtMarriageLabel,
                                    hintText: l.ageAtMarriageHint,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateAgeAtMarriage(v)),
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                if (!widget.isEdit) _section(
                                  CustomTextField(
                                    labelText: '${l.spouseNameLabel} *',
                                    hintText: l.spouseNameHint,
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateSpouseName(v.trim())),
                                    validator: (value) => _captureAnmError(Validations.validateSpousName(l, value)),
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                _section(
                                  ApiDropdown<String>(
                                    labelText: l.haveChildrenQuestion,
                                    items: const ['Yes', 'No'],
                                    getLabel: (s) => s == 'Yes' ? l.yes : l.no,
                                    value: state.hasChildren,
                                    onChanged: (v) {
                                      context.read<AddnewfamilymemberBloc>().add(AnmUpdateHasChildren(v!));
                                      setState(() { _currentStep = 0; });
                                      final ctrl = DefaultTabController.of(context);
                                      ctrl?.animateTo(0);
                                    },
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                              ]
                              else if (!_isEdit && state.maritalStatus != null &&
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
                              ],]

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
                        // Attach lightweight summary needed by the Register table
                        try {
                          // children: total number of children captured in ChildrenBloc
                          final ch = context.read<ChildrenBloc>().state;
                          result['children'] = ch.children.length;
                        } catch (_) {}
                        try {
                          // spouseName as captured in member state already; keep for table
                          if ((result['spouseName'] == null || (result['spouseName'] as String).isEmpty) &&
                              _spouseName != null && _spouseName!.isNotEmpty) {
                            result['spouseName'] = _spouseName;
                          }
                        } catch (_) {}
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

                            return Row(
                              mainAxisAlignment: _isEdit
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.spaceBetween,
                              children: [
                                if (!_isEdit) ...[
                                  if (_currentStep > 0)
                                    SizedBox(
                                      width: 120,
                                      height: 4.8.h,
                                      child: RoundButton(
                                        title: l.previousButton,
                                        color: AppColors.primary,
                                        borderRadius: 8,
                                        height: 4.9.h,
                                        isLoading: false,
                                        onPress: () {
                                          if (_currentStep > 0) {
                                            setState(() { _currentStep -= 1; });
                                            final ctrl = DefaultTabController.of(context);
                                            ctrl?.animateTo(_currentStep);
                                          }
                                        },
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                                SizedBox(
                                  width: 120,
                                  height: 4.9.h,
                                  child: RoundButton(
                                    title: () {
                                      if (isLoading) return (_isEdit ? 'UPDATING...' : l.addingButton);
                                      if (_isEdit) return 'UPDATE';
                                      final bool showSpouse = !_isEdit && state.memberType != 'Child' && state.maritalStatus == 'Married';
                                      final bool showChildren = !_isEdit && showSpouse && state.hasChildren == 'Yes';
                                      final lastStep = showChildren ? 2 : (showSpouse ? 1 : 0);
                                      return (_currentStep < lastStep) ? 'Next' : l.addButton;
                                    }(),
                                    color: AppColors.primary,
                                    borderRadius: 8,
                                    height: 44,
                                    isLoading: isLoading,
                                    onPress: () async {
                                      _clearAnmFormError();
                                      final formState = _formKey.currentState;
                                      if (formState == null) return;

                                      final isValid = formState.validate();
                                      if (!isValid) {
                                        final msg = _anmLastFormError ?? 'Please correct the highlighted errors before continuing.';
                                        showAppSnackBar(context, msg);
                                        return;
                                      }

                                      try {
                                        // Get current state
                                        final bloc = context.read<AddnewfamilymemberBloc>();
                                        final state = bloc.state;

                                        // Extra DOB safety check using bloc state to
                                        // ensure invalid DOB never passes even if the
                                        // DOB field widget is not currently mounted.
                                        if (state.useDob == true) {
                                          if (state.dob == null) {
                                            showAppSnackBar(context, 'Date of birth is required');
                                            return;
                                          }

                                          final today = DateTime.now();
                                          final dobDate = DateTime(state.dob!.year, state.dob!.month, state.dob!.day);
                                          final todayDate = DateTime(today.year, today.month, today.day);

                                          if (dobDate.isAfter(todayDate)) {
                                            showAppSnackBar(context, 'Date of birth cannot be in the future');
                                            return;
                                          }

                                          final memberType = (state.memberType ?? '').trim().toLowerCase();
                                          if (memberType == 'child') {
                                            final diffDays = todayDate.difference(dobDate).inDays;

                                            const int minDays = 1;
                                            const int maxDays = 15 * 365;

                                            if (diffDays < minDays || diffDays > maxDays) {
                                              showAppSnackBar(context, 'For Child: Age should be between 1 day to 15 years.');
                                              return;
                                            }
                                          }
                                        }

                                        final memberData = {
                                          'memberType': state.memberType,
                                          'name': state.name,
                                          'relation': state.relation,
                                          'fatherName': state.fatherName,
                                          'motherName': state.motherName,
                                          'gender': state.gender,
                                          'dob': state.dob?.toIso8601String(),
                                          'approxAge': state.approxAge,
                                          'maritalStatus': state.maritalStatus,
                                          'mobileNo': state.mobileNo,
                                          'mobileOwner': state.mobileOwner,
                                          'education': state.education,
                                          'occupation': state.occupation,
                                          'religion': state.religion,
                                          'category': state.category,
                                          'bankAcc': state.bankAcc,
                                          'ifsc': state.ifsc,
                                          'voterId': state.voterId,
                                          'rationId': state.rationId,
                                          'phId': state.phId,
                                          'abhaAddress': state.abhaAddress,
                                          'richId': state.RichIDChanged,
                                          'birthCertificate': state.BirthCertificateChange,
                                          'weight': state.WeightChange,
                                          'school': state.ChildSchool,
                                          'hasChildren': state.hasChildren,
                                          'isPregnant': state.isPregnant,
                                          'ageAtMarriage': state.ageAtMarriage,
                                          'spouseName': state.spouseName,
                                          'createdAt': DateTime.now().toIso8601String(),
                                        };


                                        print('Submitting member data: ${jsonEncode(memberData)}');

                                        // If this screen was opened as standalone member
                                        // details (from AllBeneficiary / HouseHold_Beneficiery)
                                        // OR in edit mode, always save immediately using the
                                        // AddNewFamilyMemberBloc submit events.
                                        if (_isMemberDetails || _isEdit) {
                                          if (_isEdit) {
                                            bloc.add(AnmUpdateSubmit(hhid: widget.hhId ?? ''));
                                          } else {
                                            bloc.add(AnmSubmit(context, hhid: widget.hhId));
                                          }
                                          return;
                                        }

                                        // Household registration flow (isMemberDetails == false):
                                        // advance through tabs and, on the last step, pop the
                                        // collected memberData back to RegisterNewHouseHold.
                                        if (!_isEdit) {
                                          final showSpouse = !_isEdit && state.memberType != 'Child' && state.maritalStatus == 'Married';
                                          final showChildren = !_isEdit && showSpouse && state.hasChildren == 'Yes';
                                          final lastStep = showChildren ? 2 : (showSpouse ? 1 : 0);

                                          if (_currentStep < lastStep) {
                                            setState(() { _currentStep += 1; });
                                            final ctrl = DefaultTabController.of(context);
                                            ctrl?.animateTo(_currentStep);
                                            return;
                                          }

                                          // We are already on the last step: close this screen
                                          // and return the prepared memberData to the caller.
                                          Navigator.of(context).pop(memberData);
                                          return;
                                        }
                                      } catch (e) {
                                        print('Error preparing member data: $e');
                                        showAppSnackBar(context, 'Error preparing data. Please try again.');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            )
      )
      )));
  }
}
