import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/enums.dart';
import '../../../../data/Local_Storage/database_provider.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../data/Local_Storage/tables/training_data_table.dart';

part 'training_event.dart';
part 'training_state.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final String formName = "training_form";
  final String formRefKey = "training_form_ref";

  TrainingBloc() : super(TrainingState.initial()) {

    on<TrainingTypeChanged>((event, emit) {
      emit(state.copyWith(
        trainingType: event.type,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<TrainingNameChanged>((event, emit) {
      emit(state.copyWith(
        trainingName: event.name,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<TrainingDateChanged>((event, emit) {
      emit(state.copyWith(
        date: event.date,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<TrainingPlaceChanged>((event, emit) {
      emit(state.copyWith(
        place: event.place,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<TrainingDaysChanged>((event, emit) {
      emit(state.copyWith(
        days: event.days,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<SubmitTraining>(_onSubmitTraining);
  }

  Future<void> _onSubmitTraining(
      SubmitTraining event,
      Emitter<TrainingState> emit,
      ) async {

    if (!state.isValid) {
      emit(state.copyWith(
        status: FormStatus.failure,
        error: "Please complete all fields correctly.",
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));

    try {
      final db = await DatabaseProvider.instance.database;

      final now = DateTime.now().toIso8601String();

      final formData = {
        'form_name': formName,
        'form_data': {
          'training_type': state.trainingType,
          'training_name': state.trainingName,
          'training_date': state.date?.toIso8601String(),
          'place': state.place,
          'days': state.days,
        },
        'created_at': now,
        'updated_at': now,
      };

      final formJson = jsonEncode(formData);

      final formDataForDb = {
        'server_id': '',
        'forms_ref_key': formRefKey,
        'household_ref_key': '',
        'beneficiary_ref_key': '',
        'mother_key': '',
        'father_key': '',
        'child_care_state': '',
        'device_details': '{}',
        'app_details': '{}',
        'parent_user': '',
        'current_user_key': '',
        'facility_id': 0,
        'form_json': formJson,
        'created_date_time': now,
        'modified_date_time': now,
        'is_synced': 0,
        'is_deleted': 0,
      };

      final formId = await LocalStorageDao.instance.insertTrainingData(formDataForDb);
      if (formId > 0) {
        emit(state.copyWith(status: FormStatus.success));
      } else {
        emit(state.copyWith(
          status: FormStatus.failure,
          error: 'Failed to save form data.',
        ));
      }

    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.failure,
        error: 'Error saving form data: $e',
      ));
    }
  }
}
