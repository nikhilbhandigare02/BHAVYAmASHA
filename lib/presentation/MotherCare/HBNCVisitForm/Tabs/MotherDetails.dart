import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
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
                    items: const ['alive', 'dead'],
                    getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                    value: _asString(m['motherStatus']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(field: 'motherStatus', value: val),
                    ),
                  ),
                  const Divider(height: 0),

                  if (m['motherStatus'] == 'alive') ...[
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

                  ],

                  if (m['mcpCardAvailable'] == 'Yes') ...[
                    ApiDropdown<String>(
                      labelText: 'Has the MCP card filled? *',
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
                    items: const [
                      'None',
                      'Excessive bleeding',
                      'Severe headache/blurred vision',
                      'Lower abdominal pain',
                      'Foul-smelling discharge',
                      'High fever',
                      'Convulsions',
                      'Other',
                    ],
                    getLabel: (e) {
                      switch (e) {
                        case 'None':
                          return t.postDeliveryProblemNone;
                        case 'Excessive bleeding':
                          return t.postDeliveryProblemExcessiveBleeding;
                        case 'Severe headache/blurred vision':
                          return t
                              .postDeliveryProblemSevereHeadacheBlurredVision;
                        case 'Lower abdominal pain':
                          return t.postDeliveryProblemLowerAbdominalPain;
                        case 'Foul-smelling discharge':
                          return t.postDeliveryProblemFoulSmellingDischarge;
                        case 'High fever':
                          return t.postDeliveryProblemHighFever;
                        case 'Convulsions':
                          return t.postDeliveryProblemConvulsions;
                        case 'Other':
                        default:
                          return t.other;
                      }
                    },
                    value: _asString(m['postDeliveryProblems']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(
                        field: 'postDeliveryProblems',
                        value: val,
                      ),
                    ),
                  ),
                  const Divider(),

                  // Extra questions when there is any post-delivery problem
                  if (m['postDeliveryProblems'] != null &&
                      m['postDeliveryProblems'] != 'None') ...[
                    ApiDropdown<String>(
                      labelText: 'Excessive bleeding*',
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
                      labelText: 'Unconsious / fits*',
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
                      labelText: 'Please enter problem *',
                      hintText: 'Enter breastfeeding problem',
                      initialValue:
                          _asString(m['breastfeedingProblemDescription']) ?? '',
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(
                          field: 'breastfeedingProblemDescription',
                          value: val,
                        ),
                      ),
                    ),
                    const Divider(),
                    ApiDropdown<String>(
                      labelText:
                          'Is there is a problem in breastfeeding, help the mother to overcome it *',
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['breastfeedingHelpGiven']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(
                          field: 'breastfeedingHelpGiven',
                          value: val,
                        ),
                      ),
                    ),
                    const Divider(),
                  ],

                  // Full meals count
                  ApiDropdown<int>(
                    labelText: "${t.mealsPerDayLabel} *",
                    items: const [1, 2, 3, 4, 5, 6],
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

                  // Pads changed per day
                  ApiDropdown<int>(
                    labelText: t.padsPerDayLabel,
                    items: const [0, 1, 2, 3, 4, 5, 6],
                    getLabel: (e) => e.toString(),
                    value: (m['padsPerDay'] is int)
                        ? m['padsPerDay'] as int
                        : int.tryParse(_asString(m['padsPerDay']) ?? ''),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(field: 'padsPerDay', value: val),
                    ),
                  ),
                  const Divider(),

                  CustomTextField(
                    labelText: t.mothersTemperatureLabel,
                    hintText: t.mothersTemperatureLabel,
                    keyboardType: TextInputType.number,
                    initialValue: _asString(m['temperature']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(field: 'temperature', value: val),
                    ),
                  ),
                  const Divider(height: 0),

                  // Paracetamol tablet given when temperature up to 102 F
                  Builder(
                    builder: (context) {
                      final tempStr = _asString(m['temperature']) ?? '';
                      final tempVal = double.tryParse(tempStr);
                      if (tempVal != null && tempVal > 0 && tempVal <= 102) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ApiDropdown<String>(
                              labelText:
                                  'Paracetamol tablet given (Temperature up to 102°F / 38.9°C) *',
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
                            const Divider(height: 0),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Foul-smelling discharge & high fever
                  ApiDropdown<String>(
                    labelText: t.foulDischargeHighFeverLabel,
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

                  // Abnormal speech or seizures
                  ApiDropdown<String>(
                    labelText: t.abnormalSpeechOrSeizureLabel,
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
                    labelText: t.milkNotProducingOrLessLabel,
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
                      labelText: 'Counseling/Advise *',
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

                  // Refer to Hospital & Refer to
                  ApiDropdown<String>(
                    labelText: 'Refer to Hospital *',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: _asString(m['referHospital']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      MotherDetailsChanged(field: 'referHospital', value: val),
                    ),
                  ),
                  const Divider(height: 0),

                  if (m['referHospital'] == 'Yes') ...[
                    ApiDropdown<String>(
                      labelText: 'Refer to? *',
                      items: const [
                        'PHC',
                        'CHC',
                        'District Hospital',
                        'Private',
                      ],
                      getLabel: (e) => e,
                      value: _asString(m['referTo']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'referTo', value: val),
                      ),
                    ),
                    const Divider(height: 0),
                  ],

                  ApiDropdown<String>(
                    labelText: t.nippleCracksPainOrEngorgedLabel,
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
