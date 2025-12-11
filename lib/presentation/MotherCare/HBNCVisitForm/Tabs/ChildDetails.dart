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
  final int childTabCount;
  final int childIndex;
  const ChildDetailsTab({super.key, required this.beneficiaryId, this.childTabCount = 1, this.childIndex = 1});

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
              final idx = widget.childIndex <= 1 ? 1 : (widget.childIndex >= 3 ? 3 : widget.childIndex);
              final sfx = idx.toString();
              final babyName = fd['baby${sfx}_name']?.toString();
              final babyGender = fd['baby${sfx}_gender']?.toString();
              final babyWeight = fd['baby${sfx}_weight']?.toString();
              if (mounted && outcome == 'Live birth') {
                final bloc = context.read<HbncVisitBloc>();
                bloc.add(NewbornDetailsChanged(field: 'babyCondition', value: 'alive', childIndex: widget.childIndex));
                if (babyName != null && babyName.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'babyName', value: babyName, childIndex: widget.childIndex));
                }
                if (babyGender != null && babyGender.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'gender', value: babyGender, childIndex: widget.childIndex));
                }
                if (babyWeight != null && babyWeight.isNotEmpty) {
                  bloc.add(NewbornDetailsChanged(field: 'weightAtBirth', value: babyWeight, childIndex: widget.childIndex));
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
        final i = widget.childIndex - 1;
        final c = i >= 0 && i < state.newbornDetailsList.length ? state.newbornDetailsList[i] : const <String, dynamic>{};
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
                      NewbornDetailsChanged(field: 'babyCondition', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
              
                  CustomTextField(
                    labelText: t.babyNameLabel,
                    hintText: t.babyNameLabel,
                    initialValue: s(c['babyName']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyName', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: t.babyGenderLabel,
                    hintText: t.babyGenderLabel,
                    items: const ['Male', 'Female'],   // 👈 ONLY these two now
                    getLabel: (e) => e == 'Male' ? t.male : t.female,
                    value: s(c['gender']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(
                        field: 'gender',
                        value: val,
                        childIndex: widget.childIndex,
                      ),
                    ),
                  ),

                  const Divider(height: 0,),
              
                  CustomTextField(
                    labelText: t.newbornWeightGramLabel,
                    hintText: t.newbornWeightGramLabel,
                    keyboardType: TextInputType.number,
                    initialValue: s(c['weightAtBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weightAtBirth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
              
                  CustomTextField(
                    labelText: t.newbornTemperatureLabel,
                    hintText: t.newbornTemperatureLabel,
                    keyboardType: TextInputType.number,
                    initialValue: s(c['temperature']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'temperature', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.infantTemperatureUnitLabel,
                    items: const ['Celsius', 'Fahrenheit'],
                    getLabel: (e) => e == 'Celsius' ? t.temperatureUnitCelsius : t.temperatureUnitFahrenheit,
                    value: s(c['tempUnit']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'tempUnit', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.weightColorMatchLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? 'Yes' : 'No',
                    value: yn(c['weightColorMatch']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weightColorMatch', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.weighingScaleColorLabel,
                    items: const ['Green', 'Yellow', 'Red'],
                    getLabel: (e) => e == 'Green' ? t.colorGreen : (e == 'Yellow' ? t.colorYellow : t.colorRed),
                    value: s(c['weighingScaleColor']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weighingScaleColor', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'motherReportsTempOrChestIndrawing', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'exclusiveBreastfeedingStarted', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.firstBreastfeedTimingLabel,
                    items: const [
                      'Within 30 minutes of birth',
                      'Within 1 hour of birth',
                      'Within 6 hours of birth',
                      'Within 24 hours of birth',
                      'Other',
                      'Not breastfed'
                    ],
                    getLabel: (e) => e,
                    value: c['firstBreastfeedTiming'] ?? '',
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'firstBreastfeedTiming', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.howWasBreastfedLabel,
                    items: const [
                      'Normal',
                      'Forcefully',
                      'With weakness',
                      'Could not breast feed but had to be fed with spoon',
                      'Could neither breast feed nor take given by spoon'
                    ],
                    getLabel: (e) => e,
                    value: c['howWasBreastfed'] ?? '',
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'howWasBreastfed', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                   const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.firstFeedGivenAfterBirthLabel,
                    items: const ['First Breastfeeding','Water','Honey','Mishri Water / Sugar Syrup', 'Goat Milk','Cow Milk', 'Other' ],
                    getLabel: (e) => e,
                    value: s(c['firstFeedGivenAfterBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'firstFeedGivenAfterBirth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['firstFeedGivenAfterBirth'] == 'Other')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: CustomTextField(
                        labelText: 'Please enter other option',
                        initialValue: c['firstFeedOther'] ?? '',
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(field: 'firstFeedOther', value: val, childIndex: widget.childIndex),
                        ),
                      ),
                    ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.adequatelyFedSevenToEightTimesLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['adequatelyFedSevenToEightTimes']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'adequatelyFedSevenToEightTimes', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['adequatelyFedSevenToEightTimes'] == 'No')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ApiDropdown<String>(
                        labelText: 'Counselling/Advise needed?',
                        items: const ['Yes', 'No'],
                        getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                        value: yn(c['adequatelyFedCounseling']),
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(field: 'adequatelyFedCounseling', value: val, childIndex: widget.childIndex),
                        ),
                      ),
                    ),
                     const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.babyDrinkingLessMilkLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['babyDrinkingLessMilk']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyDrinkingLessMilk', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.breastfeedingStoppedLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['breastfeedingStopped']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'breastfeedingStopped', value: val, childIndex: widget.childIndex),
                    ),),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.bloatedStomachOrFrequentVomitingLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['bloatedStomachOrFrequentVomiting']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'bloatedStomachOrFrequentVomiting', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'bleedingUmbilicalCord', value: val, childIndex: widget.childIndex),
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
                        NewbornDetailsChanged(field: 'navelTiedByAshaAnm', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'pusInNavel', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.routineCareDoneLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['routineCareDone']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'routineCareDone', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'wipedWithCleanCloth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 2: Kept warm
                  ApiDropdown<String>(
                    labelText: 'Has the baby kept warm?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['keptWarm']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'keptWarm', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 3: Given bath
                  ApiDropdown<String>(
                    labelText: 'Has the baby given a bath?',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['givenBath']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'givenBath', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  // New Question 4: Wrapped and placed near mother
                  ApiDropdown<String>(
                    labelText: 'Whether the baby was wrapped in a cloth and placed near the mother ? *',
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['wrappedAndPlacedNearMother']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'wrappedAndPlacedNearMother', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
                  ApiDropdown<String>(
                    labelText: t.breathingRapidLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['breathingRapid']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'breathingRapid', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.lethargicLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['lethargic']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'lethargic', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.congenitalAbnormalitiesLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['congenitalAbnormalities']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'congenitalAbnormalities', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.eyesNormalLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['eyesNormal']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'eyesNormal', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['eyesNormal'] == 'No')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ApiDropdown<String>(
                        labelText: 'Select type of eye problem',
                        items: const ['Swelling', 'Oozing pus'],
                        getLabel: (e) => e,
                        value: c['eyesProblemType'],
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(field: 'eyesProblemType', value: val, childIndex: widget.childIndex),
                        ),
                      ),
                    ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.eyesSwollenOrPusLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['eyesSwollenOrPus']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'eyesSwollenOrPus', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'skinFoldRedness', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.newbornJaundiceLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['jaundice']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'jaundice', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.pusBumpsOrBoilLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['pusBumpsOrBoil']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'pusBumpsOrBoil', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.newbornSeizuresLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['seizures']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'seizures', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'cryingConstantlyOrLessUrine', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['cryingConstantlyOrLessUrine'] == 'Yes')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ApiDropdown<String>(
                        labelText: 'Counselling/Advise needed for breastfeeding?',
                        items: const ['Yes', 'No'],
                        getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                        value: yn(c['cryingCounseling']),
                        onChanged: (val) => context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(field: 'cryingCounseling', value: val, childIndex: widget.childIndex),
                        ),
                      ),
                    ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.cryingSoftlyLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['cryingSoftly']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'cryingSoftly', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.stoppedCryingLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['stoppedCrying']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'stoppedCrying', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.newbornReferredByAshaLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['referredByASHA']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'referredByASHA', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['referredByASHA'] == 'Yes') ...[
                    const SizedBox(height: 8),
                    ApiDropdown<String>(
                      labelText: 'Referred by ASHA to',
                      items: const ['HSC', 'APHC', 'PHC', 'CHC', 'RH', 'SDH', 'DH'],
                      getLabel: (e) => e,
                      value: s(c['referredByASHAFacility']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'referredByASHAFacility', value: val, childIndex: widget.childIndex),
                      ),
                    ),
                  ],
                  const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.birthRegisteredLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthRegistered']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthRegistered', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.birthCertificateIssuedLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthCertificateIssued']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthCertificateIssued', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.birthDoseVaccinationLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthDoseVaccination']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthDoseVaccination', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              
              
                  ApiDropdown<String>(
                    labelText: t.mcpCardAvailableLabel,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['mcpCardAvailable']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'mcpCardAvailable', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                                      const Divider(height: 0,),
              

                  if (c['mcpCardAvailable'] == 'Yes')
                    ApiDropdown<String>(
                      labelText: 'Is the weight of the new born baby recorded in the Mother Card Protection card?',
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['weightRecordedInMcpCard']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'weightRecordedInMcpCard', value: val, childIndex: widget.childIndex),
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
                      NewbornDetailsChanged(field: 'referToHospital', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['referToHospital'] == 'Yes') ...[
                    const SizedBox(height: 8),
                    ApiDropdown<String>(
                      labelText: 'Refer to',
                      items: const ['PHC', 'CHC', 'RH', 'SDH', 'DH', 'MCH'],
                      getLabel: (e) => e,
                      value: s(c['referToHospitalFacility']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'referToHospitalFacility', value: val, childIndex: widget.childIndex),
                      ),
                    ),
                  ],
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

