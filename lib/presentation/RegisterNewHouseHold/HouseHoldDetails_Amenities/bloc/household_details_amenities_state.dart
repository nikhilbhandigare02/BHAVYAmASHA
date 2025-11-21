part of 'household_details_amenities_bloc.dart';

class HouseholdDetailsAmenitiesState extends Equatable {
  const HouseholdDetailsAmenitiesState({
    this.residentialArea = '',
    this.ownershipType = '',
    this.houseType = '',
    this.houseKitchen = '',
    this.cookingFuel = '',
    this.waterSource = '',
    this.electricity = '',
    this.toilet = '',
    this.toiletType = '',
    this.toiletPlace = '',
    this.error = '',
    this.postApiStatus = PostApiStatus.initial,
  });
  
  final String residentialArea;
  final String ownershipType;
  final String houseType;
  final String houseKitchen;
  final String cookingFuel;
  final String waterSource;
  final String electricity;
  final String toilet;
  final String toiletType;
  final String toiletPlace;
  final String error;
  final PostApiStatus postApiStatus;

  HouseholdDetailsAmenitiesState copyWith({
     String? residentialArea,
     String? ownershipType,
     String? houseType,
     String? houseKitchen,
     String? cookingFuel,
     String? waterSource,
     String? electricity,
     String? toilet,
     String? toiletType,
     String? toiletPlace,
     String? error,
    PostApiStatus? postApiStatus,

  }){
    return HouseholdDetailsAmenitiesState(
        residentialArea: residentialArea ?? this.residentialArea,
        ownershipType: ownershipType ?? this.ownershipType,
      houseType: houseType ?? this.houseType,
        houseKitchen: houseKitchen ?? this.houseKitchen,
        cookingFuel: cookingFuel ?? this.cookingFuel,
        waterSource: waterSource ?? this.waterSource,
        electricity: electricity ?? this.electricity,
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
    ownershipType,
    houseKitchen,
    houseType,
    cookingFuel,
    waterSource,
    electricity,
    toilet,
    toiletType,
    toiletPlace,
    error,
    postApiStatus,
  ];

}
