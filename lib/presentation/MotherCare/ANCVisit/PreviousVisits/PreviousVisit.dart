import 'package:flutter/material.dart';
import 'dart:convert' show jsonDecode;
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';

class Previousvisit extends StatefulWidget {
  final String beneficiaryId;
  const Previousvisit({super.key, required this.beneficiaryId});

  @override
  State<Previousvisit> createState() => _PreviousvisitState();
}

class _PreviousvisitState extends State<Previousvisit> {
  List<Map<String, String>> _visits = [];
  bool _loading = true;

  int _calculateWeeksOfPregnancy(DateTime? lmpDate, DateTime? visitDate) {
    if (lmpDate == null) return 0;
    final base = visitDate ?? DateTime.now();
    final difference = base.difference(lmpDate).inDays;
    return (difference / 7).floor() + 1;
  }

  // Extract LMP date from followup forms if week is missing
  Future<DateTime?> _getLmpFromFollowupForms(String beneficiaryId) async {
    try {
      // Get beneficiary info to extract household ID
      final beneficiaries = await LocalStorageDao.instance.getAllBeneficiaries();
      String? hhId;
      
      for (final beneficiary in beneficiaries) {
        if (beneficiary['unique_key']?.toString() == beneficiaryId) {
          hhId = beneficiary['household_ref_key']?.toString();
          break;
        }
      }
      
      if (hhId == null || hhId.isEmpty) {
        print('⚠️ Could not find household ID for beneficiary: $beneficiaryId');
        return null;
      }

      final dao = LocalStorageDao();
      final forms = await dao.getFollowupFormsByHouseholdAndBeneficiary(
        formType: FollowupFormDataTable.eligibleCoupleTrackingDue,
        householdId: hhId,
        beneficiaryId: beneficiaryId,
      );

      if (forms.isEmpty) {
        print('ℹ️ No eligible couple tracking due forms found for beneficiary');
        return null;
      }

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
          
          // Check for LMP date in eligible_couple_tracking_due_from structure
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final lmpStr = trackingData['lmp_date']?.toString();
            if (lmpStr != null && lmpStr.isNotEmpty && lmpStr != '""') {
              try {
                final lmpDate = DateTime.parse(lmpStr);
                print('✅ Found LMP date from followup form: $lmpDate');
                return lmpDate;
              } catch (e) {
                print('⚠️ Error parsing LMP date: $e');
              }
            }
          }
          
          // Check for LMP date in form_data structure
          if (root['form_data'] is Map) {
            final formData = root['form_data'] as Map<String, dynamic>;
            final lmpStr = formData['lmp_date']?.toString();
            if (lmpStr != null && lmpStr.isNotEmpty && lmpStr != '""') {
              try {
                String dateStr = lmpStr;
                if (dateStr.contains('T')) {
                  try {
                    final lmpDate = DateTime.parse(dateStr);
                    print('✅ Found LMP date from form_data: $lmpDate');
                    return lmpDate;
                  } catch (e) {
                    dateStr = dateStr.split('T')[0];
                    print('⚠️ Full date parsing failed, trying date part only: $dateStr');
                  }
                }
                
                final lmpDate = DateTime.parse(dateStr);
                print('✅ Found LMP date from form_data: $lmpDate');
                return lmpDate;
              } catch (e) {
                print('⚠️ Error parsing LMP date from form_data: $e');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error parsing followup form JSON: $e');
        }
      }
      
      print('ℹ️ No LMP date found in any eligible couple tracking due forms');
      return null;
    } catch (e) {
      print('❌ Error loading LMP from followup forms: $e');
      return null;
    }
  }

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
      final fd = r['anc_form'] is Map<String, dynamic>
          ? (r['anc_form'] as Map<String, dynamic>)
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

      String week = fd['week_of_pregnancy']?.toString() ?? '';
      if (week.trim().isEmpty || week == '-') {
        // Try to calculate week from LMP date if not available in form data
        final lmpDate = await _getLmpFromFollowupForms(widget.beneficiaryId);
        if (lmpDate != null) {
          // Use the visit date for calculation if available, otherwise current date
          DateTime? visitDate;
          try {
            visitDate = DateTime.parse(dateRaw);
          } catch (_) {
            visitDate = null;
          }
          
          final calculatedWeeks = _calculateWeeksOfPregnancy(lmpDate, visitDate);
          week = calculatedWeeks.toString();
          print('✅ Calculated week of pregnancy: $week from LMP: $lmpDate');
        } else {
          week = '-';
        }
      }

      String risk = fd['is_high_risk']?.toString() ?? '';
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
