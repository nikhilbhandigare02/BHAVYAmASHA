import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
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

      // Fetch deceased children from child tracking forms with case closure
      final deceasedChildren = await _storageDao.getFollowupFormsWithCaseClosure(
        FollowupFormDataTable.childTrackingDue,
      );

      // Transform to match the expected format
      final transformed = deceasedChildren.map((child) {
        final formData = child['form_data']['form_data'];
        final caseClosure = formData['case_closure'];
        
        return {
          'hhId': formData['household_id']?.toString() ?? 'N/A',
          'RegitrationDate': formData['registration_date'] ?? 'N/A',
          'RegitrationType': 'General',
          'BeneficiaryID': formData['beneficiary_id']?.toString() ?? 'N/A',
          'RchID': formData['rch_id']?.toString() ?? 'N/A',
          'Name': child['name'] ?? 'Unknown',
          'Age|Gender': '${formData['age'] ?? 'N/A'} Y | ${formData['gender'] ?? 'N/A'}',
          'Mobileno.': formData['mobile_number']?.toString() ?? 'N/A',
          'FatherName': formData['father_name'] ?? 'N/A',
          'causeOFDeath': caseClosure['probable_cause_of_death'] ?? 'Not specified',
          'reason': caseClosure['reason_of_death'] ?? 'Not specified',
          'place': caseClosure['death_place'] ?? 'Not specified',
          'DateofDeath': _formatDate(caseClosure['date_of_death']) ?? 'N/A',
        };
      }).toList();

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
      // Show error message to user
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
          : _filtered.isEmpty
              ? const Center(child: Text('No deceased children found'))
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or mobile',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('S.No')),
                DataColumn(label: Text('HH ID')),
                DataColumn(label: Text('Beneficiary ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Age|Gender')),
                DataColumn(label: Text('Mobile No.')),
                DataColumn(label: Text('Father\'s Name')),
                DataColumn(label: Text('Cause of Death')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Place')),
                DataColumn(label: Text('Date of Death')),
                DataColumn(label: Text('Action')),
              ],
              rows: List<DataRow>.generate(
                _filtered.length,
                (index) {
                  final item = _filtered[index];
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(item['hhId']?.toString() ?? 'N/A')),
                      DataCell(Text(item['BeneficiaryID']?.toString() ?? 'N/A')),
                      DataCell(Text(item['Name']?.toString() ?? 'N/A')),
                      DataCell(Text(item['Age|Gender']?.toString() ?? 'N/A')),
                      DataCell(Text(item['Mobileno.']?.toString() ?? 'N/A')),
                      DataCell(Text(item['FatherName']?.toString() ?? 'N/A')),
                      DataCell(Text(item['causeOFDeath']?.toString() ?? 'N/A')),
                      DataCell(Text(item['reason']?.toString() ?? 'N/A')),
                      DataCell(Text(item['place']?.toString() ?? 'N/A')),
                      DataCell(Text(item['DateofDeath']?.toString() ?? 'N/A')),
                      DataCell(
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              _viewDetails(item);
                            } else if (value == 'edit') {
                              _editDetails(item);
                            } else if (value == 'delete') {
                              _confirmDelete(item);
                            }
                          },
                          child: const Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deceased Child Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', item['Name']?.toString() ?? 'N/A'),
              _buildDetailRow('HH ID', item['hhId']?.toString() ?? 'N/A'),
              _buildDetailRow('Beneficiary ID', item['BeneficiaryID']?.toString() ?? 'N/A'),
              _buildDetailRow('Age | Gender', item['Age|Gender']?.toString() ?? 'N/A'),
              _buildDetailRow('Mobile', item['Mobileno.']?.toString() ?? 'N/A'),
              _buildDetailRow('Father\'s Name', item['FatherName']?.toString() ?? 'N/A'),
              const SizedBox(height: 16),
              const Text('Death Details', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('Date of Death', item['DateofDeath']?.toString() ?? 'N/A'),
              _buildDetailRow('Cause of Death', item['causeOFDeath']?.toString() ?? 'N/A'),
              _buildDetailRow('Place of Death', item['place']?.toString() ?? 'N/A'),
              _buildDetailRow('Reason', item['reason']?.toString() ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _editDetails(Map<String, dynamic> item) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the record for ${item['Name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

}
