import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EDD Calculation Tests', () {
    test('EDD calculation using 277 days (same as SpousDetails)', () {
      // Test case: LMP on January 1, 2024
      final lmpDate = DateTime(2024, 1, 1);
      
      // Calculate EDD using the same logic as SpousDetails
      final edd = lmpDate.add(const Duration(days: 277));
      
      // Expected: October 5, 2024 (277 days after January 1)
      final expectedEdd = DateTime(2024, 10, 5);
      
      print('LMP Date: $lmpDate');
      print('EDD Calculated: $edd');
      print('EDD Expected: $expectedEdd');
      print('Days difference: ${edd.difference(lmpDate).inDays}');
      
      expect(edd.year, equals(expectedEdd.year));
      expect(edd.month, equals(expectedEdd.month));
      expect(edd.day, equals(expectedEdd.day));
      expect(edd.difference(lmpDate).inDays, equals(277));
    });
    
    test('EDD calculation comparison between old and new methods', () {
      final lmpDate = DateTime(2024, 1, 1);
      
      // Old method: 8 months + 10 days
      int year = lmpDate.year;
      int month = lmpDate.month + 8;
      if (month > 12) {
        year += (month - 1) ~/ 12;
        month = ((month - 1) % 12) + 1;
      }
      final oldBase = DateTime(year, month, lmpDate.day);
      final oldEdd = oldBase.add(const Duration(days: 10));
      
      // New method: 277 days
      final newEdd = lmpDate.add(const Duration(days: 277));
      
      print('LMP Date: $lmpDate');
      print('Old EDD (8 months + 10 days): $oldEdd');
      print('New EDD (277 days): $newEdd');
      print('Difference: ${newEdd.difference(oldEdd).inDays} days');
      
      // The new method should give a slightly different date
      expect(newEdd, isNot(equals(oldEdd)));
    });
  });
}
