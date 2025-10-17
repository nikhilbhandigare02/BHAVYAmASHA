import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../l10n/app_localizations.dart';
import '../AddFamilyHead/bloc/add_family_head_bloc.dart';

class HouseHoldAmenities extends StatefulWidget {
  const HouseHoldAmenities({super.key});

  @override
  State<HouseHoldAmenities> createState() => _HouseHoldAmenitiesState();
}

class _HouseHoldAmenitiesState extends State<HouseHoldAmenities> {
  late final HouseholdDetailsAmenitiesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = HouseholdDetailsAmenitiesBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<HouseholdDetailsAmenitiesBloc, HouseholdDetailsAmenitiesState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      children: [
                        ApiDropdown<String>(
                          labelText: l.kitchenInsideLabel,
                          items: const ['Yes', 'No'],
                          getLabel: (s) {
                            switch (s) {
                              case 'Yes':
                                return l.yes;
                              case 'No':
                                return l.no;
                              default:
                                return s;
                            }
                          },
                          value: (state.houseKitchen.isEmpty) ? null : state.houseKitchen,
                          onChanged: (v) => context
                              .read<HouseholdDetailsAmenitiesBloc>()
                              .add(KitchenChange(houseKitchen: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        ApiDropdown<String>(
                          labelText: l.cookingFuelTypeLabel,
                          items: const [
                            'LPG',
                            'Firewood',
                            'Coal',
                            'Kerosene',
                            'Crop Residue',
                            'Drug Cake',
                            'Other'
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'LPG':
                                return l.fuelLpg;
                              case 'Firewood':
                                return l.fuelFirewood;
                              case 'Coal':
                                return l.fuelCoal;
                              case 'Kerosene':
                                return l.fuelKerosene;
                              case 'Crop Residue':
                                return l.fuelCropResidue;
                              case 'Drug Cake':
                                return l.fuelDungCake;
                              case 'Other':
                                return l.fuelOther;
                              default:
                                return s;
                            }
                          },
                          value: (state.cookingFuel.isEmpty) ? null : state.cookingFuel,
                          onChanged: (v) => context
                              .read<HouseholdDetailsAmenitiesBloc>()
                              .add(CookingFuelTypeChange(cookingFuel: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        ApiDropdown<String>(
                          labelText: l.primaryWaterSourceLabel,
                          items: const [
                            'Supply Water',
                            'R.O',
                            'Hand pump within house',
                            'Hand pump outside of house',
                            'Tanker',
                            'River',
                            'Pond',
                            'Lake',
                            'Well',
                            'Other'
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'Supply Water':
                                return l.waterSupply;
                              case 'R.O':
                                return l.waterRO;
                              case 'Hand pump within house':
                                return l.waterHandpumpInside;
                              case 'Hand pump outside of house':
                                return l.waterHandpumpOutside;
                              case 'Tanker':
                                return l.waterTanker;
                              case 'River':
                                return l.waterRiver;
                              case 'Pond':
                                return l.waterPond;
                              case 'Lake':
                                return l.waterLake;
                              case 'Well':
                                return l.waterWell;
                              case 'Other':
                                return l.waterOther;
                              default:
                                return s;
                            }
                          },
                          value: (state.waterSource.isEmpty) ? null : state.waterSource,
                          onChanged: (v) => context
                              .read<HouseholdDetailsAmenitiesBloc>()
                              .add(WaterSourceChange(waterSource: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        ApiDropdown<String>(
                          labelText: l.electricityAvailabilityLabel,
                          items: const [
                            'Electricity Supply',
                            'Generator',
                            'Solar Power',
                            'Kerosene Lamp',
                            'Other'
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'Electricity Supply':
                                return l.elecSupply;
                              case 'Generator':
                                return l.elecGenerator;
                              case 'Solar Power':
                                return l.elecSolar;
                              case 'Kerosene Lamp':
                                return l.elecKeroseneLamp;
                              case 'Other':
                                return l.elecOther;
                              default:
                                return s;
                            }
                          },
                          value: (state.electricity.isEmpty) ? null : state.electricity,
                          onChanged: (v) => context
                              .read<HouseholdDetailsAmenitiesBloc>()
                              .add(ElectricityChange(electricity: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        ApiDropdown<String>(
                          labelText: l.toiletAccessLabel,
                          items: const ['Yes', 'No'],
                          getLabel: (s) {
                            switch (s) {
                              case 'Yes':
                                return l.yes;
                              case 'No':
                                return l.no;
                              default:
                                return s;
                            }
                          },
                          value: (state.toilet.isEmpty) ? null : state.toilet,
                          onChanged: (v) => context
                              .read<HouseholdDetailsAmenitiesBloc>()
                              .add(ToiletChange(toilet: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                      ],
                    )
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
