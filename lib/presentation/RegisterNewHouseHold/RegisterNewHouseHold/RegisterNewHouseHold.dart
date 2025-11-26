import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/HomeScreen/HomeScreen.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHoldDetails.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/HouseHold_Amenities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:sizer/sizer.dart';

import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import '../AddNewFamilyMember/AddNewFamilyMember.dart';
import 'bloc/registernewhousehold_bloc.dart';

class RegisterNewHouseHoldScreen extends StatefulWidget {
  final List<Map<String, String>>? initialMembers;
  final bool headAddedInit;
  final bool hideAddMemberButton;
  // If false, do not show success popup when saving (used for update flows)
  final bool showSuccessOnSave;
  // Flag to indicate whether we are editing an existing household
  final bool isEdit;
  // Optional initial head form, used in edit flows so that SaveHousehold
  // can see the existing keys (hh_unique_key, head_unique_key, etc.).
  final Map<String, dynamic>? initialHeadForm;

  const RegisterNewHouseHoldScreen({
    super.key,
    this.initialMembers,
    this.headAddedInit = false,
    this.hideAddMemberButton = false,
    this.showSuccessOnSave = true,
    this.isEdit = false,
    this.initialHeadForm,
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
    _hhBloc = HouseholdDetailsAmenitiesBloc();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    headAdded = widget.headAddedInit;
    _hideAddMemberButton = widget.hideAddMemberButton;
    if (widget.initialMembers != null && widget.initialMembers!.isNotEmpty) {
      _members.clear();
      _members.addAll(widget.initialMembers!
          .map((m) => Map<String, String>.from(m)));
      totalMembers = _members.length;
    }

    // When coming from an edit flow (AllHouseHold or Today's Programme),
    // we receive the original head form including technical keys like
    // hh_unique_key and head_unique_key. Store it so SaveHousehold can
    // detect isEdit and update instead of inserting.
    if (widget.initialHeadForm != null) {
      _headForm = Map<String, dynamic>.from(widget.initialHeadForm!);
      headAdded = true;
    }
  }

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
            l10n?.gridNewHouseholdRegister ?? 'Register New Household',
            showBack: true,
          ),

          body: SafeArea(
        child: Column(
          children: [

            Material(
              color: AppColors.primary,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start, // 👈 ensures tabs start flush left
                labelPadding: const EdgeInsets.symmetric(horizontal: 16), // spacing between tabs
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
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text(
                    //       l10n?.rnhAddHeadFirstTabs ??
                    //           'Please add a family head before accessing other sections.',
                    //     ),
                    //   ),
                    // );
                    _tabController.animateTo(0);
                  } else {
                    _tabController.animateTo(index);
                  }
                },
                tabs: [
                  _buildTab(l10n?.rnhTabMemberDetails ?? 'MEMBER DETAILS', 0),
                  _buildTab(l10n?.rnhTabHouseholdDetails ?? 'HOUSEHOLD DETAILS', 1),
                  _buildTab(l10n?.rnhTabHouseholdAmenities ?? 'HOUSEHOLD AMENITIES', 2),
                ],
              ),
            ),


            Expanded(
              child: BlocProvider.value(
                value: _hhBloc,
                child: TabBarView(
                  controller: _tabController,
                  physics: (!headAdded)
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    _buildMemberDetails(context),
                    const HouseHoldDetails(),
                    const HouseHoldAmenities(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_tabController.index > 0)
                SizedBox(
                  width: 25.5.w,
                  height: 4.5.h,
                  child: RoundButton(
                    title: l10n?.previousButton ?? 'PREVIOUS',
                    color: AppColors.primary,
                    fontSize: 14.sp,
                    borderRadius: 4,
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
            width: 25.5.w,
            height: 4.5.h,
            child: Builder(
              builder: (context) {
                final idx = _tabController.index;
                final bool disableNext = idx == 0 && !headAdded;

                String rightTitle;
                if (idx == 2) {
                  rightTitle = widget.isEdit
                      ? (l10n?.updateButton ?? 'UPDATE')
                      : (l10n?.saveButton ?? 'SAVE');
                } else {
                  rightTitle = (l10n?.nextButton ?? 'NEXT');
                }

                final householdBloc = context.read<RegisterNewHouseholdBloc>();
                
                return BlocConsumer<RegisterNewHouseholdBloc, RegisterHouseholdState>(
                  listener: (context, state) {
                    if (state.isSaved) {
                      _skipExitConfirm = true;
                      if (widget.showSuccessOnSave) {
                        showSuccessDialog(context).then((shouldNavigate) {
                          if (shouldNavigate == true && mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Route_Names.homeScreen,
                              (route) => false,
                            );
                          }
                        });
                      } else {
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Route_Names.homeScreen,
                            (route) => false,
                          );
                        }
                      }
                    } else if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return RoundButton(
                      title: rightTitle,
                      color: AppColors.primary,
                      height: 44,
                      isLoading: state.isSaving,
                      onPress: () async {
                        if (disableNext) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please add family head details',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        if (idx < 2) {
                          _tabController.animateTo(idx + 1);
                        } else {
                          try {
                            _hhBloc.emit(_hhBloc.state);
                            final amenitiesState = _hhBloc.state;
                            print(' Current Amenities State: ${amenitiesState.toString()}');
                            
                            // Create a map with all the amenities data
                            final amenitiesData = {
                              'residentialArea': amenitiesState.residentialArea,
                              'ownershipType': amenitiesState.ownershipType,
                              'houseType': amenitiesState.houseType,
                              'houseKitchen': amenitiesState.houseKitchen,
                              'cookingFuel': amenitiesState.cookingFuel,
                              'waterSource': amenitiesState.waterSource,
                              'electricity': amenitiesState.electricity,
                              'toilet': amenitiesState.toilet,
                              'toiletType': amenitiesState.toiletType,
                              'toiletPlace': amenitiesState.toiletPlace,
                            };
                            

                            amenitiesData.removeWhere((key, value) => 
                                value == null || 
                                (value is String && value.isEmpty) ||
                                value == '');
                            
                            print('📤 Prepared Amenities Data: $amenitiesData');
                            
                            if (amenitiesData.isEmpty) {
                              print('⚠️ Warning: No amenities data to save');
                            }
                            
                            householdBloc.add(
                              SaveHousehold(
                                headForm: _headForm,
                                memberForms: _memberForms,
                                amenitiesData: amenitiesData,
                              ),
                            );
                          } catch (e, stackTrace) {
                            print('❌ Error preparing amenities data:');
                            print('   Error: $e');
                            print('   Stack trace: $stackTrace');
                            // Re-throw to show error to user
                            rethrow;
                          }
                        }
                      },
                    );
                  },
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


        try {
          final spRaw = result['spousedetails'];
          Map<String, dynamic>? spMap;
          if (spRaw is Map) {
            spMap = Map<String, dynamic>.from(spRaw);
          } else if (spRaw is String && spRaw.isNotEmpty) {
            spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
          }
          if (spMap != null) {
            spMap.forEach((key, value) {
              if (value != null) {
                _headForm!['sp_$key'] = value.toString();
              }
            });
          }
        } catch (_) {}

        // Flatten children JSON details (if any) into children-related keys
        // so ChildrenBloc can hydrate on reopen.
        try {
          final chRaw = result['childrendetails'];
          Map<String, dynamic>? chMap;
          if (chRaw is Map) {
            chMap = Map<String, dynamic>.from(chRaw);
          } else if (chRaw is String && chRaw.isNotEmpty) {
            chMap = Map<String, dynamic>.from(jsonDecode(chRaw));
          }
          if (chMap != null) {
            chMap.forEach((key, value) {
              if (value != null) {
                _headForm![key] = value;
              }
            });
          }
        } catch (_) {}

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
          // Calculate spouse age from spouse DOB / approx age
          String spouseAge = '';
          final bool spouseUseDob = (result['spouseUseDob'] == true);
          final String? spouseDobIso = result['spouseDob'] as String?;
          if (spouseUseDob && spouseDobIso != null && spouseDobIso.isNotEmpty) {
            final dob = DateTime.tryParse(spouseDobIso);
            if (dob != null) {
              final today = DateTime.now();
              int years = today.year - dob.year;
              if (today.month < dob.month ||
                  (today.month == dob.month && today.day < dob.day)) {
                years--;
              }
              spouseAge = years.toString();
            } else {
              spouseAge = (result['spouseApproxAge'] ?? '').toString();
            }
          } else {
            spouseAge = (result['spouseApproxAge'] ?? '').toString();
          }
          _members.add({
            '#': '${_members.length + 1}',
            'Type': 'Adult',
            'Name': spouse,
            'Age': spouseAge,
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
    try {
      final beneficiaries = await LocalStorageDao.instance.getAllBeneficiaries();
      if (beneficiaries.isEmpty) {
        throw Exception('No existing beneficiary found to derive keys. Add a member first.');
      }
      final latestBeneficiary = beneficiaries.first;
      final uniqueKey = (latestBeneficiary['household_ref_key'] ?? '').toString();

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => AddNewFamilyMemberScreen(
            hhId: uniqueKey,
          ),
        ),
      );
      if (result != null) {
        setState(() {
          _memberForms.add(Map<String, dynamic>.from(result));
          final int formIndex = _memberForms.length - 1;
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
            'formIndex': formIndex.toString(),
            // This is the primary member row for this form entry.
            'isSpouseRow': '0',
          });

          // Add spouse row similar to head flow when married
          final String maritalStatus = (result['maritalStatus'] ?? '').toString();
          if (maritalStatus == 'Married' && spouse.isNotEmpty) {
            final String spouseGender = (gender == 'Male')
                ? 'Female'
                : (gender == 'Female')
                    ? 'Male'
                    : '';
            final bool spouseUseDob = (result['spouseUseDob'] == true);
            final String? spouseDobIso = result['spouseDob'] as String?;
            String spouseAge = '';
            if (spouseUseDob && spouseDobIso != null && spouseDobIso.isNotEmpty) {
              final spouseDob = DateTime.tryParse(spouseDobIso);
              if (spouseDob != null) {
                final today = DateTime.now();
                int years = today.year - spouseDob.year;
                if (today.month < spouseDob.month ||
                    (today.month == spouseDob.month && today.day < spouseDob.day)) {
                  years--;
                }
                spouseAge = years.toString();
              } else {
                spouseAge = (result['spouseApproxAge'] ?? '').toString();
              }
            } else {
              spouseAge = (result['spouseApproxAge'] ?? '').toString();
            }
            _members.add({
              '#': '${_members.length + 1}',
              'Type': 'Adult',
              'Name': spouse,
              'Age': spouseAge,
              'Gender': spouseGender,
              'Relation': 'Spouse',
              'Father': '',
              'Spouse': name,
              'Total Children': totalChildren,
              'formIndex': formIndex.toString(),
              // Mark this as the auto-generated spouse summary row.
              'isSpouseRow': '1',
            });
            totalMembers = totalMembers + 1;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMemberDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.all(2.w),
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
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
                Text(
                  '$totalMembers',
                  style:  TextStyle(fontWeight: FontWeight.w600, color: AppColors.background, fontSize: 15.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Builder(builder: (_) {
          // Total children expected in this household =
          //   head's own children count + sum of children counts
          //   declared on each member form.
          final int headChildren = int.tryParse((_headForm?['children'] ?? '').toString()) ?? 0;

          int memberChildren = 0;
          for (final form in _memberForms) {
            final dynamic rawChildren = form['children'];
            final int val = int.tryParse(rawChildren?.toString() ?? '') ?? 0;
            if (val > 0) {
              memberChildren += val;
            }
          }

          final int childrenTarget = headChildren + memberChildren;

          // Children already added as individual rows in the table.
          final int childrenAdded = _members.where((m) {
            final t = (m['Type'] ?? '');
            final r = (m['Relation'] ?? '');
            return t == 'Child' || t == 'Infant' || r == 'Son' || r == 'Daughter';
          }).length;

          // Remaining children to be added.
          final int remaining = (childrenTarget - childrenAdded).clamp(0, 9999);
          if (childrenTarget <= 0) return const SizedBox.shrink();
          return Padding(
              padding: EdgeInsets.all(2.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${l10n!.memberRemainsToAdd} :",
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning, fontSize: 17.sp),
                ),
                Text(
                  '$remaining ',
                  style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 17.sp),
                ),
              ],
            ),
          );
        }),
        if (headAdded) _buildMembersTable(),
        if (headAdded) SizedBox(height: 2.h),
        if (!_hideAddMemberButton)
          Center(
            child: SizedBox(
              height: 5.h,
              width: 25.h,
              child: RoundButton(
                title: headAdded
                    ? (l10n?.addNewMemberButton ?? 'ADD NEW MEMBER')
                    : (l10n?.addFamilyHeadButton ?? 'ADD FAMILY HEAD'),
                icon: Icons.add_circle_outline,
                color: AppColors.green,
                borderRadius: 8,
                height: 5.h,
                fontSize: 15.sp,
                iconSize: 20.sp,
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

    return Container(

      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 45.h,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 3.h,
              dataRowHeight: 3.h,
              columnSpacing: 1.5.w,
              horizontalMargin: 0.w,
              dividerThickness: 0.1,
              showCheckboxColumn: false,
              headingRowColor: MaterialStateColor.resolveWith(
                    (states) => AppColors.background,
              ),
              dataRowColor: MaterialStateColor.resolveWith(
                    (states) => AppColors.background,
              ),
              border: TableBorder.all(color: AppColors.primary, width: 0.5),
              columns: [
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thType ?? 'Type',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thName ?? 'Name',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thAge ?? 'Age',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thGender ?? 'Gender',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thRelation ?? 'Relation',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thFather ?? 'Father',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thSpouse ?? 'Spouse',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataColumn(
                  label: Center(
                    child: Text(
                      l10n?.thTotalChildren ?? 'Total Children',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              rows: _members.map((m) {

                // Use per-row children count; default to '0' when empty
                String totalChildrenText = m['Total Children'] ?? '';
                if (totalChildrenText.isEmpty) {
                  totalChildrenText = '0';
                }

                return DataRow(
                  onSelectChanged: (selected) async {
                    if (selected != true) return;

                    final formIndexStr = m['formIndex'];
                    // Inline member/child row edit when formIndex is present
                    if (formIndexStr != null && formIndexStr.toString().isNotEmpty) {
                      final idx = int.tryParse(formIndexStr.toString());
                      if (idx == null || idx < 0 || idx >= _memberForms.length) {
                        return;
                      }

                      final initialMember = Map<String, dynamic>.from(_memberForms[idx]);

                      // Decide which tab to open initially inside AddNewFamilyMemberScreen
                      // based on whether this is the auto-generated spouse summary row.
                      // We use the explicit isSpouseRow flag so that even if a member
                      // has Relation == 'Spouse', their own row still opens on the
                      // Member Details tab, and only the extra spouse row opens on
                      // the Spouse Details tab.
                      final isSpouseRow = (m['isSpouseRow'] ?? '0').toString() == '1';
                      final int initialStep = isSpouseRow ? 1 : 0;

                      final result = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => AddNewFamilyMemberScreen(
                            hhId: _headForm?['hh_unique_key']?.toString(),
                            headName: _headForm?['headName']?.toString(),
                            headGender: _headForm?['gender']?.toString(),
                            spouseName: _headForm?['spouseName']?.toString(),
                            spouseGender: _headForm?['spouseGender']?.toString(),
                            inlineEdit: true,
                            isEdit: true,
                            initial: initialMember,
                            initialStep: initialStep,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _memberForms[idx] = Map<String, dynamic>.from(result);

                          final String type = (result['memberType'] ?? 'Adult').toString();
                          final String name = (result['name'] ?? '').toString();
                          final bool useDob = (result['useDob'] == true);
                          final String? dobIso = result['dob'] as String?;
                          String age = '';
                          if (useDob && dobIso != null && dobIso.isNotEmpty) {
                            final dob = DateTime.tryParse(dobIso);
                            age = dob != null
                                ? (DateTime.now().year - dob.year).toString()
                                : (result['approxAge'] ?? '').toString();
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
                          final String maritalStatus = (result['maritalStatus'] ?? '').toString();

                          // Identify both the primary member row and (optional) spouse row
                          final String formIndexKey = formIndexStr.toString();
                          final int primaryIndex = _members.indexWhere((row) =>
                              (row['formIndex'] ?? '') == formIndexKey &&
                              (row['isSpouseRow'] ?? '0') == '0');
                          final int spouseIndex = _members.indexWhere((row) =>
                              (row['formIndex'] ?? '') == formIndexKey &&
                              (row['isSpouseRow'] ?? '0') == '1');

                          // Update primary member summary row
                          if (primaryIndex != -1) {
                            final primary = _members[primaryIndex];
                            primary['Type'] = type;
                            primary['Name'] = name;
                            primary['Age'] = age;
                            primary['Gender'] = gender;
                            primary['Relation'] = relation;
                            primary['Father'] = father;
                            primary['Spouse'] = spouse;
                            primary['Total Children'] = totalChildren;
                          }

                          // Maintain spouse summary row in sync with member details
                          if (maritalStatus == 'Married' && spouse.isNotEmpty) {
                            // Derive spouse gender and age from member details
                            final String spouseGender = (gender == 'Male')
                                ? 'Female'
                                : (gender == 'Female')
                                    ? 'Male'
                                    : '';

                            String spouseAge = '';
                            final bool spouseUseDob = (result['spouseUseDob'] == true);
                            final String? spouseDobIso = result['spouseDob'] as String?;
                            if (spouseUseDob && spouseDobIso != null && spouseDobIso.isNotEmpty) {
                              final spouseDob = DateTime.tryParse(spouseDobIso);
                              if (spouseDob != null) {
                                final today = DateTime.now();
                                int years = today.year - spouseDob.year;
                                if (today.month < spouseDob.month ||
                                    (today.month == spouseDob.month && today.day < spouseDob.day)) {
                                  years--;
                                }
                                spouseAge = years.toString();
                              } else {
                                spouseAge = (result['spouseApproxAge'] ?? '').toString();
                              }
                            } else {
                              spouseAge = (result['spouseApproxAge'] ?? '').toString();
                            }

                            if (spouseIndex != -1) {
                              // Update existing spouse summary row
                              final spouseRow = _members[spouseIndex];
                              spouseRow['Type'] = 'Adult';
                              spouseRow['Name'] = spouse;
                              spouseRow['Age'] = spouseAge;
                              spouseRow['Gender'] = spouseGender;
                              spouseRow['Relation'] = 'Spouse';
                              spouseRow['Father'] = '';
                              spouseRow['Spouse'] = name;
                              spouseRow['Total Children'] = totalChildren;
                            } else {
                              // Create spouse summary row if it does not yet exist
                              _members.add({
                                '#': '${_members.length + 1}',
                                'Type': 'Adult',
                                'Name': spouse,
                                'Age': spouseAge,
                                'Gender': spouseGender,
                                'Relation': 'Spouse',
                                'Father': '',
                                'Spouse': name,
                                'Total Children': totalChildren,
                                'formIndex': formIndexKey,
                                'isSpouseRow': '1',
                              });
                              totalMembers = totalMembers + 1;
                            }
                          } else {
                            // If no longer married or spouse cleared, remove spouse summary row
                            if (spouseIndex != -1) {
                              _members.removeAt(spouseIndex);
                              totalMembers = (totalMembers - 1).clamp(0, 9999);
                            }
                          }
                        });
                      }
                      return;
                    }

                    // Head/spouse summary rows: open AddNewFamilyHeadScreen edit
                    if (_headForm != null) {
                      final initial = <String, String>{};
                      _headForm!.forEach((key, value) {
                        if (value != null) {
                          initial[key] = value.toString();
                        }
                      });

                      // Also propagate technical keys used for update flows when editing
                      // inside the household screen.
                      for (final key in [
                        'hh_unique_key',
                        'head_unique_key',
                        'spouse_unique_key',
                        'head_id_pk',
                        'spouse_id_pk',
                      ]) {
                        final v = _headForm![key];
                        if (v != null && !initial.containsKey(key)) {
                          initial[key] = v.toString();
                        }
                      }

                      // Decide initial tab based on which summary row was tapped.
                      // Head row (Relation == 'Self') -> tab 0 (Head)
                      // Spouse summary row (Relation == 'Wife'/'Spouse') -> tab 1 (Spouse)
                      final relation = (m['Relation'] ?? '').toString();
                      final int initialTab = (relation == 'Wife' || relation == 'Spouse') ? 1 : 0;

                      // Open head form in "inline edit" mode for this
                      // household screen: we want to get the updated head
                      // form back via Navigator.pop(result) and update the
                      // existing table, not recreate a new screen.
                      final result = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => AddNewFamilyHeadScreen(
                            isEdit: false,
                            initial: initial,
                            initialTab: initialTab,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _headForm = Map<String, dynamic>.from(result);


                          try {final spRaw = result['spousedetails'];
                            Map<String, dynamic>? spMap;
                            if (spRaw is Map) {
                              spMap = Map<String, dynamic>.from(spRaw);
                            } else if (spRaw is String && spRaw.isNotEmpty) {
                              spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                            }
                            if (spMap != null) {
                              spMap.forEach((key, value) {
                                if (value != null) {
                                  _headForm!['sp_$key'] = value.toString();
                                }
                              });
                            }
                          } catch (_) {}

                          final String name = (result['headName'] ?? '').toString();
                          final bool useDob = (result['useDob'] == true);
                          final String? dobIso = result['dob'] as String?;

                          String age = '';
                          if (useDob && dobIso != null && dobIso.isNotEmpty) {
                            final dob = DateTime.tryParse(dobIso);
                            if (dob != null) {
                              final today = DateTime.now();
                              int years = today.year - dob.year;
                              if (today.month < dob.month ||
                                  (today.month == dob.month && today.day < dob.day)) {
                                years--;
                              }
                              age = years.toString();
                            } else {
                              age = (result['approxAge'] ?? '').toString();
                            }
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

                          // Update head row (Relation == 'Self') without creating new rows
                          final int headIndex = _members.indexWhere((row) => row['Relation'] == 'Self');
                          if (headIndex >= 0) {
                            final Map<String, String> headRow = {
                              '#': _members[headIndex]['#'] ?? '${headIndex + 1}',
                              'Type': 'Adult',
                              'Name': name,
                              'Age': age,
                              'Gender': gender,
                              'Relation': 'Self',
                              'Father': father,
                              'Spouse': spouse,
                              'Total Children': totalChildren,
                            };
                            _members[headIndex] = headRow;
                          }

                          // Update or remove spouse summary row but do not create new rows
                          final String maritalStatus = (result['maritalStatus'] ?? '').toString();
                          final int spouseIndex = _members.indexWhere((row) => row['Relation'] == 'Wife' || row['Relation'] == 'Spouse');

                          if (maritalStatus == 'Married' && spouse.isNotEmpty) {
                            if (spouseIndex >= 0) {
                              final String spouseGender = (gender == 'Male')
                                  ? 'Female'
                                  : (gender == 'Female')
                                      ? 'Male'
                                      : '';
                              final bool spouseUseDob = (result['spouseUseDob'] == true);
                              final String? spouseDobIso = result['spouseDob'] as String?;
                              String spouseAge = '';
                              if (spouseUseDob && spouseDobIso != null && spouseDobIso.isNotEmpty) {
                                final spouseDob = DateTime.tryParse(spouseDobIso);
                                if (spouseDob != null) {
                                  final today = DateTime.now();
                                  int years = today.year - spouseDob.year;
                                  if (today.month < spouseDob.month ||
                                      (today.month == spouseDob.month && today.day < spouseDob.day)) {
                                    years--;
                                  }
                                  spouseAge = years.toString();
                                } else {
                                  spouseAge = (result['spouseApproxAge'] ?? '').toString();
                                }
                              } else {
                                spouseAge = (result['spouseApproxAge'] ?? '').toString();
                              }
                              final Map<String, String> spouseRow = {
                                '#': _members[spouseIndex]['#'] ?? '${spouseIndex + 1}',
                                'Type': 'Adult',
                                'Name': spouse,
                                'Age': spouseAge,
                                'Gender': spouseGender,
                                'Relation': _members[spouseIndex]['Relation'] ?? 'Wife',
                                'Father': '',
                                'Spouse': name,
                                'Total Children': totalChildren,
                              };
                              _members[spouseIndex] = spouseRow;
                            }
                          } else {
                            if (spouseIndex >= 0) {
                              _members.removeAt(spouseIndex);
                              // Do not change totalMembers here; keep count stable during edit
                            }
                          }
                        });
                      }
                    }
                  },
                  cells: [
                    DataCell(Center(child: Text(m['Type'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Name'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Age'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Gender'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Relation'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Father'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(m['Spouse'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                    DataCell(Center(child: Text(totalChildrenText, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }


  Future<bool?> showSuccessDialog(BuildContext context) {
    final memberCount = _members.length;
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


                const SizedBox(height: 8),
                Text(
                      'New house has been added successfully',
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total beneficiary added: $memberCount ',
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
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
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
  }
  Widget _buildTab(String title, int index) {
    final bool isDisabled = !headAdded && index > 0;

    return Tab(
      child: Text(
        title,
        style: TextStyle(
          color: isDisabled
              ? Colors.white.withOpacity(0.4) // 👈 faded color for disabled tabs
              : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

}