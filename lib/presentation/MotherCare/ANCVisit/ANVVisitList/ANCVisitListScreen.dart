import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';

import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';

import '../../../../data/Database/database_provider.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/Database/tables/followup_form_data_table.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';
import '../ANCVisitForm/ANCVisitForm.dart';
import '../../../../core/widgets/SuccessDialogbox/SuccessDialogbox.dart';

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
    final db = await DatabaseProvider.instance.database;

    final currentUserData = await SecureStorageService.getCurrentUserData();
    final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
      return [];
    }

    final rows = await db.rawQuery(
      '''
    WITH RankedMCA AS (
      SELECT DISTINCT
        mca.*,
        ROW_NUMBER() OVER (
          PARTITION BY mca.beneficiary_ref_key
          ORDER BY mca.created_date_time DESC, mca.id DESC
        ) AS rn
      FROM mother_care_activities mca
      WHERE
        mca.is_deleted = 0
        AND mca.current_user_key = ?
    )
    SELECT DISTINCT r.*
    FROM RankedMCA r
    INNER JOIN beneficiaries_new bn
      ON r.beneficiary_ref_key = bn.unique_key
    WHERE
      r.rn = 1
      AND r.mother_care_state = 'anc_due'
      AND bn.is_deleted = 0
      AND bn.is_migrated = 0
      AND bn.is_death = 0
    ORDER BY r.created_date_time DESC; 
    ''',
      [ashaUniqueKey],
    );

    return rows;
  }

  Future<void> _loadPregnantWomen() async {
    setState(() => _isLoading = true);

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];
      final Set<String> processedBeneficiaries = {};

      print('ℹ️ Found ${rows.length} beneficiaries');

      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .toSet();

    //  final deliveredBeneficiaryIds = await _getDeliveredBeneficiaryIds();
     // print('ℹ️ Delivered: ${deliveredBeneficiaryIds.length}');

      for (final row in rows) {
        try {
          final rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          final Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo)
              : Map<String, dynamic>.from(rawInfo);

          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          // if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
          //   continue;
          // }

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

          if ((isPregnant || isAncDue) &&
              (gender == 'f' || gender == 'female')) {
            final personData =
            await _processPerson(row, info, isPregnant: true);

            if (personData != null) {
              personData['isAncDue'] = isAncDue;
              pregnantWomen.add(personData);
              processedBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (_) {}
      }

      for (final ancDue in ancDueRecords) {
        final beneficiaryId =
            ancDue['beneficiary_ref_key']?.toString() ?? '';

        if (beneficiaryId.isEmpty ||
            processedBeneficiaries.contains(beneficiaryId)) {
          continue;
        }

        // // ❌ EXCLUDE DELIVERED (IMPORTANT)
        // if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
        //   continue;
        // }

        pregnantWomen.add({
          'BeneficiaryID': beneficiaryId,
          'unique_key': beneficiaryId,
          'Name': 'ANC Due - ${_getLast11Chars(beneficiaryId)}',
          'isAncDue': true,
          'RegistrationDate': ancDue['created_date_time'],
          'lmpDate': await _extractLmpDate(ancDue), // Extract LMP date for ANC due records
          '_rawRow': ancDue,
          'is_synced': ancDue['is_synced'],
        });
      }

      // ---------------- DEDUP + SORT ----------------
      final Map<String, Map<String, dynamic>> byId = {};
      for (final item in pregnantWomen) {
        final id = item['BeneficiaryID'] ?? item['unique_key'];
        if (id != null) byId[id] = item;
      }

      final list = byId.values.toList()
        ..sort((a, b) {
          final d1 = DateTime.tryParse(
              a['_rawRow']?['created_date_time'] ?? '');
          final d2 = DateTime.tryParse(
              b['_rawRow']?['created_date_time'] ?? '');
          return (d2 ?? DateTime(0))
              .compareTo(d1 ?? DateTime(0));
        });

      setState(() {
        _allData = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getSyncStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'mother_care_activities',
        columns: ['is_synced',  'created_date_time'],
        where: 'beneficiary_ref_key = ? AND is_deleted = 0 ',
        whereArgs: [beneficiaryRefKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return {
          'is_synced': rows.first['is_synced'] == 1,
          // 'server_id': rows.first['server_id']
        };
      }

      return {'is_synced': false};
    } catch (e) {
      print('Error fetching sync status: $e');
      return {'is_synced': false,};
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

    // Calculate PMSMA dates based on ANC ranges:
    // PMSMA start = First ANC "to date" + 1 day
    // PMSMA end = Second ANC "from date" - 1 day
    ranges['pmsma_start'] = ranges['1st_anc_end']!.add(const Duration(days: 1));
    ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(const Duration(days: 1));

    return ranges;
  }

  // Format date to dd/MM/yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Future<Map<String, dynamic>?> _processPerson(
      Map<String, dynamic> row,
      Map<String, dynamic> person, {
        required bool isPregnant,
      }) async {
    try {
      final name = person['memberName'] ?? person['headName'] ?? 'Unknown';
      final gender = person['gender']?.toString().toLowerCase() ?? '';
      final dob = person['dob'];
      final age = _calculateAge(dob);
      final spouseName = person['spouseName'] ?? person['headName'] ?? '';

      final householdRefKey = row['household_ref_key']?.toString() ?? '';
      final uniqueKey = row['unique_key']?.toString() ?? '';

      // Get TRIMMED versions for display only
      final householdRefKeyDisplay = _getLast11Chars(householdRefKey);
      final uniqueKeyDisplay = _getLast11Chars(uniqueKey);

      final registrationDate = row['created_date_time']?.toString() ?? '';

      if (!isPregnant) return null;

      // Extract LMP date
      final lmpDate = await _extractLmpDate(row);

      // Format registration date if available
      String formattedDate = 'N/A';
      if (registrationDate.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(registrationDate);
          // Format day and month to always show two digits
          final day = dateTime.day.toString().padLeft(2, '0');
          final month = dateTime.month.toString().padLeft(2, '0');
          formattedDate = '$day-$month-${dateTime.year}';
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
        'Name': name,
        'Age': age?.toString() ?? 'Not Available',
        'Gender': 'Female',
        'RCH ID': person['RCH_ID'] ?? person['RichID'] ?? 'Not Available',
        'Mobile No': person['mobileNo'] ?? '',
        'Husband': spouseName,
        'RegistrationDate': formattedDate,
        'lmpDate': lmpDate, // Add LMP date to the data
        'beneficiary_info': jsonEncode(person),
        '_rawRow': row,
      };
    } catch (e) {
      print('⚠️ Error processing person: $e');
      return null;
    }
  }




  Future<DateTime?> _extractLmpDate(Map<String, dynamic> data) async {
    try {
      // First try to get LMP from beneficiary_info (beneficiaries_new table)
      dynamic rawInfo = data['beneficiary_info'];
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
        final lmpDate = DateTime.tryParse(dateStr);
        if (lmpDate != null) {
          print('✅ Found LMP date from beneficiaries_new: ${_formatDate(lmpDate)}');
          return lmpDate;
        }
      }

      // Fallback: try to get from _rawRow if available
      final rawRow = data['_rawRow'] as Map<String, dynamic>?;
      if (rawRow != null) {
        rawInfo = rawRow['beneficiary_info'];
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
          final lmpDate = DateTime.tryParse(dateStr);
          if (lmpDate != null) {
            print('✅ Found LMP date from _rawRow: ${_formatDate(lmpDate)}');
            return lmpDate;
          }
        }
      }

      // If not found in beneficiaries_new, check followup forms
      print('⚠️ No LMP found in beneficiaries_new, checking followup forms...');
      final lmpFromFollowup = await _getLmpFromFollowupForm(data);
      if (lmpFromFollowup != null) {
        print('✅ Found LMP date from followup form: ${_formatDate(lmpFromFollowup)}');
        return lmpFromFollowup;
      }

      print('⚠️ No LMP date found in beneficiaries_new or followup forms');
      return null;
    } catch (e) {
      print('⚠️ Error extracting LMP date: $e');
      return null;
    }
  }

  Future<DateTime?> _getLmpFromFollowupForm(Map<String, dynamic> data) async {
    try {
      final benId = data['BeneficiaryID']?.toString() ?? 
                   data['unique_key']?.toString() ?? 
                   (data['_rawRow'] is Map ? (data['_rawRow'] as Map)['unique_key']?.toString() : null);

      final hhId = data['hhId']?.toString() ?? 
                  (data['_rawRow'] is Map ? (data['_rawRow'] as Map)['household_ref_key']?.toString() : null);

      if (benId == null || benId.isEmpty || hhId == null || hhId.isEmpty) {
        print('⚠️ Missing beneficiary ID or household ID for followup form LMP lookup');
        return null;
      }

      final dao = LocalStorageDao();
      final forms = await dao.getFollowupFormsByHouseholdAndBeneficiary(
        formType: FollowupFormDataTable.eligibleCoupleTrackingDue,
        householdId: hhId,
        beneficiaryId: benId,
      );

      if (forms.isEmpty) {
        print('ℹ️ No eligible couple tracking due forms found for beneficiary');
        return null;
      }

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) {
          continue;
        }

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
          
          // Check for LMP date in eligible_couple_tracking_due_from structure
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final lmpStr = trackingData['lmp_date']?.toString();
            
            if (lmpStr != null && lmpStr.isNotEmpty) {
              try {
                final lmpDate = DateTime.parse(lmpStr);
                print('✅ Found LMP date from followup form: $lmpDate');
                return lmpDate;
              } catch (e) {
                print('⚠️ Error parsing LMP date from followup form: $e');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error parsing followup form JSON: $e');
        }
      }

      print('ℹ️ No LMP date found in any eligible couple tracking due forms');
      return null;
    } catch (e) {
      print('❌ Error loading LMP from followup form: $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPregnantWomen();
      print('📊 Pregnant women count (initState): ${_allData.length}');
    });
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
    final l10n = AppLocalizations.of(context);
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
               l10n!.noPregnantWomenFound,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.registerNewANCCases,
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
        : l10n?.notAvailable ?? l10n!.na;

    final ageGender = '${data['Age']} Y';

    // Use COMPLETE IDs for functionality
    final uniqueKey = data['unique_key']?.toString() ?? '';
    final beneficiaryId = data['BeneficiaryID']?.toString() ?? '';
    final hhId = data['hhId']?.toString() ?? '';

    final uniqueKeyDisplay = data['unique_key_display']?.toString() ?? data['BeneficiaryID_display']?.toString() ?? '';
    final hhIdDisplay = data['hhId_display']?.toString() ?? '';

    final husbandName = data['Husband'] is String && data['Husband'].isNotEmpty
        ? data['Husband']
        : l10n?.notAvailable ?? l10n!.na;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
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
              if (latest['anc_form'] is Map) {
                fd = Map<String, dynamic>.from(latest['anc_form'] as Map);
              } else if (latest['form_json'] is String && (latest['form_json'] as String).isNotEmpty) {
                try {
                  final decoded = jsonDecode(latest['form_json'] as String);
                  if (decoded is Map && decoded['anc_form'] is Map) {
                    fd = Map<String, dynamic>.from(decoded['anc_form'] as Map);
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

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Ancvisitform(beneficiaryData: formData),
          ),
        );
        if (!mounted) return;
        if (result == true ||
            (result is Map<String, dynamic> && (result['saved'] == true))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onRefresh();
            CustomDialog.show(
              context,
              title: 'Form has been saved successfully',
              message: 'Registration has been completed',
            );
          });
        } else {
          _onRefresh();
        }
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
                        hhIdDisplay.isNotEmpty ? hhIdDisplay : l10n!.na,
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                               // border: Border.all(color: Colors.red[700]!),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                l10n!.hrp,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: 2,),
                          Text(
                            '${isAncDue ? ' ' : ''}${l10n?.visitsLabel ?? 'Visits :'} $count',
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 15,
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          uniqueKeyDisplay.isNotEmpty ? uniqueKeyDisplay : l10n!.na,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(
                          l10n?.nameLabel ?? 'Name',
                          data['Name'] ?? l10n!.na,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 50,
                        child: _rowText(
                          l10n?.age ?? 'Age/Gender',
                          "${ageGender}",
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 40,
                        child: _rowText(
                          l10n?.husband ?? 'Husband',
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
                          data['RCH ID'] ?? l10n?.na,
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

                      // Get high risk reasons if available
                      final highRiskReasons = snapshot.data?['highRiskReasons'] is List
                          ? List<String>.from(snapshot.data?['highRiskReasons'] ?? [])
                          : <String>[];

                      // First try to get LMP date from the processed data
                      final lmpDateFromData = data['lmpDate'] as DateTime?;
                      
                      // If we have LMP date from data, use it directly
                      if (lmpDateFromData != null) {
                        final ancRanges = _calculateAncDateRanges(lmpDateFromData);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ancDateBox(l10n!.firstAnc, ancRanges['1st_anc_start']!, ancRanges['1st_anc_end']!),
                            const SizedBox(width: 4),
                            _ancDateBox(l10n!.secondAnc, ancRanges['2nd_anc_start']!, ancRanges['2nd_anc_end']!),
                            const SizedBox(width: 4),
                            _ancDateBox(l10n!.thirdAnc, ancRanges['3rd_anc_start']!, ancRanges['3rd_anc_end']!),
                            const SizedBox(width: 4),
                            _ancDateBox(l10n!.fourthAnc, ancRanges['4th_anc_start']!, ancRanges['4th_anc_end']!),
                            const SizedBox(width: 4),
                            _ancDateBox(l10n!.pmsma, ancRanges['pmsma_start']!, ancRanges['pmsma_end']!),
                          ],
                        );
                      }

                      // If no LMP date from data, use FutureBuilder to extract it
                      return FutureBuilder<DateTime?>(
                        future: _extractLmpDate(data),
                        builder: (context, lmpSnapshot) {
                          final lmpDate = lmpSnapshot.data;

                          if (lmpDate == null) {
                            print('⚠️ No LMP date found for beneficiary ${data['BeneficiaryID']}');
                            // Show "Not Available" for all ANC dates when LMP is not found
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ancDateBox(l10n!.firstAnc, null, null),
                                const SizedBox(width: 4),
                                _ancDateBox(l10n!.secondAnc, null, null),
                                const SizedBox(width: 4),
                                _ancDateBox(l10n!.thirdAnc, null, null),
                                const SizedBox(width: 4),
                                _ancDateBox(l10n!.fourthAnc, null, null),
                                const SizedBox(width: 4),
                                _ancDateBox(l10n!.pmsma, null, null),
                              ],
                            );
                          } else {
                            print('✅ Using LMP date: ${_formatDate(lmpDate)} for beneficiary ${data['BeneficiaryID']}');
                          }

                          final ancRanges = _calculateAncDateRanges(lmpDate);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ancDateBox(l10n!.firstAnc, ancRanges['1st_anc_start']!, ancRanges['1st_anc_end']!),
                              const SizedBox(width: 4),
                              _ancDateBox(l10n!.secondAnc, ancRanges['2nd_anc_start']!, ancRanges['2nd_anc_end']!),
                              const SizedBox(width: 4),
                              _ancDateBox(l10n!.thirdAnc, ancRanges['3rd_anc_start']!, ancRanges['3rd_anc_end']!),
                              const SizedBox(width: 4),
                              _ancDateBox(l10n!.fourthAnc, ancRanges['4th_anc_start']!, ancRanges['4th_anc_end']!),
                              const SizedBox(width: 4),
                              _ancDateBox(l10n!.pmsma, ancRanges['pmsma_start']!, ancRanges['pmsma_end']!),
                            ],
                          );
                        },
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



  Widget _ancDateBox(String label, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.background,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Not Available',
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

    DateTime displayEndDate = endDate;
    DateTime displayStartDate = startDate;
    
    if (label.toLowerCase().contains('4th') || label.toLowerCase().contains('fourth')) {
      displayEndDate = startDate.add(const Duration(days: 15));
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDate(displayStartDate)}\nTO\n${_formatDate(displayEndDate)}',
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
            fontSize: 14.sp,
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
                      l10n!.refresh,
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

////////////////////////////////////////////////////////
