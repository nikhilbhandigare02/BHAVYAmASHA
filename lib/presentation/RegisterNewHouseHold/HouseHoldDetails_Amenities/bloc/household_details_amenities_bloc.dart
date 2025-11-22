import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../core/utils/enums.dart';

part 'household_details_amenities_event.dart';
part 'household_details_amenities_state.dart';

class HouseholdDetailsAmenitiesBloc extends Bloc<HouseholdDetailsAmenitiesEvent, HouseholdDetailsAmenitiesState> {
  HouseholdDetailsAmenitiesBloc() : super(HouseholdDetailsAmenitiesState()) {
    on<ResidentialAreaChange>((event, emit) {
      print('ResidentialAreaChange: ${event.residentialArea}');
      emit(state.copyWith(
        residentialArea: event.residentialArea.isNotEmpty ? event.residentialArea : state.residentialArea
      ));
      print('New state: ${state.toString()}');
    });
    on<ResidentialAreaOtherChange>((event, emit) {
      emit(state.copyWith(otherResidentialArea: event.otherResidentialArea));
    });
    
    on<CookingFuelTypeChange>((event, emit) {
      print('CookingFuelTypeChange: ${event.cookingFuel}');
      emit(state.copyWith(
        cookingFuel: event.cookingFuel.isNotEmpty ? event.cookingFuel : state.cookingFuel
      ));
      print('New state: ${state.toString()}');
    });
    on<CookingFuelOtherChange>((event, emit) {
      emit(state.copyWith(otherCookingFuel: event.otherCookingFuel));
    });
    
    on<KitchenChange>((event, emit) {
      print('KitchenChange: ${event.houseKitchen}');
      emit(state.copyWith(
        houseKitchen: event.houseKitchen.isNotEmpty ? event.houseKitchen : state.houseKitchen
      ));
      print('New state: ${state.toString()}');
    });
    
    on<OwnershipTypeChange>((event, emit) {
      print('OwnershipTypeChange: ${event.ownershipType}');
      emit(state.copyWith(
        ownershipType: event.ownershipType.isNotEmpty ? event.ownershipType : state.ownershipType
      ));
      print('New state: ${state.toString()}');
    });
    on<OwnershipTypeOtherChange>((event, emit) {
      emit(state.copyWith(otherOwnershipType: event.otherOwnershipType));
    });
    
    on<HouseTypeChange>((event, emit) {
      print('HouseTypeChange: ${event.houseType}');
      emit(state.copyWith(
        houseType: event.houseType.isNotEmpty ? event.houseType : state.houseType
      ));
      print('New state: ${state.toString()}');
    });
    on<HouseTypeOtherChange>((event, emit) {
      emit(state.copyWith(otherHouseType: event.otherHouseType));
    });
    
    on<WaterSourceChange>((event, emit) {
      print('WaterSourceChange: ${event.waterSource}');
      emit(state.copyWith(
        waterSource: event.waterSource.isNotEmpty ? event.waterSource : state.waterSource
      ));
      print('New state: ${state.toString()}');
    });
    on<WaterSourceOtherChange>((event, emit) {
      emit(state.copyWith(otherWaterSource: event.otherWaterSource));
    });
    
    on<ElectricityChange>((event, emit) {
      print('ElectricityChange: ${event.electricity}');
      emit(state.copyWith(
        electricity: event.electricity.isNotEmpty ? event.electricity : state.electricity
      ));
      print('New state: ${state.toString()}');
    });
    on<ElectricityOtherChange>((event, emit) {
      emit(state.copyWith(otherElectricity: event.otherElectricity));
    });
    
    on<ToiletChange>((event, emit) {
      print('ToiletChange: ${event.toilet}');
      emit(state.copyWith(
        toilet: event.toilet.isNotEmpty ? event.toilet : state.toilet
      ));
      print('New state: ${state.toString()}');
    });

    on<ToiletTypeChange>((event, emit) {
      print('ToiletTypeChange: ${event.toiletType}');
      emit(state.copyWith(
        toiletType: event.toiletType.isNotEmpty ? event.toiletType : state.toiletType,
      ));
      print('New state: ${state.toString()}');
    });

    on<ToiletPlaceChange>((event, emit) {
      print('ToiletPlaceChange: ${event.toiletPlace}');
      emit(state.copyWith(
        toiletPlace: event.toiletPlace.isNotEmpty ? event.toiletPlace : state.toiletPlace,
      ));
      print('New state: ${state.toString()}');
    });
  }
}
