import 'package:flutter_test/flutter_test.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';

void main() {
  group('HBNC Visit Date Calculation Tests', () {
    late HbncVisitBloc bloc;
    
    setUp(() {
      bloc = HbncVisitBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('should calculate correct visit dates for different visit numbers', () {
      final baseDate = DateTime(2024, 1, 1); // January 1, 2024
      
      // Test Day 1 visit
      final day1Date = bloc.calculateHbncVisitDate(1, baseDate);
      expect(day1Date, equals(DateTime(2024, 1, 1)));
      
      // Test Day 3 visit (2 days after day 1)
      final day3Date = bloc.calculateHbncVisitDate(3, baseDate);
      expect(day3Date, equals(DateTime(2024, 1, 3)));
      
      // Test Day 7 visit (4 days after day 3)
      final day7Date = bloc.calculateHbncVisitDate(7, baseDate);
      expect(day7Date, equals(DateTime(2024, 1, 5)));
      
      // Test Day 14 visit (7 days after day 7)
      final day14Date = bloc.calculateHbncVisitDate(14, baseDate);
      expect(day14Date, equals(DateTime(2024, 1, 8)));
      
      // Test Day 21 visit (7 days after day 14)
      final day21Date = bloc.calculateHbncVisitDate(21, baseDate);
      expect(day21Date, equals(DateTime(2024, 1, 15)));
      
      // Test Day 28 visit (7 days after day 21)
      final day28Date = bloc.calculateHbncVisitDate(28, baseDate);
      expect(day28Date, equals(DateTime(2024, 1, 22)));
      
      // Test Day 42 visit (14 days after day 28)
      final day42Date = bloc.calculateHbncVisitDate(42, baseDate);
      expect(day42Date, equals(DateTime(2024, 2, 5)));
    });

    test('should handle null base date by using current date', () {
      final beforeCalculation = DateTime.now();
      final result = bloc.calculateHbncVisitDate(1, null);
      final afterCalculation = DateTime.now();
      
      expect(result, isNotNull);
      expect(result!.isAfter(beforeCalculation.subtract(const Duration(seconds: 1))), true);
      expect(result.isBefore(afterCalculation.add(const Duration(seconds: 1))), true);
    });

    test('should handle unknown visit numbers with default 7 days', () {
      final baseDate = DateTime(2024, 1, 1);
      final unknownVisitDate = bloc.calculateHbncVisitDate(99, baseDate);
      
      expect(unknownVisitDate, equals(DateTime(2024, 1, 8))); // 7 days after base date
    });
  });
}
