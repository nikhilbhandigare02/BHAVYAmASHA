import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../HomeScreen/HomeScreen.dart';


class HBNCListScreen extends StatefulWidget {
  const HBNCListScreen({super.key});

  @override
  State<HBNCListScreen> createState() =>
      _HBNCListScreenState();
}

class _HBNCListScreenState
    extends State<HBNCListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPregnancyOutcomeeCouples();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }
  Future<int> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getVisitCount');
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      
      // Get the latest visit record to extract visit number
      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );
      
      if (latestVisitRows.isNotEmpty) {
        final result = latestVisitRows.first;
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          
          if (formJson.containsKey('hbyc_form')) {
            final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};
            
            if (hbycForm.containsKey('visitDetails')) {
              final visitDetails = hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
              final visitNumber = visitDetails['visitNumber']?.toString();
              
              if (visitNumber != null) {
                final number = int.tryParse(visitNumber);
                if (number != null) {
                  print('🔢 Found visit number from hbyc_form.visitDetails: $number for beneficiary $beneficiaryId');
                  return number;
                }
              }
            }
          }
          
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};
          
          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'] as Map<String, dynamic>? ?? {};
            final visitNumber = visitDetails['visitNumber']?.toString() ??
                visitDetails['visit_number']?.toString();
            
            if (visitNumber != null) {
              final number = int.tryParse(visitNumber);
              if (number != null) {
                print('🔢 Found visit number from form_data.visitDetails: $number for beneficiary $beneficiaryId');
                return number;
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing visit number: $e');
        }
      }
      
      // Fallback to counting total records
      final countRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, hbncVisitKey],
        columns: ['id'],
      );
      final count = countRows.length;
      print('🔢 HBNC visit record count for $beneficiaryId: $count');
      return count;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return 0;
    }
  }

  Future<bool> _isSynced(String beneficiaryId) async {
    try {
      final db = await DatabaseProvider.instance.database;

      final motherCareResult = await db.query(
        'mother_care_activities',
        columns: ['is_synced'],
        where: 'beneficiary_ref_key = ? AND mother_care_state = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, 'pnc_mother'],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      final followupResult = await db.query(
        'followup_form_data',
        columns: ['is_synced'],
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, '4r7twnycml3ej1vg'],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      // Return true if either record exists and is synced
      if (motherCareResult.isNotEmpty && motherCareResult.first['is_synced'] == 1) {
        return true;
      }

      if (followupResult.isNotEmpty && followupResult.first['is_synced'] == 1) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking sync status: $e');
      return false;
    }
  }

  Future<int> _getChildTabCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) return 1;
      final db = await DatabaseProvider.instance.database;
      
      // First try to get from ANC form
      final ancRefKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
      if (ancRefKey.isNotEmpty) {
        final ancRows = await db.rawQuery(
          'SELECT * FROM ${FollowupFormDataTable.table} WHERE forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0 ORDER BY created_date_time DESC LIMIT 1',
          [ancRefKey, beneficiaryId],
        );
        if (ancRows.isNotEmpty) {
          final s = ancRows.first['form_json']?.toString() ?? '';
          if (s.isNotEmpty) {
            final decoded = jsonDecode(s);
            final fd = (decoded is Map) ? Map<String, dynamic>.from(decoded['anc_form'] as Map? ?? {}) : <String, dynamic>{};
            
            // Check for children_arr first (new structure)
            final childrenArr = fd['children_arr'] as List?;
            if (childrenArr != null && childrenArr.isNotEmpty) {
              final count = childrenArr.length;
              print('👶 Child count from children_arr: $count for beneficiary $beneficiaryId');
              return (count > 3) ? 3 : (count < 1) ? 1 : count;
            }
            
            final raw = fd['live_birth']?.toString().trim().toLowerCase() ?? '';
            if (raw.isNotEmpty) {
              if (raw == 'one' || raw == 'single' || raw == '1') return 1;
              if (raw == 'twins' || raw == 'twin' || raw == '2') return 2;
              if (raw == 'triplets' || raw == 'triplet' || raw == '3') return 3;
              final n = int.tryParse(raw);
              if (n != null && n >= 1) {
                return (n > 3 ? 3 : n);
              }
            }
          }
        }
      }
      
       final deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final deliveryRows = await db.rawQuery(
        'SELECT * FROM ${FollowupFormDataTable.table} WHERE forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0 ORDER BY created_date_time DESC LIMIT 1',
        [deliveryOutcomeKey, beneficiaryId],
      );
      
      if (deliveryRows.isNotEmpty) {
        final s = deliveryRows.first['form_json']?.toString() ?? '';
        if (s.isNotEmpty) {
          final decoded = jsonDecode(s);
          final formData = (decoded is Map) ? Map<String, dynamic>.from(decoded['form_data'] as Map? ?? {}) : <String, dynamic>{};
          
          final outcomeCount = formData['outcome_count']?.toString() ?? '';
          if (outcomeCount.isNotEmpty) {
            final n = int.tryParse(outcomeCount);
            if (n != null && n >= 1) {
              print('👶 Child count from delivery outcome: $n for beneficiary $beneficiaryId');
              return (n > 3 ? 3 : n);
            }
          }
        }
      }
      
      return 1;
    } catch (e) {
      print('❌ Error determining child_tab_count for $beneficiaryId: $e');
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> _getDeliveryOutcomeData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final validBeneficiaries = await db.rawQuery('''
      SELECT DISTINCT mca.beneficiary_ref_key 
      FROM mother_care_activities mca
      WHERE mca.mother_care_state ='pnc_mother'
      AND mca.is_deleted = 0
      AND mca.current_user_key = ?
    ''', [ashaUniqueKey]);

      if (validBeneficiaries.isEmpty) {
        print('No beneficiaries found with pnc_mother or hbnc_visit state');
        return [];
      }

      final beneficiaryKeys = validBeneficiaries.map((e) => e['beneficiary_ref_key']).toList();

      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');

      final query = '''
      SELECT * FROM followup_form_data 
      WHERE forms_ref_key = ? 
      AND current_user_key = ?
      AND beneficiary_ref_key IN ($placeholders)
      ORDER BY created_date_time DESC
    ''';

      final results = await db.rawQuery(
        query,
        [deliveryOutcomeKey, ashaUniqueKey, ...beneficiaryKeys],
      );

      print('Fetched ${results.length} delivery outcome records with valid mother care states');
      return results;
    } catch (e) {
      print('Error fetching delivery outcome data: $e');
      return [];
    }
  }

  Future<void> _loadPregnancyOutcomeeCouples() async {
    setState(() => _isLoading = true);
    _filtered = [];

    final Set<String> processedBeneficiaries = <String>{};

    try {
      final dbOutcomes = await _getDeliveryOutcomeData();
      print('Found ${dbOutcomes.length} delivery outcomes');

      if (dbOutcomes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      for (final outcome in dbOutcomes) {
        try {
          final formJson = jsonDecode(outcome['form_json'] as String);
          final formData = formJson['form_data'] ?? {};
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          print('\nProcessing outcome ID: ${outcome['id']}');
          print('Beneficiary Ref Key: $beneficiaryRefKey');

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            print('⚠️ Missing beneficiary_ref_key in outcome: ${outcome['id']}');
            continue;
          }

          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            print('ℹ️ Skipping duplicate outcome for beneficiary: $beneficiaryRefKey');
            continue;
          }
          processedBeneficiaries.add(beneficiaryRefKey);

          final db = await DatabaseProvider.instance.database;
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiaryResults.isEmpty) {
            print('⚠️ No beneficiary found for key: $beneficiaryRefKey');
            continue;
          }

          final beneficiary = beneficiaryResults.first;
          print('Found beneficiary: ${beneficiary['id']}');

          final beneficiaryInfoRaw = beneficiary['beneficiary_info'] as String? ?? '{}';
          print('Raw beneficiary info: $beneficiaryInfoRaw');

          Map<String, dynamic> beneficiaryInfo;
          try {
            beneficiaryInfo = jsonDecode(beneficiaryInfoRaw);
            print('Parsed beneficiary info: $beneficiaryInfo');
          } catch (e) {
            print('Error parsing beneficiary info: $e');
            continue;
          }

          // Extract data based on the structure
          final name = beneficiaryInfo['memberName']?.toString() ??
              beneficiaryInfo['headName']?.toString() ?? 'N/A';
          final dob = beneficiaryInfo['dob']?.toString();
          final age = _calculateAge(dob);
          final gender = beneficiaryInfo['gender']?.toString() ?? 'N/A';
          final mobile = beneficiaryInfo['mobileNo']?.toString() ?? 'N/A';
          final rchId = beneficiaryInfo['RichID']?.toString() ??
              beneficiaryInfo['rchId']?.toString() ?? 'N/A';
          final husbandName = beneficiaryInfo['spouseName']?.toString() ??
              beneficiaryInfo['fatherName']?.toString() ?? 'N/A';

          final householdRefKey = beneficiary['household_ref_key']?.toString() ?? 'N/A';
          final createdDateTime = beneficiary['created_date_time']?.toString() ?? '';

          // Get registration date from mother_care_activities table for pnc_mother state
          String registrationDate = createdDateTime;
          try {
            final mcaResult = await db.query(
              'mother_care_activities',
              where: 'beneficiary_ref_key = ? AND mother_care_state = ? AND is_deleted = 0',
              whereArgs: [beneficiaryRefKey, 'pnc_mother'],
              orderBy: 'created_date_time DESC',
              limit: 1,
            );
            
            if (mcaResult.isNotEmpty) {
              final mcaCreatedDate = mcaResult.first['created_date_time']?.toString() ?? '';
              if (mcaCreatedDate.isNotEmpty) {
                registrationDate = mcaCreatedDate;
              }
            }
          } catch (e) {
            print('⚠️ Error fetching registration date from mother_care_activities: $e');
            // Fallback to beneficiary created date
          }

          print('🔍 FormData keys: ${formData.keys.toList()}');
          print('📅 Delivery date from formData: ${formData['delivery_date']}');
          print('📅 Delivery date type: ${formData['delivery_date'].runtimeType}');

          final visitCount = await _getVisitCount(beneficiaryRefKey);
          final previousHBNCDate = await _getLastVisitDate(beneficiaryRefKey);
          final deliveryDate = formData['delivery_date']?.toString();
          print('📅 Passing delivery date to _getNextVisitDate: $deliveryDate');
          final nextHBNCDate = await _getNextVisitDate(beneficiaryRefKey, deliveryDate);
          
          print('📊 Final values for beneficiary $beneficiaryRefKey:');
          print('  - Visit Count: $visitCount');
          print('  - Previous HBNC Date: $previousHBNCDate');
          print('  - Next HBNC Date: $nextHBNCDate');

          final formattedData = {
            // Display values (last 11 digits)
            'hhId': _getLastDigits(householdRefKey, 11),
            'beneficiaryId': _getLastDigits(beneficiaryRefKey, 11),

            // Full values for passing to next screen
            'fullHhId': householdRefKey,
            'fullBeneficiaryId': beneficiaryRefKey,

            // Other display data
            'registrationDate': _formatDate(registrationDate),
            'name': name,
            'age': age,
            'gender': gender,
            'mobile': mobile,
            'rchId': rchId,
            'husbandName': husbandName,
            'deliveryDate': formData['delivery_date']?.toString() ?? 'N/A',
            'deliveryType': formData['delivery_type']?.toString() ?? 'N/A',
            'placeOfDelivery': formData['place_of_delivery']?.toString() ?? 'N/A',
            'outcomeCount': formData['outcome_count']?.toString() ?? '1',
            'previousHBNCDate': previousHBNCDate,
            'nextHBNCDate': nextHBNCDate,
            'visitCount': visitCount,

            '_rawData': beneficiary,
            '_formData': formData,
          };

          print('Adding formatted data: $formattedData');
          setState(() {
            _filtered.add(formattedData);
          });

        } catch (e) {
          print('❌ Error processing outcome ${outcome['id']}: $e');
          if (e is Error) {
            print('Stack trace: ${e.stackTrace}');
          }
        }
      }
    } catch (e) {
      print('❌ Error in _loadPregnancyOutcomeeCouples: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    } finally {
      setState(() {
        _isLoading = false;
        print('Finished loading. Found ${_filtered.length} records.');
      });
    }
  }


  String _getLastDigits(String value, int count) {
    if (value.isEmpty || value == 'N/A') return value;
    return value.length > count ? value.substring(value.length - count) : value;
  }

  Future<String?> _getLastVisitDate(String beneficiaryId) async {
    try {
      print('🔍 Fetching last visit date for beneficiary: $beneficiaryId');
      final db = await DatabaseProvider.instance.database;

      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      print('🔑 Using form reference key: $hbncVisitKey');

      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      print('📋 Found ${results.length} HBNC visit records');

      if (results.isNotEmpty) {
        final result = results.first;
        print('📋 Found HBNC visit record with ID: ${result['id']}');
        print('📅 Raw form_json: ${result['form_json']}');

        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          print('🔍 Parsed form JSON successfully');
          
          // Check for hbyc_form structure first (based on sample data)
          if (formJson.containsKey('hbyc_form')) {
            final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};
            print('🔍 Found hbyc_form structure');
            
            if (hbycForm.containsKey('visitDetails')) {
              final visitDetails = hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
              print('🔍 Found visitDetails in hbyc_form');
              
              final visitDate = visitDetails['visitDate'];
              print('📅 Extracted visitDate from hbyc_form.visitDetails: $visitDate');
              
              if (visitDate != null && visitDate.toString().isNotEmpty) {
                final formattedDate = _formatDate(visitDate.toString());
                print('✅ Using visit date from hbyc_form.visitDetails: $formattedDate');
                return formattedDate;
              } else {
                print('⚠️ visitDate is null or empty in hbyc_form.visitDetails');
              }
            } else {
              print('⚠️ No visitDetails found in hbyc_form');
            }
          } else {
            print('⚠️ No hbyc_form found in form JSON');
          }
          
          // Fallback to form_data structure
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};
          print('🔑 Checking form_data structure');
          print('🔑 Form data keys: ${formData.keys.toList()}');

          // Debug: Print full form data structure
          print('🔍 Full form data structure:');
          print(jsonEncode(formData));

          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'];
            print('🔍 Found visitDetails: ${visitDetails.runtimeType}');

            if (visitDetails is Map) {
              final visitDate = visitDetails['visitDate'] ??
                  visitDetails['visit_date'] ??
                  visitDetails['dateOfVisit'] ??
                  visitDetails['date_of_visit'];

              print('📅 Extracted visit date from visitDetails: $visitDate');

              if (visitDate != null && visitDate.toString().isNotEmpty) {
                final formattedDate = _formatDate(visitDate.toString());
                print('✅ Using visit date from visitDetails: $formattedDate');
                return formattedDate;
              }
            }
          } else {
            print('⚠️ No visitDetails found in form_data');
          }

          // Try to get visit date directly from form data (check multiple possible field names)
          final visitDate = formData['visit_date'] ??
              formData['visitDate'] ??
              formData['dateOfVisit'] ??
              formData['date_of_visit'] ??
              formData['visitDate'];

          if (visitDate != null && visitDate.toString().isNotEmpty) {
            print('📅 Found visit date in form data: $visitDate');
            final formattedDate = _formatDate(visitDate.toString());
            print('✅ Using visit date from form data: $formattedDate');
            return formattedDate;
          }

          // Fall back to created_date_time
          final createdDate = result['created_date_time'];
          if (createdDate != null && createdDate.toString().isNotEmpty) {
            print('⏰ Using created_date_time as fallback: $createdDate');
            final formattedDate = _formatDate(createdDate.toString());
            print('✅ Using created_date_time: $formattedDate');
            return formattedDate;
          }

          print('⚠️ No valid date found in form data');
          return null;

        } catch (e) {
          print('❌ Error parsing form data: $e');
          // Try to return created_date_time as last resort
          final createdDate = result['created_date_time'];
          if (createdDate != null && createdDate.toString().isNotEmpty) {
            print('🔄 Falling back to created_date_time due to error');
            return _formatDate(createdDate.toString());
          }
          return null;
        }
      } else {
        print('ℹ️ No HBNC visit records found for beneficiary');
      }
    } catch (e) {
      print('❌ Error in _getLastVisitDate: $e');
    }
    return null;
  }

  Future<String?> _getNextVisitDate(String beneficiaryId, String? deliveryDate) async {
    try {
      print('🔍 Calculating next visit date for beneficiary: $beneficiaryId');
      
      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      
      // Get the latest visit record to extract visit number and date
      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );
      
      print('📋 Found ${latestVisitRows.length} visit records');
      
      if (latestVisitRows.isNotEmpty) {
        final result = latestVisitRows.first;
        print('📋 Processing visit record ID: ${result['id']}');
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          print('🔍 Parsed form JSON');
          
          // Check for hbyc_form structure first (based on sample data)
          if (formJson.containsKey('hbyc_form')) {
            final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};
            print('🔍 Found hbyc_form structure');
            
            if (hbycForm.containsKey('visitDetails')) {
              final visitDetails = hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
              print('🔍 Found visitDetails in hbyc_form');
              
              final visitNumber = visitDetails['visitNumber']?.toString();
              final visitDate = visitDetails['visitDate']?.toString();
              
              print('📊 Visit number: $visitNumber');
              print('📅 Visit date: $visitDate');
              
              if (visitNumber != null && visitDate != null) {
                final number = int.tryParse(visitNumber);
                final date = DateTime.tryParse(visitDate);
                
                print('🔢 Parsed visit number: $number');
                print('📅 Parsed visit date: $date');
                
                if (number != null && date != null) {
                  // For all visits, calculate next visit based on the visit date itself
                  // The visit date becomes the base for calculating the next visit
                  final nextVisitDate = _calculateNextVisitDate(number, date);
                  if (nextVisitDate != null) {
                    final formatted = _formatDate(nextVisitDate.toString());
                    print('📅 Calculated next visit date from visit date: visit $number on ${_formatDate(date.toString())} → $formatted');
                    return formatted;
                  }
                }
              }
            }
          }
          
          // Fallback to form_data structure
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};
          print('🔍 Checking form_data structure');
          
          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'] as Map<String, dynamic>? ?? {};
            final visitNumber = visitDetails['visitNumber']?.toString() ??
                visitDetails['visit_number']?.toString();
            final visitDate = visitDetails['visitDate']?.toString() ??
                visitDetails['visit_date']?.toString();
            
            print('📊 Visit number from form_data: $visitNumber');
            print('📅 Visit date from form_data: $visitDate');
            
            if (visitNumber != null && visitDate != null) {
              final number = int.tryParse(visitNumber);
              final date = DateTime.tryParse(visitDate);
              
              if (number != null && date != null) {
                // For all visits, calculate next visit based on the visit date itself
                // The visit date becomes the base for calculating the next visit
                final nextVisitDate = _calculateNextVisitDate(number, date);
                if (nextVisitDate != null) {
                  final formatted = _formatDate(nextVisitDate.toString());
                  print('📅 Calculated next visit date from visit date: visit $number on ${_formatDate(date.toString())} → $formatted');
                  return formatted;
                }
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing visit data for next visit calculation: $e');
        }
      } else {
        print('ℹ️ No visit records found - using registration date as base');
        
        // For first-time beneficiaries, get registration date and calculate next visit
        final beneficiaryRows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ?',
          whereArgs: [beneficiaryId],
          columns: ['created_date_time'],
        );
        
        if (beneficiaryRows.isNotEmpty) {
          final registrationDate = beneficiaryRows.first['created_date_time']?.toString();
          if (registrationDate != null) {
            // For first-time beneficiary (no visit records), show registration date only
            final formatted = _formatDate(registrationDate);
            print('📅 First-time beneficiary, showing registration date only: $registrationDate → $formatted');
            return formatted;
          }
        }
        
        // Fallback: Use current date if registration date not available
        print('⚠️ Registration date not found, using current date as fallback');
        final today = DateTime.now();
        final nextVisitDate = today.add(const Duration(days: 2));
        final formatted = _formatDate(nextVisitDate.toString());
        print('📅 Default next visit date set: $formatted');
        return formatted;
      }
      
    } catch (e) {
      print('❌ Error calculating next visit date: $e');
      return null;
    }
  }
  
  DateTime? _calculateNextVisitDate(int currentVisitNumber, DateTime currentVisitDate) {
    switch (currentVisitNumber) {
      case 0: // Day 0 → Day 1 (within 24 hours of birth)
      case 1: // Day 1 → Day 3 (after 2 days)
        return currentVisitDate.add(const Duration(days: 2));
      case 3: // Day 3 → Day 7 (after 4 days)
        return currentVisitDate.add(const Duration(days: 4));
      case 7: // Day 7 → Day 14 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 14: // Day 14 → Day 21 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 21: // Day 21 → Day 28 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 28: // Day 28 → Day 42 (after 14 days)
        return currentVisitDate.add(const Duration(days: 14));
      default:
        // For any other visit number, add 7 days as default
        return currentVisitDate.add(const Duration(days: 7));
    }
  }

  int _calculateAge(dynamic dob) {
    if (dob == null) return 0;
    try {
      final birthDate = DateTime.tryParse(dob.toString());
      if (birthDate == null) return 0;
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      print('🔍 Formatting date: $dateStr');
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) {
        print('❌ Failed to parse date: $dateStr');
        return '';
      }
      final formatted = '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      print('✅ Formatted date: $formatted');
      return formatted;
    } catch (e) {
      print('❌ Error formatting date: $dateStr, error: $e');
      return '';
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _loadPregnancyOutcomeeCouples();
      } else {
        _filtered = _filtered.where((e) {
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobile'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.pushReplacementNamed(context, Route_Names.Mothercarehomescreen);
        }
        return false;
      },
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n!.hbncListTitle,
          showBack: true,
          onBackTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, Route_Names.Mothercarehomescreen);
            }
          },
        ),

        body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.searchHBNC ?? 'search Eligible Couple',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

          // Household List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final data = _filtered[index];
                return _householdCard(context, data);
              },
            ),
          ),

        ],
        ),
      ),
    );
  }
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {

          print('🔵 Navigating to HbncVisitScreen');
          print('🆔 Complete Household ID: ${data['fullHhId']}');
          print('🆔 Complete Beneficiary ID: ${data['fullBeneficiaryId']}');
          print('👤 Name: ${data['name']}');


          // Pass only beneficiary ID, household ID, and name
          final childTabCount = await _getChildTabCount(data['fullBeneficiaryId']?.toString() ?? '');
          print('👤 tabcount: ${data['child_tab_count']}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HbncVisitScreen(
                beneficiaryData: {
                  'unique_key': data['fullBeneficiaryId'],
                  'household_ref_key': data['fullHhId'],
                  'name': data['name'],
                  'child_tab_count': childTabCount,
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(),
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
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Colors.black54, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['hhId']?.toString() ?? 'N/A',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<int>(
                      future: _getVisitCount(data['fullBeneficiaryId']?.toString() ?? ''),
                      builder: (context, snapshot) {
                        final visitCount = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Text(
                              '${t!.visitsLabel} : ',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$visitCount',
                              style: TextStyle(
                                color: primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Replace the existing sync icon with this code
                    // Replace the existing sync icon with this code
                    // Replace the existing sync icon with this code
                    FutureBuilder<bool>(
                      future: _isSynced(data['fullBeneficiaryId']?.toString() ?? ''),
                      builder: (context, snapshot) {
                        final isSynced = snapshot.data ?? false;
                        return SizedBox(
                          width: 24,
                          height: 24,
                          child: Image.asset(
                            'assets/images/sync.png',
                            color: isSynced ? null : Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Body with all information
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _rowText(
                            t!.registrationDate,
                            data['registrationDate']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.beneficiaryId,
                            data['beneficiaryId']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.rchIdLabel,
                            data['rchId']?.toString() ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Second Row: Name, Age | Gender, Husband Name
                    Row(
                      children: [
                        Expanded(
                          child: _rowText(
                            t.nameLabel,
                            data['name']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.ageGenderLabel,
                            '${data['age']?.toString() ?? '0'} Y | ${data['gender']?.toString() ?? 'N/A'}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.husbandName,
                            data['husbandName']?.toString() ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _rowText(
                            t.mobileNumber,
                            data['mobile']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.previousHBNCDate,
                            (data['visitCount'] as int?) != null && (data['visitCount'] as int) > 0
                                ? data['previousHBNCDate']?.toString() ?? 'Not Available'
                                : 'Not Available',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            t.nextHBNCDate,
                            (() {
                              final nextDate = data['nextHBNCDate']?.toString() ?? 'Not Available';
                              print('🎯 Displaying next HBNC date in UI: $nextDate');
                              return nextDate;
                            })(),
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
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
