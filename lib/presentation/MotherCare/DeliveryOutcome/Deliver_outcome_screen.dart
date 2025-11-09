import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../core/models/anc_visit_model.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class DeliveryOutcomeScreen extends StatefulWidget {
  const DeliveryOutcomeScreen({super.key});

  @override
  State<DeliveryOutcomeScreen> createState() =>
      _DeliveryOutcomeScreenState();
}

class _DeliveryOutcomeScreenState
    extends State<DeliveryOutcomeScreen> {
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
                  'high_risk': true,
                  'date_of_inspection': visit['RegistrationDate'],
                  'mobileNumber': visit['mobileno'],
                };

                highRiskVisits.add(ANCVisitModel.fromJson(visitData));
              } catch (e) {
                print('Error processing visit: $e\nVisit data: $visit');
              }
            }
          }

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
        screenTitle:  l10n!.deliveryOutcomeList,
        showBack: true,


      ),
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
                    return _householdCard(context, displayVisits[index]);
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _householdCard(BuildContext context, ANCVisitModel visit) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              Route_Names.OutcomeFormScreen,
              // arguments: {'isBeneficiary': true},
            );
          },
          child: Container(
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
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                         visit.hhId?? '',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w500,fontSize: 14.sp
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/images/sync.png',
                          width: 25,
                          height: 25,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body section
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
                      Row(
                        children: [
                          Expanded(
                            child: _rowText(
                              l10n?.registrationDateLabel ?? 'Registration Date',
                              visit.registrationDate ??'',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rowText(
                              l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                              visit.id ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rowText(
                               'RCH ID',
                              l10n?.notAvailable ?? 'Not Available',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _rowText(l10n?.thName ?? 'Name', visit.womanName ?? '')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rowText(
                              l10n?.ageGenderLabel ?? 'Age | Gender',
                              visit.age ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rowText(
                              l10n?.mobileLabelSimple ?? 'Mobile no.',
                              visit.mobileNumber ?? '',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _rowText(
                               'Husband Name',
                              visit.husbandName ?? '',
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
        ),

      ],
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(color: AppColors.background, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 13.sp),
        ),
      ],
    );
  }

}
