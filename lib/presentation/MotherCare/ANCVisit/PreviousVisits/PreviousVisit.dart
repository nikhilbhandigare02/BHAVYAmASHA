import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class Previousvisit extends StatefulWidget {
  final String beneficiaryId;
  const Previousvisit({super.key, required this.beneficiaryId});

  @override
  State<Previousvisit> createState() => _PreviousvisitState();
}

class _PreviousvisitState extends State<Previousvisit> {
  List<Map<String, String>> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final rows = await LocalStorageDao.instance
        .getAncFormsByBeneficiaryId(widget.beneficiaryId);

    final list = <Map<String, String>>[];

    for (final r in rows.reversed) { // 👈 reverse here
      final fd = r['form_data'] is Map<String, dynamic>
          ? (r['form_data'] as Map<String, dynamic>)
          : {};

      String dateRaw = fd['date_of_inspection']?.toString() ?? '';
      if (dateRaw.isEmpty) {
        dateRaw = r['created_date_time']?.toString() ?? '';
      }

      String created = '-';

      try {
        final dt = DateTime.parse(dateRaw);
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        created = '$d-$m-$y';
      } catch (_) {
        created = dateRaw.isEmpty ? '-' : dateRaw;
      }

      String week = fd['weeks_of_pregnancy']?.toString() ?? '';
      if (week.trim().isEmpty) week = '-';

      String risk = fd['high_risk']?.toString() ?? '';
      if (risk.trim().isEmpty) risk = '-';

      list.add({'date': created, 'week': week, 'risk': risk});
    }

    setState(() {
      _visits = list;
      _loading = false;
    });
  }

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
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Sr No.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Visit Date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Pregnancy Week',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'High Risk',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
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
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    row['date'] ?? '-',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    row['week'] ?? '-',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    row['risk'] ?? '-',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ),
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
