import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/models/anc_visit_model.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class Abortionlist extends StatefulWidget {
  const Abortionlist({super.key});

  @override
  State<Abortionlist> createState() => _AbortionlistState();
}

class _AbortionlistState extends State<Abortionlist> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ANCVisitModel> _ancVisits = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadANCVisits();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadANCVisits() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final dbForms = await LocalStorageDao.instance.getAbortionFollowupForms();

      print('Total records fetched: ${dbForms.length}');

      final List<ANCVisitModel> abortionVisits = [];

      for (final row in dbForms) {
        try {
          final formData = row['form_data'] as Map<String, dynamic>;

          final beneficiaryData = row['beneficiary_data'] as Map<String, dynamic>?;
          final beneficiaryInfo = beneficiaryData?['beneficiary_info'] as Map<String, dynamic>? ?? {};

          final dobStr = beneficiaryInfo['dob']?.toString();
          final gender = beneficiaryInfo['gender']?.toString() ?? formData['gender'] ?? 'Female';

          final visitData = {
            'id': row['beneficiary_ref_key']?.toString(),
            'hhId': beneficiaryData?['household_ref_key']?.toString(),
            'house_number': formData['house_no'] ?? formData['house_number'],
            'woman_name': (beneficiaryInfo['memberName'] ??
                beneficiaryInfo['name'] ??
                beneficiaryInfo['headName'] ??
                beneficiaryInfo['spouseName'] ??
                formData['pw_name'])
                ?.toString(),
            'husband_name':
            (beneficiaryInfo['spouseName'] ?? formData['husband_name'])
                ?.toString(),
            'rch_number': formData['rch_reg_no_of_pw'] ?? formData['rch_number'],
            'visit_type': formData['visit_type'],
            'high_risk': (formData['is_high_risk'] == 'yes') || (formData['high_risk'] == true),
            'date_of_inspection': formData['date_of_inspection'],
            'edd_date': formData['edd_date'],
            'weeks_of_pregnancy': formData['week_of_pregnancy'] ?? formData['weeks_of_pregnancy'],
            'weight': formData['weight'],
            'hemoglobin': formData['hemoglobin'],
            'pre_existing_disease': formData['pre_exist_desease'] ?? formData['pre_existing_disease'],
            'mobileNumber': formData['mobile_number'] ?? formData['contact_number'],
            'date_of_birth': dobStr,
            'gender': gender,
            'has_abortion_complication': true,
            'abortion_date': formData['date_of_abortion'] ?? formData['abortion_date'],
            'fp_method': formData['fp_method'],
            'is_family_planning': formData['is_family_planning'],
            'is_family_planning_counselling': formData['is_family_planning_counselling'],
          };

          abortionVisits.add(ANCVisitModel.fromJson(visitData));
          print('Added abortion visit for: ${formData['pw_name']}');
        } catch (e) {
          print('Error mapping abortion row: $e');
        }
      }

      print('Total abortion visits found: ${abortionVisits.length}'); // Debug log

      if (abortionVisits.isEmpty) {
        setState(() {
          _ancVisits = [];
          _filteredVisits = [];
          _isLoading = false;
          _error = 'No abortion complication cases found';
        });
        return;
      }

      abortionVisits.sort((a, b) {
        if (a.abortionDate == null) return 1;
        if (b.abortionDate == null) return -1;
        return b.abortionDate!.compareTo(a.abortionDate!);
      });

      setState(() {
        _ancVisits = abortionVisits;
        _filteredVisits = List.from(_ancVisits);
        _isLoading = false;
        if (_ancVisits.isEmpty) {
          _error = 'No abortion complication cases found';
        }
      });
    } catch (e) {
      print('Error loading ANC visits: $e');
      setState(() {
        _error = 'Failed to load ANC visits: $e';
        _isLoading = false;
      });
    }
  }
  List<ANCVisitModel> _filteredVisits = [];

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVisits = List.from(_ancVisits);
      } else {
        _filteredVisits = _ancVisits.where((visit) {
          return (visit.houseNumber?.toLowerCase().contains(query) ?? false) ||
              (visit.womanName?.toLowerCase().contains(query) ?? false) ||
              (visit.rchNumber?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }


  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayVisits = _searchCtrl.text.isEmpty ? _ancVisits : _filteredVisits;

    return Scaffold(
      appBar: AppHeader(
        screenTitle:l10n!.abortionList,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          // else if (_error.isNotEmpty)
          //   Expanded(
          //     child: Center(
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           const Icon(Icons.error_outline, color: Colors.red, size: 48),
          //           const SizedBox(height: 16),
          //           Text(
          //             _error,
          //             style: const TextStyle(color: Colors.red),
          //             textAlign: TextAlign.center,
          //           ),
          //           const SizedBox(height: 16),
          //           ElevatedButton(
          //             onPressed: _loadANCVisits,
          //             child: const Text('Retry'),
          //           ),
          //         ],
          //       ),
          //     ),
          //   )
          else if (displayVisits.isEmpty)
            Padding(
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
                        l10n?.noRecordFound ?? 'No Record Found',
                        style: TextStyle(
                          fontSize: 17.sp,
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
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: displayVisits.length,
                  itemBuilder: (context, index) {
                    return _ancVisitCard(context, displayVisits[index]);
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _ancVisitCard(BuildContext context, ANCVisitModel visit) {
    final Color primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () {

      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with house ID and status
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, color: AppColors.primary, size: 14.sp),
                      const SizedBox(width: 6),
                      Text(
                        (visit.hhId != null && visit.hhId!.length > 11)
                            ? '${visit.hhId!.substring(visit.hhId!.length - 11)}'
                            : visit.hhId ?? 'N/A',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),


                ],
              ),
            ),

            // Body with beneficiary details
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _infoRow(
                    '',
                    visit.womanName ?? l10n!.na,
                    textStyle:  TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),


                  Row(

                    children: [
                      if (visit.formattedAge.isNotEmpty || visit.displayGender.isNotEmpty)
                        Text(
                          '${visit.formattedAge} ${visit.displayGender.isNotEmpty ? '| ${visit.displayGender}' : ''}'.trim(),
                          style:  TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      if (visit.abortionDate != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 80.0),
                          child: Text(
                            'Abortion Date: ${_formatDate(visit.abortionDate!)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,

                            ),
                          ),
                        ),
                    ],
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Widget _infoRow(String title, String value,
      {bool isWrappable = false, TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment:
        isWrappable ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            title.isEmpty ? '' : '$title: ',
            style:  TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: textStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
              softWrap: isWrappable,
              overflow:
              isWrappable ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
                l10n?.noRecordFound ?? 'No Record Found',
                style: TextStyle(
                  fontSize: 17.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
