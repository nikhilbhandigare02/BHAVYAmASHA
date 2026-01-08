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
import '../../../data/repositories/RegisterNewHouseHoldController/register_new_house_hold.dart';
import 'bloc/addnewfamilymember_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show MultiBlocProvider;
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/SpousDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/SpousDetails/bloc/spous_bloc.dart'
    hide RichIDChanged;
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/ChildrenDetaills.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/Children_Details/bloc/children_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart'
    hide ChildrenChanged;
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

class AddNewFamilyMemberScreen extends StatefulWidget {
  final String? hhId;
  final String? headName;
  final String? headGender;
  final String? spouseName;
  final String? spouseGender;
  final bool isEdit;
  final bool inlineEdit;
  final bool maintainState;
  final Map<String, dynamic>? initial;
  final int initialStep;
  final bool isAddMember;
  final String? headMobileNumber;
  final String? headSpouseMobile;

  const AddNewFamilyMemberScreen({
    super.key,
    this.isEdit = false,
    this.hhId,
    this.headName,
    this.headGender,
    this.spouseName,
    this.spouseGender,
    this.inlineEdit = false,
    this.maintainState = true,
    this.initial,
    this.initialStep = 0,
    this.isAddMember = false,
    this.headMobileNumber,
    this.headSpouseMobile,
  });

  @override
  State<AddNewFamilyMemberScreen> createState() =>
      _AddNewFamilyMemberScreenState();
}

class _AddNewFamilyMemberScreenState extends State<AddNewFamilyMemberScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _argsHandled = false;

  bool _isMemberDetails = false;
  String _fatherOption = '';
  String _motherOption = '';
  int _currentStep = 0;
  bool _tabListenerAttached = false;
  bool _syncingGender = false;
  bool _syncingSpouseName = false;
  bool _dataClearedByTypeChange = false;

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

  void _scrollToFirstError() {
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
    final formContext = _formKey.currentContext;

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

    formContext.visitChildElements(visitElement);
    return firstErrorField;
  }

  String? _headName;
  String? _headGender;
  String? _spouseName;
  String? _spouseGender;

  List<String> _maleAdultNames = [];
  List<String> _femaleAdultNames = [];
  List<Map<String, String>> _adultSummaries = [];
  final Map<String, String> _adultRelationByName = {};


  Widget _section(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 4), child: child);

  late final AddnewfamilymemberBloc _bloc;
  late final SpousBloc _spousBloc;
  late final ChildrenBloc _childrenBloc;
  late final AddFamilyHeadBloc _dummyHeadBloc;

  // Form controllers
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _initialApplied = false;

  final TextEditingController _memberTypeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _maritalStatusController =
  TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _beneficiaryTypeController =
  TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _memberStatusController = TextEditingController();
  final TextEditingController _familyPlanningMethodController =
  TextEditingController();

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

  void _handleAbhaProfileResult(Map<String, dynamic> profile, BuildContext context) {
    debugPrint("ABHA Profile Received in Add New Family Member: $profile");

    final bloc = context.read<AddnewfamilymemberBloc>();

    // 1. ABHA Address
    final abhaAddress = profile['abhaAddress']?.toString().trim();
    if (abhaAddress != null && abhaAddress.isNotEmpty) {
      bloc.add(AnmUpdateAbhaAddress(abhaAddress));
    }

    // 2. Full Name
    final nameParts = [
      profile['firstName'],
      profile['middleName'],
      profile['lastName'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
    if (nameParts.isNotEmpty) {
      bloc.add(AnmUpdateName(nameParts.trim()));
    }

    // 3. DOB
    try {
      final day = profile['dayOfBirth']?.toString();
      final month = profile['monthOfBirth']?.toString();
      final year = profile['yearOfBirth']?.toString();
      if (day != null && month != null && year != null) {
        final dob = DateTime(int.parse(year), int.parse(month), int.parse(day));
        bloc.add(AnmToggleUseDob());
        bloc.add(AnmUpdateDob(dob));
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
      bloc.add(AnmUpdateGender(gender));
    }

    // 5. Mobile
    final mobile = profile['mobile']?.toString().trim();
    if (mobile != null && mobile.length == 10) {
      bloc.add(AnmUpdateMobileNo(mobile));
      bloc.add(AnmUpdateMobileOwner('Self'));
    }

    showAppSnackBar(context, "ABHA details filled successfully!");
  }

  Future<void> _loadBeneficiaryData(String beneficiaryId) async {
    try {
      print('=== Loading Beneficiary Data ===');
      print('Beneficiary ID: $beneficiaryId');
      print('isEdit: $_isEdit');
      print('isMemberDetails: $_isMemberDetails');

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

  @override
  void initState() {
    super.initState();
    _isEdit = widget.isEdit;

    _bloc = AddnewfamilymemberBloc();
    _spousBloc = SpousBloc();
    _childrenBloc = ChildrenBloc();
    _dummyHeadBloc = AddFamilyHeadBloc();
    _loadAdultsFromSecureStorage();

    print('HHID passed to AddNewFamilyMember: ${widget.hhId}');

    _fatherOption = '';
    _motherOption = '';

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
      await _loadAdultsFromSecureStorage();

      try {
        final hh = widget.hhId?.toString() ?? '';
        if (hh.isNotEmpty) {
          final rows = await LocalStorageDao.instance
              .getBeneficiariesByHousehold(hh);
          final male = <String>{};
          final female = <String>{};
          for (final row in rows) {
            final isAdult = (row['is_adult'] is num)
                ? (row['is_adult'] as num).toInt() == 1
                : false;
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
            final name =
            (info['memberName'] ?? info['headName'] ?? info['name'] ?? '')
                .toString()
                .trim();
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
            if ((_headName == null || _headName!.isEmpty) &&
                _maleAdultNames.isNotEmpty) {
              _headName = _maleAdultNames.first;
              _headGender = 'Male';
            }
            if ((_spouseName == null || _spouseName!.isEmpty) &&
                _femaleAdultNames.isNotEmpty) {
              _spouseName = _femaleAdultNames.first;
              _spouseGender = 'Female';
            }
          });
        }
      } catch (_) {}

      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        print('=== Form Arguments ===');
        print('isEdit: ${args['isEdit']}');
        print('isMemberDetails: ${args['isMemberDetails']}');
        print('beneficiaryId: ${args['beneficiaryId']}');
        print('hhId: ${args['hhId']}');

        setState(() {
          _isEdit = args['isEdit'] == true;
          _isMemberDetails = args['isMemberDetails'] == true;
        });

        if (args['isBeneficiary'] == true && args['beneficiaryId'] != null) {
          await _loadBeneficiaryData(args['beneficiaryId']);
        }
      }

      if (_fatherOption != 'Other') {
        _bloc.add(AnmUpdateFatherName(_fatherOption));
      }
      if (_motherOption != 'Other') {
        _bloc.add(AnmUpdateMotherName(_motherOption));
      }
    });
  }

  Future<void> _loadAdultsFromSecureStorage() async {
    try {
      final adults = await SecureStorageService.getHouseholdAdultsSummary();
      final male = <String>{..._maleAdultNames};
      final female = <String>{..._femaleAdultNames};
      _adultSummaries = adults.map((e) => {
        'Name': (e['Name'] ?? '').toString(),
        'Gender': (e['Gender'] ?? '').toString(),
        'Relation': (e['Relation'] ?? '').toString(),
      }).toList();
      _adultRelationByName.clear();
      for (final m in _adultSummaries) {
        final name = (m['Name'] ?? '').toString().trim();
        final g = (m['Gender'] ?? '').toString().toLowerCase();
        final rel = (m['Relation'] ?? '').toString();
        if (name.isEmpty) continue;
        if (rel.isNotEmpty) {
          _adultRelationByName[name] = rel;
        }
        if (g == 'male') {
          male.add(name);
        } else if (g == 'female') {
          female.add(name);
        }
      }
      if (mounted) {
        setState(() {
          _maleAdultNames = male.toList();
          _femaleAdultNames = female.toList();
        });
      }
    } catch (_) {}
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
    _familyPlanningMethodController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.maintainState;



  List<String> _getMobileOwnerList(String gender) {

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
  List<String> _getchildMobileOwnerList(String gender) {

    gender = gender.toLowerCase();

    if (gender == 'female') {
      return [
        'Self',
        'Family Head',
        'Father',
        'Mother',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    if (gender == 'male') {
      return [
        'Self',
        'Family Head',
        'Father',
        'Mother',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    if (gender == 'transgender') {
      return [
        'Self',
        'Family Head',
        'Father',
        'Mother',
        'Neighbour',
        'Relative',
        'Other',
      ];
    }

    // Fallback if gender is unknown
    return [
      'Self',
      'Family Head',
      'Father',
      'Mother',
      'Neighbour',
      'Relative',
      'Other',

    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();

    if (!_argsHandled) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final dynamic flagA = args['isBeneficiary'];
        final dynamic flagB = args['isEdit'];
        final dynamic flagC = args['edit'];
        _isEdit = (flagA == true) || (flagB == true) || (flagC == true);

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

    if (_isFirstLoad) {
      _isFirstLoad = false;

      _currentStep = widget.initialStep;
    }

    final childMinDate = DateTime(now.year - 15, now.month, now.day);
    final childMaxDate = now;

    final adultMinDate = DateTime(now.year - 110, now.month, now.day);
    final adultMaxDate = DateTime(now.year - 15, now.month, now.day);

    if (widget.inlineEdit && !_initialApplied && widget.initial != null && !_dataClearedByTypeChange) {
      final data = widget.initial!;
      final b = _bloc;

      final memberType = (data['memberType'] ?? '') as String;
      if (memberType.isNotEmpty) b.add(AnmUpdateMemberType(memberType));

      final name = (data['name'] ?? '') as String;
      if (name.isNotEmpty) b.add(AnmUpdateName(name));

      final relation = (data['relation'] ?? '') as String;
      if (relation.isNotEmpty) b.add(AnmUpdateRelation(relation));

      final fatherName = (data['fatherName'] ?? '') as String;
      if (fatherName.isNotEmpty) b.add(AnmUpdateFatherName(fatherName));

      if (fatherName.isNotEmpty) {
        if (_maleAdultNames.contains(fatherName)) {
          _fatherOption = fatherName;
        } else {
          _fatherOption = 'Other';
        }
      }

      final motherName = (data['motherName'] ?? '') as String;
      if (motherName.isNotEmpty) b.add(AnmUpdateMotherName(motherName));

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
      if (maritalStatus.isNotEmpty)
        b.add(AnmUpdateMaritalStatus(maritalStatus));
      // Ensure marital status is 'Married' when editing spouse cards
      else if (widget.initialStep == 1)
        b.add(AnmUpdateMaritalStatus('Married'));

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
      final updYear = (data['updateYear'] ?? '') as String;
      final updMonth = (data['updateMonth'] ?? '') as String;
      final updDay = (data['updateDay'] ?? '') as String;

      if (updYear.isNotEmpty) b.add(UpdateYearChanged(updYear));
      if (updMonth.isNotEmpty) b.add(UpdateMonthChanged(updMonth));
      if (updDay.isNotEmpty) b.add(UpdateDayChanged(updDay));

      // If split fields are missing but approxAge string exists, derive them
      if (updYear.isEmpty &&
          updMonth.isEmpty &&
          updDay.isEmpty &&
          approxAge.isNotEmpty) {
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

      final fpFlagRaw = data['isFamilyPlanning'] ?? data['is_family_planning'];
      if (fpFlagRaw != null) {
        String fpVal;
        if (fpFlagRaw is String) {
          fpVal = fpFlagRaw;
        } else if (fpFlagRaw is num) {
          fpVal = (fpFlagRaw == 1) ? 'Yes' : 'No';
        } else if (fpFlagRaw is bool) {
          fpVal = fpFlagRaw ? 'Yes' : 'No';
        } else {
          fpVal = fpFlagRaw.toString();
        }
        if (fpVal.isNotEmpty) b.add(AnmUpdateFamilyPlanning(fpVal));
      }

      final fpMethod = (data['familyPlanningMethod'] ?? '') as String;
      if (fpMethod.isNotEmpty) b.add(AnmUpdateFamilyPlanningMethod(fpMethod));

      // Type of beneficiary
      final benType = (data['beneficiaryType'] ?? '') as String;
      if (benType.isNotEmpty) b.add(AnmUpdateBeneficiaryType(benType));

      // Age at marriage and spouse name (member side)
      final ageAtMarriage = (data['ageAtMarriage'] ?? '') as String;
      if (ageAtMarriage.isNotEmpty)
        b.add(AnmUpdateAgeAtMarriage(ageAtMarriage));

      // Prefill spouse LMP/EDD in member spouse form
      final spLmpIso = (data['lmp'] ?? '') as String;
      print('📅 [AddNewMember] EDIT - Spouse LMP data received: "$spLmpIso"');
      if (spLmpIso.isNotEmpty) {
        final spLmp = DateTime.tryParse(spLmpIso);
        if (spLmp != null) {
          print('✅ [AddNewMember] EDIT - Setting spouse LMP: $spLmp');
          // Use post frame callback to ensure the widget is fully initialized
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _spousBloc.add(SpLMPChange(spLmp));
              print('🔄 [AddNewMember] EDIT - Spouse LMP change event sent after frame callback');
            }
          });
        } else {
          print('❌ [AddNewMember] EDIT - Failed to parse spouse LMP: "$spLmpIso"');
        }
      } else {
        print('❌ [AddNewMember] EDIT - No spouse LMP data found');
      }

      final spEddIso = (data['edd'] ?? '') as String;
      print('📅 [AddNewMember] EDIT - Spouse EDD data received: "$spEddIso"');
      if (spEddIso.isNotEmpty) {
        final spEdd = DateTime.tryParse(spEddIso);
        if (spEdd != null) {
          print('✅ [AddNewMember] EDIT - Setting spouse EDD: $spEdd');
          // Use post frame callback to ensure the widget is fully initialized
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _spousBloc.add(SpEDDChange(spEdd));
              print('🔄 [AddNewMember] EDIT - Spouse EDD change event sent after frame callback');
            }
          });
        } else {
          print('❌ [AddNewMember] EDIT - Failed to parse spouse EDD: "$spEddIso"');
        }
      } else {
        print('❌ [AddNewMember] EDIT - No spouse EDD data found');
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
          if (spMemberName.isNotEmpty)
            spBloc.add(SpUpdateMemberName(spMemberName));

          final spSpouseName = (spMap['spouseName'] ?? '') as String;
          if (spSpouseName.isNotEmpty)
            spBloc.add(SpUpdateSpouseName(spSpouseName));

          final spAgeAtMarriage = (spMap['ageAtMarriage'] ?? '') as String;
          if (spAgeAtMarriage.isNotEmpty)
            spBloc.add(SpUpdateAgeAtMarriage(spAgeAtMarriage));

          final spFatherName = (spMap['fatherName'] ?? '') as String;
          if (spFatherName.isNotEmpty)
            spBloc.add(SpUpdateFatherName(spFatherName));

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
          if (spMobOwner.isNotEmpty)
            spBloc.add(SpUpdateMobileOwner(spMobOwner));

          final spMobOwnerRel =
          (spMap['mobileOwnerOtherRelation'] ?? '') as String;
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

          final spFpCounsel =
          (spMap['familyPlanningCounseling'] ?? '') as String;
          if (spFpCounsel.isNotEmpty) {
            spBloc.add(FamilyPlanningCounselingChanged(spFpCounsel));
          }

          final spFpMethod = (spMap['fpMethod'] ?? '') as String;
          if (spFpMethod.isNotEmpty) spBloc.add(FpMethodChanged(spFpMethod));

          final spRelApprox = (spMap['approxAge'] ?? '') as String;
          if (spRelApprox.isNotEmpty)
            spBloc.add(SpUpdateApproxAge(spRelApprox));

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

    if (!widget.inlineEdit) {
      _isEdit = _isEdit || widget.isEdit;
    }
    // Allow spouse tab when editing spouse cards (initialStep == 1)
    final bool hideFamilyTabs = _isEdit && widget.initialStep != 1;
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
                  yesText: l.yes,
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
                    p.memberName != c.memberName ||
                        p.spouseName != c.spouseName,
                    listener: (context, sp) {
                      if (_syncingSpouseName) return;
                      _syncingSpouseName = true;
                      try {
                        final mb = context.read<AddnewfamilymemberBloc>();

                        // Spouse tab "Name of Member" (memberName) should
                        // update the member form's spouseName.
                        final memberNameFromSpouse = (sp.memberName ?? '')
                            .trim();
                        if (memberNameFromSpouse.isNotEmpty &&
                            (mb.state.spouseName ?? '').trim() !=
                                memberNameFromSpouse) {
                          mb.add(AnmUpdateSpouseName(memberNameFromSpouse));
                        }

                        // Spouse tab "Spouse Name" should update the
                        // member form's own name field.
                        final spouseNameFromSpouse = (sp.spouseName ?? '')
                            .trim();
                        if (spouseNameFromSpouse.isNotEmpty &&
                            (mb.state.name ?? '').trim() !=
                                spouseNameFromSpouse) {
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
                          (spBloc.state.spouseName ?? '').trim() !=
                              memberName) {
                        spBloc.add(SpUpdateSpouseName(memberName));
                      }

                      // Member screen "spouseName" should appear as spouse's
                      // "memberName" in the Spousdetails form.
                      final spouseName = (st.spouseName ?? '').trim();
                      if (spouseName.isNotEmpty &&
                          (spBloc.state.memberName ?? '').trim() !=
                              spouseName) {
                        spBloc.add(SpUpdateMemberName(spouseName));
                      }
                    },
                  ),
                  BlocListener<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                    listenWhen: (previous, current) =>
                    previous.postApiStatus != current.postApiStatus,
                    listener: (context, state) {
                      if (state.postApiStatus == PostApiStatus.success) {
                        // Only navigate back after successful save
                        final Map<String, dynamic> result = state.toJson();
                        Navigator.of(context).pop(result);
                      } else if (state.postApiStatus == PostApiStatus.error) {
                        // Show error message if save fails
                        if (state.errorMessage != null &&
                            state.errorMessage!.isNotEmpty) {
                          showAppSnackBar(context, state.errorMessage!);
                        } else {
                          showAppSnackBar(
                            context,
                            l?.failedToSaveFamilyMember ??
                                'Failed to save family member. Please try again.',
                          );
                        }
                      }
                    },
                  ),
                  BlocListener<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                    listenWhen: (p, c) =>
                        p.fatherName != c.fatherName ||
                        p.motherName != c.motherName,
                    listener: (context, state) {
                      if (state.fatherName != null &&
                          state.fatherName!.isNotEmpty) {
                        if (_maleAdultNames.contains(state.fatherName)) {
                          setState(() {
                            _fatherOption = state.fatherName!;
                          });
                        } else {
                          setState(() {
                            _fatherOption = 'Other';
                          });
                        }
                      }
                      if (state.motherName != null &&
                          state.motherName!.isNotEmpty) {
                        if (_femaleAdultNames.contains(state.motherName)) {
                          setState(() {
                            _motherOption = state.motherName!;
                          });
                        } else {
                          setState(() {
                            _motherOption = 'Other';
                          });
                        }
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
                              setState(() {
                                _currentStep = ctrl.index;
                              });
                            });
                          }
                          return BlocBuilder<
                              AddnewfamilymemberBloc,
                              AddnewfamilymemberState
                          >(
                            builder: (ctx2, st) {
                              final bool spouseAllowed =
                                  (!hideFamilyTabs &&
                                      st.memberType != 'Child' &&
                                      st.maritalStatus == 'Married') ||
                                  // Allow spouse tab when explicitly editing spouse cards
                                  widget.initialStep == 1;
                              final bool childrenAllowed =
                                  !hideFamilyTabs &&
                                      spouseAllowed &&
                                      st.hasChildren == 'Yes';
                              final String firstTabTitle =
                              (st.memberType == 'Child')
                                  ? l.childDetails
                                  : l.memberDetails;
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
                                    labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white70,
                                    indicator: const UnderlineTabIndicator(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    tabs: [Tab(text: firstTabTitle)],
                                  ),
                                );
                              }
                              return buildTabs(
                                TabBar(
                                  isScrollable: true,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  labelColor: Colors.white,
                                  unselectedLabelColor: Colors.white70,
                                  indicator: const UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  onTap: (i) {
                                    final ctrl = DefaultTabController.of(ctx);
                                    int target = i;
                                    if (i == 1 && !spouseAllowed) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l?.setMaritaDetails ??
                                                'Set Marital Status = Married to fill Spouse details.',
                                          ),
                                        ),
                                      );
                                      target = 0;
                                    } else if (i == 2 && !childrenAllowed) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l?.setChildDetails ??
                                                'Select Have Children = Yes to fill Children details.',
                                          ),
                                        ),
                                      );
                                      target = spouseAllowed ? 1 : 0;
                                    }
                                    setState(() {
                                      _currentStep = target;
                                    });
                                    ctrl?.animateTo(target);
                                  },
                                  tabs: [
                                    Tab(text: firstTabTitle),
                                    Tab(
                                      child: Opacity(
                                        opacity: spouseAllowed ? 1.0 : 0.0,
                                        child: Text(
                                          l?.spouseDetails ?? 'Spouse Details',
                                        ),
                                      ),
                                    ),
                                    Tab(
                                      child: Opacity(
                                        opacity: childrenAllowed ? 1.0 : 0.0,
                                        child: Text(
                                          l?.childrenDetails ??
                                              'Children Details',
                                        ),
                                      ),
                                    ),
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
                              return SizedBox.expand(
                                child: Spousdetails(
                                  syncFromHead: false,
                                  isMemberDetails: true,
                                  isAddMember: widget.isAddMember,
                                  hhId: widget.hhId,
                                  headMobileNo: widget.headMobileNumber,
                                  headGender: widget.headGender,
                                ),
                              );
                            }
                            if (_currentStep == 2) {
                              return SizedBox.expand(child: Childrendetaills());
                            }
                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                100,
                              ),
                              child: Column(
                                children: [
                                _section(
                                  ApiDropdown<String>(
                                    labelText: l.memberTypeLabel,
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
                                      final bloc = context
                                          .read<AddnewfamilymemberBloc>();
                                      
                                      final currentMemberType = state.memberType;
                                      
                                      print('🔄 [MemberType] Changing from: $currentMemberType to: $v');
                                      print('🔄 [MemberType] Current state - Name: ${state.name}, Mobile: ${state.mobileNo}');
                                      print('🔄 [MemberType] Data cleared flag: $_dataClearedByTypeChange');
                                      

                                      if ((currentMemberType == 'Adult' && v == 'Child') ||
                                          (currentMemberType == 'Child' && v == 'Adult')) {
                                        print('🧹 [MemberType] Clearing all data due to member type change');
                                        setState(() {
                                          _dataClearedByTypeChange = true;
                                        });
                                        
                                        bloc.add( AnmClearAllData());
                                        
                                        Future.microtask(() {
                                          bloc.add(AnmUpdateMemberType(v ?? ''));
                                          bloc.add( AnmResetDataClearedFlag());
                                          print('🔄 [MemberType] Set new member type after clearing: $v');
                                        });
                                      } else {
                                        bloc.add(AnmUpdateMemberType(v ?? ''));
                                      }
                                      
                                      if (v == 'Child') {
                                        bloc.add(
                                          const AnmUpdateMaritalStatus(''),
                                        );
                                        if (state.relation == 'Spouse') {
                                          bloc.add(AnmUpdateRelation(''));
                                        }
                                      }
                                      
                                      // Clear father name and mother name fields when member type changes
                                      bloc.add(const AnmUpdateFatherName(''));
                                      bloc.add(const AnmUpdateMotherName(''));
                                      bloc.add(const UpdateIsMemberStatus(''));
                                      setState(() {
                                        _fatherOption = l.select;
                                        _motherOption = l.select;
                                      });
                                      
                                      print('🔄 [MemberType] After change - MemberType: ${state.memberType}, Name: ${state.name}');
                                    },
                                    validator: (value) => _captureAnmError(
                                      Validations.validateMemberType(l, value),
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                // if (state.mobileOwner == 'Other')
                                //   _section(
                                //     CustomTextField(
                                //       labelText: 'Relation with mobile holder *',
                                //       hintText: 'Enter relation with mobile holder',
                                //       initialValue: state.mobileOwnerRelation ?? '',
                                //       onChanged: (v) => context.read<AddnewfamilymemberBloc>().add(AnmUpdateMobileOwnerRelation(v.trim())),
                                //     ),
                                //   ),
                                // if (state.mobileOwner == 'Other')
                                //   Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                //
                                // // Member Status (only shown in edit mode)
                                if (_isEdit) ...[
                                  _section(
                                    ApiDropdown<String>(
                                      labelText: l
                                          .member_status_label,
                                      items: const [
                                        'Alive',
                                        'Death',
                                      ],
                                      getLabel: (s) {
                                        switch (s) {
                                          case 'Alive':
                                            return l.alive;
                                          case 'Death':
                                            return l.death;
                                          default:
                                            return s;
                                        }
                                      },
                                      value: state.memberStatus ?? 'Alive',
                                      onChanged: (v) {
                                        if (v != null) {
                                          context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(UpdateIsMemberStatus(v));
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return l?.please_select_member_status ??
                                              'Please select member status'; // If you want, I can localize this too
                                        }
                                        return null;
                                      },
                                    ),

                                    /*ApiDropdown<String>(
                                      labelText: 'Member Status *',
                                      items: const ['Alive', 'Death'],
                                      getLabel: (s) => s,
                                      value: state.memberStatus ?? 'Alive',
                                      onChanged: (v) {
                                        if (v != null) {
                                          context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(UpdateIsMemberStatus(v));
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select member status';
                                        }
                                        return null;
                                      },
                                    ),*/
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (state.memberStatus == 'Death') ...[
                                    _section(
                                      CustomDatePicker(
                                        labelText:
                                        '${l?.dateOfDeathLabel ?? "Date of Death"} *',
                                        initialDate:
                                        state.dateOfDeath ?? DateTime.now(),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                        onDateChanged: (date) {
                                          context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(UpdateDateOfDeath(date!));
                                        },
                                        validator: (value) {
                                          if (state.memberStatus == 'Death' &&
                                              value == null) {
                                            return l?.please_select_date_of_death ??
                                                'Please select date of death';
                                          }
                                          return null;
                                        },
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
                                        '${l?.placeOfDeathLabel ?? "Place of Death"} *',
                                        items: const [
                                          'Home',
                                          'Hospital',
                                          'Transit',
                                          'Other'
                                        ],
                                        getLabel: (s) {
                                          switch (s) {
                                            case 'Home':
                                              return l?.home ?? 'Home';
                                            case 'Hospital':
                                              return l?.hospital ?? 'Hospital';
                                            case 'Transit':
                                              return 'Transit';
                                            case 'Other':
                                              return l?.other ?? 'Other';
                                            default:
                                              return s;
                                          }
                                        },
                                        value: state.deathPlace,
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(UpdateDatePlace(v ?? '')),
                                        validator: (value) {
                                          if (state.memberStatus == 'Death' &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return l?.please_enter_place_of_death ??
                                                'Please select place of death';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (state.deathPlace == 'Other') ...[
                                      Divider(
                                        color: AppColors.divider,
                                        thickness: 0.5,
                                        height: 0,
                                      ),
                                      _section(
                                        CustomTextField(
                                          labelText: '${l?.other ?? "Other"} *',
                                          hintText: l?.enter_place_of_death ??
                                              'Enter place of death',
                                          initialValue: state.otherDeathPlace,
                                          onChanged: (v) => context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(
                                            UpdateOtherDeathPlace(v ?? ''),
                                          ),
                                          validator: (value) {
                                            if (state.memberStatus == 'Death' &&
                                                state.deathPlace == 'Other' &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return l?.please_enter_place_of_death ??
                                                  'Please enter place of death';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                    _section(
                                      ApiDropdown<String>(
                                        labelText: l
                                            .reason_of_death_label, // localized label
                                        items: const [
                                          'Natural Causes',
                                          'Illness',
                                          'Accident',
                                          'Other',
                                        ],
                                        getLabel: (s) {
                                          switch (s) {
                                            case 'Natural Causes':
                                              return l.natural_causes;
                                            case 'Illness':
                                              return l.illness;
                                            case 'Accident':
                                              return l.accident;
                                            case 'Other':
                                              return l.other;
                                            default:
                                              return s;
                                          }
                                        },
                                        value: state.deathReason,
                                        onChanged: (v) {
                                          if (v != null) {
                                            context
                                                .read<AddnewfamilymemberBloc>()
                                                .add(UpdateReasonOfDeath(v));
                                          }
                                        },
                                        validator: (value) {
                                          if (state.memberStatus == 'Death' &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return l
                                                .please_select_reason_of_death;
                                          }
                                          return null;
                                        },
                                      ),

                                      /*ApiDropdown<String>(
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
                                            context
                                                .read<AddnewfamilymemberBloc>()
                                                .add(UpdateReasonOfDeath(v));
                                          }
                                        },
                                        validator: (value) {
                                          if (state.memberStatus == 'Death' &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Please select reason of death';
                                          }
                                          return null;
                                        },
                                      ),*/
                                    ),
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                    if (state.deathReason == 'Other')
                                      _section(
                                        CustomTextField(
                                          labelText:
                                          l?.specify_reason_required ??
                                              'Specify Reason *',
                                          hintText:
                                          l?.enter_reason_of_death ??
                                              'Enter reason of death',
                                          onChanged: (v) => context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(
                                            UpdateOtherReasonOfDeath(
                                              v ?? '',
                                            ),
                                          ),
                                          validator: (value) {
                                            if (state.memberStatus == 'Death' &&
                                                state.deathReason == 'Other' &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return l?.specify_reason_required ??
                                                  'Please specify reason of death';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                  ],
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],

                                if (state.memberType == 'Child') ...[
                                  _section(
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        IgnorePointer(
                                          ignoring: widget.isEdit,

                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: CustomTextField(
                                                  labelText:
                                                  l?.rchIdLabel ?? "RCH ID",
                                                  hintText:
                                                  l?.enter_12_digit_rch_id ??
                                                      'Enter 12 digit RCH ID',
                                                  keyboardType:
                                                  TextInputType.number,
                                                  initialValue:
                                                  state.RichIDChanged ?? '',
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                      12,
                                                    ),
                                                  ],
                                                  onChanged: (v) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).removeCurrentSnackBar();
                                                    
                                                    // Filter out non-digit characters (for copy-paste scenarios)
                                                    final filteredValue = v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                                                    final value = filteredValue.trim();
                                                    
                                                    context
                                                        .read<
                                                        AddnewfamilymemberBloc
                                                    >()
                                                        .add(
                                                      RichIDChanged(value),
                                                    );

                                                    if (value.isNotEmpty &&
                                                        value.length != 12) {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback((
                                                          _,
                                                          ) {
                                                        if (mounted) {
                                                          showAppSnackBar(
                                                            context,
                                                            l?.rch_id_must_be_12_digits ??
                                                                'RCH ID must be exactly 12 digits',
                                                          );
                                                        }
                                                      });
                                                    }
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty)
                                                      return null;
                                                    if (value.length != 12)
                                                      return l?.must_be_12_digits ??
                                                          'Must be 12 digits';
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SizedBox(
                                                height: 3.5.h,
                                                child: RoundButton(
                                                  title:
                                                  l?.verifyLabel ?? 'VERIFY',
                                                  width: 100,
                                                  borderRadius: 8,
                                                  fontSize: 12,
                                                  isLoading: _isLoading,
                                                  disabled: !state.isRchIdButtonEnabled,
                                                  onPress: () async {
                                                    final rchIdStr =
                                                        state
                                                            .RichIDChanged?.trim() ??
                                                            '';

                                                    // --- Basic validation ---
                                                    if (rchIdStr.isEmpty) {
                                                      showAppSnackBar(
                                                        context,
                                                        l?.please_enter_rch_id_first ??
                                                            'Please enter RCH ID first',
                                                      );
                                                      return;
                                                    }
                                                    if (rchIdStr.length != 12) {
                                                      showAppSnackBar(
                                                        context,
                                                        l?.rch_id_must_be_12digits ??
                                                            'RCH ID must be exactly 12 digits',
                                                      );
                                                      return;
                                                    }

                                                    final rchId = int.tryParse(
                                                      rchIdStr,
                                                    );
                                                    if (rchId == null) {
                                                      showAppSnackBar(
                                                        context,
                                                        l?.invalid_rch_id ??
                                                            'Invalid RCH ID',
                                                      );
                                                      return;
                                                    }
                                                    setState(
                                                          () => _isLoading = true,
                                                    );
                                                    showAppSnackBar(
                                                      context,
                                                      l?.verifying_rch_id ??
                                                          'Verifying RCH ID...',
                                                    );

                                                    print(
                                                      'API REQUEST → getRCHData(rchId: $rchId, requestFor: 2)',
                                                    );
                                                    try {
                                                      final requestFor =
                                                      state.memberType ==
                                                          'Child'
                                                          ? 2
                                                          : 1;

                                                      final response =
                                                      await fetchRCHDataForScreen(
                                                        rchId,
                                                        requestFor:
                                                        requestFor,
                                                      );
                                                      print(
                                                        'API RESPONSE → $response',
                                                      );

                                                      if (!mounted) return;

                                                      setState(
                                                            () => _isLoading = false,
                                                      );

                                                      if (response == null) {
                                                        showAppSnackBar(
                                                          context,
                                                          l?.api_returned_null_response ??
                                                              'API returned null response',
                                                        );
                                                        return;
                                                      }

                                                      if (response.isEmpty) {
                                                        showAppSnackBar(
                                                          context,
                                                          l?.no_data_found_rch_id ??
                                                              'No data found for this RCH ID',
                                                        );
                                                        return;
                                                      }

                                                      // If API returns an "error" field
                                                      if (response.containsKey(
                                                        'error',
                                                      )) {
                                                        showAppSnackBar(
                                                          context,
                                                          'Error: ${response['error']}',
                                                        );
                                                        return;
                                                      }

                                                      // If API returns status parameter
                                                      if (response['status'] ==
                                                          false) {
                                                        showAppSnackBar(
                                                          context,
                                                          response['message'] ??
                                                              (l?.failed_to_fetch_rch_data ??
                                                                  'Failed to fetch RCH data'),
                                                        );
                                                        return;
                                                      }

                                                      // --- SAFE EXTRACTION ---
                                                      final bloc = context
                                                          .read<
                                                          AddnewfamilymemberBloc
                                                      >();

                                                      final name =
                                                      response['name']
                                                          ?.toString()
                                                          .trim();
                                                      final genderRaw =
                                                      response['gender']
                                                          ?.toString()
                                                          .trim();
                                                      final dobStr =
                                                      response['dob']
                                                          ?.toString()
                                                          .trim();

                                                      // NAME
                                                      if (name != null &&
                                                          name.isNotEmpty) {
                                                        bloc.add(
                                                          AnmUpdateName(name),
                                                        );
                                                      }

                                                      // GENDER
                                                      if (genderRaw != null &&
                                                          genderRaw.isNotEmpty) {
                                                        final gender =
                                                        (genderRaw.toLowerCase() ==
                                                            'm' ||
                                                            genderRaw == '1')
                                                            ? 'Male'
                                                            : (genderRaw.toLowerCase() ==
                                                            'f' ||
                                                            genderRaw == '2'
                                                            ? 'Female'
                                                            : 'Transgender');

                                                        bloc.add(
                                                          AnmUpdateGender(gender),
                                                        );
                                                      }

                                                      // DOB
                                                      if (dobStr != null &&
                                                          dobStr.isNotEmpty) {
                                                        final dob =
                                                        DateTime.tryParse(
                                                          dobStr,
                                                        );
                                                        if (dob != null) {
                                                          bloc.add(
                                                            AnmUpdateDob(dob),
                                                          );
                                                          bloc.add(
                                                            AnmToggleUseDob(),
                                                          );
                                                        }
                                                      }

                                                      showAppSnackBar(
                                                        context,
                                                        l?.rch_data_loaded_successfully ??
                                                            'RCH data loaded successfully!',
                                                      );
                                                    } catch (e) {
                                                      print('API ERROR → $e');

                                                      if (mounted) {
                                                        setState(
                                                              () =>
                                                          _isLoading = false,
                                                        );
                                                        showAppSnackBar(
                                                          context,
                                                          '${l?.failedTo_fetch_rch_data ?? "Failed to fetch RCH data"}: $e',
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],
                                _section(
                                  IgnorePointer(
                                    ignoring: widget.isEdit,
                                    child: ApiDropdown<String>(
                                      labelText: '${l.relationWithHeadLabel} *',
                                      items: state.memberType == 'Child'
                                          ? const [
                                        'Father',
                                        'Mother',
                                        'Brother',
                                        'Sister',
                                        'Grand Father',
                                        'Grand Mother',
                                        'Other',
                                      ]
                                          : const [
                                        'Self',

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
                                            return l.mother;
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
                                        final relation = v ?? '';
                                        context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmUpdateRelation(relation));

                                        if (v == 'Father') {
                                          try {
                                            final match = _adultSummaries.firstWhere(
                                                    (m) => (m['Relation'] ?? '').toString() == 'Self' &&
                                                    (m['Gender'] ?? '').toString().toLowerCase() == 'male');
                                            final name = (match['Name'] ?? '').toString();
                                            if (name.isNotEmpty) {
                                              setState(() => _fatherOption = name);
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateFatherName(name));
                                            }
                                          } catch (_) {}
                                        } else if (v == 'Mother') {
                                          try {
                                            final match = _adultSummaries.firstWhere(
                                                    (m) => (m['Relation'] ?? '').toString() == 'Self' &&
                                                    (m['Gender'] ?? '').toString().toLowerCase() == 'female');
                                            final name = (match['Name'] ?? '').toString();
                                            if (name.isNotEmpty) {
                                              setState(() => _motherOption = name);
                                              context.read<AddnewfamilymemberBloc>().add(AnmUpdateMotherName(name));
                                            }
                                          } catch (_) {}
                                        }
                                      },
                                      validator: (value) => _captureAnmError(
                                        Validations.validateFamilyHeadRelation(
                                          l,
                                          value,
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                if (state.relation == 'Other') ...[
                                  _section(
                                    CustomTextField(
                                      labelText:
                                      l?.enter_relation_with_family_head ??
                                          'Enter relation with family head',
                                      hintText:
                                      l?.enter_relation_with_family_head ??
                                          'Enter relation with family head',
                                      initialValue: state.otherRelation ?? '',
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(
                                        AnmUpdateOtherRelation(v.trim()),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],

                                if (state.relation == 'Other')
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                _section(
                                  CustomTextField(
                                    labelText: '${l.nameOfMemberLabel} *',
                                    hintText: l.nameOfMemberHint,
                                    initialValue: state.name ?? '',
                                    onChanged: (v) {
                                      final name = v.trim();
                                      context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateName(name));
                                      // Auto-fill spouse details' spouseName with member name
                                      try {
                                        final spBloc = context
                                            .read<SpousBloc>();
                                        if ((spBloc.state.memberName ?? '') !=
                                            name) {
                                          spBloc.add(SpUpdateSpouseName(name));
                                        }
                                      } catch (_) {}
                                    },
                                    validator: (value) => _captureAnmError(
                                      Validations.validateNameofMember(
                                        l,
                                        value,
                                      ),
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                if ((state.memberType ?? '').toLowerCase() ==
                                    'adult') ...[
                                  _section(
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final Set<String> fatherSet = {
                                              ..._maleAdultNames,
                                            };
                                            final List<String> fatherItems = [
                                              ...fatherSet,
                                              'Other',
                                            ];
                                            return ApiDropdown<String>(
                                              labelText:
                                              _isEdit ? l.fatherGuardianNameLabel : '${l.fatherGuardianNameLabel} *',
                                              hintText: l.select,
                                              items: fatherItems,
                                              getLabel: (s) => s,
                                              value: (_fatherOption == null ||
                                                  _fatherOption.isEmpty ||
                                                  _fatherOption == l.select)
                                                  ? null
                                                  : _fatherOption,
                                              validator: (value) {
                                                if (!_isEdit) {
                                                  if (_fatherOption == l.select ||
                                                      _fatherOption.isEmpty) {
                                                    return '${l.fatherGuardianNameRequired.toLowerCase()}';
                                                  }
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  _fatherOption = v;
                                                });
                                                if (v != l.select &&
                                                    v != 'Other') {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateFatherName(v),
                                                  );
                                                } else {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateFatherName(''),
                                                  );
                                                }
                                                // Trigger form validation
                                                if (_formKey.currentState !=
                                                    null) {
                                                  _formKey.currentState!
                                                      .validate();
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        if (_fatherOption == 'Other')
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),

                                        if (_fatherOption == 'Other')
                                          CustomTextField(
                                            labelText:
                                            _isEdit ? l.fatherGuardianNameLabel : '${l.fatherGuardianNameLabel} *',
                                            hintText: l.fatherGuardianNameLabel,
                                             initialValue:
                                            state.fatherName ?? '',
                                            onChanged: (v) {
                                              final name = v.trim();
                                              context
                                                  .read<
                                                  AddnewfamilymemberBloc
                                              >()
                                                  .add(
                                                AnmUpdateFatherName(name),
                                              );
                                              if (_formKey.currentState !=
                                                  null) {
                                                _formKey.currentState!
                                                    .validate();
                                              }
                                            },
                                            validator: (value) {
                                              if (!_isEdit) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return '${l.fatherGuardianNameRequired.toLowerCase()}';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  _section(
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final Set<String> motherSet = {
                                              ..._femaleAdultNames,
                                            };
                                            final List<String> motherItems = [
                                              ...motherSet,
                                              'Other',
                                            ];
                                            return ApiDropdown<String>(
                                              labelText:
                                              _isEdit ? l.motherNameLabel : "${l.motherNameLabel} *",
                                              hintText: l.select,
                                              items: motherItems,
                                              getLabel: (s) => s,
                                              value: (_motherOption == null ||
                                                  _motherOption.isEmpty ||
                                                  _motherOption == 'Select')
                                                  ? null
                                                  : _motherOption,
                                              validator: (value) {
                                                if (!_isEdit) {
                                                  if (_motherOption == 'Select' ||
                                                      _motherOption.isEmpty) {
                                                    return ' ${l.motherGuardianNameRequired.toLowerCase()}';
                                                  }
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  _motherOption = v;
                                                });
                                                if (v != 'Select' &&
                                                    v != 'Other') {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateMotherName(v),
                                                  );
                                                } else {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateMotherName(''),
                                                  );
                                                }
                                                if (_formKey.currentState !=
                                                    null) {
                                                  _formKey.currentState!
                                                      .validate();
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        // Divider(
                                        //   color: AppColors.divider,
                                        //   thickness: 0.5,
                                        //   height: 0,
                                        // ),
                                        if (_motherOption == 'Other')
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        if (_motherOption == 'Other') ...[
                                          CustomTextField(
                                            labelText: _isEdit ? l.motherNameLabel : "${l.motherNameLabel} *",
                                            hintText: l.motherNameLabel,
                                            initialValue:
                                            state.motherName ?? '',
                                            onChanged: (v) => context
                                                .read<AddnewfamilymemberBloc>()
                                                .add(
                                              AnmUpdateMotherName(v.trim()),
                                            ),
                                            validator: (value) {
                                              if (!_isEdit) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return ' ${l.motherGuardianNameRequired.toLowerCase()}';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],
                                        Divider(
                                          color: AppColors.divider,
                                          thickness: 0.5,
                                          height: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if ((state.memberType ?? '').toLowerCase() ==
                                    'child') ...[
                                  _section(
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final List<String> fatherItems = [
                                              ..._maleAdultNames,
                                              'Other',
                                            ];
                                            return ApiDropdown<String>(
                                              labelText:
                                              _isEdit ? l.fatherGuardianNameLabel : '${l.fatherGuardianNameLabel} *',
                                              hintText: l.select,
                                              items: fatherItems,
                                              getLabel: (s) => s,
                                              value: (_fatherOption == null ||
                                                  _fatherOption.isEmpty ||
                                                  _fatherOption == 'Select')
                                                  ? null
                                                  : _fatherOption,
                                              validator: (value) {
                                                if (!_isEdit) {
                                                  if (_fatherOption == 'Select' ||
                                                      _fatherOption.isEmpty) {
                                                    return 'Please select or enter ${l.fatherGuardianNameLabel.toLowerCase()}';
                                                  }
                                                }
                                                return null;
                                              },
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  _fatherOption = v;
                                                });
                                                if (v != 'Select' &&
                                                    v != 'Other') {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateFatherName(v),
                                                  );
                                                } else {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmUpdateFatherName(''),
                                                  );
                                                }
                                                if (_formKey.currentState !=
                                                    null) {
                                                  _formKey.currentState!
                                                      .validate();
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        if (_fatherOption == 'Other')
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        if (_fatherOption == 'Other')
                                          CustomTextField(
                                            labelText:
                                            _isEdit ? l.fatherGuardianNameLabel : '${l.fatherGuardianNameLabel} *',
                                            hintText: l.fatherGuardianNameLabel,
                                            initialValue:
                                            state.fatherName ?? '',
                                            onChanged: (v) {
                                              final name = v.trim();
                                              context
                                                  .read<
                                                  AddnewfamilymemberBloc
                                              >()
                                                  .add(
                                                AnmUpdateFatherName(name),
                                              );
                                              if (_formKey.currentState !=
                                                  null) {
                                                _formKey.currentState!
                                                    .validate();
                                              }
                                            },
                                            validator: (value) {
                                              if (!_isEdit) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Please enter ${l.fatherGuardianNameLabel.toLowerCase()}';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        Divider(
                                          color: AppColors.divider,
                                          thickness: 0.5,
                                          height: 0,
                                        ),
                                        _section(
                                          Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  final List<String> motherItems = [
                                                    ..._femaleAdultNames,
                                                    'Other',
                                                  ];
                                                  return ApiDropdown<String>(
                                                    labelText:
                                                    _isEdit ? l.motherNameLabel : "${l.motherNameLabel} *",
                                                    hintText: l.select,
                                                    items: motherItems,
                                                    getLabel: (s) => s,
                                                    value: (_motherOption == null ||
                                                        _motherOption.isEmpty ||
                                                        _motherOption == 'Select')
                                                        ? null
                                                        : _motherOption,
                                                    validator: (value) {
                                                      if (!_isEdit) {
                                                        if (_motherOption ==
                                                            'Select' ||
                                                            _motherOption
                                                                .isEmpty) {
                                                          return 'Please select or enter ${l.motherNameLabel.toLowerCase()}';
                                                        }
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (v) {
                                                      if (v == null) return;
                                                      setState(() {
                                                        _motherOption = v;
                                                      });
                                                      if (v != 'Select' &&
                                                          v != 'Other') {
                                                        context
                                                            .read<
                                                            AddnewfamilymemberBloc
                                                        >()
                                                            .add(
                                                          AnmUpdateMotherName(
                                                            v,
                                                          ),
                                                        );
                                                      } else {
                                                        context
                                                            .read<
                                                            AddnewfamilymemberBloc
                                                        >()
                                                            .add(
                                                          AnmUpdateMotherName(
                                                            '',
                                                          ),
                                                        );
                                                      }
                                                      if (_formKey
                                                          .currentState !=
                                                          null) {
                                                        _formKey.currentState!
                                                            .validate();
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                              // Divider(
                                              //   color: AppColors.divider,
                                              //   thickness: 0.5,
                                              //   height: 0,
                                              // ),
                                              if (_motherOption == 'Other')
                                                Divider(
                                                  color: AppColors.divider,
                                                  thickness: 0.5,
                                                  height: 0,
                                                ),
                                              if (_motherOption == 'Other') ...[
                                                CustomTextField(
                                                  labelText:
                                                  _isEdit ? l.motherNameLabel : "${l.motherNameLabel} *",
                                                  hintText: l.motherNameLabel,
                                                  initialValue:
                                                  state.motherName ?? '',
                                                  onChanged: (v) {
                                                    final name = v.trim();
                                                    context
                                                        .read<
                                                        AddnewfamilymemberBloc
                                                    >()
                                                        .add(
                                                      AnmUpdateMotherName(
                                                        name,
                                                      ),
                                                    );
                                                    if (_formKey.currentState !=
                                                        null) {
                                                      _formKey.currentState!
                                                          .validate();
                                                    }
                                                  },
                                                  validator: (value) {
                                                    if (!_isEdit) {
                                                      if (_motherOption ==
                                                          'Other' &&
                                                          (value == null ||
                                                              value
                                                                  .trim()
                                                                  .isEmpty)) {
                                                        return 'Please enter ${l.motherNameLabel.toLowerCase()}';
                                                      }
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                Divider(
                                                  color: AppColors.divider,
                                                  thickness: 0.5,
                                                  height: 0,
                                                ),
                                              ],
                                              Divider(
                                                color: AppColors.divider,
                                                thickness: 0.5,
                                                height: 0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if ((state.memberType ?? '').toLowerCase() ==
                                    'child') ...[
                                  _section(
                                      IgnorePointer(
                                          ignoring: widget.isEdit,
                                          child: ApiDropdown<String>(
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
                                          onChanged: (v) {
                                            if (v == null) return;
                                            final memberGender = v;
                                            context
                                                .read<AddnewfamilymemberBloc>()
                                                .add(AnmUpdateGender(memberGender));
                                            try {
                                              if (_syncingGender) return;
                                              _syncingGender = true;
                                              final opposite = _oppositeGender(
                                                memberGender,
                                              );
                                              final spBloc = context
                                                  .read<SpousBloc>();
                                              if (spBloc.state.gender != opposite) {
                                                spBloc.add(
                                                  SpUpdateGender(opposite),
                                                );
                                              }
                                            } finally {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                _syncingGender = false;
                                              });
                                            }
                                          },
                                          validator: (value) => _captureAnmError(
                                            Validations.validateGender(l, value),
                                          ),
                                        ),
                                      )
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  _section(
                                    ApiDropdown<String>(
                                      labelText: '${l.whoseMobileLabel} *',
                                      items: _getchildMobileOwnerList(state.gender ?? ''),
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
                                        final bloc = context.read<AddnewfamilymemberBloc>();

                                        bloc.add(AnmUpdateMobileOwner(v));

                                        bloc.add(AnmUpdateMobileNo(''));

                                        if (v == 'Family Head' || v == "Father" || v == "Mother") {
                                          String? mobileNumber;
                                          bool shouldFetchFromDb = true;

                                          if (v == 'Mother') {
                                            if (widget.headSpouseMobile != null && widget.headSpouseMobile!.isNotEmpty) {
                                              mobileNumber = widget.headSpouseMobile;
                                              print('📱 [AddNewMember] Using spouse mobile from props: $mobileNumber');
                                              shouldFetchFromDb = false;
                                            }
                                          }
                                          else if ((v == 'Family Head' || v == 'Father') &&
                                              widget.headMobileNumber != null &&
                                              widget.headMobileNumber!.isNotEmpty) {
                                            mobileNumber = widget.headMobileNumber;
                                            print('📱 [AddNewMember] Using head mobile from props: $mobileNumber');
                                            shouldFetchFromDb = false;
                                          }

                                          if (shouldFetchFromDb && _isMemberDetails && widget.hhId != null) {
                                            try {
                                              if (v == 'Mother') {
                                                mobileNumber = await LocalStorageDao.instance.getSpouseMobileNumber(widget.hhId!);
                                                print('📱 [AddNewMember] Fetched spouse mobile from DB: $mobileNumber');
                                              } else {
                                                mobileNumber = await LocalStorageDao.instance.getHeadMobileNumber(widget.hhId!);
                                                print('📱 [AddNewMember] Fetched head mobile from DB: $mobileNumber');
                                              }
                                            } catch (e) {
                                              print('❌ Error fetching mobile number: $e');
                                            }
                                          }

                                          // Update the mobile number if found
                                          if (mobileNumber != null && mobileNumber.isNotEmpty) {
                                            print('📱 [AddNewMember] Setting mobile number: $mobileNumber for $v');
                                            bloc.add(AnmUpdateMobileNo(mobileNumber));
                                          } else if (mobileNumber == null && mounted) {
                                            // Show error if no mobile number found
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l?.no_mobile_found_for_head ?? 'No mobile number found',
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          // For any other selection, clear the mobile number
                                          bloc.add(AnmUpdateMobileNo(''));
                                        }
                                      },
                                      validator: (value) => _captureAnmError(
                                        Validations.validateWhoMobileNo(
                                          l,
                                          value,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (state.mobileOwner == 'Other')
                                    _section(
                                      CustomTextField(
                                        labelText:
                                        '${l?.enter_relation_with_mobile_holder ?? "Enter relation with mobile no. holder"} *',
                                        hintText:
                                        l?.enter_relation_with_mobile_holder ??'Enter relation with mobile no. holder',
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(
                                          AnmUpdateMobileOwnerRelation(
                                            v.trim(),
                                          ),
                                        ),
                                        validator: (value) =>
                                        state.mobileOwner == 'Other'
                                            ? _captureAnmError(
                                          (value == null ||
                                              value.trim().isEmpty)
                                              ?l?.relation_with_mobile_holder_required ?? 'Relation with mobile no. holder is required'
                                              : null,
                                        )
                                            : null,
                                      ),
                                    ),
                                  if (state.mobileOwner == 'Other')
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  _section(
                                    CustomTextField(
                                      key: ValueKey(
                                        'member_mobile_${state.mobileOwner ?? ''}',
                                      ),
                                      controller:
                                      TextEditingController(
                                        text: state.mobileNo ?? '',
                                      )
                                        ..selection =
                                        TextSelection.collapsed(
                                          offset:
                                          state.mobileNo?.length ??
                                              0,
                                        ),
                                      labelText: '${l.mobileLabel} *',
                                      hintText: '${l.mobileLabel} *',
                                      keyboardType: TextInputType.number,
                                      maxLength: 10,
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateMobileNo(v.trim())),
                                      validator: (value) => _captureAnmError(
                                        Validations.validateMobileNo(l, value),
                                      ),
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
                                ],
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: state.useDob,
                                        onChanged: widget.isEdit ? null :(_) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmToggleUseDob()),
                                      ),
                                      Text(l.dobShort),
                                      const SizedBox(width: 16),
                                      Radio<bool>(
                                        value: false,
                                        groupValue: state.useDob,
                                        onChanged: widget.isEdit ? null :(_) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmToggleUseDob()),
                                      ),
                                      Text("${l.ageApproximate}"),
                                    ],
                                  ),
                                ),
                                if (state.useDob)
                                  _section(
                                      IgnorePointer(
                                        ignoring: widget.isEdit,

                                        child: CustomDatePicker(
                                          labelText: '${l.dobLabel}  *',
                                          initialDate: state.dob,

                                          firstDate:
                                          (state.memberType.toLowerCase() ==
                                              'child')
                                              ? childMinDate // child minimum age = today - 15 years
                                              : adultMinDate, // adult minimum age = today - 110 years

                                          lastDate:
                                          (state.memberType.toLowerCase() ==
                                              'child')
                                              ? childMaxDate
                                              : adultMaxDate,

                                          onDateChanged: (date) {
                                            if (date != null) {
                                              context
                                                  .read<AddnewfamilymemberBloc>()
                                                  .add(AnmUpdateDob(date));
                                            }
                                          },
                                          validator: (date) {
                                            if (date == null) {
                                              return _captureAnmError(
                                                l?.dob_required ?? 'Date of birth is required',

                                              );
                                            }

                                            final today = DateTime.now();
                                            final dobDate = DateTime(
                                              date.year,
                                              date.month,
                                              date.day,
                                            );
                                            final todayDate = DateTime(
                                              today.year,
                                              today.month,
                                              today.day,
                                            );

                                            if (dobDate.isAfter(todayDate)) {
                                              return _captureAnmError(
                                                l?.dob_cannot_be_future ?? 'Date of birth cannot be in the future',
                                              );
                                            }

                                            // Apply the 1 day–15 years rule only when member type is Child
                                            final memberType =
                                            (state.memberType ?? '')
                                                .trim()
                                                .toLowerCase();
                                            if (memberType == 'child') {
                                              final diffDays = todayDate
                                                  .difference(dobDate)
                                                  .inDays;

                                              const int minDays = 1;
                                              const int maxDays = 15 * 365;

                                              if (diffDays < minDays ||
                                                  diffDays > maxDays) {
                                                return _captureAnmError(
                                                  l?.child_age_validation ?? 'For Child: Age should be between 1 day to 15 years.',
                                                );
                                              }
                                            }

                                            // For adults, no extra age-range restriction beyond not-future
                                            return null;
                                          },
                                        ),
                                      )
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
                                                    color: Colors
                                                        .red, // Make asterisk red
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
                                                labelText: l?.years ??'Years',
                                                hintText: '0',
                                                maxLength: 3,
                                                initialValue:
                                                state.updateYear ?? '',
                                                keyboardType:
                                                TextInputType.number,
                                                onChanged: (v) => context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  UpdateYearChanged(
                                                    v.trim(),
                                                  ),
                                                ),
                                                validator: (value) => _captureAnmError(
                                                  (state.memberType
                                                      .toLowerCase() ==
                                                      'child')
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
                                                labelText: l?.months ?? 'Months',
                                                hintText: '0',
                                                maxLength: 2,
                                                initialValue:
                                                state.updateMonth ?? '',
                                                keyboardType:
                                                TextInputType.number,
                                                onChanged: (v) => context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  UpdateMonthChanged(
                                                    v.trim(),
                                                  ),
                                                ),
                                                validator: (value) => _captureAnmError(
                                                  (state.memberType
                                                      .toLowerCase() ==
                                                      'child')
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
                                                labelText: l?.days ?? 'Days',
                                                hintText: '0',
                                                maxLength: 2,
                                                initialValue:
                                                state.updateDay ?? '',
                                                keyboardType:
                                                TextInputType.number,
                                                onChanged: (v) => context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  UpdateDayChanged(
                                                    v.trim(),
                                                  ),
                                                ),
                                                validator: (value) => _captureAnmError(
                                                  (state.memberType
                                                      .toLowerCase() ==
                                                      'child')
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
                                        ),
                                      ],
                                    ),
                                  ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                // Birth order field - only show in edit mode for children
                                if (_isEdit && (state.memberType ?? '').toLowerCase() == 'child') ...[
                                  _section(
                                    ApiDropdown<String>(
                                      labelText: l.birthOrderLabel,
                                      items: const [
                                        '1',
                                        '2',
                                        '3',
                                        '4',
                                        '5',
                                        '6',
                                        '7',
                                        '8',
                                        '9',
                                        '10',
                                      ],
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
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateBirthOrder(v ?? '')),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],

                                if ((state.memberType ?? '').toLowerCase() ==
                                    'adult') ...[
                                  _section(
                                    IgnorePointer(
                                      ignoring: widget.isEdit,
                                      child:ApiDropdown<String>(
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
                                        onChanged: (v) {
                                          if (v == null) return;
                                          final memberGender = v;
                                          context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(AnmUpdateGender(memberGender));
                                          try {
                                            if (_syncingGender) return;
                                            _syncingGender = true;
                                            final opposite = _oppositeGender(
                                              memberGender,
                                            );
                                            final spBloc = context
                                                .read<SpousBloc>();
                                            if (spBloc.state.gender != opposite) {
                                              spBloc.add(
                                                SpUpdateGender(opposite),
                                              );
                                            }
                                          } finally {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              _syncingGender = false;
                                            });
                                          }
                                        },
                                        validator: (value) => _captureAnmError(
                                          Validations.validateGender(l, value),
                                        ),
                                      ),
                                    )
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
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
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateOccupation(v!)),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (state.occupation == 'Other')
                                    _section(
                                      CustomTextField(
                                        labelText:l?.enter_other_occupation ?? 'Enter occupation',
                                        hintText:l?.enter_other_occupation ?? 'Enter occupation',
                                        initialValue: state.otherOccupation,
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(
                                          AnmUpdateOtherOccupation(
                                            v.trim(),
                                          ),
                                        ),
                                      ),
                                    ),
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
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateEducation(v!)),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],

                                if (state.memberType == 'Child') ...[
                                  _section(
                                    CustomTextField(
                                      labelText:l?.weightRange ?? 'Weight (1.2-90)Kg',
                                      hintText:l?.weightRange ?? 'Weight (1.2-90)Kg',
                                      keyboardType: TextInputType.number,
                                      initialValue: state.WeightChange ?? '',
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(WeightChange(v.trim())),
                                      validator: (value) {
                                        final trimmed = value?.trim() ?? '';
                                        if (trimmed.isEmpty) {
                                          return null; // optional field
                                        }

                                        final parsed = double.tryParse(trimmed);
                                        if (parsed == null) {
                                          return _captureAnmError(
                                            l?.enter_valid_weight ?? 'Please enter a valid weight',
                                          );
                                        }

                                        if (parsed < 1.2 || parsed > 90) {
                                          return _captureAnmError(
                                            l?.weight_range_validation ??  'Weight must be between 1.2 and 90 Kg',
                                          );
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (() {
                                    final yy =
                                        int.tryParse(state.updateYear ?? '0') ??
                                            0;
                                    final mm =
                                        int.tryParse(
                                          state.updateMonth ?? '0',
                                        ) ??
                                            0;
                                    final dd =
                                        int.tryParse(state.updateDay ?? '0') ??
                                            0;

                                    if (yy == 0 && mm == 0 && dd == 0) {
                                      return false;
                                    }

                                    // Check if age is exactly 1 year, 3 months, and 1 day or more
                                    if (yy > 1) return false;
                                    if (yy == 1 && mm > 3) return false;
                                    if (yy == 1 && mm == 3 && dd >= 1)
                                      return false;

                                    return true; // Show only if age is less than 1 year, 3 months, and 1 day
                                  }()) ...[
                                    _section(
                                      CustomTextField(
                                        labelText:l?.weight_at_birth ??
                                            'Birth Weight (1200-4000)gms',
                                        hintText: l?.weight_at_birth ??'Birth Weight (1200-4000)gms',
                                        keyboardType: TextInputType.number,
                                        initialValue: state.birthWeight ?? '',
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(
                                          BirthWeightChange(
                                            v?.trim() ?? '',
                                          ),
                                        ),
                                        validator: (value) {
                                          final trimmed = value?.trim() ?? '';
                                          if (trimmed.isEmpty) {
                                            return null; // optional field
                                          }

                                          final parsed = int.tryParse(trimmed);
                                          if (parsed == null) {
                                            return _captureAnmError(
                                              l?.enter_valid_birth_weight ??  'Please enter a valid birth weight',
                                            );
                                          }

                                          if (parsed < 1200 || parsed > 4000) {
                                            return _captureAnmError(
                                              l?.birth_weight_range_validation ?? 'Birth weight must be between 1200 and 4000 gms',
                                            );
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  ],
                                  _section(
                                    ApiDropdown<String>(
                                      labelText:l?.is_birth_certificate_issued ?? 'is birth certificate issued?',
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
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(BirthCertificateChange(v!)),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  _section(
                                    ApiDropdown<String>(
                                      labelText:l?.is_school_going_child ?? 'is He/She school going child',
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
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(ChildSchoolChange(v!)),
                                    ),
                                  ),
                                ],
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
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
                                    onChanged: (v) {
                                      if (v == null) return;
                                      context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateReligion(v));
                                    },
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                if (state.religion == 'Other')
                                  _section(
                                    CustomTextField(
                                      labelText:l?.enter_religion ?? 'Enter Religion',
                                      hintText:l?.enter_religion ?? 'Enter Religion',
                                      initialValue: state.otherReligion,
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(
                                        AnmUpdateOtherReligion(v.trim()),
                                      ),
                                    ),
                                  ),
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
                                    onChanged: (v) {
                                      if (v == null) return;
                                      context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateCategory(v));
                                    },
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                if (state.category == 'Other')
                                  _section(
                                    CustomTextField(
                                      labelText:l?.enter_category ?? 'Enter Category',
                                      hintText:l?.enter_category ?? 'Enter Category',
                                      initialValue: state.otherCategory,
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(
                                        AnmUpdateOtherCategory(v.trim()),
                                      ),
                                    ),
                                  ),
                                if (state.category == 'Other')
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                _section(
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      IgnorePointer(
                                        ignoring: widget.isEdit,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: CustomTextField(
                                                labelText: l.abhaAddressLabel,
                                                hintText: l.abhaAddressLabel,
                                                initialValue: state.abhaAddress,
                                                onChanged: (v) => context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmUpdateAbhaAddress(
                                                    v.trim(),
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

                                                  debugPrint("BACK FROM ABHA LINK SCREEN (New Member)");
                                                  debugPrint("RESULT: $result");

                                                  if (result is Map<String, dynamic> && mounted) {
                                                    _handleAbhaProfileResult(result, context);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                if ((state.memberType ?? '').toLowerCase() ==
                                    'adult') ...[
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
                                        final bloc = context.read<AddnewfamilymemberBloc>();

                                        bloc.add(AnmUpdateMobileOwner(v));

                                        bloc.add(AnmUpdateMobileNo(''));

                                        if (v == 'Family Head' || v == "Father" || v == "Mother") {
                                          String? mobileNumber;
                                          bool shouldFetchFromDb = true;

                                          if (v == 'Mother') {
                                            if (widget.headSpouseMobile != null && widget.headSpouseMobile!.isNotEmpty) {
                                              mobileNumber = widget.headSpouseMobile;
                                              print('📱 [AddNewMember] Using spouse mobile from props: $mobileNumber');
                                              shouldFetchFromDb = false;
                                            }
                                          }
                                          else if ((v == 'Family Head' || v == 'Father') &&
                                              widget.headMobileNumber != null &&
                                              widget.headMobileNumber!.isNotEmpty) {
                                            mobileNumber = widget.headMobileNumber;
                                            print('📱 [AddNewMember] Using head mobile from props: $mobileNumber');
                                            shouldFetchFromDb = false;
                                          }

                                          if (shouldFetchFromDb && _isMemberDetails && widget.hhId != null) {
                                            try {
                                              if (v == 'Mother') {
                                                mobileNumber = await LocalStorageDao.instance.getSpouseMobileNumber(widget.hhId!);
                                                print('📱 [AddNewMember] Fetched spouse mobile from DB: $mobileNumber');
                                              } else {
                                                mobileNumber = await LocalStorageDao.instance.getHeadMobileNumber(widget.hhId!);
                                                print('📱 [AddNewMember] Fetched head mobile from DB: $mobileNumber');
                                              }
                                            } catch (e) {
                                              print('❌ Error fetching mobile number: $e');
                                            }
                                          }

                                          // Update the mobile number if found
                                          if (mobileNumber != null && mobileNumber.isNotEmpty) {
                                            print('📱 [AddNewMember] Setting mobile number: $mobileNumber for $v');
                                            bloc.add(AnmUpdateMobileNo(mobileNumber));
                                          } else if (mobileNumber == null && mounted) {
                                            // Show error if no mobile number found
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l?.no_mobile_found_for_head ?? 'No mobile number found',
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          // For any other selection, clear the mobile number
                                          bloc.add(AnmUpdateMobileNo(''));
                                        }
                                      },
                                      validator: (value) => _captureAnmError(
                                        Validations.validateWhoMobileNo(
                                          l,
                                          value,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (state.mobileOwner == 'Other')
                                    _section(
                                      CustomTextField(
                                        labelText:
                                        '${l?.enter_relation_with_mobile_holder ?? "Enter relation with mobile no. holder"} *',
                                        hintText:
                                        l?.enter_relation_with_mobile_holder ??'Enter relation with mobile no. holder',
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(
                                          AnmUpdateMobileOwnerRelation(
                                            v.trim(),
                                          ),
                                        ),
                                        validator: (value) =>
                                        state.mobileOwner == 'Other'
                                            ? _captureAnmError(
                                          (value == null ||
                                              value.trim().isEmpty)
                                              ? (l?.relation_with_mobile_holder_required ??'Relation with mobile no. holder is required')
                                              : null,
                                        )
                                            : null,
                                      ),
                                    ),
                                  if (state.mobileOwner == 'Other')
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  _section(
                                    CustomTextField(
                                      key: ValueKey(
                                        'member_mobile_${state.mobileOwner ?? ''}',
                                      ),
                                      controller:
                                      TextEditingController(
                                        text: state.mobileNo ?? '',
                                      )
                                        ..selection =
                                        TextSelection.collapsed(
                                          offset:
                                          state.mobileNo?.length ??
                                              0,
                                        ),
                                      labelText: '${l.mobileLabel} *',
                                      hintText: '${l.mobileLabel} *',
                                      keyboardType: TextInputType.number,
                                      maxLength: 10,
                                      onChanged: (v) => context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateMobileNo(v.trim())),
                                      validator: (value) => _captureAnmError(
                                        Validations.validateMobileNo(l, value),
                                      ),
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
                                ],

                                // Bank account
                                _section(
                                  CustomTextField(
                                    labelText: l.accountNumberLabel,
                                    hintText: l.accountNumberLabel,
                                    keyboardType: TextInputType.number,
                                    initialValue: state.bankAcc,
                                    onChanged: (v) {
                                      final value = v.trim();
                                      context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateBankAcc(value));
                                      // Clear previous snackbar
                                      ScaffoldMessenger.of(
                                        context,
                                      ).removeCurrentSnackBar();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null; // Field is optional
                                      }

                                      // Remove any non-digit characters
                                      final digitsOnly = value.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );

                                      if (digitsOnly.length < 11 ||
                                          digitsOnly.length > 18) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            showAppSnackBar(
                                              context,
                                              l?.bank_account_length_error ?? 'Bank account number must be between 11 to 18 digits',
                                            );
                                          }
                                        });
                                        return l?.invalid_length ??'Invalid length';
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
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                _section(
                                  CustomTextField(
                                    labelText: l.ifscLabel,
                                    hintText: l.ifscLabel,
                                    initialValue: state.ifsc,
                                    maxLength: 11,
                                    onChanged: (v) {
                                      final value = v.trim().toUpperCase();
                                      // Clear previous snackbar
                                      ScaffoldMessenger.of(
                                        context,
                                      ).removeCurrentSnackBar();

                                      // Always update the state with the current value
                                      context
                                          .read<AddnewfamilymemberBloc>()
                                          .add(AnmUpdateIfsc(value));

                                      // Validate the input
                                      String? error;
                                      if (value.isNotEmpty) {
                                        // Only validate if there's input
                                        if (value.length != 11) {
                                          error =
                                              l?.ifsc_invalid_length??  'Please enter a valid 11-character IFSC code';
                                        } else if (!RegExp(
                                          r'^[A-Z]{4}0\d{6}$',
                                        ).hasMatch(value)) {
                                          error =
                                              l?.ifsc_invalid_format ?? 'IFSC code must have first 4 uppercase letters, followed by 0 and 6 digits';
                                        }

                                        if (error != null) {
                                          // Show error snackbar but keep the current value in the state
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              backgroundColor: Colors.orange,
                                              duration: const Duration(
                                                seconds: 3,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return null; // Field is optional
                                      }

                                      String? error;
                                      if (value.length != 11) {
                                        error =
                                            l?.ifsc_invalid_length ?? 'Please enter a valid 11-character IFSC code';
                                      } else if (!RegExp(
                                        r'^[A-Z]{4}0\d{6}$',
                                      ).hasMatch(value)) {
                                        error =
                                            l?.ifsc_invalid_format ?? 'IFSC code must have first 4 uppercase letters, followed by 0 and 6 digits';
                                      }

                                      if (error != null) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            showAppSnackBar(
                                              context,
                                              error!,
                                            );
                                          }
                                        });
                                      }

                                      return error;
                                    },
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                // IDs
                                _section(
                                  CustomTextField(
                                    labelText: l.voterIdLabel,
                                    hintText: l.voterIdLabel,
                                    initialValue: state.voterId,
                                    onChanged: (v) => context
                                        .read<AddnewfamilymemberBloc>()
                                        .add(AnmUpdateVoterId(v.trim())),
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
                                        .read<AddnewfamilymemberBloc>()
                                        .add(AnmUpdateRationId(v.trim())),
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
                                        .read<AddnewfamilymemberBloc>()
                                        .add(AnmUpdatePhId(v.trim())),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

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
                                        .read<AddnewfamilymemberBloc>()
                                        .add(AnmUpdateBeneficiaryType(v!)),
                                  ),
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),
                                if (state.memberType != 'Child')
                                  _section(
                                    ApiDropdown<String>(
                                      labelText: '${l.maritalStatusLabel} *',
                                      hintText: '${l.maritalStatusLabel} *',
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
                                      onChanged: (v) {
                                        context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmUpdateMaritalStatus(v!));
                                        setState(() {
                                          _currentStep = 0;
                                        });
                                        final ctrl = DefaultTabController.of(
                                          context,
                                        );
                                        ctrl?.animateTo(0);
                                      },
                                      validator: (value) {
                                        if (state.memberType == 'Child')
                                          return null;
                                        return _captureAnmError(
                                          Validations.validateMaritalStatus(
                                            l,
                                            value,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (state.memberType != 'Child')
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                if (state.maritalStatus == 'Married') ...[
                                  if (!_isEdit) ...[
                                    _section(
                                      CustomTextField(
                                        labelText: l.ageAtMarriageLabel,
                                        hintText: l.ageAtMarriageLabel,
                                        keyboardType: TextInputType.number,
                                        initialValue: state.ageAtMarriage,
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmUpdateAgeAtMarriage(v)),


                                      ),
                                    ),
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  ],

                                  // Spouse name field - hide in edit mode
                                  if (!_isEdit) ...[
                                    _section(
                                      CustomTextField(
                                        labelText: '${l.spouseNameLabel} *',
                                        hintText: l.spouseNameHint,
                                        initialValue: state.spouseName,
                                        onChanged: (v) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmUpdateSpouseName(v.trim())),
                                        validator: (value) {
                                          if (state.maritalStatus == 'Married') {
                                            return _captureAnmError(Validations.validateSpousName(l, value));
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  ],

                                  if (!_isEdit) ...[
                                      _section(
                                        ApiDropdown<String>(
                                          labelText: l.haveChildrenQuestion,
                                          items: const ['Yes', 'No'],
                                          getLabel: (s) =>
                                              s == 'Yes' ? l.yes : l.no,
                                          value: state.hasChildren,
                                          onChanged: (v) {
                                            context
                                                .read<AddnewfamilymemberBloc>()
                                                .add(AnmUpdateHasChildren(v!));
                                            setState(() {
                                              _currentStep = 0;
                                            });
                                            final ctrl = DefaultTabController.of(
                                              context,
                                            );
                                            ctrl?.animateTo(0);
                                          },
                                        ),
                                      ),
                                    ],
                                  if (!_isEdit)
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ] else if (!_isEdit &&
                                    state.maritalStatus != null &&
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
                                      onChanged: (v) {
                                        if (v != null) {
                                          context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(ChildrenChanged(v.trim()));
                                        }
                                      },
                                    ),
                                  ),
                                ],

                                if (state.memberType == 'Adult' &&
                                    state.maritalStatus == 'Married' &&
                                    state.gender == 'Female') ...[
                                  if(!_isEdit) ... [
                                    _section(
                                      ApiDropdown<String>(
                                        key: ValueKey(
                                          'is_pregnant_${state.gender}_${state.isPregnant ?? ''}',
                                        ),
                                        labelText:
                                        '${l.isWomanPregnantQuestion} *',
                                        items: const ['Yes', 'No'],
                                        getLabel: (s) =>
                                        s == 'Yes' ? l.yes : l.no,
                                        value: state.isPregnant,
                                        onChanged: (v) {
                                          final bloc = context
                                              .read<AddnewfamilymemberBloc>();
                                          bloc.add(AnmUpdateIsPregnant(v!));
                                          if (v == 'No') {
                                            bloc.add(const AnmLMPChange(null));
                                            bloc.add(const AnmEDDChange(null));
                                          }
                                        },
                                        validator: (value) {
                                          if (state.gender == 'Female') {
                                            return Validations.validateIsPregnant(
                                              l,
                                              value,
                                            );
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                  const Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                  if (!_isEdit && state.isPregnant == 'Yes') ...[
                                    _section(
                                      CustomDatePicker(
                                        key: const ValueKey('lmp_date_picker'),
                                        labelText: '${l.lmpDateLabel} *',
                                        hintText: l.dateHint,
                                        initialDate: state.lmp,
                                        onDateChanged: (d) {
                                          final bloc = context
                                              .read<AddnewfamilymemberBloc>();
                                          bloc.add(AnmLMPChange(d));
                                          if (d != null) {
                                            final edd = d.add(const Duration(days: 277));
                                            bloc.add(AnmEDDChange(edd));
                                          } else {
                                            bloc.add(const AnmEDDChange(null));
                                          }
                                        },
                                        validator: (date) =>
                                            Validations.validateLMP(l, date),
                                        firstDate: DateTime.now().subtract(
                                          const Duration(days: 276),
                                        ),
                                        lastDate: DateTime.now().subtract(const Duration(days: 31)),
                                      ),
                                    ),
                                    const Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),

                                    _section(
                                      CustomDatePicker(
                                        key: const ValueKey('edd_date_picker'),
                                        labelText: '${l.eddDateLabel} *',
                                        hintText: l.dateHint,
                                        initialDate: state.edd,
                                        onDateChanged: (d) => context
                                            .read<AddnewfamilymemberBloc>()
                                            .add(AnmEDDChange(d)),
                                        validator: (date) =>
                                            Validations.validateEDD(l, date),
                                        readOnly: true,
                                      ),
                                    ),
                                    const Divider(
                                      color: AppColors.divider,
                                      thickness: 0.5,
                                      height: 0,
                                    ),
                                  ],

                                  if(!_isEdit)... [
                                    if (state.isPregnant == 'No') ...[
                                      _section(
                                        ApiDropdown<String>(
                                          key: const ValueKey('family_planning'),
                                          labelText:
                                          '${l?.fpAdoptingLabel ?? "Are you/your partner adopting family planning?"} *',
                                          items: const ['Yes', 'No'],
                                          getLabel: (s) =>
                                          s == 'Yes' ? l.yes : l.no,
                                          value: state.isFamilyPlanning,
                                          onChanged: (v) => context
                                              .read<AddnewfamilymemberBloc>()
                                              .add(
                                            AnmUpdateFamilyPlanning(v ?? ''),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value == l.select) {
                                              return l?.please_select_family_planning_status ??'Please select family planning status';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const Divider(
                                        color: AppColors.divider,
                                        thickness: 0.5,
                                        height: 0,
                                      ),

                                      if (state.isFamilyPlanning == 'Yes') ...[
                                        _section(
                                          ApiDropdown<String>(
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
                                            getLabel: (value) {
                                              switch (value) {

                                                case 'Condom':
                                                  return l.condom;
                                                case 'Mala -N (Daily Contraceptive pill)':
                                                  return l.malaN;
                                                case 'Antra injection':
                                                  return l.antraInjection;
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
                                                  return l.anyOtherSpecify;
                                                default:
                                                  return value;
                                              }
                                            },
                                            value: state.fpMethod ?? 'Select',
                                            onChanged: (value) {
                                              if (value != null) {
                                                context
                                                    .read<AddnewfamilymemberBloc>()
                                                    .add(AnmFpMethodChanged(value));
                                              }
                                            },
                                            validator: (value) =>
                                                _captureAnmError(Validations.validateAntra(l, value)),
                                          ),

                                          /* ApiDropdown<String>(
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
                                            'Any Other Specify',
                                          ],
                                          getLabel: (value) => value,
                                          value: state.fpMethod ?? 'Select',
                                          onChanged: (value) {
                                            if (value != null) {
                                              context
                                                  .read<
                                                    AddnewfamilymemberBloc
                                                  >()
                                                  .add(
                                                    AnmFpMethodChanged(value),
                                                  );
                                            }
                                          },
                                          validator: (value) =>
                                              _captureAnmError(
                                                Validations.validateAntra(
                                                  l,
                                                  value,
                                                ),
                                              ),
                                        ),*/
                                        ),
                                        Divider(
                                          color: AppColors.divider,
                                          thickness: 0.5,
                                          height: 0,
                                        ),

                                        if (state.fpMethod ==
                                            'Antra injection') ...[
                                          _section(
                                            CustomDatePicker(
                                              labelText: l?.dateOfAntra ?? 'Date of Antra',
                                              initialDate:
                                              state.antraDate ??
                                                  DateTime.now(),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime(2100),
                                              onDateChanged: (date) {
                                                if (date != null) {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmFpDateOfAntraChanged(
                                                      date,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],

                                        if (state.fpMethod ==
                                            'Copper -T (IUCD)') ...[
                                          _section(
                                            CustomDatePicker(
                                              labelText: l?.removalDate ?? 'Removal Date',
                                              initialDate:
                                              state.removalDate ??
                                                  DateTime.now(),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime(2100),
                                              onDateChanged: (date) {
                                                if (date != null) {
                                                  context
                                                      .read<
                                                      AddnewfamilymemberBloc
                                                  >()
                                                      .add(
                                                    AnmFpRemovalDateChanged(
                                                      date,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                          _section(
                                            CustomTextField(
                                              labelText:l?.reasonLabel ?? 'Reason',
                                              hintText:l?.reasonLabel ?? 'reason ',
                                              initialValue: state.removalReason,
                                              onChanged: (value) {
                                                context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmFpRemovalReasonChanged(
                                                    value ?? '',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],

                                        if (state.fpMethod == 'Condom') ...[
                                          _section(
                                            CustomTextField(
                                              labelText:l?.quantityOfCondoms ?? 'Quantity of Condoms',
                                              hintText:l?.quantityOfCondoms ?? 'Quantity of Condoms',
                                              keyboardType: TextInputType.number,
                                              initialValue: state.condomQuantity,
                                              onChanged: (value) {
                                                context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmFpCondomQuantityChanged(
                                                    value ?? '',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],

                                        if (state.fpMethod ==
                                            'Mala -N (Daily Contraceptive pill)') ...[
                                          _section(
                                            CustomTextField(
                                              labelText:l?.quantityOfMalaN ??
                                                  'Quantity of Mala -N (Daily Contraceptive pill)',
                                              hintText:l?.quantityOfMalaN ??
                                                  'Quantity of Mala -N (Daily Contraceptive pill)',
                                              keyboardType: TextInputType.number,
                                              initialValue: state.malaQuantity,
                                              onChanged: (value) {
                                                context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmFpMalaQuantityChanged(
                                                    value ?? '',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],

                                        if (state.fpMethod ==
                                            'Chhaya (Weekly Contraceptive pill)') ...[
                                          _section(
                                            CustomTextField(
                                              labelText:l?.quantityOfChhaya ??
                                                  'Quantity of Chhaya (Weekly Contraceptive pill)',
                                              hintText: l?.quantityOfChhaya ??
                                                  'Quantity of Chhaya (Weekly Contraceptive pill)',
                                              keyboardType: TextInputType.number,
                                              initialValue: state.chhayaQuantity,
                                              onChanged: (value) {
                                                context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmFpChhayaQuantityChanged(
                                                    value ?? '',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],

                                        if (state.fpMethod ==
                                            'ECP (Emergency Contraceptive pill)') ...[
                                          _section(
                                            CustomTextField(
                                              labelText:l?.quantityOfECP ??
                                                  'Quantity of ECP (Emergency Contraceptive pill)',
                                              hintText:l?.quantityOfECP ??
                                                  'Quantity of ECP (Emergency Contraceptive pill)',
                                              keyboardType: TextInputType.number,
                                              initialValue: state.ecpQuantity,
                                              onChanged: (value) {
                                                context
                                                    .read<
                                                    AddnewfamilymemberBloc
                                                >()
                                                    .add(
                                                  AnmFpEcpQuantityChanged(
                                                    value ?? '',
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            color: AppColors.divider,
                                            thickness: 0.5,
                                            height: 0,
                                          ),
                                        ],
                                      ],
                                    ],
                                  ]
                                ],
                              ],
                            ));
                          },
                        ),
                      ),
                    ),

                    BlocListener<
                        AddnewfamilymemberBloc,
                        AddnewfamilymemberState
                    >(
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
                            if ((result['spouseName'] == null ||
                                (result['spouseName'] as String).isEmpty) &&
                                _spouseName != null &&
                                _spouseName!.isNotEmpty) {
                              result['spouseName'] = _spouseName;
                            }
                          } catch (_) {}
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.of(
                                context,
                              ).pop<Map<String, dynamic>>(result);
                            }
                          });
                        }
                      },
                      child: SafeArea(
                        child: Container(
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: BlocBuilder<AddnewfamilymemberBloc, AddnewfamilymemberState>(
                              builder: (context, state) {
                                final isLoading =
                                    state.postApiStatus ==
                                        PostApiStatus.loading;

                                return Row(
                                  mainAxisAlignment: _isEdit
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (!_isEdit) ...[
                                      if (_currentStep > 0)
                                        SizedBox(
                                          width: 25.5.w,
                                          height: 4.5.h,
                                          child: RoundButton(
                                            title: l.previousButton,
                                            color: AppColors.primary,
                                            borderRadius: 4,
                                            height: 4.9.h,
                                            isLoading: false,
                                            onPress: () {
                                              if (_currentStep > 0) {
                                                setState(() {
                                                  _currentStep -= 1;
                                                });
                                                final ctrl =
                                                DefaultTabController.of(
                                                  context,
                                                );
                                                ctrl?.animateTo(_currentStep);
                                              }
                                            },
                                          ),
                                        )
                                      else
                                        const SizedBox.shrink(),
                                    ],
                                    SizedBox(
                                      width: 25.5.w,
                                      height: 4.5.h,
                                      child: RoundButton(
                                        title: () {
                                          final bool isUpdateContext = _isEdit;

                                          if (isLoading) {
                                            return isUpdateContext
                                                ? l?.updating ?? 'UPDATING...'
                                                : l.addingButton;
                                          }

                                          if (isUpdateContext) {
                                            return l?.updateButton ?? 'UPDATE';
                                          }

                                          final bool showSpouse =
                                              !_isEdit &&
                                                  state.memberType != 'Child' &&
                                                  state.maritalStatus == 'Married';
                                          final bool showChildren =
                                              !_isEdit &&
                                                  showSpouse &&
                                                  state.hasChildren == 'Yes';
                                          final lastStep = showChildren
                                              ? 2
                                              : (showSpouse ? 1 : 0);
                                          return (_currentStep < lastStep)
                                              ? l?.nextButton ?? 'Next'
                                              : l.addButton;
                                        }(),
                                        color: AppColors.primary,
                                        borderRadius: 4,
                                        height: 44,
                                        isLoading: isLoading,
                                        onPress: () async {
                                          _clearAnmFormError();
                                          clearSpousFormError();

                                          final bool showSpouse =
                                              state.memberType != 'Child' &&
                                                  state.maritalStatus == 'Married';
                                          final bool showChildren =
                                              showSpouse &&
                                                  state.hasChildren == 'Yes';
                                          final int lastStep = showChildren
                                              ? 2
                                              : (showSpouse ? 1 : 0);

                                          if (_currentStep == 1) {
                                            final spouseForm =
                                                spousFormKey.currentState;
                                            if (spouseForm == null ||
                                                !spouseForm.validate()) {
                                              final msg =
                                                  spousLastFormError ??
                                                      l?.fillSpouseDetails ?? 'Please fill all required fields in the spouse details before continuing.';
                                              showAppSnackBar(context, msg);
                                              return;
                                            }
                                          }

                                          if (!_isEdit &&
                                              _currentStep < lastStep) {
                                            // Validate current form before moving to next step
                                            final formState = _formKey.currentState;
                                            if (formState == null) return;
                                            
                                            final isValid = formState.validate();
                                            if (!isValid) {
                                              final msg =
                                                  _anmLastFormError ??
                                                      l?.pleaseCorrectErrors ?? 'Please correct the highlighted errors before continuing.';
                                              showAppSnackBar(context, msg);
                                              _scrollToFirstError();
                                              return;
                                            }
                                            
                                            final newStep = _currentStep + 1;
                                            setState(() {
                                              _currentStep = newStep;
                                            });

                                            // Get the tab controller and animate to the new step
                                            final tabController =
                                            DefaultTabController.of(
                                              context,
                                            );
                                            if (tabController != null &&
                                                newStep <
                                                    tabController.length) {
                                              tabController.animateTo(newStep);
                                            }
                                            return;
                                          }

                                          final formState =
                                              _formKey.currentState;
                                          if (formState == null) return;

                                          final isValid = formState.validate();
                                          if (!isValid) {
                                            final msg =
                                                _anmLastFormError ??
                                                    l?.pleaseCorrectErrors ?? 'Please correct the highlighted errors before continuing.';
                                            showAppSnackBar(context, msg);
                                            _scrollToFirstError();
                                            return;
                                          }

                                          try {
                                            // Get current state
                                            final bloc = context
                                                .read<AddnewfamilymemberBloc>();
                                            final state = bloc.state;

                                            if (state.useDob == true) {
                                              if (state.dob == null) {
                                                showAppSnackBar(
                                                  context,
                                                  l?.dob_required ?? 'Date of birth is required',
                                                );
                                                return;
                                              }

                                              final today = DateTime.now();
                                              final dobDate = DateTime(
                                                state.dob!.year,
                                                state.dob!.month,
                                                state.dob!.day,
                                              );
                                              final todayDate = DateTime(
                                                today.year,
                                                today.month,
                                                today.day,
                                              );

                                              if (dobDate.isAfter(todayDate)) {
                                                showAppSnackBar(
                                                  context,
                                                  l?.dob_cannot_be_future ?? 'Date of birth cannot be in the future',
                                                );
                                                return;
                                              }

                                              final memberType =
                                              (state.memberType ?? '')
                                                  .trim()
                                                  .toLowerCase();
                                              if (memberType == 'child') {
                                                final diffDays = todayDate
                                                    .difference(dobDate)
                                                    .inDays;

                                                const int minDays = 1;
                                                const int maxDays = 15 * 365;

                                                if (diffDays < minDays ||
                                                    diffDays > maxDays) {
                                                  showAppSnackBar(
                                                    context,
                                                    l?.child_age_validation ?? 'For Child: Age should be between 1 day to 15 years.',
                                                  );
                                                  return;
                                                }
                                              }
                                            }

                                            // Prepare base member data
                                            final memberData = {
                                              'memberType': state.memberType,
                                              'name': state.name,
                                              'relation': state.relation,
                                              'fatherName': state.fatherName,
                                              'motherName': state.motherName,
                                              'gender': state.gender,
                                              'useDob': state.useDob,
                                              'dob': state.dob
                                                  ?.toIso8601String(),
                                              'approxAge': state.approxAge,
                                              'children': state.children,
                                              'birthOrder': state.birthOrder,
                                              'maritalStatus':
                                              state.maritalStatus,
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
                                              'beneficiaryType':
                                              state.beneficiaryType,
                                              'abhaAddress': state.abhaAddress,
                                              'richId': state.RichIDChanged,
                                              'birthCertificate':
                                              state.BirthCertificateChange,
                                              'weight': state.WeightChange,
                                              'birthWeight': state.birthWeight,
                                              'school': state.ChildSchool,
                                              'hasChildren': state.hasChildren,
                                              'isPregnant': state.isPregnant,
                                              'ageAtMarriage':
                                              state.ageAtMarriage,
                                              'spouseName': state.spouseName,
                                              'createdAt': DateTime.now()
                                                  .toIso8601String(),
                                            };

                                            // Add spouse details if married
                                            if (state.maritalStatus
                                                ?.toLowerCase() ==
                                                'married' &&
                                                state.spouseName != null &&
                                                state.spouseName!.isNotEmpty) {
                                              print('👫 [AddNewMember] Adding spouse details - spouse name: ${state.spouseName}');
                                              // Get spouse data from SpousBloc
                                              final spouseState = _spousBloc.state;
                                              print('💑 [AddNewMember] Spouse state - useDob: ${spouseState.useDob}, dob: ${spouseState.dob}, approxAge: ${spouseState.approxAge}');
                                              
                                              // Calculate spouse age
                                              String calculatedSpouseAge = '';
                                              if (spouseState.useDob == true && spouseState.dob != null) {
                                                try {
                                                  final now = DateTime.now();
                                                  final dob = spouseState.dob!;
                                                  int years = now.year - dob.year;
                                                  if (now.month < dob.month ||
                                                      (now.month == dob.month && now.day < dob.day)) {
                                                    years--;
                                                  }
                                                  calculatedSpouseAge = years.toString();
                                                  print('🎂 [AddNewMember] Spouse age calculated from DOB: $calculatedSpouseAge (DOB: $dob)');
                                                } catch (_) {
                                                  calculatedSpouseAge = spouseState.approxAge ?? '';
                                                  print('❌ [AddNewMember] Error calculating spouse age from DOB, using approx: $calculatedSpouseAge');
                                                }
                                              } else {
                                                calculatedSpouseAge = spouseState.approxAge ?? '';
                                                print('📅 [AddNewMember] Spouse age from approximate: $calculatedSpouseAge');
                                              }
                                              
                                              final spouseDetailsData = {
                                                'relation':
                                                spouseState.relation ?? 'spouse',
                                                'memberName': spouseState.memberName,
                                                'ageAtMarriage':
                                                spouseState.ageAtMarriage,
                                                'RichIDChanged':
                                                spouseState.RichIDChanged,
                                                'spouseName': spouseState
                                                    .spouseName ?? state.name, // Original member's name
                                                'fatherName': spouseState.fatherName,
                                                'useDob': spouseState.useDob,
                                                'dob': spouseState.dob
                                                    ?.toIso8601String(),
                                                'edd': spouseState.edd
                                                    ?.toIso8601String(),
                                                'lmp': spouseState.lmp
                                                    ?.toIso8601String(),
                                                'approxAge': spouseState.approxAge,
                                                'age': calculatedSpouseAge, // Add calculated age
                                                'gender': spouseState.gender,
                                                'occupation': spouseState.occupation,
                                                'education': spouseState.education,
                                                'religion': spouseState.religion,
                                                'category': spouseState.category,
                                                'abhaAddress':
                                                spouseState.abhaAddress,
                                                'mobileOwner':
                                                spouseState.mobileOwner,
                                                'mobileNo': spouseState.mobileNo,
                                                'bankAcc': spouseState.bankAcc,
                                                'ifsc': spouseState.ifsc,
                                                'voterId': spouseState.voterId,
                                                'rationId': spouseState.rationId,
                                                'phId': spouseState.phId,
                                                'beneficiaryType':
                                                spouseState.beneficiaryType,
                                                'isPregnant': spouseState.isPregnant,
                                                'familyPlanningCounseling':
                                                spouseState.familyPlanningCounseling,
                                                'is_family_planning':
                                                (spouseState.familyPlanningCounseling
                                                    ?.toLowerCase() ==
                                                    'yes')
                                                    ? 1
                                                    : 0,
                                                'fpMethod': spouseState.fpMethod,
                                                'removalDate': spouseState.removalDate
                                                    ?.toIso8601String(),
                                                'removalReason':
                                                spouseState.removalReason,
                                                'condomQuantity':
                                                spouseState.condomQuantity,
                                                'malaQuantity':
                                                spouseState.malaQuantity,
                                                'chhayaQuantity':
                                                spouseState.chhayaQuantity,
                                                'ecpQuantity':
                                                spouseState.ecpQuantity,
                                                'maritalStatus': 'Married',
                                                'relation_to_head':
                                                state.relation,
                                                'isFamilyhead': false,
                                                'isFamilyheadWife': false,
                                                'createdAt': DateTime.now()
                                                    .toIso8601String(),
                                                'isSynced': false,
                                              };
                                              print('💾 [AddNewMember] Final spousedetails data: $spouseDetailsData');
                                              memberData['spousedetails'] = spouseDetailsData;
                                            } else {
                                              print('❌ [AddNewMember] Not married or no spouse name - maritalStatus: ${state.maritalStatus}, spouseName: ${state.spouseName}');
                                            }

                                            try {
                                              final ch = _childrenBloc.state;
                                              memberData['childrendetails'] = ch
                                                  .toJson();
                                            } catch (_) {}

                                            print(
                                              'Submitting member data: ${jsonEncode(memberData)}',
                                            );

                                            if (_isMemberDetails) {
                                              if (_isEdit) {
                                                bloc.add(
                                                  AnmUpdateSubmit(
                                                    hhid: widget.hhId ?? '',
                                                  ),
                                                );
                                              } else {
                                                bloc.add(
                                                  AnmSubmit(
                                                    context,
                                                    hhid: widget.hhId,
                                                    extraData: memberData,
                                                  ),
                                                );
                                              }
                                              return; // Don't navigate yet, wait for success state
                                            } else {
                                              Navigator.of(
                                                context,
                                              ).pop(memberData);
                                              return;
                                            }
                                          } catch (e) {
                                            print(
                                              'Error preparing member data: $e',
                                            );
                                            showAppSnackBar(
                                              context,
                                              l?.errorPreparingData ??  'Error preparing data. Please try again.',
                                            );
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
