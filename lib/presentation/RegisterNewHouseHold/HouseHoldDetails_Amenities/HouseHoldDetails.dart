import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../l10n/app_localizations.dart';

class HouseHoldDetails extends StatefulWidget {
  const HouseHoldDetails({super.key});

  @override
  State<HouseHoldDetails> createState() => _HouseHoldDetailsState();
}

class _HouseHoldDetailsState extends State<HouseHoldDetails> {
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
                        labelText: l.residentialAreaTypeLabel,
                        items: const ['Rural', 'Urban', 'Tribal','Other'],
                        getLabel: (s) {
                          switch (s) {
                            case 'Rural':
                              return l.areaRural;
                            case 'Urban':
                              return l.areaUrban;
                            case 'Tribal':
                              return l.areaTribal;
                            case 'Other':
                              return l.other;
                            default:
                              return s;
                          }
                        },
                        value: (state.residentialArea.isEmpty) ? null : state.residentialArea,
                        onChanged: (v) => context
                            .read<HouseholdDetailsAmenitiesBloc>()
                            .add(ResidentialAreaChange( residentialArea: v ?? '')),
                      ),
                      Divider(color: AppColors.divider, thickness: 0.8),
                      ApiDropdown<String>(
                        labelText: l.houseTypeLabel,
                        items: const ['None', 'Kuchcha house', 'Semi Pucca house','Pucca house',' Thrust house','other'],
                        getLabel: (s) {
                          switch (s) {
                            case 'None':
                              return l.houseNone;
                            case 'Kuchcha house':
                              return l.houseKachcha;
                            case 'Semi Pucca house':
                              return l.houseSemiPucca;
                            case 'Pucca house':
                              return l.housePucca;
                            case 'Thrust house':
                              return l.houseThatch;
                            case 'other':
                              return l.other;
                            default:
                              return s;
                          }
                        },
                        value: (state.houseType.isEmpty) ? null : state.houseType,
                        onChanged: (v) => context
                            .read<HouseholdDetailsAmenitiesBloc>()
                            .add(HouseTypeChange( houseType: v ?? '')),
                      ),
                      Divider(color: AppColors.divider, thickness: 0.8),
                      ApiDropdown<String>(
                        labelText: l.ownershipTypeLabel,
                        items: const ['Self', 'Rental', 'Sharing','Other'],
                        getLabel: (s) {
                          switch (s) {
                            case 'Self':
                              return l.self;
                            case 'Rental':
                              return l.rental;
                            case 'Sharing':
                              return l.sharing;
                            case 'Other':
                              return l.other;
                            default:
                              return s;
                          }
                        },
                        value: (state.ownershipType.isEmpty) ? null : state.ownershipType,
                        onChanged: (v) => context
                            .read<HouseholdDetailsAmenitiesBloc>()
                            .add(OwnershipTypeChange( ownershipType: v ?? '')),
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
