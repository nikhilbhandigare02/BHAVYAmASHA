import 'package:flutter/material.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHoldDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHold_Amenities.dart';

import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import '../AddNewFamilyMember/AddNewFamilyMember.dart';

class RegisterNewHouseHoldScreen extends StatefulWidget {
  final List<Map<String, String>>? initialMembers;
  final bool headAddedInit;
  final bool hideAddMemberButton;
  const RegisterNewHouseHoldScreen({
    super.key,
    this.initialMembers,
    this.headAddedInit = false,
    this.hideAddMemberButton = false,
  });

  @override
  State<RegisterNewHouseHoldScreen> createState() =>
      _RegisterNewHouseHoldScreenState();
}

class _RegisterNewHouseHoldScreenState extends State<RegisterNewHouseHoldScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int totalMembers = 0;
  bool headAdded = false;
  final List<Map<String, String>> _members = [];
  bool _hideAddMemberButton = false;

  final List<bool> _memberPanelsOpen = [false, false, false];
  final List<bool> _householdPanelsOpen = [false, false];
  final List<bool> _amenityPanelsOpen = [false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize from incoming data if provided
    if (widget.initialMembers != null && widget.initialMembers!.isNotEmpty) {
      _members.clear();
      _members.addAll(widget.initialMembers!);
      totalMembers = _members.length;
    }
    headAdded = widget.headAddedInit || _members.isNotEmpty;
    _hideAddMemberButton = widget.hideAddMemberButton;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
        onWillPop: () async {
          if (_members.isNotEmpty) {
            final shouldExit = await showConfirmationDialog(
              context: context,
              title: 'Attention !',
              message: 'If you get back, Details will be lost. So, Do you want to go back ?',
              yesText: 'Yes, Exit',
              noText: 'No',
            );
            return shouldExit ?? false;
          }
          return true;
        },
        child:  Scaffold(
          appBar:  AppHeader(
            screenTitle:
            l10n?.gridRegisterNewHousehold ?? 'Register New Household',
            showBack: true,
          ),

          body: SafeArea(
        child: Column(
          children: [

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.rnhAddHeadFirstTabs ??
                              'Please add a family head before accessing other sections.',
                        ),
                      ),
                    );
                    _tabController.animateTo(0);
                  } else {
                    _tabController.animateTo(index);
                  }
                },

                tabs: [
                  Tab(text: l10n?.rnhTabMemberDetails ?? 'MEMBER DETAILS'),
                  Tab(
                    text: l10n?.rnhTabHouseholdDetails ?? 'HOUSEHOLD DETAILS',
                  ),
                  Tab(
                    text:
                        l10n?.rnhTabHouseholdAmenities ?? 'HOUSEHOLD AMENITIES',
                  ),
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
                  HouseHoldDetails(),
                  HouseHoldAmenities(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_tabController.index > 0)
                SizedBox(
                  width: 120,
                  height: 44,
                  child: RoundButton(
                    title: l10n?.previousButton ?? 'PREVIOUS',
                    color: AppColors.primary,
                    borderRadius: 8,
                    height: 44,
                    onPress: () {
                      final prev = (_tabController.index - 1).clamp(0, 2);
                      _tabController.animateTo(prev);
                    },
                  ),
                )
              else
                const SizedBox(width: 120, height: 44),

              SizedBox(
                width: 120,
                height: 44,
                child: Builder(
                  builder: (context) {
                    final idx = _tabController.index;
                    final bool disableNext = idx == 0 && !headAdded;
                    final String rightTitle = idx == 2
                        ? (l10n?.saveButton ?? 'SAVE')
                        : (l10n?.nextButton ?? 'NEXT');
                    return IgnorePointer(
                      ignoring: disableNext,
                      child: Opacity(
                        opacity: disableNext ? 0.5 : 1.0,
                        child: RoundButton(
                          title: rightTitle,
                          color: AppColors.primary,
                          borderRadius: 8,
                          height: 44,
                          onPress: () {
                            if (disableNext) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.rnhAddHeadProceed ??
                                        'Please add a family head before proceeding.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (idx < 2) {
                              _tabController.animateTo(idx + 1);
                            } else {
                              // TODO: Save action for amenities
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> _openAddHead() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => AddNewFamilyHeadScreen()),
    );
    if (result != null) {
      setState(() {
        headAdded = true;
        totalMembers = totalMembers + 1;
        _members.add({
          '#': '${_members.length + 1}',
          'Type': 'Adult',
          'Name': result['Name'] ?? '',
          'Age': result['Age'] ?? '',
          'Gender': result['Gender'] ?? '',
          'Relation': result['Relation'] ?? 'Self',
          'Father': result['Father'] ?? '',
          'Spouse': result['Spouse'] ?? '',
          'Total Children': result['Total Children'] ?? '',
        });
      });
    }
  }

  Future<void> _openAddMember() async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const AddNewFamilyMemberScreen()),
    );
    if (result != null) {
      setState(() {
        totalMembers = totalMembers + 1;
        _members.add({
          '#': '${_members.length + 1}',
          'Type': result['Type'] ?? 'Adult',
          'Name': result['Name'] ?? '',
          'Age': result['Age'] ?? '',
          'Gender': result['Gender'] ?? '',
          'Relation': result['Relation'] ?? '',
          'Father': result['Father'] ?? '',
          'Spouse': result['Spouse'] ?? '',
          'Total Children': result['Total Children'] ?? '',
        });
      });
    }
  }

  Widget _buildMemberDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    l10n?.rnhTotalMembers ?? 'No. of total members',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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
        if (!_hideAddMemberButton)
          Center(
            child: SizedBox(
              height: 28,
              width: 170,
              child: RoundButton(
                title: headAdded
                    ? (l10n?.addNewMemberButton ?? 'ADD NEW MEMBER')
                    : (l10n?.addFamilyHeadButton ?? 'ADD FAMILY HEAD'),
                icon: Icons.add_circle_outline,
                color: AppColors.green,
                borderRadius: 4,
                height: 20,
                onPress: () {
                  if (!headAdded) {
                    _openAddHead();
                  } else {
                    _openAddMember();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMembersTable() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 0.1),
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
            (states) => AppColors.background,
          ),
          border: TableBorder.all(color: AppColors.primary, width: 0.5),
          columns: [
            DataColumn(
              label: Text(
                l10n?.thNumber ?? '#',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thType ?? 'Type',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thName ?? 'Name',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thAge ?? 'Age',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thGender ?? 'Gender',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thRelation ?? 'Relation',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thFather ?? 'Father',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thSpouse ?? 'Spouse',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                l10n?.thTotalChildren ?? 'Total Children',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          rows: _members
              .map(
                (m) => DataRow(
                  cells: [
                    DataCell(
                      Text(m['#'] ?? '', style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      Text(
                        m['Type'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Name'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Age'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Gender'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Relation'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Father'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Spouse'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m['Total Children'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }


  Widget _buildExpansionPanelList({
    required List<String> titles,
    required List<bool> opens,
    required List<Widget> contents,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
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

}
