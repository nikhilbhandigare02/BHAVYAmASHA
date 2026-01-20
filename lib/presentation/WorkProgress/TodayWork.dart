import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;
import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/tables/eligible_couple_activities_table.dart';
import '../../data/Database/tables/followup_form_data_table.dart';
import 'bloc/todays_work_bloc.dart';

class Todaywork extends StatefulWidget {
  const Todaywork({super.key});

  @override
  State<Todaywork> createState() => _TodayworkState();
}

class _TodayworkState extends State<Todaywork> {
  int? _selectedSlice; // selected slice for tooltip
  int? _selectedSliceFromLegend;
  List<Map<String, dynamic>> _riItems = [];
  List<Map<String, dynamic>> _ancItems = [];
  List<Map<String, dynamic>> _familySurveyItems = [];
  List<Map<String, dynamic>> _eligibleCoupleItems = [];
  List<Map<String, dynamic>> _hbncItems = [];
  List<Map<String, dynamic>> _familySurveyCompletedItems = [];

  List<Map<String, dynamic>> _riCompletedItems = [];
  List<Map<String, dynamic>> _ancCompletedItems = [];
  List<Map<String, dynamic>> _eligibleCompletedCoupleItems = [];
  List<Map<String, dynamic>> _hbncCompletedItems = [];
  int _completedVisitsCount = 0;
  int _pendingCountVisitsCount = 0;
  int _toDoVisitsCount = 0;
  var _isLoading = true;

  @override
  void initState() {
    _loadData();
  }


  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      // Load all the data from the database
      await _loadFamilySurveyItems();
      if (!mounted) return;

      await _loadEligibleCoupleItems();
      if (!mounted) return;

      await _loadFamilySurveyCompletedItems();
      if (!mounted) return;

      await _loadAncItems();
      if (!mounted) return;

      await _loadHbncItems();
      if (!mounted) return;

      await _loadRoutineImmunizationItems();
      if (!mounted) return;

      // Finally, load the completed visits count
      await _loadCompletedVisitsCount();

      // Save the counts to storage
      if (mounted) {
        await _saveTodayWorkCountsToStorage();
        // Trigger a rebuild to ensure UI is updated
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadCompletedVisitsCount() async {
    try {
      final counts = await SecureStorageService.getTodayWorkCounts();
      if (mounted) {
        setState(() {
          _completedVisitsCount = counts['completed'] ?? 0;
          _toDoVisitsCount = counts['toDo'] ?? 0;
        });
      }

      _eligibleCompletedCoupleItems = [];
      _ancCompletedItems = [];
      _hbncCompletedItems = [];
      _riCompletedItems = [];

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      try {
        final db = await DatabaseProvider.instance.database;

        final now = DateTime.now();
        final todayStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Only get today's date for completed visits filter

        print('=== Date Range for Completed Visits Filter ===');
        print('Today String: $todayStr');
        print('Current DateTime: $now');
        print('============================================');

        // Debug: Check all records in followup_form_data for today only
        final debugQuery =
            'SELECT * FROM ${FollowupFormDataTable.table} WHERE DATE(created_date_time) = DATE(?) AND (is_deleted IS NULL OR is_deleted = 0)';
        final debugRows = await db.rawQuery(debugQuery, [todayStr]);
        print('=== DEBUG: All followup_form_data records for today ===');
        print('Total records found: ${debugRows.length}');
        for (final row in debugRows) {
          print(
            'ID: ${row['id']}, forms_ref_key: ${row['forms_ref_key']}, beneficiary_ref_key: ${row['beneficiary_ref_key']}, created_date_time: ${row['created_date_time']}, current_user_key: ${row['current_user_key']}',
          );
        }
        print('================================================');

        // Debug: Check what form keys we're looking for
        print('=== DEBUG: Form Keys We Are Looking For ===');
        final ancFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .ancDueRegistration] ??
                '';
        final ecFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .eligibleCoupleTrackingDue] ??
                '';
        final hbncFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .pncMother] ??
                '';
        print('ANC Form Key: $ancFormKey');
        print('EC Form Key: $ecFormKey');
        print('HBNC Form Key: $hbncFormKey');
        print('RI Form Key: 30bycxe4gv7fqnt6');
        print('Current ASHA Key: $ashaUniqueKey');
        print('=========================================');

        if (ancFormKey.isEmpty) return;

        try {
          // Direct query for ANC completed forms created today only
          String query =
              'SELECT f.* FROM ${FollowupFormDataTable.table} f '
              'JOIN beneficiaries_new b ON f.beneficiary_ref_key = b.unique_key '
              'WHERE f.forms_ref_key = ? '
              'AND (f.is_deleted IS NULL OR f.is_deleted = 0) '
              'AND DATE(f.created_date_time) = DATE(?) '
              'AND f.current_user_key = ? '
              'AND (b.is_death IS NULL OR b.is_death = 0)';

          List<dynamic> args = [ancFormKey, todayStr, ashaUniqueKey ?? ''];

          print('=== ANC Completed Query ===');
          print('Query: $query');
          print('Args: $args');
          print('============================');

          final rows = await db.rawQuery(query, args);

          print(
            'Found ${rows.length} ANC followup forms with created_date_time',
          );

          for (final row in rows) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            // Decode form_json
            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            // Get anc_form
            final Map<String, dynamic> ancForm = formJson['anc_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': ancForm['woman_name']?.toString() ?? '',
              'age': ancForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': ancForm['mobile']?.toString() ?? '-',
            };

            _ancCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key'] ?? '',
              'hhId': row['household_ref_key'] ?? '',
              'unique_key': row['beneficiary_ref_key'] ?? '',
              'BeneficiaryID': row['beneficiary_ref_key'] ?? '',
              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date': _formatAncDateOnly(
                row['created_date_time']?.toString(),
              ),
              'Current ANC last due date': '',
              'mobile': fields['mobile'],
              'badge': 'ANC',
              '_rawRow': row,
            });
          }
        } catch (e) {
          print('Error in ANC query: $e');
        }
        try {
          _eligibleCompletedCoupleItems = [];

          final ecFormKey =
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .eligibleCoupleTrackingDue] ??
                  '';

          if (ecFormKey.isNotEmpty) {
            // 1. Get all EC Tracking Due forms created before 1 month ago AND modified today
            final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
            String queryForms =
                'SELECT * FROM ${FollowupFormDataTable.table} '
                'WHERE forms_ref_key = ? '
                'AND (is_deleted IS NULL OR is_deleted = 0) '
                'AND DATE(created_date_time) < DATE(?) '
                'AND DATE(modified_date_time) = DATE(?)';

            List<dynamic> argsForms = [ecFormKey,
              '${oneMonthAgo.year.toString().padLeft(4, '0')}-${oneMonthAgo.month.toString().padLeft(2, '0')}-${oneMonthAgo.day.toString().padLeft(2, '0')}',
              todayStr];

            if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
              queryForms += ' AND current_user_key = ?';
              argsForms.add(ashaUniqueKey);
            }

            queryForms += ' ORDER BY modified_date_time DESC';

            print('=== EC Completed Query ===');
            print('Query: $queryForms');
            print('Args: $argsForms');
            print('===========================');

            final formRows = await db.rawQuery(queryForms, argsForms);

            print('=== DEBUG: EC Form Rows Found ===');
            print('Total EC Form Rows: ${formRows.length}');
            for (final row in formRows) {
              print('  - ID: ${row['id']}, Beneficiary: ${row['beneficiary_ref_key']}, Created: ${row['created_date_time']}');
            }
            print('================================');

            final processedBeneficiaries = <String>{};

            for (final row in formRows) {
              final beneficiaryId =
                  row['beneficiary_ref_key']?.toString() ?? '';
              if (beneficiaryId.isEmpty ||
                  processedBeneficiaries.contains(beneficiaryId)) {
                if (processedBeneficiaries.contains(beneficiaryId)) {
                  print('⚠️ SKIPPED: Beneficiary $beneficiaryId already processed');
                }
                continue;
              }

              print('=== DEBUG: Processing EC Form ===');
              print('Beneficiary ID: $beneficiaryId');
              print('Form Row ID: ${row['id']}');
              print('Created: ${row['created_date_time']}');
              print('================================');

              // Check if pregnant from form data
              final Map<String, dynamic> formJson = row['form_json'] != null
                  ? jsonDecode(row['form_json'] as String)
                  : {};

              final Map<String, dynamic> formData = formJson['form_data'] ?? {};
              final isPregnant = formData['is_pregnant']?.toString().toLowerCase() == 'yes';

              print('=== DEBUG: Pregnancy Check ===');
              print('Form Data: $formData');
              print('Is Pregnant: $isPregnant');
              print('================================');

              // Include forms that were created before 1 month ago AND modified today
              // This ensures only older records that were updated today are shown in completed list

              // Check if form was created before 1 month ago AND modified today
              bool meetsCriteria = false;
              try {
                final now = DateTime.now();
                final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));

                // Check created_date_time is before 1 month ago
                bool createdBeforeOneMonth = false;
                if (row['created_date_time'] != null) {
                  final createdDate = DateTime.parse(row['created_date_time'].toString());
                  createdBeforeOneMonth = createdDate.isBefore(oneMonthAgo);
                }

                // Check modified_date_time is today
                bool modifiedToday = false;
                if (row['modified_date_time'] != null) {
                  final modifiedDate = DateTime.parse(row['modified_date_time'].toString());
                  modifiedToday = modifiedDate.year == now.year &&
                      modifiedDate.month == now.month &&
                      modifiedDate.day == now.day;
                }

                meetsCriteria = createdBeforeOneMonth && modifiedToday;
              } catch (e) {
                print('Error parsing dates: $e');
              }

              print('=== DEBUG: Date Check ===');
              print('Created Date: ${row['created_date_time']}');
              print('Modified Date: ${row['modified_date_time']}');
              print('One Month Ago: ${DateTime.now().subtract(const Duration(days: 30))}');
              print('Meets Criteria (created < 1 month ago AND modified today): $meetsCriteria');
              print('================================');

              // Only include if created before 1 month ago AND modified today
              if (!meetsCriteria) {
                print('❌ SKIPPED: Form does not meet criteria (not created before 1 month ago AND modified today)');
                continue;
              }

              // Mark beneficiary as processed BEFORE adding to list
              processedBeneficiaries.add(beneficiaryId);

              if (isPregnant) {
                print('✅ INCLUDING: Pregnant woman found in completed forms (created before 1 month ago AND modified today)');
              } else {
                print('✅ INCLUDING: Non-pregnant woman found in completed forms (created before 1 month ago AND modified today)');
              }

              final fields = await _getBeneficiaryFields(beneficiaryId);

              // Check if this beneficiary is already in the completed list
              final alreadyInCompletedList = _eligibleCompletedCoupleItems
                  .any((item) => item['BeneficiaryID'] == beneficiaryId);

              if (alreadyInCompletedList) {
                print('⚠️ SKIPPED: Beneficiary $beneficiaryId already in completed list');
                continue;
              }

              _eligibleCompletedCoupleItems.add({
                'id': row['id'] ?? '',
                'household_ref_key': row['household_ref_key']?.toString() ?? '',
                'hhId': row['household_ref_key']?.toString() ?? '',
                'unique_key': row['beneficiary_ref_key'] ?? '',
                'BeneficiaryID': row['beneficiary_ref_key'] ?? '',
                'name': fields['name'],
                'age': fields['age'],
                'gender': fields['gender']?.isNotEmpty == true
                    ? fields['gender']
                    : 'Female',
                'last Visit date': _formatDateOnly(
                  row['created_date_time']?.toString(),
                ),
                'Current ANC last due date': '',
                'mobile': fields['mobile'],
                'badge': 'EligibleCouple',
                '_rawRow': row,
              });
            }
          }

          print('=== DEBUG: Final EC Completed List ===');
          print('Total EC Completed Items: ${_eligibleCompletedCoupleItems.length}');
          for (final item in _eligibleCompletedCoupleItems) {
            print('  - ID: ${item['id']}, BeneficiaryID: ${item['BeneficiaryID']}, Name: ${item['name']}');
          }
          print('==================================');
        } catch (e) {
          print('Error in eligible couple query: $e');
        }

        try {
          final hbncFormKey =
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .pncMother] ??
                  '';

          final formKeysHBNC = <String>[];
          if (hbncFormKey.isNotEmpty) formKeysHBNC.add(hbncFormKey);

          if (formKeysHBNC.isEmpty) return;

          final placeholdersHBNC = List.filled(
            formKeysHBNC.length,
            '?',
          ).join(',');

          String queryHBNC =
              'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholdersHBNC) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND created_date_time LIKE ?';
          List<dynamic> argsHBNC = [...formKeysHBNC, '$todayStr%'];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryHBNC += ' AND current_user_key = ?';
            argsHBNC.add(ashaUniqueKey);
          }

          print('=== HBNC Completed Query ===');
          print('Query: $queryHBNC');
          print('Args: $argsHBNC');
          print('============================');

          final rowsHBNC = await db.rawQuery(queryHBNC, argsHBNC);

          print('=== HBNC Query Results ===');
          print('HBNC Records Found: ${rowsHBNC.length}');
          for (final row in rowsHBNC) {
            print(
              'HBNC Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}',
            );
          }
          print('==========================');

          final List<Map<String, dynamic>> hbncCompleted = [];

          for (final row in rowsHBNC) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> hbncForm =
                formJson['pnc_mother_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': hbncForm['mother_name']?.toString() ?? '',
              'age': hbncForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': hbncForm['mobile']?.toString() ?? '-',
            };

            hbncCompleted.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key']?.toString() ?? '',
              'hhId': row['household_ref_key']?.toString() ?? '',
              'unique_key': row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID': row['beneficiary_ref_key']?.toString() ?? '',
              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date': _formatDateOnly(
                row['created_date_time']?.toString(),
              ),
              'mobile': fields['mobile'],
              'badge': 'HBNC',
              '_rawRow': row,
            });
          }

          if (mounted) {
            setState(() {
              _hbncCompletedItems = hbncCompleted;
            });
          }
        } catch (e) {
          debugPrint('HBNC error: $e');
        }

        try {
          String queryRI =
              'SELECT f.* FROM ${FollowupFormDataTable.table} f '
              'JOIN beneficiaries_new b ON f.beneficiary_ref_key = b.unique_key '
              'WHERE f.forms_ref_key = ? '
              'AND f.created_date_time LIKE ? '
              'AND (b.is_death IS NULL OR b.is_death = 0)';

          List<dynamic> argsRI = ['30bycxe4gv7fqnt6', '$todayStr%'];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryRI += ' AND f.current_user_key = ?';
            argsRI.add(ashaUniqueKey);
          }

          queryRI += ' ORDER BY f.id DESC';

          print('=== RI Completed Query ===');
          print('Query: $queryRI');
          print('Args: $argsRI');
          print('===========================');

          final resulrowsRI = await db.rawQuery(queryRI, argsRI);

          print('=== RI Query Results ===');
          print('RI Records Found: ${resulrowsRI.length}');
          for (final row in resulrowsRI) {
            print(
              'RI Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}',
            );
          }
          print('=========================');

          _riCompletedItems = [];

          for (final row in resulrowsRI) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> riForm =
                formJson['child_registration_due_form'] ??
                    formJson['tracking_due_form'] ??
                    formJson['form_data'] ??
                    {};

            // Get beneficiary data to extract DOB for proper age calculation
            final beneficiaryData = beneficiaryId.isNotEmpty
                ? await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
              beneficiaryId,
            )
                : null;

            String childName = '';
            String childDob = '';
            String childGender = '';
            String mobile = '';

            // Try to get child info from form data first
            childName =
                riForm['child_name']?.toString() ??
                    riForm['name']?.toString() ??
                    '';
            childGender = riForm['gender']?.toString() ?? '';
            mobile =
                riForm['mobile']?.toString() ??
                    riForm['mother_mobile']?.toString() ??
                    '-';

            // Extract DOB from beneficiary data if available
            if (beneficiaryData != null) {
              dynamic info = beneficiaryData['beneficiary_info'];
              Map<String, dynamic> beneficiaryInfo = {};

              if (info is Map) {
                beneficiaryInfo = Map<String, dynamic>.from(info);
              } else if (info is String && info.isNotEmpty) {
                try {
                  beneficiaryInfo = Map<String, dynamic>.from(jsonDecode(info));
                } catch (_) {}
              }

              // Use beneficiary name if form name is empty
              if (childName.isEmpty) {
                childName =
                    beneficiaryInfo['name']?.toString() ??
                        beneficiaryInfo['memberName']?.toString() ??
                        '';
              }

              // Extract DOB from beneficiary info
              childDob =
                  beneficiaryInfo['dob']?.toString() ??
                      beneficiaryInfo['dateOfBirth']?.toString() ??
                      beneficiaryInfo['date_of_birth']?.toString() ??
                      '';

              // Use beneficiary gender if form gender is empty
              if (childGender.isEmpty) {
                childGender =
                    beneficiaryInfo['gender']?.toString() ??
                        beneficiaryInfo['sex']?.toString() ??
                        'Female';
              }

              // Use beneficiary mobile if form mobile is empty
              if (mobile == '-' || mobile.isEmpty) {
                mobile =
                    beneficiaryInfo['mobileNo']?.toString() ??
                        beneficiaryInfo['mobile']?.toString() ??
                        beneficiaryInfo['phone']?.toString() ??
                        '-';
              }
            }

            // Calculate age using DOB with same logic as RegisterChildListScreen
            String calculatedAgeGender = _formatAgeGenderFromDob(
              childDob,
              childGender,
            );

            // Extract only the age part (before the |) to avoid duplication in UI
            String calculatedAge = calculatedAgeGender.contains('|')
                ? calculatedAgeGender.split('|')[0].trim()
                : calculatedAgeGender;

            _riCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key']?.toString() ?? '',
              'hhId': row['household_ref_key']?.toString() ?? '',
              'unique_key': row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID': row['beneficiary_ref_key']?.toString() ?? '',

              'name': childName.isNotEmpty ? childName : 'Unknown',
              'age': calculatedAge,
              'gender': childGender.isNotEmpty ? childGender : 'Female',
              'last Visit date': _formatDateOnly(
                row['created_date_time']?.toString(),
              ),
              'mobile': mobile,
              'badge': 'RI',

              '_rawRow': row,
            });
          }
        } catch (e) {
          debugPrint('RI error: $e');
        }

        /* final rows = await db.rawQuery(
          'SELECT COUNT(*) AS cnt FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholders) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND DATE(created_date_time) = DATE(?)',
          [...formKeys, todayStr],
        );*/

        final count =
            (_ancCompletedItems.length) +
                (_eligibleCompletedCoupleItems.length ?? 0) +
                (_hbncCompletedItems.length ?? 0) +
                (_riCompletedItems.length ?? 0) +
                (_familySurveyCompletedItems.length ?? 0);
        if (mounted && count > _completedVisitsCount) {
          setState(() {
            _completedVisitsCount = count;
          });
          await _saveTodayWorkCountsToStorage();
        }

        // Print completed items count to console
        _printCompletedItemsCount();
      } catch (e) {
        print(e);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completedVisitsCount = 0;
        });
      }
    }
  }

  String _formatAncDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }

  int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    try {
      DateTime? birthDate;

      // Try parsing the date string
      if (dob.contains('T')) {
        birthDate = DateTime.tryParse(dob.split('T')[0]);
      } else {
        birthDate = DateTime.tryParse(dob);
      }

      if (birthDate == null) {
        // If parsing fails, try to extract date parts manually
        final parts = dob.split(RegExp(r'[^0-9]'));
        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]) ?? 0;
          final month = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          birthDate = DateTime(year, month, day);
        } else {
          return 0;
        }
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age > 0 ? age : 0;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  Future<Map<String, String>> _getBeneficiaryFields(String uniqueKey) async {
    final rec = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
      uniqueKey,
    );
    if (rec == null) {
      return {'name': '', 'age': '', 'gender': '', 'mobile': '-'};
    }

    dynamic info = rec['beneficiary_info'];
    Map<String, dynamic> m = {};
    if (info is Map) {
      m = Map<String, dynamic>.from(info);
    } else if (info is String && info.isNotEmpty) {
      try {
        m = Map<String, dynamic>.from(jsonDecode(info));
      } catch (_) {}
    }

    final name =
        (m['name']?.toString()?.trim().isNotEmpty == true
            ? m['name']?.toString()
            : null) ??
            m['memberName']?.toString() ??
            m['headName']?.toString() ??
            '';

    final dob = m['dob']?.toString() ?? m['date_of_birth']?.toString();
    var ageYears = _calculateAge(dob);
    if (ageYears == 0) {
      final updateYearStr = m['updateYear']?.toString() ?? '';
      final approxAgeStr = m['approxAge']?.toString() ?? '';
      final parsedUpdateYear = int.tryParse(updateYearStr);
      if (parsedUpdateYear != null && parsedUpdateYear > 0) {
        ageYears = parsedUpdateYear;
      } else if (approxAgeStr.isNotEmpty) {
        final matches = RegExp(r"\d+").allMatches(approxAgeStr).toList();
        if (matches.isNotEmpty) {
          ageYears = int.tryParse(matches.first.group(0) ?? '') ?? 0;
        }
      }
    }

    final gender = m['gender']?.toString() ?? '';
    final mobile =
        (m['mobileNo'] ?? m['mobile'] ?? m['phone'])?.toString() ?? '-';

    return {
      'name': name,
      'age': ageYears > 0 ? ageYears.toString() : '',
      'gender': gender,
      'mobile': mobile.isNotEmpty ? mobile : '-',
    };
  }


  String _formatDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }
  void _printCompletedItemsCount() {
    final ancCount = _ancCompletedItems.length;
    final hbncCount = _hbncCompletedItems.length;
    final ecCount = _eligibleCompletedCoupleItems.length;
    final riCount = _riCompletedItems.length;
    final familySurveyCount = _familySurveyCompletedItems.length;
    final totalCount = ancCount + hbncCount + ecCount + riCount + familySurveyCount;

    print('=== Completed Items Count ===');
    print('ANC Completed Items: $ancCount');
    print('HBNC Completed Items: $hbncCount');
    print('Eligible Couple Completed Items: $ecCount');
    print('RI Completed Items: $riCount');
    print('Family Survey Completed Items: $familySurveyCount');
    print('Total Completed Items: $totalCount');
    print('_completedVisitsCount (State): $_completedVisitsCount');
    print('_toDoVisitsCount (from Storage): $_toDoVisitsCount');
    print('============================');
  }

  Future<void> _loadFamilySurveyItems() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhRefKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhRefKey] = headId;
        }
      }

      final DateTime now = DateTime.now();
      final DateTime sixMonthsAgo = now.subtract(const Duration(days: 180));
      final String todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (final row in rows) {
        try {
          if (ashaUniqueKey != null &&
              ashaUniqueKey.isNotEmpty &&
              row['current_user_key']?.toString() != ashaUniqueKey) {
            continue;
          }

          if (row['is_death'] == 1 ||
              row['is_migrated'] == 1 ||
              row['is_deleted'] == 1) continue;

          final String householdRefKey =
              row['household_ref_key']?.toString() ?? '';
          final String uniqueKey =
              row['unique_key']?.toString() ?? '';

          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;

          // ------------------ BENEFICIARY INFO ------------------
          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info =
          infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw);

          final bool isFamilyHeadFromInfo =
              info['isFamilyhead'] == true ||
                  info['isFamilyHead']?.toString() == 'true';

          final String? configuredHeadKey =
          headKeyByHousehold[householdRefKey];

          final bool isHouseholdHead =
              configuredHeadKey != null &&
                  configuredHeadKey == uniqueKey;

          // ❌ If neither condition matches → skip
          if (!isHouseholdHead && !isFamilyHeadFromInfo) continue;

          DateTime? createdDt;
          DateTime? modifiedDt;

          try {
            // if (row['created_date_time'] != null &&
            //     row['created_date_time'].toString().isNotEmpty) {
            //   String dateStr = row['created_date_time'].toString();
            //   // Handle both "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS" formats
            //   if (dateStr.contains(' ')) {
            //     dateStr = dateStr.split(' ')[0];
            //   } else if (dateStr.contains('T')) {
            //     dateStr = dateStr.split('T')[0];
            //   }
            //   createdDt = DateTime.parse(dateStr);
            // }

            if (row['modified_date_time'] != null &&
                row['modified_date_time'].toString().isNotEmpty) {
              String dateStr = row['modified_date_time'].toString();
              // Handle both "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS" formats
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              modifiedDt = DateTime.parse(dateStr);
            }
          } catch (_) {}

          final bool isEligible =
              modifiedDt != null && modifiedDt.isBefore(sixMonthsAgo);

          if (!isEligible) continue;

          // ------------------ CHECK IF MODIFIED TODAY ------------------
          bool isModifiedToday = false;
          final String? rawModifiedDate = row['modified_date_time']?.toString();

          if (rawModifiedDate != null && rawModifiedDate.isNotEmpty) {
            try {
              String dateStr = rawModifiedDate;
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              if (dateStr == todayStr) {
                isModifiedToday = true;
                print('📋 Record was modified today - excluding from to-do list');
              }
            } catch (e) {
              // If parsing fails, try to extract date part
              if (rawModifiedDate.contains(' ')) {
                final datePart = rawModifiedDate.split(' ')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record was modified today (fallback) - excluding from to-do list');
                }
              } else if (rawModifiedDate.contains('T')) {
                final datePart = rawModifiedDate.split('T')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record was modified today (fallback) - excluding from to-do list');
                }
              }
            }
          }

          // Skip if modified today (these go to completed tab)
          if (isModifiedToday) continue;

          // ------------------ LAST SURVEY DATE ------------------
          final String lastSurveyDate = modifiedDt != null
              ? '${modifiedDt.day}-${modifiedDt.month}-${modifiedDt.year}'
              : '-';

          // ------------------ DISPLAY DATA ------------------
          final String name =
              (info['headName'])
                  ?.toString()
                  .trim() ??
                  '';
          if (name.isEmpty) continue;

          final String gender = (info['gender']?.toString() ?? '-')
              .toLowerCase()
              .replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());

          String ageText = '-';
          final String? dobRaw = info['dob']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            final dob = DateTime.tryParse(dobRaw.split('T')[0]);
            if (dob != null) {
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age >= 0) ageText = '${age}Y';
            }
          } else if (info['age'] != null) {
            ageText = '${info['age']}y';
          }

          final String mobile =
              info['mobileNo']?.toString() ??
                  info['phone']?.toString() ??
                  '-';

          String displayId = uniqueKey;
          if (displayId.length > 11) {
            displayId = displayId.substring(displayId.length - 11);
          }

          final rawCreatedDate = row['created_date_time']?.toString();

          print('=== DEBUG: Adding Family Survey Item ===');
          print('Name: $name');
          print('Raw Modified Date: $rawModifiedDate');
          print('Last Survey Date (based on modified date): $lastSurveyDate');
          print('Note: Only modified date is checked for 6+ month eligibility');
          print('=====================================');

          items.add({
            'id': displayId,
            'beneficiary_ref_key': uniqueKey,
            'household_ref_key': householdRefKey,
            'name': name,
            'age': ageText,
            'gender': gender,
            'last survey date': lastSurveyDate,
            'lastSurveyDate': lastSurveyDate, // Add this field for UI display
            'Next HBNC due date': '-',
            'mobile': mobile,
            'badge': 'Family',
            // Add raw date fields for completed tab filtering
            'created_date': rawCreatedDate,
            'modified_date': rawModifiedDate,
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _familySurveyItems = items;
        });
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('Family survey load error: $e');
    }
  }

  Future<void> _loadEligibleCoupleItems() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return;

      final DateTime oneMonthAgo =
      DateTime.now().subtract(const Duration(days: 30));

      final ecRows = await db.query(
        EligibleCoupleActivitiesTable.table,
        columns: [
          'beneficiary_ref_key',
          'created_date_time',
          'modified_date_time',
        ],
        where: '''
        eligible_couple_state = ?
        AND current_user_key = ?
        AND (is_deleted IS NULL OR is_deleted = 0)
      ''',
        whereArgs: ['tracking_due', ashaUniqueKey],
      );

      // ------------------ STEP 2: FILTER 1 MONTH OLD ------------------
      final Set<String> eligibleBeneficiaryKeys = {};

      for (final row in ecRows) {
        final String? beneficiaryKey =
        row['beneficiary_ref_key']?.toString();
        if (beneficiaryKey == null || beneficiaryKey.isEmpty) continue;

        DateTime? createdDate;
        DateTime? modifiedDate;

        try {
          if (row['created_date_time'] != null &&
              row['created_date_time'].toString().isNotEmpty) {
            createdDate =
                DateTime.parse(row['created_date_time'].toString());
          }

          if (row['modified_date_time'] != null &&
              row['modified_date_time'].toString().isNotEmpty) {
            modifiedDate =
                DateTime.parse(row['modified_date_time'].toString());
          }
        } catch (_) {
          continue;
        }

        final bool isValid =
            createdDate != null &&
                createdDate.isBefore(oneMonthAgo) &&
                (modifiedDate == null ||
                    modifiedDate.isBefore(oneMonthAgo));

        if (isValid) {
          eligibleBeneficiaryKeys.add(beneficiaryKey);
        }
      }

      if (eligibleBeneficiaryKeys.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) setState(() {});
        _saveTodayWorkCountsToStorage();
        return;
      }

      // ------------------ STEP 3: FILTER OUT COMPLETED TODAY ------------------
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final ecFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .eligibleCoupleTrackingDue] ?? '';

      if (ecFormKey.isNotEmpty) {
        final completedTodayQuery = '''
          SELECT DISTINCT beneficiary_ref_key 
          FROM ${FollowupFormDataTable.table} 
          WHERE forms_ref_key LIKE ? 
          AND DATE(created_date_time) = DATE(?)
          AND (is_deleted IS NULL OR is_deleted = 0)
        ''';

        final completedTodayRows = await db.rawQuery(
          completedTodayQuery,
          [ecFormKey, todayStr],
        );

        print('=== DEBUG: EC Completed Today Filter ===');
        print('Form Key: $ecFormKey');
        print('Today String: $todayStr');
        print('Completed Today Query: $completedTodayQuery');
        print('Completed Today Rows: ${completedTodayRows.length}');
        for (final row in completedTodayRows) {
          print('  - Beneficiary: ${row['beneficiary_ref_key']}, Form Key: ${row['forms_ref_key']}, Created: ${row['created_date_time']}');
        }
        print('=====================================');

        final Set<String> completedTodayBeneficiaries = completedTodayRows
            .map((row) => row['beneficiary_ref_key']?.toString() ?? '')
            .where((key) => key.isNotEmpty)
            .toSet();

        print('Completed Today Beneficiaries: $completedTodayBeneficiaries');
        print('Before Filter - Eligible Beneficiary Keys: $eligibleBeneficiaryKeys');

        // Remove completed beneficiaries from eligible list
        eligibleBeneficiaryKeys.removeAll(completedTodayBeneficiaries);

        print('After Filter - Eligible Beneficiary Keys: $eligibleBeneficiaryKeys');
        print('Removed ${completedTodayBeneficiaries.length} beneficiaries from eligible list');
        print('=====================================');
      }

      // ------------------ STEP 4: FETCH BENEFICIARIES ------------------
      final placeholders =
      List.filled(eligibleBeneficiaryKeys.length, '?').join(',');

      final beneficiaryRows = await db.query(
        'beneficiaries_new',
        where: '''
        unique_key IN ($placeholders)
        AND (is_deleted IS NULL OR is_deleted = 0)
        AND (is_migrated IS NULL OR is_migrated = 0)
      ''',
        whereArgs: eligibleBeneficiaryKeys.toList(),
      );

      _eligibleCoupleItems.clear();

      // ------------------ STEP 4: BUILD FINAL LIST ------------------
      for (final member in beneficiaryRows) {
        final dynamic infoRaw = member['beneficiary_info'];
        if (infoRaw == null) continue;

        Map<String, dynamic> info = {};
        try {
          info = infoRaw is String
              ? jsonDecode(infoRaw)
              : Map<String, dynamic>.from(infoRaw);
        } catch (_) {}

        final String beneficiaryId =
            member['unique_key']?.toString() ?? '';

        // -------- AGE --------
        String ageText = '-';
        final String dob = info['dob']?.toString() ?? '';

        if (dob.isNotEmpty) {
          final int age = _calculateAgeFromDob(dob);
          if (age > 0) ageText = age.toString();
        } else if (info['age'] != null &&
            info['age'].toString().isNotEmpty) {
          ageText = info['age'].toString();
        }

        // -------- LAST VISIT FROM FOLLOWUP --------
        final String lastVisitDate =
        await _getLastVisitDate(
          beneficiaryId: beneficiaryId,
          formRefKey: '0g5au2h46icwjlvr',
        );

        _eligibleCoupleItems.add({
          'id': member['id'],
          'unique_key': beneficiaryId,

          'beneficiary_id': beneficiaryId,
          'beneficiaryId': beneficiaryId,
          'BeneficiaryID': beneficiaryId,

          'household_ref_key': member['household_ref_key'],
          'name': info['memberName'] ??
              info['headName'] ??
              info['name'] ??
              '',
          'gender':
          info['gender']?.toString().toLowerCase() ?? 'female',
          'age': ageText,
          'mobile':
          info['mobileNo']?.toString() ?? 'Not Available',
          'badge': 'EligibleCouple',

          // ✅ CORRECT LAST VISIT DATE
          'last Visit date': lastVisitDate,

          '_rawRow': member,
        });
      }

      if (mounted) {
        setState(() {});
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('Eligible Couple load error: $e');
    }
  }

  Future<void> _loadFamilySurveyCompletedItems() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhRefKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhRefKey] = headId;
        }
      }

      final DateTime now = DateTime.now();
      final String todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      print('=== DEBUG: Loading Family Survey Completed Items ===');
      print('Today String: $todayStr');
      print('Filter Criteria: Created before 6 months AND modified today');

      for (final row in rows) {
        try {
          if (ashaUniqueKey != null &&
              ashaUniqueKey.isNotEmpty &&
              row['current_user_key']?.toString() != ashaUniqueKey) {
            continue;
          }

          if (row['is_death'] == 1 ||
              row['is_migrated'] == 1 ||
              row['is_deleted'] == 1) continue;

          final String householdRefKey =
              row['household_ref_key']?.toString() ?? '';
          final String uniqueKey =
              row['unique_key']?.toString() ?? '';

          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;

          // ------------------ BENEFICIARY INFO ------------------
          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info =
          infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw);

          final bool isFamilyHeadFromInfo =
              info['isFamilyhead'] == true ||
                  info['isFamilyHead']?.toString() == 'true';

          final String? configuredHeadKey =
          headKeyByHousehold[householdRefKey];

          final bool isHouseholdHead =
              configuredHeadKey != null &&
                  configuredHeadKey == uniqueKey;

          // ❌ If neither condition matches → skip
          if (!isHouseholdHead && !isFamilyHeadFromInfo) continue;

          // ------------------ CHECK IF CREATED BEFORE 6 MONTHS AND MODIFIED TODAY ------------------
          final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
          bool meetsCriteria = false;
          final String? rawModifiedDate = row['modified_date_time']?.toString();
          final String? rawCreatedDate = row['created_date_time']?.toString();

          if (rawModifiedDate != null && rawModifiedDate.isNotEmpty && rawCreatedDate != null && rawCreatedDate.isNotEmpty) {
            try {
              // Check if modified today
              bool isModifiedToday = false;
              String modifiedDateStr = rawModifiedDate;
              if (modifiedDateStr.contains(' ')) {
                modifiedDateStr = modifiedDateStr.split(' ')[0];
              } else if (modifiedDateStr.contains('T')) {
                modifiedDateStr = modifiedDateStr.split('T')[0];
              }
              if (modifiedDateStr == todayStr) {
                isModifiedToday = true;
              }

              // Check if created before 6 months
              bool createdBeforeSixMonths = false;
              String createdDateStr = rawCreatedDate;
              if (createdDateStr.contains(' ')) {
                createdDateStr = createdDateStr.split(' ')[0];
              } else if (createdDateStr.contains('T')) {
                createdDateStr = createdDateStr.split('T')[0];
              }
              final createdDate = DateTime.parse(createdDateStr);
              createdBeforeSixMonths = createdDate.isBefore(sixMonthsAgo);

              meetsCriteria = isModifiedToday && createdBeforeSixMonths;

              print('=== DEBUG: Family Survey Date Check ===');
              print('Created Date: $rawCreatedDate');
              print('Modified Date: $rawModifiedDate');
              print('Six Months Ago: $sixMonthsAgo');
              print('Created Before 6 Months: $createdBeforeSixMonths');
              print('Modified Today: $isModifiedToday');
              print('Meets Criteria: $meetsCriteria');
              print('====================================');
            } catch (e) {
              print('Error parsing dates for family survey: $e');
            }
          }

          // Only include if created before 6 months AND modified today
          if (!meetsCriteria) continue;

          // ------------------ DATE PARSING ------------------
          DateTime? createdDt;
          DateTime? modifiedDt;

          try {
            if (row['created_date_time'] != null &&
                row['created_date_time'].toString().isNotEmpty) {
              String dateStr = row['created_date_time'].toString();
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              createdDt = DateTime.parse(dateStr);
            }

            if (row['modified_date_time'] != null &&
                row['modified_date_time'].toString().isNotEmpty) {
              String dateStr = row['modified_date_time'].toString();
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              modifiedDt = DateTime.parse(dateStr);
            }
          } catch (_) {}

          // ------------------ LAST SURVEY DATE ------------------
          final String lastSurveyDate = modifiedDt != null
              ? '${modifiedDt.day}-${modifiedDt.month}-${modifiedDt.year}'
              : '-';

          // ------------------ DISPLAY DATA ------------------
          final String name =
              (info['headName'])
                  ?.toString()
                  .trim() ??
                  '';
          if (name.isEmpty) continue;

          final String gender = (info['gender']?.toString() ?? '-')
              .toLowerCase()
              .replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());

          String ageText = '-';
          final String? dobRaw = info['dob']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            final dob = DateTime.tryParse(dobRaw.split('T')[0]);
            if (dob != null) {
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age >= 0) ageText = '${age}Y';
            }
          } else if (info['age'] != null) {
            ageText = '${info['age']}y';
          }

          final String mobile =
              info['mobileNo']?.toString() ??
                  info['phone']?.toString() ??
                  '-';

          String displayId = uniqueKey;
          if (displayId.length > 11) {
            displayId = displayId.substring(displayId.length - 11);
          }

          print('=== DEBUG: Adding Family Survey Completed Item ===');
          print('Name: $name');
          print('Raw Created Date: $rawCreatedDate');
          print('Raw Modified Date: $rawModifiedDate');
          print('Last Survey Date: $lastSurveyDate');
          print('Criteria: Created before 6 months AND modified today');
          print('=============================================');

          items.add({
            'id': displayId,
            'household_ref_key': householdRefKey,
            'name': name,
            'age': ageText,
            'gender': gender,
            'last survey date': lastSurveyDate,
            'lastSurveyDate': lastSurveyDate,
            'Next HBNC due date': '-',
            'mobile': mobile,
            'badge': 'Family',
            'created_date': rawCreatedDate,
            'modified_date': rawModifiedDate,
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _familySurveyCompletedItems = items;
        });
        print('=== DEBUG: Family Survey Completed Items Loaded ===');
        print('Total Completed Items: ${items.length}');
        print('===============================================');
      }
    } catch (e) {
      debugPrint('Family survey completed load error: $e');
    }
  }

  Future<void> _loadAncItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> items = [];
      final Set<String> processedBeneficiaries = {};

      String query = '''
      SELECT 
        mca.*,
        bn.*,
        bn.household_ref_key
      FROM mother_care_activities mca
      INNER JOIN beneficiaries_new bn
        ON mca.beneficiary_ref_key = bn.unique_key
      WHERE mca.mother_care_state = 'anc_due'
        AND bn.is_deleted = 0
    ''';

      final List<dynamic> args = [];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        query += ' AND bn.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      query += ' ORDER BY mca.created_date_time DESC';

      final List<Map<String, Object?>> rows =
      await db.rawQuery(query, args);

      final DateTime today = DateTime.now();
      final DateTime todayDate =
      DateTime(today.year, today.month, today.day);

      bool isTodayInsideWindow(DateTime start, DateTime end) {
        final s = DateTime(start.year, start.month, start.day);
        final e = DateTime(end.year, end.month, end.day);
        return (todayDate.isAtSameMomentAs(s) ||
            todayDate.isAfter(s)) &&
            (todayDate.isAtSameMomentAs(e) ||
                todayDate.isBefore(e));
      }

      for (final row in rows) {
        final String beneficiaryKey =
            row['beneficiary_ref_key']?.toString() ?? '';

        if (beneficiaryKey.isEmpty ||
            processedBeneficiaries.contains(beneficiaryKey)) {
          continue;
        }
        processedBeneficiaries.add(beneficiaryKey);

        if (row['is_death'] == 1 || row['is_migrated'] == 1) continue;

        final Object? infoRaw = row['beneficiary_info'];
        if (infoRaw == null) continue;

        late Map<String, dynamic> info;
        try {
          info = infoRaw is String
              ? jsonDecode(infoRaw) as Map<String, dynamic>
              : Map<String, dynamic>.from(infoRaw as Map);
        } catch (_) {
          continue;
        }

        final bool isPregnant =
            info['isPregnant']?.toString().toLowerCase() == 'yes';
        final String gender =
            info['gender']?.toString().toLowerCase() ?? '';

        if (!isPregnant && gender != 'f' && gender != 'female') continue;

        DateTime? lmpDate = await _extractLmpDate(row);
        lmpDate ??= info['lmp'] != null
            ? DateTime.tryParse(info['lmp'].toString().split('T')[0])
            : null;

        if (lmpDate == null) continue;

        final Map<String, DateTime?> ancRanges =
        _calculateAncDateRanges(lmpDate);

        DateTime? activeWindowStart;
        DateTime? activeWindowEnd;

        final windows = [
          ['1st_anc_start', '1st_anc_end'],
          ['2nd_anc_start', '2nd_anc_end'],
          ['3rd_anc_start', '3rd_anc_end'],
          ['4th_anc_start', '4th_anc_end'],
        ];

        for (final w in windows) {
          final start = ancRanges[w[0]];
          final end = ancRanges[w[1]];
          if (start != null &&
              end != null &&
              isTodayInsideWindow(start, end)) {
            activeWindowStart = start;
            activeWindowEnd = end;
            break;
          }
        }

        // ---------- STRICT FILTER ----------
        // ❌ If today is not inside ANY ANC window → skip
        if (activeWindowStart == null || activeWindowEnd == null) {
          continue;
        }

        final String currentAncDueDate =
        _formatAncDateOnly(activeWindowEnd.toIso8601String());

        // ---------- Check if ANC followup form exists within current ANC window ----------
        final ancFormKey = 'bt7gs9rl1a5d26mz';
        final followupFormsQuery = await db.query(
          FollowupFormDataTable.table,
          where: '''
            forms_ref_key = ? 
            AND beneficiary_ref_key = ? 
            AND (is_deleted IS NULL OR is_deleted = 0)
            AND DATE(created_date_time) >= DATE(?) 
            AND DATE(created_date_time) <= DATE(?)
          ''',
          whereArgs: [
            ancFormKey,
            beneficiaryKey,
            activeWindowStart.toIso8601String().split('T')[0],
            activeWindowEnd.toIso8601String().split('T')[0]
          ],
          limit: 1,
        );

        if (followupFormsQuery.isNotEmpty) {
          continue;
        }

        // ---------- Check if current date exceeds 4th ANC window and no ANC follow-up exists ----------
        final fourthAncEnd = ancRanges['4th_anc_end'];
        if (fourthAncEnd != null && today.isAfter(fourthAncEnd)) {
          // Check if beneficiary has ANY ANC follow-up form in any window
          final anyAncFollowupQuery = await db.query(
            FollowupFormDataTable.table,
            where: '''
              forms_ref_key = ? 
              AND beneficiary_ref_key = ? 
              AND (is_deleted IS NULL OR is_deleted = 0)
            ''',
            whereArgs: [ancFormKey, beneficiaryKey],
            limit: 1,
          );

          if (anyAncFollowupQuery.isEmpty) {
            // No ANC follow-up found and current date is beyond 4th ANC window
            continue;
          }
        }

        // ---------- Age ----------
        String ageText = '-';
        if (info['dob'] != null) {
          final DateTime? dob =
          DateTime.tryParse(info['dob'].toString().split('T')[0]);
          if (dob != null) {
            int age = today.year - dob.year;
            final birthdayThisYear =
            DateTime(today.year, dob.month, dob.day);
            if (todayDate.isBefore(birthdayThisYear)) age--;
            ageText = '$age Y';
          }
        }

        final String uniqueKey = row['unique_key']?.toString() ?? '';
        final String householdRefKey =
            row['household_ref_key']?.toString() ?? '';

        // ---------- Add record ----------
        items.add({
          'id': uniqueKey.length > 11
              ? uniqueKey.substring(uniqueKey.length - 11)
              : uniqueKey,
          'unique_key': uniqueKey,
          'household_ref_key': householdRefKey,
          'name':
          info['memberName'] ?? info['name'] ?? 'Unknown',
          'age': ageText,
          'gender': 'Female',
          'last Visit date':
          _formatAncDateOnly(activeWindowStart.toIso8601String()),
          'Current ANC last due date': currentAncDueDate,
          'mobile': info['mobileNo'] ?? '-',
          'badge': 'ANC',
          'beneficiary_info': jsonEncode(info),
          '_rawRow': row,
        });
      }

      if (mounted) {
        setState(() => _ancItems = items);
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('ANC load error: $e');
    }
  }


  Future<void> _loadHbncItems() async {
    try {
      setState(() => _isLoading = true);
      _hbncItems = [];

      final Set<String> processedBeneficiaries = <String>{};

      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey =
          '4r7twnycml3ej1vg';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String whereClause = 'forms_ref_key = ?';
      List<dynamic> whereArgs = [deliveryOutcomeKey];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: whereClause,
        whereArgs: whereArgs,
      );

      debugPrint('Found ${dbOutcomes.length} delivery outcomes');

      for (final outcome in dbOutcomes) {
        try {
          final formJson = jsonDecode(outcome['form_json'] as String? ?? '{}');
          final formData = formJson['form_data'] ?? {};
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            debugPrint(
              '⚠️ Missing beneficiary_ref_key in outcome: ${outcome['id']}',
            );
            continue;
          }

          // Skip if already processed
          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            debugPrint(
              'ℹ️ Skipping duplicate outcome for beneficiary: $beneficiaryRefKey',
            );
            continue;
          }
          processedBeneficiaries.add(beneficiaryRefKey);

          // Get beneficiary details
          String benWhere =
              'unique_key = ? AND (is_deleted = 0 OR is_deleted IS NULL)';
          List<dynamic> benArgs = [beneficiaryRefKey];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            benWhere += ' AND current_user_key = ?';
            benArgs.add(ashaUniqueKey);
          }

          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: benWhere,
            whereArgs: benArgs,
          );

          if (beneficiaryResults.isEmpty) {
            debugPrint('⚠️ No beneficiary found for key: $beneficiaryRefKey');
            continue;
          }

          final beneficiary = beneficiaryResults.first;
          final beneficiaryInfoRaw =
              beneficiary['beneficiary_info'] as String? ?? '{}';

          Map<String, dynamic> beneficiaryInfo;
          try {
            beneficiaryInfo = jsonDecode(beneficiaryInfoRaw);
          } catch (e) {
            debugPrint('Error parsing beneficiary info: $e');
            continue;
          }

          // Extract data
          final name =
              beneficiaryInfo['memberName']?.toString() ??
                  beneficiaryInfo['headName']?.toString() ??
                  'N/A';
          final dob = beneficiaryInfo['dob']?.toString();
          final age = _calculateAge(dob);
          final gender =
          (beneficiaryInfo['gender']?.toString() ?? 'female')
              .toLowerCase() ==
              'female'
              ? 'Female'
              : 'Male';
          final mobile = beneficiaryInfo['mobileNo']?.toString() ?? '-';
          final spouseName = beneficiaryInfo['spouseName']?.toString() ?? '-';
          final householdRefKey =
              beneficiary['household_ref_key']?.toString() ?? '';

          // Get registration date from mother_care_activities table for pnc_mother state
          String registrationDate = beneficiary['created_date_time']?.toString() ?? '';
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

          // Use HBNCList logic for visit count and dates
          final visitCount = await _getHbncVisitCountFromHBNCList(beneficiaryRefKey);
          final previousHBNCDate = await _getHbncLastVisitDateFromHBNCList(beneficiaryRefKey);
          final deliveryDate = formData['delivery_date']?.toString();
          print('📅 Passing delivery date to _getHbncNextVisitDateFromHBNCList: $deliveryDate');
          print('📊 Passing visit count to _getHbncNextVisitDateFromHBNCList: $visitCount');
          final nextHBNCDate = await _getHbncNextVisitDateFromHBNCList(
            beneficiaryRefKey,
            deliveryDate,
            visitCount,
            registrationDate,
          );

          print('📊 Final values for beneficiary $beneficiaryRefKey:');
          print('  - Visit Count: $visitCount');
          print('  - Previous HBNC Date: $previousHBNCDate');
          print('  - Next HBNC Date: $nextHBNCDate');

          // Get visit number for filtering logic (keep existing logic)
          final visitNumber = await _getHbncVisitNumber(beneficiaryRefKey);

          // Apply filtering logic based on visit number
          if (visitNumber != null) {
            // Handle visit number 0 case - show record if today's date matches any criteria
            if (visitNumber == 0) {
              debugPrint(
                '✅ Including HBNC record for $beneficiaryRefKey - visit number 0',
              );
            } else {
              // For other visit numbers, apply specific filtering
              final specificVisitNumbers = [3, 7, 14, 21, 28, 42];
              if (!specificVisitNumbers.contains(visitNumber)) {
                debugPrint(
                  '🗑️ Skipping HBNC record for $beneficiaryRefKey - visit number $visitNumber not in specific list',
                );
                continue;
              }

              // Check if next visit date is today, in the past, or matches today's date
              if (nextHBNCDate != null && nextHBNCDate.isNotEmpty) {
                final nextDate = _parseDate(nextHBNCDate);
                if (nextDate != null) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final nextDateOnly = DateTime(
                    nextDate.year,
                    nextDate.month,
                    nextDate.day,
                  );

                  // Show if next visit date is today, in the past, or exactly matches today
                  if (nextDateOnly.isAfter(today)) {
                    debugPrint(
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is in the future',
                    );
                    continue;
                  }

                  // If next visit date is today or in the past, show the record
                  if (nextDateOnly.isBefore(today) ||
                      nextDateOnly.isAtSameMomentAs(today)) {
                    debugPrint(
                      '✅ Including HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is today or in the past',
                    );
                  } else {
                    debugPrint(
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is in the future',
                    );
                    continue;
                  }
                }
              }
            }
          }
          // If visitNumber is null, show all records (existing behavior)

          // Check if beneficiary already has a completed HBNC form (to exclude from to-do list)
          final hasCompletedHbncForm = await _hasCompletedHbncForm(
            beneficiaryRefKey,
          );
          if (hasCompletedHbncForm) {
            debugPrint(
              '🗑️ Skipping HBNC record for $beneficiaryRefKey - already has completed HBNC form',
            );
            continue;
          }

          // Check if visit count will change between current date and next HBNC visit date
          final shouldRemoveFromList =
          await _shouldRemoveHbncRecordDueToCountChange(
            beneficiaryRefKey,
            formData['delivery_date']?.toString(),
            visitCount,
          );

          // If count will change, skip adding this record to list
          if (shouldRemoveFromList) {
            debugPrint(
              '🗑️ Removing HBNC record for $beneficiaryRefKey - visit count will change before next visit',
            );
            continue;
          }

          // Format the data for display
          // In the _loadHbncItems method, update the formattedData map to include the 'badge' field
          final formattedData = {
            'id': _last11(beneficiaryRefKey),
            'unique_key': beneficiaryRefKey,
            'name': name,
            'age': _formatAgeWithSuffix(age),
            'gender': gender,
            'mobile': mobile,
            // spouse_name removed as requested
            'household_ref_key': householdRefKey,
            'delivery_date': formData['delivery_date']?.toString() ?? '-',
            'last_visit_date': previousHBNCDate ?? '-',
            'next_visit_date': nextHBNCDate ?? '-',
            'visit_count': visitCount,
            'is_hbnc': true,
            'beneficiary_info': jsonEncode(beneficiaryInfo),
            'form_data': formData,
            'badge': 'HBNC', // Add this line to ensure the badge shows "HBNC"
            'last Visit date':
            previousHBNCDate ??
                '-', // Ensure this matches the card's expected field name
            'next hbnc visit due date':
            nextHBNCDate ??
                '-', // Changed from 'Current HBNC last due date' to 'next hbnc visit due date'
            'fullBeneficiaryId': beneficiaryRefKey, // Add this for navigation
            'fullHhId': householdRefKey, // Add this for navigation
          };

          setState(() {
            _hbncItems.add(formattedData);
          });
        } catch (e) {
          debugPrint('❌ Error processing outcome ${outcome['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _loadHbncItems: $e');
    } finally {
      setState(() => _isLoading = false);
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
          print(
            '✅ Found LMP date from beneficiaries_new: ${_formatDate(lmpDate)}',
          );
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
        print(
          '✅ Found LMP date from followup form: ${_formatDate(lmpFromFollowup)}',
        );
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
          (data['_rawRow'] is Map
              ? (data['_rawRow'] as Map)['unique_key']?.toString()
              : null);

      if (benId == null || benId.isEmpty) {
        print('⚠️ Missing beneficiary ID for followup form LMP lookup');
        print('   benId: $benId');
        print('   data keys: ${data.keys}');
        return null;
      }

      print('🔍 Looking for followup forms with benId: $benId');

      final db = await DatabaseProvider.instance.database;
      final formKey = FollowupFormDataTable
          .formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue];

      print('🔍 Querying with formKey: $formKey, benId: $benId');

      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ?',
        whereArgs: [formKey, benId],
        orderBy: 'created_date_time DESC',
      );

      print('📋 Found ${result.length} followup forms for beneficiary: $benId');

      if (result.isEmpty) {
        print('ℹ️ No eligible couple tracking due forms found for beneficiary: $benId');

        final allForms = await db.query(
          FollowupFormDataTable.table,
          where: 'beneficiary_ref_key = ?',
          whereArgs: [benId],
          orderBy: 'created_date_time DESC',
        );

        print('🔍 DEBUG: All forms for beneficiary $benId:');
        for (int i = 0; i < allForms.length; i++) {
          final form = allForms[i];
          print(
            '   Form ${i + 1}: forms_ref_key=${form['forms_ref_key']}, '
                'household_ref_key=${form['household_ref_key']}',
          );
        }

        return null;
      }

      // ✅ try block is now properly closed above
      for (int i = 0; i < result.length; i++) {
        final form = result[i];
        final formJsonStr = form['form_json']?.toString();
        final formHouseholdId = form['household_ref_key']?.toString();
        final formBeneficiaryId = form['beneficiary_ref_key']?.toString();

        print(
          '📄 Processing form ${i + 1}/${result.length}: '
              'household=$formHouseholdId, beneficiary=$formBeneficiaryId',
        );

        if (formJsonStr == null || formJsonStr.isEmpty) {
          print('⚠️ Empty form_json in form ${i + 1}, skipping');
          continue;
        }

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
          print('🔍 Parsing followup form JSON ${i + 1}: ${root.keys}');

          String? lmpStr;

          /// ✅ EXISTING CONDITION
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final val = trackingData['lmp_date']?.toString();
            if (val != null && val.isNotEmpty && val != 'null') {
              lmpStr = val;
              print(
                '✅ Found LMP in eligible_couple_tracking_due_from (form ${i + 1}): "$lmpStr"',
              );
            }
          }

          /// ✅ NEW CONDITION
          if ((lmpStr == null || lmpStr.isEmpty || lmpStr == 'null') &&
              root['form_data'] is Map) {
            final formData = root['form_data'] as Map<String, dynamic>;
            final val = formData['lmp_date']?.toString();
            if (val != null && val.isNotEmpty && val != '""' && val != 'null') {
              lmpStr = val;
              print('✅ Found LMP in form_data (form ${i + 1}): "$lmpStr"');
            }
          }

          if (lmpStr != null && lmpStr.isNotEmpty && lmpStr != 'null') {
            try {
              if (lmpStr.contains('T')) {
                final lmpDate = DateTime.parse(lmpStr);
                print('✅ Successfully parsed LMP date (form ${i + 1}): $lmpDate');
                return lmpDate;
              }

              final lmpDate = DateTime.parse(lmpStr);
              print('✅ Successfully parsed LMP date (form ${i + 1}): $lmpDate');
              return lmpDate;
            } catch (e) {
              print('⚠️ Error parsing LMP date "$lmpStr": $e');
            }
          }
        } catch (e) {
          print('⚠️ Error parsing followup form JSON (form ${i + 1}): $e');
        }
      }

      print('ℹ️ No LMP date found in any eligible couple tracking due forms');
      return null;
    } catch (e) {
      print('❌ Error loading LMP from followup form: $e');
      return null;
    }
  }


  String _getNextAncDueDate(DateTime? lmpDate, int visitCount) {
    if (lmpDate == null) return AppLocalizations.of(context)!.na;

    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final ancRanges = _calculateAncDateRanges(lmpDate);

    String? nextAncKey;

    if (visitCount == 0) {
      // First ANC is due
      nextAncKey = '1st_anc_end';
    } else if (visitCount == 1) {
      // Second ANC is due
      nextAncKey = '2nd_anc_end';
    } else if (visitCount == 2) {
      // Third ANC is due
      nextAncKey = '3rd_anc_end';
    } else if (visitCount == 3) {
      // Fourth ANC is due
      nextAncKey = '4th_anc_end';
    } else {
      nextAncKey = '4th_anc_end';
    }

    if (nextAncKey != null && ancRanges.containsKey(nextAncKey)) {
      final dueDate = ancRanges[nextAncKey];
      if (dueDate != null) {
        return _formatDate(dueDate);
      }
    }

    return AppLocalizations.of(context)!.na;
  }

  Future<Map<String, dynamic>> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getVisitCount');
        return {'count': 0, 'isHighRisk': false};
      }

      print(
        '🔍 Fetching visit count and high-risk status for beneficiary: $beneficiaryId',
      );
      final result = await LocalStorageDao.instance.getANCVisitCount(
        beneficiaryId,
      );
      print('✅ Visit details for $beneficiaryId: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return {'count': 0, 'isHighRisk': false};
    }
  }

  Future<int> _getVisitCountFromFollowupForm(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getVisitCountFromFollowupForm');
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final ancFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';

      if (ancFormKey.isEmpty) {
        print('⚠️ ANC form key is empty');
        return 0;
      }

      // Get the most recent ANC form for this beneficiary
      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ? ',
        whereArgs: [ancFormKey, beneficiaryId],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (result.isEmpty) {
        print('ℹ️ No ANC followup forms found for beneficiary: $beneficiaryId');
        return 0;
      }

      final formJsonStr = result.first['form_json']?.toString();
      if (formJsonStr == null || formJsonStr.isEmpty) {
        print('⚠️ No form_json found in followup form for beneficiary: $beneficiaryId');
        return 0;
      }

      try {
        final formJson = jsonDecode(formJsonStr) as Map<String, dynamic>;

        final ancForm = formJson['anc_form'] as Map<String, dynamic>?;
        if (ancForm != null) {
          final visitCount = ancForm['anc_visit'] as int?;
          if (visitCount != null) {
            print('✅ Found visit count $visitCount in anc_form for beneficiary: $beneficiaryId');
            return visitCount;
          }
        }

        // Try alternative structure (form_data)
        final formData = formJson['form_data'] as Map<String, dynamic>?;
        if (formData != null) {
          final visitCount = formData['anc_visit'] as int?;
          if (visitCount != null) {
            print('✅ Found visit count $visitCount in form_data for beneficiary: $beneficiaryId');
            return visitCount;
          }
        }

        // Try top level
        final visitCount = formJson['anc_visit'] as int?;
        if (visitCount != null) {
          print('✅ Found visit count $visitCount at top level for beneficiary: $beneficiaryId');
          return visitCount;
        }

        print('⚠️ No visit count found in followup form for beneficiary: $beneficiaryId');
        return 0;
      } catch (e) {
        print('❌ Error parsing followup form JSON for beneficiary $beneficiaryId: $e');
        return 0;
      }
    } catch (e) {
      print('❌ Error in _getVisitCountFromFollowupForm for $beneficiaryId: $e');
      return 0;
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
    var displayEndDate = ranges['4th_anc_start']!.add(const Duration(days: 15));
    ranges['4th_anc_end'] = displayEndDate;

    ranges['pmsma_start'] = ranges['1st_anc_end']!.add(const Duration(days: 1));
    ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(
      const Duration(days: 1),
    );

    return ranges;
  }




  Future<int> _getHbncVisitCountFromHBNCList(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getHbncVisitCountFromHBNCList');
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];

      // Get the latest visit record to extract visit number
      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? ',
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

      // Fallback 1: Check home_visit_day from pnc_infant_form
      if (latestVisitRows.isNotEmpty) {
        final result = latestVisitRows.first;
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          print('🔍 Full form JSON keys: ${formJson.keys.toList()}');

          // Check for both pnc_mother_form and pnc_infant_form structures
          List<String> formKeysToCheck = ['pnc_mother_form', 'pnc_infant_form'];

          for (final formKey in formKeysToCheck) {
            if (formJson.containsKey(formKey)) {
              final formData = formJson[formKey] as Map<String, dynamic>? ?? {};
              print('🔍 Found $formKey structure');
              print('🔍 $formKey keys: ${formData.keys.toList()}');

              final homeVisitDay = formData['home_visit_day']?.toString();
              print('📊 Extracted home_visit_day from $formKey: $homeVisitDay');
              print('📊 home_visit_day type: ${homeVisitDay.runtimeType}');

              if (homeVisitDay != null && homeVisitDay.isNotEmpty) {
                final number = int.tryParse(homeVisitDay);
                print('🔢 Parsed home_visit_day as integer: $number');
                if (number != null && number > 0) {
                  print('🔢 Found visit number from $formKey.home_visit_day: $number for beneficiary $beneficiaryId');
                  return number;
                } else {
                  print('⚠️ home_visit_day is null or <= 0: $number');
                }
              } else {
                print('⚠️ home_visit_day is null or empty in $formKey: $homeVisitDay');
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing pnc_infant_form: $e');
          print('🔍 Raw form_json: ${result['form_json']}');
        }
      } else {
        print('⚠️ No latest visit rows found for pnc_infant_form check');
      }

      // Fallback 2: Counting total records
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
      print('❌ Error in _getHbncVisitCountFromHBNCList for $beneficiaryId: $e');
      return 0;
    }
  }

  Future<String?> _getHbncNextVisitDateFromHBNCList(
      String beneficiaryId,
      String? deliveryDate,
      int visitCount,
      String registrationDate,
      ) async {
    try {
      print('🔍 Calculating next visit date for beneficiary: $beneficiaryId');
      print('📊 Visit count: $visitCount');
      print('📅 Registration date: $registrationDate');

      /// 🔹 CASE 1: No HBNC visits done yet
      /// → Show registration date
      if (visitCount == 0) {
        if (registrationDate.isNotEmpty) {
          final parsedRegDate = DateTime.tryParse(registrationDate);
          if (parsedRegDate != null) {
            final formatted = _formatDateFromString(parsedRegDate.toString());
            print('📅 Visit count 0 → Next HBNC = Registration Date: $formatted');
            return formatted;
          }
        }

        // Fallback safety
        print('⚠️ Invalid registration date, using today');
        return _formatDateFromString(DateTime.now().toString());
      }

      /// 🔹 CASE 2: Visit count >= 1
      final db = await DatabaseProvider.instance.database;

      final possibleFormKeys = [
        FollowupFormDataTable.formUniqueKeys[
        FollowupFormDataTable.pncMother],
        '4r7twnycml3ej1vg',
        '695fdc026276645a01e9c800',
      ];

      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND (forms_ref_key = ? OR forms_ref_key = ? OR forms_ref_key = ?)',
        whereArgs: [beneficiaryId, ...possibleFormKeys],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      DateTime baseDate;

      if (latestVisitRows.isNotEmpty) {
        final createdDateTime =
        latestVisitRows.first['created_date_time']?.toString();
        baseDate =
            DateTime.tryParse(createdDateTime ?? '') ?? DateTime.now();
        print('📅 Base date from last visit: $baseDate');
      } else {
        baseDate = DateTime.now();
        print('⚠️ No visit found, using today as base date');
      }

      /// Visit 1 → +2 days
      if (visitCount == 1) {
        final nextVisit = baseDate.add(const Duration(days: 2));
        return _formatDateFromString(nextVisit.toString());
      }

      /// Visit 2+ → use your existing rule
      final nextVisitDate =
      _calculateNextVisitDate(visitCount, baseDate);

      return nextVisitDate != null
          ? _formatDateFromString(nextVisitDate.toString())
          : null;
    } catch (e) {
      print('❌ Error calculating next visit date: $e');
      return null;
    }
  }

  // Helper method to get visit number from latest HBNC record
  Future<int?> _getHbncVisitNumber(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        return null;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
      FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) {
        return null;
      }

      final results = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      try {
        final latestRecord = results.first;
        final formJson = jsonDecode(
          latestRecord['form_json'] as String? ?? '{}',
        );

        // Check for hbyc_form structure first (based on sample data)
        if (formJson.containsKey('hbyc_form')) {
          final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};
          if (hbycForm.containsKey('visitDetails')) {
            final visitDetails =
                hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
            final visitNumber = visitDetails['visitNumber']?.toString();
            if (visitNumber != null) {
              final number = int.tryParse(visitNumber);
              if (number != null) {
                return number;
              }
            }
          }
        }

        // Fallback to form_data structure
        final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

        if (formData.containsKey('visitDetails')) {
          final visitDetails =
              formData['visitDetails'] as Map<String, dynamic>? ?? {};
          final visitNumber =
              visitDetails['visitNumber']?.toString() ??
                  visitDetails['visit_number']?.toString();
          if (visitNumber != null) {
            final number = int.tryParse(visitNumber);
            if (number != null) {
              return number;
            }
          }
        }
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  // Helper method to parse date strings in different formats
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Try parsing in different formats
      // ISO format: yyyy-MM-dd or yyyy-MM-ddTHH:mm:ss
      if (dateStr.contains('-')) {
        return DateTime.tryParse(dateStr);
      }

      // Format: dd-MM-yyyy
      if (RegExp(r'\d{2}-\d{2}-\d{4}').hasMatch(dateStr)) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getHbncLastVisitDateFromHBNCList(String beneficiaryId) async {
    try {
      print('🔍 Fetching last visit date for beneficiary: $beneficiaryId');
      final db = await DatabaseProvider.instance.database;

      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      print('🔑 Using form reference key: $hbncVisitKey');

      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? ',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      print('📋 Found ${results.length} HBNC visit records');

      if (results.isNotEmpty) {
        final result = results.first;
        print('📋 Found HBNC visit record with ID: ${result['id']}');

        // Directly use created_date_time as the previous HBNC date
        final createdDate = result['created_date_time'];
        if (createdDate != null && createdDate.toString().isNotEmpty) {
          print('⏰ Using created_date_time as previous HBNC date: $createdDate');
          final formattedDate = _formatDateFromString(createdDate.toString());
          print('✅ Previous HBNC date: $formattedDate');
          return formattedDate;
        } else {
          print('⚠️ created_date_time is null or empty');
          return null;
        }
      } else {
        print('ℹ️ No HBNC visit records found for beneficiary');
      }
    } catch (e) {
      print('❌ Error in _getHbncLastVisitDateFromHBNCList: $e');
    }
    return null;
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

  Future<bool> _hasCompletedHbncForm(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final hbncFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .pncMother] ??
              '';

      if (hbncFormKey.isEmpty) return false;

      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String whereClause =
          'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND created_date_time LIKE ?';
      List<dynamic> whereArgs = [hbncFormKey, beneficiaryRefKey, '$todayStr%'];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final result = await db.query(
        FollowupFormDataTable.table,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint(
        'Error checking completed HBNC form for $beneficiaryRefKey: $e',
      );
      return false;
    }
  }
  Future<bool> _shouldRemoveHbncRecordDueToCountChange(
      String beneficiaryId,
      String? deliveryDate,
      int currentVisitCount,
      ) async {
    try {
      if (deliveryDate == null || deliveryDate.isEmpty) return false;

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
      FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) return false;

      // Parse delivery date
      final deliveryDt = DateTime.tryParse(deliveryDate);
      if (deliveryDt == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final schedule = <int>[1, 3, 7, 14, 21, 28, 42];
      final futureVisitDates = <DateTime>[];

      for (final day in schedule) {
        final visitDate = deliveryDt.add(Duration(days: day));
        if (visitDate.isAfter(today) || visitDate.isAtSameMomentAs(today)) {
          futureVisitDates.add(visitDate);
        }
      }

      if (futureVisitDates.isEmpty) return false;

      final existingVisits = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time ASC',
      );

      for (final futureVisitDate in futureVisitDates) {
        int visitsByFutureDate = 0;

        for (final visit in existingVisits) {
          final visitCreatedDate = DateTime.tryParse(
            visit['created_date_time']?.toString() ?? '',
          );
          if (visitCreatedDate != null) {
            final visitDateOnly = DateTime(
              visitCreatedDate.year,
              visitCreatedDate.month,
              visitCreatedDate.day,
            );
            if (visitDateOnly.isBefore(futureVisitDate) ||
                visitDateOnly.isAtSameMomentAs(futureVisitDate)) {
              visitsByFutureDate++;
            }
          }
        }

        // Calculate expected visit count based on schedule
        int expectedCount = 0;
        for (int i = 0; i < schedule.length; i++) {
          final scheduledDate = deliveryDt.add(Duration(days: schedule[i]));
          if (scheduledDate.isBefore(futureVisitDate) ||
              scheduledDate.isAtSameMomentAs(futureVisitDate)) {
            expectedCount = i + 1;
          } else {
            break;
          }
        }

        // If counts don't match, the record should be removed
        if (visitsByFutureDate != expectedCount) {
          debugPrint(
            '📊 Count mismatch for $beneficiaryId by ${_formatHbncDate(futureVisitDate.toIso8601String())}: expected=$expectedCount, actual=$visitsByFutureDate',
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking HBNC count change: $e');
      return false;
    }
  }
  String _formatAgeWithSuffix(int age) {
    if (age <= 0) return '0 Y';

    final now = DateTime.now();
    // We need to calculate more precise age, so let's use the same logic as _formatAgeGender
    // But since we only have years, we'll just show years with Y suffix
    return '$age Y';
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

  String _formatHbncDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadRoutineImmunizationItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      final rows = await db.rawQuery(
        '''
      SELECT *
      FROM beneficiaries_new
      WHERE is_deleted = 0
        AND is_adult = 0
        AND is_migrated = 0
        AND current_user_key = ?
      ORDER BY created_date_time DESC
      ''',
        [ashaUniqueKey],
      );

      final List<Map<String, dynamic>> items = [];
      final Set<String> seenBeneficiaries = {};

      for (final row in rows) {
        try {
          final beneficiaryRefKey = row['unique_key']?.toString() ?? '';
          if (beneficiaryRefKey.isEmpty) continue;
          if (!seenBeneficiaries.add(beneficiaryRefKey)) continue;

          final Map<String, dynamic>? info =
          row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
          as Map<String, dynamic>?
              : row['beneficiary_info'] as Map<String, dynamic>?;


          if (info == null) continue;

          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final relation =
              info['relation']?.toString().toLowerCase() ?? '';

          if (!(memberType == 'child' ||
              relation == 'child' ||
              relation == 'daughter')) {
            continue;
          }


          final hasTrackingDue =
          await _hasTrackingDueStatus(beneficiaryRefKey);
          if (!hasTrackingDue) continue;


          final trackingDueDate =
          await _getLatestTrackingDueDate(beneficiaryRefKey);

          if (trackingDueDate != null) {
            final hasFollowupIn6Months =
            await _hasFollowupWithinSixMonths(
              beneficiaryKey: beneficiaryRefKey,
              trackingDueDate: trackingDueDate,
            );

            if (hasFollowupIn6Months) {
              print('❌ Excluding $beneficiaryRefKey → RI done within 6 months');
              continue;
            }
          }


          // 🔹 Extract display data
          final name =
              info['name'] ??
                  info['memberName'] ??
                  info['member_name'] ??
                  '';

          final mobile =
              info['mobileNo'] ??
                  info['mobile'] ??
                  info['mobile_number'] ??
                  '-';

          final dob =
              info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];

          final genderRaw =
              info['gender']?.toString().toLowerCase() ?? '';

          final gender = genderRaw == 'male' || genderRaw == 'm'
              ? 'Male'
              : genderRaw == 'female' || genderRaw == 'f'
              ? 'Female'
              : 'Other';

          final age = _formatAgeOnly(dob);

          final hhId = row['household_ref_key']?.toString() ?? '';

          // Get last visit date from child_care_activities for infant_pnc or tracking_due states
          final lastVisitDate = await _getLatestTrackingDueDate(beneficiaryRefKey);
          final formattedLastVisitDate = lastVisitDate != null
              ? _formatDateOnly(lastVisitDate.toIso8601String())
              : '-';

          items.add({
            'id': _last11(beneficiaryRefKey),
            'household_ref_key': hhId,
            'hhId': hhId,
            'BeneficiaryID': beneficiaryRefKey,
            'name': name,
            'age': age,
            'gender': gender,
            'mobile': mobile,
            'badge': 'RI',
            'last Visit date': formattedLastVisitDate,
          });
        } catch (e) {
          print('⚠️ Beneficiary error: $e');
        }
      }

      if (mounted) {
        setState(() => _riItems = items);
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      print('❌ RI load error: $e');
    }
  }


  Future<bool> _hasTrackingDueStatus(String beneficiaryKey) async {
    final db = await DatabaseProvider.instance.database;

    final result = await db.rawQuery(
      '''
    SELECT 1
    FROM child_care_activities
    WHERE beneficiary_ref_key = ?
      AND child_care_state = 'tracking_due'
      AND is_deleted = 0
    LIMIT 1
    ''',
      [beneficiaryKey],
    );

    return result.isNotEmpty;
  }

  Future<bool> _hasFollowupWithinSixMonths({
    required String beneficiaryKey,
    required DateTime trackingDueDate,
  }) async {
    final db = await DatabaseProvider.instance.database;

    final sixMonthEnd = DateTime(
      trackingDueDate.year,
      trackingDueDate.month + 6,
      trackingDueDate.day,
    );

    print('🟢 ENTERED _hasFollowupWithinSixMonths for $beneficiaryKey');
    print('📅 Window: $trackingDueDate → $sixMonthEnd');

    final result = await db.rawQuery(
      '''
    SELECT 1
    FROM followup_form_data
    WHERE forms_ref_key = ?
      AND beneficiary_ref_key = ?
      AND is_deleted = 0
      AND datetime(created_date_time)
          BETWEEN datetime(?) AND datetime(?)
    LIMIT 1
    ''',
      [
        FollowupFormDataTable
            .formUniqueKeys[FollowupFormDataTable.childTrackingDue],
        beneficiaryKey,
        trackingDueDate.toIso8601String(),
        sixMonthEnd.toIso8601String(),
      ],
    );

    return result.isNotEmpty;
  }

  Future<DateTime?> _getLatestTrackingDueDate(
      String beneficiaryKey,
      ) async {
    final db = await DatabaseProvider.instance.database;

    final result = await db.rawQuery(
      '''
    WITH ranked AS (
      SELECT
          cca.created_date_time,
          ROW_NUMBER() OVER (
              PARTITION BY cca.beneficiary_ref_key
              ORDER BY datetime(cca.created_date_time) DESC, cca.rowid DESC
          ) AS rn
      FROM child_care_activities cca
      WHERE cca.is_deleted = 0
        AND cca.beneficiary_ref_key = ?
        AND cca.child_care_state IN ('tracking_due', 'infant_pnc')
    )
    SELECT created_date_time
    FROM ranked
    WHERE rn = 1
    ''',
      [beneficiaryKey],
    );

    if (result.isEmpty) {
      print('❌ No tracking_due for $beneficiaryKey');
      return null;
    }

    print('✅ tracking_due found for $beneficiaryKey → ${result.first['created_date_time']}');

    return DateTime.parse(result.first['created_date_time'] as String);
  }

  String _formatAgeOnly(dynamic dobRaw) {
    String age = 'Not Available';

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
            final daysInLastMonth = DateTime(
              lastMonthYear,
              lastMonth + 1,
              0,
            ).day;
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

    return age;
  }

  DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
    final days = noOfWeeks * 7;
    return startDate.add(Duration(days: days));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
  Future<String> _getLastVisitDate({
    required String beneficiaryId,
    required String formRefKey,
  }) async {
    try {
      final db = await DatabaseProvider.instance.database;

      final result = await db.rawQuery(
        '''
      SELECT MAX(created_date_time) AS last_visit
      FROM ${FollowupFormDataTable.table}
      WHERE beneficiary_ref_key = ?
        AND forms_ref_key = ?
        AND (is_deleted IS NULL OR is_deleted = 0)
      ''',
        [beneficiaryId, formRefKey],
      );

      final String? rawDate =
      result.first['last_visit']?.toString();

      if (rawDate == null || rawDate.isEmpty) {
        return '-';
      }

      return _formatDateOnly(rawDate);
    } catch (e) {
      debugPrint('Last visit error: $e');
      return '-';
    }
  }

  int _calculateAgeFromDob(String dob) {
    try {
      final DateTime birthDate = DateTime.parse(
        dob.contains('T') ? dob.split('T')[0] : dob,
      );

      final DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month &&
              today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  String _formatAgeGenderFromDob(dynamic dobRaw, dynamic genderRaw) {
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
            final daysInLastMonth = DateTime(
              lastMonthYear,
              lastMonth + 1,
              0,
            ).day;
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



  Future<void> _saveTodayWorkCountsToStorage() async {
    try {
      if (!mounted) return;

      final familyCount = _familySurveyItems.length;
      final familyCompletedCount = _familySurveyCompletedItems.length;
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = _riItems.length;

      // Calculate total to-do count (excluding completed visits)
      final totalToDoCount =
          familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

      // Calculate total completed count (including family survey completed)
      final totalCompletedCount = _completedVisitsCount + familyCompletedCount;

      // Ensure we don't have negative counts
      final toDoCount = totalToDoCount >= 0 ? totalToDoCount : 0;
      final completedCount = totalCompletedCount >= 0
          ? totalCompletedCount
          : 0;

      // Save to secure storage
      print('=== TodaysProgramm Saving to Storage ===');
      print('Family To-Do Count: $familyCount');
      print('Family Completed Count: $familyCompletedCount');
      print('To-Do Count: $toDoCount');
      print('Completed Count: $completedCount');
      print('====================================');

      await SecureStorageService.saveTodayWorkCounts(
        toDo: toDoCount,
        completed: completedCount,
      );
      // Update the UI with the latest counts
      if (mounted) {
        setState(() {
          // Ensure the UI reflects the same values we saved
          _completedVisitsCount = completedCount;
          _toDoVisitsCount = toDoCount +completedCount;
          _pendingCountVisitsCount = toDoCount;
        });
        print('=== TodayWork After setState ===');
        print(
          'State - To-Do: $_toDoVisitsCount, Completed: $_completedVisitsCount, Pending: $_pendingCountVisitsCount',
        );
        print('==================================');
      }

      // Update the Bloc DIRECTLY (This stops the flickering)
      _bloc.add(TwUpdateCounts(
          toDo: toDoCount,
          completed: completedCount
      ));
    } catch (e) {
      // Log error if needed
      debugPrint('Error saving today\'s work counts: $e');
    }
  }


  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }
  Future<void> _refreshData() async {
    // Clear the UI momentarily to show loading
    _bloc.add(const TwLoad(toDo: 0, completed: 0));
    // Start the load process
    await _loadData();
  }

  late TodaysWorkBloc _bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BlocProvider(
        create: (_) {
          _bloc = TodaysWorkBloc();
          // Don't load counts here, let _loadData handle it
          return _bloc;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppHeader(
            screenTitle: l10n?.todayWorkTitle ?? "Today's Work Progress",
            showBack: true,
          ),
          body: SafeArea(
            child: BlocBuilder<TodaysWorkBloc, TodaysWorkState>(
              builder: (context, state) {
                int completed = state.completed;
                int pending = state.pending;

                // Adjust for hidden slices
                if (_selectedSliceFromLegend == 0) completed = 0;
                if (_selectedSliceFromLegend == 1) pending = 0;
                if (_selectedSliceFromLegend == 2) completed = pending = 0;

                final total = completed + pending;
                final progress = state.completed + state.pending == 0
                    ? 0
                    : (state.completed / (state.completed + state.pending)) *
                    100;
                final percent = progress.toStringAsFixed(2);

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv("${l10n!.toDoVisits}:", "${_toDoVisitsCount.toString()}"),
                            _kv(
                              '${l10n!.completedVisits} :',
                              _completedVisitsCount.toString(),
                            ),
                            _kv(
                              '${l10n.pendingVisits}:',
                              _pendingCountVisitsCount.toString(),
                            ),
                            _kv('${l10n.progress} :', '$percent%'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legend(
                                  color: Colors.green,
                                  label: l10n.completed,
                                  sliceIndex: 0,
                                ),
                                const SizedBox(width: 16),
                                _legend(
                                  color: AppColors.primary,
                                  label: l10n.pending,
                                  sliceIndex: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTapDown: (details) {
                                          int? tappedSlice = detectSlice(
                                            details.localPosition,
                                            completed,
                                            pending,
                                          );
                                          setState(() {
                                            if (_selectedSlice == tappedSlice) {
                                              _selectedSlice = null;
                                            } else {
                                              _selectedSlice = tappedSlice;
                                            }
                                          });
                                        },
                                        child: CustomPaint(
                                          size: const Size(220, 220),
                                          painter: _PiePainter(
                                            completed: completed,
                                            pending: pending,
                                            legendSelected:
                                            _selectedSliceFromLegend,
                                          ),
                                        ),
                                      ),
                                      if (_selectedSlice != null)
                                        _buildTooltip(
                                          completed,
                                          pending,
                                          _selectedSlice!,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  int? detectSlice(Offset local, int completed, int pending) {
    const size = Size(220, 220);
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final radius = math.sqrt(dx * dx + dy * dy);
    final maxRadius = size.width / 2;
    if (radius > maxRadius) return null;
    final total = completed + pending;
    if (total == 0) return null;
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    const start = -math.pi / 2;
    double rel = (angle - start) % (2 * math.pi);
    if (rel < 0) rel += 2 * math.pi;
    final sweepCompleted = (completed / total) * (2 * math.pi);
    if (completed > 0 && rel <= sweepCompleted) return 0;
    if (pending > 0) return 1;
    return null;
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(fontSize: 15.sp, color: AppColors.primary,fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            v,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    // Determine if this slice is striked
    bool isStriked = false;
    if (_selectedSliceFromLegend != null) {
      if (_selectedSliceFromLegend == 2) {
        isStriked = true; // both are striked
      } else if (_selectedSliceFromLegend == sliceIndex) {
        isStriked = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle this slice only
          if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike this
          } else if (_selectedSliceFromLegend == 2) {
            // Both are striked, toggle only this slice
            // Unstriking this slice => only the other remains
            _selectedSliceFromLegend = sliceIndex == 0 ? 1 : 0;
          } else {
            // One is already striked, toggle the other => both striked
            _selectedSliceFromLegend = 2;
          }

          // Reset pie tooltip
          _selectedSlice = null;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration: isStriked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    final bool isStriked =
    (_selectedSliceFromLegend == sliceIndex || _selectedSliceFromLegend == 2);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike
          } else if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend != sliceIndex && _selectedSliceFromLegend != 2) {
            _selectedSliceFromLegend = 2; // both strike
          } else if (_selectedSliceFromLegend == 2) {
            _selectedSliceFromLegend = sliceIndex; // only this remains
          }

          _selectedSlice = null; // reset tooltip
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration:
              isStriked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _balloonTooltip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(int completed, int pending, int sliceIndex) {
    final l = AppLocalizations.of(context);
    final total = completed + pending;
    if (total == 0) return const SizedBox.shrink();

    const size = 220.0;
    const center = size / 2;

    double midAngle;
    int count;
    String label;
    Color color;

    const start = -math.pi / 2;
    final full = 2 * math.pi;
    final sweepCompleted = completed / total * full;
    final remainingSweep = full - sweepCompleted;

    if (sliceIndex == 0) {
      label = l!.completed;
      count = completed;
      color = Colors.green;
      midAngle = start + sweepCompleted / 2;
    } else {
      label = l!.pending;
      count = pending;
      color = AppColors.primary;
      midAngle = start + sweepCompleted + remainingSweep / 2;
    }

    const radius = 90.0;
    final dx = center + math.cos(midAngle) * radius;
    final dy = center + math.sin(midAngle) * radius;

    return Positioned(
      left: dx - 40,
      top: dy - 30,
      child: _balloonTooltip(label: label, count: count, color: color),
    );
  }
}

class _PiePainter extends CustomPainter {
  final int completed;
  final int pending;
  final int? legendSelected;

  _PiePainter({
    required this.completed,
    required this.pending,
    required this.legendSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    int comp = completed;
    int pend = pending;

    // Handle legend hiding
    if (legendSelected == 0) comp = 0;
    if (legendSelected == 1) pend = 0;
    if (legendSelected == 2) comp = pend = 0;

    final total = comp + pend;
    if (total == 0) return;

    final paintCompleted = Paint()..color = Colors.green;
    final paintPending = Paint()..color = AppColors.primary;

    if (comp > 0) {
      final sweep = comp / total * full;
      canvas.drawArc(rect, start, sweep, true, paintCompleted);
    }
    if (pend > 0) {
      final sweep = pend / total * full;
      final startAngle = comp > 0 ? (comp / total * full) + start : start;
      canvas.drawArc(rect, startAngle, sweep, true, paintPending);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.completed != completed ||
          old.pending != pending ||
          old.legendSelected != legendSelected;
}
