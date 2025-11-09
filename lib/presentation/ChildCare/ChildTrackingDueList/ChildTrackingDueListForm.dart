
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../core/widgets/TextField/TextField.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import 'case_closure_widget.dart';

class ChildTrackingDueListForm extends StatefulWidget {
  const ChildTrackingDueListForm({Key? key}) : super(key: key);

  @override
  State<ChildTrackingDueListForm> createState() => _ChildTrackingDueState();
}

class _ChildTrackingDueState extends State<ChildTrackingDueListForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, Map<String, dynamic>> _tabCaseClosureState = {};
  final Map<int, TextEditingController> _otherCauseControllers = {};
  final Map<int, TextEditingController> _otherReasonControllers = {};
  late DateTime _birthDate;
  late Map<String, dynamic> _formData;
  String? _lastChildName;

  @override
  void initState() {
    super.initState();
    _birthDate = DateTime.now();
    _formData = {};
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Extract arguments in didChangeDependencies (safe to access context here)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['formData'] != null) {
      final newFormData = args['formData'] as Map<String, dynamic>;
      final childName = newFormData['child_name']?.toString() ?? '';
      
      // Only update if this is a different child
      if (_lastChildName != childName) {
        _lastChildName = childName;
        _formData = newFormData;
        final dobStr = _formData['date_of_birth']?.toString() ?? '';
        final weight = _formData['weight_grams']?.toString() ?? '';
        
        debugPrint('📋 ChildTrackingDueListForm - Received formData for NEW CHILD');
        debugPrint('   - Child Name: ${_formData['child_name']}');
        debugPrint('   - Date of Birth: $dobStr');
        debugPrint('   - Weight (grams): $weight');
        debugPrint('   - Gender: ${_formData['gender']}');
        debugPrint('   - Father Name: ${_formData['father_name']}');
        debugPrint('   - Mother Name: ${_formData['mother_name']}');
        debugPrint('   - Mobile Number: ${_formData['mobile_number']}');
        
        if (dobStr.isNotEmpty) {
          try {
            _birthDate = DateTime.parse(dobStr);
            debugPrint('✅ Birth date parsed successfully: $_birthDate');
            setState(() {});
          } catch (e) {
            debugPrint('❌ Error parsing birth date: $e');
            _birthDate = DateTime.now();
          }
        } else {
          debugPrint('⚠️ No birth date provided, using current date');
          _birthDate = DateTime.now();
        }
      }
    } else {
      debugPrint('❌ No formData received in arguments');
      _birthDate = DateTime.now();
      _formData = {};
      _lastChildName = null;
    }
  }

  // Calculate due date for each vaccination schedule
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
    };
    _otherCauseControllers[tabIndex] ??= TextEditingController();
    _otherReasonControllers[tabIndex] ??= TextEditingController();
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

  @override
  void dispose() {
    for (var c in _otherCauseControllers.values) {
      c.dispose();
    }
    for (var c in _otherReasonControllers.values) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }
  final List<String> tabs = [
    'BIRTH DOSES',
    '6 WEEK',
    '10 WEEK',
    '14 WEEK',
    '9 MONTHS',
    '16-24 MONTHS',
    '5-6 YEAR',
    '10 YEAR',
    '16 YEAR',
  ];

  Widget _buildBirthDoseTab() {
    final tabIndex = 0; // Birth Dose tab
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
                  _infoRow('Date of Visits', _getBirthDateFormatted()),
                  const Divider(),
                  const SizedBox(height: 8),
                  CustomTextField(
                    labelText: 'Weight (1.2–90)kg',
                    initialValue: _formData['weight_grams'] != null
                        ? '${(int.tryParse(_formData['weight_grams'].toString()) ?? 0) / 1000}'
                        : null,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Convert kg to grams and update form data
                      final grams = (double.tryParse(value) ?? 0) * 1000;
                      _formData['weight_grams'] = grams.round();
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixWeekDoseTable() {
    final sixWeekDueDate = _calculateDueDate(6);
    final data = [
      {'name': 'O.P.V. -1', 'due': sixWeekDueDate},
      {'name': 'D.P.T. -1', 'due': sixWeekDueDate},
      {'name': 'Pentavelent 1', 'due': sixWeekDueDate},
      {'name': 'Rota-1', 'due': sixWeekDueDate},
      {'name': 'I.P.V.-1', 'due': sixWeekDueDate},
      {'name': 'P.C.V.-1', 'due': sixWeekDueDate},
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
              child: Text('6 Week Doses', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Tracking Due',
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
              tabs: tabs.map((e) => Tab(text: e)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((tabName) {
                if (tabName == 'BIRTH DOSES') {
                  return _buildBirthDoseTab();
                } else if (tabName == '6 WEEK') {
                  return _buildSixWeekTab();
                } else if (tabName == '10 WEEK') {
                  return _buildTenWeekTab();
                } else if (tabName == '14 WEEK') {
                  return _buildFourteenWeekTab();
                } else if (tabName == '9 MONTHS') {
                  return _buildNineMonthTab();
                } else if (tabName == '16-24 MONTHS') {
                  return _buildSixteenToTwentyFourMonthTab();
                } else if (tabName == '5-6 YEAR') {
                  return _buildFiveToSixYearTab();
                } else if (tabName == '10 YEAR') {
                  return _buildTenYearTab();
                } else if (tabName == '16 YEAR') {
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
    final tenWeekDueDate = _calculateDueDate(10);
    final data = [
      {'name': 'O.P.V.-2', 'due': tenWeekDueDate},
      {'name': 'Pentavelent -2', 'due': tenWeekDueDate},
      {'name': 'Rota-2', 'due': tenWeekDueDate},
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
              child: Text('10 Week Doses', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFourteenWeekDoseTable() {
    final fourteenWeekDueDate = _calculateDueDate(14);
    final data = [
      {'name': 'O.P.V.-3', 'due': fourteenWeekDueDate},
      {'name': 'Pentavalent-3', 'due': fourteenWeekDueDate},
      {'name': 'Rota 3', 'due': fourteenWeekDueDate},
      {'name': 'IPV 2', 'due': fourteenWeekDueDate},
      {'name': 'P.V.C. -2', 'due': fourteenWeekDueDate},
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
              child: Text('14 Week Doses', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFourteenWeekTab() {
    final tabIndex = 3; // 14 Week tab
    _initializeTabState(tabIndex);
    String? isBeneficiaryAbsent;
    final List<String> absentOptions = ['No', 'Yes'];

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


                          const SizedBox(height: 16),

                          const SizedBox(height: 8),

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
                          const SizedBox(height: 16),
                          const Text(
                            'Is Beneficiary Absent?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          ApiDropdown<String>(
                            labelText: 'Select',
                            items: absentOptions,
                            value: isBeneficiaryAbsent,
                            onChanged: (value) {
                              setState(() {
                                isBeneficiaryAbsent = value;
                              });
                            },
                            getLabel: (value) => value,
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RoundButton(
                  title: 'SAVE',
                  onPress: () {},
                  height: 50,
                  borderRadius: 8,
                  fontSize: 16,
                  spacing: 1.2,
                ),
              ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildNineMonthDoseTable() {
    final data = [
      {'name': 'Measles -1', 'due': '14-07-2023'},
      {'name': 'M.R Dose -1', 'due': '14-07-2023'},
      {'name': 'Vitamin A Dose -1', 'due': '14-07-2023'},
      {'name': 'J.E Vaccine -1', 'due': '14-07-2023'},
      {'name': 'P.V.C Booster', 'due': '14-07-2023'},
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
                  const SizedBox(height: 8),
                  _infoRow('Date of visit', '30-10-2025'),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Weight (1.2–90)kg',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Enter weight',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixteenToTwentyFourMonthDoseTable() {
    final sixteenToTwentyFourMonthDueDate = _calculateDueDate(20);
    final data = [
      {'name': 'O.P.V. Booster-1', 'due': sixteenToTwentyFourMonthDueDate},
      {'name': 'D.P.T. Booster-1', 'due': sixteenToTwentyFourMonthDueDate},

      {'name': 'J.E Vaccine 2', 'due': sixteenToTwentyFourMonthDueDate},
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundButton(
              title: 'SAVE',
              onPress: () {},
              height: 50,
              borderRadius: 8,
              fontSize: 16,
              spacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseTable() {
    final birthDueDate = _getBirthDateFormatted();
    final data = [
      {'name': 'BCG', 'due': birthDueDate},
      {'name': 'Hepatitis B - 0', 'due': birthDueDate},
      {'name': 'O. P. V. - 0', 'due': birthDueDate},
      {'name': 'VIT - K', 'due': birthDueDate},
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
              child: Text('Birth Doses', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
