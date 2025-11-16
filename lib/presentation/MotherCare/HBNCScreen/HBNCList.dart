import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../data/Local_Storage/database_provider.dart';
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

  // Method to fetch delivery outcome data from followup_form_data table
  Future<List<Map<String, dynamic>>> _getDeliveryOutcomeData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey = '4r7twnycml3ej1vg';

      final results = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ?',
        whereArgs: [deliveryOutcomeKey],
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

          final db = await DatabaseProvider.instance.database;
          final beneficiaryResults = await db.query(
            'beneficiaries',
            where: 'unique_key = ? AND is_deleted = 0',
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

          // Get HBNC visit dates
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
            'previousHBNCDate': previousHBNCDate ?? 'Unavailable',
            'nextHBNCDate': nextHBNCDate ?? 'Unavailable',

            // Raw data for next screen
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

  // Helper to get last N digits
  String _getLastDigits(String value, int count) {
    if (value.isEmpty || value == 'N/A') return value;
    return value.length > count ? value.substring(value.length - count) : value;
  }

  // Helper to get last visit date
  Future<String?> _getLastVisitDate(String beneficiaryId) async {
    try {
      final db = await DatabaseProvider.instance.database;
      // Replace 'hbnc_visit_form_key' with your actual HBNC form key
      final results = await db.query(
        'followup_form_data',
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
        whereArgs: [beneficiaryId, 'hbnc_visit_form_key'],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        final formJson = jsonDecode(results.first['form_json'] as String);
        final visitDate = formJson['form_data']?['visit_date'];
        return visitDate != null ? _formatDate(visitDate.toString()) : null;
      }
    } catch (e) {
      print('Error getting last visit date: $e');
    }
    return null;
  }

  // Helper to calculate next visit date
  Future<String?> _getNextVisitDate(String beneficiaryId, String? deliveryDate) async {
    if (deliveryDate == null) return null;

    try {
      final lastVisit = await _getLastVisitDate(beneficiaryId);
      if (lastVisit == null) {
        final delivery = DateTime.parse(deliveryDate);
        final nextVisit = delivery.add(const Duration(days: 1));
        return _formatDate(nextVisit.toString());
      }
    } catch (e) {
      print('Error calculating next visit date: $e');
    }
    return null;
  }

  // Helper method to calculate age from DOB
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

  Future<int> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getVisitCount');
        return 0;
      }

      print('🔍 Getting visit count for beneficiary: $beneficiaryId');
      final count = await SecureStorageService.getVisitCount(beneficiaryId);
      print('📊 Retrieved count for $beneficiaryId: $count');

      try {
        final allKeys = await const FlutterSecureStorage().readAll();
        print('🔑 All secure storage keys:');
        allKeys.forEach((key, value) {
          if (key.startsWith('submission_count_')) {
            print('   - $key: $value');
          }
        });
      } catch (e) {
        print('⚠️ Error reading secure storage keys: $e');
      }

      return count;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.pregnancyOutcome ?? '',
        showBack: false,
        icon1Image: 'assets/images/home.png',

        onIcon1Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.searchEligibleCouple ?? 'search Eligible Couple',
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
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Print the complete IDs before navigation
          print('🔵 Navigating to HbncVisitScreen');
          print('🆔 Complete Household ID: ${data['fullHhId']}');
          print('🆔 Complete Beneficiary ID: ${data['fullBeneficiaryId']}');
          print('👤 Name: ${data['name']}');

          // Pass only beneficiary ID, household ID, and name
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HbncVisitScreen(
                beneficiaryData: {
                  'unique_key': data['fullBeneficiaryId'],
                  'household_ref_key': data['fullHhId'],
                  'name': data['name'],
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
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
              // Header with HH ID and Visits count
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
                          fontSize: 16,
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
                                fontSize: 14,
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
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_done,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
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
                            data['previousHBNCDate']?.toString() ?? 'Not Available',
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

// Helper method for row text styling
  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.background,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}