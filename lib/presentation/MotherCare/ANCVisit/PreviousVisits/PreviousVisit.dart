import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

class Previousvisit extends StatefulWidget {
  const Previousvisit({super.key});

  @override
  State<Previousvisit> createState() => _PreviousvisitState();
}

class _PreviousvisitState extends State<Previousvisit> {
  // Replace with real data source
  final List<Map<String, String>> _visits = [
    {'date': '16-09-2025', 'week': '12', 'risk': 'No'},
    {'date': '21-10-2025', 'week': '16', 'risk': 'Yes'},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Previous Visits',
        showBack: false,
        icon1: Icons.close,
        onIcon1Tap: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(child: Text('Sr No.', style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Visit Date', style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Pregnancy Week', style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(child: Text('High Risk', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemBuilder: (context, index) {
                  final row = _visits[index];
                  return Material(
                    elevation: 1,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text('${index + 1}')),
                          Expanded(child: Text(row['date'] ?? '-')),
                          Expanded(child: Text(row['week'] ?? '-')),
                          Expanded(child: Text(row['risk'] ?? '-')),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: _visits.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
