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

class HighRisk extends StatefulWidget {
  const HighRisk({super.key});

  @override
  State<HighRisk> createState() => _EligibleCoupleListState();
}

class _EligibleCoupleListState extends State<HighRisk> {
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

      final dbForms = await LocalStorageDao.instance.getHighRiskANCVisits();
      final List<ANCVisitModel> highRiskVisits = [];

      for (final entry in dbForms) {
        try {
          final formData = Map<String, dynamic>.from(entry['form_data'] as Map);
          final beneficiaryKey = entry['beneficiary_ref_key']?.toString() ?? '';

          if (beneficiaryKey.isEmpty) continue;

          final rawHhId = entry['household_ref_key']?.toString() ??
              entry['beneficiary_data']?['household_ref_key']?.toString() ??
              formData['household_ref_key']?.toString() ??
              '';

          final hhId = rawHhId.isNotEmpty
              ? rawHhId.length > 11
              ? rawHhId.substring(rawHhId.length - 11)
              : rawHhId
              : 'N/A';

          // Get beneficiary info
          final beneficiaryData = entry['beneficiary_data'] is Map
              ? Map<String, dynamic>.from(entry['beneficiary_data'])
              : <String, dynamic>{};

          // Parse beneficiary info if it's a string
          if (beneficiaryData['beneficiary_info'] is String) {
            try {
              beneficiaryData['beneficiary_info'] = jsonDecode(
                beneficiaryData['beneficiary_info'],
              ) as Map<String, dynamic>? ?? {};
            } catch (e) {
              debugPrint('Error parsing beneficiary_info: $e');
              beneficiaryData['beneficiary_info'] = {};
            }
          }

          Map<String, dynamic>? spouseData;
          if (entry['spouse_data'] != null) {
            spouseData = Map<String, dynamic>.from(entry['spouse_data']);
            if (spouseData!['beneficiary_info'] is String) {
              try {
                spouseData['beneficiary_info'] = jsonDecode(
                  spouseData['beneficiary_info'],
                ) as Map<String, dynamic>? ?? {};
              } catch (e) {
                debugPrint('Error parsing spouse beneficiary_info: $e');
                spouseData['beneficiary_info'] = {};
              }
            }
          }

          final visitData = {
            'id': beneficiaryKey,
            'hhId': hhId,
            'house_number': formData['house_number'] ?? '',
            'woman_name': formData['woman_name'] ??
                beneficiaryData['beneficiary_info']?['name'] ??
                '',
            'husband_name': formData['husband_name'] ??
                spouseData?['beneficiary_info']?['name'] ??
                '',
            'rch_number': formData['rch_number'] ?? '',
            'visit_type': formData['visit_type'] ?? '',
            'high_risk': true,
            'date_of_inspection': formData['date_of_inspection'] ?? '',
            'edd_date': formData['edd_date'] ?? '',
            'weeks_of_pregnancy': formData['weeks_of_pregnancy']?.toString() ?? '',
            'weight': formData['weight']?.toString() ?? '',
            'hemoglobin': formData['hemoglobin']?.toString() ?? '',
            'pre_existing_disease': formData['pre_existing_disease'] ?? '',
            'mobileNumber': formData['mobile_number'] ??
                formData['contact_number'] ??
                beneficiaryData['beneficiary_info']?['mobile_number'] ??
                beneficiaryData['beneficiary_info']?['contact_number'] ??
                '',
            'age': beneficiaryData['beneficiary_info']?['age']?.toString() ?? '',
            'date_of_birth': beneficiaryData['beneficiary_info']?['dob']?.toString() ?? '',
            'gender': beneficiaryData['beneficiary_info']?['gender']?.toString().toUpperCase() ?? 'F',
            'beneficiary_data': beneficiaryData,
            'spouse_data': spouseData,
          };

          highRiskVisits.add(ANCVisitModel.fromJson(visitData));
        } catch (e) {
          debugPrint('Error processing high-risk ANC entry: $e');
        }
      }

      setState(() {
        _ancVisits = highRiskVisits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading high-risk ANC visits: $e');
      setState(() {
        _error = 'Failed to load high-risk ANC visits';
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
        screenTitle: l10n?.highRisk ??"High-Risk Pregnancy List",
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadANCVisits,
                      child:  Text(l10n?.retry ?? "Retry"),
                    ),
                  ],
                ),
              ),
            )
          else if (displayVisits.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.no_high_risk_anc_visits_found ?? "No high-risk ANC visits found",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
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
        // Navigate to detail view if needed
        // Navigator.pushNamed(context, Route_Names.ANCDetail, arguments: visit);
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
                      Icon(Icons.home, color: Colors.black54, size: 14.sp),
                      const SizedBox(width: 6),
                      Text(
                        visit.hhId ?? l10n?.na ?? "N/A",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n?.hrp ?? "HRP",
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                  _infoRow(context,
                    '',
                    visit.womanName ?? (l10n?.no_name ?? "No Name"),
                    textStyle:  TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),

                  const SizedBox(height: 2),

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



  Widget _infoRow(BuildContext context,String title, String value,
      {bool isWrappable = false, TextStyle? textStyle}) {
    final l10n = AppLocalizations.of(context);

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
              value.isEmpty ? (l10n?.na ?? "N/A") : value,
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
}