import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';

import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';

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

  // Member type options
  final List<Map<String, dynamic>> _memberTypes = [
    {'value': 'hs', 'label': 'hs (Family Head)', 'selected': false},
    {'value': 'va', 'label': 'va', 'selected': false},
  ];


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

  // Check if any member type is selected
  bool get _isMemberTypeSelected => _memberTypes.any((type) => type['selected'] == true);

  // Get list of selected member type values
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Split / Migration',
        showBack: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Migration/Split Toggle
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<MigrationSplitOption>(
                      title: Text('Migration',style: TextStyle(fontSize: 15.sp),),
                      value: MigrationSplitOption.migration,
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _selectedMemberType = null;
                          _selectedChild = null;
                          _selectedFamilyHead = null;
                          _houseNoController.clear();
                          // Reset member types selection
                          for (var type in _memberTypes) {
                            type['selected'] = false;
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<MigrationSplitOption>(
                      title: Text('Split',style: TextStyle(fontSize: 15.sp)),
                      value: MigrationSplitOption.split,
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _selectedMemberType = null;
                          _selectedChild = null;
                          _selectedFamilyHead = null;
                          _houseNoController.clear();
                          // Reset member types selection
                          for (var type in _memberTypes) {
                            type['selected'] = false;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (widget.hhid != null && widget.hhid!.isNotEmpty) ...[
                SizedBox(height: 8),
            //    Text('HHID: ${widget.hhid}', style: TextStyle(fontSize: 12, color: Colors.black54)),
                SizedBox(height: 4),
                if (_isLoadingMembers)
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading members...'),
                    ],
                  )
                else if (_loadError != null)
                  Text('Failed to load members', style: TextStyle(color: Colors.red, fontSize: 12))

              ],

              if (_selectedOption == MigrationSplitOption.migration) ..._buildMigrationForm(),

              if (_selectedOption == MigrationSplitOption.split) ..._buildSplitForm(),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
      for (final r in rows) {
        final info = _tryDecodeInfo(r['beneficiary_info']);
        final name = info['headName'] ?? info['memberName'] ?? info['name'];
        final relation = info?['relation_to_head'];
        print(' - unique_key=${r['unique_key']}, name=$name, relation_to_head=$relation');
         try {
          print('   full_row: ${jsonEncode(r)}');
        } catch (_) {
           print('   full_row(map): $r');
        }
      }
      setState(() {
        _householdMembers = rows;
         _disabledAdultNames = <String>{};
        final adults = <String>[];
        final children = <String>[];
        for (final r in rows) {
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
            } else {
              print('MigrationSplitScreen: Adult detected but name empty for unique_key=${r['unique_key']}');
            }
          } else {
            if (nm.isNotEmpty) {
              children.add(nm);
            }
          }
        }
        _adultNames = adults.toSet().toList();
        _childNames = children.toSet().toList();
        print('MigrationSplitScreen: Adult candidates extracted: ${_adultNames.length} -> $_adultNames');
        print('MigrationSplitScreen: Child candidates extracted: ${_childNames.length} -> $_childNames');
        if (_disabledAdultNames.isNotEmpty) {
          print('MigrationSplitScreen: Disabled adults (relation_to_head=self): ${_disabledAdultNames.toList()}');
        }
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
        content: Text('Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(fontSize: 14)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  List<Widget> _buildMigrationForm() {
    return [
      SizedBox(height: 20),
      // Member Type Dropdown with Checkbox
      RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
          children: [
            const TextSpan(text: 'Select Member Type'),
            TextSpan(
              text: ' *',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showMemberTypeDialog(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            // border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedMemberLabel,
                style: TextStyle(
                  color: _isMemberTypeSelected ? Colors.black : Colors.grey[600],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      SizedBox(height: 16),
      // Show children dropdown if any member type is selected
      if (_isMemberTypeSelected) ...[
        SizedBox(height: 16),
        Text(
          'Select child',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
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
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      ],
      SizedBox(height: 16),
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 100.0, // Smaller width
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
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              minimumSize: MaterialStateProperty.all(Size(100.0, 36.0)),
            ),
            child: Text(
              'MIGRATE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14, // Smaller font size
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSplitForm() {
    return [
      SizedBox(height: 20),
       RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
          children: [
            const TextSpan(text: 'Select Member Type'),
            TextSpan(
              text: ' *',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 8),
      GestureDetector(
        onTap: () => _showMemberTypeDialog(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedMemberLabel,
                style: TextStyle(
                  color: _isMemberTypeSelected ? Colors.black : Colors.grey[600],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
      Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      SizedBox(height: 16),
       if (_isMemberTypeSelected) ...[
        SizedBox(height: 16),
        Text(
          'Select Child',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        ApiDropdown<String>(
          items: [..._childNames, 'Add New Child'],
          getLabel: (item) => item,
          value: _selectedChild,
          onChanged: (value) {
            if (value == 'Add New Child') {
              _showAddChildDialog();
            } else {
              setState(() {
                _selectedChild = value;
              });
            }
          },
          hintText: 'Select a child',
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        SizedBox(height: 16),
        // Select New Family Head dropdown
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
            children: [
              const TextSpan(text: 'Select New Family Head'),
              TextSpan(
                text: ' *',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        ApiDropdown<String>(
          items: _adultNames,
          getLabel: (item) => item,
          value: _selectedFamilyHead,
          onChanged: (value) {
            setState(() {
              _selectedFamilyHead = value;
            });
          },
          hintText: 'Select new family head',
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        SizedBox(height: 16),
        // House No TextField
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
            children: [
              const TextSpan(text: 'House No'),
              TextSpan(
                text: ' *',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _houseNoController,
          decoration: InputDecoration(
            hintText: 'Enter house number',
            hintStyle: TextStyle(color: Colors.grey[600]),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: InputBorder.none,
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
      ],
      SizedBox(height: 16),
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 100.0,
          child: ElevatedButton(
            onPressed: _isMemberTypeSelected &&
                _selectedChild != null &&
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
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              minimumSize: MaterialStateProperty.all(Size(100.0, 36.0)),
            ),
            child: Text(
              'SPLIT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  void _handleMigration() {
    final selectedType = _memberTypes.cast<Map<String, dynamic>>().firstWhere(
      (type) => type['selected'] == true,
      orElse: () => <String, dynamic>{},
    );

    if (selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a member type')),
      );
      return;
    }

    // Build list of target names from selections (adults and/or child)
    final targets = <String>[];
    if (_selectedAdults.isNotEmpty) targets.addAll(_selectedAdults);
    if (_selectedChild != null && _selectedChild!.trim().isNotEmpty) targets.add(_selectedChild!.trim());

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one member to migrate')),
      );
      return;
    }

    // Map names to rows and update is_migrated=1
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
            final changes = await LocalStorageDao.instance.setBeneficiaryMigratedByUniqueKey(uniqueKey: uniqueKey, isMigrated: 1);
            if (changes > 0) updated += changes;
          } catch (e) {
            print('MigrationSplitScreen: Failed to set is_migrated for $uniqueKey -> $e');
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Migration updated: $updated record(s)${notFound > 0 ? ", $notFound name(s) not found" : ''}')),
      );

      // Refresh members to reflect any UI changes
      await _loadHouseholdMembers();
    });
  }

  void _handleSplit() {
    if (_selectedChild == null || _selectedFamilyHead == null || _houseNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Handle split logic here
    print('Split started:');
    print('Child: $_selectedChild');
    print('New Family Head: $_selectedFamilyHead');
    print('House No: ${_houseNoController.text.trim()}');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split successful!')),
    );

    // Clear the form after successful split
    setState(() {
      _selectedChild = null;
      _selectedFamilyHead = null;
      _houseNoController.clear();
      for (var type in _memberTypes) {
        type['selected'] = false;
      }
    });
  }

  void _showMemberTypeDialog() {
    // Local copy of selected adults for dialog state
    final localSelectedAdults = Set<String>.from(_selectedAdults);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Select Member(s)'),
            content: Container(
              width: double.maxFinite,
              child: _isLoadingMembers
                  ? SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text('Select Adult Member(s)', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          if (_adultNames.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text('No adult members found for this household', style: TextStyle(color: Colors.black54)),
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
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _adultNames.length,
                              itemBuilder: (context, index) {
                                final name = _adultNames[index];
                                final isDisabled = _disabledAdultNames.contains(name);
                                return CheckboxListTile(
                                  title: Text(
                                    isDisabled ? '$name (Head)' : name,
                                    style: isDisabled ? const TextStyle(color: Colors.black54) : null,
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
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Update the main state with the selection
                  setState(() {
                    // Persist selected adults (exclude disabled ones)
                    _selectedAdults = localSelectedAdults.where((n) => !_disabledAdultNames.contains(n)).toList();
                    // Auto-toggle 'va' option depending on selection to keep rest of UI logic
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
                child: Text('OK'),
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
        title: Text('Add New Child'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Child Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
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
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }
}