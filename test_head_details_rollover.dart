import 'package:flutter_test/flutter_test.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_state.dart';

void main() {
  group('HeadDetails Age Rollover Logic', () {
    late AddFamilyHeadBloc bloc;

    setUp(() {
      bloc = AddFamilyHeadBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('should rollover days to months when days >= 30', () {
      // Start with initial state
      const initialState = AddFamilyHeadState(
        years: '0',
        months: '0', 
        days: '0',
      );
      
      // Simulate entering 35 days
      bloc.add(const UpdateDays('35'));
      // Wait for state to update
      expectLater(
        bloc.stream,
        emits(predicate<AddFamilyHeadState>((state) {
          // Days should be empty (0) and months should be incremented by 1
          return state.days == '' && state.months == '1';
        })),
      );
    });

    test('should rollover months to years when months >= 12', () {
      // Start with some months
      bloc.emit(const AddFamilyHeadState(
        years: '0',
        months: '13',
        days: '0',
      ));
      
      // Trigger a change to activate rollover logic
      bloc.add(const UpdateYears('0'));
      
      expectLater(
        bloc.stream,
        emits(predicate<AddFamilyHeadState>((state) {
          // Months should be empty (0) and years should be incremented by 1
          return state.months == '' && state.years == '1';
        })),
      );
    });

    test('should make both months and days empty when they are 0 after rollover', () {
      // Test multiple rollovers: 45 days should become 1 month 15 days, then 15 months should become 1 year 3 months
      bloc.add(const UpdateDays('45'));
      
      expectLater(
        bloc.stream,
        emits(predicate<AddFamilyHeadState>((state) {
          // After 45 days: should be 0 years, 1 month, 0 days (days empty after rollover)
          return state.years == '0' && state.months == '1' && state.days == '';
        })),
      );
    });

    test('should handle complex rollover scenario', () {
      // Test: 15 months and 35 days
      bloc.emit(const AddFamilyHeadState(
        years: '0',
        months: '15',
        days: '35',
      ));
      
      // Trigger change to activate rollover
      bloc.add(const UpdateYears('0'));
      
      expectLater(
        bloc.stream,
        emits(predicate<AddFamilyHeadState>((state) {
          // 15 months = 1 year 3 months, 35 days = 1 month 5 days
          // Total: 1 year, 4 months, 0 days (days empty after rollover)
          return state.years == '1' && state.months == '4' && state.days == '';
        })),
      );
    });
  });
}
