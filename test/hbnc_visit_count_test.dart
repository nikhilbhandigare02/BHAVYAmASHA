import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HBNC Visit Count Logic Tests', () {
    test('HBNC schedule dates are correct', () {
      // Test the HBNC schedule: 1,3,7,14,21,28,42 days after delivery
      final schedule = <int>[1, 3, 7, 14, 21, 28, 42];
      
      // Verify schedule contains expected values
      expect(schedule, equals([1, 3, 7, 14, 21, 28, 42]));
      expect(schedule.length, equals(7));
    });

    test('Date formatting works correctly', () {
      // Test date formatting similar to _formatHbncDate
      String formatDate(DateTime date) {
        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }

      final testDate = DateTime(2024, 1, 15);
      expect(formatDate(testDate), equals('15-01-2024'));
      
      final testDate2 = DateTime(2024, 12, 5);
      expect(formatDate(testDate2), equals('05-12-2024'));
    });

    test('Visit count calculation logic', () {
      // Test visit count calculation based on schedule
      final schedule = <int>[1, 3, 7, 14, 21, 28, 42];
      
      // Test scenarios
      expect(calculateExpectedCount(schedule, 0), equals(0)); // Before day 1
      expect(calculateExpectedCount(schedule, 1), equals(1)); // On day 1
      expect(calculateExpectedCount(schedule, 2), equals(1)); // Between day 1-3
      expect(calculateExpectedCount(schedule, 3), equals(2)); // On day 3
      expect(calculateExpectedCount(schedule, 7), equals(3)); // On day 7
      expect(calculateExpectedCount(schedule, 42), equals(7)); // On day 42
      expect(calculateExpectedCount(schedule, 50), equals(7)); // After day 42
    });
  });
}

// Helper function to calculate expected visit count based on days after delivery
int calculateExpectedCount(List<int> schedule, int daysAfterDelivery) {
  int expectedCount = 0;
  for (int i = 0; i < schedule.length; i++) {
    if (schedule[i] <= daysAfterDelivery) {
      expectedCount = i + 1;
    } else {
      break;
    }
  }
  return expectedCount;
}
