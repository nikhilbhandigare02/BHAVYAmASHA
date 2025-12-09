import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class PreviousVisitsScreen extends StatefulWidget {
  final String beneficiaryId;

  const PreviousVisitsScreen({super.key, required this.beneficiaryId});

  @override
  State<PreviousVisitsScreen> createState() => _PreviousVisitsScreenState();
}

class _PreviousVisitsScreenState extends State<PreviousVisitsScreen> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndLoadVisits();
  }

  Future<void> _initializeDatabaseAndLoadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;
      _loadVisits();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize database: $e';
      });
    }
  }

  Future<void> _loadVisits() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // First, check if the table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='followup_form_data'"
      );

      if (tables.isEmpty) {
        throw Exception('followup_form_data table does not exist');
      }

      // Query for all eligible couple related forms
      final visits = await db.query(
        'followup_form_data',
        where: 'beneficiary_ref_key = ? AND (form_json LIKE ? OR form_json LIKE ? OR form_json LIKE ?)',
        whereArgs: [
          widget.beneficiaryId, 
          '%"form_type":"eligible_couple_tracking_due"%',
          '%"form_type":"eligible_couple_registration"%',
          '%"form_type":"eligible_couple_re_registration"%',
        ],
        orderBy: 'created_date_time DESC',
      );

      // Parse the form_json data
      final parsedVisits = visits.map((visit) {
        try {
          final formJson = jsonDecode(visit['form_json'] as String? ?? '{}');
          
          // Get form type for display
          String formType = 'Visit';
          if (formJson is Map) {
            if (formJson['form_type'] == 'eligible_couple_registration') {
              formType = 'Registration';
            } else if (formJson['form_type'] == 'eligible_couple_re_registration') {
              formType = 'Re-registration';
            } else if (formJson['form_type'] == 'eligible_couple_tracking_due') {
              formType = 'Follow-up';
            }
          }
          
          return {
            ...visit,
            'form_type': formType,
            'form_data': formJson is Map ? formJson : {},
            'created_date_time': visit['created_date_time'] ?? visit['created_at']
          };
        } catch (e, stackTrace) {
          print('Error parsing form data: $e');
          print('Stack trace: $stackTrace');
          return {
            ...visit,
            'form_type': 'Unknown',
            'form_data': {},
            'error': 'Failed to parse form data: $e'
          };
        }
      }).toList();

      if (mounted) {
        setState(() {
          _visits = parsedVisits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading visits: $e';
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.tryParse(dateString);
      return date != null
          ? '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}'
          : dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Helper method to format the value for display
  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value.isNotEmpty ? value : 'N/A';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  // Helper method to build a section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  // Helper method to build a key-value row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppHeader(
        screenTitle:l10n?.previousVisits ?? 'Previous Visits',
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _visits.isEmpty
                  ?  Center(
                      child: Text(l10n?.noPreviousVisits ??'No previous visits found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _visits.length,
                      itemBuilder: (context, index) {
                        final visit = _visits[index];
                        final formData = visit['form_data'] is Map
                            ? visit['form_data'] as Map<String, dynamic>
                            : <String, dynamic>{};

                        // Extract form data
                        final formValues = formData['form_data'] is Map
                            ? formData['form_data'] as Map<String, dynamic>
                            : <String, dynamic>{};

                        // Extract basic info
                        final visitType = visit['form_type'] ?? 'Visit';
                        final visitDate = _formatDate(visit['created_date_time']);
                        final visitId = visit['id']?.toString() ?? 'N/A';
                        final syncStatus = visit['is_synced'] == 1
                            ? 'Synced'
                            : 'Not Synced';

                        return Card(
                          margin:  EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: ExpansionTile(
                            title: Text(
                              '$visitType - $visitDate',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text('${l10n?.id ?? "ID"}: $visitId • $syncStatus'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (visit['error'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          '${l10n?.error ?? "Error"}: ${visit['error']}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    // Basic Info Section
                                    _buildSectionHeader(l10n?.visitInformation ?? 'Visit Information'),
                                    _buildInfoRow('${l10n?.visitId ?? "Visit ID"}:', visitId),
                                    _buildInfoRow('${l10n?.thType ??"Type"}:', visitType),
                                    _buildInfoRow('${l10n?.dateLabel ?? "Date"}:', visitDate),
                                    _buildInfoRow('${l10n?.visitStatusLabel ?? "Status"}:', syncStatus),

                                    // Form Data Section
                                    if (formValues.isNotEmpty) ...[
                                      _buildSectionHeader(l10n?.formData ??'Form Data'),
                                      ...formValues.entries.map((entry) {
                                        // Skip null or empty values
                                        if (entry.value == null ||
                                            (entry.value is String &&
                                                (entry.value as String).isEmpty) ||
                                            entry.key == 'form_type') {
                                          return const SizedBox.shrink();
                                        }

                                        // Format the key for display
                                        String displayKey = entry.key
                                            .toString()
                                            .replaceAll('_', ' ')
                                            .split(' ')
                                            .map((str) => str.isNotEmpty
                                                ? '${str[0].toUpperCase()}${str.substring(1)}'
                                                : '')
                                            .join(' ');

                                        return _buildInfoRow(
                                          '$displayKey:',
                                          _formatValue(entry.value),
                                        );
                                      }).toList(),
                                    ],

                                    // Raw Data Section (for debugging)
                                    if (formData.isNotEmpty) ...[
                                      _buildSectionHeader(l10n?.rawData ?? 'Raw Data'),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Text(
                                          const JsonEncoder.withIndent('  ')
                                              .convert(formData),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }



}