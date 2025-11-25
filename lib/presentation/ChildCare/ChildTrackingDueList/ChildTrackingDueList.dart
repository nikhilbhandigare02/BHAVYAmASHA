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
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
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

  Future<void> _loadChildTrackingData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final db = await DatabaseProvider.instance.database;

      // First, let's see ALL records in the table (newest first)
      final allRecords = await db.query(
        FollowupFormDataTable.table,
        orderBy: 'id DESC',
      );
      debugPrint('📋 Total records in followup_form_data table: ${allRecords.length}');
      
      for (var i = 0; i < allRecords.length && i < 5; i++) {
        final record = allRecords[i];
        debugPrint('\n--- Record ${i + 1} (ID: ${record['id']}) ---');
        debugPrint('household_ref_key: ${record['household_ref_key']}');
        debugPrint('beneficiary_ref_key: ${record['beneficiary_ref_key']}');
        debugPrint('created_date_time: ${record['created_date_time']}');
        debugPrint('form_json: ${record['form_json']}');
        debugPrint('form_json length: ${(record['form_json'] as String?)?.length ?? 0}');
      }

      // Query followup_form_data for child registration entries OR child tracking due forms
      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'form_json LIKE ? OR forms_ref_key = ?',
        whereArgs: ['%child_registration_due%', '30bycxe4gv7fqnt6'],
        orderBy: 'id DESC',
      );

      debugPrint('\n🔍 Found ${results.length} child registration/tracking records after filtering');

      final List<Map<String, dynamic>> childTrackingList = [];
      final Set<String> seenBeneficiaries = <String>{};

      for (final row in results) {
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) {
            debugPrint('Skipping row with empty form_json');
            continue;
          }

          debugPrint('Processing form_json: ${formJson.substring(0, formJson.length > 100 ? 100 : formJson.length)}...');

          final formData = jsonDecode(formJson);
          final formType = formData['form_type']?.toString() ?? '';
          final formsRefKey = row['forms_ref_key']?.toString() ?? '';

          debugPrint('Form type found: $formType');
          debugPrint('Forms ref key: $formsRefKey');


          final isChildRegistration = formType == FollowupFormDataTable.childRegistrationDue;
          final isChildTracking = formsRefKey == '30bycxe4gv7fqnt6' || formType == FollowupFormDataTable.childTrackingDue;
          
          if (!isChildRegistration && !isChildTracking) {
            debugPrint('Skipping form with type: $formType and ref key: $formsRefKey');
            continue;
          }

          final formDataMap = formData['form_data'] as Map<String, dynamic>? ?? {};
          final childName = formDataMap['child_name']?.toString() ?? '';
          final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';

          debugPrint('Child name found: $childName');

          // Skip if no child name
          if (childName.isEmpty) {
            debugPrint('Skipping record with empty child name');
            continue;
          }

          // De-duplicate on beneficiary_ref_key so each child appears only once
          if (beneficiaryRefKey.isNotEmpty && seenBeneficiaries.contains(beneficiaryRefKey)) {
            debugPrint('⏭️ Skipping duplicate record for beneficiary: $beneficiaryRefKey');
            continue;
          }
          if (beneficiaryRefKey.isNotEmpty) {
            seenBeneficiaries.add(beneficiaryRefKey);
          }

          // Check if case closure exists for this beneficiary
          if (beneficiaryRefKey.isNotEmpty) {
            final caseClosureRecords = await db.query(
              FollowupFormDataTable.table,
              where: 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0',
              whereArgs: [beneficiaryRefKey, '%case_closure%'],
            );
            
            if (caseClosureRecords.isNotEmpty) {
              // Check if any of these records have case_closure with is_case_closure = true
              bool hasCaseClosure = false;
              for (final ccRecord in caseClosureRecords) {
                try {
                  final ccFormJson = ccRecord['form_json'] as String?;
                  if (ccFormJson != null) {
                    final ccFormData = jsonDecode(ccFormJson);
                    final ccFormDataMap = ccFormData['form_data'] as Map<String, dynamic>? ?? {};
                    final caseClosure = ccFormDataMap['case_closure'] as Map<String, dynamic>? ?? {};
                    if (caseClosure['is_case_closure'] == true) {
                      hasCaseClosure = true;
                      break;
                    }
                  }
                } catch (e) {
                  debugPrint('Error checking case closure: $e');
                }
              }
              
              if (hasCaseClosure) {
                debugPrint('⏭️ Skipping child $childName - case closure already recorded');
                continue;
              }
            }
          }

          // Format registration date
          final registrationDate = row['created_date_time'] != null 
              ? _formatDate(row['created_date_time'].toString())
              : 'N/A';

          // Extract other fields with null safety
          final childData = {
            'hhId': row['household_ref_key']?.toString() ?? 'N/A',
            'RegitrationDate': registrationDate,
            'RegitrationType': 'Child Registration',
            'BeneficiaryID': beneficiaryRefKey,
            'RchID': formDataMap['rch_id_child']?.toString() ?? 'N/A',
            'Name': childName,
            'Age|Gender': _formatAgeGender(formDataMap['date_of_birth'], formDataMap['gender']),
            'Mobileno.': formDataMap['mobile_number']?.toString() ?? 'N/A',
            'FatherName': formDataMap['father_name']?.toString() ?? 'N/A',
            'MotherName': formDataMap['mother_name']?.toString() ?? 'N/A',
            'Address': formDataMap['address']?.toString() ?? 'N/A',
            'Weight': formDataMap['weight_grams']?.toString() ?? 'N/A',
            'formData': formDataMap,
          };

          childTrackingList.add(childData);
          debugPrint('✅ Successfully added child: $childName');
        } catch (e) {
          debugPrint('❌ Error processing child registration record: $e');
          continue;
        }
      }

      debugPrint('📊 Total child records processed: ${childTrackingList.length}');

      if (mounted) {
        setState(() {
          _childTrackingList = childTrackingList;
          _filtered = List<Map<String, dynamic>>.from(childTrackingList);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading child registration data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load child registration data. Please try again.';
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
        screenTitle: l10n?.childTrackingDueListTitle ?? 'Child Tracking Due List',
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
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                    ),

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
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 12),
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

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        final formData = data['formData'] as Map<String, dynamic>?;

        
        if (formData == null) {
          debugPrint('❌ formData is null, cannot navigate');
          return;
        }
        
        final completeFormData = {
          ...formData,
          'household_ref_key': data['hhId']?.toString() ?? '',
          'household_id': data['hhId']?.toString() ?? '',
          'beneficiary_ref_key': data['BeneficiaryID']?.toString() ?? '',
          'beneficiary_id': data['BeneficiaryID']?.toString() ?? '',
          'child_name': data['Name']?.toString() ?? formData['child_name'] ?? '',
          'age': data['Age|Gender']?.toString() ?? '',
          'gender': formData['gender'] ?? '',
          'father_name': data['FatherName']?.toString() ?? formData['father_name'] ?? '',
          'mother_name': data['MotherName']?.toString() ?? formData['mother_name'] ?? '',
          'mobile_number': data['Mobileno.']?.toString() ?? formData['mobile_number'] ?? '',
          'rch_id': data['RchID']?.toString() ?? formData['rch_id_child'] ?? '',
          'registration_type': data['RegitrationType']?.toString() ?? 'Child Registration',
          'registration_date': data['RegitrationDate']?.toString() ?? '',
        };
        
        debugPrint('Complete form data to pass:');
        debugPrint('  household_ref_key: ${completeFormData['household_ref_key']}');
        debugPrint('  beneficiary_ref_key: ${completeFormData['beneficiary_ref_key']}');
        debugPrint('  child_name: ${completeFormData['child_name']}');
        debugPrint('  age: ${completeFormData['age']}');
        debugPrint('  gender: ${completeFormData['gender']}');
        
        Navigator.pushNamed(
          context,
          Route_Names.ChildTrackingDueListForm,
          arguments: {
            'formData': completeFormData,
            'isEdit': true,
          },
        )?.then((result) {
          if (result is Map && result['saved'] == true) {
            debugPrint('✅ Form saved, removing card for beneficiary: ${completeFormData['beneficiary_id']}');
            
            setState(() {
              _childTrackingList.removeWhere((child) {
                final childBeneficiaryId = child['BeneficiaryID']?.toString() ?? '';
                final formBeneficiaryId = completeFormData['beneficiary_id']?.toString() ?? '';
                return childBeneficiaryId == formBeneficiaryId && childBeneficiaryId.isNotEmpty;
              });
              _filtered = List<Map<String, dynamic>>.from(_childTrackingList);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Case closure recorded. Child removed from tracking list.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            _loadChildTrackingData();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                   Icon(Icons.home, color: AppColors.primary, size: 15.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null && data['hhId'].toString().length > 11)
                          ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                          : (data['hhId']?.toString() ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.sync, size: 24, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType'] ?? 'Child Registration')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', 
                        (data['BeneficiaryID']?.toString().length ?? 0) > 11 
                          ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11) 
                          : (data['BeneficiaryID']?.toString() ?? 'N/A'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.nameLabelSimple ?? 'Name', data['Name'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(
                        l10n?.rchIdLabel ?? 'RCH ID', 
                        data['RchID']?.isNotEmpty == true ? data['RchID'] : 'N/A',
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] : 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.fatherNameLabel ?? 'Father\'s Name',
                          data['FatherName']?.isNotEmpty == true ? data['FatherName'] : 'N/A',
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

  Widget _rowText(String title, String value) {
    final Color primary = Theme.of(context).primaryColor;
    final bool isLight = primary.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
