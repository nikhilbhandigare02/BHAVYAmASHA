import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';


enum MigrationSplitOption { migration, split }

class MigrationSplitScreen extends StatefulWidget {
  const MigrationSplitScreen({super.key});

  @override
  State<MigrationSplitScreen> createState() => _MigrationSplitScreenState();
}

class _MigrationSplitScreenState extends State<MigrationSplitScreen> {
  MigrationSplitOption? _selectedOption = MigrationSplitOption.migration;
  String? _selectedMemberType;
  String? _selectedChild;
  String? _selectedFamilyHead;
  final TextEditingController _houseNoController = TextEditingController();

  // Member type options
  final List<Map<String, dynamic>> _memberTypes = [
    {'value': 'hs', 'label': 'hs (Family Head)', 'selected': false},
    {'value': 'va', 'label': 'va', 'selected': false},
  ];

  // Sample children data - replace with your actual data source
  final List<String> _children = [
    'Child 1',
    'Child 2',
    'Child 3',
    'Add New Child',
  ];

  // Sample family heads data - replace with your actual data source
  final List<String> _familyHeads = [
    'John Doe',
    'Jane Smith',
    'Robert Johnson',
    'Maria Garcia',
  ];

  // Get comma-separated list of selected member types
  String get _selectedMemberLabel {
    final selected = _memberTypes.where((type) => type['selected'] == true).toList();
    if (selected.isEmpty) {
      return 'Select member type';
    }
    // Show selected labels in the input field
    return selected.map((type) => type['label']).join(', ');
  }

  // Check if any member type is selected
  bool get _isMemberTypeSelected => _memberTypes.any((type) => type['selected'] == true);

  // Get list of selected member type values
  List<String> get _selectedMemberTypes => _memberTypes
      .where((type) => type['selected'] == true)
      .map((type) => type['value'] as String)
      .toList();

  @override
  void initState() {
    super.initState();
    // Add listener to house number controller to rebuild when text changes
    _houseNoController.addListener(() {
      setState(() {});
    });
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
                      title: Text('Migration'),
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
                      title: Text('Split'),
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

              if (_selectedOption == MigrationSplitOption.migration) ..._buildMigrationForm(),

              if (_selectedOption == MigrationSplitOption.split) ..._buildSplitForm(),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
          'Select Children',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        ApiDropdown<String>(
          items: _children,
          getLabel: (item) => item,
          value: _selectedChild,
          onChanged: (value) {
            if (value == 'Add New Child') {
              // Handle add new child
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
      ],
      SizedBox(height: 16),
      Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 100, // Smaller width
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
              minimumSize: MaterialStateProperty.all(Size(100, 36)),
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
          'Select Child',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        ApiDropdown<String>(
          items: _children,
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
          items: _familyHeads,
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
          width: 100,
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
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ).copyWith(
              minimumSize: MaterialStateProperty.all(Size(100, 36)),
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

    // Handle migration logic here
    final isFamilyHead = selectedType['value'] == 'hs';
    print('Migration started for: ${isFamilyHead ? 'Family Head' : 'Child: $_selectedChild'}');

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Migration successful!')),
    );
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
    // Create a local copy of member types for the dialog
    final localMemberTypes = List<Map<String, dynamic>>.from(_memberTypes.map((e) => Map<String, dynamic>.from(e)));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Select Member Types'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: localMemberTypes.length,
                itemBuilder: (context, index) {
                  final type = localMemberTypes[index];
                  return CheckboxListTile(
                    title: Text(type['label']),
                    value: type['selected'],
                    onChanged: (bool? value) {
                      setDialogState(() {
                        type['selected'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Check if 'va' is being deselected
                  bool wasVaSelected = _memberTypes.any((t) => t['value'] == 'va' && t['selected'] == true);
                  bool isVaNowSelected = localMemberTypes.any((t) => t['value'] == 'va' && t['selected'] == true);

                  // Update the main state with the selection
                  setState(() {
                    for (int i = 0; i < _memberTypes.length; i++) {
                      _memberTypes[i]['selected'] = localMemberTypes[i]['selected'];
                    }
                    // Update _selectedMemberType if needed for backward compatibility
                    final selected = localMemberTypes.firstWhere(
                          (t) => t['selected'] == true,
                      orElse: () => <String, dynamic>{},
                    );
                    _selectedMemberType = selected.isNotEmpty ? selected['value'] : null;

                    // If 'va' is being unchecked, clear child selection
                    if (wasVaSelected && !isVaNowSelected) {
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
                  _children.insert(_children.length - 1, controller.text.trim());
                  _selectedChild = controller.text.trim();
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