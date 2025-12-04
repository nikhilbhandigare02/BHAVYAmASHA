import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_bloc.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_event.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/bloc/hbcn_visit_state.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';

class ChildDetailsTab extends StatefulWidget {
  final String beneficiaryId;
  const ChildDetailsTab({super.key, required this.beneficiaryId});

  @override
  State<ChildDetailsTab> createState() => _ChildDetailsTabState();
}

class _ChildDetailsTabState extends State<ChildDetailsTab> {
  @override
  void initState() {
    super.initState();
    _loadLastAncForm();
  }

  Future<void> _loadLastAncForm() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final refKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
      if (refKey.isEmpty || widget.beneficiaryId.isEmpty) return;
      final rows = await db.rawQuery(
        'SELECT * FROM ${FollowupFormDataTable.table} WHERE forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0 ORDER BY created_date_time DESC LIMIT 1',
        [refKey, widget.beneficiaryId],
      );
      if (rows.isNotEmpty) {
        final r = rows.first;
        final s = r['form_json']?.toString() ?? '';
        if (s.isNotEmpty) {
          print('HBNC ChildDetails last ANC record for ${widget.beneficiaryId}: $s');
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map && decoded['form_data'] is Map) {
              final fd = Map<String, dynamic>.from(decoded['form_data'] as Map);
              final outcome = fd['delivery_outcome']?.toString();
              final number_of_children = fd['number_of_children']?.toString();
              final babyName = fd['baby1_name']?.toString();
              final babyGender = fd['baby1_gender']?.toString();
              final babyWeight = fd['baby1_weight']?.toString();
              if (mounted && outcome == 'Live birth') {
                final bloc = context.read<HbncVisitBloc>();
                bloc.add(NewbornDetailsChanged(field: 'babyCondition', value: 'alive'));
                if (babyName != null && babyName.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'babyName', value: babyName));
                }
                if (babyGender != null && babyGender.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'gender', value: babyGender));
                }
                if (babyWeight != null && babyWeight.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'weightAtBirth', value: babyWeight));
                }
              }
            }
          } catch (e) {
            print('HBNC ChildDetails parse error: $e');
          }
        } else {
          print('HBNC ChildDetails last ANC record for ${widget.beneficiaryId}: ${jsonEncode(r)}');
        }
      } else {
        print('HBNC ChildDetails no ANC record for ${widget.beneficiaryId}');
      }
    } catch (e) {
      print('HBNC ChildDetails load error: $e');
    }
  }

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
          padding: const EdgeInsets.all(8),
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ApiDropdown<String>(
                    labelText: t.babyConditionLabel,
                    items: const ['alive', 'death'],
                    getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                    value: s(c['babyCondition']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyCondition', value: val),
                    ),
                  ),
                  const Divider(height: 0,),
              
                  CustomTextField(
                    labelText: t.babyNameLabel,
                    hintText: t.babyNameLabel,
                    initialValue: s(c['babyName']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyName', value: val),
                    ),
                  ),
                  const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.babyGenderLabel,
                    hintText: t.babyGenderLabel,
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
                    hintText: t.newbornWeightGramLabel,
                    keyboardType: TextInputType.number,
                    initialValue: s(c['weightAtBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weightAtBirth', value: val),
                    ),
                  ),
                  const Divider(height: 0,),
              
                  CustomTextField(
                    labelText: t.newbornTemperatureLabel,
                    hintText: t.newbornTemperatureLabel,
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
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? 'Yes' : 'No',
                    value: yn(c['weightColorMatch']),
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
              
              
                  // Breastfeeding-related fields
                  ApiDropdown<String>(
                    labelText: t.exclusiveBreastfeedingStartedLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['exclusiveBreastfeedingStarted']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'exclusiveBreastfeedingStarted', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.firstBreastfeedTimingLabel,
                    items: const [
                      'within 30 minutes of birth',
                      'within 1 hour of birth',
                      'within 6 hours of birth',
                      'within 24 hours of birth',
                      'other',
                      'not breastfed'
                    ],
                    getLabel: (e) => e,
                    value: c['firstBreastfeedTiming'] ?? '',
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'firstBreastfeedTiming', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.howWasBreastfedLabel,
                    items: const [
                      'normal',
                      'forcefully',
                      'with weakness',
                      'could not breast feed but had to be fed with spoon',
                      'could neither breast feed nor take given by spoon'
                    ],
                    getLabel: (e) => e,
                    value: c['howWasBreastfed'] ?? '',
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'howWasBreastfed', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.firstFeedGivenAfterBirthLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['firstFeedGivenAfterBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'firstFeedGivenAfterBirth', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.adequatelyFedSevenToEightTimesLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['adequatelyFedSevenToEightTimes']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'adequatelyFedSevenToEightTimes', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.babyDrinkingLessMilkLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['babyDrinkingLessMilk']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyDrinkingLessMilk', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.breastfeedingStoppedLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['breastfeedingStopped']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'breastfeedingStopped', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.bloatedStomachOrFrequentVomitingLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['bloatedStomachOrFrequentVomiting']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'bloatedStomachOrFrequentVomiting', value: val),
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
              
                  // Conditional dropdown for navel tied by ASHA/ANM
                  if (c['bleedingUmbilicalCord'] == 'Yes')
                    ApiDropdown<String>(
                      labelText: 'Is navel tied with a clean thread by ASHA or ANM?',
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['navelTiedByAshaAnm']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'navelTiedByAshaAnm', value: val),
                      ),
                    ),
                  if (c['bleedingUmbilicalCord'] == 'Yes')
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
              
                  // New Question 1: Wiped with clean cloth
                  ApiDropdown<String>(
                    labelText: 'Has the baby been wiped with a clean dry cloth?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['wipedWithCleanCloth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'wipedWithCleanCloth', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 2: Kept warm
                  ApiDropdown<String>(
                    labelText: 'Has the baby been kept warm?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['keptWarm']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'keptWarm', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 3: Given bath
                  ApiDropdown<String>(
                    labelText: 'Has the baby been given a bath?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['givenBath']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'givenBath', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 4: Wrapped and placed near mother
                  ApiDropdown<String>(
                    labelText: 'Was the baby wrapped in a cloth and placed near the mother?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['wrappedAndPlacedNearMother']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'wrappedAndPlacedNearMother', value: val),
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
              
                  // Conditional dropdown for weight recorded in MCP card
                  if (c['mcpCardAvailable'] == 'Yes')
                    ApiDropdown<String>(
                      labelText: 'Is the weight of the new born baby recorded in the Mother Card Protection card?',
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['weightRecordedInMcpCard']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'weightRecordedInMcpCard', value: val),
                      ),
                    ),
                  if (c['mcpCardAvailable'] == 'Yes')
                    const Divider(height: 0,),
              
                  // Refer to hospital field
                  ApiDropdown<String>(
                    labelText: 'Refer to hospital?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['referToHospital']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'referToHospital', value: val),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

