import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/widgets/DatePicker/timepicker.dart';

class ChildDetailsTab extends StatefulWidget {
  final String beneficiaryId;
  final int childTabCount;
  final int childIndex;
  const ChildDetailsTab({super.key, required this.beneficiaryId, this.childTabCount = 1, this.childIndex = 1});

  // Create keys for fields that have validation
  static final Map<String, GlobalKey> fieldKeys = {
    'babyCondition': GlobalKey(),
    'babyName': GlobalKey(),
    'gender': GlobalKey(),
    'weightAtBirth': GlobalKey(),
    'temperature': GlobalKey(),
    'temperatureUnit': GlobalKey(),
    'breathingRate': GlobalKey(),
    'breastfeeding': GlobalKey(),
    'skinToSkin': GlobalKey(),
    'bcgGiven': GlobalKey(),
    'opv0Given': GlobalKey(),
    'hepatitisB0Given': GlobalKey(),
    'vitaminKGiven': GlobalKey(),
    'eyeOintmentGiven': GlobalKey(),
    'referralNeeded': GlobalKey(),
    'referralPlace': GlobalKey(),
    'referralReason': GlobalKey(),
  };

  @override
  State<ChildDetailsTab> createState() => _ChildDetailsTabState();
}

class _ChildDetailsTabState extends State<ChildDetailsTab> {
  String? _breastfeedingTime;
  @override
  void initState() {
    super.initState();
    _loadLastAncForm();
  }
  void _validateTemperature({
    required BuildContext context,
    required String? tempValue,
    required String? unit,
  }) {
    if (tempValue == null || tempValue.isEmpty || unit == null) return;
    final l10n = AppLocalizations.of(context);

    final temp = double.tryParse(tempValue);
    if (temp == null) return;

    bool isValid = true;

    if (unit == 'Celsius') {
      isValid = temp >= 36 && temp <= 37;
    } else if (unit == 'Fahrenheit') {
      isValid = temp >= 96 && temp <= 99;
    }

    if (!isValid) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(

          surfaceTintColor: Colors.white,
          title: Text(
            l10n?.attention ?? 'Attention!',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n?.hospitalReferMsg ?? 'Please refer the child to nearby hospital.',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n?.okayLabel ?? 'OKAY',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
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
            if (decoded is Map && decoded['anc_form'] is Map) {
              final fd = Map<String, dynamic>.from(decoded['anc_form'] as Map);
              final outcome = fd['delivery_outcome']?.toString();

              // Check for children_arr first (new structure)
              final childrenArr = fd['children_arr'] as List?;
              String? babyName, babyGender, babyWeight;

              if (childrenArr != null && childrenArr.isNotEmpty) {
                final childIndex = widget.childIndex - 1; // Convert to 0-based index
                if (childIndex < childrenArr.length) {
                  final childData = childrenArr[childIndex] as Map<String, dynamic>?;
                  if (childData != null) {
                    babyName = childData['name']?.toString();
                    babyGender = childData['gender']?.toString();
                    babyWeight = childData['weight_at_birth']?.toString();
                    print('👶 Loaded child data from children_arr for child ${widget.childIndex}: name=$babyName, gender=$babyGender, weight=$babyWeight');
                  }
                }
              } else {
                // Fallback to old field structure for backward compatibility
                final idx = widget.childIndex <= 1 ? 1 : (widget.childIndex >= 3 ? 3 : widget.childIndex);
                final sfx = idx.toString();
                babyName = fd['baby${sfx}_name']?.toString();
                babyGender = fd['baby${sfx}_gender']?.toString();
                babyWeight = fd['baby${sfx}_weight']?.toString();
                print('👶 Loaded child data from old fields for child ${widget.childIndex}: name=$babyName, gender=$babyGender, weight=$babyWeight');
              }

              if (mounted && (outcome == 'Live birth' || outcome == 'live_birth')) {
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

        return BlocConsumer<HbncVisitBloc, HbncVisitState>(
          listenWhen: (previous, current) =>
          previous.newbornDetailsList != current.newbornDetailsList,
          listener: (context, state) {
            print('ChildDetails (from state): ${state.newbornDetailsList}');
          },
          builder: (context, state) {
            final condition = s(c['babyCondition']);

            final baseChildren = <Widget>[
              ApiDropdown<String>(
                key: ChildDetailsTab.fieldKeys['babyCondition'],
                labelText: "${t.babyConditionLabel} *",
                items: ['alive', 'death'],
                validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                getLabel: (e) => e == 'alive' ? t.alive : t.dead,
                value: condition,
                onChanged: (val) => context.read<HbncVisitBloc>().add(
                  NewbornDetailsChanged(
                    field: 'babyCondition',
                    value: val,
                    childIndex: widget.childIndex,
                  ),
                ),
              ),
              const Divider(height: 0),
            ];

            // If baby is marked as death, show only the babyCondition field
            if (condition == 'death') {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: baseChildren,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...baseChildren,

                  CustomTextField(
                    key: ChildDetailsTab.fieldKeys['babyName'],
                    labelText: "${t.babyNameLabel} *",
                    hintText: t.babyNameLabel,
                    validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                    initialValue: s(c['babyName']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyName', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    key: ChildDetailsTab.fieldKeys['gender'],
                    labelText: "${t.babyGenderLabel} *",
                    hintText: t.babyGenderLabel,
                    validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                    items: const ['Male', 'Female', 'Transgender'],
                    getLabel: (s) {
                      switch (s) {
                        case 'Male':
                          return t.genderMale;
                        case 'Female':
                          return t.genderFemale;
                        case 'Transgender':
                          return t.transgender;
                        default:
                          return s;
                      }
                    },
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
                    key: ChildDetailsTab.fieldKeys['weightAtBirth'],
                    labelText: "${t.newbornWeightGramLabel} *",
                    hintText: t.newbornWeightGramLabel,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                    initialValue: s(c['weightAtBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weightAtBirth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  CustomTextField(
                    key: ChildDetailsTab.fieldKeys['temperature'],
                    labelText: "${t.newbornTemperatureLabel} *",
                    hintText: t.hintTemp,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? t.requiredField : null,
                    initialValue: s(c['temperature']),
                    onChanged: (val) {
                      context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(
                          field: 'temperature',
                          value: val,
                          childIndex: widget.childIndex,
                        ),
                      );

                      if (val.length >= 2) {
                        _validateTemperature(
                          context: context,
                          tempValue: val,
                          unit: s(c['tempUnit']),
                        );
                      }
                    },
                  ),

                  const Divider(height: 0,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: t.infantTemperatureUnitLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black, // label color
                                ),
                              ),
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red, // 🔴 red asterisk
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Celsius',
                            groupValue: s(c['tempUnit']),
                            onChanged: (val) {
                              context.read<HbncVisitBloc>().add(
                                NewbornDetailsChanged(
                                  field: 'tempUnit',
                                  value: val,
                                  childIndex: widget.childIndex,
                                ),
                              );

                              _validateTemperature(
                                context: context,
                                tempValue: s(c['temperature']),
                                unit: val,
                              );
                            },
                          ),
                          Text(t.temperatureUnitCelsius),

                          const SizedBox(width: 24),

                          Radio<String>(
                            value: 'Fahrenheit',
                            groupValue: s(c['tempUnit']),
                            onChanged: (val) {
                              context.read<HbncVisitBloc>().add(
                                NewbornDetailsChanged(
                                  field: 'tempUnit',
                                  value: val,
                                  childIndex: widget.childIndex,
                                ),
                              );

                              _validateTemperature(
                                context: context,
                                tempValue: s(c['temperature']),
                                unit: val,
                              );
                            },
                          ),
                          Text(t.temperatureUnitFahrenheit),
                        ],
                      ),
                    ],
                  ),


                  const Divider(height: 0,),
                  ApiDropdown<String>(
                    labelText: "${t.weightColorMatchLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['weightColorMatch']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weightColorMatch', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.weighingScaleColorLabel} *",
                    items: const ['Green', 'Yellow', 'Red'],
                    getLabel: (e) => e == 'Green' ? t.colorGreen : (e == 'Yellow' ? t.colorYellow : t.colorRed),
                    value: s(c['weighingScaleColor']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'weighingScaleColor', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.motherReportsTempOrChestIndrawingLabel} *",
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
                    labelText: "${t.exclusiveBreastfeedingStartedLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['exclusiveBreastfeedingStarted']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'exclusiveBreastfeedingStarted', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.firstBreastfeedTimingLabel} *",
                    hintText: t.selectOption,
                    items: const [
                      'Within 30 minutes of birth',
                      'Within 1 hour of birth',
                      'Within 6 hours of birth',
                      'Within 24 hours of birth',
                      'Other',
                      'Not breastfed'
                    ],
                    getLabel: (s) {
                      switch (s) {
                        case 'Within 30 minutes of birth':
                          return t.within30Minutes;
                        case 'Within 1 hour of birth':
                          return t.within1Hour;
                        case 'Within 6 hours of birth':
                          return t.within6Hours;
                        case 'Within 24 hours of birth':
                          return t.within24Hours;
                        case 'Other':
                          return t.other;
                        case 'Not breastfed':
                          return t.notBreastfed;
                        default:
                          return s;
                      }
                    },
                    value: c['firstBreastfeedTiming'],
                    onChanged: (val) {
                      context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(
                          field: 'firstBreastfeedTiming',
                          value: val,
                          childIndex: widget.childIndex,
                        ),
                      );

                      if (val != 'Other') {
                        context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(
                            field: 'firstBreastfeedCustomTime',
                            value: null, // or ''
                            childIndex: widget.childIndex,
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 0,),
                  if (c['firstBreastfeedTiming'] == 'Other')

                    CustomTextField(
                      labelText: t.breastfeedingTime,
                      hintText: 'hh:mm',
                      keyboardType: TextInputType.number,
                        initialValue: c['firstBreastfeedCustomTime'] ?? '',
                      onChanged: (val) {}
                    ),
                  const Divider(height: 0,),

                  if (c['firstBreastfeedTiming'] != 'Not breastfed')
                    ApiDropdown<String>(
                      labelText: "${t.howWasBreastfedLabel} *",
                      hintText: t.selectOption,
                      items: const [
                        'Normal',
                        'Forcefully',
                        'With weakness',
                        'Could not breast feed but had to be fed with spoon',
                        'Could neither breast feed nor take given by spoon'
                      ],
                      getLabel: (s) {
                        switch (s) {
                          case 'Normal':
                            return t.normal;
                          case 'Forcefully':
                            return t.forcefully;
                          case 'With weakness':
                            return t.withWeakness;
                          case 'Could not breast feed but had to be fed with spoon':
                            return t.couldNotBreastfeedButSpoon;
                          case 'Could neither breast feed nor take given by spoon':
                            return t.couldNeitherBreastfeedNorSpoon;
                          default:
                            return s;
                        }
                      },
                      value: c['howWasBreastfed'],
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(
                          field: 'howWasBreastfed',
                          value: val,
                          childIndex: widget.childIndex,
                        ),
                      ),
                    ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.firstFeedGivenAfterBirthLabel} *",
                    hintText: t.selectOption,
                    items: const ['First Breastfeeding','Water','Honey','Mishri Water / Sugar Syrup', 'Goat Milk','Cow Milk', 'Other' ],
                    getLabel: (s) {
                      switch (s) {
                        case 'First Breastfeeding':
                          return t.firstBreastfeeding;
                        case 'Water':
                          return t.water;
                        case 'Honey':
                          return t.honey;
                        case 'Mishri Water / Sugar Syrup':
                          return t.mishriWater;
                        case 'Goat Milk':
                          return t.goatMilk;
                        case 'Cow Milk':
                          return t.cowMilk;
                        case 'Other':
                          return t.other;
                        default:
                          return s;
                      }
                    },
                    value: s(c['firstFeedGivenAfterBirth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'firstFeedGivenAfterBirth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                    const Divider(height: 0,),
                  if (c['firstFeedGivenAfterBirth'] == 'Other')
                    CustomTextField(
                      labelText: "${t.enter_other_feeding_option} *",
                      initialValue: t.enter_other_feeding_option,
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'firstFeedOther', value: val, childIndex: widget.childIndex),
                      ),
                    ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.adequatelyFedSevenToEightTimesLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['adequatelyFedSevenToEightTimes']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'adequatelyFedSevenToEightTimes', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                    const Divider(height: 0,),
                  if (c['adequatelyFedSevenToEightTimes'] == 'No')
                    ApiDropdown<String>(
                      labelText: "${t.counsellingAdviceNeeded} *",
                      items: const ['Yes', 'No'],
                      getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                      value: yn(c['adequatelyFedCounseling']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'adequatelyFedCounseling', value: val, childIndex: widget.childIndex),
                      ),
                    ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.babyDrinkingLessMilkLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['babyDrinkingLessMilk']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'babyDrinkingLessMilk', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.breastfeedingStoppedLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['breastfeedingStopped']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'breastfeedingStopped', value: val, childIndex: widget.childIndex),
                    ),),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.bloatedStomachOrFrequentVomitingLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['bloatedStomachOrFrequentVomiting']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'bloatedStomachOrFrequentVomiting', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
                   ApiDropdown<String>(
                    labelText: "${t.bleedingUmbilicalCordLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['bleedingUmbilicalCord']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'bleedingUmbilicalCord', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  if (c['bleedingUmbilicalCord'] == 'Yes')
                    ApiDropdown<String>(
                      labelText: "${t.is_navel_tied_with_thread} *",
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
                    labelText: "${t.pusInNavelLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['pusInNavel']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'pusInNavel', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.routineCareDoneLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['routineCareDone']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'routineCareDone', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText:"${t.babyWipedWithCleanCloth} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['wipedWithCleanCloth']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'wipedWithCleanCloth', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.is_child_kept_warm} *",
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
                    labelText: "${t.babyGivenBath} *",
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
                    labelText: "${t.babyWrappedAndPlacedNearMother} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['wrappedAndPlacedNearMother']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'wrappedAndPlacedNearMother', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  ApiDropdown<String>(
                    labelText: "${t.breathingRapidLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['breathingRapid']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'breathingRapid', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.lethargicLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['lethargic']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'lethargic', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.congenitalAbnormalitiesLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['congenitalAbnormalities']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'congenitalAbnormalities', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  if (c['congenitalAbnormalities'] == 'Yes') ...[
                    ApiDropdown<String>(
                      labelText: "Select abnormality *",
                      hintText: t.selectOption,
                      items: const ['Curved limbs', 'Clift lip / palate', 'Other'],
                      getLabel: (e) => e,
                      value: c['congenitalAbnormalityType'],
                      onChanged: (val) {
                        context.read<HbncVisitBloc>().add(
                          NewbornDetailsChanged(
                            field: 'congenitalAbnormalityType',
                            value: val,
                            childIndex: widget.childIndex,
                          ),
                        );

                        if (val != 'Other') {

                          context.read<HbncVisitBloc>().add(
                            NewbornDetailsChanged(
                              field: 'congenitalAbnormalityOther',
                              value: '',
                              childIndex: widget.childIndex,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                   const Divider(height: 0,),
                  if (c['congenitalAbnormalityType'] == 'Other')
                    CustomTextField(
                      labelText: "Please enter abnormality",
                      hintText: "Please enter abnormality",
                      initialValue: c['congenitalAbnormalityOther'] ?? '',
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(
                          field: 'congenitalAbnormalityOther',
                          value: val,
                          childIndex: widget.childIndex,
                        ),
                      ),
                    ),
                  if (c['congenitalAbnormalities'] == 'Yes')
                    const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.eyesNormalLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['eyesNormal']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'eyesNormal', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
                  if (c['eyesNormal'] == 'No')

                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ApiDropdown<String>(
                      labelText:"${t.selectEyeProblemTypeLabel} *",
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
                    labelText: "${t.eyesSwollenOrPusLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['eyesSwollenOrPus']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'eyesSwollenOrPus', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText:"${ t.skinFoldRednessLabel} *",
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
                    labelText: "${t.newbornJaundiceLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['jaundice']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'jaundice', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.pusBumpsOrBoilLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['pusBumpsOrBoil']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'pusBumpsOrBoil', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
                  ApiDropdown<String>(
                    labelText: "${t.newbornSeizuresLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['seizures']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'seizures', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
                  ApiDropdown<String>(
                    labelText: "${t.cryingConstantlyOrLessUrineLabel} *",
                    labelMaxLines: 3,
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['cryingConstantlyOrLessUrine']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'cryingConstantlyOrLessUrine', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                    const Divider(height: 0,),
                  if (c['cryingConstantlyOrLessUrine'] == 'Yes')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ApiDropdown<String>(
                        labelText: "${t.counsellingBreastfeeding} *",
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
                    labelText: "${t.cryingSoftlyLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['cryingSoftly']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'cryingSoftly', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.stoppedCryingLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['stoppedCrying']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'stoppedCrying', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.newbornReferredByAshaLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['referredByASHA']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'referredByASHA', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),
                  if (c['referredByASHA'] == 'Yes') ...[

                    ApiDropdown<String>(
                      labelText:"${t.referredByASHA} *",
                      items:  [t.hsc,t.aphc,t.phc,t.chc,t.rhLabel,t.sdh,t.dhLabel],
                      getLabel: (e) => e,
                      value: s(c['referredByASHAFacility']),
                      onChanged: (val) => context.read<HbncVisitBloc>().add(
                        NewbornDetailsChanged(field: 'referredByASHAFacility', value: val, childIndex: widget.childIndex),
                      ),
                    ),
                  ],
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.birthRegisteredLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthRegistered']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthRegistered', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.birthCertificateIssuedLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthCertificateIssued']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthCertificateIssued', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),


                  ApiDropdown<String>(
                    labelText: "${t.birthDoseVaccinationLabel} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['birthDoseVaccination']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'birthDoseVaccination', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  const Divider(height: 0,),

                  if (c['birthDoseVaccination'] == 'Yes') ...[
                    VaccineTable(),
                    Divider(height: 0,),
                    SizedBox(height: 5,)
                  ],
                  ApiDropdown<String>(
                    labelText:"${ t.mcpCardAvailableLabel} *",
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
                      labelText: "${t.babyWeightRecordedInMPC} *",
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
                    labelText: "${t.refer_to_hospital} *",
                    items: const ['Yes', 'No'],
                    getLabel: (e) => e == 'Yes' ? t.yes : t.no,
                    value: yn(c['referToHospital']),
                    onChanged: (val) => context.read<HbncVisitBloc>().add(
                      NewbornDetailsChanged(field: 'referToHospital', value: val, childIndex: widget.childIndex),
                    ),
                  ),
                  if (c['referToHospital'] == 'Yes') ...[
                    const Divider(height: 0,),
                    ApiDropdown<String>(
                      labelText: "${t.referToLabel} *",
                      items:  [
                        t.visitTypePhc,
                        t.chc,
                        t.rhLabel,
                        t.sdh,
                        t.dhLabel,
                        t.mchLabel,
                      ],
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
            );
          },
        );
      },

    );

  }
}

class VaccineTable extends StatefulWidget {
  const VaccineTable({super.key});

  @override
  State<VaccineTable> createState() => _VaccineTableState();
}

class _VaccineTableState extends State<VaccineTable> {
  final vaccines = ['BCG', 'OPV-0', 'Hepatitis-B', 'Vit-K'];
  final Map<String, bool> _checked = {};

  @override
  void initState() {
    super.initState();
    for (var v in vaccines) {
      _checked[v] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
      },
      children: [
        /// Header
        const TableRow(
          children: [
            _HeaderCell('Type of Vaccine'),
            _HeaderCell('Date'),
            _HeaderCell('Age'),
            _HeaderCell('Dose Given'),
          ],
        ),

        /// Rows
        ...vaccines.map(
              (vaccine) => TableRow(
            children: [
              _TextCell(vaccine),

              const _TextCell(
                'dd-mm-yyyy',
                color: Colors.grey,
              ),

              /// Age
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 28, // 👈 reduced
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Days',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              /// Checkbox
              Center(
                child: Checkbox(
                  value: _checked[vaccine],
                  activeColor: AppColors.primary,
                  visualDensity: VisualDensity.compact, // 👈 reduces space
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _checked[vaccine] = val ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------- Cells ----------///

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4), // 👈 reduced
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  final String text;
  final Color? color;

  const _TextCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ),
    );
  }
}


