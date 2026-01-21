import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'dart:convert';

class PreviousVisitScreen extends StatefulWidget {
  final String beneficiaryId;

  const PreviousVisitScreen({super.key, required this.beneficiaryId});

  @override
  State<PreviousVisitScreen> createState() => _PreviousVisitScreenState();
}

class _PreviousVisitScreenState extends State<PreviousVisitScreen> {
  List<Map<String, String>> _pncVisits = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Method to check high risk from form_json
  bool _checkHighRiskFromFormJson(String? formJson) {
    if (formJson == null || formJson.isEmpty) return false;
    
    try {
      final Map<String, dynamic> jsonData = json.decode(formJson);
      
      // Check different possible structures for high risk indicators
      // Case 1: Direct form_data structure
      if (jsonData.containsKey('form_data')) {
        final formData = jsonData['form_data'] as Map<String, dynamic>?;
        if (formData != null) {
          // Check for high_risk field
          if (formData.containsKey('high_risk')) {
            final highRisk = formData['high_risk']?.toString().toLowerCase();
            if (highRisk == 'yes') return true;
          }
          
          // Check for is_high_risk field
          if (formData.containsKey('is_high_risk')) {
            final isHighRisk = formData['is_high_risk']?.toString().toLowerCase();
            if (isHighRisk == 'yes') return true;
          }
        }
      }
      
      // Case 2: anc_form structure
      if (jsonData.containsKey('anc_form')) {
        final ancForm = jsonData['anc_form'] as Map<String, dynamic>?;
        if (ancForm != null) {
          // Check for is_high_risk field
          if (ancForm.containsKey('is_high_risk')) {
            final isHighRisk = ancForm['is_high_risk']?.toString().toLowerCase();
            if (isHighRisk == 'yes') return true;
          }
          
          // Check for high_risk field
          if (ancForm.containsKey('high_risk')) {
            final highRisk = ancForm['high_risk']?.toString().toLowerCase();
            if (highRisk == 'yes') return true;
          }
        }
      }
      
      // Case 3: Direct structure (no nested form_data or anc_form)
      if (jsonData.containsKey('high_risk')) {
        final highRisk = jsonData['high_risk']?.toString().toLowerCase();
        if (highRisk == 'yes') return true;
      }
      
      if (jsonData.containsKey('is_high_risk')) {
        final isHighRisk = jsonData['is_high_risk']?.toString().toLowerCase();
        if (isHighRisk == 'yes') return true;
      }
      
    } catch (e) {
      print('Error parsing form JSON: $e');
    }
    
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // Fetch ANC Mother follow-up forms for this beneficiary (form_ref_key = 'bt7gs9rl1a5d26mz')
      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
            'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [
          widget.beneficiaryId,
          'bt7gs9rl1a5d26mz', // ANC form key
        ],
        orderBy: 'datetime(created_date_time) ASC',
      );

      final List<Map<String, String>> visits = [];

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final rawDate = row['created_date_time']?.toString() ?? '';
        final formJson = row['form_json']?.toString();

        String formattedDate = rawDate;
        if (rawDate.isNotEmpty) {
          try {
            final dt = DateTime.parse(rawDate);
            final d = dt.day.toString().padLeft(2, '0');
            final m = dt.month.toString().padLeft(2, '0');
            final y = dt.year.toString();
            formattedDate = '$d-$m-$y';
          } catch (_) {}
        }

        // Check for high risk from form_json
        final isHighRisk = _checkHighRiskFromFormJson(formJson);
        final highRiskStatus = isHighRisk ? 'Yes' : 'No';

        visits.add({
          'date': formattedDate.isEmpty ? '-' : formattedDate,
          'visit_number': (i + 1).toString(),
          'high_risk': highRiskStatus,
        });
      }

      if (!mounted) return;

      setState(() {
        _pncVisits = visits;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load previous visits';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(
        screenTitle: t.previousVisitsButtonS,
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _pncVisits.isEmpty
                        ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t?.noRecordFound ?? 'No Record Found',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TableHeader(t: t),
                              const SizedBox(height: 8),
                              ..._pncVisits.asMap().entries.map(
                                    (e) => _TableRowItem(
                                      index: e.key + 1,
                                      date: e.value['date'] ?? '-',
                                      visitNumber: e.value['visit_number'] ?? '-',
                                      highRisk: e.value['high_risk'] ?? 'No',
                                    ),
                                  ),
                            ],
                          ),
          ),
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
            Expanded(flex: 2, child: Text(t.srNo, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 4, child: Text('Visit No', style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 4, child: Text('Date', style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 3, child: Text('High Risk', style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _TableRowItem extends StatelessWidget {
  const _TableRowItem({required this.index, required this.date, required this.visitNumber, required this.highRisk});
  final int index;
  final String date;
  final String visitNumber;
  final String highRisk;

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
            Expanded(flex: 4, child: Text(visitNumber)),
            Expanded(flex: 4, child: Text(date)),
            Expanded(
              flex: 3, 
              child: Text(
                highRisk,
                style: TextStyle(
                  color: highRisk.toLowerCase() == 'yes' ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
