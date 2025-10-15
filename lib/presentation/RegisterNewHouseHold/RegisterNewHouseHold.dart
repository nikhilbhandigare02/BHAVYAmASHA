import 'package:flutter/material.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

import '../../core/widgets/RoundButton/RoundButton.dart'; // ✅ your custom header

class RegisterNewHouseHoldScreen extends StatefulWidget {
  const RegisterNewHouseHoldScreen({super.key});

  @override
  State<RegisterNewHouseHoldScreen> createState() =>
      _RegisterNewHouseHoldScreenState();
}

class _RegisterNewHouseHoldScreenState
    extends State<RegisterNewHouseHoldScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int totalMembers = 0;
  bool headAdded = false;
  final List<Map<String, String>> _members = [];

  final List<bool> _memberPanelsOpen = [false, false, false];
  final List<bool> _householdPanelsOpen = [false, false];
  final List<bool> _amenityPanelsOpen = [false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              screenTitle:
              l10n?.gridRegisterNewHousehold ?? 'Register New Household',
              showBack: true,
            ),

            Material(
              color: AppColors.primary,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.onPrimary,
                labelColor: AppColors.onPrimary,
                unselectedLabelColor: AppColors.onPrimary,

                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                onTap: (index) {
                  if (!headAdded && index > 0) {
                    // Block navigation to later tabs until head is added
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add a family head before accessing other sections.')),
                    );
                    // Keep focus on first tab
                    _tabController.animateTo(0);
                  } else {
                    _tabController.animateTo(index);
                  }
                },

                tabs: const [
                  Tab(text: 'MEMBER DETAILS'),
                  Tab(text: 'HOUSEHOLD DETAILS'),
                  Tab(text: 'HOUSEHOLD AMENITIES'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: (!headAdded)
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  _buildMemberDetails(context),
                  _buildHouseholdDetails(context),
                  _buildHouseholdAmenities(context),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                height: 44,
                child: Builder(builder: (context) {
                  final bool disableNext = _tabController.index == 0 && !headAdded;
                  return IgnorePointer(
                    ignoring: disableNext,
                    child: Opacity(
                      opacity: disableNext ? 0.5 : 1.0,
                      child: RoundButton(
                        title: _tabController.index < 2 ? 'NEXT' : 'FINISH',
                        color: const Color(0xFF2E73B8),
                        borderRadius: 8,
                        height: 44,
                        onPress: () {
                          if (disableNext) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please add a family head before proceeding.')),
                            );
                            return;
                          }
                          if (_tabController.index < 2) {
                            _tabController.animateTo(_tabController.index + 1);
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- MEMBER DETAILS TAB ----------------
  Widget _buildMemberDetails(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No. of total members',
                    style:
                    TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalMembers',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (headAdded) _buildMembersTable(),
        if (headAdded) const SizedBox(height: 16),
        Center(
          child: SizedBox(
            height: 28,
            width: 170,
            child: RoundButton(
              title: headAdded ? 'ADD NEW MEMBER' : 'ADD FAMILY HEAD',
              icon: Icons.add_circle_outline,
              color: AppColors.green,
              borderRadius: 4,
              height: 20,
              onPress: () {
                setState(() {
                  if (!headAdded) {
                    headAdded = true;
                    totalMembers = totalMembers + 1;
                    _members.add({
                      '#': '1',
                      'Type': 'Adult',
                      'Name': '',
                      'Age': '',
                      'Gender': '',
                      'Relation': 'Self',
                      'Father': '',
                      'Spouse': '',
                      'Total Children': '',
                    });
                  } else {
                    totalMembers = totalMembers + 1;
                    _members.add({
                      '#': '${_members.length + 1}',
                      'Type': 'Adult',
                      'Name': '',
                      'Age': '',
                      'Gender': '',
                      'Relation': '',
                      'Father': '',
                      'Spouse': '',
                      'Total Children': '',
                    });
                  }
                });
              },
            ),
          ),
        ),


      ],
    );
  }

  Widget _buildMembersTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DataTable(
          headingRowHeight: 32,
          dataRowHeight: 28,
          columnSpacing: 8,
          horizontalMargin: 5,
          dividerThickness: 0.1,
          headingRowColor: MaterialStateColor.resolveWith(
                (states) => AppColors.background,
          ),
          dataRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.white,
          ),
          border: TableBorder.all(color: AppColors.primary, width: 0.5),
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Type', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Name', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Age', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Gender', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Relation', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Father', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Spouse', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Total Children', style: TextStyle(fontSize: 12))),
          ],
          rows: _members
              .map(
                (m) => DataRow(
              cells: [
                DataCell(Text(m['#'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Type'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Name'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Age'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Gender'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Relation'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Father'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Spouse'] ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text(m['Total Children'] ?? '', style: const TextStyle(fontSize: 12))),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }


  // ---------------- HOUSEHOLD DETAILS TAB ----------------
  Widget _buildHouseholdDetails(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExpansionPanelList(
          titles: const ['Address Details', 'Socio-economic Details'],
          opens: _householdPanelsOpen,
          contents: [
            _addressForm(),
            _socioEconomicForm(),
          ],
        ),
      ],
    );
  }

  Widget _buildHouseholdAmenities(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildExpansionPanelList(
          titles: const ['Water & Sanitation', 'Cooking Fuel', 'Electricity'],
          opens: _amenityPanelsOpen,
          contents: [
            _amenitiesForm(section: 'Water & Sanitation'),
            _amenitiesForm(section: 'Cooking Fuel'),
            _amenitiesForm(section: 'Electricity'),
          ],
        ),
      ],
    );
  }

  // ---------------- EXPANSION PANEL GENERATOR ----------------
  Widget _buildExpansionPanelList({
    required List<String> titles,
    required List<bool> opens,
    required List<Widget> contents,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionPanelList(
        elevation: 2,
        expandedHeaderPadding: EdgeInsets.zero,
        expansionCallback: (index, isOpen) {
          setState(() {
            opens[index] = !isOpen;
          });
        },
        children: List.generate(titles.length, (index) {
          return ExpansionPanel(
            canTapOnHeader: true,
            isExpanded: opens[index],
            headerBuilder: (context, isOpen) {
              return ListTile(
                title: Text(
                  titles[index],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: contents[index],
            ),
          );
        }),
      ),
    );
  }


  Widget _addressForm() {
    return Column(
      children: const [
        TextField(
          decoration: InputDecoration(
            labelText: 'House No.',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Street/Locality',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            labelText: 'Pincode',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _socioEconomicForm() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: 'APL', child: Text('APL')),
            DropdownMenuItem(value: 'BPL', child: Text('BPL')),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(
            labelText: 'Economic Status',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: 'GEN', child: Text('General')),
            DropdownMenuItem(value: 'OBC', child: Text('OBC')),
            DropdownMenuItem(value: 'SC', child: Text('SC')),
            DropdownMenuItem(value: 'ST', child: Text('ST')),
          ],
          onChanged: (_) {},
          decoration: const InputDecoration(
            labelText: 'Caste',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _amenitiesForm({required String section}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: const Text('Available'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Remarks',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
