import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/DatePicker/timepicker.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/outcome_form_bloc.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../core/widgets/SuccessDialogbox/SuccessDialogbox.dart';

class OutcomeFormPage extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;

  const OutcomeFormPage({super.key, required this.beneficiaryData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutcomeFormBloc()
        ..add(
          OutcomeFormInitialized(
            householdId: beneficiaryData['householdId']?.toString(),
            beneficiaryId: beneficiaryData['beneficiaryId']?.toString(),
          ),
        ),
      child: _OutcomeFormView(beneficiaryData: beneficiaryData),
    );
  }
}

class _OutcomeFormView extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;

  _OutcomeFormView({required this.beneficiaryData}) {
    print('OutcomeFormView created with beneficiaryData: $beneficiaryData');
  }

  void _logState(OutcomeFormState state) {
    print(
      'Current state - householdId: ${state.householdId}, beneficiaryId: ${state.beneficiaryId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(screenTitle: l10n.deliveryOutcomeTitle, showBack: true),
      body: SafeArea(
        bottom: true,
        child: BlocConsumer<OutcomeFormBloc, OutcomeFormState>(
          listenWhen: (previous, current) => true,
          listener: (context, state) {
            _logState(state);
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              showAppSnackBar(context, state.errorMessage!);
            }

            if (state.submitted) {
              showAppSnackBar(context, l10n.dataSavedSuccessMessage);
              Future.microtask(() {
                CustomDialog.show(
                  context,
                  title: l10n.deliveryOutcomeDialogue,
                  message: l10n.savedBeneficiary,
                  onOkPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.pop(context);
                  },
                );
              });
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _SectionHeader(title: l10n.deliveryOutcomeDetails),

                FutureBuilder<int>(
                  future: () async {
                    try {
                      final beneficiaryId = beneficiaryData['BeneficiaryID']
                          ?.toString();
                      print(
                        '🔍 Checking submFion count for BeneficiaryID: $beneficiaryId',
                      );

                      if (beneficiaryId == null || beneficiaryId.isEmpty) {
                        print(
                          '⚠️ No valid BeneficiaryID found in beneficiaryData: $beneficiaryData',
                        );
                        return 0;
                      }

                      final count =
                          await SecureStorageService.getSubmissionCount(
                            beneficiaryId,
                          );
                      print(
                        '✅ Found $count submissions for BeneficiaryID: $beneficiaryId',
                      );
                      return count;
                    } catch (e) {
                      print('❌ Error getting submission count: $e');
                      return 0;
                    }
                  }(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      color: Colors.white,
                      child: Row(children: []),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder<void>(
                  future: () async {
                    try {
                      final db = await DatabaseProvider.instance.database;
                      final beneficiaryId =
                          beneficiaryData['BeneficiaryID']?.toString() ??
                          beneficiaryData['beneficiaryId']?.toString() ??
                          beneficiaryData['unique_key']?.toString() ??
                          '';
                      final ancKey =
                          FollowupFormDataTable
                              .formUniqueKeys[FollowupFormDataTable
                              .ancDueRegistration] ??
                          '';
                      if (beneficiaryId.isEmpty || ancKey.isEmpty) return;
                      final results = await db.query(
                        FollowupFormDataTable.table,
                        where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
                        whereArgs: [beneficiaryId, ancKey],
                        orderBy: 'created_date_time DESC',
                        limit: 1,
                      );
                      if (results.isEmpty) return;
                      final formJsonRaw =
                          results.first['form_json']?.toString() ?? '';
                      final createdAt =
                          results.first['created_date_time']?.toString() ?? '';
                      DateTime? createdDate;
                      try {
                        createdDate = DateTime.tryParse(createdAt);
                      } catch (_) {}
                      if (createdDate != null) {
                        context.read<OutcomeFormBloc>().add(
                          DeliveryDateChanged(createdDate),
                        );
                      }
                      if (formJsonRaw.isEmpty) return;
                      final decoded = jsonDecode(formJsonRaw);
                      if (decoded is Map && decoded['anc_form'] is Map) {
                        final fd = Map<String, dynamic>.from(
                          decoded['anc_form'] as Map,
                        );
                        final flag =
                            (fd['gives_birth_to_baby']?.toString() ?? '')
                                .toLowerCase();
                        if (flag == 'yes') {
                          print(
                            'ANC record with gives_birth_to_baby YES: ${results.first}',
                          );
                        }
                        final weeks =
                            fd['weeks_of_pregnancy']?.toString() ?? '';
                        if (weeks.isNotEmpty) {
                          context.read<OutcomeFormBloc>().add(
                            GestationWeeksChanged(weeks),
                          );
                        }
                        final children =
                            fd['number_of_children']?.toString() ?? '';
                        if (children.isNotEmpty) {
                          final t = children.trim().toLowerCase();
                          String numeric;
                          if (t == 'one child' || t == 'one' || t == '1') {
                            numeric = '1';
                          } else if (t == 'twins' || t == 'two' || t == '2') {
                            numeric = '2';
                          } else if (t == 'triplets' ||
                              t == 'three' ||
                              t == '3') {
                            numeric = '3';
                          } else {
                            final n = int.tryParse(children);
                            numeric = n?.toString() ?? children;
                          }
                          context.read<OutcomeFormBloc>().add(
                            OutcomeCountChanged(numeric),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error loading ANC gives_birth_to_baby record: $e');
                    }
                  }(),
                  builder: (context, snapshot) => const SizedBox.shrink(),
                ),

                // Form Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: _OutcomeFormFields(beneficiaryData: beneficiaryData),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OutcomeFormFields extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;

  const _OutcomeFormFields({required this.beneficiaryData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<OutcomeFormBloc>();
    final state = context.watch<OutcomeFormBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomDatePicker(
          initialDate: state.deliveryDate,
          isEditable: true,
          labelText: l10n.deliveryDate,
          onDateChanged: (d) => bloc.add(DeliveryDateChanged(d)),
          // readOnly: true,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.gestationWeeks,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bloc.add(GestationWeeksChanged(v)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  controller: TextEditingController(text: state.gestationWeeks),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => ScrollableTimePicker(
                initialTime: state.deliveryTime,
                use24Hour: true,
                onTimeSelected: (time) {
                  bloc.add(DeliveryTimeChanged(time));
                },
              ),
            );
          },
          child: AbsorbPointer(
            child: CustomTextField(
              labelText: l10n.deliveryTime,
              hintText: l10n.deliveryTimeHint,
              initialValue: state.deliveryTime ?? '',
              keyboardType: TextInputType.datetime,
              onChanged: (v) => bloc.add(DeliveryTimeChanged(v)),
              // suffixIcon: Icon(Icons.access_time),
            ),
          ),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: const ['Institutional', 'Non-Institutional', 'Other'],

          getLabel: (s) {
            switch (s) {
              case 'Institutional':
                return l10n.institutional;
              case 'Non-Institutional':
                return l10n.nonInstitutional;
              case 'Other':
                return l10n.other;
              default:
                return s;
            }
          },

          value: state.placeOfDelivery.isEmpty ||
              !['Institutional', 'Non-Institutional', 'Other']
                  .contains(state.placeOfDelivery)
              ? null
              : state.placeOfDelivery,

          onChanged: (v) =>
              bloc.add(PlaceOfDeliveryChanged(v ?? '')),

          labelText: l10n.placeOfDelivery,
        ),

        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.placeOfDelivery == 'Other') ...[
          const SizedBox(height: 8),
          CustomTextField(
            labelText: l10n.enterOtherPlaceOfDelivery,
            hintText: l10n.enterPlace,
            initialValue: state.otherPlaceOfDeliveryName ?? '',
            onChanged: (v) => bloc.add(OtherPlaceOfDeliveryNameChanged(v)),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],

        if (state.placeOfDelivery == 'Institutional') ...[
          ApiDropdown<String>(
            items: const ['Public', 'Private'],
            getLabel: (s) {
              switch (s) {
                case 'Public':
                  return l10n?.publicPlace ?? '';
                case 'Private':
                  return l10n?.privatePlace ?? '';
                default:
                  return s;
              }
            },
            value:
                (state.institutionalPlaceType == null ||
                    state.institutionalPlaceType!.isEmpty ||
                    ![
                      'Public',
                      'Private',
                    ].contains(state.institutionalPlaceType))
                ? null
                : state.institutionalPlaceType,
            onChanged: (v) => bloc.add(InstitutionalPlaceTypeChanged(v ?? '')),
            labelText:
                l10n?.institutionPlaceOfDelivery ??
                'Institution place of delivery',
            hintText: l10n?.select ?? 'Select',
          ),

          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

          if (state.institutionalPlaceType == 'Public') ...[
            ApiDropdown<String>(
              items: const ['Sub-Center', 'PHC', 'CHC', 'RH', 'DH', 'MCH'],
              getLabel: (s) {
                switch (s) {
                  case 'Sub-Center':
                    return l10n?.subCenter ?? '';
                  case 'PHC':
                    return l10n?.phc ?? '';
                  case 'CHC':
                    return l10n?.chc ?? '';
                  case 'RH':
                    return l10n?.rh ?? '';
                  case 'DH':
                    return l10n?.dh ?? '';
                  case 'MCH':
                    return l10n?.mch ?? '';
                  default:
                    return s;
                }
              },
              value:
                  (state.institutionalPlaceOfDelivery == null ||
                      state.institutionalPlaceOfDelivery!.isEmpty ||
                      ![
                        'Sub-Center',
                        'PHC',
                        'CHC',
                        'RH',
                        'DH',
                        'MCH',
                      ].contains(state.institutionalPlaceOfDelivery))
                  ? null
                  : state.institutionalPlaceOfDelivery,
              onChanged: (v) =>
                  bloc.add(InstitutionalPlaceOfDeliveryChanged(v ?? '')),
              labelText:
                  l10n?.institutionPlaceOfDelivery ??
                  'Institutional place of delivery',
              hintText: l10n?.select ?? 'Select',
            ),

            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            const SizedBox(height: 8),
          ] else if (state.institutionalPlaceType == 'Private') ...[
            ApiDropdown<String>(
              items: const ['Nursing Home', 'Hospital'],
              getLabel: (s) {
                switch (s) {
                  case 'Nursing Home':
                    return l10n?.nursingHome ?? '';
                  case 'Hospital':
                    return l10n?.hospital ?? '';
                  default:
                    return s;
                }
              },
              value:
                  (state.institutionalPlaceOfDelivery == null ||
                      state.institutionalPlaceOfDelivery!.isEmpty ||
                      ![
                        'Nursing Home',
                        'Hospital',
                      ].contains(state.institutionalPlaceOfDelivery))
                  ? null
                  : state.institutionalPlaceOfDelivery,
              onChanged: (v) =>
                  bloc.add(InstitutionalPlaceOfDeliveryChanged(v ?? '')),
              labelText:
                  l10n?.nonInstitutionalPlaceOfDelivery ??
                  'Institutional place of delivery',
              hintText: l10n?.select ?? 'Select',
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            const SizedBox(height: 8),
          ],
        ],
        if (state.placeOfDelivery == 'Non-Institutional') ...[
          ApiDropdown<String>(
            items: ['Home Based Delivery', 'In Transit', 'Other'],
            getLabel: (s) {
              switch (s) {
                case 'Home Based Delivery':
                  return l10n?.homeBasedDelivery ?? '';
                case 'In Transit':
                  return l10n?.inTransit ?? '';
                case 'Other':
                  return l10n?.other ?? '';
                default:
                  return s;
              }
            },
            value:
                (state.nonInstitutionalPlaceType == null ||
                    state.nonInstitutionalPlaceType!.isEmpty ||
                    ![
                      'Home Based delivery',
                      'In Transit',
                      'Other',
                    ].contains(state.nonInstitutionalPlaceType))
                ? l10n.select
                : state.nonInstitutionalPlaceType!,
            onChanged: (v) =>
                bloc.add(NonInstitutionalPlaceTypeChanged(v ?? '')),
            labelText:
                l10n?.nonInstitutionalPlaceOfDelivery ??
                'Institutional place of delivery',
          ),

          const SizedBox(height: 8),
          if (state.nonInstitutionalPlaceType == 'Other') ...[
            CustomTextField(
              labelText: l10n?.enterOtherNonInstitutionalDelivery,
              hintText: l10n.enterName,
              initialValue: state.otherNonInstitutionalPlaceName ?? '',
              onChanged: (v) =>
                  bloc.add(OtherNonInstitutionalPlaceNameChanged(v)),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          ] else if (state.nonInstitutionalPlaceType == 'In Transit') ...[
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            ApiDropdown<String>(
              items: ['Ambulance', 'Other'],
              getLabel: (s) {
                switch (s) {
                  case 'Ambulance':
                    return l10n?.ambulance ?? '';
                  case 'Other':
                    return l10n?.other ?? '';
                  default:
                    return s;
                }
              },
              value:
                  (state.transitPlace == null ||
                      state.transitPlace!.isEmpty ||
                      !['Ambulance', 'Other'].contains(state.transitPlace))
                  ? l10n.select
                  : state.transitPlace!,
              onChanged: (v) => bloc.add(TransitPlaceChanged(v ?? '')),
              labelText: l10n.transitPlace,
            ),
            const SizedBox(height: 8),
            if (state.transitPlace == 'Other') ...[
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
              CustomTextField(
                labelText: l10n.enterOtherTransitPlace,
                hintText: l10n.enterOtherTransitPlace,
                initialValue: state.otherTransitPlaceName ?? '',
                onChanged: (v) => bloc.add(OtherTransitPlaceNameChanged(v)),
              ),
              const SizedBox(height: 8),
            ],
          ],
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],

        ApiDropdown<String>(
          items: [
            'ANM',
            'LHV',
            'Doctor',
            'Staff Nurse',
            'Relative',
            'TBA (Non-Skilled birth attendant)',
            'Other',
          ],
          getLabel: (s) {
            switch (s) {
              case 'ANM':
                return l10n.anm ;
              case 'LHV':
                return l10n.lhv ;
              case 'Doctor':
                return l10n.doctor ;
              case 'Staff Nurse':
                return l10n.staffNurse ;
              case 'Relative':
                return l10n.relative;
              case 'TBA (Non-Skilled birth attendant)':
                return l10n.tba ;
              case 'Other':
                return l10n.other ;
              default:
                return s;
            }
          },
          value:
              (state.conductedBy == null ||
                  state.conductedBy!.isEmpty ||
                  ![
                    'ANM',
                    'LHV',
                    'Doctor',
                    'Staff Nurse',
                    'Relative',
                    'TBA (Non-Skilled birth attendant)',
                    'Other',
                  ].contains(state.conductedBy))
              ? l10n.select
              : state.conductedBy!,
          onChanged: (v) => bloc.add(ConductedByChanged(v ?? '')),
          labelText: l10n.whoConductedDelivery,
        ),
        if (state.conductedBy == 'Other') ...[
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

          const SizedBox(height: 8),
          CustomTextField(
            labelText: l10n.whoElseConductedDelivery,
            hintText: l10n.enterName,
            initialValue: state.otherConductedByName ?? '',
            onChanged: (v) => bloc.add(OtherConductedByNameChanged(v)),
          ),
        ],
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [
            l10n.cesareanDelivery,
            l10n.assistedDelivery,
            l10n.normalDelivery,
          ],
          getLabel: (s) => s,
          value:
              state.deliveryType.isEmpty ||
                  ![
                    l10n.cesareanDelivery,
                    l10n.assistedDelivery,
                    l10n.normalDelivery,
                  ].contains(state.deliveryType)
              ? l10n.select
              : state.deliveryType,
          onChanged: (v) => bloc.add(DeliveryTypeChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.deliveryType,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [l10n.yes, l10n.no],
          getLabel: (s) => s,
          value:
              state.complications.isEmpty ||
                  ![l10n.yes, l10n.no].contains(state.complications)
              ? l10n.select
              : state.complications,
          onChanged: (v) => bloc.add(ComplicationsChanged(v ?? '')),
          hintText: l10n.enterComplicationDuringDelivery,
          labelText: l10n.enterComplicationDuringDelivery,
        ),
        if (state.complications == l10n.yes) ...[
          const SizedBox(height: 8),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          ApiDropdown<String>(
            items: [
              'Convulsion',
              'Ante Partumhaemorrhage (Aph)',
              'Pregnancy Induced Hypertension (PIH)',
              'Repeated Abortion',
              'Mother Death',
              'Congenital Anomaly',
              'Blood Transfusion',
              'Obstructed Labour',
              'PPH',
              'Any other',
            ],
            getLabel: (s) {
              switch (s) {
                case 'Convulsion':
                  return l10n?.convulsion ?? '';
                case 'Ante Partumhaemorrhage (Aph)':
                  return l10n?.aph ?? '';
                case 'Pregnancy Induced Hypertension (PIH)':
                  return l10n?.pih ?? '';
                case 'Repeated Abortion':
                  return l10n?.repeatedAbortion ?? '';
                case 'Mother Death':
                  return l10n?.motherDeath ?? '';
                case 'Congenital Anomaly':
                  return l10n?.congenitalAnomaly ?? '';
                case 'Blood Transfusion':
                  return l10n?.bloodTransfusion ?? '';
                case 'Obstructed Labour':
                  return l10n?.obstructedLabour ?? '';
                case 'PPH':
                  return l10n?.pph ?? '';
                case 'Any other':
                  return l10n?.anyOther ?? '';
                default:
                  return s;
              }
            },
            value:
                (state.complicationType == null ||
                    state.complicationType!.isEmpty ||
                    ![
                      'Convulsion',
                      'Ante Partumhaemorrhage (Aph)',
                      'Pregnancy Induced Hypertension (PIH)',
                      'Repeated Abortion',
                      'Mother Death',
                      'Congenital Anomaly',
                      'Blood Transfusion',
                      'Obstructed Labour',
                      'PPH',
                      'Any other',
                    ].contains(state.complicationType))
                ? l10n.select
                : state.complicationType!,
            onChanged: (v) => bloc.add(ComplicationTypeChanged(v ?? '')),
            labelText: l10n.complication,
          ),

          if (state.complicationType == 'Any other') ...[
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            CustomTextField(
              labelText: l10n.enterOtherComplication,
              hintText: l10n.enterComplication,
              initialValue: state.otherComplicationName ?? '',
              onChanged: (v) => bloc.add(OtherComplicationNameChanged(v)),
            ),
            const SizedBox(height: 8),
          ],
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        if (state.placeOfDelivery == 'Institutional') ...[
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          CustomDatePicker(
            initialDate: state.dischargeDate,
            isEditable: true,
            labelText: l10n.dateOfDischarge,
            onDateChanged: (d) => bloc.add(DischargeDateChanged(d)),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => ScrollableTimePicker(
                  initialTime: state.dischargeTime,
                  use24Hour: true, // Set to false for 12-hour format
                  onTimeSelected: (time) {
                    bloc.add(DischargeTimeChanged(time));
                  },
                ),
              );
            },
            child: AbsorbPointer(
              child: CustomTextField(
                labelText: l10n.discharge_time,
                hintText: l10n.hhmm,
                initialValue: state.dischargeTime ?? '',
                // suffixIcon: Icon(Icons.access_time),
              ),
            ),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: l10n.outcomeCount.endsWith('*')
                            ? l10n.outcomeCount.substring(
                                0,
                                l10n.outcomeCount.length - 1,
                              )
                            : l10n.outcomeCount,
                      ),
                      if (l10n.outcomeCount.endsWith('*'))
                        TextSpan(
                          text: '*',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bloc.add(OutcomeCountChanged(v)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  controller: TextEditingController(text: state.outcomeCount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: ["Yes", "No"],
          getLabel: (s) {
            switch (s) {
              case 'No':
                return l10n.no;
              case 'Yes':
                return l10n.yes ?? '';
              default:
                return s;
            }
          },
          value: state.familyPlanningCounseling.isEmpty
              ? l10n.select
              : state.familyPlanningCounseling,
          onChanged: (v) => bloc.add(FamilyPlanningCounselingChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText:"${ l10n.familyPlanningCounseling} *",
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.familyPlanningCounseling == 'Yes') ...[
          const SizedBox(height: 8),
          ApiDropdown<String>(
            labelText: "${l10n.adaptFamilyPlanningMethod} *",
            items: ["Yes", "No"],
            getLabel: (s) {
              switch (s) {
                case 'No':
                  return l10n.no;
                case 'Yes':
                  return l10n.yes ?? '';
                default:
                  return s;
              }
            },
            value: state.adaptFpMethod ?? l10n.select,
            onChanged: (v) => bloc.add(AdaptFpMethodChanged(v ?? '')),
            hintText: l10n.selectOption,
          ),

          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          if (state.adaptFpMethod == 'Yes' &&
              state.familyPlanningCounseling == 'Yes') ...[
            ApiDropdown<String>(
              labelText: "${l10n.methodOfContra} *",
              items: const [
                'Atra injection',
                'Copper -T (IUCD)',
                'Condom',
                'Mala -N (Daily Contraceptive pill)',
                'Chhaya (Weekly Contraceptive pill)',
                'ECP (Emergency Contraceptive pill)',
                'Male Sterilization',
                'Female Sterilization',
                'Any Other Specify',
              ],
              getLabel: (s) {
                switch (s) {
                  case 'Condom':
                    return l10n?.condom ?? '';
                  case 'Mala -N (Daily Contraceptive pill)':
                    return l10n?.malaN ?? '';
                  case 'Atra injection':
                    return l10n.antraInjection ?? '';
                  case 'Copper -T (IUCD)':
                    return l10n?.copperT ?? '';
                  case 'Chhaya (Weekly Contraceptive pill)':
                    return l10n?.chhaya ?? '';
                  case 'ECP (Emergency Contraceptive pill)':
                    return l10n?.ecp ?? '';
                  case 'Male Sterilization':
                    return l10n?.maleSterilization ?? '';
                  case 'Female Sterilization':
                    return l10n?.femaleSterilization ?? '';
                  case 'Any Other Specify':
                    return l10n?.anyOtherSpecify ?? '';
                  default:
                    return s;
                }
              },
              value: state.fpMethod ?? l10n.select,
              onChanged: (value) {
                if (value != null) {
                  context.read<OutcomeFormBloc>().add(FpMethodChanged(value));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.fpMethod == 'Copper -T (IUCD)' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomDatePicker(
            labelText: l10n.dateOfRemoval,
            // initialDate: state.removalDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              if (date != null) {
                context.read<OutcomeFormBloc>().add(RemovalDateChanged(date));
              }
            },
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
          CustomTextField(
            labelText: l10n.reasonForRemoval,
            hintText: l10n.enterReasonForRemoval,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(RemovalReasonChanged(value));
            },
            controller: TextEditingController(text: state.removalReason ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Atra injection' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomDatePicker(
            labelText: l10n.dateOfAntra,
            // initialDate: state.antraDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              if (date != null) {
                context.read<OutcomeFormBloc>().add(AntraDateChanged(date));
              }
            },
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Condom' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomTextField(
            labelText: l10n.quantityOfCondoms,
            hintText:l10n.quantityOfCondoms,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(CondomQuantityChanged(value));
            },
            controller: TextEditingController(text: state.condomQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Mala -N (Daily Contraceptive pill)' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomTextField(
            labelText: l10n.quantityOfMalaN,
            hintText: l10n.quantityOfMalaN,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(MalaQuantityChanged(value));
            },
            controller: TextEditingController(text: state.malaQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Chhaya (Weekly Contraceptive pill)' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomTextField(
            labelText: l10n.chhaya,
            hintText: l10n.chhaya,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(ChhayaQuantityChanged(value));
            },
            controller: TextEditingController(text: state.chhayaQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'ECP (Emergency Contraceptive pill)' &&
            state.familyPlanningCounseling == 'Yes' &&
            state.adaptFpMethod == 'Yes') ...[
          CustomTextField(
            labelText:l10n.ecp,
            hintText: l10n.ecp,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(ECPQuantityChanged(value));
            },
            controller: TextEditingController(text: state.ecpQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: SizedBox(
            height: 34,
            width: 140,
            child: RoundButton(
              title: l10n.saveButton,
              borderRadius: 4,
              isLoading: state.submitting,
              color: AppColors.primary,
              onPress: () {
                final bloc = context.read<OutcomeFormBloc>();
                final beneficiaryData =
                    (context
                                .findAncestorWidgetOfExactType<
                                  BlocProvider<OutcomeFormBloc>
                                >()
                                ?.child
                            as _OutcomeFormView)
                        .beneficiaryData;
                
                // Pass localized messages to the BLoC
                bloc.add(
                  OutcomeFormSubmitted(
                    beneficiaryData: beneficiaryData,
                    localizedMessages: {
                      'deliveryDateRequired': l10n.deliveryDateRequired,
                      'placeOfDeliveryRequired': l10n.placeOfDeliveryRequired,
                      'deliveryTypeRequired': l10n.deliveryTypeRequired,
                      'outcomeCountRequired': l10n.outcomeCountRequired,
                      'familyPlanningCounselingRequired': l10n.familyPlanningCounselingRequired,
                      'failedToSaveDeliveryOutcomeSecure': l10n.failedToSaveDeliveryOutcomeSecure,
                      'failedToSaveDeliveryOutcomeDatabase': l10n.failedToSaveDeliveryOutcomeDatabase,
                      'unexpectedErrorOccurred': l10n.unexpectedErrorOccurred,
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.background,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
