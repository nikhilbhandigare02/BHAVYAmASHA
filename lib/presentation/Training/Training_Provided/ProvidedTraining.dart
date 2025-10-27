import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class TrainingProvided extends StatefulWidget {
  const TrainingProvided({super.key});

  @override
  State<TrainingProvided> createState() =>
      _TrainingProvidedState();
}

class _TrainingProvidedState
    extends State<TrainingProvided> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',

      'Date': '16-10-2025',
      'trainingName': 'ASHA module 2',

    },

  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
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
        _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
      } else {
        _filtered = _staticHouseholds.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['trainingName'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
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
                    const Icon(Icons.school, color: Colors.black54, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['hhId'] ?? '',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
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
                      l10n?.trainingNameLabel ?? 'Training Name',
                      data['trainingName'] ?? '',
                    ),
                    const SizedBox(height: 6),
                    _rowText(
                       l10n?.trainingDateLabel ?? 'Training Date',
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
          "${title} :",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          "${value}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
