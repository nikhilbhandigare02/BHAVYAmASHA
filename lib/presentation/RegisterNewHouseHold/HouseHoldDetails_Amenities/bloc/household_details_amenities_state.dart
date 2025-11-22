part of 'household_details_amenities_bloc.dart';

class HouseholdDetailsAmenitiesState extends Equatable {
  const HouseholdDetailsAmenitiesState({
    this.residentialArea = '',
    this.otherResidentialArea = '',
    this.ownershipType = '',
    this.otherOwnershipType = '',
    this.houseType = '',
    this.otherHouseType = '',
    this.houseKitchen = '',
    this.cookingFuel = '',
    this.otherCookingFuel = '',
    this.waterSource = '',
    this.otherWaterSource = '',
    this.electricity = '',
    this.otherElectricity = '',
    this.toilet = '',
    this.toiletType = '',
    this.toiletPlace = '',
    this.error = '',
    this.postApiStatus = PostApiStatus.initial,
  });
  
  final String residentialArea;
  final String otherResidentialArea;
  final String ownershipType;
  final String otherOwnershipType;
  final String houseType;
  final String otherHouseType;
  final String houseKitchen;
  final String cookingFuel;
  final String otherCookingFuel;
  final String waterSource;
  final String otherWaterSource;
  final String electricity;
  final String otherElectricity;
  final String toilet;
  final String toiletType;
  final String toiletPlace;
  final String error;
  final PostApiStatus postApiStatus;

  HouseholdDetailsAmenitiesState copyWith({
     String? residentialArea,
     String? otherResidentialArea,
     String? ownershipType,
     String? otherOwnershipType,
     String? houseType,
     String? otherHouseType,
     String? houseKitchen,
     String? cookingFuel,
     String? otherCookingFuel,
     String? waterSource,
     String? otherWaterSource,
     String? electricity,
     String? otherElectricity,
     String? toilet,
     String? toiletType,
     String? toiletPlace,
     String? error,
    PostApiStatus? postApiStatus,

  }){
    return HouseholdDetailsAmenitiesState(
        residentialArea: residentialArea ?? this.residentialArea,
        otherResidentialArea: otherResidentialArea ?? this.otherResidentialArea,
        ownershipType: ownershipType ?? this.ownershipType,
        otherOwnershipType: otherOwnershipType ?? this.otherOwnershipType,
        houseType: houseType ?? this.houseType,
        otherHouseType: otherHouseType ?? this.otherHouseType,
        houseKitchen: houseKitchen ?? this.houseKitchen,
        cookingFuel: cookingFuel ?? this.cookingFuel,
        otherCookingFuel: otherCookingFuel ?? this.otherCookingFuel,
        waterSource: waterSource ?? this.waterSource,
        otherWaterSource: otherWaterSource ?? this.otherWaterSource,
        electricity: electricity ?? this.electricity,
        otherElectricity: otherElectricity ?? this.otherElectricity,
        toilet: toilet ?? this.toilet,
        toiletType: toiletType ?? this.toiletType,
        toiletPlace: toiletPlace ?? this.toiletPlace,
        error: error ?? this.error,
        postApiStatus: postApiStatus ?? this.postApiStatus,
    );
  }
  @override
  List<Object?> get props => [
    residentialArea,
    otherResidentialArea,
    ownershipType,
    otherOwnershipType,
    houseKitchen,
    houseType,
    otherHouseType,
    cookingFuel,
    otherCookingFuel,
    waterSource,
    otherWaterSource,
    electricity,
    otherElectricity,
    toilet,
    toiletType,
    toiletPlace,
    error,
    postApiStatus,
  ];

}
