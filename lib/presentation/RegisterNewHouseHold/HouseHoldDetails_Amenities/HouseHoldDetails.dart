import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import '../../../l10n/app_localizations.dart';

class HouseHoldDetails extends StatelessWidget {
  const HouseHoldDetails({
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
        print('Household Details Form State: ${state.toString()}');
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                value: (state.residentialArea?.isEmpty ?? true) ? null : state.residentialArea,
                onChanged: (v) => context
                    .read<HouseholdDetailsAmenitiesBloc>()
                    .add(ResidentialAreaChange(residentialArea: v ?? '')),
              ),
              const Divider(color: AppColors.divider, thickness: 0.8),
              if (state.residentialArea == 'Other')
                CustomTextField(
                  labelText: l?.other_type_of_residential_area ??'Enter type of residential area',
                  hintText:l?.other_type_of_residential_area ?? 'Enter type of residential area',
                  initialValue: state.otherResidentialArea,
                  onChanged: (v) => context
                      .read<HouseholdDetailsAmenitiesBloc>()
                      .add(ResidentialAreaOtherChange(otherResidentialArea: v.trim())),
                ),
              if (state.residentialArea == 'Other')
                const Divider(color: AppColors.divider, thickness: 0.8),
              ApiDropdown<String>(
                labelText: l.houseTypeLabel,
                items: const ['None', 'Kuchcha house', 'Semi Pucca house','Pucca house','Thrust house','other'],
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
                value: (state.houseType?.isEmpty ?? true) ? null : state.houseType,
                onChanged: (v) => context
                    .read<HouseholdDetailsAmenitiesBloc>()
                    .add(HouseTypeChange(houseType: v ?? '')),
              ),
              const Divider(color: AppColors.divider, thickness: 0.8),
              if (state.houseType == 'other')
                CustomTextField(
                  labelText:l?.other_type_of_house ?? 'Enter type of house',
                  hintText:l?.other_type_of_house ?? 'Enter type of house',
                  initialValue: state.otherHouseType,
                  onChanged: (v) => context
                      .read<HouseholdDetailsAmenitiesBloc>()
                      .add(HouseTypeOtherChange(otherHouseType: v.trim())),
                ),
              if (state.houseType == 'other')
                const Divider(color: AppColors.divider, thickness: 0.8),
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
                value: (state.ownershipType?.isEmpty ?? true) ? null : state.ownershipType,
                onChanged: (v) => context
                    .read<HouseholdDetailsAmenitiesBloc>()
                    .add(OwnershipTypeChange(ownershipType: v ?? '')),
              ),
              const Divider(color: AppColors.divider, thickness: 0.8),
              if (state.ownershipType == 'Other')
                CustomTextField(
                  labelText:l?.enterTypeOfOwnershipLabel ?? 'Enter type of ownership',
                  hintText:l?.enterTypeOfOwnershipLabel ?? 'Enter type of ownership',
                  initialValue: state.otherOwnershipType,
                  onChanged: (v) => context
                      .read<HouseholdDetailsAmenitiesBloc>()
                      .add(OwnershipTypeOtherChange(otherOwnershipType: v.trim())),
                ),
              if (state.ownershipType == 'Other')
                const Divider(color: AppColors.divider, thickness: 0.8),
            ],
          ),
        );
      },
    );
  }
}
