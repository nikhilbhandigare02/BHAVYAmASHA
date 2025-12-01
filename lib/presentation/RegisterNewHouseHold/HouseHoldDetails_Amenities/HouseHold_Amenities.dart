import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../l10n/app_localizations.dart';

class HouseHoldAmenities extends StatelessWidget {
  const HouseHoldAmenities({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<HouseholdDetailsAmenitiesBloc>();
    
    return BlocBuilder<HouseholdDetailsAmenitiesBloc, HouseholdDetailsAmenitiesState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          value: (state.houseKitchen!.isEmpty) ? null : state.houseKitchen,
                          onChanged: (v) => bloc.add(KitchenChange(houseKitchen: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        Builder(
                          builder: (context) {
                            const options = <String>[
                              'LPG',
                              'Firewood',
                              'Coal',
                              'Kerosene',
                              'Crop Residue',
                              'Drug Cake',
                              'Other',
                            ];

                            String labelFor(String s) {
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
                            }

                            final selected = state.cookingFuel
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toSet();

                            final displayText = selected.isEmpty
                                ? l.select
                                : selected.map(labelFor).join(', ');

                            Future<void> openFuelDialog() async {
                              final current = Set<String>.from(selected);

                              await showDialog<void>(
                                context: context,
                                builder: (ctx) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    backgroundColor: Colors.white,

                                    // ---------- TITLE WITH LINE ----------
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.cookingFuelTypeLabel,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Divider(
                                          color: Colors.grey.shade400,
                                          thickness: 0.8,
                                          height: 0,
                                        ),
                                      ],
                                    ),
                                    // -------------------------------------

                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          for (final option in options)
                                            StatefulBuilder(
                                              builder: (ctx2, setStateDialog) {
                                                final isChecked = current.contains(option);

                                                return Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Transform.scale(
                                                    scale: 1.0, // checkbox size
                                                    child: CheckboxListTile(
                                                      dense: true,
                                                      visualDensity: const VisualDensity(
                                                        vertical: -2,  // reduces height between items
                                                      ),
                                                      contentPadding: EdgeInsets.zero,
                                                      title: Text(
                                                        labelFor(option),
                                                        style: const TextStyle(fontSize: 12.5), // option size
                                                      ),
                                                      value: isChecked,
                                                      controlAffinity: ListTileControlAffinity.leading,
                                                      onChanged: (checked) {
                                                        setStateDialog(() {
                                                          if (checked == true) {
                                                            current.add(option);
                                                          } else {
                                                            current.remove(option);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: Text(l.cancel ?? 'Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final joined = current.join(', ');
                                          bloc.add(CookingFuelTypeChange(cookingFuel: joined));
                                          Navigator.of(ctx).pop();
                                        },
                                        child: Text(l.ok ?? 'OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    l.cookingFuelTypeLabel,
                                    style:  TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: openFuelDialog,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displayText,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12.5),
                                          ),
                                        ),
                                         Padding(
                                           padding: const EdgeInsets.only(right: 4.0),
                                           child: Icon(Icons.arrow_drop_down, color: Colors.blueGrey[400] ,),
                                         ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(color: AppColors.divider, thickness: 0.8),
                                if (selected.contains('Other'))
                                  CustomTextField(
                                    labelText: 'Enter type of fuel for cooking',
                                    hintText: 'Enter type of fuel for cooking',
                                    initialValue: state.otherCookingFuel,
                                    onChanged: (v) => bloc.add(CookingFuelOtherChange(otherCookingFuel: v.trim())),
                                  ),
                                if (selected.contains('Other'))
                                  const Divider(color: AppColors.divider, thickness: 0.8),
                              ],
                            );
                          },
                        ),
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
                          value: (state.waterSource!.isEmpty) ? null : state.waterSource,
                          onChanged: (v) => bloc.add(WaterSourceChange(waterSource: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        if (state.waterSource == 'Other')
                          CustomTextField(
                            labelText: 'Enter primary source of water',
                            hintText: 'Enter primary source of water',
                            initialValue: state.otherWaterSource,
                            onChanged: (v) => bloc.add(WaterSourceOtherChange(otherWaterSource: v.trim())),
                          ),
                        if (state.waterSource == 'Other')
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
                          value: (state.electricity!.isEmpty) ? null : state.electricity,
                          onChanged: (v) => bloc.add(ElectricityChange(electricity: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),
                        if (state.electricity == 'Other')
                          CustomTextField(
                            labelText: 'Enter availability of electricity',
                            hintText: 'Enter availability of electricity',
                            initialValue: state.otherElectricity,
                            onChanged: (v) => bloc.add(ElectricityOtherChange(otherElectricity: v.trim())),
                          ),
                        if (state.electricity == 'Other')
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
                          onChanged: (v) => bloc.add(ToiletChange(toilet: v ?? '')),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.8),

                        if (state.toilet == 'Yes') ...[
                          ApiDropdown<String>(
                            labelText: 'Type of toilet',
                            items: const [
                              'Flush toilet with running water ',
                              'Flush Toilet Without Water',
                              'Pit toilet with running water',
                              'Pit toilet without  water supply',
                              'Other',
                            ],
                            getLabel: (s) => s,
                            value: state.toiletType.isEmpty ? null : state.toiletType,
                            onChanged: (v) => bloc.add(ToiletTypeChange(toiletType: v ?? '')),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.8),
                          if(state.toiletType == 'Other') ... [
                            CustomTextField(
                              labelText: 'Enter Type of toilet',
                              hintText: 'Enter Type of toilet',
                              initialValue: state.typeOfToilet,
                              onChanged: (v) => bloc.add(TypeOfToilet(TypeToilet: v.trim())),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.8),
                          ]
                        ] else if (state.toilet == 'No') ...[
                          ApiDropdown<String>(
                            labelText: 'Where do you go for toilet?',
                            items: const [
                              'Community toilet',
                              'Friend/Relative toilet',
                              'Open space',
                            ],
                            getLabel: (s) => s,
                            value: state.toiletPlace.isEmpty ? null : state.toiletPlace,
                            onChanged: (v) => bloc.add(ToiletPlaceChange(toiletPlace: v ?? '')),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.8),
                        ],
            ],
          ),
        );
      },
    );
  }
  
  // Widget _buildForm(BuildContext context) {
  //   final l = AppLocalizations.of(context)!;
  //   final bloc = context.read<HouseholdDetailsAmenitiesBloc>();
  //
  //   return BlocBuilder<HouseholdDetailsAmenitiesBloc, HouseholdDetailsAmenitiesState>(
  //     bloc: bloc,
  //     builder: (context, state) {
  //       print('Amenities Form State: ${state.toString()}');
  //
  //       return SingleChildScrollView(
  //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Kitchen Inside
  //             ApiDropdown<String>(
  //               labelText: l.kitchenInsideLabel,
  //               items: const ['Yes', 'No'],
  //               getLabel: (s) {
  //                 switch (s) {
  //                   case 'Yes':
  //                     return l.yes;
  //                   case 'No':
  //                     return l.no;
  //                   default:
  //                     return s;
  //                 }
  //               },
  //               value: state.houseKitchen.isEmpty ? null : state.houseKitchen,
  //               onChanged: (v) => _bloc.add(KitchenChange(houseKitchen: v ?? '')),
  //             ),
  //             const Divider(color: AppColors.divider, thickness: 0.8),
  //
  //             // Cooking Fuel Type
  //             ApiDropdown<String>(
  //               labelText: l.cookingFuelTypeLabel,
  //               items: const [
  //                 'LPG',
  //                 'Firewood',
  //                 'Coal',
  //                 'Kerosene',
  //                 'Crop Residue',
  //                 'Drug Cake',
  //                 'Other'
  //               ],
  //               getLabel: (s) {
  //                 switch (s) {
  //                   case 'LPG':
  //                     return l.fuelLpg;
  //                   case 'Firewood':
  //                     return l.fuelFirewood;
  //                   case 'Coal':
  //                     return l.fuelCoal;
  //                   case 'Kerosene':
  //                     return l.fuelKerosene;
  //                   case 'Crop Residue':
  //                     return l.fuelCropResidue;
  //                   case 'Drug Cake':
  //                     return l.fuelDungCake;
  //                   case 'Other':
  //                     return l.fuelOther;
  //                   default:
  //                     return s;
  //                 }
  //               },
  //               value: state.cookingFuel.isEmpty ? null : state.cookingFuel,
  //               onChanged: (v) => _bloc.add(CookingFuelTypeChange(cookingFuel: v ?? '')),
  //             ),
  //             const Divider(color: AppColors.divider, thickness: 0.8),
  //
  //             // Primary Water Source
  //             ApiDropdown<String>(
  //               labelText: l.primaryWaterSourceLabel,
  //               items: const [
  //                 'Supply Water',
  //                 'R.O',
  //                 'Hand pump within house',
  //                 'Hand pump outside of house',
  //                 'Tanker',
  //                 'River',
  //                 'Pond',
  //                 'Lake',
  //                 'Well',
  //                 'Other'
  //               ],
  //               getLabel: (s) {
  //                 switch (s) {
  //                   case 'Supply Water':
  //                     return l.waterSupply;
  //                   case 'R.O':
  //                     return l.waterRO;
  //                   case 'Hand pump within house':
  //                     return l.waterHandpumpInside;
  //                   case 'Hand pump outside of house':
  //                     return l.waterHandpumpOutside;
  //                   case 'Tanker':
  //                     return l.waterTanker;
  //                   case 'River':
  //                     return l.waterRiver;
  //                   case 'Pond':
  //                     return l.waterPond;
  //                   case 'Lake':
  //                     return l.waterLake;
  //                   case 'Well':
  //                     return l.waterWell;
  //                   case 'Other':
  //                     return l.waterOther;
  //                   default:
  //                     return s;
  //                 }
  //               },
  //               value: state.waterSource.isEmpty ? null : state.waterSource,
  //               onChanged: (v) => _bloc.add(WaterSourceChange(waterSource: v ?? '')),
  //             ),
  //             const Divider(color: AppColors.divider, thickness: 0.8),
  //
  //             // Electricity Availability
  //             ApiDropdown<String>(
  //               labelText: l.electricityAvailabilityLabel,
  //               items: const [
  //                 'Electricity Supply',
  //                 'Generator',
  //                 'Solar Power',
  //                 'Kerosene Lamp',
  //                 'Other'
  //               ],
  //               getLabel: (s) {
  //                 switch (s) {
  //                   case 'Electricity Supply':
  //                     return l.elecSupply;
  //                   case 'Generator':
  //                     return l.elecGenerator;
  //                   case 'Solar Power':
  //                     return l.elecSolar;
  //                   case 'Kerosene Lamp':
  //                     return l.elecKeroseneLamp;
  //                   case 'Other':
  //                     return l.elecOther;
  //                   default:
  //                     return s;
  //                 }
  //               },
  //               value: state.electricity.isEmpty ? null : state.electricity,
  //               onChanged: (v) => _bloc.add(ElectricityChange(electricity: v ?? '')),
  //             ),
  //             const Divider(color: AppColors.divider, thickness: 0.8),
  //
  //             // Toilet Access
  //             ApiDropdown<String>(
  //               labelText: l.toiletAccessLabel,
  //               items: const ['Yes', 'No'],
  //               getLabel: (s) {
  //                 switch (s) {
  //                   case 'Yes':
  //                     return l.yes;
  //                   case 'No':
  //                     return l.no;
  //                   default:
  //                     return s;
  //                 }
  //               },
  //               value: state.toilet.isEmpty ? null : state.toilet,
  //               onChanged: (v) => _bloc.add(ToiletChange(toilet: v ?? '')),
  //             ),
  //
  //             // Add more fields as needed
  //             const SizedBox(height: 20),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
}
