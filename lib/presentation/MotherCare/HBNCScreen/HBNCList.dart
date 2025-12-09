import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
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
  Future<bool> _isSynced(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final result = await db.query(
        'mother_care_activities',
        where: 'beneficiary_ref_key = ? AND mother_care_state = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey, 'hbnc_visit'],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['is_synced'] == 1;
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
      final refKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
      if (refKey.isEmpty) return 1;
      final rows = await db.rawQuery(
        'SELECT * FROM ${FollowupFormDataTable.table} WHERE forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0 ORDER BY created_date_time DESC LIMIT 1',
        [refKey, beneficiaryId],
      );
      if (rows.isEmpty) return 1;
      final s = rows.first['form_json']?.toString() ?? '';
      if (s.isEmpty) return 1;
      final decoded = jsonDecode(s);
      final fd = (decoded is Map) ? Map<String, dynamic>.from(decoded['form_data'] as Map? ?? {}) : <String, dynamic>{};
      final raw = fd['number_of_children']?.toString().trim().toLowerCase() ?? '';
      if (raw.isEmpty) return 1;
      if (raw == 'one' || raw == 'single' || raw == '1') return 1;
      if (raw == 'twins' || raw == 'twin' || raw == '2') return 2;
      if (raw == 'triplets' || raw == 'triplet' || raw == '3') return 3;
      final n = int.tryParse(raw);
      return (n == null || n < 1) ? 1 : (n > 3 ? 3 : n);
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

      final results = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ? AND current_user_key = ?',
        whereArgs: [deliveryOutcomeKey, ashaUniqueKey],
      );

      print('Fetched ${results.length} delivery outcome records');
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

          // Skip if this beneficiary has already been processed
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

           
          final visitCount = await _getVisitCount(beneficiaryRefKey);
          final previousHBNCDate = await _getLastVisitDate(beneficiaryRefKey);
          final nextHBNCDate = await _getNextVisitDate(beneficiaryRefKey, formData['delivery_date']?.toString());

          final formattedData = {
            // Display values (last 11 digits)
            'hhId': _getLastDigits(householdRefKey, 11),
            'beneficiaryId': _getLastDigits(beneficiaryRefKey, 11),

            // Full values for passing to next screen
            'fullHhId': householdRefKey,
            'fullBeneficiaryId': beneficiaryRefKey,

            // Other display data
            'registrationDate': _formatDate(createdDateTime),
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

      if (results.isNotEmpty) {
        final result = results.first;
        print('📋 Found HBNC visit record with ID: ${result['id']}');
        print('📅 Raw form_json: ${result['form_json']}');

        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

          print('🔑 Form data:');
          formData.forEach((key, value) {
            print('  - $key: $value (${value.runtimeType})');
          });

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
      final lastVisit = await _getLastVisitDate(beneficiaryId);
      if (lastVisit != null) {
        // If we have a last visit date, add 7 days to it
        final lastVisitDate = DateTime.tryParse(lastVisit.split('-').reversed.join('-'));
        if (lastVisitDate != null) {
          final nextVisit = lastVisitDate.add(const Duration(days: 7));
          return _formatDate(nextVisit.toString());
        }
      }

      // Fall back to adding 1 day to delivery date if no last visit
      if (deliveryDate != null) {
        final delivery = DateTime.tryParse(deliveryDate);
        if (delivery != null) {
          final nextVisit = delivery.add(const Duration(days: 1));
          return _formatDate(nextVisit.toString());
        }
      }
    } catch (e) {
      print('❌ Error calculating next visit date: $e');
    }
    return null;
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
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
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
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'HBNC List',
        showBack: true,



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
                              'Visits : ',
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
                    // First Row: Registration Date, Beneficiary ID, RCH ID
                    Row(
                      children: [
                        Expanded(
                          child: _rowText(
                            'Registration Date',
                            data['registrationDate']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'Beneficiary ID',
                            data['beneficiaryId']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'RCH ID',
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
                            'Name',
                            data['name']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'Age | Gender',
                            '${data['age']?.toString() ?? '0'} Y | ${data['gender']?.toString() ?? 'N/A'}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'Husband Name',
                            data['husbandName']?.toString() ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Third Row: Mobile no., Previous HBNC Date, Next HBNC Date
                    Row(
                      children: [
                        Expanded(
                          child: _rowText(
                            'Mobile no.',
                            data['mobile']?.toString() ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'Previous HBNC Date',
                            (data['visitCount'] as int?) != null && (data['visitCount'] as int) > 0 
                                ? data['previousHBNCDate']?.toString() ?? 'Not Available'
                                : 'Not Available',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _rowText(
                            'Next HBNC Date',
                            data['nextHBNCDate']?.toString() ?? 'Not Available',
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
