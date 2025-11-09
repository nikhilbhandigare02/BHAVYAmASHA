import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/models/anc_visit_model.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
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

      // Get high-risk beneficiary IDs from getAncVisits
      Map<String, dynamic> highRiskBeneficiaries = {};
      try {
        final storageVisits = await SecureStorageService.getAncVisits();
        for (var visit in storageVisits) {
          final beneficiaryId = visit['beneficiaryId']?.toString();
          final highRiskValue = visit['high_risk']?.toString().toLowerCase();
          final isHighRisk = highRiskValue == 'yes' ||
              highRiskValue == 'true' ||
              highRiskValue == '1';

          if (beneficiaryId != null && isHighRisk) {
            // Store the most recent visit for each high-risk beneficiary
            final visitDate = visit['date_of_inspection'] != null
                ? DateTime.tryParse(visit['date_of_inspection'].toString())
                : null;

            if (!highRiskBeneficiaries.containsKey(beneficiaryId) ||
                (visitDate != null &&
                    highRiskBeneficiaries[beneficiaryId]?['date'] != null &&
                    visitDate.isAfter(highRiskBeneficiaries[beneficiaryId]!['date']))) {
              highRiskBeneficiaries[beneficiaryId] = {
                'date': visitDate,
                'visit': visit,
              };
            }
          }
        }
      } catch (e) {
        print('Error getting high-risk visits: $e');
      }

      // If no high-risk beneficiaries found, show message
      if (highRiskBeneficiaries.isEmpty) {
        setState(() {
          _error = 'No high-risk ANC visits found';
          _isLoading = false;
          _ancVisits = [];
          _filteredVisits = [];
        });
        return;
      }

      // Get all visits from getUserData and match with high-risk beneficiaries
      final storageData = await SecureStorageService.getUserData();
      if (storageData != null && storageData.isNotEmpty) {
        try {
          final Map<String, dynamic> parsedData = jsonDecode(storageData);
          final List<ANCVisitModel> highRiskVisits = [];

          if (parsedData['visits'] is List) {
            for (var visit in parsedData['visits']) {
              try {
                final beneficiaryId = visit['BeneficiaryID']?.toString();
                if (beneficiaryId == null || !highRiskBeneficiaries.containsKey(beneficiaryId)) {
                  continue; // Skip if not a high-risk beneficiary
                }

                final rawRow = visit['_rawRow'] ?? {};
                final beneficiaryInfo = visit['beneficiary_info'] ?? {};
                final headDetails = beneficiaryInfo['head_details'] ?? {};

                // Extract age and gender from the visit data
                final String? ageWithGender = visit['age']?.toString();
                String? extractedAge;
                String? extractedGender;

                if (ageWithGender != null && ageWithGender.isNotEmpty) {
                  final parts = ageWithGender.split('/').map((e) => e.trim()).toList();
                  if (parts.isNotEmpty) {
                    extractedAge = parts[0];
                    if (parts.length > 1) {
                      extractedGender = parts[1];
                    }
                  }
                }

                final visitData = {
                  'id': beneficiaryId,
                  'hhId': visit['hhId'],
                  'house_number': headDetails['houseNo'],
                  'gender': extractedGender ?? headDetails['gender'] ?? 'F',
                  'age': extractedAge ?? visit['age'],
                  'woman_name': visit['Name'],
                  'husband_name': visit['HusbandName'],
                  'rch_number': visit['RichID'],
                  'visit_type': visit['RegistrationType'],
                  'high_risk': true, // Since we already filtered high-risk beneficiaries
                  'date_of_inspection': visit['RegistrationDate'],
                  'mobileNumber': visit['mobileno'],
                };

                highRiskVisits.add(ANCVisitModel.fromJson(visitData));
              } catch (e) {
                print('Error processing visit: $e\nVisit data: $visit');
              }
            }
          }

          // Sort by date descending to show most recent first
          highRiskVisits.sort((a, b) {
            if (a.dateOfInspection == null) return 1;
            if (b.dateOfInspection == null) return -1;
            return b.dateOfInspection!.compareTo(a.dateOfInspection!);
          });

          setState(() {
            _ancVisits = highRiskVisits;
            _filteredVisits = List.from(_ancVisits);
            _isLoading = false;
            if (_ancVisits.isEmpty) {
              _error = 'No matching high-risk ANC visits found';
            }
          });

        } catch (e) {
          print('Error parsing JSON data: $e');
          setState(() {
            _error = 'Error parsing data: $e';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No ANC visit data found';
          _isLoading = false;
          _ancVisits = [];
          _filteredVisits = [];
        });
      }
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
        screenTitle: l10n!.highRisk,
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
                      child: const Text('Retry'),
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
                        'No high-risk ANC visits found',
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
                        visit.hhId ?? 'N/A',
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
                      'HRP',
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
                  _infoRow(
                    '',
                    visit.womanName ?? 'No Name',
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

  // Widget _buildInfoRow(IconData icon, String text) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 16, color: Colors.grey[600]),
  //       const SizedBox(width: 4),
  //       Text(
  //         text,
  //         style: TextStyle(
  //           fontSize: 13,
  //           color: Colors.grey[800],
  //         ),
  //         maxLines: 1,
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //     ],
  //   );
  // }

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
}