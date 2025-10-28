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
      listenWhen: (previous, current) => previous.motherDetails != current.motherDetails,
      listener: (context, state) {
        // Print from state whenever motherDetails changes
        // ignore: avoid_print
        print('MotherDetails (from state): ${state.motherDetails}');
      },
      builder: (context, state) {
        final m = state.motherDetails;
        final t = AppLocalizations.of(context)!;

        String? _asString(dynamic v) => v == null ? null : '$v';

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Padding(
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
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.mcpCardAvailableLabelMother,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['mcpCardAvailable']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'mcpCardAvailable', value: val),
                      ),
                    ),
                    const Divider(),

                    // Problems after delivery
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
                        'Other'
                      ],
                      getLabel: (e) {
                        switch (e) {
                          case 'None':
                            return t.postDeliveryProblemNone;
                          case 'Excessive bleeding':
                            return t.postDeliveryProblemExcessiveBleeding;
                          case 'Severe headache/blurred vision':
                            return t.postDeliveryProblemSevereHeadacheBlurredVision;
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
                        MotherDetailsChanged(field: 'postDeliveryProblems', value: val),
                      ),
                    ),
                    const Divider(),

                    // Breastfeeding problems
                    ApiDropdown<String>(
                      labelText: t.breastfeedingProblemsLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['breastfeedingProblems']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'breastfeedingProblems', value: val),
                      ),
                    ),
                    const Divider(),

                    // Full meals count
                    ApiDropdown<int>(
                      labelText: t.mealsPerDayLabel,
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
                        MotherDetailsChanged(field: 'counselingAdvice', value: val),
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
                      keyboardType: TextInputType.number,
                      initialValue: _asString(m['temperature']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'temperature', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    // Foul-smelling discharge & high fever

                    ApiDropdown<String>(
                      labelText: t.foulDischargeHighFeverLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['foulDischargeHighFever']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'foulDischargeHighFever', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    // Abnormal speech or seizures
                    ApiDropdown<String>(
                      labelText: t.abnormalSpeechOrSeizureLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['abnormalSpeechOrSeizure']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'abnormalSpeechOrSeizure', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),

                    // New questions (as per request) - Yes/No
                    ApiDropdown<String>(
                      labelText: t.milkNotProducingOrLessLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['milkNotProducingOrLess']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'milkNotProducingOrLess', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                    ApiDropdown<String>(
                      labelText: t.nippleCracksPainOrEngorgedLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: _asString(m['nippleCracksPainOrEngorged']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        MotherDetailsChanged(field: 'nippleCracksPainOrEngorged', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

