import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class TrainingProvided extends StatefulWidget {
  const TrainingProvided({super.key});

  @override
  State<TrainingProvided> createState() =>
      _TrainingProvidedState();
}

class _TrainingProvidedState
    extends State<TrainingProvided> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadTrainingData();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_allData);
      } else {
        _filtered = _allData.where((e) {
          final id = (e['hhId'] ?? '').toString().toLowerCase();
          final name = (e['trainingName'] ?? '').toString().toLowerCase();
          final date = (e['Date'] ?? '').toString().toLowerCase();
          return id.contains(q) || name.contains(q) || date.contains(q);
        }).toList();
      }
    });
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
          if (trainingType != 'Providing') continue;

          final trainingName = (data['training_name'] ?? '').toString();
          final rawDate = data['training_date']?.toString();
          String dateStr = '';
          if (rawDate != null && rawDate.isNotEmpty) {
            try {
              final parsedDate = DateTime.tryParse(rawDate);
              if (parsedDate != null) {
                dateStr = DateFormat('dd/MM/yyyy').format(parsedDate);
              } else {
                dateStr = rawDate;
              }
            } catch (_) {
              dateStr = rawDate;
            }
          }

          final hhIdRaw = (row['household_ref_key'] ?? '').toString();
          final hhId = hhIdRaw.isNotEmpty ? hhIdRaw : 'N/A';
          final displayHhId = hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId;

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
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.trainingProvidedTitle ?? 'Training Provided',
        showBack: true,


      ),
      body: Column(
        children: [
          // Search


          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final data = _filtered[index];
                return _householdCard(context, data);
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
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
              // Header
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
                          fontSize: 14.sp
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowText(
                      l10n?.trainingNameLabel ?? 'Training Name:',
                      data['trainingName'] ?? '',
                    ),
                    const SizedBox(height: 6),
                    _rowText(
                       l10n?.trainingDateLabel ?? 'Date:',
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
          style:  TextStyle(color: AppColors.background, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 14.sp),
        ),
      ],
    );
  }
}
