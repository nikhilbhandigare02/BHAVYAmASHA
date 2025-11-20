import 'dart:developer';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/data/models/guest_beneficiary/search_beneficiary_response.dart';
import 'package:medixcel_new/data/repositories/GuestBeneficiaryRepository.dart';
import '../../../core/utils/enums.dart' show GbsStatus;
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../../../data/models/guest_beneficiary/guest_beneficiary_model.dart';
import 'guest_beneficiary_search_event.dart';
import 'guest_beneficiary_search_state.dart';

class GuestBeneficiarySearchBloc extends Bloc<GuestBeneficiarySearchEvent, GuestBeneficiarySearchState> {
  final GuestBeneficiaryRepository _repo;

  GuestBeneficiarySearchBloc({required GuestBeneficiaryRepository repo})
      : _repo = repo,
        super(const GuestBeneficiarySearchState()) {

    /// -------------------- Toggle advanced search --------------------
    on<GbsToggleAdvanced>((event, emit) {
      emit(state.copyWith(showAdvanced: !state.showAdvanced));
    });

    /// -------------------- Update Form Fields --------------------
    on<GbsUpdateBeneficiaryNo>((event, emit) {
      log('Beneficiary No updated: ${event.value}');
      emit(state.copyWith(beneficiaryNo: event.value));
    });

    on<GbsUpdateDistrict>((event, emit) {
      log('District updated: ${event.value}');
      emit(state.copyWith(district: event.value));
    });

    on<GbsUpdateBlock>((event, emit) {
      log('Block updated: ${event.value}');
      emit(state.copyWith(block: event.value));
    });

    on<GbsUpdateCategory>((event, emit) {
      log('Category updated: ${event.value}');
      emit(state.copyWith(category: event.value));
    });

    on<GbsUpdateGender>((event, emit) {
      log('Gender updated: ${event.value}');
      emit(state.copyWith(gender: event.value));
    });

    on<GbsUpdateAge>((event, emit) {
      log('Age updated: ${event.value}');
      emit(state.copyWith(age: event.value));
    });

    on<GbsUpdateMobile>((event, emit) {
      log('Mobile No updated: ${event.value}');
      emit(state.copyWith(mobileNo: event.value));
    });

    // In the GbsSubmitSearch event handler
    on<GbsSubmitSearch>((event, emit) async {
      log('🔍 Submitting search...');

      // Validate
      if (state.beneficiaryNo == null || state.beneficiaryNo!.isEmpty) {
        emit(state.copyWith(
          status: GbsStatus.failure,
          errorMessage: 'Please enter a beneficiary number',
        ));
        return;
      }

      emit(state.copyWith(
        status: GbsStatus.loading,
        clearError: true,
      ));

      try {
        log('🔍 Searching for beneficiary: ${state.beneficiaryNo}');

        final response = await _repo.searchBeneficiary(state.beneficiaryNo!);

        if (response.success && response.data != null) {
          final List<dynamic> dataList = response.data is List
              ? List<dynamic>.from(response.data as Iterable)
              : [response.data];
          final List<GuestBeneficiary> beneficiaries = [];

          // Parse the response data
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              beneficiaries.add(GuestBeneficiary.fromJson(item));
            }
          }

          log('📊 Found ${beneficiaries.length} beneficiaries to save');

          int savedCount = 0;
          // Save to local database
          for (final beneficiary in beneficiaries) {
            try {
              final id = await LocalStorageDao().saveGuestBeneficiary(beneficiary);
              if (id != null && id > 0) {
                savedCount++;
                log('✅ Successfully saved beneficiary: ${beneficiary.uniqueKey} with ID: $id');
              } else {
                log('⚠️ Failed to save beneficiary: ${beneficiary.uniqueKey} - No ID returned');
              }
            } catch (e) {
              log('❌ Error saving beneficiary ${beneficiary.uniqueKey}: $e');
            }
          }
          log('📦 Parsed data: ${dataList.length} items');
          for (var item in dataList) {
            log('📝 Item type: ${item.runtimeType}');
            if (item is Map) {
              log('🔑 Item keys: ${item.keys.join(', ')}');
            }
          }
          log('💾 Save operation complete. Successfully saved $savedCount out of ${beneficiaries.length} beneficiaries');

          emit(state.copyWith(
            status: GbsStatus.success,
            beneficiaries: beneficiaries,
          ));
        }else {
          emit(state.copyWith(
            status: GbsStatus.failure,
            errorMessage: response.message ?? 'Failed to fetch beneficiary data',
          ));
        }
      } catch (e, stackTrace) {
        log('❌ Error searching for beneficiary: $e');
        log('Stack trace: $stackTrace');
        emit(state.copyWith(
          status: GbsStatus.failure,
          errorMessage: 'An error occurred while searching for beneficiary',
        ));
      }
    });

  }


}