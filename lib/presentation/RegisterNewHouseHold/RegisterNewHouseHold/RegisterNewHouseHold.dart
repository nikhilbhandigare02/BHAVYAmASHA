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
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import '../AddNewFamilyMember/AddNewFamilyMember.dart';
import 'bloc/registernewhousehold_bloc.dart';

class RegisterNewHouseHoldScreen extends StatefulWidget {
  final List<Map<String, String>>? initialMembers;
  final bool headAddedInit;
  final bool hideAddMemberButton;
  final bool showSuccessOnSave;
  final bool isEdit;

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
  Future<void> _persistAdultsToSecureStorage() async {
    try {
      final adults = _members
          .where((m) => (m['Type'] ?? '').toString() == 'Adult')
          .map(
            (m) => {
              'Name': (m['Name'] ?? '').toString(),
              'Gender': (m['Gender'] ?? '').toString(),
              'Relation': (m['Relation'] ?? '').toString(),
            },
          )
          .toList();
      await SecureStorageService.saveHouseholdAdultsSummary(adults);
    } catch (_) {}
  }

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
      _members.addAll(
        widget.initialMembers!.map((m) => Map<String, String>.from(m)),
      );
      totalMembers = _members.length;
    }

    // When coming from an edit flow (AllHouseHold or Today's Programme),
    // we receive the original head form including technical keys like
    // hh_unique_key and head_unique_key. Store it so SaveHousehold can
    // detect isEdit and update instead of inserting.
    if (widget.initialHeadForm != null) {
      _headForm = Map<String, dynamic>.from(widget.initialHeadForm!);
      headAdded = true;
      final hhKey = (_headForm?['hh_unique_key'] ?? '').toString();
      if (widget.isEdit && hhKey.isNotEmpty) {
        _hydrateAmenitiesFromDb(hhKey);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _persistAdultsToSecureStorage();
    });
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

  String _extractYearsFromApprox(dynamic approx) {
    if (approx == null) return '';
    final s = approx.toString().trim();
    if (s.isEmpty) return '';

    final match = RegExp(r'\d+').firstMatch(s);
    if (match != null) {
      return match.group(0) ?? '';
    }
    return s;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hhBloc.close();
    super.dispose();
  }

  Future<void> _hydrateAmenitiesFromDb(String hhKey) async {
    try {
      final row = await LocalStorageDao.instance.getHouseholdByUniqueKey(hhKey);
      if (row == null) return;
      final infoRaw = row['household_info'];
      Map<String, dynamic> info;
      if (infoRaw is Map) {
        info = Map<String, dynamic>.from(infoRaw);
      } else if (infoRaw is String && infoRaw.isNotEmpty) {
        try {
          info = Map<String, dynamic>.from(jsonDecode(infoRaw));
        } catch (_) {
          info = <String, dynamic>{};
        }
      } else {
        info = <String, dynamic>{};
      }

      String norm(dynamic v) {
        final s = (v ?? '').toString().trim();
        if (s.isEmpty) return '';
        if (s.toLowerCase() == 'not specified') return '';
        return s;
      }

      String mapValue(String key, dynamic value) {
        if (value == null) return '';
        String s = value.toString().trim();
        if (key == 'cookingFuel' && value is List && value.isNotEmpty) {
          s = value.first.toString().trim();
        }
        if (s.isEmpty) return '';

        final lower = s.toLowerCase();

        switch (key) {
          case 'residentialArea':
            if (lower == 'rural') return 'Rural';
            if (lower == 'urban') return 'Urban';
            if (lower == 'tribal') return 'Tribal';
            if (lower == 'other') return 'Other';
            break;
          case 'houseType':
            if (lower == 'kachcha' || lower == 'kuchcha house')
              return 'Kuchcha house';
            if (lower == 'semi pucca' || lower == 'semi pucca house')
              return 'Semi Pucca house';
            if (lower == 'pucca' || lower == 'pucca house')
              return 'Pucca house';
            if (lower == 'thrust' || lower == 'thrust house')
              return 'Thrust house';
            if (lower == 'none') return 'None';
            if (lower == 'other') return 'other';
            break;
          case 'ownershipType':
            if (lower == 'self') return 'Self';
            if (lower == 'rental') return 'Rental';
            if (lower == 'sharing') return 'Sharing';
            if (lower == 'other') return 'Other';
            break;
          case 'houseKitchen':
            // Logic handled separately for is_kitchen_outside
            if (lower == 'yes') return 'Yes';
            if (lower == 'no') return 'No';
            break;
          case 'cookingFuel':
            if (lower == 'lpg') return 'LPG';
            if (lower == 'firewood') return 'Firewood';
            if (lower == 'coal') return 'Coal';
            if (lower == 'kerosene') return 'Kerosene';
            if (lower == 'crop residue') return 'Crop Residue';
            if (lower == 'drug cake') return 'Drug Cake';
            if (lower == 'other') return 'Other';
            break;
          case 'waterSource':
            if (lower == 'supply water' || lower == 'supply_water')
              return 'Supply Water';
            if (lower == 'r.o' || lower == 'ro') return 'R.O';
            if (lower == 'hand pump within house' ||
                lower == 'handpump_within_house')
              return 'Hand pump within house';
            if (lower == 'hand pump outside of house' ||
                lower == 'handpump_outside_of_house')
              return 'Hand pump outside of house';
            if (lower == 'tanker') return 'Tanker';
            if (lower == 'river') return 'River';
            if (lower == 'pond') return 'Pond';
            if (lower == 'lake') return 'Lake';
            if (lower == 'well') return 'Well';
            if (lower == 'other') return 'Other';
            break;
          case 'electricity':
            if (lower == 'electricity supply' || lower == 'electricity_supply')
              return 'Electricity Supply';
            if (lower == 'generator') return 'Generator';
            if (lower == 'solar power' || lower == 'solar_power')
              return 'Solar Power';
            if (lower == 'kerosene lamp' || lower == 'kerosene_lamp')
              return 'Kerosene Lamp';
            if (lower == 'other') return 'Other';
            break;
          case 'toilet':
            if (lower == 'yes') return 'Yes';
            if (lower == 'no') return 'No';
            break;
          case 'toiletType':
            if (lower == 'flush toilet with running water')
              return 'Flush toilet with running water';
            if (lower == 'flush toilet without water')
              return 'Flush Toilet Without Water';
            if (lower == 'pit toilet with running water')
              return 'Pit toilet with running water';
            if (lower == 'pit toilet without water supply')
              return 'Pit toilet without water supply';
            if (lower == 'other') return 'Other';
            break;
          case 'toiletPlace':
            if (lower == 'community toilet') return 'Community toilet';
            if (lower == 'friend/relative toilet')
              return 'Friend/Relative toilet';
            if (lower == 'open space') return 'Open space';
            break;
        }
        return s;
      }

      // Check for nested structure and flatten/map it if present
      if (info.containsKey('household_details') ||
          info.containsKey('household_amenities')) {
        final details =
            info['household_details'] as Map<String, dynamic>? ?? {};
        final amenities =
            info['household_amenities'] as Map<String, dynamic>? ?? {};

        info['residentialArea'] = mapValue(
          'residentialArea',
          details['type_of_residential_area'],
        );
        info['otherResidentialArea'] =
            details['other_type_of_residential_area'];
        info['houseType'] = mapValue('houseType', details['type_of_house']);
        info['otherHouseType'] = details['other_type_of_house'];
        info['ownershipType'] = mapValue(
          'ownershipType',
          details['house_ownership'],
        );
        info['otherOwnershipType'] = details['other_house_ownership'];

        // Special logic for kitchen: is_kitchen_outside=yes -> Kitchen Inside=No
        String kOut = (amenities['is_kitchen_outside'] ?? '')
            .toString()
            .toLowerCase();
        if (kOut == 'yes') {
          info['houseKitchen'] = 'No';
        } else if (kOut == 'no') {
          info['houseKitchen'] = 'Yes';
        } else {
          info['houseKitchen'] = '';
        }

       /* info['cookingFuel'] = mapValue(
          'cookingFuel',
          amenities['type_of_fuel_used_for_cooking'],
        );*/
        info['cookingFuel'] = mapValue(
          'cookingFuel',
          (amenities['type_of_fuel_used_for_cooking'] as List).join(', '),
        );
        info['otherCookingFuel'] =
            amenities['other_type_of_fuel_used_for_cooking'];
        info['waterSource'] = mapValue(
          'waterSource',
          amenities['primary_source_of_water'],
        );
        info['otherWaterSource'] = amenities['other_primary_source_of_water'];
        info['electricity'] = mapValue(
          'electricity',
          amenities['availability_of_electricity'],
        );
        info['otherElectricity'] =
            amenities['other_availability_of_electricity'];
        info['toilet'] = mapValue(
          'toilet',
          amenities['availability_of_toilet'],
        );
        info['toiletType'] = mapValue(
          'toiletType',
          amenities['type_of_toilet'],
        );
        info['typeOfToilet'] =
            amenities['other_type_of_toilet']; // Maps to "Other" type
        info['toiletPlace'] = mapValue(
          'toiletPlace',
          amenities['where_do_you_go_for_toilet'],
        );
      }

      final residentialArea = norm(info['residentialArea']);
      final residentialAreaOther = norm(info['otherResidentialArea']);
      if (residentialAreaOther.isNotEmpty) {
        _hhBloc.add(ResidentialAreaChange(residentialArea: 'Other'));
        _hhBloc.add(
          ResidentialAreaOtherChange(
            otherResidentialArea: residentialAreaOther,
          ),
        );
      } else if (residentialArea.isNotEmpty) {
        _hhBloc.add(ResidentialAreaChange(residentialArea: residentialArea));
      }

      final houseType = norm(info['houseType']);
      final houseTypeOther = norm(info['otherHouseType']);
      if (houseTypeOther.isNotEmpty) {
        _hhBloc.add(HouseTypeChange(houseType: 'other'));
        _hhBloc.add(HouseTypeOtherChange(otherHouseType: houseTypeOther));
      } else if (houseType.isNotEmpty) {
        _hhBloc.add(HouseTypeChange(houseType: houseType));
      }

      final ownershipType = norm(info['ownershipType']);
      final ownershipTypeOther = norm(info['otherOwnershipType']);
      if (ownershipTypeOther.isNotEmpty) {
        _hhBloc.add(OwnershipTypeChange(ownershipType: 'Other'));
        _hhBloc.add(
          OwnershipTypeOtherChange(otherOwnershipType: ownershipTypeOther),
        );
      } else if (ownershipType.isNotEmpty) {
        _hhBloc.add(OwnershipTypeChange(ownershipType: ownershipType));
      }

      final houseKitchen = norm(info['houseKitchen']);
      if (houseKitchen.isNotEmpty) {
        _hhBloc.add(KitchenChange(houseKitchen: houseKitchen));
      }

      var cookingFuel = norm(info['cookingFuel']);
      final cookingFuelOther = norm(info['otherCookingFuel']);
      if (cookingFuelOther.isNotEmpty && !cookingFuel.contains('Other')) {
        cookingFuel = cookingFuel.isNotEmpty
            ? ("$cookingFuel, Other")
            : 'Other';
      }
      if (cookingFuel.isNotEmpty) {
        _hhBloc.add(CookingFuelTypeChange(cookingFuel: cookingFuel));
      }
      if (cookingFuelOther.isNotEmpty) {
        _hhBloc.add(CookingFuelOtherChange(otherCookingFuel: cookingFuelOther));
      }

      final waterSource = norm(info['waterSource']);
      final waterSourceOther = norm(info['otherWaterSource']);
      if (waterSourceOther.isNotEmpty) {
        _hhBloc.add(WaterSourceChange(waterSource: 'Other'));
        _hhBloc.add(WaterSourceOtherChange(otherWaterSource: waterSourceOther));
      } else if (waterSource.isNotEmpty) {
        _hhBloc.add(WaterSourceChange(waterSource: waterSource));
      }

      final electricity = norm(info['electricity']);
      final electricityOther = norm(info['otherElectricity']);
      if (electricityOther.isNotEmpty) {
        _hhBloc.add(ElectricityChange(electricity: 'Other'));
        _hhBloc.add(ElectricityOtherChange(otherElectricity: electricityOther));
      } else if (electricity.isNotEmpty) {
        _hhBloc.add(ElectricityChange(electricity: electricity));
      }

      final toilet = norm(info['toilet']);
      if (toilet.isNotEmpty) {
        _hhBloc.add(ToiletChange(toilet: toilet));
      }

      final toiletType = norm(info['toiletType']);
      final toiletTypeOther = norm(info['typeOfToilet']);
      if (toiletTypeOther.isNotEmpty) {
        _hhBloc.add(ToiletTypeChange(toiletType: 'Other'));
        _hhBloc.add(TypeOfToilet(TypeToilet: toiletTypeOther));
      } else if (toiletType.isNotEmpty) {
        _hhBloc.add(ToiletTypeChange(toiletType: toiletType));
      }

      final toiletPlace = norm(info['toiletPlace']);
      if (toiletPlace.isNotEmpty) {
        _hhBloc.add(ToiletPlaceChange(toiletPlace: toiletPlace));
      }
    } catch (_) {}
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
            message:
                l10n?.confirmBackLoseDetailsMsg ??
                'If you go back, details will be lost. Do you want to go back?',
            yesText: l10n?.yes ?? '',
            noText: l10n?.confirmNo ?? 'No',
          );
          return shouldExit ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppHeader(
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
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                    _buildTab(
                      l10n?.rnhTabHouseholdDetails ?? 'HOUSEHOLD DETAILS',
                      1,
                    ),
                    _buildTab(
                      l10n?.rnhTabHouseholdAmenities ?? 'HOUSEHOLD AMENITIES',
                      2,
                    ),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  spreadRadius: 2,
                  offset: const Offset(0, 0), // TOP shadow
                ),
              ],
            ),
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
                    height:
                        MediaQuery.of(context).size.width >
                            MediaQuery.of(context).size.height
                        ? 9.h
                        : 5.h,
                    width:
                        MediaQuery.of(context).size.width >
                            MediaQuery.of(context).size.height
                        ? 20.w
                        : 12.h,
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

                        final householdBloc = context
                            .read<RegisterNewHouseholdBloc>();

                        return BlocConsumer<
                          RegisterNewHouseholdBloc,
                          RegisterHouseholdState
                        >(
                          listener: (context, state) {
                            if (state.isSaved) {
                              _skipExitConfirm = true;
                              if (widget.showSuccessOnSave) {
                                showSuccessDialog(context).then((
                                  shouldNavigate,
                                ) {
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
                                  backgroundColor: Colors.black,
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
                                        l10n?.please_add_family_head_details ??
                                            'Please add family head details',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.black,
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
                                    print(
                                      ' Current Amenities State: ${amenitiesState.toString()}',
                                    );

                                    // Create a map with all the amenities data
                                    final amenitiesData = {
                                      'residentialArea':
                                          amenitiesState.residentialArea,
                                      'otherResidentialArea':
                                          amenitiesState.otherResidentialArea,
                                      'ownershipType':
                                          amenitiesState.ownershipType,
                                      'otherOwnershipType':
                                          amenitiesState.otherOwnershipType,
                                      'houseType': amenitiesState.houseType,
                                      'otherHouseType':
                                          amenitiesState.otherHouseType,
                                      'houseKitchen':
                                          amenitiesState.houseKitchen,
                                      'cookingFuel': amenitiesState.cookingFuel,
                                      'otherCookingFuel':
                                          amenitiesState.otherCookingFuel,
                                      'waterSource': amenitiesState.waterSource,
                                      'otherWaterSource':
                                          amenitiesState.otherWaterSource,
                                      'electricity': amenitiesState.electricity,
                                      'otherElectricity':
                                          amenitiesState.otherElectricity,
                                      'toilet': amenitiesState.toilet,
                                      'toiletType': amenitiesState.toiletType,
                                      'typeOfToilet':
                                          amenitiesState.typeOfToilet,
                                      'toiletPlace': amenitiesState.toiletPlace,
                                    };

                                    amenitiesData.removeWhere(
                                      (key, value) =>
                                          value == null ||
                                          (value is String && value.isEmpty) ||
                                          value == '',
                                    );

                                    print(
                                      '📤 Prepared Amenities Data: $amenitiesData',
                                    );

                                    if (amenitiesData.isEmpty) {
                                      print(
                                        '⚠️ Warning: No amenities data to save',
                                      );
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
        ),
      ),
    );
  }

  Future<void> _openAddHead() async {
    try {
      // Convert Map<String, dynamic>? to Map<String, String>? 
      Map<String, String>? initialData;
      if (_headForm != null) {
        initialData = <String, String>{};
        _headForm!.forEach((key, value) {
          if (value != null) {
            initialData![key] = value.toString();
          }
        });
        
        // Ensure critical fields are preserved even if missing
        if (!initialData.containsKey('houseNo') && _headForm!.containsKey('house_no')) {
          initialData!['houseNo'] = _headForm!['house_no'].toString();
        }
        if (!initialData.containsKey('dob') && _headForm!.containsKey('date_of_birth')) {
          initialData!['dob'] = _headForm!['date_of_birth'].toString();
        }
        
        debugPrint('RegisterNewHouseHold: initialData keys: ${initialData?.keys.toList()}');
        debugPrint('RegisterNewHouseHold: houseNo in initialData: ${initialData?['houseNo']}');
        debugPrint('RegisterNewHouseHold: dob in initialData: ${initialData?['dob']}');
      }
      
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (_) => AddNewFamilyHeadScreen(
          initial: initialData,
        )),
      );

      if (result != null) {
        setState(() {
          _headForm = Map<String, dynamic>.from(result);
          headAdded = true;
          _members.clear();
          _memberForms.clear();

          final String name = (result['headName'] ?? result['name'] ?? '')
              .toString();

          final String gender = (result['gender'] ?? '').toString();
          final String spouse = (result['spouseName'] ?? '').toString();

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

          totalMembers = 1; // Start with 1 for the head

          final bool useDob = (result['useDob'] == true);
          final String? dobIso = result['dob'] as String?;
          String age = '';
          if (useDob && dobIso != null && dobIso.isNotEmpty) {
            final dob = DateTime.tryParse(dobIso);
            age = dob != null
                ? (DateTime.now().year - dob.year).toString()
                : _extractYearsFromApprox(result['approxAge']);
          } else {
            age = _extractYearsFromApprox(result['approxAge']);
          }
          final String father = (result['father_name'] ?? '').toString();
          final String totalChildren =
              (result['children'] != null &&
                  result['children'].toString().isNotEmpty)
              ? (int.tryParse(result['children'].toString()) ?? 0) > 0
                    ? result['children'].toString()
                    : '0'
              : '0';

          _members.add({
            '#': '1',
            'Type': 'Adult',
            'Name': name, // This is coming from result['name']
            'Age': age,
            'Gender': gender,
            'Relation': 'Self',
            'Father': father,
            'Spouse': spouse,
            'Total Children': totalChildren,
          });

          // Add spouse row if married and spouse details exist
          final String maritalStatus = (result['maritalStatus'] ?? '')
              .toString();
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
            if (spouseUseDob &&
                spouseDobIso != null &&
                spouseDobIso.isNotEmpty) {
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
                spouseAge = _extractYearsFromApprox(result['spouseApproxAge']);
              }
            } else {
              spouseAge = _extractYearsFromApprox(result['spouseApproxAge']);
            }
            _members.add({
              '#': '${_members.length + 1}',
              'Type': 'Adult',
              'Name': spouse,
              'Age': spouseAge,
              'Gender': spouseGender,
              'Relation': 'Wife',
              'Father': (_headForm?['sp_father_name'] ?? '').toString(),
              'Spouse': name,
              'Total Children': totalChildren,
            });
            // Increment totalMembers for spouse
            totalMembers++;
          }
        });
        await _persistAdultsToSecureStorage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openAddMember() async {
    try {
      // Use empty values instead of checking database
      final uniqueKey = _headForm?['hh_unique_key']?.toString() ?? '';

      Map<String, String> head = {
        'Name': _headForm?['name']?.toString() ?? '',
        'Gender': _headForm?['gender']?.toString() ?? '',
      };

      Map<String, String> spouse = {'Name': '', 'Gender': ''};

      // Try to find spouse info if available
      try {
        final spouseMember = _members.firstWhere(
          (m) =>
              (m['Relation'] ?? '').toString().toLowerCase() == 'spouse' ||
              (m['Relation'] ?? '').toString().toLowerCase() == 'wife',
        );
        spouse = Map<String, String>.from(spouseMember);
      } catch (_) {}

      String? spouseMobileNumber;
      try {
        final spRaw = _headForm?['spousedetails'];
        Map<String, dynamic>? spMap;

        if (spRaw is Map) {
          spMap = Map<String, dynamic>.from(spRaw);
        } else if (spRaw is String && spRaw.isNotEmpty) {
          spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
        }

        if (spMap != null) {
          // Try to get mobile number from different possible keys
          spouseMobileNumber =
              spMap['mobileNo']?.toString() ??
              spMap['mobile']?.toString() ??
              spMap['phoneNumber']?.toString();

          // Also update _headForm with all spouse details
          spMap.forEach((key, value) {
            if (value != null) {
              _headForm!['sp_$key'] = value.toString();
            }
          });
        }
      } catch (e) {
        print('Error parsing spouse details: $e');
      }

      Map<String, dynamic> initial = {};
      final String? headReligion = _headForm?['religion']?.toString();
      final String? headOtherReligion = _headForm?['otherReligion']?.toString();
      final String? headCategory = _headForm?['category']?.toString();
      final String? headOtherCategory = _headForm?['otherCategory']?.toString();
      String _mapCategoryToMember(String? c) {
        switch ((c ?? '').trim()) {
          case 'Not Disclosed':
            return 'NotDisclosed';
          case 'Do not Know':
            return 'DontKnow';
          case 'Pichda Varg 1':
            return 'PichdaVarg1';
          case 'Pichda Varg 2':
            return 'PichdaVarg2';
          case 'Atyant Pichda Varg':
            return 'AtyantPichdaVarg';
          default:
            return (c ?? '').trim();
        }
      }
      if (headReligion != null && headReligion.isNotEmpty) {
        initial['religion'] = headReligion;
      }
      if (headOtherReligion != null && headOtherReligion.isNotEmpty) {
        initial['otherReligion'] = headOtherReligion;
      }
      if (headCategory != null && headCategory.isNotEmpty) {
        initial['category'] = _mapCategoryToMember(headCategory);
      }
      if (headCategory == 'Other' &&
          headOtherCategory != null &&
          headOtherCategory.isNotEmpty) {
        initial['otherCategory'] = headOtherCategory;
      }

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => AddNewFamilyMemberScreen(
            hhId: uniqueKey,
            headName: head['Name'] ?? '',
            headGender: head['Gender'] ?? '',
            isAddMember: true,
            headMobileNumber: _headForm?['mobileNo']
                ?.toString(), // Add this line
            headSpouseMobile: spouseMobileNumber, // Add this line
            spouseName: spouse['Name'] ?? '',
            spouseGender: spouse['Gender'] ?? '',
            inlineEdit: true,
            initial: initial.isEmpty ? null : initial,
          ),
        ),
      );
      if (result != null) {
        print(
          '📥 [RegisterNewHouseHold] Received result from AddNewFamilyMember: ${result.keys}',
        );
        print('🔑 [RegisterNewHouseHold] All result keys and values:');
        result.forEach((key, value) {
          print('  $key: $value');
        });
        if (result['spousedetails'] != null) {
          print(
            '👫 [RegisterNewHouseHold] Spousedetails received: ${result['spousedetails']}',
          );
        } else {
          print('❌ [RegisterNewHouseHold] No spousedetails found in result');
        }
        setState(() {
          _memberForms.add(Map<String, dynamic>.from(result));
          final int formIndex = _memberForms.length - 1;
          // Only increment total members if it's a new member (not head or spouse)
          // The count will be decreased when adding a new member with a relation to head
          if (result['relation'] != 'Self' && result['relation'] != 'Spouse') {
            totalMembers++;
          }
          final String type = (result['memberType'] ?? 'Adult').toString();
          final String name = (result['name'] ?? '').toString();
          final bool useDob = (result['useDob'] == true);
          final String? dobIso = result['dob'] as String?;
          String age = '';
          if (useDob && dobIso != null && dobIso.isNotEmpty) {
            final dob = DateTime.tryParse(dobIso);
            age = dob != null
                ? (DateTime.now().year - dob.year).toString()
                : _extractYearsFromApprox(result['approxAge']);
          } else {
            age = _extractYearsFromApprox(result['approxAge']);
          }
          final String gender = (result['gender'] ?? '').toString();
          final String relation = (result['relation'] ?? '').toString();
          final String father = (result['father_name'] ?? '').toString();
          final String spouse = (result['spouseName'] ?? '').toString();
          final String totalChildren =
              (result['children'] != null &&
                  result['children'].toString().isNotEmpty)
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
          final String maritalStatus = (result['maritalStatus'] ?? '')
              .toString();
          if (maritalStatus == 'Married' && spouse.isNotEmpty) {
            final String spouseGender = (gender == 'Male')
                ? 'Female'
                : (gender == 'Female')
                ? 'Male'
                : '';
            String spouseAge =
                ''; // Start with empty - will be filled from spousedetails
            print(
              '🔍 [RegisterNewHouseHold] Processing spouse: $spouse, marital status: $maritalStatus',
            );
            String spouseFather = '';
            try {
              final spRaw = result['spousedetails'];
              print('🔍 [RegisterNewHouseHold] Raw spousedetails data: $spRaw');
              Map<String, dynamic>? spMap;
              if (spRaw is Map) {
                spMap = Map<String, dynamic>.from(spRaw);
                print(
                  '✅ [RegisterNewHouseHold] Spousedetails is a Map with keys: ${spMap.keys}',
                );
              } else if (spRaw is String && spRaw.isNotEmpty) {
                spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                print(
                  '✅ [RegisterNewHouseHold] Spousedetails parsed from String with keys: ${spMap.keys}',
                );
              } else {
                print(
                  '❌ [RegisterNewHouseHold] Spousedetails is null or empty: $spRaw',
                );
              }
              if (spMap != null) {
                spouseFather = (spMap['father_name'] ?? '').toString();

                // Extract spouse age from spousedetails - always extract since we start with empty
                // First try to get the pre-calculated age
                final String? preCalculatedAge = spMap['age']?.toString();
                print(
                  '🔍 [RegisterNewHouseHold] Pre-calculated spouse age: $preCalculatedAge',
                );
                if (preCalculatedAge != null && preCalculatedAge.isNotEmpty) {
                  spouseAge = preCalculatedAge;
                  print(
                    '✅ [RegisterNewHouseHold] Using pre-calculated spouse age: $spouseAge',
                  );
                } else {
                  final bool spouseUseDobFromDetails =
                      (spMap['useDob'] == true);
                  final String? spouseDobFromDetails = spMap['dob'] as String?;
                  print(
                    '📅 [RegisterNewHouseHold] Spouse DOB details - useDob: $spouseUseDobFromDetails, dob: $spouseDobFromDetails',
                  );
                  if (spouseUseDobFromDetails &&
                      spouseDobFromDetails != null &&
                      spouseDobFromDetails.isNotEmpty) {
                    final spouseDob = DateTime.tryParse(spouseDobFromDetails);
                    if (spouseDob != null) {
                      final today = DateTime.now();
                      int years = today.year - spouseDob.year;
                      if (today.month < spouseDob.month ||
                          (today.month == spouseDob.month &&
                              today.day < spouseDob.day)) {
                        years--;
                      }
                      spouseAge = years.toString();
                      print(
                        '🎂 [RegisterNewHouseHold] Calculated spouse age from DOB: $spouseAge',
                      );
                    } else {
                      spouseAge = _extractYearsFromApprox(spMap['approxAge']);
                      print(
                        '📝 [RegisterNewHouseHold] Using approximate age (DOB parse failed): $spouseAge',
                      );
                    }
                  } else {
                    spouseAge = _extractYearsFromApprox(spMap['approxAge']);
                    print(
                      '📝 [RegisterNewHouseHold] Using approximate age (no DOB): $spouseAge',
                    );
                  }
                }
              }
            } catch (_) {}
            _members.add({
              '#': '${_members.length + 1}',
              'Type': 'Adult',
              'Name': spouse,
              'Age': spouseAge,
              'Gender': spouseGender,
              'Relation': 'Spouse',
              'Father': spouseFather,
              'Spouse': name,
              'Total Children': totalChildren,
              'formIndex': formIndex.toString(),
              // Mark this as the auto-generated spouse summary row.
              'isSpouseRow': '1',
            });
            print(
              '💾 [RegisterNewHouseHold] Added spouse member with age: "$spouseAge" - Full data: ${_members.last}',
            );
            totalMembers = totalMembers + 1;
          }
        });
        await _persistAdultsToSecureStorage();
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Builder(
          builder: (_) {
            final int headChildren =
                int.tryParse((_headForm?['children'] ?? '').toString()) ?? 0;

            int memberChildren = 0;
            for (final form in _memberForms) {
              final dynamic rawChildren = form['children'];
              final int val = int.tryParse(rawChildren?.toString() ?? '') ?? 0;
              if (val > 0) {
                memberChildren += val;
              }
            }

            final int childrenTarget = headChildren + memberChildren;

            final Set<String> memberNames = _members
                .map((m) => (m['Name'] ?? '').toString().trim().toLowerCase())
                .where((n) => n.isNotEmpty)
                .toSet();

            final int childFatherMatchesCount = _members.where((m) {
              final t = (m['Type'] ?? '').toString().toLowerCase();
              if (t != 'child') return false;
              final fatherName = (m['Father'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (fatherName.isEmpty) return false;
              return memberNames.contains(fatherName);
            }).length;

            final int adultFatherMatchesCount = _members.where((m) {
              final t = (m['Type'] ?? '').toString().toLowerCase();
              if (t != 'adult') return false;
              final relation = (m['Relation'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (relation == 'son' ||
                  relation == 'daughter' ||
                  relation == 'grand son' ||
                  relation == 'grand daughter') {
                return false;
              }
              final fatherName = (m['Father'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (fatherName.isEmpty) return false;
              return memberNames.contains(fatherName);
            }).length;

            final int childrenAdded =
                childFatherMatchesCount + adultFatherMatchesCount;

            final int remaining = (childrenTarget - childrenAdded).clamp(
              0,
              9999,
            );
            if (childrenTarget <= 0) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${l10n!.memberRemainsToAdd} :",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                      fontSize: 17.sp,
                    ),
                  ),
                  Text(
                    '$remaining ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17.sp,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (headAdded) _buildMembersCards(context),
        if (headAdded) SizedBox(height: 2.h),
        if (!_hideAddMemberButton)
          Center(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.width >
                      MediaQuery.of(context).size.height
                  ? 9.h
                  : 5.h,
              width:
                  MediaQuery.of(context).size.width >
                      MediaQuery.of(context).size.height
                  ? 40.w
                  : 25.h,
              child: RoundButton(
                title: headAdded
                    ? (l10n?.addNewMemberButton ?? 'ADD NEW MEMBER')
                    : (l10n?.addFamilyHeadButton ?? 'ADD FAMILY HEAD'),
                icon: Icons.add_circle_outline,
                color: AppColors.green,
                borderRadius: 8,
                height:
                    MediaQuery.of(context).size.width >
                        MediaQuery.of(context).size.height
                    ? 7.h
                    : 5.h,
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

  Widget _buildMembersCards(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (final m in _members) ...[
          _memberCard(context, m, l10n),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _memberCard(
    BuildContext context,
    Map<String, String> m,
    AppLocalizations? l10n,
  ) {
    final Color primary = Theme.of(context).primaryColor;
    final String ageGender = '${m['Age'] ?? ''} | ${m['Gender'] ?? ''}';

    // Debug logging for spouse cards
    if (m['Relation'] == 'Spouse' || m['Relation'] == 'Wife') {
      print(
        '🎴 [RegisterNewHouseHold] Displaying spouse card - Name: ${m['Name']}, Age: "${m['Age']}", Gender: ${m['Gender']}, Relation: ${m['Relation']}',
      );
    }

    final String totalChildrenText = (m['Total Children'] ?? '').isNotEmpty
        ? (m['Total Children'] ?? '')!
        : '0';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final formIndexStr = m['formIndex'];
            if (formIndexStr != null && formIndexStr.toString().isNotEmpty) {
              final idx = int.tryParse(formIndexStr.toString());
              if (idx == null || idx < 0 || idx >= _memberForms.length) {
                return;
              }
              final initialMember = Map<String, dynamic>.from(
                _memberForms[idx],
              );
              final isSpouseRow = (m['isSpouseRow'] ?? '0').toString() == '1';
              final int initialStep = isSpouseRow ? 1 : 0;

              // Ensure marital status is set to 'Married' when opening spouse cards
              // so that the spouse tab becomes accessible
              if (isSpouseRow) {
                initialMember['maritalStatus'] = 'Married';

                // Extract spouse data from spousedetails and merge with initial data
                try {
                  final spRaw = _memberForms[idx]['spousedetails'];
                  Map<String, dynamic>? spMap;
                  if (spRaw is Map) {
                    spMap = Map<String, dynamic>.from(spRaw);
                  } else if (spRaw is String && spRaw.isNotEmpty) {
                    spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                  }

                  if (spMap != null) {
                    print(
                      '🔍 [RegisterNewHouseHold] EDIT - Spouse data keys before merge: ${spMap.keys}',
                    );
                    print(
                      '📅 [RegisterNewHouseHold] EDIT - LMP data in spousedetails: ${spMap['lmp']}',
                    );
                    print(
                      '🤰 [RegisterNewHouseHold] EDIT - Pregnancy data in spousedetails: ${spMap['isPregnant']}',
                    );

                    // Merge spouse details into initial member data for prefilling
                    spMap.forEach((key, value) {
                      if (value != null && value.toString().isNotEmpty) {
                        initialMember[key] = value.toString();
                        if (key == 'lmp' || key == 'edd' || key == 'dob') {
                          print(
                            '📅 [RegisterNewHouseHold] EDIT - Merging date field $key: $value',
                          );
                        }
                      }
                    });

                    print(
                      '🔑 [RegisterNewHouseHold] EDIT - Initial member keys after merge: ${initialMember.keys}',
                    );
                    print(
                      '📅 [RegisterNewHouseHold] EDIT - LMP in initialMember after merge: ${initialMember['lmp']}',
                    );

                    // Ensure pregnancy field is properly handled
                    final spPregnant = spMap['isPregnant'];
                    if (spPregnant != null &&
                        spPregnant.toString().isNotEmpty) {
                      initialMember['isPregnant'] = spPregnant.toString();
                      print(
                        '🤰 [RegisterNewHouseHold] EDIT - Set pregnancy field: $spPregnant',
                      );
                    }
                  } else {
                    print(
                      '❌ [RegisterNewHouseHold] EDIT - Spouse data map is null',
                    );
                  }
                } catch (_) {}
              }

              print(
                '🚀 [RegisterNewHouseHold] EDIT - Navigating to AddNewFamilyMember with initial data:',
              );
              print(
                '🔑 [RegisterNewHouseHold] EDIT - Initial member keys: ${initialMember.keys}',
              );
              print(
                '📅 [RegisterNewHouseHold] EDIT - LMP in initial data: ${initialMember['lmp']}',
              );
              print(
                '🤰 [RegisterNewHouseHold] EDIT - Pregnancy in initial data: ${initialMember['isPregnant']}',
              );
              print(
                '👶 [RegisterNewHouseHold] EDIT - Initial step: $initialStep (spouse row: $isSpouseRow)',
              );

              final result = await Navigator.of(context)
                  .push<Map<String, dynamic>>(
                    MaterialPageRoute(
                      builder: (_) => AddNewFamilyMemberScreen(
                        hhId: _headForm?['hh_unique_key']?.toString(),
                        headName: _headForm?['headName']?.toString(),
                        headGender: _headForm?['gender']?.toString(),
                        isAddMember: true,
                        headMobileNumber: _headForm?['mobileNo']
                            ?.toString(), // Add this line
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
                print(
                  '🔄 [RegisterNewHouseHold] EDIT - Received result from AddNewFamilyMember: ${result.keys}',
                );
                print(
                  '🔑 [RegisterNewHouseHold] EDIT - All result keys and values:',
                );
                result.forEach((key, value) {
                  print('  $key: $value');
                });
                if (result['spousedetails'] != null) {
                  print(
                    '👫 [RegisterNewHouseHold] EDIT - Spousedetails received: ${result['spousedetails']}',
                  );
                } else {
                  print(
                    '❌ [RegisterNewHouseHold] EDIT - No spousedetails found in result',
                  );
                }
                setState(() {
                  _memberForms[idx] = Map<String, dynamic>.from(result);
                  final String type = (result['memberType'] ?? 'Adult')
                      .toString();
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
                  final String father = (result['father_name'] ?? '').toString();
                  final String spouse = (result['spouseName'] ?? '').toString();
                  final String totalChildren =
                      (result['children'] != null &&
                          result['children'].toString().isNotEmpty)
                      ? (int.tryParse(result['children'].toString()) ?? 0) > 0
                            ? result['children'].toString()
                            : '0'
                      : '0';
                  final String maritalStatus = (result['maritalStatus'] ?? '')
                      .toString();
                  final String formIndexKey = formIndexStr.toString();
                  final int primaryIndex = _members.indexWhere(
                    (row) =>
                        (row['formIndex'] ?? '') == formIndexKey &&
                        (row['isSpouseRow'] ?? '0') == '0',
                  );
                  final int spouseIndex = _members.indexWhere(
                    (row) =>
                        (row['formIndex'] ?? '') == formIndexKey &&
                        (row['isSpouseRow'] ?? '0') == '1',
                  );
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
                  if (maritalStatus == 'Married' && spouse.isNotEmpty) {
                    final String spouseGender = (gender == 'Male')
                        ? 'Female'
                        : (gender == 'Female')
                        ? 'Male'
                        : '';
                    String spouseAge =
                        ''; // Start with empty - will be filled from spousedetails
                    print(
                      '🔄 [RegisterNewHouseHold] EDIT - Processing spouse update: $spouse, marital status: $maritalStatus',
                    );

                    // Extract spouse age from spousedetails - same logic as add flow
                    try {
                      final spRaw = result['spousedetails'];
                      print(
                        '🔍 [RegisterNewHouseHold] EDIT - Raw spousedetails data: $spRaw',
                      );
                      Map<String, dynamic>? spMap;
                      if (spRaw is Map) {
                        spMap = Map<String, dynamic>.from(spRaw);
                        print(
                          '✅ [RegisterNewHouseHold] EDIT - Spousedetails is a Map with keys: ${spMap.keys}',
                        );
                      } else if (spRaw is String && spRaw.isNotEmpty) {
                        spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                        print(
                          '✅ [RegisterNewHouseHold] EDIT - Spousedetails parsed from String with keys: ${spMap.keys}',
                        );
                      } else {
                        print(
                          '❌ [RegisterNewHouseHold] EDIT - Spousedetails is null or empty: $spRaw',
                        );
                      }
                      if (spMap != null) {
                        // First try to get the pre-calculated age
                        final String? preCalculatedAge = spMap['age']
                            ?.toString();
                        print(
                          '🔍 [RegisterNewHouseHold] EDIT - Pre-calculated spouse age: $preCalculatedAge',
                        );
                        if (preCalculatedAge != null &&
                            preCalculatedAge.isNotEmpty) {
                          spouseAge = preCalculatedAge;
                          print(
                            '✅ [RegisterNewHouseHold] EDIT - Using pre-calculated spouse age: $spouseAge',
                          );
                        } else {
                          final bool spouseUseDobFromDetails =
                              (spMap['useDob'] == true);
                          final String? spouseDobFromDetails =
                              spMap['dob'] as String?;
                          print(
                            '📅 [RegisterNewHouseHold] EDIT - Spouse DOB details - useDob: $spouseUseDobFromDetails, dob: $spouseDobFromDetails',
                          );
                          if (spouseUseDobFromDetails &&
                              spouseDobFromDetails != null &&
                              spouseDobFromDetails.isNotEmpty) {
                            final spouseDob = DateTime.tryParse(
                              spouseDobFromDetails,
                            );
                            if (spouseDob != null) {
                              final today = DateTime.now();
                              int years = today.year - spouseDob.year;
                              if (today.month < spouseDob.month ||
                                  (today.month == spouseDob.month &&
                                      today.day < spouseDob.day)) {
                                years--;
                              }
                              spouseAge = years.toString();
                              print(
                                '🎂 [RegisterNewHouseHold] EDIT - Calculated spouse age from DOB: $spouseAge',
                              );
                            } else {
                              spouseAge = _extractYearsFromApprox(
                                spMap['approxAge'],
                              );
                              print(
                                '📝 [RegisterNewHouseHold] EDIT - Using approximate age (DOB parse failed): $spouseAge',
                              );
                            }
                          } else {
                            spouseAge = _extractYearsFromApprox(
                              spMap['approxAge'],
                            );
                            print(
                              '📝 [RegisterNewHouseHold] EDIT - Using approximate age (no DOB): $spouseAge',
                            );
                          }
                        }
                      }
                    } catch (_) {}
                    if (spouseIndex != -1) {
                      final spouseRow = _members[spouseIndex];
                      spouseRow['Type'] = 'Adult';
                      spouseRow['Name'] = spouse;
                      spouseRow['Age'] = spouseAge;
                      spouseRow['Gender'] = spouseGender;
                      spouseRow['Relation'] = 'Spouse';
                      // Extract father name from spouse details
                      String spouseFather = '';
                      try {
                        final spRaw = result['spousedetails'];
                        Map<String, dynamic>? spMap;
                        if (spRaw is Map) {
                          spMap = Map<String, dynamic>.from(spRaw);
                        } else if (spRaw is String && spRaw.isNotEmpty) {
                          spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                        }
                        if (spMap != null) {
                          spouseFather = (spMap['father_name'] ?? '').toString();

                          // Extract spouse age from spousedetails - this should take precedence
                          // First try to get the pre-calculated age
                          final String? preCalculatedAge = spMap['age']
                              ?.toString();
                          if (preCalculatedAge != null &&
                              preCalculatedAge.isNotEmpty) {
                            spouseAge = preCalculatedAge;
                          } else {
                            final bool spouseUseDobFromDetails =
                                (spMap['useDob'] == true);
                            final String? spouseDobFromDetails =
                                spMap['dob'] as String?;
                            if (spouseUseDobFromDetails &&
                                spouseDobFromDetails != null &&
                                spouseDobFromDetails.isNotEmpty) {
                              final spouseDob = DateTime.tryParse(
                                spouseDobFromDetails,
                              );
                              if (spouseDob != null) {
                                final today = DateTime.now();
                                int years = today.year - spouseDob.year;
                                if (today.month < spouseDob.month ||
                                    (today.month == spouseDob.month &&
                                        today.day < spouseDob.day)) {
                                  years--;
                                }
                                spouseAge = years.toString();
                              } else {
                                spouseAge = _extractYearsFromApprox(
                                  spMap['approxAge'],
                                );
                              }
                            } else {
                              final extractedAge = _extractYearsFromApprox(
                                spMap['approxAge'],
                              );
                              if (extractedAge.isNotEmpty) {
                                spouseAge = extractedAge;
                              }
                            }
                          }
                        }
                      } catch (_) {}
                      spouseRow['Father'] = spouseFather;
                      spouseRow['Spouse'] = name;
                      spouseRow['Total Children'] = totalChildren;
                    } else {
                      String spouseFather = '';
                      try {
                        final spRaw = result['spousedetails'];
                        Map<String, dynamic>? spMap;
                        if (spRaw is Map) {
                          spMap = Map<String, dynamic>.from(spRaw);
                        } else if (spRaw is String && spRaw.isNotEmpty) {
                          spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                        }
                        if (spMap != null) {
                          spouseFather = (spMap['father_name'] ?? '').toString();

                          // Extract spouse age from spousedetails - this should take precedence
                          // First try to get the pre-calculated age
                          final String? preCalculatedAge = spMap['age']
                              ?.toString();
                          if (preCalculatedAge != null &&
                              preCalculatedAge.isNotEmpty) {
                            spouseAge = preCalculatedAge;
                          } else {
                            final bool spouseUseDobFromDetails =
                                (spMap['useDob'] == true);
                            final String? spouseDobFromDetails =
                                spMap['dob'] as String?;
                            if (spouseUseDobFromDetails &&
                                spouseDobFromDetails != null &&
                                spouseDobFromDetails.isNotEmpty) {
                              final spouseDob = DateTime.tryParse(
                                spouseDobFromDetails,
                              );
                              if (spouseDob != null) {
                                final today = DateTime.now();
                                int years = today.year - spouseDob.year;
                                if (today.month < spouseDob.month ||
                                    (today.month == spouseDob.month &&
                                        today.day < spouseDob.day)) {
                                  years--;
                                }
                                spouseAge = years.toString();
                              } else {
                                spouseAge = _extractYearsFromApprox(
                                  spMap['approxAge'],
                                );
                              }
                            } else {
                              final extractedAge = _extractYearsFromApprox(
                                spMap['approxAge'],
                              );
                              if (extractedAge.isNotEmpty) {
                                spouseAge = extractedAge;
                              }
                            }
                          }
                        }
                      } catch (_) {}
                      _members.add({
                        '#': '${_members.length + 1}',
                        'Type': 'Adult',
                        'Name': spouse,
                        'Age': spouseAge,
                        'Gender': spouseGender,
                        'Relation': 'Spouse',
                        'Father': spouseFather,
                        'Spouse': name,
                        'Total Children': totalChildren,
                        'formIndex': formIndexKey,
                        'isSpouseRow': '1',
                      });
                      totalMembers = totalMembers + 1;
                    }
                  } else {
                    if (spouseIndex != -1) {
                      _members.removeAt(spouseIndex);
                      totalMembers = (totalMembers - 1).clamp(0, 9999);
                    }
                  }
                });
                await _persistAdultsToSecureStorage();
              }
              return;
            }
            if (_headForm != null) {
              final initial = <String, String>{};
              _headForm!.forEach((key, value) {
                if (value != null) {
                  initial[key] = value.toString();
                }
              });
              
              // Ensure critical fields are preserved with alternative key names
              if (!initial.containsKey('houseNo') && _headForm!.containsKey('house_no')) {
                initial['houseNo'] = _headForm!['house_no'].toString();
              }
              if (!initial.containsKey('dob') && _headForm!.containsKey('date_of_birth')) {
                initial['dob'] = _headForm!['date_of_birth'].toString();
              }
              
              debugPrint('RegisterNewHouseHold (edit): initial keys: ${initial.keys.toList()}');
              debugPrint('RegisterNewHouseHold (edit): houseNo in initial: ${initial['houseNo']}');
              debugPrint('RegisterNewHouseHold (edit): dob in initial: ${initial['dob']}');
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
              final relation = (m['Relation'] ?? '').toString();
              final int initialTab =
                  (relation == 'Wife' || relation == 'Spouse') ? 1 : 0;
              final result = await Navigator.of(context)
                  .push<Map<String, dynamic>>(
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
                  final String father = (result['father_name'] ?? '').toString();
                  final String spouse = (result['spouseName'] ?? '').toString();
                  final String totalChildren =
                      (result['children'] != null &&
                          result['children'].toString().isNotEmpty)
                      ? (int.tryParse(result['children'].toString()) ?? 0) > 0
                            ? result['children'].toString()
                            : '0'
                      : '0';
                  final int headIndex = _members.indexWhere(
                    (row) => row['Relation'] == 'Self',
                  );
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
                  final String maritalStatus = (result['maritalStatus'] ?? '')
                      .toString();
                  final int spouseIndex = _members.indexWhere(
                    (row) =>
                        row['Relation'] == 'Wife' ||
                        row['Relation'] == 'Spouse',
                  );
                  if (maritalStatus == 'Married' && spouse.isNotEmpty) {
                    if (spouseIndex >= 0) {
                      final String spouseGender = (gender == 'Male')
                          ? 'Female'
                          : (gender == 'Female')
                          ? 'Male'
                          : '';
                      final bool spouseUseDob =
                          (result['spouseUseDob'] == true);
                      final String? spouseDobIso =
                          result['spouseDob'] as String?;
                      String spouseAge = '';
                      if (spouseUseDob &&
                          spouseDobIso != null &&
                          spouseDobIso.isNotEmpty) {
                        final spouseDob = DateTime.tryParse(spouseDobIso);
                        if (spouseDob != null) {
                          final today = DateTime.now();
                          int years = today.year - spouseDob.year;
                          if (today.month < spouseDob.month ||
                              (today.month == spouseDob.month &&
                                  today.day < spouseDob.day)) {
                            years--;
                          }
                          spouseAge = years.toString();
                        } else {
                          spouseAge = (result['spouseApproxAge'] ?? '')
                              .toString();
                        }
                      } else {
                        spouseAge = (result['spouseApproxAge'] ?? '')
                            .toString();
                      }
                      final Map<String, String> spouseRow = {
                        '#': _members[spouseIndex]['#'] ?? '${spouseIndex + 1}',
                        'Type': 'Adult',
                        'Name': spouse,
                        'Age': spouseAge,
                        'Gender': spouseGender,
                        'Relation': _members[spouseIndex]['Relation'] ?? 'Wife',
                        'Father': (_headForm?['sp_father_name'] ?? '')
                            .toString(),
                        'Spouse': name,
                        'Total Children': totalChildren,
                      };
                      _members[spouseIndex] = spouseRow;
                    }
                  } else {
                    if (spouseIndex >= 0) {
                      _members.removeAt(spouseIndex);
                    }
                  }
                });
                await _persistAdultsToSecureStorage();
              }
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.black54, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        m['Name'] ?? (l10n?.na ?? 'N/A'),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black54,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardRow([
                      _cardRowText(l10n?.thType ?? 'Type', m['Type'] ?? ''),
                      _cardRowText(
                        l10n?.ageGenderLabel ?? 'Age | Gender',
                        ageGender,
                      ),
                      _cardRowText(
                        l10n?.thRelation ?? 'Relation',
                        m['Relation'] ?? '',
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildCardRow([
                      _cardRowText(
                        l10n?.thFather ?? 'Father',
                        m['Father'] ?? '',
                      ),
                      _cardRowText(
                        l10n?.thSpouse ?? 'Spouse',
                        m['Spouse'] ?? '',
                      ),
                      _cardRowText(
                        l10n?.thTotalChildren ?? 'Total Children',
                        totalChildrenText,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _cardRowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.background,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
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
                  l10n?.dataSavedSuccessfullyFamily ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  '${l10n?.totalBeneficiaryAdded ?? ""}: $memberCount ',
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
                            builder: (context) =>
                                HomeScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                      child: Text(
                        l10n?.ok ?? 'OKAY',
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
          color: isDisabled ? Colors.white.withOpacity(0.4) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
