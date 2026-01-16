import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // Fetch PNC Mother follow-up forms for this beneficiary
      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
            'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [
          widget.beneficiaryId,
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother],
        ],
        orderBy: 'datetime(created_date_time) ASC',
      );

      const visitDays = [1, 3, 7, 14, 21, 28, 42];
      final List<Map<String, String>> visits = [];

      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final rawDate = row['created_date_time']?.toString() ?? '';

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

        final dayNumber =
            i < visitDays.length ? visitDays[i].toString() : (i + 1).toString();

        visits.add({
          'date': formattedDate.isEmpty ? '-' : formattedDate,
          'day': dayNumber,
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
                                      day: e.value['day'] ?? '-',
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
