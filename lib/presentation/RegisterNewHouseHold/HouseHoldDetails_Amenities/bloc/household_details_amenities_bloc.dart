import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../core/utils/enums.dart';

part 'household_details_amenities_event.dart';
part 'household_details_amenities_state.dart';

class HouseholdDetailsAmenitiesBloc extends Bloc<HouseholdDetailsAmenitiesEvent, HouseholdDetailsAmenitiesState> {
  HouseholdDetailsAmenitiesBloc() : super(const HouseholdDetailsAmenitiesState()) {
    on<ResidentialAreaChange>((event, emit) {
      print(event.residentialArea);
      emit(state.copyWith(residentialArea: event.residentialArea));
    });
    on<CookingFuelTypeChange>((event, emit) {
      emit(state.copyWith(cookingFuel: event.cookingFuel));
    });
    on<KitchenChange>((event, emit) {
      emit(state.copyWith(houseKitchen: event.houseKitchen));
    });
    on<OwnershipTypeChange>((event, emit) {
      emit(state.copyWith(ownershipType: event.ownershipType));
    });
    on<HouseTypeChange>((event, emit) {
      emit(state.copyWith(houseType: event.houseType));
    });
    on<WaterSourceChange>((event, emit) {
      emit(state.copyWith(waterSource: event.waterSource));
    });
    on<ElectricityChange>((event, emit) {
      emit(state.copyWith(electricity: event.electricity));
    });
    on<ToiletChange>((event, emit) {
      emit(state.copyWith(toilet: event.toilet));
    });
  }
}
