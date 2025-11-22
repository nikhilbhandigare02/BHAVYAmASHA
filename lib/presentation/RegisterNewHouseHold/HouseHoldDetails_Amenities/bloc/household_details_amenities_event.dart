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

class ResidentialAreaOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherResidentialArea;
  const ResidentialAreaOtherChange({required this.otherResidentialArea});

  List<Object> get props => [otherResidentialArea];
}

class HouseTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String houseType;
  const HouseTypeChange({required this.houseType});

  List<Object> get props => [houseType];
}

class HouseTypeOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherHouseType;
  const HouseTypeOtherChange({required this.otherHouseType});

  List<Object> get props => [otherHouseType];
}

class OwnershipTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String ownershipType;
  const OwnershipTypeChange({required this.ownershipType});

  List<Object> get props => [ownershipType];
}

class OwnershipTypeOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherOwnershipType;
  const OwnershipTypeOtherChange({required this.otherOwnershipType});

  List<Object> get props => [otherOwnershipType];
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

class CookingFuelOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherCookingFuel;
  const CookingFuelOtherChange({required this.otherCookingFuel});

  List<Object> get props => [otherCookingFuel];
}

class WaterSourceChange extends HouseholdDetailsAmenitiesEvent{
  final String waterSource;
  const WaterSourceChange({required this.waterSource});

  List<Object> get props => [waterSource];
}

class WaterSourceOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherWaterSource;
  const WaterSourceOtherChange({required this.otherWaterSource});

  List<Object> get props => [otherWaterSource];
}

class ElectricityChange extends HouseholdDetailsAmenitiesEvent{
  final String electricity;
  const ElectricityChange({required this.electricity});

  List<Object> get props => [electricity];
}

class ElectricityOtherChange extends HouseholdDetailsAmenitiesEvent{
  final String otherElectricity;
  const ElectricityOtherChange({required this.otherElectricity});

  List<Object> get props => [otherElectricity];
}

class ToiletChange extends HouseholdDetailsAmenitiesEvent{
  final String toilet;
  const ToiletChange({required this.toilet});

  List<Object> get props => [toilet];
}

class ToiletTypeChange extends HouseholdDetailsAmenitiesEvent{
  final String toiletType;
  const ToiletTypeChange({required this.toiletType});

  List<Object> get props => [toiletType];
}

class ToiletPlaceChange extends HouseholdDetailsAmenitiesEvent{
  final String toiletPlace;
  const ToiletPlaceChange({required this.toiletPlace});

  List<Object> get props => [toiletPlace];
}

class AddButton extends HouseholdDetailsAmenitiesEvent{}