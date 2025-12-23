import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class MotherDetailsTab extends StatelessWidget {
  const MotherDetailsTab({super.key});

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

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ApiDropdown<String>(
                    labelText: t.motherStatusLabel,
                    items: const ['alive', 'death'],
                    getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                    value: _asString(m['motherStatus']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(field: 'motherStatus', value: val),
                    ),
                  ),
                  const Divider(height: 0),
                  if (m['motherStatus'] == 'death') ...[
                    CustomDatePicker(
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
                      labelText: t.mcpCardAvailableLabelMother,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['mcpCardAvailable']),
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
                        labelText: t.has_mcp_card_filled,
                        items: const ['Yes', 'No'],
                        getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                        value: _asString(m['mcpCardFilled']),
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
                      labelText: t.postDeliveryProblemsLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['postDeliveryProblems']),
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
                        labelText: t.excessive_bleeding,
                        items: const ['Yes', 'No'],
                        getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                        value: _asString(m['excessiveBleeding']),
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
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          MotherDetailsChanged(
                            field: 'unconsciousFits',
                            value: val,
                          ),
                        ),
                      ),
                      const Divider(),
                    ],

                    // Breastfeeding problems
                    ApiDropdown<String>(
                      labelText: t.breastfeedingProblemsLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['breastfeedingProblems']),
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
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          MotherDetailsChanged(
                            field: 'breastfeedingProblemDescription',
                            value: val,
                          ),
                        ),
                      ),
                      const Divider(),
                      CustomTextField(
                        labelText: t.breastfeeding_problem_help,
                        hintText: t.write_take_action,
                        initialValue: _asString(m['breastfeedingHelpGiven']),
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          MotherDetailsChanged(
                            field: 'breastfeedingHelpGiven',
                            value: val,
                          ),
                        ),
                      ),
                      const Divider(height: 0),
                    ],

                    // Full meals count
                    ApiDropdown<int>(
                      labelText: "${t.mealsPerDayLabel} *",
                      items: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                      getLabel: (e) => e.toString(),
                      value: (m['mealsPerDay'] is int)
                          ? m['mealsPerDay'] as int
                          : int.tryParse(_asString(m['mealsPerDay']) ?? ''),
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
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(
                          field: 'counselingAdvice',
                          value: val,
                        ),
                      ),
                    ),
                    const Divider(),

                    ApiDropdown<int>(
                      labelText: t.padsPerDayLabel,
                      items: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                      getLabel: (e) => e.toString(),
                      value: (m['padsPerDay'] is int)
                          ? m['padsPerDay'] as int
                          : int.tryParse(_asString(m['padsPerDay']) ?? ''),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'padsPerDay', value: val),
                      ),
                    ),
                    const Divider(),

                    ApiDropdown<String>(
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
                                labelText: "${t.paracetamolGivenLabel} *",
                                items: const ['Yes', 'No'],
                                getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                                value: _asString(m['paracetamolGiven']),
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
                      labelText: "${t.foulDischargeHighFeverLabel} *",
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['foulDischargeHighFever']),
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
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(
                          field: 'abnormalSpeechOrSeizure',
                          value: val,
                        ),
                      ),
                    ),
                    const Divider(height: 0),

                    // New questions (as per request) - Yes/No
                    ApiDropdown<String>(
                      labelText: "${t.milkNotProducingOrLessLabel} *",
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['milkNotProducingOrLess']),
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
                        labelText: "${t.counselingAdviceLabel} *",
                        items: const ['Yes', 'No'],
                        getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                        value: _asString(m['milkCounselingAdvice']),
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
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(
                          field: 'nippleCracksPainOrEngorged',
                          value: val,
                        ),
                      ),
                    ),
                    const Divider(height: 0),

                    // Refer to Hospital & Refer to
                    ApiDropdown<String>(
                      labelText: "${t.refer_to_hospital} *",
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['referHospital']),
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
                        labelText: "${t.referToLabel} *",
                        items: [
                          t.visitTypePhc,
                          t.chc,
                          t.rh,
                          t.sdh,
                          t.dh,
                          t.mch,
                        ],
                        getLabel: (e) => e,
                        value: _asString(m['referTo']),
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
        );
      },
    );
  }
}
