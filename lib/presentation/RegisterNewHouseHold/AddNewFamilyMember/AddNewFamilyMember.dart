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
  // When true, this screen is used for inline edit inside
  // RegisterNewHouseHold and should not trigger DB save via bloc.
  final bool inlineEdit;
  // Full member data map used to prefill fields during inline edit.
  final Map<String, dynamic>? initial;
  // Initial tab index for the DefaultTabController: 0 = member, 1 = spouse, 2 = children.
  final int initialStep;

  const AddNewFamilyMemberScreen({
    super.key,
    this.isEdit = false,
    this.hhId,
    this.headName,
    this.headGender,
    this.spouseName,
    this.spouseGender,
    this.inlineEdit = false,
    this.initial,
    this.initialStep = 0,
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
  bool _syncingSpouseName = false;

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
  // Ensure inline initial data is applied only once.
  bool _initialApplied = false;

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
    // On first build, honor the initialStep requested by the caller so that
    // we can open directly on Spouse/Children tabs when needed.
    if (_isFirstLoad) {
      _isFirstLoad = false;
      // tabCount is computed below as either 1 or 3; clamp will be applied again
      // just before creating DefaultTabController.
      _currentStep = widget.initialStep;
    }
    // Inline edit inside RegisterNewHouseHold: hydrate member + spouse blocs
    // once from the initial map stored in RegisterNewHouseHold._memberForms.
    if (widget.inlineEdit && !_initialApplied && widget.initial != null) {
      final data = widget.initial!;
      final b = _bloc;

      // Basic identity and relation fields
      final memberType = (data['memberType'] ?? '') as String;
      if (memberType.isNotEmpty) b.add(AnmUpdateMemberType(memberType));

      final name = (data['name'] ?? '') as String;
      if (name.isNotEmpty) b.add(AnmUpdateName(name));

      final relation = (data['relation'] ?? '') as String;
      if (relation.isNotEmpty) b.add(AnmUpdateRelation(relation));

      final fatherName = (data['fatherName'] ?? '') as String;
      if (fatherName.isNotEmpty) b.add(AnmUpdateFatherName(fatherName));

      // Align father dropdown selection with stored fatherName so that
      // reopening shows the correct option or 'Other' + text field.
      if (fatherName.isNotEmpty) {
        if (_maleAdultNames.contains(fatherName)) {
          _fatherOption = fatherName;
        } else {
          _fatherOption = 'Other';
        }
      }

      final motherName = (data['motherName'] ?? '') as String;
      if (motherName.isNotEmpty) b.add(AnmUpdateMotherName(motherName));

      // Align mother dropdown selection with stored motherName so that
      // reopening shows the correct option or 'Other' + text field.
      if (motherName.isNotEmpty) {
        if (_femaleAdultNames.contains(motherName)) {
          _motherOption = motherName;
        } else {
          _motherOption = 'Other';
        }
      }

      final gender = (data['gender'] ?? '') as String;
      if (gender.isNotEmpty) b.add(AnmUpdateGender(gender));

      final mobileNo = (data['mobileNo'] ?? '') as String;
      if (mobileNo.isNotEmpty) b.add(AnmUpdateMobileNo(mobileNo));

      // Whose mobile number ("whose mobile no.")
      final mobileOwner = (data['mobileOwner'] ?? '') as String;
      if (mobileOwner.isNotEmpty) b.add(AnmUpdateMobileOwner(mobileOwner));

      final maritalStatus = (data['maritalStatus'] ?? '') as String;
      if (maritalStatus.isNotEmpty) b.add(AnmUpdateMaritalStatus(maritalStatus));

      final hasChildren = (data['hasChildren'] ?? '') as String;
      if (hasChildren.isNotEmpty) b.add(AnmUpdateHasChildren(hasChildren));

      // Pregnancy status (used for eligible-couple type flows)
      final isPregnant = (data['isPregnant'] ?? '') as String;
      if (isPregnant.isNotEmpty) b.add(AnmUpdateIsPregnant(isPregnant));

      final spouseName = (data['spouseName'] ?? '') as String;
      if (spouseName.isNotEmpty) b.add(AnmUpdateSpouseName(spouseName));

      // Age: restore useDob, DOB and approxAge when available
      final useDobVal = data['useDob'];
      bool? useDobBool;
      if (useDobVal is bool) {
        useDobBool = useDobVal;
      } else if (useDobVal is String) {
        final s = useDobVal.toLowerCase();
        if (s == 'true' || s == '1') useDobBool = true;
        if (s == 'false' || s == '0') useDobBool = false;
      }
      if (useDobBool != null && useDobBool != b.state.useDob) {
        // Toggle once so bloc state matches stored preference
        b.add(AnmToggleUseDob());
      }

      // DOB
      final dobIso = (data['dob'] ?? '') as String;
      if (dobIso.isNotEmpty) {
        final dob = DateTime.tryParse(dobIso);
        if (dob != null) b.add(AnmUpdateDob(dob));
      }

      final approxAge = (data['approxAge'] ?? '') as String;
      if (approxAge.isNotEmpty) b.add(AnmUpdateApproxAge(approxAge));

      // Prefer explicit saved year/month/day fields when present
      final updYear  = (data['updateYear']  ?? '') as String;
      final updMonth = (data['updateMonth'] ?? '') as String;
      final updDay   = (data['updateDay']   ?? '') as String;

      if (updYear.isNotEmpty)  b.add(UpdateYearChanged(updYear));
      if (updMonth.isNotEmpty) b.add(UpdateMonthChanged(updMonth));
      if (updDay.isNotEmpty)   b.add(UpdateDayChanged(updDay));

      // If split fields are missing but approxAge string exists, derive them
      if (updYear.isEmpty && updMonth.isEmpty && updDay.isEmpty && approxAge.isNotEmpty) {
        final matches = RegExp(r'\d+').allMatches(approxAge).toList();
        String _part(int index) =>
            matches.length > index ? (matches[index].group(0) ?? '') : '';

        final y = _part(0);
        final m = _part(1);
        final d = _part(2);

        if (y.isNotEmpty) b.add(UpdateYearChanged(y));
        if (m.isNotEmpty) b.add(UpdateMonthChanged(m));
        if (d.isNotEmpty) b.add(UpdateDayChanged(d));
      }

      // Children count for this member (used in members table summary)
      final children = (data['children'] ?? '') as String;
      if (children.isNotEmpty) b.add(ChildrenChanged(children));

      // Education / occupation / socio-demographic
      final education = (data['education'] ?? '') as String;
      if (education.isNotEmpty) b.add(AnmUpdateEducation(education));

      final occupation = (data['occupation'] ?? '') as String;
      if (occupation.isNotEmpty) b.add(AnmUpdateOccupation(occupation));

      final religion = (data['religion'] ?? '') as String;
      if (religion.isNotEmpty) b.add(AnmUpdateReligion(religion));

      final category = (data['category'] ?? '') as String;
      if (category.isNotEmpty) b.add(AnmUpdateCategory(category));

      // Banking / IDs / ABHA
      final bankAcc = (data['bankAcc'] ?? '') as String;
      if (bankAcc.isNotEmpty) b.add(AnmUpdateBankAcc(bankAcc));

      final ifsc = (data['ifsc'] ?? '') as String;
      if (ifsc.isNotEmpty) b.add(AnmUpdateIfsc(ifsc));

      final voterId = (data['voterId'] ?? '') as String;
      if (voterId.isNotEmpty) b.add(AnmUpdateVoterId(voterId));

      final rationId = (data['rationId'] ?? '') as String;
      if (rationId.isNotEmpty) b.add(AnmUpdateRationId(rationId));

      final phId = (data['phId'] ?? '') as String;
      if (phId.isNotEmpty) b.add(AnmUpdatePhId(phId));

      final abhaAddress = (data['abhaAddress'] ?? '') as String;
      if (abhaAddress.isNotEmpty) b.add(AnmUpdateAbhaAddress(abhaAddress));

      // Children-specific extras (best-effort)
      final richId = (data['richId'] ?? '') as String;
      if (richId.isNotEmpty) b.add(RichIDChanged(richId));

      final birthCert = (data['birthCertificate'] ?? '') as String;
      if (birthCert.isNotEmpty) b.add(BirthCertificateChange(birthCert));

      final weight = (data['weight'] ?? '') as String;
      if (weight.isNotEmpty) b.add(WeightChange(weight));

      final birthWeight = (data['birthWeight'] ?? '') as String;
      if (birthWeight.isNotEmpty) b.add(BirthWeightChange(birthWeight));

      final school = (data['school'] ?? '') as String;
      if (school.isNotEmpty) b.add(ChildSchoolChange(school));

      // Hydrate ChildrenBloc from any saved childrendetails summary so that
      // reopening a member via the children tab shows the same counters
      // (totalBorn, totalLive, etc.) that were captured when the member
      // was first added.
      try {
        final chRaw = data['childrendetails'];
        Map<String, dynamic>? chMap;
        if (chRaw is Map) {
          chMap = Map<String, dynamic>.from(chRaw as Map);
        } else if (chRaw is String && chRaw.isNotEmpty) {
          chMap = Map<String, dynamic>.from(jsonDecode(chRaw));
        }
        if (chMap != null) {
          int _parseInt(String? v) => int.tryParse(v ?? '') ?? 0;

          final chState = ChildrenState(
            totalBorn: _parseInt(chMap['totalBorn']?.toString()),
            totalLive: _parseInt(chMap['totalLive']?.toString()),
            totalMale: _parseInt(chMap['totalMale']?.toString()),
            totalFemale: _parseInt(chMap['totalFemale']?.toString()),
            youngestAge: chMap['youngestAge']?.toString(),
            ageUnit: chMap['ageUnit']?.toString(),
            youngestGender: chMap['youngestGender']?.toString(),
          );

          _childrenBloc.emit(chState);
        }
      } catch (_) {}

      // Birth order
      final birthOrder = (data['birthOrder'] ?? '') as String;
      if (birthOrder.isNotEmpty) b.add(AnmUpdateBirthOrder(birthOrder));

      // Type of beneficiary
      final benType = (data['beneficiaryType'] ?? '') as String;
      if (benType.isNotEmpty) b.add(AnmUpdateBeneficiaryType(benType));

      // Age at marriage and spouse name (member side)
      final ageAtMarriage = (data['ageAtMarriage'] ?? '') as String;
      if (ageAtMarriage.isNotEmpty) b.add(AnmUpdateAgeAtMarriage(ageAtMarriage));

      // Prefill spouse LMP/EDD in member spouse form
      final spLmpIso = (data['spouseLmp'] ?? '') as String;
      if (spLmpIso.isNotEmpty) {
        final spLmp = DateTime.tryParse(spLmpIso);
        if (spLmp != null) _spousBloc.add(SpLMPChange(spLmp));
      }

      final spEddIso = (data['spouseEdd'] ?? '') as String;
      if (spEddIso.isNotEmpty) {
        final spEdd = DateTime.tryParse(spEddIso);
        if (spEdd != null) _spousBloc.add(SpEDDChange(spEdd));
      }

      // Hydrate spouse details bloc from any saved spousedetails map so that
      // reopening a member via the spouse row shows the same spouse data
      // that was entered when the member was first added.
      try {
        final spRaw = data['spousedetails'];
        Map<String, dynamic>? spMap;
        if (spRaw is Map) {
          spMap = Map<String, dynamic>.from(spRaw as Map);
        } else if (spRaw is String && spRaw.isNotEmpty) {
          spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
        }
        if (spMap != null) {
          final spBloc = _spousBloc;

          final rel = (spMap['relation'] ?? '') as String;
          if (rel.isNotEmpty) spBloc.add(SpUpdateRelation(rel));

          final spMemberName = (spMap['memberName'] ?? '') as String;
          if (spMemberName.isNotEmpty) spBloc.add(SpUpdateMemberName(spMemberName));

          final spSpouseName = (spMap['spouseName'] ?? '') as String;
          if (spSpouseName.isNotEmpty) spBloc.add(SpUpdateSpouseName(spSpouseName));

          final spAgeAtMarriage = (spMap['ageAtMarriage'] ?? '') as String;
          if (spAgeAtMarriage.isNotEmpty) spBloc.add(SpUpdateAgeAtMarriage(spAgeAtMarriage));

          final spFatherName = (spMap['fatherName'] ?? '') as String;
          if (spFatherName.isNotEmpty) spBloc.add(SpUpdateFatherName(spFatherName));

          final spGender = (spMap['gender'] ?? '') as String;
          if (spGender.isNotEmpty) spBloc.add(SpUpdateGender(spGender));

          final spOcc = (spMap['occupation'] ?? '') as String;
          if (spOcc.isNotEmpty) spBloc.add(SpUpdateOccupation(spOcc));

          final spEdu = (spMap['education'] ?? '') as String;
          if (spEdu.isNotEmpty) spBloc.add(SpUpdateEducation(spEdu));

          final spRelig = (spMap['religion'] ?? '') as String;
          if (spRelig.isNotEmpty) spBloc.add(SpUpdateReligion(spRelig));

          final spCat = (spMap['category'] ?? '') as String;
          if (spCat.isNotEmpty) spBloc.add(SpUpdateCategory(spCat));

          final spAbha = (spMap['abhaAddress'] ?? '') as String;
          if (spAbha.isNotEmpty) spBloc.add(SpUpdateAbhaAddress(spAbha));

          final spMobOwner = (spMap['mobileOwner'] ?? '') as String;
          if (spMobOwner.isNotEmpty) spBloc.add(SpUpdateMobileOwner(spMobOwner));

          final spMobOwnerRel = (spMap['mobileOwnerOtherRelation'] ?? '') as String;
          if (spMobOwnerRel.isNotEmpty) {
            spBloc.add(SpUpdateMobileOwnerOtherRelation(spMobOwnerRel));
          }

          final spMobile = (spMap['mobileNo'] ?? '') as String;
          if (spMobile.isNotEmpty) spBloc.add(SpUpdateMobileNo(spMobile));

          final spBank = (spMap['bankAcc'] ?? '') as String;
          if (spBank.isNotEmpty) spBloc.add(SpUpdateBankAcc(spBank));

          final spIfsc = (spMap['ifsc'] ?? '') as String;
          if (spIfsc.isNotEmpty) spBloc.add(SpUpdateIfsc(spIfsc));

          final spVoter = (spMap['voterId'] ?? '') as String;
          if (spVoter.isNotEmpty) spBloc.add(SpUpdateVoterId(spVoter));

          final spRation = (spMap['rationId'] ?? '') as String;
          if (spRation.isNotEmpty) spBloc.add(SpUpdateRationId(spRation));

          final spPhId = (spMap['phId'] ?? '') as String;
          if (spPhId.isNotEmpty) spBloc.add(SpUpdatePhId(spPhId));

          final spBen = (spMap['beneficiaryType'] ?? '') as String;
          if (spBen.isNotEmpty) spBloc.add(SpUpdateBeneficiaryType(spBen));

          final spPreg = (spMap['isPregnant'] ?? '') as String;
          if (spPreg.isNotEmpty) spBloc.add(SpUpdateIsPregnant(spPreg));

          final spFpCounsel = (spMap['familyPlanningCounseling'] ?? '') as String;
          if (spFpCounsel.isNotEmpty) {
            spBloc.add(FamilyPlanningCounselingChanged(spFpCounsel));
          }

          final spFpMethod = (spMap['fpMethod'] ?? '') as String;
          if (spFpMethod.isNotEmpty) spBloc.add(FpMethodChanged(spFpMethod));

          final spRelApprox = (spMap['approxAge'] ?? '') as String;
          if (spRelApprox.isNotEmpty) spBloc.add(SpUpdateApproxAge(spRelApprox));

          final spYears = (spMap['UpdateYears'] ?? '') as String;
          if (spYears.isNotEmpty) spBloc.add(UpdateYearsChanged(spYears));

          final spMonths = (spMap['UpdateMonths'] ?? '') as String;
          if (spMonths.isNotEmpty) spBloc.add(UpdateMonthsChanged(spMonths));

          final spDays = (spMap['UpdateDays'] ?? '') as String;
          if (spDays.isNotEmpty) spBloc.add(UpdateDaysChanged(spDays));

          final spDobStr = (spMap['dob'] ?? '') as String;
          if (spDobStr.isNotEmpty) {
            final d = DateTime.tryParse(spDobStr);
            if (d != null) spBloc.add(SpUpdateDob(d));
          }

          final spUseDob = spMap['useDob'];
          if (spUseDob is bool && spUseDob != spBloc.state.useDob) {
            spBloc.add(SpToggleUseDob());
          }

          final spLmpStr = (spMap['lmp'] ?? '') as String;
          if (spLmpStr.isNotEmpty) {
            final d = DateTime.tryParse(spLmpStr);
            if (d != null) spBloc.add(SpLMPChange(d));
          }

          final spEddStr = (spMap['edd'] ?? '') as String;
          if (spEddStr.isNotEmpty) {
            final d = DateTime.tryParse(spEddStr);
            if (d != null) spBloc.add(SpEDDChange(d));
          }
        }
      } catch (_) {}

      _initialApplied = true;
    }
    // For inline edit inside RegisterNewHouseHold we keep _isEdit false
    // so that the flow behaves like the household registration flow and
    // returns data to the caller instead of triggering DB save.
    if (!widget.inlineEdit) {
      _isEdit = _isEdit || widget.isEdit;
    }
    final bool hideFamilyTabs = _isEdit;
    final int tabCount = hideFamilyTabs ? 1 : 3;
    // Ensure currentStep is always within valid range of available tabs.
    _currentStep = _currentStep.clamp(0, tabCount - 1);
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
                  // When names are edited on the spouse tab, keep the
                  // main member form in sync:
                  //   - Spous.memberName  -> member.spouseName
                  //   - Spous.spouseName -> member.name
                  BlocListener<SpousBloc, SpousState>(
                    listenWhen: (p, c) =>
                        p.memberName != c.memberName || p.spouseName != c.spouseName,
                    listener: (context, sp) {
                      if (_syncingSpouseName) return;
                      _syncingSpouseName = true;
                      try {
                        final mb = context.read<AddnewfamilymemberBloc>();

                        // Spouse tab "Name of Member" (memberName) should
                        // update the member form's spouseName.
                        final memberNameFromSpouse = (sp.memberName ?? '').trim();
                        if (memberNameFromSpouse.isNotEmpty &&
                            (mb.state.spouseName ?? '').trim() != memberNameFromSpouse) {
                          mb.add(AnmUpdateSpouseName(memberNameFromSpouse));
                        }

                        // Spouse tab "Spouse Name" should update the
                        // member form's own name field.
                        final spouseNameFromSpouse = (sp.spouseName ?? '').trim();
                        if (spouseNameFromSpouse.isNotEmpty &&
                            (mb.state.name ?? '').trim() != spouseNameFromSpouse) {
                          mb.add(AnmUpdateName(spouseNameFromSpouse));
                        }
                      } finally {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _syncingSpouseName = false;
                        });
                      }
                    },
                  ),
                  BlocListener<AddnewfamilymemberBloc, AddnewfamilymemberState>(

                    listenWhen: (p, c) =>
                        p.name != c.name || p.spouseName != c.spouseName,
                    listener: (context, st) {
                      if (_syncingSpouseName) {
                        // Change originated from spouse tab; avoid loop.
                        return;
                      }
                      final spBloc = context.read<SpousBloc>();

                      final memberName = (st.name ?? '').trim();
                      if (memberName.isNotEmpty &&
                          (spBloc.state.spouseName ?? '').trim() != memberName) {
                        spBloc.add(SpUpdateSpouseName(memberName));
                      }

                      // Member screen "spouseName" should appear as spouse's
                      // "memberName" in the Spousdetails form.
                      final spouseName = (st.spouseName ?? '').trim();
                      if (spouseName.isNotEmpty &&
                          (spBloc.state.memberName ?? '').trim() != spouseName) {
                        spBloc.add(SpUpdateMemberName(spouseName));
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
                            // In the member flow we do not want Spousdetails to
                            // mirror AddFamilyHeadBloc (head form). Instead it
                            // should rely purely on its own SpousBloc state,
                            // which we hydrate from member data.
                            return const SizedBox.expand(
                              child: Spousdetails(syncFromHead: false),
                            );
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
                                                // Navigator.pushNamed(context, Route_Names.Abhalinkscreen);
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
                                          initialValue: state.motherName ?? '',
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
                                          initialValue: state.fatherName ?? '',
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
                              if (state.mobileOwner == 'Other')
                                _section(
                                  CustomTextField(
                                    labelText: 'Enter relation with mobile no. holder *',
                                    hintText: 'Enter relation with mobile no. holder',
                                    onChanged: (v) => context
                                        .read<AddnewfamilymemberBloc>()
                                        .add(AnmUpdateMobileOwnerRelation(v.trim())),
                                    validator: (value) => state.mobileOwner == 'Other'
                                        ? _captureAnmError(
                                            (value == null || value.trim().isEmpty)
                                                ? 'Relation with mobile no. holder is required'
                                                : null,
                                          )
                                        : null,
                                  ),
                                ),
                              if (state.mobileOwner == 'Other')
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
                                    firstDate: (state.memberType.toLowerCase() == 'child')
                                        ? DateTime.now().subtract(const Duration(days: 15 * 365))
                                        : DateTime(1900),
                                    lastDate: (state.memberType.toLowerCase() == 'child')
                                        ? DateTime.now()
                                        : DateTime.now().subtract(const Duration(days: 15 * 365)),
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
                                              maxLength: 3,
                                              initialValue: state.updateYear ?? '',
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateYearChanged(v.trim())),
                                              validator: (value) => _captureAnmError(
                                                (state.memberType.toLowerCase() == 'child')
                                                    ? Validations.validateApproxAgeChild(
                                                        l,
                                                        value,
                                                        state.updateMonth,
                                                        state.updateDay,
                                                      )
                                                    : Validations.validateApproxAge(
                                                        l,
                                                        value,
                                                        state.updateMonth,
                                                        state.updateDay,
                                                      ),
                                              ),
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
                                              maxLength: 2,
                                              initialValue: state.updateMonth ?? '',
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateMonthChanged(v.trim())),
                                              validator: (value) => _captureAnmError(
                                                (state.memberType.toLowerCase() == 'child')
                                                    ? Validations.validateApproxAgeChild(
                                                        l,
                                                        state.updateYear,
                                                        value,
                                                        state.updateDay,
                                                      )
                                                    : Validations.validateApproxAge(
                                                        l,
                                                        state.updateYear,
                                                        value,
                                                        state.updateDay,
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

                                          Expanded(
                                            child: CustomTextField(
                                              labelText: 'Days',
                                              hintText: '0',
                                              maxLength: 2,
                                              initialValue: state.updateDay ?? '',
                                              keyboardType: TextInputType.number,
                                              onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(UpdateDayChanged(v.trim())),
                                              validator: (value) => _captureAnmError(
                                                (state.memberType.toLowerCase() == 'child')
                                                    ? Validations.validateApproxAgeChild(
                                                        l,
                                                        state.updateYear,
                                                        state.updateMonth,
                                                        value,
                                                      )
                                                    : Validations.validateApproxAge(
                                                        l,
                                                        state.updateYear,
                                                        state.updateMonth,
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
                                    initialValue: state.WeightChange ?? '',
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(WeightChange(v.trim())),
                                    validator: (value) {
                                      final trimmed = value?.trim() ?? '';
                                      if (trimmed.isEmpty) {
                                        return null; // optional field
                                      }

                                      final parsed = double.tryParse(trimmed);
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
                                // Show birth weight if child age is from birth up to 15 months
                                if (() {
                                  final yy = int.tryParse(state.updateYear ?? '0') ?? 0;
                                  final mm = int.tryParse(state.updateMonth ?? '0') ?? 0;
                                  final dd = int.tryParse(state.updateDay ?? '0') ?? 0;

                                  // If no age entered at all, hide the field
                                  if (yy == 0 && mm == 0 && dd == 0) {
                                    return false;
                                  }

                                  final totalMonths = yy * 12 + mm;
                                  return totalMonths <= 15;
                                }())...[
                                  _section(
                                    CustomTextField(
                                      labelText: 'Birth Weight (1200-4000)gms',
                                      hintText: 'Birth Weight (1200-4000)gms',
                                      keyboardType: TextInputType.number,
                                      initialValue: state.birthWeight ?? '',
                                      onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(BirthWeightChange(v?.trim() ?? '')),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return null; // optional field
                                        }

                                        final parsed = int.tryParse(trimmed);
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
                                ],
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
                                    value: state.ChildSchool,
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
                                  initialValue: state.bankAcc,
                                  onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateBankAcc(v.trim())),
                                ),
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(
                                CustomTextField(
                                  labelText: l.ifscLabel,
                                  hintText: l.ifscLabel,
                                  initialValue: state.ifsc,
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
                                if (state.occupation == 'Other')
                                  _section(
                                    CustomTextField(
                                      labelText: 'Enter occupation',
                                      hintText: 'Enter occupation',
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateOtherOccupation(v.trim())),
                                    ),
                                  ),
                                if (state.occupation == 'Other')
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
                              _section(CustomTextField(labelText: l.voterIdLabel,hintText: l.voterIdLabel, initialValue: state.voterId, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateVoterId(v.trim())),)),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(CustomTextField(labelText: l.rationCardIdLabel, hintText: l.rationCardIdLabel, initialValue: state.rationId, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateRationId(v.trim())),)),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              _section(CustomTextField(labelText: l.personalHealthIdLabel,hintText: l.personalHealthIdLabel, initialValue: state.phId, onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdatePhId(v.trim())),)),
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
                              if (state.maritalStatus == 'Married') ...[
                                _section(
                                  CustomTextField(
                                    labelText: l.ageAtMarriageLabel,
                                    hintText: l.ageAtMarriageHint,
                                    keyboardType: TextInputType.number,
                                    initialValue: state.ageAtMarriage,
                                    onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateAgeAtMarriage(v)),
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                _section(
                                  CustomTextField(
                                    labelText: '${l.spouseNameLabel} *',
                                    hintText: l.spouseNameHint,
                                    initialValue: state.spouseName,
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
                                      // Use the _isEdit flag (driven by widget.isEdit and
                                      // route args) to decide whether this is an update
                                      // context. inlineEdit still controls behavior (pop
                                      // vs DB save) but not the label.
                                      final bool isUpdateContext = _isEdit;

                                      if (isLoading) {
                                        return isUpdateContext ? 'UPDATING...' : l.addingButton;
                                      }

                                      if (isUpdateContext) {
                                        return 'UPDATE';
                                      }

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
                                          'useDob': state.useDob,
                                          'dob': state.dob?.toIso8601String(),
                                          'approxAge': state.approxAge,
                                          'children': state.children,
                                          'birthOrder': state.birthOrder,
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
                                          'beneficiaryType': state.beneficiaryType,
                                          'abhaAddress': state.abhaAddress,
                                          'richId': state.RichIDChanged,
                                          'birthCertificate': state.BirthCertificateChange,
                                          'weight': state.WeightChange,
                                          'birthWeight': state.birthWeight,
                                          'school': state.ChildSchool,
                                          'hasChildren': state.hasChildren,
                                          'isPregnant': state.isPregnant,
                                          'ageAtMarriage': state.ageAtMarriage,
                                          'spouseName': state.spouseName,
                                          'createdAt': DateTime.now().toIso8601String(),
                                        };

                                        // Attach children details snapshot so that
                                        // reopening via the children tab can restore
                                        // the same counters in ChildrenBloc.
                                        try {
                                          final ch = _childrenBloc.state;
                                          memberData['childrendetails'] = ch.toJson();
                                        } catch (_) {}


                                        print('Submitting member data: ${jsonEncode(memberData)}');


                                        if (_isMemberDetails || _isEdit) {
                                          if (_isEdit) {
                                            bloc.add(AnmUpdateSubmit(hhid: widget.hhId ?? ''));
                                          } else {
                                            bloc.add(AnmSubmit(context, hhid: widget.hhId));
                                          }
                                          return;
                                        }

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


                                          try {
                                            final spState = _spousBloc.state;
                                            final spJson = spState.toJson();


                                            final hasSpouseData = spJson.values.any((v) {
                                              if (v == null) return false;
                                              if (v is String) return v.trim().isNotEmpty;
                                              return true;
                                            });
                                            if (hasSpouseData) {
                                              memberData['spouseUseDob'] = spState.useDob;
                                              memberData['spouseDob'] = spState.dob?.toIso8601String();
                                              memberData['spouseApproxAge'] = spState.approxAge;

                                              // Store as JSON string so that it
                                              // is compatible with memberData's
                                              // String-valued fields. Inline edit
                                              // hydration already supports both
                                              // Map and String for spousedetails.
                                              memberData['spousedetails'] = jsonEncode(spJson);
                                            }
                                          } catch (_) {}

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
