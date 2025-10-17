part of 'household_details_amenities_bloc.dart';

abstract class HouseholdDetailsAmenitiesEvent extends Equatable{
  const HouseholdDetailsAmenitiesEvent();

  List<Object> get props => [];
}


class ResidentialAreaChange extends HouseholdDetailsAmenitiesEvent{
  final String residentialArea;
  const ResidentialAreaChange({required this.residentialArea});

  List<Object> get props => [residentialArea];
}
class HouseTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String houseType;
  const HouseTypeChange({required this.houseType});

  List<Object> get props => [houseType];
}


class OwnershipTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String ownershipType;
  const OwnershipTypeChange({required this.ownershipType});

  List<Object> get props => [ownershipType];
}

class KitchenChange extends HouseholdDetailsAmenitiesEvent{
  final String houseKitchen;
  const KitchenChange({required this.houseKitchen});

  List<Object> get props => [houseKitchen];
}
class CookingFuelTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String cookingFuel;
  const CookingFuelTypeChange({required this.cookingFuel});

  List<Object> get props => [cookingFuel];
}
class WaterSourceChange extends HouseholdDetailsAmenitiesEvent{
  final String waterSource;
  const WaterSourceChange({required this.waterSource});

  List<Object> get props => [waterSource];
}
class ElectricityChange extends HouseholdDetailsAmenitiesEvent{
  final String electricity;
  const ElectricityChange({required this.electricity});

  List<Object> get props => [electricity];
}
class ToiletChange extends HouseholdDetailsAmenitiesEvent{
  final String toilet;
  const ToiletChange({required this.toilet});

  List<Object> get props => [toilet];
}

class AddButton extends HouseholdDetailsAmenitiesEvent{}