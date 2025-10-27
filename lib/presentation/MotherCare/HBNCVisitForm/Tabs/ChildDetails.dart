import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class ChildDetailsTab extends StatelessWidget {
  const ChildDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HbncVisitBloc, HbncVisitState>(
      builder: (context, state) {
        final c = state.newbornDetails;
        String? s(dynamic v) {
          if (v == null) return null;
          if (v is String && v.trim().isEmpty) return null;
          return '$v';
        }
        String? yn(dynamic v) {
          if (v == null) return null;
          if (v is bool) return v ? 'Yes' : 'No';
          if (v is String && (v == 'Yes' || v == 'No')) return v;
          return null;
        }
        final t = AppLocalizations.of(context)!;

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
                      labelText: t.babyConditionLabel,
                      items: const ['alive', 'dead'],
                      getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                      value: s(c['babyCondition']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'babyCondition', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                    CustomTextField(
                      labelText: t.babyNameLabel,
                      initialValue: s(c['babyName']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'babyName', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                    ApiDropdown<String>(
                      labelText: t.babyGenderLabel,
                      items: const ['Male', 'Female', 'Other'],
                      getLabel: (e) => e == 'Male' ? t.male : (e == 'Female' ? t.female : t.other),
                      value: s(c['gender']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'gender', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                    CustomTextField(
                      labelText: t.newbornWeightGramLabel,
                      keyboardType: TextInputType.number,
                      initialValue: s(c['weightAtBirth']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'weightAtBirth', value: val),
                      ),
                    ),
                    const Divider(height: 0,),

                    CustomTextField(
                      labelText: t.newbornTemperatureLabel,
                      keyboardType: TextInputType.number,
                      initialValue: s(c['temperature']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'temperature', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.infantTemperatureUnitLabel,
                      items: const ['Celsius', 'Fahrenheit'],
                      getLabel: (e) => e == 'Celsius' ? t.temperatureUnitCelsius : t.temperatureUnitFahrenheit,
                      value: s(c['tempUnit']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'tempUnit', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.weightColorMatchLabel,
                      items: const ['Green', 'Yellow', 'Red'],
                      getLabel: (e) => e == 'Green' ? t.colorGreen : (e == 'Yellow' ? t.colorYellow : t.colorRed),
                      value: s(c['weightColorMatch']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'weightColorMatch', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.weighingScaleColorLabel,
                      items: const ['Green', 'Yellow', 'Red'],
                      getLabel: (e) => e == 'Green' ? t.colorGreen : (e == 'Yellow' ? t.colorYellow : t.colorRed),
                      value: s(c['weighingScaleColor']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'weighingScaleColor', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.motherReportsTempOrChestIndrawingLabel,
                      labelMaxLines: 4,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['motherReportsTempOrChestIndrawing']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'motherReportsTempOrChestIndrawing', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    // Additional checks (mostly Yes/No)
                    ApiDropdown<String>(
                      labelText: t.bleedingUmbilicalCordLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['bleedingUmbilicalCord']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'bleedingUmbilicalCord', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.pusInNavelLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['pusInNavel']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'pusInNavel', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.routineCareDoneLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['routineCareDone']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'routineCareDone', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.breathingRapidLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['breathingRapid']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'breathingRapid', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.lethargicLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['lethargic']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'lethargic', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.congenitalAbnormalitiesLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['congenitalAbnormalities']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'congenitalAbnormalities', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.eyesNormalLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['eyesNormal']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'eyesNormal', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.eyesSwollenOrPusLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['eyesSwollenOrPus']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'eyesSwollenOrPus', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.skinFoldRednessLabel,
                      labelMaxLines: 3,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['skinFoldRedness']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'skinFoldRedness', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.newbornJaundiceLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['jaundice']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'jaundice', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.pusBumpsOrBoilLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['pusBumpsOrBoil']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'pusBumpsOrBoil', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.newbornSeizuresLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['seizures']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'seizures', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.cryingConstantlyOrLessUrineLabel,
                      labelMaxLines: 3,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['cryingConstantlyOrLessUrine']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'cryingConstantlyOrLessUrine', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.cryingSoftlyLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['cryingSoftly']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'cryingSoftly', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.stoppedCryingLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['stoppedCrying']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'stoppedCrying', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.newbornReferredByAshaLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['referredByASHA']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'referredByASHA', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.birthRegisteredLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['birthRegistered']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'birthRegistered', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.birthCertificateIssuedLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['birthCertificateIssued']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'birthCertificateIssued', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.birthDoseVaccinationLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['birthDoseVaccination']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'birthDoseVaccination', value: val),
                      ),
                    ),
                                        const Divider(height: 0,),


                    ApiDropdown<String>(
                      labelText: t.mcpCardAvailableLabel,
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['mcpCardAvailable']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'mcpCardAvailable', value: val),
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

