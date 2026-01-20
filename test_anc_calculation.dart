import 'dart:io';

void main() {
  print('=== ANC Date Calculation Test ===\n');
  
  // Test with a sample LMP date (12 weeks ago from today)
  final today = DateTime.now();
  final lmpDate = today.subtract(Duration(days: 12 * 7)); // 12 weeks ago
  
  print('Today: ${_formatDate(today)}');
  print('LMP Date: ${_formatDate(lmpDate)}');
  print('');
  
  // Calculate ANC ranges using the same logic as the app
  final ranges = _calculateAncDateRanges(lmpDate);
  
  print('ANC Windows:');
  print('1st ANC: ${_formatDate(ranges['1st_anc_start']!)} to ${_formatDate(ranges['1st_anc_end']!)}');
  print('2nd ANC: ${_formatDate(ranges['2nd_anc_start']!)} to ${_formatDate(ranges['2nd_anc_end']!)}');
  print('3rd ANC: ${_formatDate(ranges['3rd_anc_start']!)} to ${_formatDate(ranges['3rd_anc_end']!)}');
  print('4th ANC: ${_formatDate(ranges['4th_anc_start']!)} to ${_formatDate(ranges['4th_anc_end']!)}');
  print('');
  
  // Check which window today falls in
  final todayDate = DateTime(today.year, today.month, today.day);
  
  bool isTodayInsideWindow(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (todayDate.isAtSameMomentAs(s) || todayDate.isAfter(s)) &&
           (todayDate.isAtSameMomentAs(e) || todayDate.isBefore(e));
  }
  
  print('Window Checks:');
  if (isTodayInsideWindow(ranges['1st_anc_start']!, ranges['1st_anc_end']!)) {
    print('✅ Today is within 1st ANC window');
  } else if (isTodayInsideWindow(ranges['2nd_anc_start']!, ranges['2nd_anc_end']!)) {
    print('✅ Today is within 2nd ANC window');
  } else if (isTodayInsideWindow(ranges['3rd_anc_start']!, ranges['3rd_anc_end']!)) {
    print('✅ Today is within 3rd ANC window');
  } else if (isTodayInsideWindow(ranges['4th_anc_start']!, ranges['4th_anc_end']!)) {
    print('✅ Today is within 4th ANC window');
  } else {
    final fourthEndDateOnly = DateTime(ranges['4th_anc_end']!.year, ranges['4th_anc_end']!.month, ranges['4th_anc_end']!.day);
    if (todayDate.isAfter(fourthEndDateOnly)) {
      print('✅ Today is after 4th ANC window (overdue)');
    } else {
      print('❌ Today is not within any ANC window');
    }
  }
}

DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
  final days = noOfWeeks * 7;
  return startDate.add(Duration(days: days));
}

DateTime _calculateEdd(DateTime lmp) {
  return _dateAfterWeeks(lmp, 40);
}

Map<String, DateTime> _calculateAncDateRanges(DateTime lmp) {
  final ranges = <String, DateTime>{};

  ranges['1st_anc_start'] = lmp;
  ranges['1st_anc_end'] = _dateAfterWeeks(lmp, 12);

  ranges['2nd_anc_start'] = _dateAfterWeeks(lmp, 14);
  ranges['2nd_anc_end'] = _dateAfterWeeks(lmp, 24);
  ranges['3rd_anc_start'] = _dateAfterWeeks(lmp, 26);
  ranges['3rd_anc_end'] = _dateAfterWeeks(lmp, 34);

  ranges['4th_anc_start'] = _dateAfterWeeks(lmp, 36);
  ranges['4th_anc_end'] = _calculateEdd(lmp);

  ranges['pmsma_start'] = ranges['1st_anc_end']!.add(const Duration(days: 1));
  ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(const Duration(days: 1));

  return ranges;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}
