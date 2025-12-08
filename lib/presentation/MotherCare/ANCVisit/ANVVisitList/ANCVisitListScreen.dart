import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';

import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';

import '../../../../data/Database/database_provider.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../ANCVisitForm/ANCVisitForm.dart';

class Ancvisitlistscreen extends StatefulWidget {
  const Ancvisitlistscreen({super.key});

  @override
  State<Ancvisitlistscreen> createState() => _AncvisitlistscreenState();
}

class _AncvisitlistscreenState extends State<Ancvisitlistscreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  Future<List<Map<String, dynamic>>> _getAncDueRecords() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final List<Map<String, dynamic>> ancDueRecords = await db.rawQuery('''
        SELECT 
          mca.*,
          bn.*,
          mca.id as mca_id,  
          bn.id as beneficiary_id
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' AND bn.is_deleted = 0
      ''');

      print('ℹ️ Found ${ancDueRecords.length} anc_due records with valid beneficiary references');

      // Process the records to include beneficiary info
      return ancDueRecords.map((record) {
        // Extract beneficiary info
        final beneficiaryInfo = {
          'id': record['beneficiary_id'],
          'unique_key': record['unique_key'],
          'memberName': record['memberName'],
          'headName': record['headName'],
          'gender': record['gender'],
          'dob': record['dob'],
          'mobileNo': record['mobileNo'],
          'isPregnant': 'yes',  // Since we're in ANC visit list
          'RCH_ID': record['RCH_ID'],
          'spouseName': record['spouseName'],
          'beneficiary_info': jsonEncode({
            'memberName': record['memberName'] ?? record['headName'],
            'headName': record['headName'],
            'gender': record['gender'],
            'dob': record['dob'],
            'mobileNo': record['mobileNo'],
            'isPregnant': 'yes',
            'RCH_ID': record['RCH_ID'],
            'spouseName': record['spouseName'],
          }),
        };


        return {
          ...record,
          'beneficiary_info': jsonEncode(beneficiaryInfo),
          'isAncDue': true,
          'Name': record['memberName'] ?? record['headName'] ?? 'Unknown',
          'Husband': record['spouseName'] ?? record['headName'] ?? 'N/A',
          'RCH ID': record['RCH_ID'] ?? 'N/A',
          'Age': _calculateAge(record['dob'] ?? '')?.toString() ?? 'N/A',
          'RegistrationDate': record['created_date_time'] ?? 'N/A',
        };
      }).toList();
    } catch (e) {
      print('⚠️ Error fetching anc_due records: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> _getSyncStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'mother_care_activities',
        columns: ['is_synced', 'server_id', 'created_date_time'],
        where: 'beneficiary_ref_key = ? AND is_deleted = 0 ',
        whereArgs: [beneficiaryRefKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return {
          'is_synced': rows.first['is_synced'] == 1,
          'server_id': rows.first['server_id']
        };
      }

      return {'is_synced': false, 'server_id': null};
    } catch (e) {
      print('Error fetching sync status: $e');
      return {'is_synced': false, 'server_id': null};
    }
  }

  Future<void> _loadPregnantWomen() async {
    setState(() {
      _isLoading = true;
    });
    
    try {

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];
      final Set<String> processedBeneficiaries = {}; // To track already processed beneficiaries

      print('ℹ️ Found ${rows.length} beneficiaries to process');

      // First, get all anc_due records to avoid duplicate DB queries
      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords.map((e) => e['beneficiary_ref_key']?.toString() ?? '').toSet();
      
      // Get all delivery outcomes to exclude those records
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomes = await db.query(
        'followup_form_data',
        where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND form_json LIKE '%\"gives_birth_to_baby\":\"Yes\"%'",
        columns: ['beneficiary_ref_key']
      );
      final deliveredBeneficiaryIds = deliveryOutcomes
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      print('ℹ️ Found ${deliveredBeneficiaryIds.length} beneficiaries with delivery outcomes');

      for (final row in rows) {
        try {
          // Parse the beneficiary info
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) {
            print(' Skipping - No beneficiary_info found');
            continue;
          }

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print(' Error parsing beneficiary_info: $e');
            continue;
          }

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final beneficiaryId = row['unique_key']?.toString() ?? '';
          
          // Check if this beneficiary is in anc_due records
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);
          
          // Skip if this beneficiary already has a delivery outcome
          if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
            print('  ⏩ Skipping - Already has delivery outcome');
            continue;
          }

          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            print('  🤰 Found ${isAncDue ? 'anc_due ' : ''}pregnant woman: $name (${isPregnant ? 'pregnant' : 'anc_due only'})');
            final personData = _processPerson(row, info, isPregnant: isPregnant || isAncDue);
            if (personData != null) {
              // Mark if this is an anc_due record
              personData['isAncDue'] = isAncDue;
              print('  ✅ Added ${isAncDue ? "anc_due " : ""}pregnant woman: ${personData['Name']}');
              pregnantWomen.add(personData);
              processedBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (e, stackTrace) {
          print('⚠️ Error processing beneficiary row: $e');
          print('Stack trace: $stackTrace');
        }
      }

      // Add any anc_due records that weren't in the regular beneficiaries list
      for (final ancDueRecord in ancDueRecords) {
        final beneficiaryId = ancDueRecord['beneficiary_ref_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty || processedBeneficiaries.contains(beneficiaryId)) {
          continue; // Skip if already processed or no beneficiary ID
        }

        try {
          // For anc_due records not in regular beneficiaries, create a minimal record
          final personData = {
            'id': ancDueRecord['id']?.toString() ?? '',
            'unique_key': beneficiaryId,
            'BeneficiaryID': beneficiaryId,
            'hhId': ancDueRecord['household_ref_key']?.toString() ?? '',
            'unique_key_display': _getLast11Chars(beneficiaryId),
            'BeneficiaryID_display': _getLast11Chars(beneficiaryId),
            'hhId_display': _getLast11Chars(ancDueRecord['household_ref_key']?.toString() ?? ''),
            'Name': 'ANC Due - ${_getLast11Chars(beneficiaryId)}',
            'isAncDue': true,
            'RegistrationDate': ancDueRecord['created_date_time']?.toString() ?? '',
            '_rawRow': ancDueRecord,
          };
          
          print('  ✅ Added anc_due only record: ${personData['Name']}');
          pregnantWomen.add(personData);
        } catch (e, stackTrace) {
          print('⚠️ Error processing anc_due record: $e');
          print('Stack trace: $stackTrace');
        }
      }


      final Map<String, Map<String, dynamic>> byBeneficiary = {};
      for (final item in pregnantWomen) {
        final benId = item['BeneficiaryID']?.toString() ?? '';
        final uniqueKey = item['unique_key']?.toString() ?? '';
        final key = benId.isNotEmpty ? benId : uniqueKey;
        if (key.isEmpty) continue;
         byBeneficiary[key] = item;
      }

      // Convert to list and sort by registration date (newest first)
      final dedupedList = byBeneficiary.values.toList();
      dedupedList.sort((a, b) {
        final dateA = DateTime.tryParse(a['_rawRow']?['created_date_time']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['_rawRow']?['created_date_time']?.toString() ?? '');
        
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Descending order (newest first)
      });

      setState(() {
        _allData = dedupedList;
        _filtered = dedupedList;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Fatal error in _loadPregnantWomen: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getLast11Chars(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }


  DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
    final days = noOfWeeks * 7;
    return startDate.add(Duration(days: days));
  }


  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  Map<String, DateTime> _calculateAncDateRanges(DateTime lmp) {
    final ranges = <String, DateTime>{};

    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = _dateAfterWeeks(lmp, 12);

    ranges['2nd_anc_start'] = _dateAfterWeeks(lmp, 14);
    ranges['2nd_anc_end'] = _dateAfterWeeks(lmp, 24);
     ranges['3rd_anc_start'] = _dateAfterWeeks(lmp, 26);
    ranges['3rd_anc_end'] = _dateAfterWeeks(lmp, 34);

     ranges['4th_anc_start'] = _dateAfterWeeks(lmp, 36);
    ranges['4th_anc_end'] = _calculateEdd(lmp);

     ranges['pmsma_start'] = _dateAfterWeeks(lmp, 40);
    ranges['pmsma_end'] = _dateAfterWeeks(lmp, 44);

    return ranges;
  }

  // Format date to dd/MM/yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Map<String, dynamic>? _processPerson(
      Map<String, dynamic> row,
      Map<String, dynamic> person, {
        required bool isPregnant,
      }) {
    try {
      final name = person['memberName'] ?? person['headName'] ?? 'Unknown';
      final gender = person['gender']?.toString().toLowerCase() ?? '';
      final dob = person['dob'];
      final age = _calculateAge(dob);
      final spouseName = person['spouseName'] ?? person['headName'] ?? '';

      // Store COMPLETE IDs
      final householdRefKey = row['household_ref_key']?.toString() ?? '';
      final uniqueKey = row['unique_key']?.toString() ?? '';

      // Get TRIMMED versions for display only
      final householdRefKeyDisplay = _getLast11Chars(householdRefKey);
      final uniqueKeyDisplay = _getLast11Chars(uniqueKey);

      final registrationDate = row['created_date_time']?.toString() ?? '';

      if (!isPregnant) return null;

      // Format registration date if available
      String formattedDate = 'N/A';
      if (registrationDate.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(registrationDate);
          formattedDate = '${dateTime.day}-${dateTime.month}-${dateTime.year}';
        } catch (e) {
          print('⚠️ Error parsing date: $e');
        }
      }

      return {
        'id': row['id']?.toString() ?? '',

        'unique_key': uniqueKey,
        'BeneficiaryID': uniqueKey,
        'hhId': householdRefKey,

        'unique_key_display': uniqueKeyDisplay,
        'BeneficiaryID_display': uniqueKeyDisplay,
        'hhId_display': householdRefKeyDisplay,
        // Other fields
        'Name': name,
        'Age': age?.toString() ?? 'N/A',
        'Gender': 'Female',
        'RCH ID': person['RCH_ID'] ?? person['RichID'] ?? 'N/A',
        'Mobile No': person['mobileNo'] ?? '',
        'Husband': spouseName,
        'RegistrationDate': formattedDate,
        'beneficiary_info': jsonEncode(person),
        '_rawRow': row,
      };
    } catch (e) {
      print('⚠️ Error processing person: $e');
      return null;
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    try {
      DateTime? birthDate;
      if (dob is String) {
        birthDate = DateTime.tryParse(dob);
      } else if (dob is DateTime) {
        birthDate = dob;
      }

      if (birthDate == null) return null;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      print('⚠️ Error calculating age: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getVisitCount');
        return {'count': 0, 'isHighRisk': false};
      }

      print('🔍 Fetching visit count and high-risk status for beneficiary: $beneficiaryId');
      final result = await LocalStorageDao.instance.getANCVisitCount(beneficiaryId);
      print('✅ Visit details for $beneficiaryId: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return {'count': 0, 'isHighRisk': false};
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadPregnantWomen();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filtered = _allData;
      });
    } else {
      setState(() {
        _filtered = _allData.where((e) {
          return (e['Name']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['Age']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['RCH ID']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['Husband']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['BeneficiaryID']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
      });
    }
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pregnant_woman, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No pregnant women found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Register new ANC cases in the family registration',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final item = _filtered[index];
            return _ancCard(context, item);
          },
        ),
      ),
    );
  }

  Widget _ancCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final isAncDue = data['isAncDue'] == true;

    final registrationDate = data['RegistrationDate'] is String && data['RegistrationDate'].isNotEmpty
        ? data['RegistrationDate']
        : l10n?.notAvailable ?? 'N/A';

    final ageGender = '${data['Age']} Y';

    // Use COMPLETE IDs for functionality
    final uniqueKey = data['unique_key']?.toString() ?? '';
    final beneficiaryId = data['BeneficiaryID']?.toString() ?? '';
    final hhId = data['hhId']?.toString() ?? '';

    // Use DISPLAY versions for UI
    final uniqueKeyDisplay = data['unique_key_display']?.toString() ?? data['BeneficiaryID_display']?.toString() ?? '';
    final hhIdDisplay = data['hhId_display']?.toString() ?? '';

    final husbandName = data['Husband'] is String && data['Husband'].isNotEmpty
        ? data['Husband']
        : l10n?.notAvailable ?? 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        // Get the visit count and high risk status before navigating
        final visitData = await (beneficiaryId.isNotEmpty
            ? _getVisitCount(beneficiaryId)
            : Future.value({'count': 0, 'isHighRisk': false}));

        final formData = Map<String, dynamic>.from(data);

        formData['hhId'] = hhId;
        formData['BeneficiaryID'] = beneficiaryId;
        formData['unique_key'] = uniqueKey;
        formData['visitCount'] = visitData['count'] ?? 0;
        formData['isHighRisk'] = visitData['isHighRisk'] ?? false;
        formData['woman_name'] = data['Name']?.toString() ?? '';
        formData['husband_name'] = data['Husband']?.toString() ?? '';

        try {
          if (beneficiaryId.isNotEmpty) {
            final ancForms = await LocalStorageDao.instance.getAncFormsByBeneficiaryId(beneficiaryId);
            if (ancForms.isNotEmpty) {
              final latest = ancForms.first;
              Map<String, dynamic> fd = {};
              if (latest['form_data'] is Map) {
                fd = Map<String, dynamic>.from(latest['form_data'] as Map);
              } else if (latest['form_json'] is String && (latest['form_json'] as String).isNotEmpty) {
                try {
                  final decoded = jsonDecode(latest['form_json'] as String);
                  if (decoded is Map && decoded['form_data'] is Map) {
                    fd = Map<String, dynamic>.from(decoded['form_data'] as Map);
                  }
                } catch (_) {}
              }
              if (fd.isNotEmpty) {
                formData['prefill'] = fd;
              }
            }
          }
        } catch (_) {}

        print('Passing visit data to form: $visitData');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Ancvisitform(beneficiaryData: formData),
          ),
        ).then((_) => _onRefresh());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        hhIdDisplay.isNotEmpty ? hhIdDisplay : 'N/A',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<Map<String, dynamic>>(
                    future: beneficiaryId.isNotEmpty
                        ? _getVisitCount(beneficiaryId)
                        : Future.value({'count': 0, 'isHighRisk': false}),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          '${l10n?.visitsLabel ?? 'Visits :'} ...',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('❌ Error fetching visit details: ${snapshot.error}');
                        return Text(
                          '${l10n?.visitsLabel ?? 'Visits :'} ?',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        );
                      }

                      final count = snapshot.data?['count'] ?? 0;
                      final isHighRisk = snapshot.data?['isHighRisk'] == true;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHighRisk) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'HRP',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],


                          Text(
                            '${isAncDue ? 'DUE - ' : ''}${l10n?.visitsLabel ?? 'Visits :'} $count',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),

                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getSyncStatus(beneficiaryId),
                    builder: (context, snapshot) {
                      final isSynced = snapshot.data?['is_synced'] == true;
                      return Image.asset(
                        'assets/images/sync.png',
                        width: 25,
                        color: isSynced ? null : Colors.grey[500],
                      );
                    },
                  )
                ],
              ),
            ),

            // Colored body
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isAncDue ? AppColors.primary : primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Row: 6 items - use DISPLAY version (trimmed)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          uniqueKeyDisplay.isNotEmpty ? uniqueKeyDisplay : 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(
                          l10n?.nameLabel ?? 'Name',
                          data['Name'] ?? 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(
                          l10n?.ageLabel ?? 'Age/Gender',
                          ageGender,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 49,
                        child: _rowText(
                          l10n?.husbandLabel ?? 'Husband',
                          husbandName,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          registrationDate,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 7 - 13,
                        child: _rowText(
                          l10n?.rchIdLabel ?? 'RCH ID',
                          data['RCH ID'] ?? 'N/A',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  FutureBuilder<Map<String, dynamic>>(
                    future: beneficiaryId.isNotEmpty
                        ? _getVisitCount(beneficiaryId)
                        : Future.value({'count': 0, 'isHighRisk': false}),
                    builder: (context, snapshot) {
                      final visitCount = snapshot.data?['count'] ?? 0;
                      final isHighRisk = snapshot.data?['isHighRisk'] == true;

                       DateTime? lmpDate;
                      try {
                        final rawRow = data['_rawRow'] as Map<String, dynamic>?;
                        dynamic rawInfo = rawRow?['beneficiary_info'];
                        Map<String, dynamic> info;

                        if (rawInfo is String && rawInfo.isNotEmpty) {
                          info = jsonDecode(rawInfo) as Map<String, dynamic>;
                        } else if (rawInfo is Map) {
                          info = Map<String, dynamic>.from(rawInfo as Map);
                        } else {
                          info = <String, dynamic>{};
                        }

                        final lmpRaw = info['lmp']?.toString();
                        if (lmpRaw != null && lmpRaw.isNotEmpty) {
                           String dateStr = lmpRaw;
                          if (dateStr.contains('T')) {
                            dateStr = dateStr.split('T')[0];
                          }
                          lmpDate = DateTime.tryParse(dateStr);
                        }
                      } catch (e) {
                        print('⚠️ Error deriving LMP date: $e');
                      }

                       if (lmpDate == null) {
                        try {
                          final parts = registrationDate.split('/');
                          if (parts.length == 3) {
                            lmpDate = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                          } else {
                            lmpDate = DateTime.now();
                          }
                        } catch (e) {
                          print('⚠️ Error parsing fallback registration date: $e');
                          lmpDate = DateTime.now();
                        }
                      }

                      final ancRanges = _calculateAncDateRanges(lmpDate!);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _ancDateBox(
                            'First ANC',
                            ancRanges['1st_anc_start']!,
                            ancRanges['1st_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Second ANC',
                            ancRanges['2nd_anc_start']!,
                            ancRanges['2nd_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Third ANC',
                            ancRanges['3rd_anc_start']!,
                            ancRanges['3rd_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Fourth ANC',
                            ancRanges['4th_anc_start']!,
                            ancRanges['4th_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'PMAMA',
                            ancRanges['pmsma_start']!,
                            ancRanges['pmsma_end']!,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _ancDateRow(String label, DateTime startDate, DateTime endDate) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ancDateBox(String label, DateTime startDate, DateTime endDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDate(startDate)}\nTO\n${_formatDate(endDate)}',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 12.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.ancVisitListTitle ?? 'ANC Visit List',
        showBack: true,
        icon1Widget: InkWell(
          onTap: () async {
            await _onRefresh();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                          color: AppColors.onSurface, fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.ancVisitSearchHint ?? 'Search pregnant women',
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
                  borderSide:
                  BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          _buildList(),
        ],
      ),
    );
  }
}