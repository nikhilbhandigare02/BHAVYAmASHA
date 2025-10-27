import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'cbac_form_event.dart';
part 'cbac_form_state.dart';

class CbacFormBloc extends Bloc<CBACFormEvent, CbacFormState> {
  static const int totalTabs = 6; // General, Personal, Part A, Part B, Part C, Part D

  CbacFormBloc() : super(const CbacFormInitial()) {
    on<CbacOpened>((event, emit) {
      if (!state.consentDialogShown) {
        emit(state.copyWith(consentDialogShown: true));
      }
    });

    on<CbacConsentDialogShown>((event, emit) => emit(state.copyWith(consentDialogShown: true)));
    on<CbacConsentAgreed>((event, emit) => emit(state.copyWith(consentAgreed: true)));
    on<CbacConsentDisagreed>((event, emit) => emit(state.copyWith(consentAgreed: false)));

    on<CbacNextTab>((event, emit) {
      if (!state.consentAgreed) return; // block navigation until consent
      // Per-part required validation before moving forward
      bool has(String key) {
        final v = state.data[key];
        if (v == null) return false;
        if (v is String) return v.trim().isNotEmpty;
        return true;
      }

      List<String> missing = [];
      // Tabs: 0=General, 1=Personal, 2=Part A, 3=Part B, 4=Part C, 5=Part D
      switch (state.activeTab) {
        case 2: // Part A
          {
            final req = [
              'partA.age',
              'partA.tobacco',
              'partA.alcohol',
              'partA.activity',
              'partA.waist',
              'partA.familyHistory',
            ];
            for (final k in req) {
              if (!has(k)) missing.add(k);
            }
          }
          break;
        case 3: // Part B
          {
            final req = [
              'partB.b1.cough2w',
              'partB.b1.bloodMucus',
              'partB.b1.fever2w',
              'partB.b1.weightLoss',
              'partB.b1.nightSweat',
              'partB.b2.excessBleeding',
              'partB.b2.depression',
              'partB.b2.uterusProlapse',
            ];
            for (final k in req) {
              if (!has(k)) missing.add(k);
            }
          }
          break;
        default:
          break;
      }

      if (missing.isNotEmpty) {
        // Emit a unique token in errorMessage to guarantee state change each time
        final token = DateTime.now().microsecondsSinceEpoch.toString();
        emit(state.copyWith(missingKeys: missing, errorMessage: token, clearError: false));
        return;
      }

      final next = (state.activeTab + 1).clamp(0, totalTabs - 1);
      emit(state.copyWith(activeTab: next));
    });

    on<CbacPrevTab>((event, emit) {
      final prev = (state.activeTab - 1).clamp(0, totalTabs - 1);
      emit(state.copyWith(activeTab: prev));
    });

    on<CbacFieldChanged>((event, emit) {
      final newData = Map<String, dynamic>.from(state.data);
      newData[event.keyPath] = event.value;
      emit(state.copyWith(data: newData, clearError: true));
    });
  }
}
