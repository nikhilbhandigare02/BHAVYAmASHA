import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../data/Database/local_storage_dao.dart';

part 'spous_event.dart';
part 'spous_state.dart';

class SpousBloc extends Bloc<SpousEvent, SpousState> {
  int _daysInMonth(int year, int month) {
    return 30;
  }

  Map<String, int> _agePartsFromDob(DateTime dob) {
    final today = DateTime.now();
    int totalDays = today.difference(dob).inDays;
    if (totalDays < 0) {
      totalDays = 0;
    }
    final years = totalDays ~/ 360;
    final remainderAfterYears = totalDays % 360;
    final months = remainderAfterYears ~/ 30;
    final days = remainderAfterYears % 30;
    return {'years': years, 'months': months, 'days': days};
  }

  DateTime? _dobFromAgeParts(int years, int months, int days) {
    if (years < 0 || months < 0 || days < 0) return null;
    if (years == 0 && months == 0 && days == 0) return null;
    final totalDays = years * 360 + months * 30 + days;
    final today = DateTime.now();
    return today.subtract(Duration(days: totalDays));
  }

  SpousBloc({SpousState? initial}) : super(initial ?? const SpousState()) {
    on<SpHydrate>((event, emit) => emit(event.value));
    on<SpToggleUseDob>(
      (event, emit) => emit(state.copyWith(useDob: !state.useDob)),
    );

    on<SpUpdateRelation>(
      (event, emit) => emit(state.copyWith(relation: event.value)),
    );
    on<UpdateYearsChanged>((event, emit) {
      final yearsStr = event.value ?? '';
      final monthsStr = state.UpdateMonths ?? '';
      final daysStr = state.UpdateDays ?? '';

      int years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      int months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      int days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      // Handle day rollover (30 days = 1 month)
      if (days >= 30) {
        final additionalMonths = days ~/ 30;
        months += additionalMonths;
        days = days % 30;
      }

      // Handle month rollover (12 months = 1 year)
      if (months >= 12) {
        final additionalYears = (months / 12).floor();
        years += additionalYears;
        months = months % 12;
      }

      final newYearStr = yearsStr.isEmpty ? '' : years.toString();
      final newMonthStr = months.toString();
      final newDayStr = daysStr.isEmpty ? '' : days.toString();

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();
      emit(
        state.copyWith(
          UpdateYears: newYearStr,
          UpdateMonths: newMonthStr,
          UpdateDays: newDayStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<UpdateMonthsChanged>((event, emit) {
      final monthsStr = event.value ?? '';
      final yearsStr = state.UpdateYears ?? '';
      final daysStr = state.UpdateDays ?? '';

      int years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      int months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      int days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      // Handle day rollover (30 days = 1 month)
      if (days >= 30) {
        final additionalMonths = days ~/ 30;
        months += additionalMonths;
        days = days % 30;
      }

      // Handle month rollover (12 months = 1 year)
      if (months >= 12) {
        final additionalYears = (months / 12).floor();
        years += additionalYears;
        months = months % 12;
      }

      final newYearStr = years.toString();
      final newMonthStr = months.toString();
      final newDayStr = daysStr.isEmpty ? '' : days.toString();

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          UpdateYears: newYearStr,
          UpdateMonths: newMonthStr,
          UpdateDays: newDayStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<UpdateDaysChanged>((event, emit) {
      final daysStr = event.value ?? '';
      final yearsStr = state.UpdateYears ?? '';
      final monthsStr = state.UpdateMonths ?? '';

      int years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      int months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      int days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      // Handle day rollover (30 days = 1 month)
      if (days >= 30) {
        final additionalMonths = days ~/ 30;
        months += additionalMonths;
        days = days % 30;
      }

      // Handle month rollover (12 months = 1 year)
      if (months >= 12) {
        final additionalYears = (months / 12).floor();
        years += additionalYears;
        months = months % 12;
      }

      final newYearStr = years.toString();
      final newMonthStr = months.toString();
      final newDayStr = daysStr.isEmpty ? '' : days.toString();

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          UpdateYears: newYearStr,
          UpdateMonths: newMonthStr,
          UpdateDays: newDayStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });
    on<SpUpdateMemberName>(
      (event, emit) => emit(state.copyWith(memberName: event.value)),
    );
    on<SpUpdateAgeAtMarriage>(
      (event, emit) => emit(state.copyWith(ageAtMarriage: event.value)),
    );
    on<SpUpdateSpouseName>(
      (event, emit) => emit(state.copyWith(spouseName: event.value)),
    );
    on<SpUpdateFatherName>(
      (event, emit) => emit(state.copyWith(fatherName: event.value)),
    );
    on<SpUpdateDob>((event, emit) {
      final dob = event.value;
      if (dob == null) {
        emit(state.copyWith(dob: null));
        return;
      }

      if (!state.useDob) {
        emit(state.copyWith(dob: dob));
        return;
      }

      final parts = _agePartsFromDob(dob);
      final years = parts['years'] ?? 0;
      final months = parts['months'] ?? 0;
      final days = parts['days'] ?? 0;
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          dob: dob,
          UpdateYears: years.toString(),
          UpdateMonths: months.toString(),
          UpdateDays: days.toString(),
          approxAge: approx,
        ),
      );
    });
    on<SpUpdateApproxAge>(
      (event, emit) => emit(state.copyWith(approxAge: event.value)),
    );
    on<SpUpdateGender>(
      (event, emit) => emit(state.copyWith(gender: event.value)),
    );
    on<SpUpdateOccupation>(
      (event, emit) => emit(state.copyWith(occupation: event.value)),
    );
    on<SpUpdateOtherOccupation>(
      (event, emit) => emit(state.copyWith(otherOccupation: event.value)),
    );
    on<SpUpdateEducation>(
      (event, emit) => emit(state.copyWith(education: event.value)),
    );
    on<SpUpdateReligion>(
      (event, emit) => emit(state.copyWith(religion: event.value)),
    );
    on<SpUpdateOtherReligion>(
      (event, emit) => emit(state.copyWith(otherReligion: event.value)),
    );
    on<SpUpdateCategory>(
      (event, emit) => emit(state.copyWith(category: event.value)),
    );
    on<SpUpdateOtherCategory>(
      (event, emit) => emit(state.copyWith(otherCategory: event.value)),
    );
    on<SpUpdateAbhaAddress>(
      (event, emit) => emit(state.copyWith(abhaAddress: event.value)),
    );
    on<SpUpdateMobileOwner>(
      (event, emit) => emit(state.copyWith(mobileOwner: event.value)),
    );
    on<SpUpdateMobileOwnerOtherRelation>(
      (event, emit) =>
          emit(state.copyWith(mobileOwnerOtherRelation: event.value)),
    );
    on<SpUpdateMobileNo>(
      (event, emit) => emit(state.copyWith(mobileNo: event.value)),
    );
    on<SpUpdateBankAcc>(
      (event, emit) => emit(state.copyWith(bankAcc: event.value)),
    );
    on<SpUpdateIfsc>((event, emit) => emit(state.copyWith(ifsc: event.value)));
    on<SpUpdateVoterId>(
      (event, emit) => emit(state.copyWith(voterId: event.value)),
    );
    on<SpUpdateRationId>(
      (event, emit) => emit(state.copyWith(rationId: event.value)),
    );
    on<SpUpdatePhId>((event, emit) => emit(state.copyWith(phId: event.value)));
    on<SpUpdateBeneficiaryType>(
      (event, emit) => emit(state.copyWith(beneficiaryType: event.value)),
    );

    on<RchIDChanged>((event, emit) {
      final value = event.value;
      final isButtonEnabled = value.length == 12;
      emit(
        state.copyWith(
          RichIDChanged: value,
          isRchIdButtonEnabled: isButtonEnabled,
        ),
      );
    });
    on<SpUpdateIsPregnant>(
      (event, emit) => emit(state.copyWith(isPregnant: event.value)),
    );
    on<SpUpdateMemberStatus>((event, emit) async {
      emit(state.copyWith(memberStatus: event.value));

      // Update beneficiary's is_death field when status changes to death
      if (event.value == 'death') {
        try {
          final spouseData = state.toJson();
          final spouseUniqueKey =
              spouseData['unique_key'] ?? spouseData['spouse_unique_key'];

          if (spouseUniqueKey != null) {
            await LocalStorageDao.instance.updateBeneficiaryDeathStatus(
              uniqueKey: spouseUniqueKey,
              isDeath: 1,
            );
          }
        } catch (e) {
          print('Error updating spouse beneficiary death status: $e');
        }
      } else if (event.value == 'alive') {
        try {
          final spouseData = state.toJson();
          final spouseUniqueKey =
              spouseData['unique_key'] ?? spouseData['spouse_unique_key'];

          if (spouseUniqueKey != null) {
            await LocalStorageDao.instance.updateBeneficiaryDeathStatus(
              uniqueKey: spouseUniqueKey,
              isDeath: 0,
            );
          }
        } catch (e) {
          print('Error updating spouse beneficiary death status: $e');
        }
      }
    });

    on<SpLMPChange>((event, emit) {
      final lmp = event.value;
      final edd = lmp != null ? lmp.add(const Duration(days: 5)) : null;
      emit(state.copyWith(lmp: lmp, edd: edd));
    });

    on<SpEDDChange>((event, emit) => emit(state.copyWith(edd: event.value)));

    // Family planning fields
    on<FamilyPlanningCounselingChanged>(
      (event, emit) =>
          emit(state.copyWith(familyPlanningCounseling: event.value)),
    );
    on<FpMethodChanged>(
      (event, emit) => emit(state.copyWith(fpMethod: event.value)),
    );
    on<RemovalDateChanged>(
      (event, emit) => emit(state.copyWith(removalDate: event.value)),
    );
    on<DateofAntraChanged>(
      (event, emit) => emit(state.copyWith(antraDate: event.value)),
    );
    on<RemovalReasonChanged>(
      (event, emit) => emit(state.copyWith(removalReason: event.value)),
    );
    on<CondomQuantityChanged>(
      (event, emit) => emit(state.copyWith(condomQuantity: event.value)),
    );
    on<MalaQuantityChanged>(
      (event, emit) => emit(state.copyWith(malaQuantity: event.value)),
    );
    on<ChhayaQuantityChanged>(
      (event, emit) => emit(state.copyWith(chhayaQuantity: event.value)),
    );
    on<ECPQuantityChanged>(
      (event, emit) => emit(state.copyWith(ecpQuantity: event.value)),
    );
  }
}
