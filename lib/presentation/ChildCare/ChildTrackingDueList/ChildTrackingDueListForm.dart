import 'package:flutter/material.dart';
 import 'package:medixcel_new/core/config/themes/CustomColors.dart';
 import '../../../core/widgets/AppHeader/AppHeader.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
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
  bool _isCaseClosureChecked = false;
  String? _selectedClosureReason;

  DateTime? _dateOfDeath;
  String? _probableCauseOfDeath;
  String? _deathPlace;
  String? _reasonOfDeath;
  
  // Migration related state
  String? _migrationType;

  final TextEditingController _otherReasonController = TextEditingController();

  TextEditingController _otherCauseController = TextEditingController();
  bool _showOtherCauseField = false;
  
  @override
  void dispose() {
    _otherCauseController.dispose();
    _otherReasonController.dispose();
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  Widget _buildBirthDoseTab() {
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
                  _buildDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value;
                          });
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
    final data = [
      {'name': 'OPV-1', 'due': '14-10-2022'},
      {'name': 'DPT-1', 'due': '14-10-2022'},
      {'name': 'Hep B-1', 'due': '14-10-2022'},
      {'name': 'Hib-1', 'due': '14-10-2022'},
      {'name': 'Rota-1', 'due': '14-10-2022'},
      {'name': 'IPV-1', 'due': '14-10-2022'},
      {'name': 'PCV-1', 'due': '14-10-2022'},
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
    final data = [
      {'name': 'OPV-2', 'due': '14-11-2022'},
      {'name': 'DPT-2', 'due': '14-11-2022'},
      {'name': 'Hep B-2', 'due': '14-11-2022'},
      {'name': 'Hib-2', 'due': '14-11-2022'},
      {'name': 'Rota-2', 'due': '14-11-2022'},
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
    final data = [
      {'name': 'OPV-3', 'due': '14-12-2022'},
      {'name': 'DPT-3', 'due': '14-12-2022'},
      {'name': 'Hep B-3', 'due': '14-12-2022'},
      {'name': 'Hib-3', 'due': '14-12-2022'},
      {'name': 'IPV-2', 'due': '14-12-2022'},
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
                      _buildFourteenWeekDoseTable(),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [


                          const SizedBox(height: 16),

                          const SizedBox(height: 8),
                          
                          // Case Closure Widget
                          CaseClosureWidget(
                            isCaseClosureChecked: _isCaseClosureChecked,
                            selectedClosureReason: _selectedClosureReason,
                            migrationType: _migrationType,
                            dateOfDeath: _dateOfDeath,
                            probableCauseOfDeath: _probableCauseOfDeath,
                            deathPlace: _deathPlace,
                            reasonOfDeath: _reasonOfDeath,
                            showOtherCauseField: _showOtherCauseField,
                            otherCauseController: _otherCauseController,
                            otherReasonController: _otherReasonController,
                            onCaseClosureChanged: (value) {
                              setState(() {
                                _isCaseClosureChecked = value;
                                if (!value) {
                                  _selectedClosureReason = null;
                                  _migrationType = null;
                                  _dateOfDeath = null;
                                  _probableCauseOfDeath = null;
                                  _deathPlace = null;
                                  _reasonOfDeath = null;
                                  _showOtherCauseField = false;
                                  _otherCauseController.clear();
                                  _otherReasonController.clear();
                                }
                              });
                            },
                            onClosureReasonChanged: (value) {
                              setState(() {
                                _selectedClosureReason = value;
                                if (value != 'Death') {
                                  _dateOfDeath = null;
                                  _probableCauseOfDeath = null;
                                  _deathPlace = null;
                                  _reasonOfDeath = null;
                                  _showOtherCauseField = false;
                                  _otherCauseController.clear();
                                }
                              });
                            },
                            onMigrationTypeChanged: (value) {
                              setState(() {
                                _migrationType = value;
                              });
                            },
                            onDateOfDeathChanged: (value) {
                              setState(() {
                                _dateOfDeath = value;
                              });
                            },
                            onProbableCauseChanged: (value) {
                              setState(() {
                                _probableCauseOfDeath = value;
                                _showOtherCauseField = (value == 'Any other (specify)');
                                if (!_showOtherCauseField) {
                                  _otherCauseController.clear();
                                }
                              });
                            },
                            onDeathPlaceChanged: (value) {
                              setState(() {
                                _deathPlace = value;
                              });
                            },
                            onReasonOfDeathChanged: (value) {
                              setState(() {
                                _reasonOfDeath = value;
                              });
                            },
                            onShowOtherCauseFieldChanged: (value) {
                              setState(() {
                                _showOtherCauseField = value ?? false;
                              });
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
                  _buildTenWeekDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value;
                          });
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
                  _buildSixWeekDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value;
                          });
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
      {'name': 'MMR-1', 'due': '14-07-2023'},
      {'name': 'JE-1', 'due': '14-07-2023'},
      {'name': 'OPV-4', 'due': '14-07-2023'},
      {'name': 'DPT-4', 'due': '14-07-2023'},
      {'name': 'Hep B-4', 'due': '14-07-2023'},
      {'name': 'Hib-4', 'due': '14-07-2023'},
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
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value ?? false;
                          });
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
    final data = [
      {'name': 'DPT Booster-1', 'due': '14-01-2024'},
      {'name': 'OPV Booster-1', 'due': '14-01-2024'},
      {'name': 'MMR-2', 'due': '14-01-2024'},
      {'name': 'JE-2', 'due': '14-01-2024'},
      {'name': 'Vitamin A (1st dose)', 'due': '14-01-2024'},
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
                  _buildSixteenToTwentyFourMonthDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value ?? false;
                          });
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
    final data = [
      {'name': 'D.P.T Booster-2', 'due': '14-01-2028'},
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
                  _buildFiveToSixYearDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value ?? false;
                          });
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
    final data = [
      {'name': 'Tetanus Diphtheria (Td)', 'due': '11-10-2032'},
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
                  _buildTenYearDoseTable(),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CaseClosureWidget(
                        isCaseClosureChecked: _isCaseClosureChecked,
                        selectedClosureReason: _selectedClosureReason,
                        migrationType: _migrationType,
                        dateOfDeath: _dateOfDeath,
                        probableCauseOfDeath: _probableCauseOfDeath,
                        deathPlace: _deathPlace,
                        reasonOfDeath: _reasonOfDeath,
                        showOtherCauseField: _showOtherCauseField,
                        otherCauseController: _otherCauseController,
                        otherReasonController: _otherReasonController,
                        onCaseClosureChanged: (value) {
                          setState(() {
                            _isCaseClosureChecked = value;
                            if (!value) {
                              _selectedClosureReason = null;
                              _migrationType = null;
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                              _otherReasonController.clear();
                            }
                          });
                        },
                        onClosureReasonChanged: (value) {
                          setState(() {
                            _selectedClosureReason = value;
                            if (value != 'Death') {
                              _dateOfDeath = null;
                              _probableCauseOfDeath = null;
                              _deathPlace = null;
                              _reasonOfDeath = null;
                              _showOtherCauseField = false;
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onMigrationTypeChanged: (value) {
                          setState(() {
                            _migrationType = value;
                          });
                        },
                        onDateOfDeathChanged: (value) {
                          setState(() {
                            _dateOfDeath = value;
                          });
                        },
                        onProbableCauseChanged: (value) {
                          setState(() {
                            _probableCauseOfDeath = value;
                            _showOtherCauseField = (value == 'Any other (specify)');
                            if (!_showOtherCauseField) {
                              _otherCauseController.clear();
                            }
                          });
                        },
                        onDeathPlaceChanged: (value) {
                          setState(() {
                            _deathPlace = value;
                          });
                        },
                        onReasonOfDeathChanged: (value) {
                          setState(() {
                            _reasonOfDeath = value;
                          });
                        },
                        onShowOtherCauseFieldChanged: (value) {
                          setState(() {
                            _showOtherCauseField = value ?? false;
                          });
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
    final data = [
      {'name': 'BCG', 'due': '14-10-2022'},
      {'name': 'Hepatitis B - 0', 'due': '14-10-2022'},
      {'name': 'O. P. V. - 0', 'due': '14-10-2022'},
      {'name': 'VIT - K', 'due': '14-10-2022'},
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
