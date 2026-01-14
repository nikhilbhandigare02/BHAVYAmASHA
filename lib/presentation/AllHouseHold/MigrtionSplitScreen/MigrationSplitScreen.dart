import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../core/widgets/TextField/TextField.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/User_Info.dart';
import '../../../core/utils/geolocation_utils.dart';
import '../../../core/utils/device_info_utils.dart';
import '../../../core/utils/id_generator_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/migration_split_bloc.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../HomeScreen/HomeScreen.dart';

enum MigrationSplitOption { migration, split }

class MigrationSplitScreen extends StatefulWidget {
  final String? hhid;

  const MigrationSplitScreen({super.key, this.hhid});

  @override
  State<MigrationSplitScreen> createState() => _MigrationSplitScreenState();
}

class _MigrationSplitScreenState extends State<MigrationSplitScreen> {
  MigrationSplitOption? _selectedOption = MigrationSplitOption.migration;
  String? _selectedMemberType;
  String? _selectedChild;
  String? _selectedFamilyHead;
  final TextEditingController _houseNoController = TextEditingController();
  List<Map<String, dynamic>> _householdMembers = [];
  bool _isLoadingMembers = false;
  String? _loadError;
  // Store name to ID mapping
  final Map<String, String> _adultNameToId = {};
  final Map<String, String> _childNameToId = {};
  List<String> _selectedChildren = [];
  late final MigrationSplitBloc _splitBloc;
  bool _isMigrating = false;
  bool _isSplitting = false;

  // For backward compatibility
  List<String> get _adultNames => _adultNameToId.keys.toList();
  List<String> get _childNames => _childNameToId.keys.toList();

  List<String> _selectedAdults = [];
  Set<String> _disabledAdultNames = <String>{};

  // Design Constants
  static const double _labelFontSize = 9.5;
  static const double starzize = 16;
  static const double _inputFontSize = 12.0;
  static const double _buttonFontSize = 12.0;
  static const double _radioFontSize = 13.0;
  static const double _verticalSpacing = 7.0;
  static const double _smallVerticalSpacing = 6.0;
  static const double _horizontalPadding = 12.0;
  static const double _verticalPadding = 12.0;
  static const double _borderRadius = 4.0;
  static const double _buttonHeight = 40.0;
  static const double _buttonWidth = 105.0;

  final List<Map<String, dynamic>> _memberTypes = [];

  void _navigateToHomeDashboard() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(initialTabIndex: 1),
        ),
        (route) => false,
      );
    });
  }

  String get _selectedMemberLabel {
    final l10n =  AppLocalizations.of(context);

    if (_selectedAdults.isNotEmpty) {
      return _selectedAdults.join(', ');
    }
    final selected = _memberTypes
        .where((type) => type['selected'] == true)
        .toList();
    if (selected.isEmpty) {
      return l10n!.selectAMember;
    }
    return selected.map((type) => type['label']).join(', ');
  }

  String get _selectedChildLabel {
   final l10n =  AppLocalizations.of(context);
    if (_selectedChildren.isNotEmpty) {
      return _selectedChildren.join(', ');
    }
    return l10n!.selectChildren;
  }

  bool get _isMemberTypeSelected => _selectedAdults.isNotEmpty;

  List<String> get _selectedMemberTypes => _memberTypes
      .where((type) => type['selected'] == true)
      .map((type) => type['value'] as String)
      .toList();

  int? _calculateAgeYears(dynamic dobRaw) {
    if (dobRaw == null) return null;
    try {
      var s = dobRaw.toString();
      final dt = DateTime.tryParse(s);
      if (dt == null) return null;
      final now = DateTime.now();
      int age = now.year - dt.year;
      if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  bool _isAdultRecord(Map<String, dynamic> info, Map<String, dynamic> row) {
    final v = row['is_adult'];
    final isAdultFlag =
        (v is int && v == 1) ||
        (v is bool && v == true) ||
        (v is String && (v == '1' || v.toLowerCase() == 'true'));
    if (isAdultFlag) return true;

    final memberType = (info['memberType'] ?? info['MemberType'] ?? '')
        .toString();
    if (memberType.toLowerCase() == 'adult') return true;

    final maritalStatus = (info['maritalStatus'] ?? info['MaritalStatus'] ?? '')
        .toString();
    if (maritalStatus.isNotEmpty) return true;

    final spouseName = (info['spouseName'] ?? info['SpouseName'] ?? '')
        .toString();
    if (spouseName.isNotEmpty) return true;

    final relation = (info['relation_to_head'] ?? info['relation'] ?? '')
        .toString()
        .toLowerCase();
    if (relation == 'self' || relation == 'spouse') return true;

    final age = _calculateAgeYears(info['dob']);
    if (age != null && age >= 18) return true;

    return false;
  }

  Map<String, dynamic> _tryDecodeInfo(dynamic raw) {
    try {
      if (raw == null) return <String, dynamic>{};
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return Map<String, dynamic>.from(raw);
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      print('MigrationSplitScreen: failed to decode beneficiary_info -> $e');
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    _splitBloc = MigrationSplitBloc();
    _houseNoController.addListener(() {
      setState(() {});
    });
    _loadHouseholdMembers();
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _splitBloc.close();
    super.dispose();
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style:  TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: starzize,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer(
    BuildContext context,
    String label,
    Widget child,
  ) {
    return GestureDetector(
      onTap: () => _showMemberTypeDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          //vertical: _verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.splitMigration ?? 'Split / Migration',
        showBack: true,
      ),
      body: BlocListener<MigrationSplitBloc, MigrationSplitState>(
        bloc: _splitBloc,
        listener: (context, state) async {
          if (state is MigrationSplitUpdated) {
            if (!mounted) return;
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l10n?.splitFailed ?? "Split failed"}: ${state.error}',
                    style: const TextStyle(fontSize: _labelFontSize),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${l10n?.splitUpdated ?? "Split updated"}: ${state.updatedCount} record(s)${state.notFoundCount > 0 ? ", ${state.notFoundCount} not found" : ''}',
                    style: const TextStyle(fontSize: _labelFontSize),
                  ),
                ),
              );
              setState(() {
                _resetForm();
              });
              await _loadHouseholdMembers();
            }
            if (mounted) {
              setState(() {
                _isSplitting = false;
              });
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Migration/Split Toggle
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<MigrationSplitOption>(
                        title: Text(
                          l10n?.migration ?? 'Migration',
                          style: TextStyle(fontSize: _radioFontSize),
                        ),
                        value: MigrationSplitOption.migration,
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value;
                            _resetForm();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<MigrationSplitOption>(
                        title: Text(
                          l10n?.split ?? 'Split',
                          style: TextStyle(fontSize: _radioFontSize),
                        ),
                        value: MigrationSplitOption.split,
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value;
                            _resetForm();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (widget.hhid != null && widget.hhid!.isNotEmpty) ...[
                  const SizedBox(height: _smallVerticalSpacing),
                  if (_isLoadingMembers)
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          l10n?.loadingMembers ?? 'Loading members...',
                          style: TextStyle(fontSize: _labelFontSize),
                        ),
                      ],
                    )
                  else if (_loadError != null)
                    Text(
                      l10n?.failedToLoadMembers ?? 'Failed to load members',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: _labelFontSize,
                      ),
                    ),
                ],

                if (_selectedOption == MigrationSplitOption.migration)
                  ..._buildMigrationForm(context),

                if (_selectedOption == MigrationSplitOption.split)
                  ..._buildSplitForm(context),

                const SizedBox(height: _verticalSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _selectedMemberType = null;
    _selectedChild = null;
    _selectedFamilyHead = null;
    _houseNoController.clear();
    _selectedAdults.clear();
    _selectedChildren.clear();
    for (var type in _memberTypes) {
      type['selected'] = false;
    }
  }

  Future<void> _loadHouseholdMembers() async {
    final hhid = widget.hhid;
    if (hhid == null || hhid.isEmpty) {
      print('MigrationSplitScreen: No HHID provided');
      return;
    }
    setState(() {
      _isLoadingMembers = true;
      _loadError = null;
    });
    try {
      final rows = await LocalStorageDao.instance.getBeneficiariesByHousehold(
        hhid,
      );
      print(
        'MigrationSplitScreen: Loaded ${rows.length} beneficiaries for household_ref_key=$hhid',
      );

      // Clear previous data
      _adultNameToId.clear();
      _childNameToId.clear();
      _disabledAdultNames.clear();

      for (final r in rows) {
        // Check if member is migrated
        final isMigrated =
            r['is_migrated'] == 1 ||
                r['is_migrated'] == '1' ||
                r['is_migrated'] == true;

        // Check if member is deceased
        final isDeceased =
            r['is_death'] == 1 ||
                r['is_death'] == '1' ||
                r['is_death'] == true;

        // Skip if migrated OR deceased
        if (isMigrated || isDeceased) continue;

        final uniqueKey = r['unique_key']?.toString() ?? '';
        if (uniqueKey.isEmpty) continue;

        final info = _tryDecodeInfo(r['beneficiary_info']);
        final isAdult = _isAdultRecord(info, r);
        final nm =
        (info['headName'] ?? info['memberName'] ?? info['name'] ?? '')
            .toString()
            .trim();
        final rel = (info['relation_to_head'] ?? info['relation'] ?? '')
            .toString()
            .toLowerCase();

        if (nm.isEmpty) continue;

        if (isAdult) {
          _adultNameToId[nm] = uniqueKey;
          print('Adult: $nm (ID: $uniqueKey)');
          if (rel == 'self') {
            _disabledAdultNames.add(nm);
          }
        } else {
          _childNameToId[nm] = uniqueKey;
          print('Child: $nm (ID: $uniqueKey)');
        }
      }

      setState(() {
        _householdMembers = rows;
      });
    } catch (e) {
      print(
        'MigrationSplitScreen: Error loading household members for $hhid -> $e',
      );
      setState(() {
        _loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showConfirmationDialog(
      context: context,
      message:l10n?.doYouWantToContinue ?? 'Do you want to continue?',
      yesText:l10n?.yes ?? 'Yes',
      noText:l10n?.no ?? 'No',
    );
    return result ?? false;
  }

  List<Widget> _buildMigrationForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      const SizedBox(height: _verticalSpacing),

      _buildLabel(l10n?.selectMember ?? 'Select Member', isRequired: true),
      // SizedBox(height: 12),
      _buildDropdownContainer(
        context,
        '',
        Row(
          children: [
            Text(
              _selectedMemberLabel,
              style: TextStyle(
                fontSize: 15.sp,
                color: _isMemberTypeSelected ? Colors.black : Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),

            Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          ],
        ),
      ),
      SizedBox(height: 4),
      const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      SizedBox(height: 4),
      if (_isMemberTypeSelected) ...[
        // _buildLabel('Select Child'),
        ApiDropdown<String>(
          labelText: l10n?.selectChildren ?? 'Select Child',
          items: _childNames,
          getLabel: (item) => item,
          value: _selectedChild,
          onChanged: (value) {
            setState(() {
              _selectedChild = value;
            });
          },
          hintText: l10n?.selectChildren ?? 'Select a member',
        ),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: _verticalSpacing),
      ],

      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: _buttonWidth,
          height: _buttonHeight,
          child: ElevatedButton(
            onPressed: _isMemberTypeSelected && !_isMigrating
                ? () async {
                    final confirm = await _showConfirmDialog(context);
                    if (confirm) {
                      setState(() {
                        _isMigrating = true;
                      });
                      await _handleMigration();
                      if (mounted) {
                        setState(() {
                          _isMigrating = false;
                        });
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isMigrating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n?.migrate ?? 'MIGRATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _buttonFontSize,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSplitForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      const SizedBox(height: _verticalSpacing),

      // Member Type Dropdown
      Padding(
        padding: const EdgeInsets.only(left: 0),
        child: _buildLabel(
          l10n?.selectMember ?? 'Select Member Type',
          isRequired: true,
        ),
      ),
      // SizedBox(height: 12),
      GestureDetector(
        onTap: () => _showMemberTypeDialog(context),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  _selectedMemberLabel,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: _isMemberTypeSelected
                        ? Colors.black
                        : Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[800]),
            ],
          ),
        ),
      ),
      SizedBox(height: 4),
      const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      const SizedBox(height: _verticalSpacing),

      if (_isMemberTypeSelected) ...[
        // Select Child (Optional)
        _buildLabel(l10n?.selectChildren ?? 'Select Child (Optional)'),
        // const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showChildSelectionDialog(context),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    _selectedChildLabel,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: _selectedChildren.isNotEmpty
                          ? Colors.black
                          : AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          labelText:'${ l10n?.selectNewFamilyHead ?? 'Select New Family Head'} *',
          items: _selectedAdults,

          getLabel: (item) => item,
          value: _selectedFamilyHead,
          onChanged: (value) {
            setState(() {
              _selectedFamilyHead = value;
            });
          },
          hintText: l10n?.selectMember ?? 'Select new family head',
        ),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),


        CustomTextField(
          labelText: '${l10n?.houseNoLabel ?? 'Enter house number'} *',
          hintText: l10n?.houseNoLabel ?? 'Enter house number',
          controller: _houseNoController,
        ),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: _verticalSpacing),
      ],

      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: _buttonWidth,
          height: _buttonHeight,
          child: ElevatedButton(
            onPressed: !_isSplitting
                ? () async {
                    if (!_isMemberTypeSelected) {
                      showAppSnackBar(context, 'Please select members');
                      return;
                    }
                    if (_selectedFamilyHead == null) {
                      showAppSnackBar(
                        context,
                        'Please select Family Head',
                      );
                      return;
                    }
                    if (_houseNoController.text.trim().isEmpty) {
                      showAppSnackBar(
                        context,
                        'Please enter valid House number',
                      );
                      return;
                    }

                    final confirm = await _showConfirmDialog(context);
                    if (confirm) {
                      setState(() {
                        _isSplitting = true;
                      });
                      await _handleSplit();
                      if (mounted) {
                        setState(() {
                          _isSplitting = false;
                        });
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSplitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        l10n?.split ?? 'SPLIT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: _buttonFontSize,
                        ),
                      ),
                    ],
                  )
                : Text(
                    l10n?.split ?? 'SPLIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _buttonFontSize,
                    ),
                  ),
          ),
        ),
      ),
    ];
  }

  Future<void> _handleMigration() async {
    if (_selectedAdults.isEmpty) {
      showAppSnackBar(context, 'Please select at least one member to migrate');

      return;
    }

    final targets = <String>[..._selectedAdults];
    if (_selectedChild != null && _selectedChild!.trim().isNotEmpty) {
      targets.add(_selectedChild!.trim());
    }

    int updated = 0;
    int notFound = 0;

    for (final targetName in targets.toSet()) {
      final matches = _householdMembers.where((r) {
        final info = _tryDecodeInfo(r['beneficiary_info']);
        final nm =
            (info['headName'] ?? info['memberName'] ?? info['name'] ?? '')
                .toString();
        return nm.trim() == targetName;
      }).toList();

      if (matches.isEmpty) {
        notFound++;
        continue;
      }

      for (final row in matches) {
        final uniqueKey = row['unique_key']?.toString();
        if (uniqueKey == null || uniqueKey.isEmpty) continue;
        try {
          final changes = await LocalStorageDao.instance
              .setBeneficiaryMigratedByUniqueKey(
                uniqueKey: uniqueKey,
                isMigrated: 1,
              );
          if (changes > 0) updated += changes;
        } catch (e) {
          print(
            'MigrationSplitScreen: Failed to set is_migrated for $uniqueKey -> $e',
          );
        }
      }
    }

    if (!mounted) return;

    showAppSnackBar(
      context,
      'Migration updated: $updated record(s)${notFound > 0 ? ", $notFound name(s) not found" : ''}',
    );

    await _loadHouseholdMembers();
    if (mounted) {
      setState(() {
        _resetForm();
      });
    }
    if (updated > 0) {
      _navigateToHomeDashboard();
    }
  }

  Future<void> _handleSplit() async {
    try {
      final headName = _selectedFamilyHead!.trim();
      final headUniqueKey = _adultNameToId[headName] ?? '';
      if (headUniqueKey.isEmpty) {
        showAppSnackBar(context, 'Selected head not found');
        return;
      }

      final headRow = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
        headUniqueKey,
      );
      if (headRow == null || headRow.isEmpty) {
        showAppSnackBar(context, 'Head record not found');
        return;
      }

      final infoRaw = headRow['beneficiary_info'];
      final Map<String, dynamic> headInfo = _tryDecodeInfo(infoRaw);
      headInfo['houseNo'] = _houseNoController.text.trim();

      final deviceInfo = await DeviceInfo.getDeviceInfo();
      final geoLocation = await GeoLocation.getCurrentLocation();
      final locationData = Map<String, String>.from(geoLocation.toJson());
      locationData['source'] = 'gps';
      if (!geoLocation.hasCoordinates) {
        locationData['status'] = 'unavailable';
        locationData['reason'] = 'Could not determine location';
      }
      final geoLocationJson = jsonEncode(locationData);

      final currentUser = await UserInfo.getCurrentUser();
      final userDetails = currentUser?['details'] is String
          ? jsonDecode(currentUser?['details'] ?? '{}')
          : currentUser?['details'] ?? {};
      final working = userDetails['working_location'] ?? {};

      final address = {
        'state_name': working['state'] ?? userDetails['stateName'] ?? '',
        'state_id': (working['state_id'] ?? userDetails['stateId'] ?? 1),
        'state_lgd_code': userDetails['stateLgdCode'] ?? 1,
        'division_name':
            working['division'] ?? userDetails['division'] ?? 'Patna',
        'division_id':
            (working['division_id'] ?? userDetails['divisionId'] ?? 27),
        'division_lgd_code': userDetails['divisionLgdCode'] ?? 198,
        'district_name': working['district'] ?? userDetails['districtName'],
        'district_id': (working['district_id'] ?? userDetails['districtId']),
        'block_name': working['block'] ?? userDetails['blockName'],
        'block_id': (working['block_id'] ?? userDetails['blockId']),
        'village_name': working['village'] ?? userDetails['villageName'],
        'village_id': (working['village_id'] ?? userDetails['villageId']),
        'hsc_id': (working['hsc_id'] ?? userDetails['facility_hsc_id']),
        'hsc_name': working['hsc_name'] ?? userDetails['facility_hsc_name'],
        'hsc_hfr_id': working['hsc_hfr_id'] ?? userDetails['facility_hfr_id'],
        'asha_id': working['asha_id'] ?? userDetails['asha_id'],
        'pincode': working['pincode'] ?? userDetails['pincode'],
        'user_identifier':
            working['user_identifier'] ?? userDetails['user_identifier'],
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

      final facilityId =
          working['asha_associated_with_facility_id'] ??
          userDetails['asha_associated_with_facility_id'] ??
          0;
      final ashaUniqueKey = userDetails['unique_key'] ?? {};

      final ts = DateTime.now().toIso8601String();
      final newHouseholdKey = await IdGenerator.generateUniqueId(deviceInfo);

      final householdPayload = {
        'server_id': null,
        'unique_key': newHouseholdKey,
        'address': jsonEncode(address),
        'geo_location': geoLocationJson,
        'head_id': headUniqueKey,
        'household_info': jsonEncode(headInfo),
        'device_details': jsonEncode({
          'id': deviceInfo.deviceId,
          'platform': deviceInfo.platform,
          'version': deviceInfo.osVersion,
          'model': deviceInfo.model,
        }),
        'app_details': jsonEncode({
          'app_version': deviceInfo.appVersion.split('+').first,
          'app_name': deviceInfo.appName,
          'build_number': deviceInfo.buildNumber,
          'package_name': deviceInfo.packageName,
          'instance': 'prod',
        }),
        'parent_user': jsonEncode({}),
        'current_user_key': ashaUniqueKey,
        'facility_id': facilityId,
        'created_date_time': ts,
        'modified_date_time': ts,
        'is_synced': 0,
        'is_deleted': 0,
      };

      await LocalStorageDao.instance.insertHousehold(householdPayload);

      final targets = <String>{
        headName,
        ..._selectedAdults,
        ..._selectedChildren,
      };
      final beneficiaryKeys = <String>[];
      for (final name in targets) {
        final uk = _adultNameToId[name] ?? _childNameToId[name] ?? '';
        if (uk.isNotEmpty) beneficiaryKeys.add(uk);
      }

      _splitBloc.add(
        PerformSplitUpdateBeneficiaries(
          newHouseholdKey: newHouseholdKey,
          beneficiaryUniqueKeys: beneficiaryKeys,
          isSeparated: 1,
          houseNo: _houseNoController.text.trim(),
        ),
      );

      _navigateToHomeDashboard();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Split failed: $e',
            style: const TextStyle(fontSize: _labelFontSize),
          ),
        ),
      );
    }
  }

  void _showChildSelectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final localSelectedChildren = Set<String>.from(_selectedChildren);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.5.h),
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.selectChildren ?? 'Select Child',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 10),
                ],
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 40.h),
              child: SingleChildScrollView(
                child: _isLoadingMembers
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _childNames.map((name) {
                          final selected = localSelectedChildren.contains(name);
                          return CheckboxListTile(
                            title: Text(
                              name,
                              style: TextStyle(fontSize: 15.sp),
                            ),
                            value: selected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if ((value ?? false)) {
                                  localSelectedChildren.add(name);
                                } else {
                                  localSelectedChildren.remove(name);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0.2.h,
                            ),
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -4),
                          );
                        }).toList(),
                      ),
              ),
            ),
            actions: [
              const Divider(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n?.cancel ?? 'CANCEL',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedChildren = localSelectedChildren.toList();
                      });
                      FocusManager.instance.primaryFocus?.unfocus();
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n?.ok ?? 'OK',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMemberTypeDialog(BuildContext context) {
    final localSelectedAdults = Set<String>.from(_selectedAdults);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0.5.h),
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.selectMember ?? 'Select Member Type',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 10),
                ],
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 40.h),
              child: SingleChildScrollView(
                child: _isLoadingMembers
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(padding: const EdgeInsets.only(bottom: 8.0)),
                          if (_adultNames.isEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n?.noAdultMembersFound ??
                                        'No adult members found for this household',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    setDialogState(() {});
                                    await _loadHouseholdMembers();
                                    if (mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Refresh',
                                ),
                              ],
                            )
                          else
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_adultNames.length, (
                                index,
                              ) {
                                final name = _adultNames[index];
                                final isDisabled =
                                    _disabledAdultNames.contains(name) ||
                                    index == 0;
                                return CheckboxListTile(
                                  title: Text(
                                    isDisabled ? '$name ( Family Head)' : name,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: isDisabled
                                          ? Colors.black54
                                          : Colors.black,
                                    ),
                                  ),
                                  value: localSelectedAdults.contains(name),
                                  onChanged: isDisabled
                                      ? null
                                      : (bool? value) {
                                          setDialogState(() {
                                            if ((value ?? false)) {
                                              localSelectedAdults.add(name);
                                            } else {
                                              localSelectedAdults.remove(name);
                                            }
                                          });
                                        },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 0.2.h,
                                  ),
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                    vertical: -4,
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
              ),
            ),
            actions: [
              const Divider(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n?.cancel ?? 'CANCEL',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedAdults = localSelectedAdults
                            .where((n) => !_disabledAdultNames.contains(n))
                            .toList();
                        final vaIndex = _memberTypes.indexWhere(
                          (t) => t['value'] == 'va',
                        );
                        if (vaIndex != -1) {
                          _memberTypes[vaIndex]['selected'] =
                              _selectedAdults.isNotEmpty;
                        }
                        _selectedMemberType = _selectedAdults.isNotEmpty
                            ? 'va'
                            : null;
                        if (_selectedAdults.isEmpty) {
                          _selectedChild = null;
                          _selectedFamilyHead = null;
                          _houseNoController.clear();
                        }
                      });
                      FocusManager.instance.primaryFocus?.unfocus();
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(FocusNode());
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n?.ok ?? 'OK',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
