import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

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
    _loadTrainingData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadTrainingData() async {
    try {
      final rows = await LocalStorageDao.instance.fetchTrainingList();

      final List<Map<String, dynamic>> parsed = [];
      for (final row in rows) {
        try {
          final formJson = row['form_json'];
          if (formJson is! Map) continue;
          final data = formJson['form_data'];
          if (data is! Map) continue;

          final trainingType = (data['training_type'] ?? '').toString();
          if (trainingType != 'Receiving') continue;

          final trainingName = (data['training_name'] ?? '').toString();
          final rawDate = data['training_date']?.toString();
          String dateStr = '';
          if (rawDate != null && rawDate.isNotEmpty) {
            try {
              final parsedDate = DateTime.tryParse(rawDate);
              if (parsedDate != null) {
                dateStr = DateFormat('dd-MM-yyyy').format(parsedDate);
              } else {
                dateStr = rawDate;
              }
            } catch (_) {
              dateStr = rawDate;
            }
          }

          final hhIdRaw = (row['household_ref_key'] ?? '').toString();
          final hhId = hhIdRaw.isNotEmpty ? hhIdRaw : 'N/A';
          final displayHhId = hhId.length > 11
              ? hhId.substring(hhId.length - 11)
              : hhId;

          parsed.add({
            'hhId': displayHhId,
            'trainingName': trainingName,
            'Date': dateStr,
          });
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;
      setState(() {
        _allData = parsed;
        _filtered = List.from(parsed);
        _isLoading = false;
      });
    } catch (_) {}
  }

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

  bool _isLoading = true;

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
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _filtered.isEmpty
                ? Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                height: 110, // 👈 fixed height
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 20.0,
                      ),
                      child: Center(
                        child: Text(
                          l10n?.noRecordFound ?? 'No Record Found',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
                : ListView.builder(
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
    final l10n = AppLocalizations.of(context);

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
                    _rowText(
                      "${l10n?.trainingNameLabel}:" ?? "Training Name:",
                      data['trainingName'] ?? '',
                    ),
                    const SizedBox(height: 6),
                    _rowText(
                      "${l10n?.dateLabel}:" ?? "Date:",
                      data['Date'] ?? '',
                    ),
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
