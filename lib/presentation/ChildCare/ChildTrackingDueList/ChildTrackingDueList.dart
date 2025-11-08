import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/routes/Routes.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../../../data/Local_Storage/tables/followup_form_data_table.dart';
import 'ChildTrackingDueListForm.dart';

class CHildTrackingDueList extends StatefulWidget {
  const CHildTrackingDueList({super.key});

  @override
  State<CHildTrackingDueList> createState() => _CHildTrackingDueListState();
}

class _CHildTrackingDueListState extends State<CHildTrackingDueList> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _childTrackingList = [];
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _searchCtrl.addListener(_onSearchChanged);
    _loadChildTrackingData();
  }

   Future<void> _checkDatabaseRecords() async {
    try {
      final db = await DatabaseProvider.instance.database;
      
      // First, check total records in the table
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM ${FollowupFormDataTable.table}');
      final totalRecords = countResult.first['count'] as int;
      debugPrint('Total records in followup_form_data: $totalRecords');
      
      // Check for any records with the child_tracking_due form type
      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'form_json LIKE ?',
        whereArgs: ['%${FollowupFormDataTable.childTrackingDue}%'],
      );
      
      debugPrint('Found ${results.length} records with child_tracking_due form type');
      
      // If no records found, check for any records with similar form types
      if (results.isEmpty) {
        final allResults = await db.query(FollowupFormDataTable.table, limit: 5);
        debugPrint('Sample of first 5 records:');
        for (var i = 0; i < allResults.length; i++) {
          debugPrint('Record $i: ${allResults[i]}');
        }
      }
    } catch (e) {
      debugPrint('Error checking database records: $e');
    }
  }

  Future<void> _loadChildTrackingData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _checkDatabaseRecords(); // Check database records first
      
      final db = await DatabaseProvider.instance.database;
      
      // Try different query approaches to find matching records
      List<Map<String, dynamic>> results = [];
      
      // First try: Exact form_type match
      results = await db.query(
        FollowupFormDataTable.table,
        where: 'form_json LIKE ?',
        whereArgs: ['%"form_type":"${FollowupFormDataTable.childTrackingDue}"%'],
      );
      
      // If no results, try case-insensitive search
      if (results.isEmpty) {
        debugPrint('No results with exact form_type match, trying case-insensitive search');
        results = await db.rawQuery('''
          SELECT * FROM ${FollowupFormDataTable.table} 
          WHERE LOWER(form_json) LIKE ?
        ''', ['%${FollowupFormDataTable.childTrackingDue.toLowerCase()}%']);
      }
      
      debugPrint('Found ${results.length} child tracking records');
      if (results.isNotEmpty) {
        debugPrint('First record: ${results.first}');
      }

      final List<Map<String, dynamic>> childTrackingList = [];

      for (final row in results) {
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) {
            debugPrint('Skipping empty form_json');
            continue;
          }

          debugPrint('Processing form_json: $formJson');
          
          final formData = jsonDecode(formJson);
          final formType = formData['form_type']?.toString() ?? '';
          
          debugPrint('Form type: $formType');
          
          // Skip if not a child tracking form
          if (formType != FollowupFormDataTable.childTrackingDue) {
            debugPrint('Skipping non-child tracking form: $formType');
            continue;
          }
          
          final formDataMap = formData['form_data'] as Map<String, dynamic>? ?? {};
          final childName = formDataMap['child_name']?.toString() ?? '';
          
          debugPrint('Child name: $childName');
          
          // Skip if no child name
          if (childName.isEmpty) {
            debugPrint('Skipping record with empty child name');
            continue;
          }
          
          // Extract other fields with null safety
          final childData = {
            'hhId': row['household_ref_key']?.toString() ?? '',
            'RegitrationDate': _formatDate(row['created_date_time']?.toString()),
            'RegitrationType': 'Child Tracking',
            'BeneficiaryID': row['beneficiary_ref_key']?.toString() ?? '',
            'RchID': formDataMap['rch_id']?.toString() ?? '',
            'Name': childName,
            'Age|Gender': _formatAgeGender(formDataMap['date_of_birth'], formDataMap['gender']),
            'Mobileno.': formDataMap['mobile_number']?.toString() ?? '',
            'FatherName': formDataMap['father_name']?.toString() ?? '',
            'formData': formDataMap, // Store full form data for potential future use
          };
          
          debugPrint('Processed child data: $childData');
          childTrackingList.add(childData);
        } catch (e) {
          debugPrint('Error processing child tracking record: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _childTrackingList = childTrackingList;
          _filtered = List<Map<String, dynamic>>.from(childTrackingList);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading child tracking data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load child tracking data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
  
  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        String dateStr = dobRaw.toString();
        DateTime? dob;
        
        dob = DateTime.tryParse(dateStr);
        
        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }
        
        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            years--;
          }
          
          age = years >= 0 ? years.toString() : '0';
        }
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }
    
    String displayGender;
    switch (gender) {
      case 'm':
      case 'male':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
        displayGender = 'Female';
        break;
      default:
        displayGender = 'Other';
    }
    
    return '$age Y | $displayGender';
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
        _filtered = List<Map<String, dynamic>>.from(_childTrackingList);
      } else {
        _filtered = _childTrackingList.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['RchID']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['FatherName']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.childTrackingDueListTitle ?? 'Child Tracking\nDue List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: TextStyle(fontSize: 16.sp, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChildTrackingData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 🔍 Search Field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by name, ID, or mobile...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color:AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),

                    // 🔄 Refresh button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 20),
                          label: Text('Refresh', style: TextStyle(fontSize: 12.sp)),
                          onPressed: _loadChildTrackingData,
                        ),
                      ),
                    ),

                    // 📋 List of Children
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No children found',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadChildTrackingData,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  final childData = _filtered[index];
                                  return _householdCard(context, childData);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  // 🧱 Household Card UI
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 First Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _infoChip(
                    'HHID: ${data['hhId'] ?? 'N/A'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _infoChip(data['RegitrationDate'] ?? 'N/A'),
                const SizedBox(width: 8),
                _infoChip(
                  data['RegitrationType'] ?? 'N/A',
                  color: _getStatusColor(data['RegitrationType']),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 Second Row
            Row(
              children: [
                Expanded(
                  child: _infoChip(
                    'Beneficiary ID: ${data['BeneficiaryID'] ?? 'N/A'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (data['RchID']?.toString().isNotEmpty ?? false) ...[
                  const SizedBox(width: 8),
                  _infoChip('RCH ID: ${data['RchID']}'),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 Divider
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),

            // 🔹 Name and Age/Gender
            _infoRow('Name', data['Name']?.toString() ?? 'N/A'),
            const SizedBox(height: 8),
            _infoRow('Age | Gender', data['Age|Gender']?.toString() ?? 'N/A'),
            if (data['Mobileno.']?.toString().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _infoRow('Mobile No.', data['Mobileno.']!),
            ],
            if (data['FatherName']?.toString().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              _infoRow("Father's Name", data['FatherName']!),
            ],

            // 🔹 View/Edit Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: RoundButton(
                onPress: () {
                  Navigator.pushNamed(
                    context,
                    Route_Names.ChildTrackingDueListForm,
                    arguments: data['formData'],
                  );
                },
                title: 'View/Edit',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

 
  Widget _infoChip(String text, {Color? color, int? maxLines, TextOverflow? overflow}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: 10.sp,
          color: color != null ? Colors.white : Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper method to create an info row with label and value
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[900],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'child tracking':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
