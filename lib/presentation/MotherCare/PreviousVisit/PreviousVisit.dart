import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class PreviousVisitScreen extends StatefulWidget {
  const PreviousVisitScreen({super.key});

  @override
  State<PreviousVisitScreen> createState() => _PreviousVisitScreenState();
}

class _PreviousVisitScreenState extends State<PreviousVisitScreen> {
  // Minimal PNC-style data matching the screenshot
  final List<Map<String, dynamic>> _pncVisits = const [
    { 'date': '12-01-2024', 'day': 1 },
    // Add more rows if needed
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(
        screenTitle: t.previousVisits,
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeader(t: t),
            const SizedBox(height: 8),
            ..._pncVisits.asMap().entries.map((e) => _TableRowItem(
                  index: e.key + 1,
                  date: e.value['date'].toString(),
                  day: e.value['day'].toString(),
                )),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.t});
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0,1))],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(t.prevVisitSrNo, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 6, child: Text(t.prevVisitPncDate, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 4, child: Text(t.prevVisitPncDay, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  const _TableRowItem({required this.index, required this.date, required this.day});
  final int index;
  final String date;
  final String day;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0,1))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text('$index')),
            Expanded(flex: 6, child: Text(date)),
            Expanded(flex: 4, child: Text(day)),
          ],
        ),
      ),
    );
  }}
