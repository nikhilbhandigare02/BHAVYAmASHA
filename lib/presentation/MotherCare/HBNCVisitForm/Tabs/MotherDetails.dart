import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'dart:convert';

class MotherDetailsTab extends StatefulWidget {
  final String beneficiaryId;

  const MotherDetailsTab({super.key, required this.beneficiaryId});

  // Create keys for fields that have validation
  static final Map<String, GlobalKey> fieldKeys = {
    'motherStatus': GlobalKey(),
    'dateOfDeath': GlobalKey(),
    'deathPlace': GlobalKey(),
    'mcpCardAvailable': GlobalKey(),
    'mcpCardFilled': GlobalKey(),
    'postDeliveryProblems': GlobalKey(),
    'excessiveBleeding': GlobalKey(),
    'breastfeedingProblems': GlobalKey(),
    'breastfeedingHelpGiven': GlobalKey(),
    'mealsPerDay': GlobalKey(),
    'padsPerDay': GlobalKey(),
    'temperature': GlobalKey(),
    'paracetamolGiven': GlobalKey(),
    'foulDischargeHighFever': GlobalKey(),
    'milkNotProducingOrLess': GlobalKey(),
    'milkCounselingAdvice': GlobalKey(),
    'referHospital': GlobalKey(),
    'referTo': GlobalKey(),
  };

  @override
  State<MotherDetailsTab> createState() => _MotherDetailsTabState();
}

class _MotherDetailsTabState extends State<MotherDetailsTab> {
  bool _isMotherStatusLocked = false;

  @override
  void initState() {
    super.initState();
    _loadLastMotherStatus();
  }

  Future<void> _loadLastMotherStatus() async {
    try {
      if (widget.beneficiaryId.isEmpty) return;

      final db = await DatabaseProvider.instance.database;
      final pncKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother] ?? '';
      if (pncKey.isEmpty) return;

      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
            'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [pncKey, widget.beneficiaryId],
        orderBy: 'datetime(created_date_time) DESC',
        limit: 1,
      );

      if (rows.isEmpty) return;

      final rawJson = rows.first['form_json'] as String?;
      if (rawJson == null || rawJson.isEmpty) return;

      String? motherStatus;

      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          // Normalized structure: form_data.motherDetails.motherStatus
          if (decoded['form_data'] is Map &&
              (decoded['form_data']['motherDetails'] is Map)) {
            final md = decoded['form_data']['motherDetails'] as Map;
            motherStatus = md['motherStatus']?.toString();
          }

          // Local HBNC save structure: hbyc_form.motherDetails.motherStatus
          if (motherStatus == null && decoded['hbyc_form'] is Map) {
            final h = decoded['hbyc_form'] as Map<String, dynamic>;
            if (h['motherDetails'] is Map) {
              final md = h['motherDetails'] as Map;
              motherStatus = md['motherStatus']?.toString();
            }
          }

          // Fallback: top-level motherDetails
          if (motherStatus == null && decoded['motherDetails'] is Map) {
            final md = decoded['motherDetails'] as Map;
            motherStatus = md['motherStatus']?.toString();
          }
        }
      } catch (e) {
        print('Error parsing last HBNC motherStatus: $e');
      }

      if (!mounted) return;

      if (motherStatus == 'death' || motherStatus == 'alive') {
        final bloc = context.read<HbncVisitBloc>();

        bloc.add(
          MotherDetailsChanged(
            field: 'motherStatus',
            value: motherStatus,
          ),
        );

        if (motherStatus == 'death') {
          setState(() {
            _isMotherStatusLocked = true;
          });
        }
      }

    } catch (e) {
      print('Error loading last HBNC motherStatus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HbncVisitBloc, HbncVisitState>(
      listenWhen: (previous, current) =>
          previous.motherDetails != current.motherDetails,
      listener: (context, state) {
        print('MotherDetails (from state): ${state.motherDetails}');
      },
      builder: (context, state) {
        final m = state.motherDetails;
        final t = AppLocalizations.of(context)!;

        String? _asString(dynamic v) => v == null ? null : '$v';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ApiDropdown<String>(
                        key: MotherDetailsTab.fieldKeys['motherStatus'],
                        labelText: t.motherStatusLabel,
                        items: const ['alive', 'death'],
                        getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                        value: _asString(m['motherStatus']),
                        readOnly: _isMotherStatusLocked,
                        autoOpenTick: state.focusedErrorField == 'motherStatus' ? state.validationTick : null,
                        onChanged: _isMotherStatusLocked
                            ? null
                            : (val) => context.read<HbncVisitBloc>().add(
                                  MotherDetailsChanged(
                                    field: 'motherStatus',
                                    value: val,
                                  ),
                                ),
                      ),
                      const Divider(height: 0),
                      if (m['motherStatus'] == 'death') ...[
                        CustomDatePicker(
                          key: MotherDetailsTab.fieldKeys['dateOfDeath'],
                          labelText: t.date_of_death,
                          initialDate: m['dateOfDeath'] is DateTime
                              ? m['dateOfDeath'] as DateTime
                              : null,
                          onDateChanged: (d) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(field: 'dateOfDeath', value: d),
                          ),
                        ),
                        const Divider(),
                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['deathPlace'],
                          labelText: t.place_of_death,
                          items: [
                            t.home,
                            t.migrated_out,
                            t.on_the_way,
                            t.facility,
                            t.other,
                          ],
                          getLabel: (e) => e,
                          value: _asString(m['deathPlace']),
                          autoOpenTick: state.focusedErrorField == 'deathPlace' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(field: 'deathPlace', value: val),
                          ),
                        ),
                        const Divider(),
                        ApiDropdown<String>(
                          labelText: t.reason_of_death,
                          items: [
                            t.ph,
                            t.pph,
                            t.severe_anaemia,
                            t.spesis,
                            t.obstructedLabour,
                            t.malpresentation,
                            t.eclampsia_severe_hypertension,
                            t.unsafe_abortion,
                            t.surgical_complication,
                            t.other_reason_not_maternal_complication,
                            t.other_specify,
                          ],
                          getLabel: (e) => e,
                          value: _asString(m['reasonOfDeath']),
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'reasonOfDeath',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(),
                        if (m['reasonOfDeath'] == 'Other (Specify)') ...[
                          CustomTextField(
                            labelText: t.other_reason_of_death,
                            hintText: t.specify_other_reason,
                            initialValue: _asString(m['reasonOfDeathOther']),
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'reasonOfDeathOther',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(),
                        ],
                      ] else ...[
                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['mcpCardAvailable'],
                          labelText: t.mcpCardAvailableLabelMother,
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['mcpCardAvailable']),
                          autoOpenTick: state.focusedErrorField == 'mcpCardAvailable' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'mcpCardAvailable',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(),

                        if (m['mcpCardAvailable'] == 'Yes') ...[
                          ApiDropdown<String>(
                            key: MotherDetailsTab.fieldKeys['mcpCardFilled'],
                            labelText: t.has_mcp_card_filled,
                            items: const ['Yes', 'No'],
                            getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                            value: _asString(m['mcpCardFilled']),
                            autoOpenTick: state.focusedErrorField == 'mcpCardFilled' ? state.validationTick : null,
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'mcpCardFilled',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(),
                        ],

                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['postDeliveryProblems'],
                          labelText: t.postDeliveryProblemsLabel,
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['postDeliveryProblems']),
                          autoOpenTick: state.focusedErrorField == 'postDeliveryProblems' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'postDeliveryProblems',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(),

                        if (m['postDeliveryProblems'] == 'Yes') ...[
                          ApiDropdown<String>(
                            key: MotherDetailsTab.fieldKeys['excessiveBleeding'],
                            labelText: t.excessive_bleeding,
                            items: const ['Yes', 'No'],
                            getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                            value: _asString(m['excessiveBleeding']),
                            autoOpenTick: state.focusedErrorField == 'excessiveBleeding' ? state.validationTick : null,
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'excessiveBleeding',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(),
                          ApiDropdown<String>(
                            labelText: t.unconscious_fits,
                            items: const ['Yes', 'No'],
                            getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                            value: _asString(m['unconsciousFits']),
                            autoOpenTick: state.focusedErrorField == 'unconsciousFits' ? state.validationTick : null,
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'unconsciousFits',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(),
                        ],

                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['breastfeedingProblems'],
                          labelText: t.breastfeedingProblemsLabel,
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['breastfeedingProblems']),
                           autoOpenTick: state.focusedErrorField == 'breastfeedingProblems' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'breastfeedingProblems',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(),

                        if (m['breastfeedingProblems'] == 'Yes') ...[
                          CustomTextField(
                            labelText: t.please_enter_problem,
                            hintText: t.enter_breastfeeding_problem,
                            initialValue:
                            _asString(m['breastfeedingProblemDescription']) ??
                                '',
                            autofocus: state.focusedErrorField == 'breastfeedingProblemDescription',
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'breastfeedingProblemDescription',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(),
                          CustomTextField(
                            key: MotherDetailsTab.fieldKeys['breastfeedingHelpGiven'],
                            labelText: t.breastfeeding_problem_help,
                            hintText: t.write_take_action,
                            initialValue: _asString(m['breastfeedingHelpGiven']),
                            autofocus: state.focusedErrorField == 'breastfeedingHelpGiven',
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'breastfeedingHelpGiven',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(height: 0),
                        ],

                        ApiDropdown<int>(
                          key: MotherDetailsTab.fieldKeys['mealsPerDay'],
                          labelText: "${t.mealsPerDayLabel} *",
                          items: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                          getLabel: (e) => e.toString(),
                          value: (m['mealsPerDay'] is int)
                              ? m['mealsPerDay'] as int
                              : int.tryParse(_asString(m['mealsPerDay']) ?? ''),
                          autoOpenTick: state.focusedErrorField == 'mealsPerDay' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(field: 'mealsPerDay', value: val),
                          ),
                        ),
                        const Divider(),

                        ApiDropdown<String>(
                          labelText: t.counselingAdviceLabel,
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['counselingAdvice']),
                          autoOpenTick: state.focusedErrorField == 'counselingAdvice' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'counselingAdvice',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(),

                        ApiDropdown<int>(
                          key: MotherDetailsTab.fieldKeys['padsPerDay'],
                          labelText: t.padsPerDayLabel,
                          items: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                          getLabel: (e) => e.toString(),
                          value: (m['padsPerDay'] is int)
                              ? m['padsPerDay'] as int
                              : int.tryParse(_asString(m['padsPerDay']) ?? ''),
                          autoOpenTick: state.focusedErrorField == 'padsPerDay' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(field: 'padsPerDay', value: val),
                          ),
                        ),
                        const Divider(),

                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['temperature'],
                          labelText: "${t.mothersTemperatureLabel} *",
                          hintText: t.selectOption,
                          items: const [
                            'Temperature upto 102 degree F(38.9 degree C)',
                            'Temperure More that102 degree F (38.9 degree C)',
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'Temperature upto 102 degree F(38.9 degree C)':
                                return t.temp_upto_102;
                              case 'Temperure More that102 degree F (38.9 degree C)':
                                return t.temp_more_than_102;
                              default:
                                return s;
                            }
                          },
                          value: _asString(m['temperature']),
                          autoOpenTick: state.focusedErrorField == 'temperature' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(field: 'temperature', value: val),
                          ),
                        ),
                        const Divider(height: 0),

                        Builder(
                          builder: (context) {
                            final tempStr = _asString(m['temperature']) ?? '';
                            final isUpto102 =
                                tempStr ==
                                    'Temperature upto 102 degree F(38.9 degree C)';
                            if (isUpto102) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ApiDropdown<String>(
                                    key: MotherDetailsTab.fieldKeys['paracetamolGiven'],
                                    labelText: "${t.paracetamolGivenLabel} *",
                                    items: const ['Yes', 'No'],
                                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                                    value: _asString(m['paracetamolGiven']),
                                    autoOpenTick: state.focusedErrorField == 'paracetamolGiven' ? state.validationTick : null,
                                    onChanged: (val) =>
                                        context.read<HbncVisitBloc>().add(
                                          MotherDetailsChanged(
                                            field: 'paracetamolGiven',
                                            value: val,
                                          ),
                                        ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const Divider(height: 0),
                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['foulDischargeHighFever'],
                          labelText: "${t.foulDischargeHighFeverLabel}",
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['foulDischargeHighFever']),
                          autoOpenTick: state.focusedErrorField == 'foulDischargeHighFever' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'foulDischargeHighFever',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        ApiDropdown<String>(
                          labelText: "${t.abnormalSpeechOrSeizureLabel} *",
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['abnormalSpeechOrSeizure']),
                          autoOpenTick: state.focusedErrorField == 'abnormalSpeechOrSeizure' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'abnormalSpeechOrSeizure',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['milkNotProducingOrLess'],
                          labelText: "${t.milkNotProducingOrLessLabel} *",
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['milkNotProducingOrLess']),
                          autoOpenTick: state.focusedErrorField == 'milkNotProducingOrLess' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'milkNotProducingOrLess',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        if (m['milkNotProducingOrLess'] == 'Yes') ...[
                          ApiDropdown<String>(
                            key: MotherDetailsTab.fieldKeys['milkCounselingAdvice'],
                            labelText: "${t.counselingAdviceLabel}",
                            items: const ['Yes', 'No'],
                            getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                            value: _asString(m['milkCounselingAdvice']),
                            autoOpenTick: state.focusedErrorField == 'milkCounselingAdvice' ? state.validationTick : null,
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(
                                field: 'milkCounselingAdvice',
                                value: val,
                              ),
                            ),
                          ),
                          const Divider(height: 0),
                        ],
                        ApiDropdown<String>(
                          labelText: "${t.nippleCracksPainOrEngorgedLabel} *",
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['nippleCracksPainOrEngorged']),
                          autoOpenTick: state.focusedErrorField == 'nippleCracksPainOrEngorged' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'nippleCracksPainOrEngorged',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        ApiDropdown<String>(
                          key: MotherDetailsTab.fieldKeys['referHospital'],
                          labelText: "${t.refer_to_hospital} *",
                          items: const ['Yes', 'No'],
                          getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                          value: _asString(m['referHospital']),
                          autoOpenTick: state.focusedErrorField == 'referHospital' ? state.validationTick : null,
                          onChanged: (val) => context.read<HbncVisitBloc>().add(
                            MotherDetailsChanged(
                              field: 'referHospital',
                              value: val,
                            ),
                          ),
                        ),
                        const Divider(height: 0),

                        if (m['referHospital'] == 'Yes') ...[
                          ApiDropdown<String>(
                            key: MotherDetailsTab.fieldKeys['referTo'],
                            labelText: "${t.referToLabel} *",
                            items: [
                              t.phc,
                              t.chc,
                              t.rh,
                              t.sdh,
                              t.dh,
                              t.mch,
                            ],
                            getLabel: (e) => e,
                            value: _asString(m['referTo']),
                            autoOpenTick: state.focusedErrorField == 'referTo' ? state.validationTick : null,
                            onChanged: (val) => context.read<HbncVisitBloc>().add(
                              MotherDetailsChanged(field: 'referTo', value: val),
                            ),
                          ),
                          const Divider(height: 0),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
