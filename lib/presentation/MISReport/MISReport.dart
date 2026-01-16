import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/Database/User_Info.dart';
import 'dart:convert';

import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/tables/child_care_activities_table.dart';
import '../../data/Database/tables/followup_form_data_table.dart';
import '../../data/Database/tables/mother_care_activities_table.dart';
import '../../data/Database/tables/beneficiaries_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
class Misreport extends StatefulWidget {
  const Misreport({super.key});

  @override
  State<Misreport> createState() => _MisreportState();
}

class _MisreportState extends State<Misreport> {
  int? appRoleId;
  int ashaCount = 0;

  Future<void> loadUserData() async {
    try {
      final Map<String, dynamic>? userData =
      await UserInfo.getCurrentUser();

      if (userData != null) {
        final details = userData['details'];

        setState(() {
          appRoleId = int.tryParse(details!['app_role_id'].toString());
          ashaCount = (details?['asha_list'] as List?)?.length ?? 0;
        });

        debugPrint('App Role ID: $appRoleId');
        debugPrint('ASHA Count: $ashaCount');
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    }
  }


  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  late String _selectedMonth;

  int pregnantWomenCount = 0;
  int newborns = 0;
  int abhaGenerated = 0;
  int abhaFetched = 0;

  @override
  void initState() {
    super.initState();
   loadUserData();
    loaddata();
    /*getCurrentMonthChildCareDueCounts();
    getCurrentMonthAncDueMotherCareCount();*/

    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
  }

  Future<void> loaddata() async {
    await _loadPregnantWomen();
    await _loadChildBeneficiaries();
  }

  Future<void> _loadChildBeneficiaries() async {

    List<Map<String, dynamic>> _childBeneficiaries = [];
    if (!mounted) return;

    try {

      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String whereClause = 'is_deleted = ? AND is_adult = ? AND is_death = ?';
      List<dynamic> whereArgs = [0, 0, 0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final List<Map<String, dynamic>> rows = await db.rawQuery('''
  SELECT 
    B.*
  FROM beneficiaries_new B
  WHERE 
    B.is_deleted = 0
    AND B.is_adult = 0
    AND B.is_migrated = 0
    AND B.is_death = 0
    AND B.current_user_key = ?
  ORDER BY B.created_date_time DESC
''', [ashaUniqueKey]);


      int childCount = 0;
    //  int childCountIsSync = 0;

      for (final row in rows) {
        try {
          final createdStr = row['created_date_time']?.toString();
          if (createdStr == null || createdStr.isEmpty) continue;

          final createdDate =
          DateTime.tryParse(createdStr.replaceFirst(' ', 'T'));

          if (createdDate == null) continue;

          final DateTime today = DateTime.now();

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = (info['memberType']?.toString() ?? '').toLowerCase();
          final relation = (info['relation']?.toString() ?? '').toLowerCase();
          final name = info['name']?.toString() ??
              info['memberName']?.toString() ??
              info['member_name']?.toString() ?? '';

          // Only count if it's a child and has a name
          if ((memberType == 'child' ||
              relation == 'child' ||
              relation == 'son' ||
              relation == 'daughter') &&
              name.isNotEmpty) {
            childCount++;
          }
        } catch (e) {
          continue;
        }
      }

      setState(() {
        newborns = childCount;
      });

    //  developer.log('Found $childCount registered child beneficiaries', name: 'ChildCareCountProvider');
   //   return childCount;


      /*
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      print('🔍 Fetching deceased beneficiaries...');
      final deceasedChildren = await db.rawQuery('''
        SELECT DISTINCT beneficiary_ref_key, form_json
        FROM followup_form_data
        WHERE form_json LIKE '%"reason_of_death":%'
        AND current_user_key = ?
      ''', [ashaUniqueKey]);

      print('✅ Found ${deceasedChildren.length} potential deceased records');

      final deceasedIds = <String>{};
      for (var child in deceasedChildren) {
        try {
          final jsonData = jsonDecode(child['form_json'] as String);
          final formData = jsonData['form_data'] as Map<String, dynamic>?;
          final caseClosure = formData?['case_closure'] as Map<String, dynamic>?;

          if (caseClosure?['is_case_closure'] == true &&
              caseClosure?['reason_of_death']?.toString().toLowerCase() == 'death') {
            final beneficiaryId = child['beneficiary_ref_key']?.toString();
            if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
              print('Found deceased beneficiary: $beneficiaryId');
              deceasedIds.add(beneficiaryId);
            }
          }
        } catch (e) {
          print('⚠️ Error processing deceased record: $e');
        }
      }

      print('✅ Total deceased beneficiaries: ${deceasedIds.length}');

      final registrationDates = <String, String>{};
      final childCareRecords = await db.rawQuery('''
        SELECT
          beneficiary_ref_key,
          created_date_time,
          child_care_state
        FROM child_care_activities
        ORDER BY created_date_time ASC
      ''');

      print('🔍 Child care records query: Getting first entry for each beneficiary');
      print('📊 Found ${childCareRecords.length} total child care records');

      final Map<String, Map<String, dynamic>> firstRecordsByBeneficiary = {};
      for (var record in childCareRecords) {
        final beneficiaryKey = record['beneficiary_ref_key']?.toString();
        if (beneficiaryKey != null && !firstRecordsByBeneficiary.containsKey(beneficiaryKey)) {
          firstRecordsByBeneficiary[beneficiaryKey] = record;
        }
      }

      // Extract dates from first records
      for (var entry in firstRecordsByBeneficiary.entries) {
        final beneficiaryKey = entry.key;
        final record = entry.value;
        final createdDate = record['created_date_time']?.toString();
        final careState = record['child_care_state']?.toString();
        print('📋 First child care record for beneficiary=$beneficiaryKey, state=$careState, date=$createdDate');
        if (createdDate != null) {
          registrationDates[beneficiaryKey] = createdDate;
        }
      }

      print('📊 Found ${registrationDates.length} registration dates from child_care_activities');

      final List<Map<String, dynamic>> rows = await db.rawQuery('''
  SELECT
    B.*
  FROM beneficiaries_new B
  WHERE
    B.is_deleted = 0
    AND B.is_adult = 0
    AND B.is_migrated = 0
    AND B.current_user_key = ?
  ORDER BY B.created_date_time DESC
''', [ashaUniqueKey]);


      print('📊 Found ${rows.length} total beneficiaries');
      final childBeneficiaries = <Map<String, dynamic>>[];

      for (final row in rows) {
        try {
          final rowHhId = row['household_ref_key']?.toString();
          if (rowHhId == null) continue;

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          final relation = info['relation']?.toString().toLowerCase() ?? '';

          if (memberType == 'child' || relation == 'child' ||
              memberType == 'Child' || relation == 'daughter') {

            final name = info['name']?.toString() ??
                info['memberName']?.toString() ??
                info['member_name']?.toString() ??
                '';

            // if (name.isEmpty) continue; // Skip if no name

            final fatherName = info['fatherName']?.toString() ??
                info['father_name']?.toString() ?? '';

            final motherName = info['motherName']?.toString() ??
                info['mother_name']?.toString() ?? '';

            final spouseName = info['spouseName']?.toString() ??
                info['spouse_name']?.toString() ?? '';

            final mobileNo = info['mobileNo']?.toString() ??
                info['mobile']?.toString() ??
                info['mobile_number']?.toString() ?? '';

            final richId = info['RichIDChanged']?.toString() ??
                info['richIdChanged']?.toString() ??
                info['richId']?.toString() ?? '';

            final dob = info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
            final gender = info['gender'] ?? info['sex'];

            final beneficiaryId = row['unique_key']?.toString() ?? '';
            final isDeceased = deceasedIds.contains(beneficiaryId);

            if (isDeceased) {
              print('ℹ️ Marking as deceased - ID: $beneficiaryId, Name: $name');
            }

            String registrationDate;
            print('🔍 Checking beneficiary ID: $beneficiaryId against ${registrationDates.length} registration dates');
            print('📋 Available registration keys: ${registrationDates.keys.toList()}');

            if (registrationDates.containsKey(beneficiaryId)) {
              registrationDate = _formatDateString(registrationDates[beneficiaryId]);
              print('📅 ✅ Using registration date from child_care_activities for $beneficiaryId: $registrationDate');
            } else {
              registrationDate = _formatDateString(row['created_date_time']?.toString());
              print('📅 ❌ Using registration date from beneficiaries_new for $beneficiaryId: $registrationDate');
            }

            final card = <String, dynamic>{
              'hhId': rowHhId,
              'RegitrationDate': registrationDate,
              'RegitrationType': 'Child',
              'BeneficiaryID': beneficiaryId,
              'RchID': richId,
              'Name': name,
              'Age|Gender': _formatAgeGender(dob, gender),
              'Mobileno.': mobileNo,
              'FatherName': fatherName,
              'MotherName': motherName,
              'SpouseName': spouseName,
              'is_deceased': isDeceased,
              'is_death': row['is_death'] ?? 0,
              '_raw': row,
            };

            childBeneficiaries.add(card);
          }
        } catch (e) {
          print('⚠️ Error processing beneficiary record: $e');
        }
      }

      if (mounted) {
        setState(() {
          _childBeneficiaries = List<Map<String, dynamic>>.from(childBeneficiaries);
          newborns = _childBeneficiaries.length;
          //_filtered = List<Map<String, dynamic>>.from(childBeneficiaries);
         // _isLoading = false;


        *//*  debugPrint('✅ Loaded ${_childBeneficiaries.length} child beneficiaries');
          debugPrint('✅ Filtered list contains ${_filtered.length} records');

          final count = _childBeneficiaries.length > 5 ? 5 : _childBeneficiaries.length;
          for (int i = 0; i < count; i++) {
            debugPrint('Record $i: ${_childBeneficiaries[i]['Name']} (ID: ${_childBeneficiaries[i]['BeneficiaryID']})');
          }*//*
        });
      }*/
    } catch (e) {
      debugPrint('Error loading child beneficiaries: $e');
      if (mounted) {
      //  setState(() => _isLoading = false);
      }
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'Not Available';
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
          int months = now.month - dob.month;
          int days = now.day - dob.day;

          if (days < 0) {
            final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
            final lastMonthYear = now.month - 1 < 1 ? now.year - 1 : now.year;
            final daysInLastMonth = DateTime(lastMonthYear, lastMonth + 1, 0).day;
            days += daysInLastMonth;
            months--;
          }

          if (months < 0) {
            months += 12;
            years--;
          }

          if (years > 0) {
            age = '$years Y';
          } else if (months > 0) {
            age = '$months M';
          } else {
            age = '$days D';
          }
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

    return '$age | $displayGender';
  }




  Future<void> _loadPregnantWomen() async {

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
        pregnantWomenCount = _getPregnantWomenCountLastMonth(list);
        /*_allData = list;
        _filtered = list;
        _isLoading = false;*/
      });
    } catch (e) {
      print('❌ Error: $e');
     // setState(() => _isLoading = false);
    }
  }

  int _getPregnantWomenCountLastMonth(List<Map<String, dynamic>> list) {
    return list.length;
  }

  DateTime? _parseDDMMYYYY(String? date) {
    if (date == null || date.isEmpty) return null;

    try {
      final parts = date.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
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

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Format date to dd/MM/yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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


  String _getLast11Chars(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }



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


/*

  Future<int> getCurrentMonthAncDueMotherCareCount() async {
    try {
      print('🔍 [getCurrentMonthAncDueMotherCareCount] Querying ANC due count (latest state check)...');

      // 1. Get the current user key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final db = await DatabaseProvider.instance.database;

      String whereClause = '''
      latest_state.mother_care_state = ?
      AND latest_state.is_deleted = 0
      AND latest_state.beneficiary_ref_key IS NOT NULL
      AND latest_state.mother_care_state != 'delivery_outcome'
      AND benef.is_migrated != 1
      AND benef.is_death != 1
      AND (
        strftime('%Y-%m', latest_state.created_date_time) = strftime('%Y-%m', 'now')
        OR
        strftime('%Y-%m', latest_state.modified_date_time) = strftime('%Y-%m', 'now')
      )
    ''';

      List<dynamic> args = ['anc_due'];

      // 3. Apply the ASHA Unique Key filter if it exists
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND latest_state.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT latest_state.beneficiary_ref_key) AS total_count
      FROM ${MotherCareActivitiesTable.table} latest_state
      INNER JOIN (
        SELECT beneficiary_ref_key, MAX(created_date_time) as max_created_date
        FROM ${MotherCareActivitiesTable.table}
        WHERE is_deleted = 0
        GROUP BY beneficiary_ref_key
      ) latest_records ON latest_state.beneficiary_ref_key = latest_records.beneficiary_ref_key 
                      AND latest_state.created_date_time = latest_records.max_created_date
      INNER JOIN ${BeneficiariesTable.table} benef ON latest_state.beneficiary_ref_key = benef.unique_key
      WHERE $whereClause
    ''', args);

      final int count = Sqflite.firstIntValue(result) ?? 0;

      print('✅ [getCurrentMonthAncDueMotherCareCount] Latest ANC Due Count: $count');
      return count;
    } catch (e, stackTrace) {
      print('❌ [getCurrentMonthAncDueMotherCareCount] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, int>> getCurrentMonthChildCareDueCounts() async {
    try {
      print('🔍 [getCurrentMonthChildCareDueCounts] Querying child care due counts (memberType child)...');

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final db = await DatabaseProvider.instance.database;

      String whereClause = '''
      benef.is_deleted = 0
      AND benef.is_migrated != 1
      AND benef.is_death != 1
      AND benef.unique_key IS NOT NULL
      AND benef.beneficiary_info LIKE '%"memberType":"Child"%'
      AND (
        strftime('%Y-%m', benef.created_date_time) = strftime('%Y-%m', 'now')
        OR
        strftime('%Y-%m', benef.modified_date_time) = strftime('%Y-%m', 'now')
      )
    ''';

      List<dynamic> args = [];

      // Apply the ASHA Unique Key filter if it exists
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND benef.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      final result = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT benef.unique_key) AS newborn_count
      FROM ${BeneficiariesTable.table} benef
      WHERE $whereClause
    ''', args);

      final row = result.isNotEmpty ? result.first : <String, Object?>{};

      final int newbornCount = (row['newborn_count'] as int?) ?? 0;

      print(
        '✅ [getCurrentMonthChildCareDueCounts] '
            'Newborn Count: $newbornCount',
      );

      return {
        'newborn_count': newbornCount,
        'total_due': newbornCount,
      };
    } catch (e, stackTrace) {
      print('❌ [getCurrentMonthChildCareDueCounts] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n?.monthJanuary ?? 'January',
      l10n?.monthFebruary ?? 'February',
      l10n?.monthMarch ?? 'March',
      l10n?.monthApril ?? 'April',
      l10n?.monthMay ?? 'May',
      l10n?.monthJune ?? 'June',
      l10n?.monthJuly ?? 'July',
      l10n?.monthAugust ?? 'August',
      l10n?.monthSeptember ?? 'September',
      l10n?.monthOctober ?? 'October',
      l10n?.monthNovember ?? 'November',
      l10n?.monthDecember ?? 'December',
    ];
    final displayMonth = monthNames[DateTime.now().month - 1];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppHeader(screenTitle: l10n?.drawerMisReport ?? 'MIS Report', showBack: true,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appRoleId == 4)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Text(
                            'No. of ASHA under facilitator :',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            ashaCount.toString(), // ✅ SHOW COUNT HERE
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          l10n?.misMonthLabel ?? 'Month : ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 10,),
                        Text(
                          displayMonth,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      _statRow(
                        l10n?.misStatPregnantWomen ?? 'Number of total Pregnant Women :',
                        pregnantWomenCount.toString(),
                      ),
                     /* FutureBuilder<int>(
                        future: getCurrentMonthAncDueMotherCareCount(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;

                          return _statRow(
                            l10n?.misStatPregnantWomen ?? 'Number of total Pregnant Women :',
                            pregnantWomenCount.toString(),
                          );
                        },
                      ),*/
                      const SizedBox(height: 10),
                      _statRow(
                        l10n?.misStatNewborns ?? 'Total number of newborns :',
                        newborns.toString(), // ✅ SHOW TOTAL HERE
                      ),
                     /* FutureBuilder<Map<String, int>>(
                        future: getCurrentMonthChildCareDueCounts(),
                        builder: (context, snapshot) {
                          final total = snapshot.data?['total_due'] ?? 0;

                          return _statRow(
                            l10n?.misStatNewborns ?? 'Total number of newborns :',
                            newborns.toString(), // ✅ SHOW TOTAL HERE
                          );
                        },
                      ),*/
                      const SizedBox(height: 10),
                      _statRow(l10n?.misStatAbhaGenerated ?? 'Total number of ABHA generated by user :', abhaGenerated.toString()),
                      const SizedBox(height: 10),
                      _statRow(l10n?.misStatAbhaFetched ?? 'Total number of Exisiting ABHA fetched by user :', abhaFetched.toString()),
                    ],
                  ),
                ),
              ],
            )



          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

