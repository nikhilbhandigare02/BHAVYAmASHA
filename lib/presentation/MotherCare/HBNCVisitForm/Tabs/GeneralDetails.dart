import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'dart:convert';

class GeneralDetailsTab extends StatelessWidget {
  final String beneficiaryId;
  
  const GeneralDetailsTab({super.key, required this.beneficiaryId});

  Future<int> _getLastCompletedVisitDayFromDb() async {
    try {
      if (beneficiaryId.isEmpty) return 0;

      final db = await DatabaseProvider.instance.database;
      final formsRefKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother] ??
              '';
      if (formsRefKey.isEmpty) return 0;

      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
            'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [formsRefKey, beneficiaryId],
        orderBy: 'datetime(created_date_time) DESC',
        limit: 1,
      );

      if (rows.isEmpty) return 0;

      final rawJson = rows.first['form_json'] as String?;
      if (rawJson == null || rawJson.isEmpty) return 0;

      int? visitNumber;
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          // Normalized structure: form_data.visitDetails.visitNumber
          if (decoded['form_data'] is Map &&
              (decoded['form_data']['visitDetails'] is Map)) {
            final vd = decoded['form_data']['visitDetails'] as Map;
            visitNumber = int.tryParse(vd['visitNumber']?.toString() ?? '');
          }

          // Local HBNC save structure: hbyc_form.visitDetails.visitNumber
          if (visitNumber == null && decoded['hbyc_form'] is Map) {
            final h = decoded['hbyc_form'] as Map<String, dynamic>;
            if (h['visitDetails'] is Map) {
              final vd = h['visitDetails'] as Map;
              visitNumber = int.tryParse(vd['visitNumber']?.toString() ?? '');
            }
          }

          // PNC Mother Form structure: pnc_mother_form.home_visit_day
          if (visitNumber == null && decoded['pnc_mother_form'] is Map) {
            final pnc = decoded['pnc_mother_form'] as Map<String, dynamic>;
            visitNumber = int.tryParse(pnc['home_visit_day']?.toString() ?? '');
          }

          if (visitNumber == null && decoded['visitDetails'] is Map) {
            final vd = decoded['visitDetails'] as Map;
            visitNumber = int.tryParse(vd['visitNumber']?.toString() ?? '');
          }
        }
      } catch (e) {
        print('Error parsing last HBNC visitNumber: $e');
      }

      return visitNumber ?? 0;
    } catch (e) {
      print('Error loading last HBNC visitNumber from DB: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>?> _loadHbncVisitData() async {
    try {
      print('🔍 Loading HBNC visit data for beneficiary: $beneficiaryId');
      final db = await DatabaseProvider.instance.database;
      final pncMotherKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother] ?? '';
      print('🔑 PNC Mother Key: $pncMotherKey');

      // Debug: Query to find any records with this form key
      print('🔍 Querying for any records with form key: $pncMotherKey');
      final allPncMotherRecords = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ?',
        whereArgs: [pncMotherKey],
      );

      print('📊 Found ${allPncMotherRecords.length} records with PNC mother form key');

      // Check if we have any records with this form key
      if (allPncMotherRecords.isNotEmpty) {
        print('📄 Sample record found: ${allPncMotherRecords.first}');

        // Try to find a record with both form key and beneficiary ID
        print('🔍 Looking for record with both form key and beneficiary ID');
        final results = await db.query(
          FollowupFormDataTable.table,
          where: 'forms_ref_key = ? AND beneficiary_ref_key = ?',
          whereArgs: [pncMotherKey, beneficiaryId],
          orderBy: 'created_date_time DESC',
          limit: 1,
        );

        if (results.isNotEmpty) {
          print('✅ Found matching record with both form key and beneficiary ID');
          try {
            final formJson = results.first['form_json'] as String?;
            if (formJson != null) {
              final formData = jsonDecode(formJson) as Map<String, dynamic>;
              print('📋 Form data keys: ${formData.keys.toList()}');

              Map<String, dynamic>? visitData;

              // Check if form_data exists and is not null
              if (formData['form_data'] != null) {
                print('✅ Successfully extracted form_data');
                visitData = formData['form_data'] as Map<String, dynamic>?;
              }
              // Check if hbyc_form exists
              else if (formData['hbyc_form'] != null) {
                print('✅ Successfully extracted hbyc_form');
                visitData = formData['hbyc_form'] as Map<String, dynamic>?;
              }
              // Check if pnc_mother_form exists and convert to visit details structure
              else if (formData['pnc_mother_form'] != null) {
                print('✅ Successfully extracted pnc_mother_form');
                final pncForm = formData['pnc_mother_form'] as Map<String, dynamic>;
                
                // Convert pnc_mother_form to visit details structure
                visitData = {
                  'visitDetails': {
                    'visitNumber': pncForm['home_visit_day'],
                    'visitDate': pncForm['home_visit_date'],
                  },
                  'motherDetails': {
                    'motherStatus': pncForm['mother_status'],
                    'postDeliveryProblems': pncForm['does_mother_have_problem_post_delivery'],
                    'excessiveBleeding': pncForm['is_bleeding'],
                    'unconsciousFits': pncForm['is_unconsiousness'],
                    'breastfeedingProblems': pncForm['breastfeeding_problem'],
                    'breastfeedingProblemDescription': pncForm['problem_in_breastfeeding'],
                    'breastfeedingHelpGiven': pncForm['action_taken_to_overcome_from_breasting_problem'],
                    'padsPerDay': pncForm['number_of_pads_changed'],
                    'temperature': pncForm['measure_and_check_temperature'],
                    'paracetamolGiven': pncForm['paracetomol_tab_given'],
                    'foulDischargeHighFever': pncForm['watery_discharge_with_foul'],
                    'abnormalSpeechOrSeizure': pncForm['is_seizures'],
                    'counselingAdvice': pncForm['is_counseled'],
                    'nippleCracksPainOrEngorged': pncForm['does_mother_have_cracked_nipple'],
                    'referHospital': pncForm['is_refer_to_hospital'],
                    'referTo': pncForm['refered_to'],
                  }
                };
              }

              if (visitData != null) {
                return visitData;
              } else {
                print('⚠️ No valid visit data structure found');
                print('Full form data: $formData');
              }
            }
          } catch (e) {
            print('❌ Error parsing form data: $e');
            print('Raw form data: ${results.first['form_json']}');
          }
        } else {
          print('ℹ️ No records found with both form key and beneficiary ID, trying to find any record with this form key');

          // If no record with both, try to get the most recent record with just the form key
          final recentRecord = await db.query(
            FollowupFormDataTable.table,
            where: 'forms_ref_key = ?',
            whereArgs: [pncMotherKey],
            orderBy: 'created_date_time DESC',
            limit: 1,
          );

          if (recentRecord.isNotEmpty) {
            print('📋 Found recent record with form key: ${recentRecord.first}');
            try {
              final formJson = recentRecord.first['form_json'] as String?;
              if (formJson != null) {
                final formData = jsonDecode(formJson) as Map<String, dynamic>;
                print('📋 Form data keys: ${formData.keys.toList()}');

                Map<String, dynamic>? visitData;

                if (formData['form_data'] != null) {
                  print('✅ Successfully extracted form_data from most recent record');
                  visitData = formData['form_data'] as Map<String, dynamic>?;
                }
                // Check if hbyc_form exists
                else if (formData['hbyc_form'] != null) {
                  print('✅ Successfully extracted hbyc_form from most recent record');
                  visitData = formData['hbyc_form'] as Map<String, dynamic>?;
                }
                // Check if pnc_mother_form exists and convert to visit details structure
                else if (formData['pnc_mother_form'] != null) {
                  print('✅ Successfully extracted pnc_mother_form from most recent record');
                  final pncForm = formData['pnc_mother_form'] as Map<String, dynamic>;
                  
                  // Convert pnc_mother_form to visit details structure
                  visitData = {
                    'visitDetails': {
                      'visitNumber': pncForm['home_visit_day'],
                      'visitDate': pncForm['home_visit_date'],
                    },
                    'motherDetails': {
                      'motherStatus': pncForm['mother_status'],
                      'postDeliveryProblems': pncForm['does_mother_have_problem_post_delivery'],
                      'excessiveBleeding': pncForm['is_bleeding'],
                      'unconsciousFits': pncForm['is_unconsiousness'],
                      'breastfeedingProblems': pncForm['breastfeeding_problem'],
                      'breastfeedingProblemDescription': pncForm['problem_in_breastfeeding'],
                      'breastfeedingHelpGiven': pncForm['action_taken_to_overcome_from_breasting_problem'],
                      'padsPerDay': pncForm['number_of_pads_changed'],
                      'temperature': pncForm['measure_and_check_temperature'],
                      'paracetamolGiven': pncForm['paracetomol_tab_given'],
                      'foulDischargeHighFever': pncForm['watery_discharge_with_foul'],
                      'abnormalSpeechOrSeizure': pncForm['is_seizures'],
                      'counselingAdvice': pncForm['is_counseled'],
                      'nippleCracksPainOrEngorged': pncForm['does_mother_have_cracked_nipple'],
                      'referHospital': pncForm['is_refer_to_hospital'],
                      'referTo': pncForm['refered_to'],
                    }
                  };
                }

                if (visitData != null) {
                  return visitData;
                }
              }
            } catch (e) {
              print('❌ Error parsing recent form data: $e');
            }
          }
        }
      } else {
        print('ℹ️ No records found with form key: $pncMotherKey');
        print('ℹ️ All available form keys in database:');
        final allRecords = await db.query(
          FollowupFormDataTable.table,
          columns: ['DISTINCT forms_ref_key'],
        );
        print('Available form keys: ${allRecords.map((r) => r['forms_ref_key']).toList()}');
      }
    } catch (e) {
      print('❌ Error loading HBNC visit data: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    print('ℹ️ No HBNC visit data found');
    return null;
  }
  @override
  Widget build(BuildContext context) {
    // Load HBNC visit data when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🔄 Loading HBNC visit data...');
      final data = await _loadHbncVisitData();
      print('📦 Loaded data: $data');
      if (data != null && context.mounted) {
        print('🎯 Updating UI with loaded data');
        final bloc = context.read<HbncVisitBloc>();

        if (data['visitDetails'] != null) {
          final visitDetails = Map<String, dynamic>.from(data['visitDetails'] as Map);
          // Update each field individually, skipping visitDate
          visitDetails.forEach((field, value) {
            if (field == 'visitDate') {
              return;
            }
            if (value != null) {
              bloc.add(VisitDetailsChanged(field: field, value: value));
            }
          });
        }
      }
    });
    return BlocBuilder<HbncVisitBloc, HbncVisitState>(
      builder: (context, state) {
        final t = AppLocalizations.of(context)!;
        final visitMap = state.visitDetails;
        // Handle visit number selection
        final dynamic dayRaw = visitMap['visitNumber'];
        final int? selectedDay = dayRaw != null 
            ? (dayRaw is int ? dayRaw : int.tryParse(dayRaw.toString())) 
            : null;
            
        // Set default visit date to current date if not already set
        final DateTime currentDate = DateTime.now();

        DateTime? _parseDate(dynamic date) {
          if (date == null) return null;
          if (date is DateTime) return date;
          if (date is String) {
            try {
              return DateTime.tryParse(date);
            } catch (e) {
              return null;
            }
          }
          return null;
        }

        final DateTime visitDate = _parseDate(visitMap['visitDate']) ?? currentDate;

         if (visitMap['visitDate'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HbncVisitBloc>().add(
              VisitDetailsChanged(
                field: 'visitDate',
                value: currentDate.toIso8601String(),
              ),
            );
          });
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<int>(
                    future: _getLastCompletedVisitDayFromDb(),
                    builder: (context, snapshot) {
                      final lastCompleted = snapshot.data ?? 0; // last completed visit day
                      const schedule = [1, 3, 7, 14, 21, 28, 42];
                      final int displayDay;

                      // Always calculate the next visit day based on database
                      int nextDay;
                      if (lastCompleted <= 0) {
                        // If no previous visit, start with day 1
                        nextDay = schedule.first;
                      } else if (lastCompleted >= 42) {
                        // If last visit was 42, set to 0 (no more visits)
                        nextDay = 0;
                      } else {
                        // Find the next visit day in the schedule
                        final idx = schedule.indexOf(lastCompleted);
                        if (idx >= 0 && idx < schedule.length - 1) {
                          nextDay = schedule[idx + 1];
                        } else {
                          // If not found in schedule, default to first
                          nextDay = schedule.first;
                        }
                      }

                      displayDay = nextDay;
                      
                      // Only update the bloc if the current state doesn't have a valid visit number
                      if (selectedDay == null || selectedDay <= 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (displayDay > 0) {
                            context.read<HbncVisitBloc>().add(
                              VisitDetailsChanged(field: 'visitNumber', value: displayDay, beneficiaryId: beneficiaryId),
                            );
                          }
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (displayDay == 0)
                            Text(
                              'All visits completed (Day 42)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            )
                          else
                            ApiDropdown<int>(
                              labelText: t.homeVisitDayLabel,
                              items: [1, 3, 7, 14, 21, 28, 42],
                              getLabel: (v) => v.toString(),
                              value: displayDay,
                              onChanged: (val) {
                                if (val != null) {
                                  context.read<HbncVisitBloc>().add(
                                    VisitDetailsChanged(field: 'visitNumber', value: val, beneficiaryId: beneficiaryId),
                                  );
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  const Divider(),
                  CustomDatePicker(
                    labelText: t.dateOfHomeVisitLabel,
                    hintText: t.dateOfHomeVisitLabel,
                    initialDate: visitDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) {
                      context.read<HbncVisitBloc>().add(
                            VisitDetailsChanged(field: 'visitDate', value: date, beneficiaryId: beneficiaryId),
                          );
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

