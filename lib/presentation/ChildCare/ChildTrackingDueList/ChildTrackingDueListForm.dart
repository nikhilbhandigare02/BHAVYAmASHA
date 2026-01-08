
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../core/utils/app_info_utils.dart';
import '../../../core/utils/device_info_utils.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../core/widgets/TextField/TextField.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../../../data/Database/User_Info.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import 'bloc/child_tracking_form_bloc.dart';
import 'case_closure_widget.dart';

class ChildTrackingDueListForm extends StatelessWidget {
  const ChildTrackingDueListForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final formData = args?['formData'] as Map<String, dynamic>? ?? {};

    return BlocProvider(
      create: (context) => ChildTrackingFormBloc()..add(LoadFormData(formData)),
      child: const _ChildTrackingDueListFormView(),
    );
  }
}

class _ChildTrackingDueListFormView extends StatefulWidget {
  const _ChildTrackingDueListFormView({Key? key}) : super(key: key);

  @override
  State<_ChildTrackingDueListFormView> createState() => _ChildTrackingDueState();
}

class _ChildTrackingDueState extends State<_ChildTrackingDueListFormView>
    with SingleTickerProviderStateMixin {
  final Map<String, dynamic> _formData = {};
  final Map<int, Map<String, dynamic>> _tabCaseClosureState = {};
  bool _isSaving = false;
  bool _formDataLoaded = false;
  late DateTime _birthDate = DateTime.now();
  late TabController _tabController;
  final Map<int, TextEditingController> _otherCauseControllers = {};
  final Map<int, TextEditingController> _otherReasonControllers = {};
  final Map<int, TextEditingController> _reasonForAbsentControllers = {};

  @override
  void initState() {
    super.initState();
    // TabController will be initialized in didChangeDependencies when context is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_formDataLoaded) {
      _tabController = TabController(length: getTabs(context).length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          context.read<ChildTrackingFormBloc>().add(TabChanged(_tabController.index));
        }
      });

      // Load form data from arguments only once
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null && args['formData'] is Map<String, dynamic>) {
        _formData.addAll(args['formData'] as Map<String, dynamic>);

        final childReg = _formData['child_registration_due'];

        if (childReg is Map<String, dynamic>) {
          final dob = childReg['date_of_birth'];

          debugPrint('Loaded form data with keys: ${_formData.keys.toList()}');
          debugPrint('Household Ref Key: ${_formData['household_ref_key']}');
          debugPrint('Beneficiary Ref Key: ${_formData['beneficiary_ref_key']}');
          debugPrint('Date of Birth: $dob');
        }
      }

      _formDataLoaded = true;
      _prefillWeightsFromDb();
    }
  }

  String _calculateDueDate(int weeksAfterBirth) {
    final dueDate = _birthDate.add(Duration(days: weeksAfterBirth * 7));
    return '${dueDate.day.toString().padLeft(2, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.year}';
  }

  String _getBirthDateFormatted() {
    return '${_birthDate.day.toString().padLeft(2, '0')}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.year}';
  }

  void _initializeTabState(int tabIndex) {
    _tabCaseClosureState[tabIndex] ??= {
      'isCaseClosureChecked': false,
      'selectedClosureReason': null,
      'migrationType': null,
      'dateOfDeath': null,
      'probableCauseOfDeath': null,
      'deathPlace': null,
      'reasonOfDeath': null,
      'showOtherCauseField': false,
      'isBeneficiaryAbsent': null,
    };
    _otherCauseControllers[tabIndex] ??= TextEditingController();
    _otherReasonControllers[tabIndex] ??= TextEditingController();
    _reasonForAbsentControllers[tabIndex] ??= TextEditingController();
  }

  bool _getIsCaseClosureChecked(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['isCaseClosureChecked'] ?? false;
  String? _getSelectedClosureReason(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['selectedClosureReason'];
  String? _getMigrationType(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['migrationType'];
  DateTime? _getDateOfDeath(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['dateOfDeath'];
  String? _getProbableCauseOfDeath(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['probableCauseOfDeath'];
  String? _getDeathPlace(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['deathPlace'];
  String? _getReasonOfDeath(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['reasonOfDeath'];
  bool _getShowOtherCauseField(int tabIndex) =>
      _tabCaseClosureState[tabIndex]?['showOtherCauseField'] ?? false;

  void _updateTabState(int tabIndex, String key, dynamic value) {
    setState(() {
      _initializeTabState(tabIndex);
      _tabCaseClosureState[tabIndex]![key] = value;
    });
  }
  void _updateCaseClosureForAllTabs(bool value) {
    setState(() {
      final totalTabs = getTabs(context).length;
      for (int i = 0; i < totalTabs; i++) {
        _initializeTabState(i);
        _tabCaseClosureState[i]!['isCaseClosureChecked'] = value;
        if (!value) {
          _tabCaseClosureState[i]!['selectedClosureReason'] = null;
          _tabCaseClosureState[i]!['migrationType'] = null;
          _tabCaseClosureState[i]!['dateOfDeath'] = null;
          _tabCaseClosureState[i]!['probableCauseOfDeath'] = null;
          _tabCaseClosureState[i]!['deathPlace'] = null;
          _tabCaseClosureState[i]!['reasonOfDeath'] = null;
          _tabCaseClosureState[i]!['showOtherCauseField'] = false;
          _otherCauseControllers[i]?.clear();
          _otherReasonControllers[i]?.clear();
        }
      }
    });
  }
  Future<void> _prefillWeightsFromDb() async {
    try {
      final householdId = _formData['household_id']?.toString().trim().isNotEmpty == true
          ? _formData['household_id'].toString()
          : _formData['household_ref_key']?.toString() ?? '';
      final beneficiaryId = _formData['beneficiary_id']?.toString().trim().isNotEmpty == true
          ? _formData['beneficiary_id'].toString()
          : _formData['beneficiary_ref_key']?.toString() ?? '';
      if (householdId.isEmpty || beneficiaryId.isEmpty) {
        return;
      }
      final rows = await LocalStorageDao.instance.getFollowupFormsByHouseholdAndBeneficiary(
        formType: FollowupFormDataTable.childTrackingDue,
        householdId: householdId,
        beneficiaryId: beneficiaryId,
      );
      if (rows.isEmpty) {
        return;
      }
      final latest = rows.first;
      final formJsonStr = latest['form_json']?.toString() ?? '';
      if (formJsonStr.isEmpty) {
        return;
      }
      Map<String, dynamic>? formRoot;
      try {
        formRoot = jsonDecode(formJsonStr) as Map<String, dynamic>?;
      } catch (_) {}
      final formDataMap = formRoot?['form_data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(formRoot!['form_data'] as Map)
          : null;
      if (formDataMap == null) {
        return;
      }
      final latestWeight = formDataMap['weight_grams']?.toString() ?? '';
      final latestBirthWeight = formDataMap['birth_weight_grams']?.toString() ?? '';
      if (latestWeight.isNotEmpty || latestBirthWeight.isNotEmpty) {
        setState(() {
          if (latestWeight.isNotEmpty) {
            _formData['weight_grams'] = latestWeight;
          }
          if (latestBirthWeight.isNotEmpty) {
            _formData['birth_weight_grams'] = latestBirthWeight;
          }
        });
      }
    } catch (e) {
      debugPrint('Error pre-filling weights: $e');
    }
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;

    // Validation for weight
    final weightVal = _formData['weight_grams'];
    if (weightVal != null && weightVal.toString().trim().isNotEmpty) {
      final double? weight = double.tryParse(weightVal.toString().trim());
      if (weight != null && (weight < 500 || weight > 12500)) {
        showAppSnackBar(context, "Please enter weight between 500 to 12500 gms");
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = await DatabaseProvider.instance.database;
      final now = DateTime.now().toIso8601String();
      final currentTabIndex = _tabController.index;
      final currentTabName = getTabs(context)[currentTabIndex];

      final formType = FollowupFormDataTable.childTrackingDue;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Child Tracking Due';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '30bycxe4gv7fqnt6';

      final caseClosureData = _getIsCaseClosureChecked(currentTabIndex)
          ? {
              'is_case_closure': true,
              'closure_reason': _getSelectedClosureReason(currentTabIndex),
              'migration_type': _getMigrationType(currentTabIndex),
              'date_of_death': _getDateOfDeath(currentTabIndex)?.toIso8601String(),
              'probable_cause_of_death': _getProbableCauseOfDeath(currentTabIndex),
              'other_cause_of_death': _otherCauseControllers[currentTabIndex]?.text,
              'death_place': _getDeathPlace(currentTabIndex),
              'reason_of_death': _getReasonOfDeath(currentTabIndex),
              'other_reason': _otherReasonControllers[currentTabIndex]?.text,
            }
          : {'is_case_closure': false};

      final formData = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': {
          ..._formData,
          'current_tab': currentTabName,
          'current_tab_index': currentTabIndex,
          'weight_grams': _formData['weight_grams'],
          'birth_weight_grams': _formData['birth_weight_grams'],
          'case_closure': caseClosureData,
          'visit_date': now,
          'is_beneficiary_absent': _tabCaseClosureState[currentTabIndex]?['isBeneficiaryAbsent'],
          'reason_for_absent': _reasonForAbsentControllers[currentTabIndex]?.text,

          // Ensure household_id and beneficiary_id are saved (use ref_key if id not available)
          'household_id': _formData['household_id'] ?? _formData['household_ref_key'] ?? _formData['hhId'] ?? '',
          'beneficiary_id': _formData['beneficiary_id'] ?? _formData['beneficiary_ref_key'] ?? _formData['BeneficiaryID'] ?? '',
          // Save child details for deceased list
          'child_details': {
            'name': _formData['child_name'] ?? '',
            'age': _formData['age'] ?? '',
            'gender': _formData['gender'] ?? '',
            'father_name': _formData['father_name'] ?? '',
            'mother_name': _formData['mother_name'] ?? '',
          },
          // Save registration details
          'registration_data': {
            'registration_type': _formData['registration_type'] ?? 'Child Registration',
            'registration_date': _formData['registration_date'] ?? '',
          },
        },
        'created_at': now,
        'updated_at': now,
      };

      debugPrint('Form data to be saved:');
      final formDataMap = formData['form_data'] as Map<String, dynamic>?;
      debugPrint('  child_details: ${formDataMap?['child_details']}');
      debugPrint('  registration_data: ${formDataMap?['registration_data']}');


      String householdRefKey = _formData['household_ref_key']?.toString() ?? '';
      String motherKey = _formData['mother_key']?.toString() ?? '';
      String fatherKey = _formData['father_key']?.toString() ?? '';
      String beneficiaryRefKey = _formData['beneficiary_ref_key']?.toString() ?? '';

      debugPrint('Initial keys from _formData:');
      debugPrint('  householdRefKey: $householdRefKey');
      debugPrint('  beneficiaryRefKey: $beneficiaryRefKey');
      debugPrint('  motherKey: $motherKey');
      debugPrint('  fatherKey: $fatherKey');


      if (beneficiaryRefKey.isEmpty && _formData['beneficiary_id'] != null) {
        beneficiaryRefKey = _formData['beneficiary_id'].toString();
        debugPrint('Got beneficiaryRefKey from beneficiary_id: $beneficiaryRefKey');
      }

      if (householdRefKey.isEmpty && _formData['household_id'] != null) {
        final householdId = _formData['household_id'].toString();
        debugPrint('Querying beneficiaries with household_id: $householdId');

        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries_new',
          where: 'household_ref_key = ?',
          whereArgs: [householdId],
        );

        if (beneficiaryMaps.isEmpty) {
          beneficiaryMaps = await db.query(
            'beneficiaries_new',
            where: 'id = ?',
            whereArgs: [int.tryParse(householdId) ?? 0],
          );
        }

        if (beneficiaryMaps.isNotEmpty) {
          final beneficiary = beneficiaryMaps.first;
          householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
          motherKey = beneficiary['mother_key'] as String? ?? '';
          fatherKey = beneficiary['father_key'] as String? ?? '';
          if (beneficiaryRefKey.isEmpty) {
            beneficiaryRefKey = beneficiary['beneficiary_ref_key'] as String? ?? '';
          }
          debugPrint('Got keys from beneficiaries table:');
          debugPrint('  householdRefKey: $householdRefKey');
          debugPrint('  beneficiaryRefKey: $beneficiaryRefKey');
          debugPrint('  motherKey: $motherKey');
          debugPrint('  fatherKey: $fatherKey');
        } else {
          debugPrint('No beneficiary found for household_id: $householdId');
        }
      }

      final formJson = jsonEncode(formData);
      debugPrint('💾 Child Tracking Form JSON to be saved: $formJson');

      late DeviceInfo deviceInfo;
      try {
        deviceInfo = await DeviceInfo.getDeviceInfo();
      } catch (e) {
        debugPrint('Error getting device info: $e');
        deviceInfo = DeviceInfo(
          deviceId: 'unknown',
          platform: 'unknown',
          osVersion: 'unknown',
          appInfo: AppInfo(
            appVersion: '1.0.0',
            appName: 'BHAVYA mASHA',
            buildNumber: '1',
            packageName: 'com.medixcel.bhavyamasha',
          ),
        );
      }

      // Get current user
      final currentUser = await UserInfo.getCurrentUser();
      Map<String, dynamic> userDetails = {};
      if (currentUser != null) {
        if (currentUser['details'] is String) {
          try {
            userDetails = jsonDecode(currentUser['details'] ?? '{}');
          } catch (e) {
            debugPrint('Error parsing user details: $e');
          }
        } else if (currentUser['details'] is Map) {
          userDetails = Map<String, dynamic>.from(currentUser['details']);
        }
      }

      final facilityId = userDetails['asha_associated_with_facility_id'] ??
          userDetails['facility_id'] ??
          userDetails['facilityId'] ??
          0;

      final formDataForDb = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryRefKey,
        'mother_key': motherKey,
        'father_key': fatherKey,
        'child_care_state': currentTabName,
        'device_details': jsonEncode({
          'id': deviceInfo.deviceId,
          'platform': deviceInfo.platform,
          'version': deviceInfo.osVersion,
        }),
        'app_details': jsonEncode({
          'app_version': deviceInfo.appVersion.split('+').first,
          'app_name': deviceInfo.appName,
          'build_number': deviceInfo.buildNumber,
          'package_name': deviceInfo.packageName,
        }),
        'parent_user': '',
        'current_user_key': '',
        'facility_id': facilityId,
        'form_json': formJson,
        'created_date_time': now,
        'modified_date_time': now,
        'is_synced': 0,
        'is_deleted': 0,
      };

      final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

      if (formId > 0) {
        
        // --- CASE CLOSURE LOGIC START ---
        if (_getIsCaseClosureChecked(currentTabIndex)) {
           debugPrint('🔴 Case Closure Checked. Updating child_care_activities for beneficiary: $beneficiaryRefKey');
           
           try {
             // Update child_care_activities table to mark records as deleted
             final updateCount = await db.update(
               'child_care_activities',
               {'is_deleted': 1, 'modified_date_time': now},
               where: 'beneficiary_ref_key = ?',
               whereArgs: [beneficiaryRefKey],
             );
             debugPrint('✅ Updated $updateCount records in child_care_activities table (is_deleted = 1)');
           } catch (e) {
             debugPrint('❌ Error updating child_care_activities table: $e');
           }
        }
        // --- CASE CLOSURE LOGIC END ---

        final l10n = AppLocalizations.of(context);
        final closureReason = _getSelectedClosureReason(currentTabIndex);
        if (closureReason == l10n?.death) {
          debugPrint('🔴 Death case closure detected. Updating beneficiary record...');

          final deathDetails = {
            'date_of_death': _getDateOfDeath(currentTabIndex)?.toIso8601String(),
            'probable_cause_of_death': _getProbableCauseOfDeath(currentTabIndex),
            'other_cause_of_death': _otherCauseControllers[currentTabIndex]?.text,
            'death_place': _getDeathPlace(currentTabIndex),
            'reason_of_death': _getReasonOfDeath(currentTabIndex),
            'other_reason': _otherReasonControllers[currentTabIndex]?.text,
            'recorded_date': now,
          };

          try {
            final childName = _formData['child_name']?.toString() ?? '';

            List<Map<String, dynamic>> beneficiaryRecords = await db.query(
              'beneficiaries_new',
              where: 'unique_key = ? OR (beneficiary_info LIKE ?)',
              whereArgs: [beneficiaryRefKey, '%"$childName"%'],
            );

            if (beneficiaryRecords.isNotEmpty) {
              final beneficiary = beneficiaryRecords.first;
              final beneficiaryId = beneficiary['id'];

              await db.update(
                'beneficiaries_new',
                {
                  'is_death': 1,
                  'death_details': jsonEncode(deathDetails),
                  'modified_date_time': now,
                },
                where: 'id = ?',
                whereArgs: [beneficiaryId],
              );

              debugPrint('✅ Beneficiary record updated with death information');
              debugPrint('   is_death: 1');
              debugPrint('   death_details: ${jsonEncode(deathDetails)}');
            } else {
              debugPrint('⚠️ Beneficiary record not found for update. Ref Key: $beneficiaryRefKey');
            }
          } catch (e) {
            debugPrint('❌ Error updating beneficiary death record: $e');
          }
        }

        if (mounted) {
          showAppSnackBar(context, "Form saved successfully");

          // Pop with result to refresh the list
          Navigator.pop(context, {
            'saved': true,
            'formId': formId,
            'beneficiary_id': beneficiaryRefKey,
            'household_id': householdRefKey,
          });
        }
      } else {
        throw Exception('Failed to '
            ' form data');
      }
    } catch (e) {
      debugPrint('❌ Error saving child tracking form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving form: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var c in _otherCauseControllers.values) {
      c.dispose();
    }
    for (var c in _otherReasonControllers.values) {
      c.dispose();
    }
    for (var c in _reasonForAbsentControllers.values) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }
  List<String> getTabs(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return [
      l.birthDosesTab,
      l.sixWeekTab,
      l.tenWeekTab,
      l.fourteenWeekTab,
      l.nineMonthTab,
      l.sixteenToTwentyFourMonthTab,
      l.fiveToSixYearTab,
      l.tenYearTab,
      l.sixteenYearTab,
    ];
  }

  Widget _buildBirthDoseTab() {
    final tabIndex = 0;
    _initializeTabState(tabIndex);
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _infoRow(l!.dateOfVisit, _getBirthDateFormatted()),
                  const Divider(),
                  const SizedBox(height: 8),
                  CustomTextField(
                    maxLength: 5,
                    labelText: l.weightLabelTrackingDue,
                    hintText: l.weightLabelTrackingDue,

                    initialValue: (_formData['weight_grams'] != null &&
                        _formData['weight_grams'].toString().isNotEmpty)
                        ? _formData['weight_grams'].toString()
                        : null,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Store value directly without conversion
                      _formData['weight_grams'] = value;
                    },
                  ),
                  const Divider(),
                  CustomTextField(
                    maxLength: 4,
                    labelText: l.birthWeightRange,
                    hintText: l.birthWeightRange,
                    // Show value exactly as stored (grams)
                    initialValue: (_formData['birth_weight_grams'] != null &&
                        _formData['birth_weight_grams'].toString().isNotEmpty)
                        ? _formData['birth_weight_grams'].toString()
                        : null,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Store value directly without conversion
                      _formData['birth_weight_grams'] = value;
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
              padding: const EdgeInsets.all(16.0),
              child: RoundButton(
                title: _isSaving ? '' : l.saveButton,
                onPress: _isSaving ? () {} : _saveForm,
                height: 34,
                borderRadius: 4,
                fontSize: 15,
                spacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixWeekDoseTable() {
    final l10n = AppLocalizations.of(context);
    final sixWeekDueDate = _calculateDueDate(6);
    final data = [
      {'name': l10n!.opv1, 'due': sixWeekDueDate},
      {'name': l10n.dpt1, 'due': sixWeekDueDate},
      {'name': l10n.pentavalent1, 'due': sixWeekDueDate},
      {'name': l10n.rota1, 'due': sixWeekDueDate},
      {'name': l10n.ipv1, 'due': sixWeekDueDate},
      {'name': l10n.pcv1, 'due': sixWeekDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n!.six_WeekDoses, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
             Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n.doseTableDueDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n.doseTableActualDate, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l!.trackingDueTitle,
        showBack: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              isScrollable: true,
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: getTabs(context).map((e) => Tab(text: e)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: getTabs(context).map((tabName) {
                final tabs = getTabs(context);
                if (tabName == l.birthDosesTab) {
                  return _buildBirthDoseTab();
                } else if (tabName == l.sixWeekTab) {
                  return _buildSixWeekTab();
                } else if (tabName == l.tenWeekTab) {
                  return _buildTenWeekTab();
                } else if (tabName == l.fourteenWeekTab) {
                  return _buildFourteenWeekTab();
                } else if (tabName == l.nineMonthTab) {
                  return _buildNineMonthTab();
                } else if (tabName == l.sixteenToTwentyFourMonthTab) {
                  return _buildSixteenToTwentyFourMonthTab();
                } else if (tabName == l.fiveToSixYearTab) {
                  return _buildFiveToSixYearTab();
                } else if (tabName == l.tenYearTab) {
                  return _buildTenYearTab();
                } else if (tabName == l.sixteenYearTab) {
                  return _buildSixteenYearTab();
                }
                return Center(
                  child: Text(
                    '$tabName Content Coming Soon...',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenWeekDoseTable() {
    final l = AppLocalizations.of(context);
    final tenWeekDueDate = _calculateDueDate(10);
    final data = [
      {'name': l!.opv2, 'due': tenWeekDueDate},
      {'name': l!.pentavalent2, 'due': tenWeekDueDate},
      {'name': l!.rota2, 'due': tenWeekDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
         TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.tenWeekDoses, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.doseTableDueDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.doseTableActualDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFourteenWeekDoseTable() {
    final l = AppLocalizations.of(context);
    final fourteenWeekDueDate = _calculateDueDate(14);
    final data = [
      {'name': l!.opv3, 'due': fourteenWeekDueDate},
      {'name': l!.pentavalent3, 'due': fourteenWeekDueDate},
      {'name': l!.rota3, 'due': fourteenWeekDueDate},
      {'name': l!.ipv2, 'due': fourteenWeekDueDate},
      {'name': l!.pcv2, 'due': fourteenWeekDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
         TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.fourteenWeekDoses, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.doseTableDueDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.doseTableActualDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFourteenWeekTab() {
    final tabIndex = 3; // 14 Week tab
    _initializeTabState(tabIndex);
    final List<String> absentOptions = ['No', 'Yes'];
    final l = AppLocalizations.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      _buildFourteenWeekDoseTable(),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Case Closure Widget
                          CaseClosureWidget(
                            isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                            selectedClosureReason: _getSelectedClosureReason(tabIndex),
                            migrationType: _getMigrationType(tabIndex),
                            dateOfDeath: _getDateOfDeath(tabIndex),
                            probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                            deathPlace: _getDeathPlace(tabIndex),
                            reasonOfDeath: _getReasonOfDeath(tabIndex),
                            showOtherCauseField: _getShowOtherCauseField(tabIndex),
                            otherCauseController: _otherCauseControllers[tabIndex]!,
                            otherReasonController: _otherReasonControllers[tabIndex]!,
                            onCaseClosureChanged: (value) {
                              _updateCaseClosureForAllTabs(value);
                            },
                            onClosureReasonChanged: (value) {
                              _updateTabState(tabIndex, 'selectedClosureReason', value);
                              if (value != 'Death') {
                                _updateTabState(tabIndex, 'dateOfDeath', null);
                                _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                                _updateTabState(tabIndex, 'deathPlace', null);
                                _updateTabState(tabIndex, 'reasonOfDeath', null);
                                _updateTabState(tabIndex, 'showOtherCauseField', false);
                                _otherCauseControllers[tabIndex]!.clear();
                              }
                            },
                            onMigrationTypeChanged: (value) {
                              _updateTabState(tabIndex, 'migrationType', value);
                            },
                            onDateOfDeathChanged: (value) {
                              _updateTabState(tabIndex, 'dateOfDeath', value);
                            },
                            onProbableCauseChanged: (value) {
                              _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                              final showOther = (value == 'Any other (specify)');
                              _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                              if (!showOther) {
                                _otherCauseControllers[tabIndex]!.clear();
                              }
                            },
                            onDeathPlaceChanged: (value) {
                              _updateTabState(tabIndex, 'deathPlace', value);
                            },
                            onReasonOfDeathChanged: (value) {
                              _updateTabState(tabIndex, 'reasonOfDeath', value);
                            },
                            onShowOtherCauseFieldChanged: (value) {
                              _updateTabState(tabIndex, 'showOtherCauseField', value);
                            },
                          ),


                          ApiDropdown<String>(
                            labelText: l!.beneficiaryAbsentLabel,
                            items: absentOptions,
                            value: _tabCaseClosureState[tabIndex]?['isBeneficiaryAbsent'],
                            onChanged: (value) {
                              _updateTabState(tabIndex, 'isBeneficiaryAbsent', value);
                              if (value != 'Yes') {
                                _reasonForAbsentControllers[tabIndex]!.clear();
                              }
                            },
                            getLabel: (value) => value,
                          ),
                          Divider(height: 0,),
                          if (_tabCaseClosureState[tabIndex]?['isBeneficiaryAbsent'] == 'Yes') ...[

                            CustomTextField(
                              labelText: l!.reasonForAbsence,
                              hintText: l!.reasonForAbsence,
                              controller: _reasonForAbsentControllers[tabIndex],
                            ),
                          ],
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildSaveButtonBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTenWeekTab() {
    final tabIndex = 2; // 10 Week tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildTenWeekDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildSixWeekTab() {
    final tabIndex = 1; // 6 Week tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildSixWeekDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  Widget _buildSaveButtonBar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RoundButton(
          title: _isSaving ? '' : l.saveButton,
          onPress: _isSaving ? () {} : _saveForm,
          height: 34,
          borderRadius: 4,
          fontSize: 15,
          spacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNineMonthDoseTable() {
    final data = [
      {'name': 'Measles 1', 'due': '14-07-2023'},
      {'name': 'M.R Dose -1', 'due': '14-07-2023'},
      {'name': 'Vitamin A Dose -1', 'due': '14-07-2023'},
      {'name': 'J.E Vaccine -1', 'due': '14-07-2023'},
      {'name': 'P.V.C -Booster', 'due': '14-07-2023'},
      {'name': 'F.I.P.V. -3', 'due': '14-07-2023'},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('9 Month Doses', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Actual Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildNineMonthTab() {
    final tabIndex = 4; // 9 Months tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [

                  const SizedBox(height: 4),

                  _buildNineMonthDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Case Closure Widget
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildSixteenToTwentyFourMonthDoseTable() {
    final sixteenToTwentyFourMonthDueDate = _calculateDueDate(20);
    final data = [
      {'name': 'O.P.V. Booster', 'due': sixteenToTwentyFourMonthDueDate},
      {'name': 'D.P.T. Booster-1', 'due': sixteenToTwentyFourMonthDueDate},
      {'name': 'Measles 2', 'due': sixteenToTwentyFourMonthDueDate},

      {'name': 'J.E Vaccine -2', 'due': sixteenToTwentyFourMonthDueDate},
      {'name': 'M.R dose -2', 'due': sixteenToTwentyFourMonthDueDate},

    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('16-24 Month Doses', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Actual Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSixteenToTwentyFourMonthTab() {
    final tabIndex = 5; // 16-24 Months tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildSixteenToTwentyFourMonthDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildFiveToSixYearDoseTable() {
    final fiveToSixYearDueDate = _calculateDueDate(260);
    final data = [
      {'name': 'D.P.T Booster-2', 'due': fiveToSixYearDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('5-6 Year Doses', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Actual Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFiveToSixYearTab() {
    final tabIndex = 6; // 5-6 Year tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildFiveToSixYearDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateCaseClosureForAllTabs(value);
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildTenYearDoseTable() {
    final tenYearDueDate = _calculateDueDate(520);
    final data = [
      {'name': 'Tetanus Diphtheria (Td)', 'due': tenYearDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('10 Year Doses', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Actual Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTenYearTab() {
    final tabIndex = 7; // 10 Year tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildTenYearDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateTabState(tabIndex, 'isCaseClosureChecked', value);
                          if (!value) {
                            _updateTabState(tabIndex, 'selectedClosureReason', null);
                            _updateTabState(tabIndex, 'migrationType', null);
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                            _otherReasonControllers[tabIndex]!.clear();
                          }
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildSixteenYearDoseTable() {
    final sixteenYearDueDate = _calculateDueDate(832);
    final data = [
      {'name': 'Tetanus Diphtheria (Td)', 'due': sixteenYearDueDate},
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border: const TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('16 Year Doses', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Actual Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSixteenYearTab() {
    final tabIndex = 8; // 16 Year tab
    _initializeTabState(tabIndex);
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  _buildSixteenYearDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _getIsCaseClosureChecked(tabIndex),
                        selectedClosureReason: _getSelectedClosureReason(tabIndex),
                        migrationType: _getMigrationType(tabIndex),
                        dateOfDeath: _getDateOfDeath(tabIndex),
                        probableCauseOfDeath: _getProbableCauseOfDeath(tabIndex),
                        deathPlace: _getDeathPlace(tabIndex),
                        reasonOfDeath: _getReasonOfDeath(tabIndex),
                        showOtherCauseField: _getShowOtherCauseField(tabIndex),
                        otherCauseController: _otherCauseControllers[tabIndex]!,
                        otherReasonController: _otherReasonControllers[tabIndex]!,
                        onCaseClosureChanged: (value) {
                          _updateTabState(tabIndex, 'isCaseClosureChecked', value);
                          if (!value) {
                            _updateTabState(tabIndex, 'selectedClosureReason', null);
                            _updateTabState(tabIndex, 'migrationType', null);
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                            _otherReasonControllers[tabIndex]!.clear();
                          }
                        },
                        onClosureReasonChanged: (value) {
                          _updateTabState(tabIndex, 'selectedClosureReason', value);
                          if (value != 'Death') {
                            _updateTabState(tabIndex, 'dateOfDeath', null);
                            _updateTabState(tabIndex, 'probableCauseOfDeath', null);
                            _updateTabState(tabIndex, 'deathPlace', null);
                            _updateTabState(tabIndex, 'reasonOfDeath', null);
                            _updateTabState(tabIndex, 'showOtherCauseField', false);
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onMigrationTypeChanged: (value) {
                          _updateTabState(tabIndex, 'migrationType', value);
                        },
                        onDateOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'dateOfDeath', value);
                        },
                        onProbableCauseChanged: (value) {
                          _updateTabState(tabIndex, 'probableCauseOfDeath', value);
                          final showOther = (value == 'Any other (specify)');
                          _updateTabState(tabIndex, 'showOtherCauseField', showOther);
                          if (!showOther) {
                            _otherCauseControllers[tabIndex]!.clear();
                          }
                        },
                        onDeathPlaceChanged: (value) {
                          _updateTabState(tabIndex, 'deathPlace', value);
                        },
                        onReasonOfDeathChanged: (value) {
                          _updateTabState(tabIndex, 'reasonOfDeath', value);
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          _updateTabState(tabIndex, 'showOtherCauseField', value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButtonBar(),
        ],
      ),
    );
  }

  Widget _buildDoseTable() {
    final birthDueDate = _getBirthDateFormatted();
    final l = AppLocalizations.of(context);
    final data = [
      {'name': l!.bcg, 'due': birthDueDate},
      {'name': l.hepatitis, 'due': birthDueDate},
      {'name': l.opv, 'due': birthDueDate},
      {'name': l.vit, 'due': birthDueDate},
    ];

    return Table(
      columnWidths:  {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
      },
      border:  TableBorder(horizontalInside: BorderSide(width: 0.5)),
      children: [
         TableRow(
          decoration: BoxDecoration(color: Color(0xFFF2F2F2)),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l!.birthDosesTab, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l.doseTableDueDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(l.doseTableActualDate, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (var item in data)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['name']!),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['due']!),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('dd-mm-yyyy', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }
}
