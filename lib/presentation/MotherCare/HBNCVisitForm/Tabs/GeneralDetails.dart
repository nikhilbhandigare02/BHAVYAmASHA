import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'dart:convert';

class GeneralDetailsTab extends StatelessWidget {
  final String beneficiaryId;
  
  const GeneralDetailsTab({super.key, required this.beneficiaryId});

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

              // Check if form_data exists and is not null
              if (formData['form_data'] != null) {
                print('✅ Successfully extracted form_data');
                return formData['form_data'] as Map<String, dynamic>;
              } else {
                print('⚠️ form_data is null in the form data');
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

                if (formData['form_data'] != null) {
                  print('✅ Successfully extracted form_data from most recent record');
                  return formData['form_data'] as Map<String, dynamic>?;
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
        // Update mother details if they exist
        if (data['motherDetails'] != null) {
          final motherDetails = Map<String, dynamic>.from(data['motherDetails'] as Map);
          // Update each field individually
          motherDetails.forEach((field, value) {
            if (value != null) {
              bloc.add(MotherDetailsChanged(field: field, value: value));
            }
          });
        }
        // Update visit details if they exist
        if (data['visitDetails'] != null) {
          final visitDetails = Map<String, dynamic>.from(data['visitDetails'] as Map);
          // Update each field individually
          visitDetails.forEach((field, value) {
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
                    future: SecureStorageService.getVisitCount(beneficiaryId),
                    builder: (context, snapshot) {
                      final lastCompleted = snapshot.data ?? 0; // last completed visit day
                      const schedule = [1, 3, 7, 14, 21, 28, 42];
                      final int displayDay;

                      if (selectedDay != null && selectedDay > 0) {
                        displayDay = selectedDay;
                      } else {
                        int nextDay;
                        if (lastCompleted <= 0) {
                          nextDay = schedule.first;
                        } else {
                          final idx = schedule.indexOf(lastCompleted);
                          if (idx >= 0 && idx < schedule.length - 1) {
                            nextDay = schedule[idx + 1];
                          } else {
                            nextDay = schedule.last;
                          }
                        }

                        displayDay = nextDay;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<HbncVisitBloc>().add(
                            VisitDetailsChanged(field: 'visitNumber', value: displayDay),
                          );
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ApiDropdown<int>(
                            labelText: t.homeVisitDayLabel,
                            items: [1, 3, 7, 14, 21, 28, 42],
                            getLabel: (v) => v.toString(),
                            value: displayDay,
                            onChanged: (val) {
                              if (val != null) {
                                context.read<HbncVisitBloc>().add(
                                  VisitDetailsChanged(field: 'visitNumber', value: val),
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
                            VisitDetailsChanged(field: 'visitDate', value: date),
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

