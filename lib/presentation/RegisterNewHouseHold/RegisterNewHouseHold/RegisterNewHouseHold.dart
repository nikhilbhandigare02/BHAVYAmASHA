import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHoldDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHold_Amenities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';

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
  Map<String, dynamic>? _headForm;
  final List<Map<String, dynamic>> _memberForms = [];
  bool _hideAddMemberButton = false;
  late final HouseholdDetailsAmenitiesBloc _hhBloc;
  bool _skipExitConfirm = false;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _hhBloc = HouseholdDetailsAmenitiesBloc();

    // Initialize from incoming data if provided
    if (widget.initialMembers != null && widget.initialMembers!.isNotEmpty) {
      _members.clear();
      _members.addAll(widget.initialMembers!);
      totalMembers = _members.length;
    }
    headAdded = widget.headAddedInit || _members.isNotEmpty;
    _hideAddMemberButton = widget.hideAddMemberButton;
  }

  // Deep-convert all 'Yes'/'No' values to 1/0 for storage
  dynamic _convertYesNoDynamic(dynamic value) {
    if (value is String) {
      if (value == 'Yes') return 1;
      if (value == 'No') return 0;
      return value;
    } else if (value is Map) {
      return _convertYesNoMap(Map<String, dynamic>.from(value as Map));
    } else if (value is List) {
      return value.map(_convertYesNoDynamic).toList();
    }
    return value;
  }

  Map<String, dynamic> _convertYesNoMap(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      out[k] = _convertYesNoDynamic(v);
    });
    return out;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hhBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
        onWillPop: () async {
          if (_skipExitConfirm) return true;
          if (_members.isNotEmpty) {
            final shouldExit = await showConfirmationDialog(
              context: context,
              title: l10n?.confirmAttentionTitle ?? 'Attention!',
              message: l10n?.confirmBackLoseDetailsMsg ?? 'If you go back, details will be lost. Do you want to go back?',
              yesText: l10n?.confirmYesExit ?? 'Yes, Exit',
              noText: l10n?.confirmNo ?? 'No',
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
                  BlocProvider.value(value: _hhBloc, child: const HouseHoldDetails()),
                  BlocProvider.value(value: _hhBloc, child: const HouseHoldAmenities()),
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
                              final now = DateTime.now();
                              final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
                              final s = _hhBloc.state;
                              final householdFormJson = {
                                'headdetails': _headForm ?? {},
                                'memberdetails': _memberForms,
                                'spousedetails': _headForm?['spousedetails'] ?? {},
                                'childrendetails': _headForm?['childrendetails'] ?? {},
                                'amenities': {
                                  'residentialArea': s.residentialArea,
                                  'ownershipType': s.ownershipType,
                                  'houseType': s.houseType,
                                  'houseKitchen': s.houseKitchen,
                                  'cookingFuel': s.cookingFuel,
                                  'waterSource': s.waterSource,
                                  'electricity': s.electricity,
                                  'toilet': s.toilet,
                                },
                              };
                              final normalizedHouseholdInfo = _convertYesNoMap(Map<String, dynamic>.from(householdFormJson));
                              debugPrint(jsonEncode(normalizedHouseholdInfo));

                              final payload = {
                                'server_id': null,
                                'unique_key': 'HH_${now.millisecondsSinceEpoch}',
                                'address': {},
                                'geo_location': {},
                                'head_id': _headForm?['unique_key'] ?? _headForm?['id'],
                                'household_info': normalizedHouseholdInfo,
                                'device_details': {
                                  'platform': Platform.operatingSystem,
                                },
                                'app_details': {
                                  'app_name': 'BHAVYA mASHA UAT',
                                },
                                'parent_user': {},
                                'current_user_key': 'local_user',
                                'facility_id': 283,
                                'created_date_time': ts,
                                'modified_date_time': ts,
                                'is_synced': 0,
                                'is_deleted': 0,
                              };

                              debugPrint(jsonEncode(payload));

// In the save handler:
                              LocalStorageDao.instance.insertHousehold(payload).then((_) async {
                                _skipExitConfirm = true;
                                if (!mounted) return;

                                if (mounted) {
                                  final shouldNavigate = await showSuccessDialog(context);
                                  if (shouldNavigate == true && mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      Route_Names.homeScreen,
                                      (route) => false,
                                    );
                                  }
                                }
                              });
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
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => AddNewFamilyHeadScreen()),
    );
    if (result != null) {
      setState(() {
        _headForm = Map<String, dynamic>.from(result);
        headAdded = true;
        totalMembers = totalMembers + 1;
        final String name = (result['headName'] ?? '').toString();
        final bool useDob = (result['useDob'] == true);
        final String? dobIso = result['dob'] as String?;
        String age = '';
        if (useDob && dobIso != null && dobIso.isNotEmpty) {
          final dob = DateTime.tryParse(dobIso);
          age = dob != null ? (DateTime.now().year - dob.year).toString() : (result['approxAge'] ?? '').toString();
        } else {
          age = (result['approxAge'] ?? '').toString();
        }
        final String gender = (result['gender'] ?? '').toString();
        final String father = (result['fatherName'] ?? '').toString();
        final String spouse = (result['spouseName'] ?? '').toString();
        final String totalChildren = (result['children'] != null && result['children'].toString().isNotEmpty)
            ? (int.tryParse(result['children'].toString()) ?? 0) > 0 
                ? result['children'].toString() 
                : '0'
            : '0';

        _members.add({
          '#': '${_members.length + 1}',
          'Type': 'Adult',
          'Name': name,
          'Age': age,
          'Gender': gender,
          'Relation': 'Self',
          'Father': father,
          'Spouse': spouse,
          'Total Children': totalChildren,
        });

        // Add spouse row if married and spouse details exist
        final String maritalStatus = (result['maritalStatus'] ?? '').toString();
        if (maritalStatus == 'Married' && spouse.isNotEmpty) {
          final String spouseGender = (gender == 'Male')
              ? 'Female'
              : (gender == 'Female')
                  ? 'Male'
                  : '';
          _members.add({
            '#': '${_members.length + 1}',
            'Type': 'Adult',
            'Name': spouse,
            'Age': '',
            'Gender': spouseGender,
            'Relation': 'Wife',
            'Father': '',
            'Spouse': name,
            'Total Children': totalChildren,
          });
          totalMembers = totalMembers + 1;
        }
      });
    }
  }

  Future<void> _openAddMember() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddNewFamilyMemberScreen(
          headName: _headForm?['headName']?.toString(),
          spouseName: _headForm?['spouseName']?.toString(),
          headGender: _headForm?['gender']?.toString(),
          headMobileNo: _headForm?['mobileNo']?.toString(),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _memberForms.add(Map<String, dynamic>.from(result));
        totalMembers = totalMembers + 1;
        final String type = (result['memberType'] ?? 'Adult').toString();
        final String name = (result['name'] ?? '').toString();
        final bool useDob = (result['useDob'] == true);
        final String? dobIso = result['dob'] as String?;
        String age = '';
        if (useDob && dobIso != null && dobIso.isNotEmpty) {
          final dob = DateTime.tryParse(dobIso);
          age = dob != null ? (DateTime.now().year - dob.year).toString() : (result['approxAge'] ?? '').toString();
        } else {
          age = (result['approxAge'] ?? '').toString();
        }
        final String gender = (result['gender'] ?? '').toString();
        final String relation = (result['relation'] ?? '').toString();
        final String father = (result['fatherName'] ?? '').toString();
        final String spouse = (result['spouseName'] ?? '').toString();
        final String totalChildren = (result['children'] != null && result['children'].toString().isNotEmpty)
            ? (int.tryParse(result['children'].toString()) ?? 0) > 0 
                ? result['children'].toString() 
                : '0'
            : '0';

        _members.add({
          '#': '${_members.length + 1}',
          'Type': type,
          'Name': name,
          'Age': age,
          'Gender': gender,
          'Relation': relation,
          'Father': father,
          'Spouse': spouse,
          'Total Children': totalChildren,
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
        Builder(builder: (_) {
          final int childrenTarget = int.tryParse((_headForm?['children'] ?? '').toString()) ?? 0;
          final int childrenAdded = _members.where((m) {
            final t = (m['Type'] ?? '');
            final r = (m['Relation'] ?? '');
            return t == 'Child' || t == 'Infant' || r == 'Son' || r == 'Daughter';
          }).length;
          final int remaining = (childrenTarget - childrenAdded).clamp(0, 9999);
          if (childrenTarget <= 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all( 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No. of members remains to be added: ',
                  style:  TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning, fontSize: 16),
                ),
                Text(
                  '$remaining ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
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

  Future<bool?> showSuccessDialog(BuildContext context) {
    final memberCount = _members.length + 1;
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green checkmark circle


                const SizedBox(height: 8),
                Text(
                  l10n?.dataSavedSuccessfully ??
                      'New house has been added successfully',
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.householdSavedSuccessfully(memberCount) ??
                      '$memberCount household(s) saved successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, Route_Names.homeScreen),
                      child:  Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }}