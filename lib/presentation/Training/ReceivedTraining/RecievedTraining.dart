import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';

class TrainingReceived extends StatefulWidget {
  const TrainingReceived({super.key});

  @override
  State<TrainingReceived> createState() => _TrainingReceivedState();
}

class _TrainingReceivedState extends State<TrainingReceived> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    // _loadTrainingData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  // Future<void> _loadTrainingData() async {
  //   final List<Map<String, dynamic>> rows =
  //   await LocalStorageDao.instance.fetchTrainingList();
  //
  //   final parsed = rows.map((row) {
  //     final formJson = row['form_json'];
  //     final decoded = jsonDecode(formJson);
  //
  //     final data = decoded['form_data'];
  //
  //     return {
  //       'hhId': "N/A",
  //       'trainingName': data['training_name'] ?? '',
  //       'Date': data['training_date']?.toString().split('T').first ?? '',
  //     };
  //   }).toList();
  //
  //   setState(() {
  //     _allData = parsed;
  //     _filtered = List.from(parsed);
  //   });
  // }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _allData.where((e) {
        return e['trainingName'].toLowerCase().contains(q) ||
            e['Date'].toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.trainingReceivedTitle ?? "Training Received",
        showBack: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                return _householdCard(context, _filtered[index]);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Icon(Icons.home, color: primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['hhId'] ?? '',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowText("Training Name:", data['trainingName'] ?? ''),
                    const SizedBox(height: 6),
                    _rowText("Date:", data['Date'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowText(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
