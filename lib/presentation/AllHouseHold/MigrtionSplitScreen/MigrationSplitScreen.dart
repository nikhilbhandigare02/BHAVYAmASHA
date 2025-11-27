import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../data/Database/local_storage_dao.dart';

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
  List<String> _adultNames = [];
  List<String> _childNames = [];
  List<String> _selectedAdults = [];
  Set<String> _disabledAdultNames = <String>{};

  // Design Constants
  static const double _labelFontSize = 14.0;
  static const double _inputFontSize = 14.0;
  static const double _buttonFontSize = 13.0;
  static const double _radioFontSize = 14.0;
  static const double _verticalSpacing = 16.0;
  static const double _smallVerticalSpacing = 8.0;
  static const double _horizontalPadding = 12.0;
  static const double _verticalPadding = 16.0;
  static const double _borderRadius = 4.0;
  static const double _buttonHeight = 40.0;
  static const double _buttonWidth = 100.0;

  final List<Map<String, dynamic>> _memberTypes = [];

  String get _selectedMemberLabel {
    if (_selectedAdults.isNotEmpty) {
      return _selectedAdults.join(', ');
    }
    final selected = _memberTypes.where((type) => type['selected'] == true).toList();
    if (selected.isEmpty) {
      return 'Select member type';
    }
    return selected.map((type) => type['label']).join(', ');
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
    final isAdultFlag = (v is int && v == 1) ||
        (v is bool && v == true) ||
        (v is String && (v == '1' || v.toLowerCase() == 'true'));
    if (isAdultFlag) return true;

    final memberType = (info['memberType'] ?? info['MemberType'] ?? '').toString();
    if (memberType.toLowerCase() == 'adult') return true;

    final maritalStatus = (info['maritalStatus'] ?? info['MaritalStatus'] ?? '').toString();
    if (maritalStatus.isNotEmpty) return true;

    final spouseName = (info['spouseName'] ?? info['SpouseName'] ?? '').toString();
    if (spouseName.isNotEmpty) return true;

    final relation = (info['relation_to_head'] ?? info['relation'] ?? '').toString().toLowerCase();
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
    _houseNoController.addListener(() {
      setState(() {});
    });
    _loadHouseholdMembers();
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    super.dispose();
  }


  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: _labelFontSize,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontSize: _labelFontSize,
              fontWeight: FontWeight.normal,
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownContainer(String label, Widget child) {
    return GestureDetector(
      onTap: () => _showMemberTypeDialog(),
      child: Container(

        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
         //vertical: _verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white
         // borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Split / Migration',
        showBack: true,
      ),
      body: Padding(
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
                      title: const Text(
                        'Migration',
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
                      title: const Text(
                        'Split',
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
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading members...',
                        style: TextStyle(fontSize: _labelFontSize),
                      ),
                    ],
                  )
                else if (_loadError != null)
                  const Text(
                    'Failed to load members',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: _labelFontSize,
                    ),
                  ),
              ],

              if (_selectedOption == MigrationSplitOption.migration)
                ..._buildMigrationForm(),

              if (_selectedOption == MigrationSplitOption.split)
                ..._buildSplitForm(),

              const SizedBox(height: _verticalSpacing),
            ],
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
      final rows = await LocalStorageDao.instance.getBeneficiariesByHousehold(hhid);
      print('MigrationSplitScreen: Loaded ${rows.length} beneficiaries for household_ref_key=$hhid');

      setState(() {
        _householdMembers = rows;
        _disabledAdultNames = <String>{};
        final adults = <String>[];
        final children = <String>[];

        for (final r in rows) {
          // Skip if member is migrated (is_migrated = 1)
          final isMigrated = r['is_migrated'] == 1 || r['is_migrated'] == '1' || r['is_migrated'] == true;
          if (isMigrated) continue;

          final info = _tryDecodeInfo(r['beneficiary_info']);
          final isAdult = _isAdultRecord(info, r);
          final nm = (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString();
          final rel = (info['relation_to_head'] ?? info['relation'] ?? '').toString().toLowerCase();

          if (isAdult) {
            if (nm.isNotEmpty) {
              adults.add(nm);
              if (rel == 'self') {
                _disabledAdultNames.add(nm);
              }
            }
          } else {
            if (nm.isNotEmpty) {
              children.add(nm);
            }
          }
        }

        _adultNames = adults.toSet().toList();
        _childNames = children.toSet().toList();
      });
    } catch (e) {
      print('MigrationSplitScreen: Error loading household members for $hhid -> $e');
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

  Future<bool> _showConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Do you want to continue?',
          style: TextStyle(fontSize: _labelFontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(fontSize: _buttonFontSize),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(fontSize: _buttonFontSize),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  List<Widget> _buildMigrationForm() {
    return [
      const SizedBox(height: _verticalSpacing),

      _buildLabel('Select Member', isRequired: true),

      _buildDropdownContainer(
        ' ',
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedMemberLabel,
                style: TextStyle(
                  fontSize: _inputFontSize,
                  color: _isMemberTypeSelected ? Colors.black : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
      const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      const SizedBox(height: _verticalSpacing),

      if (_isMemberTypeSelected) ...[
        _buildLabel('Select Child'),

        ApiDropdown<String>(
          items: _childNames,
          getLabel: (item) => item,
          value: _selectedChild,
          onChanged: (value) {
            setState(() {
              _selectedChild = value;
            });
          },
          hintText: 'Select a member',
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
            onPressed: _isMemberTypeSelected
                ? () async {
              final confirm = await _showConfirmDialog();
              if (confirm) {
                _handleMigration();
              }
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'MIGRATE',
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

  List<Widget> _buildSplitForm() {
    return [
      const SizedBox(height: _verticalSpacing),

      // Member Type Dropdown
      _buildLabel('Select Member Type', isRequired: true),

      _buildDropdownContainer(
        ' ',
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedMemberLabel,
                style: TextStyle(
                  fontSize: _inputFontSize,
                  color: _isMemberTypeSelected ? Colors.black : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
      const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      const SizedBox(height: _verticalSpacing),

      if (_isMemberTypeSelected) ...[
        // Select Child (Optional)
        _buildLabel('Select Child (Optional)'),
        const SizedBox(height: _smallVerticalSpacing),
        ApiDropdown<String>(
          items: _childNames,
          getLabel: (item) => item,
          value: _selectedChild,
          onChanged: (value) {
            setState(() {
              _selectedChild = value;
            });
          },
          hintText: 'Select a child',
        ),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: _verticalSpacing),

        // Select New Family Head
        _buildLabel('Select New Family Head', isRequired: true),
        const SizedBox(height: _smallVerticalSpacing),
        ApiDropdown<String>(
          items: _selectedAdults,
          getLabel: (item) => item,
          value: _selectedFamilyHead,
          onChanged: (value) {
            setState(() {
              _selectedFamilyHead = value;
            });
          },
          hintText: 'Select new family head',
        ),
        const Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: _verticalSpacing),

        // House No TextField
        _buildLabel('House No', isRequired: true),
        const SizedBox(height: _smallVerticalSpacing),
        TextField(
          controller: _houseNoController,
          style: const TextStyle(fontSize: _inputFontSize),
          decoration: InputDecoration(
            hintText: 'Enter house number',
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: _inputFontSize,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: _horizontalPadding,
              vertical: _verticalPadding,
            ),
            border: InputBorder.none,
          ),
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
            onPressed: _isMemberTypeSelected &&
                _selectedFamilyHead != null &&
                _houseNoController.text.trim().isNotEmpty
                ? () async {
              final confirm = await _showConfirmDialog();
              if (confirm) {
                _handleSplit();
              }
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'SPLIT',
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

  void _handleMigration() {
    if (_selectedAdults.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one member to migrate',
            style: TextStyle(fontSize: _labelFontSize),
          ),
        ),
      );
      return;
    }

    final targets = <String>[..._selectedAdults];
    if (_selectedChild != null && _selectedChild!.trim().isNotEmpty) {
      targets.add(_selectedChild!.trim());
    }

    Future<void>(() async {
      int updated = 0;
      int notFound = 0;

      for (final targetName in targets.toSet()) {
        final matches = _householdMembers.where((r) {
          final info = _tryDecodeInfo(r['beneficiary_info']);
          final nm = (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString();
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
            final changes = await LocalStorageDao.instance.setBeneficiaryMigratedByUniqueKey(
              uniqueKey: uniqueKey,
              isMigrated: 1,
            );
            if (changes > 0) updated += changes;
          } catch (e) {
            print('MigrationSplitScreen: Failed to set is_migrated for $uniqueKey -> $e');
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Migration updated: $updated record(s)${notFound > 0 ? ", $notFound name(s) not found" : ''}',
            style: const TextStyle(fontSize: _labelFontSize),
          ),
        ),
      );

      await _loadHouseholdMembers();
    });
  }

  void _handleSplit() {
    if (_selectedChild == null ||
        _selectedFamilyHead == null ||
        _houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields',
            style: TextStyle(fontSize: _labelFontSize),
          ),
        ),
      );
      return;
    }

    print('Split started:');
    print('Child: $_selectedChild');
    print('New Family Head: $_selectedFamilyHead');
    print('House No: ${_houseNoController.text.trim()}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Split successful!',
          style: TextStyle(fontSize: _labelFontSize),
        ),
      ),
    );

    setState(() {
      _resetForm();
    });
  }

  void _showMemberTypeDialog() {
    final localSelectedAdults = Set<String>.from(_selectedAdults);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
              backgroundColor: Colors.white,
            content: Container(
              width: double.maxFinite,
              child: _isLoadingMembers

                  ? const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : SingleChildScrollView(
                child: Column(
                  spacing: 10,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Select Adult Member(s)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: _labelFontSize,
                        ),
                      ),
                    ),
                    if (_adultNames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'No adult members found for this household',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: _labelFontSize,
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
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _adultNames.length,
                        itemBuilder: (context, index) {
                          final name = _adultNames[index];
                          final isDisabled = _disabledAdultNames.contains(name) || index == 0;
                          return CheckboxListTile(
                            title: Text(
                              isDisabled ? '$name (Head)' : name,
                              style: TextStyle(
                                color: isDisabled ? Colors.black54 : Colors.black,
                                fontSize: _labelFontSize,
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
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: _buttonFontSize),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedAdults = localSelectedAdults
                        .where((n) => !_disabledAdultNames.contains(n))
                        .toList();
                    final vaIndex = _memberTypes.indexWhere((t) => t['value'] == 'va');
                    if (vaIndex != -1) {
                      _memberTypes[vaIndex]['selected'] = _selectedAdults.isNotEmpty;
                    }
                    _selectedMemberType = _selectedAdults.isNotEmpty ? 'va' : null;
                    if (_selectedAdults.isEmpty) {
                      _selectedChild = null;
                      _selectedFamilyHead = null;
                      _houseNoController.clear();
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: _buttonFontSize),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddChildDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(

        content: TextField(
          controller: controller,
          style: const TextStyle(fontSize: _inputFontSize),
          decoration: const InputDecoration(
            labelText: 'Child Name',
            labelStyle: TextStyle(fontSize: _labelFontSize),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(fontSize: _buttonFontSize),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  final name = controller.text.trim();
                  if (name.isNotEmpty && !_childNames.contains(name)) {
                    _childNames.add(name);
                  }
                  _selectedChild = name;
                });
                Navigator.pop(context);
              }
            },
            child: const Text(
              'ADD',
              style: TextStyle(fontSize: _buttonFontSize),
            ),
          ),
        ],
      ),
    );
  }
}