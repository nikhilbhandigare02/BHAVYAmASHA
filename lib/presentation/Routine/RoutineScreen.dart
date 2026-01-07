import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

class Routinescreen extends StatefulWidget {
  const Routinescreen({super.key});

  @override
  State<Routinescreen> createState() => _RoutinescreenState();
}

class _RoutinescreenState extends State<Routinescreen> {
  final Map<String, bool> _expanded = {};
  bool _isLoading = true;

  List<Map<String, dynamic>> _pwList = [];
  final List<Map<String, dynamic>> _child0to1 = [];
  final List<Map<String, dynamic>> _child1to2 = [];
  final List<Map<String, dynamic>> _child2to5 = [];
  final List<Map<String, dynamic>> _poornTikakaran = [];
  final List<Map<String, dynamic>> _sampoornTikakaran = [];

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _loadSampoornTikakaran();
    _loadPoornTikakaran();
    _loadChild0to1();
    _loadChild1to2();
    _loadChild2to5();
  }
  Future<List<Map<String, dynamic>>> _filterByCurrentUserKey(List<Map<String, dynamic>> rows) async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();
      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return rows;
      return rows.where((row) => (row['current_user_key'] ?? '').toString() == ashaUniqueKey).toList();
    } catch (_) {
      return rows;
    }
  }
Future<void> _loadPregnantWomen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];

      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print('Error parsing beneficiary_info: $e');
            continue;
          }

          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final gender = info['gender']?.toString().toLowerCase() ?? '';
          if (gender != 'f' && gender != 'female') continue;

          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final age = _calculateAge(info['dob']);
          final mobile = info['mobileNo'] ?? '';
          final lmp = info['lmp']?.toString();


          Map<String, DateTime> ancDates = {};
          String nextVisit = 'N/A';
          if (lmp != null && lmp.isNotEmpty) {
            try {
              final lmpDate = DateTime.tryParse(lmp.split('T')[0]);
              if (lmpDate != null) {
                ancDates = _calculateAncDateRanges(lmpDate);
                nextVisit = _getNextVisitDate(ancDates);  // Now nextVisit is properly initialized
              }
            } catch (e) {
              print('Error calculating ANC dates: $e');
            }
          }

          pregnantWomen.add({
            'name': name,
            'age': age,
            'gender': 'Female',
            'mobile': mobile,
            'id': row['unique_key']?.toString() ?? '',
            'ancDates': ancDates ,
            'nextVisit': nextVisit,
            'badge': 'ANC',
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      // Group by name and mobile to find unique women
      final Map<String, Map<String, dynamic>> uniqueWomen = {};
      
      for (final woman in pregnantWomen) {
        final key = '${woman['name']}_${woman['mobile']}';
        final existing = uniqueWomen[key];
        
        // If no record exists for this woman, or if current record is newer, keep it
        if (existing == null || 
            (woman['nextVisit'] != 'N/A' && 
             existing['nextVisit'] == 'N/A') ||
            (woman['nextVisit'] != 'N/A' && 
             existing['nextVisit'] != 'N/A' &&
             woman['nextVisit'].compareTo(existing['nextVisit']) > 0)) {
          uniqueWomen[key] = woman;
        }
      }

      setState(() {
        _pwList = uniqueWomen.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pregnant women: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadSampoornTikakaran() async {
    print('Starting to load Sampoorn Tikakaran data...');
    try {
      print('Calling getChildTrackingDueFor16Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor16Year();
      final scopedRows = await _filterByCurrentUserKey(rows);
      print('Received ${rows.length} rows from database');
      print('Scoped to current user: ${scopedRows.length}');

      setState(() {
        _sampoornTikakaran.clear();
        for (var row in scopedRows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map ?
          (formData['form_data'] ?? formData) :
          formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _sampoornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _sampoornTikakaran: ${_sampoornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadSampoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadPoornTikakaran() async {
    print('Starting to load Poorn Tikakaran (9-year) data...');
    try {
      print('Calling getChildTrackingDueFor9Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor9Year();
      final scopedRows = await _filterByCurrentUserKey(rows);
      print('Received ${rows.length} rows from database');
      print('Scoped to current user: ${scopedRows.length}');

      setState(() {
        _poornTikakaran.clear();
        for (var row in scopedRows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map
              ? (formData['form_data'] ?? formData)
              : formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _poornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _poornTikakaran: ${_poornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadPoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadChild0to1() async {
    await _loadChildBeneficiariesByAgeGroup('0-1');
  }

  Future<void> _loadChild1to2() async {
    await _loadChildBeneficiariesByAgeGroup('1-2');
  }

  Future<void> _loadChild2to5() async {
    await _loadChildBeneficiariesByAgeGroup('2-5');
  }

  Future<bool> _hasTrackingDueStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'child_care_activities',
        where: 'beneficiary_ref_key = ? AND child_care_state = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey, 'tracking_due'],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e) {
      print('Error checking tracking_due status for $beneficiaryRefKey: $e');
      return false;
    }
  }

  Future<void> _loadChildBeneficiariesByAgeGroup(String ageGroup) async {
    print('Loading children $ageGroup years data...');
    try {
      final db = await DatabaseProvider.instance.database;

      final deceasedChildren = await db.rawQuery('''
        SELECT DISTINCT beneficiary_ref_key, form_json 
        FROM followup_form_data 
        WHERE form_json LIKE '%"reason_of_death":%'
      ''');

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
              deceasedIds.add(beneficiaryId);
            }
          }
        } catch (e) {
          print('⚠️ Error processing deceased record: $e');
        }
      }

      // Get current user data
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Get last visit dates from child_care_activities (most recent entry)
      final lastVisitDates = <String, String>{};
      final childCareRecords = await db.rawQuery('''
        SELECT 
          beneficiary_ref_key, 
          created_date_time,
          child_care_state
        FROM child_care_activities 
        ORDER BY created_date_time DESC
      ''');

      final Map<String, Map<String, dynamic>> latestRecordsByBeneficiary = {};
      for (var record in childCareRecords) {
        final beneficiaryKey = record['beneficiary_ref_key']?.toString();
        if (beneficiaryKey != null && !latestRecordsByBeneficiary.containsKey(beneficiaryKey)) {
          latestRecordsByBeneficiary[beneficiaryKey] = record;
        }
      }
      
      // Extract latest dates from records
      for (var entry in latestRecordsByBeneficiary.entries) {
        final beneficiaryKey = entry.key;
        final record = entry.value;
        final createdDate = record['created_date_time']?.toString();
        if (createdDate != null) {
          lastVisitDates[beneficiaryKey] = createdDate;
        }
      }

      // Get all child beneficiaries
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

      final allChildBeneficiaries = <Map<String, dynamic>>[];

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

            final fatherName = info['fatherName']?.toString() ??
                info['father_name']?.toString() ?? '';

            final motherName = info['motherName']?.toString() ??
                info['mother_name']?.toString() ?? '';

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

            // Calculate age in months for filtering
            final ageInMonths = _calculateAgeInMonths(dob);
            
            // Filter by age group
            bool belongsToAgeGroup = false;
            if (ageGroup == '0-1') {
              belongsToAgeGroup = ageInMonths >= 0 && ageInMonths <= 12;
            } else if (ageGroup == '1-2') {
              belongsToAgeGroup = ageInMonths > 12 && ageInMonths < 24;
            } else if (ageGroup == '2-5') {
              belongsToAgeGroup = ageInMonths >= 24 && ageInMonths <= 60;
            }

            if (!belongsToAgeGroup) continue;

            // Get last visit date from child_care_activities
            String lastVisitDate;
            if (lastVisitDates.containsKey(beneficiaryId)) {
              lastVisitDate = _formatDateFromString(lastVisitDates[beneficiaryId]);
            } else {
              lastVisitDate = 'Not Available';
            }

            // Check if child has tracking_due status in child_care_activities
            final hasTrackingDue = await _hasTrackingDueStatus(beneficiaryId);
            if (!hasTrackingDue) continue;

            final card = <String, dynamic>{
              'hhId': rowHhId,

              'RegitrationType': 'Child',
              'BeneficiaryID': beneficiaryId,
              'RchID': richId,
              'Name': name,
              'Age|Gender': _formatAgeGender(dob, gender),
              'Mobileno.': mobileNo,
              'FatherName': fatherName,
              'MotherName': motherName,
              'is_deceased': isDeceased,
              'is_death': row['is_death'] ?? 0,
              'age_in_months': ageInMonths,
              'LastVisitDate': lastVisitDate,
              '_raw': row,
            };

            allChildBeneficiaries.add(card);
          }
        } catch (e) {
          print('⚠️ Error processing beneficiary record: $e');
        }
      }

      // Update the appropriate list based on age group
      setState(() {
        switch (ageGroup) {
          case '0-1':
            _child0to1.clear();
            _child0to1.addAll(allChildBeneficiaries);
            print('Total items in _child0to1: ${_child0to1.length}');
            break;
          case '1-2':
            _child1to2.clear();
            _child1to2.addAll(allChildBeneficiaries);
            print('Total items in _child1to2: ${_child1to2.length}');
            break;
          case '2-5':
            _child2to5.clear();
            _child2to5.addAll(allChildBeneficiaries);
            print('Total items in _child2to5: ${_child2to5.length}');
            break;
        }
      });
    } catch (e) {
      print('Error in _loadChildBeneficiariesByAgeGroup($ageGroup): $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  int _calculateAgeInMonths(dynamic dob) {
    if (dob == null) return 0;
    try {
      DateTime? birthDate;
      if (dob is String) {
        birthDate = DateTime.tryParse(dob);
        if (birthDate == null) {
          final timestamp = int.tryParse(dob);
          if (timestamp != null && timestamp > 0) {
            birthDate = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }
      } else if (dob is DateTime) {
        birthDate = dob;
      }
      if (birthDate == null) return 0;

      final now = DateTime.now();
      int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
      if (now.day < birthDate.day) {
        months--;
      }
      return months;
    } catch (e) {
      return 0;
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

  String _formatDateFromString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }


  void _updateChildList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows, String logName) {
    setState(() {
      targetList.clear();
      _addFormDataToList(targetList, sourceRows);
      print('Total items in $logName: ${targetList.length}');
    });
  }


  void _addFormDataToList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows) {
    for (var row in sourceRows) {
      final formData = row['form_json'];
      final formDataContent = formData is Map ? (formData['form_data'] ?? formData) : formData;

      if (formDataContent != null) {
        targetList.add({
          'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
          'age': formDataContent['age'] ?? 'N/A',
          'gender': formDataContent['gender'] ?? 'N/A',
          'father_name': formDataContent['father_name'] ?? 'N/A',
          'mother_name': formDataContent['mother_name'] ?? 'N/A',
          'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
          'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
          'registration_date': formDataContent['registration_date'] ?? 'N/A',
          'household_id': formDataContent['household_id'] ?? 'N/A',
          'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
          'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
        });
      }
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
      return null;
    }
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

  DateTime _dateAfterWeeks(DateTime startDate, int weeks) {
    return startDate.add(Duration(days: weeks * 7));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _getNextVisitDate(Map<String, DateTime> ancDates) {
    final now = DateTime.now();

     final ancWindows = [
      {'key': '1st_anc_start', 'label': '1st ANC'},
      {'key': '2nd_anc_start', 'label': ''},
      {'key': '3rd_anc_start', 'label': '3rd ANC'},
      {'key': '4th_anc_start', 'label': '4th ANC'},
      {'key': 'pmsma_start', 'label': 'PMSMA'},
    ];

    for (var window in ancWindows) {
      final startDate = ancDates[window['key']];
      if (startDate != null && startDate.isAfter(now)) {
        return '${window['label']} (${_formatDate(startDate)})';
      }
    }

    final lastVisit = ancDates['pmsma_end'];
    if (lastVisit != null) {
      return 'Last visit date: ${_formatDate(lastVisit)}';
    }

    return 'No visit scheduled';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

     final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.routine, showBack: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _sectionTile(l10n.routinePwList, _pwList),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList0to1, _child0to1),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList1to2, _child1to2),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList2to5, _child2to5),
          const SizedBox(height: 12),
          _sectionTile(l10n.routinePoornTikakaran, _poornTikakaran),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineSampoornTikakaran, _sampoornTikakaran),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTile(String title, List<Map<String, dynamic>> items) {
    final l10n = AppLocalizations.of(context)!;

    final isOpen = _expanded[title] ?? false;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded[title] = !isOpen;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style:  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color:AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[
          const Divider(height: 1, color: Color(0xFFD3E7FF)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  l10n.noRecordFound,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: _routineCard(item),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final ancDates = item['ancDates'] as Map<String, dynamic>?;
    
    // Handle both old and new data structures
    final mobile = item['mobile']?.toString() ?? item['Mobileno.']?.toString() ?? '';
    final isChildData = item.containsKey('Name') && item.containsKey('BeneficiaryID');
    final isSampoornTikakaran = item['age']?.toString().contains('16') ?? false;

    String _last11(String value) {
      if (value.length <= 11) return value;
      return value.substring(value.length - 11);
    }

    // Get appropriate ID based on data structure
    String displayId;
    String displayName;
    String displayAgeGender;
    String displayMobile;
    String badge;
    
    if (isChildData) {
      // New RegisterChildListScreen structure
      displayId = _last11(item['BeneficiaryID']?.toString() ?? '-');
      displayName = item['Name']?.toString() ?? '-';
      displayAgeGender = item['Age|Gender']?.toString() ?? '-';
      displayMobile = item['Mobileno.']?.toString() ?? '-';
      badge = 'Child Tracking';
    } else {
      // Old structure or other data
      displayId = _last11((item['beneficiary_ref_key'] ?? item['id'] ?? '-').toString());
      displayName = item['name']?.toString() ?? '-';
      displayAgeGender = '${item['age'] ?? '-'} Y | ${item['gender'] ?? '-'}';
      displayMobile = item['mobile']?.toString() ?? '-';
      badge = item['badge']?.toString() ?? 'Child Tracking';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.home, color: primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayId,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                // Show deceased badge if applicable
                if (item['is_deceased'] == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Text(
                      'Deceased'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F7E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    badge,
                    style:  TextStyle(color: Color(0xFF0E7C3A), fontWeight: FontWeight.w600, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style:  TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16.sp),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayAgeGender,
                            style:  TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                          const SizedBox(height: 2),
                          if (isChildData) ...[
                            // Show last visit date for child data
                            Text(
                              'Last visit: ${item['LastVisitDate'] ?? '-'}',
                              style:  TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),

                          ] else ...[
                            // Show next visit for ANC or other data
                            Text(
                              item['badge'] == 'ANC'
                                ? '${l10n!.antenatal} ${item['nextVisit'] ?? '-'}'
                                : 'Next Visits: ${item['nextVisit'] ?? '-'}',
                              style:  TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${l10n?.mobileLabel} $displayMobile',
                            style:  TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        if (displayMobile.isNotEmpty)
                          InkWell(
                            onTap: () => _makePhoneCall(displayMobile),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.phone, color: primary, size: 24),
                            ),
                          ),
                        if (displayMobile.isNotEmpty) const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: item['badge'] == 'ANC'
                              ? Image.asset('assets/images/hrp.png')
                              : Image.asset('assets/images/capsule2.png'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),


               ],
            ),
          ),
        ],
      ),
    );
  }


}
