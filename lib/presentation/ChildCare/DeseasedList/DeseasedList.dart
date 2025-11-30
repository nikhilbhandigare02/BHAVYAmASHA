import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';

class DeseasedList extends StatefulWidget {
  const DeseasedList({super.key});

  @override
  State<DeseasedList> createState() => _DeseasedListState();
}

class _DeseasedListState extends State<DeseasedList> {
  final TextEditingController _searchCtrl = TextEditingController();
  final LocalStorageDao _storageDao = LocalStorageDao();

  bool _isLoading = true;
  List<Map<String, dynamic>> _deceasedList = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadDeceasedList();
  }

  Future<void> _loadDeceasedList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final deceasedChildren = await _storageDao.getFollowupFormsWithCaseClosure(
        FollowupFormDataTable.childTrackingDue,
      );

      final transformed = deceasedChildren.map((child) {
        Map<String, dynamic> safeCastMap(dynamic map) {
          if (map == null) return {};
          if (map is Map<String, dynamic>) return map;
          if (map is Map) return Map<String, dynamic>.from(map);
          return {};
        }

        final formData = safeCastMap(child['form_data']);
        final childDetails = safeCastMap(child['child_details']);
        final caseClosure = safeCastMap(child['case_closure']);
        final registrationData = safeCastMap(child['registration_data']);
        final beneficiaryData = safeCastMap(child['beneficiary_data']);

        String formatAge(dynamic age) {
          if (age == null) return 'N/A';
          if (age is int || age is double) {
            return '$age Y';
          }
          return age.toString();
        }


        Map<String, dynamic> registrationFollowup = {};
        if (beneficiaryData['registration_type_followup'] is Map) {
          registrationFollowup = beneficiaryData['registration_type_followup'] as Map<String, dynamic>;
        }


        String getName() {

          if (registrationFollowup['name'] != null && registrationFollowup['name'].toString().isNotEmpty) {
            return registrationFollowup['name'].toString();
          }

          if (registrationFollowup['child_name'] != null && registrationFollowup['child_name'].toString().isNotEmpty) {
            return registrationFollowup['child_name'].toString();
          }

          if (beneficiaryData['name'] != null && beneficiaryData['name'].toString().isNotEmpty) {
            return beneficiaryData['name'].toString();
          }

          return child['name']?.toString() ?? 'Unknown';
        }

        String getAge() {
          var age = registrationFollowup['age'] ?? beneficiaryData['age'] ?? child['age'];
          if (age == null) return 'N/A';
          return age.toString();
        }

        String getGender() {
          return registrationFollowup['gender']?.toString() ?? 
                 beneficiaryData['gender']?.toString() ?? 
                 child['gender']?.toString() ?? 
                 'N/A';
        }

        String getRchId() {
          return registrationFollowup['rch_id']?.toString() ?? 
                 registrationFollowup['rchId']?.toString() ?? 
                 beneficiaryData['rch_id']?.toString() ?? 
                 formData['rch_id']?.toString() ?? 
                 'N/A';
        }

        String getBeneficiaryId() {
          return registrationFollowup['beneficiary_id']?.toString() ??
                 beneficiaryData['beneficiary_id']?.toString() ?? 
                 formData['beneficiary_id']?.toString() ?? 
                 formData['beneficiary_ref_key']?.toString() ?? 
                 'N/A';
        }

        String getRegistrationType() {
          return registrationFollowup['registration_type']?.toString() ?? 
                 registrationData['registration_type']?.toString() ?? 
                 'General';
        }

        String getRegistrationDate() {
          var date = registrationFollowup['registration_date'] ?? 
                    registrationFollowup['date_of_registration'] ??
                    registrationData['registration_date'] ?? 
                    formData['registration_date'];
          return _formatDate(date) ?? 'N/A';
        }

        return {
          'hhId': formData['household_id']?.toString() ?? formData['household_ref_key']?.toString() ?? beneficiaryData['household_id']?.toString() ?? 'N/A',
          'RegitrationDate': getRegistrationDate(),
          'RegitrationType': getRegistrationType(),
          'BeneficiaryID': getBeneficiaryId(),
          'RchID': getRchId(),
          'Name': getName(),
          'Age|Gender': '${formatAge(getAge())} | ${getGender()}',
          'Mobileno.': formData['mobile_number']?.toString() ?? formData['contact_number']?.toString() ?? beneficiaryData['mobile_number']?.toString() ?? 'N/A',
          'FatherName': registrationFollowup['father_name']?.toString() ?? beneficiaryData['father_name']?.toString() ?? child['father_name']?.toString() ?? 'N/A',
          'MotherName': registrationFollowup['mother_name']?.toString() ?? beneficiaryData['mother_name']?.toString() ?? child['mother_name']?.toString() ?? 'N/A',
          'causeOFDeath': caseClosure['probable_cause_of_death'] ?? 'Not specified',
          'reason': caseClosure['reason_of_death'] ?? 'Not specified',
          'place': caseClosure['death_place'] ?? 'Not specified',
          'DateofDeath': _formatDate(caseClosure['date_of_death']) ?? 'N/A',
          'age': getAge(),
          'gender': getGender(),
        };
      }).toList();

      print('Loaded ${transformed.length} deceased records');
      for (var record in transformed) {
        print('Deceased Record:');
        print('  Name: ${record['Name']}');
        print('  HH ID: ${record['hhId']}');
        print('  Beneficiary ID: ${record['BeneficiaryID']}');
        print('  Date of Death: ${record['DateofDeath']}');
      }

      print('\n📋 Raw data from DAO:');
      for (var child in deceasedChildren) {
        print('Raw Record:');
        print('  household_id: ${child['household_id']}');
        print('  beneficiary_id: ${child['beneficiary_id']}');
        print('  form_data keys: ${(child['form_data'] as Map?)?.keys.toList()}');
      }

      setState(() {
        _deceasedList = transformed;
        _filtered = List<Map<String, dynamic>>.from(_deceasedList);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading deceased list: $e');
      setState(() {
        _isLoading = false;
      });
       
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load deceased list: $e')),
        );
      }
    }
  }

  String? _formatDate(String? dateString) {
    if (dateString == null) return null;
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
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
        _filtered = List<Map<String, dynamic>>.from(_deceasedList);
      } else {
        _filtered = _deceasedList.where((e) {
          return (e['hhId']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['Name']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['Mobileno.']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['BeneficiaryID']?.toString() ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Deceased Child List',
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Search Box (always visible)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or mobile',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),

        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _deceasedList.isEmpty
                            ? 'No deceased children found'
                            : 'No matching records found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final data = _filtered[index];
                      return _deceasedCard(context, data);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _deceasedCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (data['hhId'] != null && data['hhId'].toString().length > 11)
                            ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                            : (data['hhId']?.toString() ?? ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow([
                      _rowText('Registration Date', data['RegitrationDate'] ?? 'N/A'),
                      _rowText('Registration Type', data['RegitrationType'] ?? 'N/A'),
                      _rowText('Beneficiary ID',
                          (data['BeneficiaryID']?.toString().length ?? 0) > 11
                              ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11)
                              : (data['BeneficiaryID']?.toString() ?? 'N/A')
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText('Name', data['Name'] ?? 'N/A'),
                      _rowText('Age | Gender', data['Age|Gender'] ?? 'N/A'),
                      _rowText('RCH ID', data['RchID'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText('Father Name', data['FatherName'] ?? 'N/A'),
                      _rowText('Mobile No.', data['Mobileno.'] ?? 'N/A'),
                      _rowText('Date of Death', data['DateofDeath'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText('Cause of Death', data['causeOFDeath'] ?? 'Not specified'),
                      _rowText('Reason', data['reason'] ?? 'Not specified'),
                      _rowText('Place', data['place'] ?? 'Not specified'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ]
      ],
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.background,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  void _viewDetails(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deceasedChildDetails ?? 'Deceased Child Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Name', item['Name']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('HH ID', item['hhId']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('Beneficiary ID', item['BeneficiaryID']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('Age | Gender', item['Age|Gender']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('Mobile', item['Mobileno.']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('Father\'s Name', item['FatherName']?.toString() ?? 'N/A'),
              const SizedBox(height: 16),
              Text(
                l10n?.deathDetailsLabel ?? 'Death Details',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              const SizedBox(height: 8),
              _detailRow('Date of Death', item['DateofDeath']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _detailRow('Cause of Death', item['causeOFDeath']?.toString() ?? 'Not specified'),
              const SizedBox(height: 8),
              _detailRow('Place of Death', item['place']?.toString() ?? 'Not specified'),
              const SizedBox(height: 8),
              _detailRow('Reason', item['reason']?.toString() ?? 'Not specified'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.closeLabel ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ],
    );
  }


}