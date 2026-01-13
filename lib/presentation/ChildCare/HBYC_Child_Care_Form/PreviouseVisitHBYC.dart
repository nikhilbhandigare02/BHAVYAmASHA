import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class PreviousVisitsScreenHBYC extends StatefulWidget {
  final String beneficiaryId;
  
  const PreviousVisitsScreenHBYC({
    super.key,
    required this.beneficiaryId,
  });

  @override
  State<PreviousVisitsScreenHBYC> createState() => _PreviousVisitsScreenState();
}

class _PreviousVisitsScreenState extends State<PreviousVisitsScreenHBYC> {
  bool _isLoading = true;
  List<Map<String, dynamic>> visits = [];

  @override
  void initState() {
    super.initState();
    _loadVisitData();
  }
  late final l10n = AppLocalizations.of(context);

  Future<void> _loadVisitData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First, check the table structure
      final tableInfo = await db.rawQuery('PRAGMA table_info(followup_form_data)');
      debugPrint('Table structure: $tableInfo');
      
      // Try to find a date column that we can use for sorting
      String orderByClause = '';
      final possibleDateColumns = ['createdAt', 'created_date', 'date_created', 'timestamp'];
      
      for (final column in possibleDateColumns) {
        final hasColumn = tableInfo.any((col) => col['name'] == column);
        if (hasColumn) {
          orderByClause = 'ORDER BY $column DESC';
          break;
        }
      }
      
      // Query to get all form submissions for this beneficiary
      final query = '''
        SELECT * FROM followup_form_data 
        WHERE beneficiary_ref_key = ? AND forms_ref_key = ?
        ${orderByClause.isNotEmpty ? orderByClause : ''}
      '''.trim();
      
      debugPrint('Executing query: $query with args: [${widget.beneficiaryId}, 999]');
      
      final List<Map<String, dynamic>> results = await db.rawQuery(
        query,
        [widget.beneficiaryId, '999']
      );

      debugPrint('Found ${results.length} form submissions for beneficiary ${widget.beneficiaryId}');
      if (results.isNotEmpty) {
        debugPrint('First result keys: ${results.first.keys}');
      }

      setState(() {
        visits = results.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final data = entry.value;
          
          // Get the creation date from the database row
          String visitDate = 'N/A';
          try {
            // First try to get the date from the database column if it exists
            if (data.containsKey('created_at') && data['created_at'] != null) {
              visitDate = data['created_at'].toString();
            } 
            // Fallback to form data if not found in the row
            else if (data.containsKey('form_json')) {
              final formData = jsonDecode(data['form_json'] as String);
              visitDate = formData['created_at']?.toString() ?? 'N/A';
            }
            
            // Format the date if it's valid
            if (visitDate != 'N/A') {
              try {
                final dateTime = DateTime.tryParse(visitDate) ?? DateTime.now();
                visitDate = '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
              } catch (e) {
                debugPrint('Error parsing date $visitDate: $e');
                visitDate = 'N/A';
              }
            }
          } catch (e) {
            debugPrint('Error processing visit data: $e');
            visitDate = 'N/A';
          }
          
          return {
            'sr': index.toString(),
            'date': visitDate,
            'raw_data': data, // Store raw data in case needed later
          };
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading visit data: $e');
      setState(() {
        _isLoading = false;
        // Show a snackbar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading visit data: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.previousVisitsButtonS ?? '',
        showBack: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.black38),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n!.srNo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n!.visitDateLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            // Table rows
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visits.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Text(
                            l10n!.noPreviousVisits,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: visits.length,
                          itemBuilder: (context, index) {
                            final item = visits[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 0.5.h),
                              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black38),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      item['sr'] ?? 'N/A',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item['date'] ?? 'N/A',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

          ],
        ),
      ),
    );
  }
}
