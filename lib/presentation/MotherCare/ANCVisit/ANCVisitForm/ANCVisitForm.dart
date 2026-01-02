import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'dart:convert';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/Database/tables/followup_form_data_table.dart';
import 'bloc/anvvisitform_bloc.dart';

import 'package:medixcel_new/core/widgets/MultiSelect/MultiSelect.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/core/widgets/SuccessDialogbox/SuccessDialogbox.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';

class Ancvisitform extends StatefulWidget {
  final Map<String, dynamic>? beneficiaryData;

  const Ancvisitform({super.key, this.beneficiaryData});

  @override
  State<Ancvisitform> createState() => _AncvisitformState();
}

class _AncvisitformState extends State<Ancvisitform> {
  late final AnvvisitformBloc _bloc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _prevLmpFromEc;
  DateTime? _lastTd1DateFromDb;

  int _childrenCount(String value) {
    switch (value) {
      case 'One Child':
        return 1;
      case 'Twins':
        return 2;
      case 'Triplets':
        return 3;
      default:
        return 0;
    }
  }

  @override
  @override
  void initState() {
    super.initState();

    String? beneficiaryId = widget.beneficiaryData?['BeneficiaryID'] as String?;
    String? householdRefKey = widget.beneficiaryData?['hhId'] as String?;

    if (beneficiaryId == null || beneficiaryId.isEmpty) {
      beneficiaryId = widget.beneficiaryData?['unique_key']?.toString();
      if (beneficiaryId == null || beneficiaryId.isEmpty) {
        final raw = widget.beneficiaryData?['_rawRow'] as Map<String, dynamic>?;
        beneficiaryId = raw?['unique_key']?.toString();
      }
    }

    if (householdRefKey == null || householdRefKey.isEmpty) {
      final raw = widget.beneficiaryData?['_rawRow'] as Map<String, dynamic>?;
      householdRefKey = raw?['household_ref_key']?.toString();
    }

    if (beneficiaryId == null ||
        beneficiaryId.isEmpty ||
        householdRefKey == null ||
        householdRefKey.isEmpty) {
      print(
        'Missing parameters for ANC form. BeneficiaryID=$beneficiaryId, hhId=$householdRefKey',
      );
    }

    _bloc = AnvvisitformBloc(
      beneficiaryId: beneficiaryId ?? '',
      householdRefKey: householdRefKey ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeForm();
      }
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  // Helper to find and scroll to the first error field
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final errorField = _findFirstErrorField();
      if (errorField != null && errorField.context != null) {
        Scrollable.ensureVisible(
          errorField.context!,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Helper method to find the first field with an error
  FormFieldState<dynamic>? _findFirstErrorField() {
    FormFieldState<dynamic>? firstErrorField;
    final formContext = _formKey.currentContext;

    if (formContext == null) return null;

    void visitElement(Element element) {
      if (firstErrorField != null) return;

      if (element.widget is FormField) {
        final formField = element as StatefulElement;
        final field = formField.state as FormFieldState<dynamic>?;

        if (field?.hasError == true) {
          firstErrorField = field;
          return;
        }
      }

      element.visitChildren(visitElement);
    }

    formContext.visitChildElements(visitElement);
    return firstErrorField;
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date $dateString: $e');
      return null;
    }
  }

  void _updateFormWithData(Map<String, dynamic> formData) {
    // Basic information
    // _bloc.add(VisitTypeChanged(formData['visit_type'] ?? '')); // Don't auto-fill visit type
    _bloc.add(
      PlaceOfAncChanged(formData['place_of_anc'] ?? ''),
    ); // Don't auto-fill place of ANC
    _bloc.add(
      DateOfInspectionChanged(_parseDate(formData['date_of_inspection'])),
    );
    _bloc.add(HouseNumberChanged(formData['house_number'] ?? ''));
    _bloc.add(WomanNameChanged(formData['woman_name'] ?? ''));
    _bloc.add(HusbandNameChanged(formData['husband_name'] ?? ''));
    _bloc.add(RchNumberChanged(formData['rch_number'] ?? ''));

    // Pregnancy information
    // Intentionally not auto-filling LMP/EDD/weeks from previous forms

    // Medical information
    _bloc.add(WeightChanged(formData['weight']?.toString() ?? ''));
    _bloc.add(SystolicChanged(formData['systolic']?.toString() ?? ''));
    _bloc.add(DiastolicChanged(formData['diastolic']?.toString() ?? ''));
    _bloc.add(HemoglobinChanged(formData['hemoglobin']?.toString() ?? ''));

    // Checkbox and boolean fields - convert to Yes/No strings
    if (formData['is_breast_feeding'] != null) {
      final isBreastFeeding =
          formData['is_breast_feeding'] == true ||
          formData['is_breast_feeding'] == 'true';
      _bloc.add(IsBreastFeedingChanged(isBreastFeeding ? 'Yes' : 'No'));
    }

    if (formData['high_risk'] != null) {
      final v = formData['high_risk'];
      final s = v.toString().toLowerCase();
      final yesNo = (v == true || s == 'yes' || s == 'true' || s == '1')
          ? 'Yes'
          : 'No';
      _bloc.add(HighRiskChanged(yesNo));
    }

    if (formData['selected_risks'] is List) {
      final risks = List<String>.from(
        (formData['selected_risks'] as List).map((e) => e.toString()),
      );
      final hr = formData['high_risk'];
      final hrStr = (hr?.toString() ?? '').toLowerCase();
      final isHigh =
          hr == true || hrStr == 'yes' || hrStr == 'true' || hrStr == '1';
      if (isHigh) {
        _bloc.add(SelectedRisksChanged(risks));
      }
    }

    // TD Vaccination dates
    _bloc.add(Td1DateChanged(_parseDate(formData['td1_date'])));
    _bloc.add(Td2DateChanged(_parseDate(formData['td2_date'])));
    _bloc.add(TdBoosterDateChanged(_parseDate(formData['td_booster_date'])));

    // Other fields
    _bloc.add(FolicAcidTabletsChanged(formData['folic_acid_tablets'] ?? ''));
    _bloc.add(
      CalciumVitaminD3TabletsChanged(formData['calcium_vitamin_tablets'] ?? ''),
    );

    if (formData['pre_existing_diseases'] != null) {
      final diseases = List<String>.from(formData['pre_existing_diseases']);
      _bloc.add(PreExistingDiseasesChanged(diseases));

      if (formData['other_disease'] != null) {
        _bloc.add(OtherDiseaseChanged(formData['other_disease']));
      }
    }
  }

  int _calculateWeeksOfPregnancy(DateTime? lmpDate) {
    if (lmpDate == null) return 0;
    final base = _bloc.state.dateOfInspection ?? DateTime.now();
    final difference = base.difference(lmpDate).inDays;
    // Add 1 to account for the first week of pregnancy
    return (difference / 7).floor() + 1;
  }

  int _fullYearsBetween(DateTime a, DateTime b) {
    final start = a.isBefore(b) ? a : b;
    final end = a.isBefore(b) ? b : a;
    int years = end.year - start.year;
    final anniversary = DateTime(end.year, start.month, start.day);
    if (anniversary.isAfter(end)) years -= 1;
    return years;
  }

  Future<void> _initializeForm() async {
    final data = widget.beneficiaryData;
    if (data == null) return;

    String? houseNo;

    // 1. First try to get names directly from the passed data
    final womanName = data['Name']?.toString();
    final husbandName =
        data['Husband']?.toString() ?? data['husbandName']?.toString();

    if (womanName != null && womanName.isNotEmpty) {
      _bloc.add(WomanNameChanged(womanName));
    }
    if (husbandName != null && husbandName.isNotEmpty) {
      _bloc.add(HusbandNameChanged(husbandName));
    }

    // 2. Fetch and set house number from beneficiary data
    try {
      final householdRefKey =
          data['hhId']?.toString() ??
          (data['_rawRow'] is Map
              ? (data['_rawRow'] as Map)['household_ref_key']?.toString()
              : null);

      if (householdRefKey != null && householdRefKey.isNotEmpty) {
        final db = await DatabaseProvider.instance.database;
        final result = await db.query(
          'beneficiaries_new',
          where: 'household_ref_key = ?',
          whereArgs: [householdRefKey],
        );

        if (result.isNotEmpty) {
          for (final row in result) {
            try {
              final beneficiaryInfo =
                  jsonDecode(row['beneficiary_info'] as String? ?? '{}')
                      as Map<String, dynamic>;
              if (beneficiaryInfo.containsKey('houseNo') &&
                  beneficiaryInfo['houseNo'] != null) {
                _bloc.add(
                  HouseNumberChanged(beneficiaryInfo['houseNo'].toString()),
                );
                break; // Found house number, no need to check other records
              }
            } catch (e) {
              print('Error parsing beneficiary info: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching house number: $e');
    }

    try {
      Map<String, dynamic>? beneficiaryInfo = {};

      if (data?['beneficiary_info'] is String) {
        try {
          beneficiaryInfo = jsonDecode(data!['beneficiary_info']);
        } catch (e) {
          print('Error parsing beneficiary_info JSON: $e');
        }
      } else if (data?['beneficiary_info'] is Map) {
        beneficiaryInfo = Map<String, dynamic>.from(data!['beneficiary_info']);
      }

      // If not found in beneficiary_info, try _rawRow
      if ((beneficiaryInfo == null || beneficiaryInfo.isEmpty) &&
          data?['_rawRow'] != null) {
        final rawRow = data!['_rawRow'];
        if (rawRow is String) {
          try {
            final rawData = jsonDecode(rawRow);
            beneficiaryInfo = rawData['beneficiary_info'] is Map
                ? Map<String, dynamic>.from(rawData['beneficiary_info'])
                : {};
          } catch (e) {
            print('Error parsing _rawRow JSON: $e');
          }
        } else if (rawRow is Map) {
          beneficiaryInfo = rawRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(rawRow['beneficiary_info'])
              : {};
        }
      }

      // Process LMP date
      final lmpDateStr = beneficiaryInfo?['lmp']?.toString();
      if (lmpDateStr != null && lmpDateStr.isNotEmpty) {
        try {
          final lmpDate = DateTime.parse(lmpDateStr);
          _bloc.add(LmpDateChanged(lmpDate));

          // Calculate and set weeks of pregnancy
          final weeksPregnant = _calculateWeeksOfPregnancy(lmpDate);
          _bloc.add(WeeksOfPregnancyChanged(weeksPregnant.toString()));

          print('✅ Set LMP date from beneficiary data: $lmpDate');
          print('✅ Calculated weeks of pregnancy: $weeksPregnant');
        } catch (e) {
          print('Error parsing LMP date "$lmpDateStr": $e');
        }
      }

      final eddDateStr = beneficiaryInfo?['edd']?.toString();
      if (eddDateStr != null && eddDateStr.isNotEmpty) {
        try {
          final eddDate = DateTime.parse(eddDateStr);
          _bloc.add(EddDateChanged(eddDate));
          print('✅ Set EDD date from beneficiary data: $eddDate');
        } catch (e) {
          print('Error parsing EDD date "$eddDateStr": $e');
        }
      }
    } catch (e) {
      print('⚠️ Error processing beneficiary data: $e');
    }

    // Set visit number
    try {
      final dynamic rawVisitCountEarly = data?['visitCount'];
      int visitCountEarly = 0;
      if (rawVisitCountEarly is int) {
        visitCountEarly = rawVisitCountEarly;
      } else if (rawVisitCountEarly is String) {
        visitCountEarly = int.tryParse(rawVisitCountEarly) ?? 0;
      }
      final nextVisitEarly = (visitCountEarly + 1);
      _bloc.add(VisitNumberChanged(nextVisitEarly.toString()));
    } catch (e) {
      print('⚠️ Early visit number setup failed: $e');
    }

    // Set beneficiary ID in the bloc if available
    if (data != null) {
      // Log the raw data to verify it's coming through correctly
      print('🔍 RAW BENEFICIARY DATA:');
      data.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });

      // If we still don't have the woman's name, try to get it from other fields
      if (_bloc.state.womanName == null || _bloc.state.womanName!.isEmpty) {
        final nameFromData =
            data['memberName']?.toString() ??
            data['headName']?.toString() ??
            data['name']?.toString();
        if (nameFromData != null && nameFromData.isNotEmpty) {
          _bloc.add(WomanNameChanged(nameFromData));
        }
      }

      // If we still don't have the husband's name, try to get it from other fields
      if (_bloc.state.husbandName == null || _bloc.state.husbandName!.isEmpty) {
        final spouseName =
            data['spouseName']?.toString() ??
            data['headName']?.toString() ??
            data['husbandName']?.toString();
        if (spouseName != null && spouseName.isNotEmpty) {
          _bloc.add(HusbandNameChanged(spouseName));
        }
      }

      final dataId = data['id']?.toString() ?? '';
      final dataBeneficiaryId = data['BeneficiaryID']?.toString() ?? '';
      final uniqueKey = data['unique_key']?.toString() ?? '';
      final hhId = data['hhId']?.toString() ?? '';

      // Try to load existing form data
      try {
        final localStorageDao = LocalStorageDao();
        final existingForms = await localStorageDao
            .getFollowupFormsByHouseholdAndBeneficiary(
              formType: FollowupFormDataTable.ancDueRegistration,
              householdId: hhId,
              beneficiaryId: dataBeneficiaryId.isNotEmpty
                  ? dataBeneficiaryId
                  : uniqueKey,
            );

        if (existingForms.isNotEmpty) {
          final formData = existingForms.first;
          print('🔍 Found existing ANC form for beneficiary');
          print('  - Form ID: ${formData['id']}');
          print('  - Forms Ref Key: ${formData['forms_ref_key']}');
          print('  - Household Ref Key: ${formData['household_ref_key']}');
          print('  - Beneficiary Ref Key: ${formData['beneficiary_ref_key']}');

          if (formData['form_json'] != null) {
            try {
              final formJson = jsonDecode(formData['form_json'] as String);
              if (formJson is Map && formJson['anc_form'] is Map) {
                final formDataMap =
                    formJson['anc_form'] as Map<String, dynamic>;
                print('📝 Loaded form data: $formDataMap');

                // Update the form with the loaded data
                _updateFormWithData(formDataMap);
              }
            } catch (e) {
              print('❌ Error parsing form JSON: $e');
            }
          }

          for (var form in existingForms) {
            if (form['form_json'] != null) {
              try {
                final formDataJson = jsonDecode(form['form_json'] as String);
                final name =
                    formDataJson['womanName'] ??
                    formDataJson['name'] ??
                    'Not found';
                print('  - Name from form: $name');

                // If this is the current beneficiary, log more details
                if (form['beneficiary_ref_key'] ==
                    (dataBeneficiaryId.isNotEmpty
                        ? dataBeneficiaryId
                        : uniqueKey)) {
                  print('  Current beneficiary match!');
                  final formJsonString = jsonEncode(formDataJson);
                  print(
                    '  📝 Full form data: ${formJsonString.length > 200 ? formJsonString.substring(0, 200) + '...' : formJsonString}',
                  );
                }
              } catch (e) {
                print('  ⚠️ Error parsing form_json: $e');
              }
            } else {
              print('  ℹ️ No form_json data available');
            }
          }

          // Use the most recent form for data extraction
          final latestForm = existingForms.first;
          if (latestForm['form_json'] != null) {
            try {
              final formDataJson = jsonDecode(
                latestForm['form_json'] as String,
              );
              print('\n✨ Found existing form data for this beneficiary');
            } catch (e) {
              print('⚠️ Error processing form data: $e');
            }
          }
        } else {
          print(
            'ℹ️ No existing ANC forms found for this beneficiary using household+beneficiary. Trying beneficiary-only fallback.',
          );
          try {
            final byBeneficiary = await localStorageDao
                .getAncFormsByBeneficiaryId(
                  dataBeneficiaryId.isNotEmpty ? dataBeneficiaryId : uniqueKey,
                );

            if (byBeneficiary.isNotEmpty) {
              final latest = byBeneficiary.first;

              // Fixed: Proper conditional expression with type casting
              final fd = latest['anc_form'] is Map
                  ? Map<String, dynamic>.from(latest['anc_form'] as Map)
                  : (latest['form_json'] != null
                        ? ((jsonDecode(latest['form_json'] as String)
                                      as Map<String, dynamic>?)?['anc_form']
                                  as Map<String, dynamic>?) ??
                              {}
                        : <String, dynamic>{});

              print('📝 Loaded fallback ANC form data: $fd');
              _updateFormWithData(fd);
            } else {
              print('ℹ️ No ANC forms found in beneficiary-only lookup');
            }
          } catch (e) {
            print('⚠️ Error in beneficiary-only ANC lookup: $e');
          }
        }
      } catch (e) {
        print('⚠️ Error loading existing forms: $e');
      }

      print('  - BeneficiaryID: $dataBeneficiaryId');
      print('  - unique_key: $uniqueKey');
      print('  - hhId: $hhId');

      String? beneficiaryIdToUse = dataBeneficiaryId.isNotEmpty
          ? dataBeneficiaryId
          : (dataId.isNotEmpty ? dataId : uniqueKey);

      print(
        '  Selected Beneficiary ID: $beneficiaryIdToUse (${beneficiaryIdToUse?.length ?? 0} chars)',
      );
      print('  Household ID: $hhId (${hhId.length} chars)');

      if (beneficiaryIdToUse != null && beneficiaryIdToUse.isNotEmpty) {
        _bloc.add(BeneficiaryIdSet(beneficiaryIdToUse));

        try {
          final beneficiaryRow = await LocalStorageDao.instance
              .getBeneficiaryByUniqueKey(beneficiaryIdToUse);
          if (beneficiaryRow != null) {
            final infoRaw = beneficiaryRow['beneficiary_info'];
            Map<String, dynamic> info;
            if (infoRaw is Map<String, dynamic>) {
              info = infoRaw;
            } else if (infoRaw is Map) {
              info = Map<String, dynamic>.from(infoRaw);
            } else if (infoRaw is String && infoRaw.isNotEmpty) {
              info = Map<String, dynamic>.from(jsonDecode(infoRaw));
            } else {
              info = {};
            }

            // Set LMP and EDD dates if available in beneficiary info
            if (info['lmp'] != null) {
              try {
                final lmpDate = DateTime.parse(info['lmp'].toString());
                _bloc.add(LmpDateChanged(lmpDate));
                print('📅 Set LMP date from beneficiary info: $lmpDate');
                final base = _bloc.state.dateOfInspection ?? DateTime.now();
                final difference = base.difference(lmpDate).inDays;
                final weeksOfPregnancy = (difference / 7).floor() + 1;
                _bloc.add(WeeksOfPregnancyChanged(weeksOfPregnancy.toString()));
              } catch (e) {
                print('⚠️ Error parsing LMP date: ${info['lmp']} - $e');
              }
            }

            if (info['edd'] != null) {
              try {
                final eddDate = DateTime.parse(info['edd'].toString());
                _bloc.add(EddDateChanged(eddDate));
                print('📅 Set EDD date from beneficiary info: $eddDate');
              } catch (e) {
                print('⚠️ Error parsing EDD date: ${info['edd']} - $e');
              }
            }

            final womanName = (info['memberName'] ?? info['headName'])
                ?.toString();
            if (womanName != null && womanName.isNotEmpty) {
              _bloc.add(WomanNameChanged(womanName));
            }

            final spouseName = info['spouseName']?.toString();
            if (spouseName != null && spouseName.isNotEmpty) {
              _bloc.add(HusbandNameChanged(spouseName));
            }

            final houseNoFromBen = info['houseNo']?.toString();
            if (houseNoFromBen != null && houseNoFromBen.isNotEmpty) {
              _bloc.add(HouseNumberChanged(houseNoFromBen));
              houseNo ??= houseNoFromBen;
            }

            final mobileFromBen = info['mobileNo']?.toString();
          }
        } catch (e) {
          print('⚠️ Error pre-filling ANC form from beneficiaries table: $e');
        }

        // Set woman's name if available
        if (data['Name'] != null) {
          _bloc.add(WomanNameChanged(data['Name'].toString()));
        }

        // Set husband's name from direct field or beneficiary_info
        if (data['Husband'] != null) {
          _bloc.add(HusbandNameChanged(data['Husband'].toString()));
          print('👨 Set husband name from direct field: ${data['Husband']}');
        } else if (data['beneficiary_info'] != null) {
          try {
            final beneficiaryInfoString = data['beneficiary_info'].toString();
            final beneficiaryInfo = jsonDecode(beneficiaryInfoString);
            if (beneficiaryInfo is Map &&
                beneficiaryInfo['spouseName'] != null) {
              _bloc.add(
                HusbandNameChanged(beneficiaryInfo['spouseName'].toString()),
              );
              print(
                '👨 Set husband name from beneficiary_info: ${beneficiaryInfo['spouseName']}',
              );
            }
          } catch (e) {
            print('⚠️ Error parsing beneficiary_info: $e');
          }
        }
      } else {
        print(
          '⚠️ No valid beneficiary ID or unique key found in the provided data',
        );
      }

      // Fetch house number from secure storage
      if (dataId.isNotEmpty || dataBeneficiaryId.isNotEmpty) {
        try {
          final storageData = await SecureStorageService.getUserData();
          if (storageData != null && storageData.isNotEmpty) {
            print(
              '🔍 Found data in secure storage, searching for matching beneficiary...',
            );

            try {
              final Map<String, dynamic> parsedData = jsonDecode(storageData);
              if (parsedData['visits'] is List) {
                for (var visit in parsedData['visits']) {
                  try {
                    final visitId = visit['id']?.toString();
                    final visitBeneficiaryId = visit['BeneficiaryID']
                        ?.toString();

                    // Try to get houseNo from different possible locations
                    String? visitHouseNo;

                    // 1. Check direct field first
                    visitHouseNo = visit['houseNo']?.toString();

                    // 2. Check nested in beneficiary_info.head_details if not found directly
                    if (visitHouseNo == null &&
                        visit['beneficiary_info'] is Map) {
                      final beneficiaryInfo = visit['beneficiary_info'] as Map;
                      if (beneficiaryInfo['head_details'] is Map) {
                        final headDetails =
                            beneficiaryInfo['head_details'] as Map;
                        visitHouseNo = headDetails['houseNo']?.toString();
                        if (visitHouseNo != null) {
                          print(
                            '   - Found houseNo in beneficiary_info.head_details',
                          );
                        }
                      }
                    }

                    // 3. Check _rawRow if still not found
                    if (visitHouseNo == null && visit['_rawRow'] is Map) {
                      final rawRow = visit['_rawRow'] as Map;

                      // First try direct houseNo in _rawRow
                      if (rawRow['houseNo'] != null) {
                        visitHouseNo = rawRow['houseNo'].toString();
                        if (visitHouseNo != null) {
                          print('   - Found houseNo in _rawRow');
                        }
                      }
                      // Then try nested in _rawRow.beneficiary_info.head_details
                      else if (rawRow['beneficiary_info'] is Map) {
                        final rawBeneficiaryInfo =
                            rawRow['beneficiary_info'] as Map;
                        if (rawBeneficiaryInfo['head_details'] is Map) {
                          final headDetails =
                              rawBeneficiaryInfo['head_details'] as Map;
                          visitHouseNo = headDetails['houseNo']?.toString();
                          if (visitHouseNo != null) {
                            print(
                              '   - Found houseNo in _rawRow.beneficiary_info.head_details',
                            );
                          }
                        }
                      }
                    }

                    final isMatch =
                        (dataId.isNotEmpty &&
                            (visitId == dataId ||
                                visitBeneficiaryId == dataId)) ||
                        (dataBeneficiaryId.isNotEmpty &&
                            (visitId == dataBeneficiaryId ||
                                visitBeneficiaryId == dataBeneficiaryId));

                    if (isMatch) {
                      houseNo = visitHouseNo;
                      print('🏠 Found matching beneficiary in secure storage');
                      print('   - ID: ${visitId ?? 'N/A'}');
                      print(
                        '   - BeneficiaryID: ${visitBeneficiaryId ?? 'N/A'}',
                      );
                      print('   - House No: ${houseNo ?? 'Not found'}');
                      print('   - Full visit data: $visit');
                      break;
                    }
                  } catch (e) {
                    print('⚠️ Error processing visit data: $e');
                  }
                }
              }
            } catch (e) {
              print('⚠️ Error parsing secure storage data: $e');
            }
          } else {
            print('ℹ️ No data found in secure storage');
          }
        } catch (e) {
          print('⚠️ Error accessing secure storage: $e');
        }
      } else {
        print(
          'ℹ️ No valid ID or BeneficiaryID provided for secure storage lookup',
        );
      }

      // Use visitCount passed from previous screen to determine next ANC visit number (final confirmation)
      try {
        final dynamic rawVisitCount = data['visitCount'];
        int visitCount = 0;

        if (rawVisitCount is int) {
          visitCount = rawVisitCount;
        } else if (rawVisitCount is String) {
          visitCount = int.tryParse(rawVisitCount) ?? 0;
        }

        final nextVisitNumber = (visitCount + 1);
        print(
          '🔢 visitCount from list screen: $visitCount, nextVisitNumber: $nextVisitNumber',
        );

        _bloc.add(VisitNumberChanged(nextVisitNumber.toString()));
      } catch (e) {
        print('⚠️ Error processing visitCount from beneficiaryData: $e');
      }
    }

    // If no data but we have house number from storage, set it
    if (houseNo != null) {
      _bloc.add(HouseNumberChanged(houseNo));
    }
    await _loadPreviousLmpFromEligibleCouple();
    await _loadLastTd1DateFromDb();
  }

  Future<void> _loadPreviousLmpFromEligibleCouple() async {
    try {
      final benId =
          widget.beneficiaryData?['BeneficiaryID']?.toString() ??
          widget.beneficiaryData?['unique_key']?.toString() ??
          (widget.beneficiaryData?['_rawRow'] is Map
              ? (widget.beneficiaryData?['_rawRow'] as Map)['unique_key']
                    ?.toString()
              : null);

      final hhId =
          widget.beneficiaryData?['hhId']?.toString() ??
          (widget.beneficiaryData?['_rawRow'] is Map
              ? (widget.beneficiaryData?['_rawRow'] as Map)['household_ref_key']
                    ?.toString()
              : null);

      if (benId == null || benId.isEmpty || hhId == null || hhId.isEmpty) {
        return;
      }

      final dao = LocalStorageDao();
      final forms = await dao.getFollowupFormsByHouseholdAndBeneficiary(
        formType: FollowupFormDataTable.eligibleCoupleTrackingDue,
        householdId: hhId,
        beneficiaryId: benId,
      );

      if (forms.isEmpty) return;

      final uiLmp = _bloc.state.lmpDate;
      DateTime? chosen;

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;
        Map<String, dynamic> root;
        try {
          root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
        } catch (_) {
          continue;
        }
        final data = root['anc_form'];
        if (data is Map) {
          final lmpStr = data['lmp_date']?.toString();
          if (lmpStr != null && lmpStr.isNotEmpty) {
            DateTime? lmp;
            try {
              lmp = DateTime.parse(lmpStr);
            } catch (_) {}
            if (lmp != null) {
              final same =
                  uiLmp != null &&
                  lmp.year == uiLmp.year &&
                  lmp.month == uiLmp.month &&
                  lmp.day == uiLmp.day;
              if (same) {
                print('Skipping LMP equal to current: $lmp');
                continue;
              }
              if (uiLmp != null) {
                if (lmp.isBefore(uiLmp)) {
                  chosen = lmp;
                  break;
                }
              } else {
                chosen = lmp;
                break;
              }
            }
          }
        }
      }

      if (chosen != null) {
        print('Loading previous LMP date: $chosen');
        setState(() {
          _prevLmpFromEc = chosen;
        });
        _bloc.add(LmpDateChanged(chosen));
        final weeks = _calculateWeeksOfPregnancy(chosen);
        _bloc.add(WeeksOfPregnancyChanged(weeks.toString()));
      }
    } catch (e) {
      print('Error loading previous LMP: $e');
    }
  }

  Future<void> _loadLastTd1DateFromDb() async {
    try {
      final benId =
          widget.beneficiaryData?['BeneficiaryID']?.toString() ??
          widget.beneficiaryData?['unique_key']?.toString() ??
          (widget.beneficiaryData?['_rawRow'] is Map
              ? (widget.beneficiaryData?['_rawRow'] as Map)['unique_key']
                    ?.toString()
              : null);

      if (benId == null || benId.isEmpty) {
        return;
      }

      final dao = LocalStorageDao();
      final forms = await dao.getAncFormsByBeneficiaryId(benId);
      if (forms.isEmpty) return;

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;
        Map<String, dynamic> root;
        try {
          root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
        } catch (_) {
          continue;
        }
        final data = root['anc_form'];
        if (data is Map) {
          final td1Str = data['td1_date']?.toString();
          if (td1Str != null && td1Str.isNotEmpty) {
            try {
              final td1 = DateTime.parse(td1Str);
              setState(() {
                _lastTd1DateFromDb = td1;
              });
              break;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      print('Error loading last TD1 date: $e');
    }
  }

  // VALIDATION FUNCTIONS
  String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Required field";
    }
    return null;
  }

  String? validateDateRequired(DateTime? date) {
    if (date == null) return "Required field";
    return null;
  }

  String? validateWeightKg(String? value) {
    if (value == null || value.trim().isEmpty) return null; // not mandatory
    final w = num.tryParse(value);
    if (w == null) return "Enter a valid number";
    if (w < 30) return "Minimum weight is 30 kg";
    if (w > 120) return "Maximum weight is 120 kg";
    return null;
  }

  String? validateTabletCount(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = int.tryParse(value);
    if (n == null) return "Enter a valid number";
    if (n > 500) return "Maximum 500 tablets allowed";
    return null;
  }

  String? validateBabyWeight(String? value) {
    if (value == null || value.trim().isEmpty) return "Required field";
    final weight = int.tryParse(value);
    if (weight == null) return "Enter a valid number";
    if (weight < 1200) return "Minimum weight is 1200 gms";
    if (weight > 4000) return "Maximum weight is 4000 gms";
    return null;
  }

  String? validateDropdownRequired(String? value) {
    if (value == null || value.isEmpty) return "Required field";
    return null;
  }

  String? validateHighRiskSelection(List<String> selected) {
    if (selected.isEmpty) return "Please select at least one risk";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.ancVisitFormTitle ?? 'ANC Visit Form',
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<AnvvisitformBloc, AnvvisitformState>(
            listener: (context, state) {
              if (state.error != null) {
                final msg = state.error!.isNotEmpty
                    ? state.error!
                    : (l10n?.somethingWentWrong ?? 'Something went wrong');
                showAppSnackBar(context, msg);
              }
              if (state.isSuccess) {
                if (state.givesBirthToBaby == (l10n?.yes ?? 'Yes')) {
                  final count = _childrenCount(state.numberOfChildren);
                  CustomDialog.show(
                    context,
                    title:
                        l10n?.formSavedSuccessfully ??
                        'Form has been saved successfully.',
                    message:
                        '${l10n?.deliveryOutcome ?? "Delivery outcome"} : $count',
                    onOkPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Navigator.pop(context, true);
                    },
                  );
                } else {
                  showAppSnackBar(
                    context,
                    l10n?.saveSuccess ?? 'Form Submitted successfully',
                  );
                  Navigator.pop(context, true);
                }
              }
            },
            builder: (context, state) {
              final bloc = context.read<AnvvisitformBloc>();

              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                l10n?.ancVisitLabel ?? 'ANC visit',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Text(
                                '${state.ancVisitNo == 0 ? 1 : state.ancVisitNo}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            const SizedBox(height: 12),
                            ApiDropdown<String>(
                              labelText: l10n?.visitTypeLabel ?? 'Visit type *',

                              items: const ['ANC', 'PMSMA'],
                              getLabel: (s) {
                                switch (s) {
                                  case 'ANC':
                                    return l10n?.anc ?? '';
                                  case 'PMSMA':
                                    return l10n?.pmsma ?? '';
                                  default:
                                    return s;
                                }
                              },

                              value: state.visitType.isEmpty
                                  ? null
                                  : state.visitType,

                              onChanged: (v) =>
                                  bloc.add(VisitTypeChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                              validator: validateDropdownRequired,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            ApiDropdown<String>(
                              labelText:
                                  l10n?.placeOfAncLabel ?? 'Place of ANC',
                              items: const [
                                'VHSND/Anganwadi',
                                'Health Sub-center/Health & Wealth Centre(HSC/HWC)',
                                'Primary Health Centre(PHC)',
                                'Community Health Centre(CHC)',
                                'Referral Hospital(RH)',
                                'District Hospital(DH)',
                                'Medical College Hospital(MCH)',
                                'PMSMA Site',
                              ],
                              value: state.placeOfAnc.isEmpty
                                  ? null
                                  : state.placeOfAnc,
                              getLabel: (s) {
                                switch (s) {
                                  case 'VHSND/Anganwadi':
                                    return l10n?.vhsndAnganwadi ?? '';
                                  case 'Health Sub-center/Health & Wealth Centre(HSC/HWC)':
                                    return l10n?.hscHwc ?? '';
                                  case 'Primary Health Centre(PHC)':
                                    return l10n?.phcLabel ?? '';
                                  case 'Community Health Centre(CHC)':
                                    return l10n?.chcLabel ?? '';
                                  case 'Referral Hospital(RH)':
                                    return l10n?.rh ?? '';
                                  case 'District Hospital(DH)':
                                    return l10n?.dh ?? '';
                                  case 'Medical College Hospital(MCH)':
                                    return l10n?.mch ?? '';
                                  case 'PMSMA Site':
                                    return l10n?.pmsmaSite ?? '';
                                  default:
                                    return s;
                                }
                              },
                              onChanged: (v) =>
                                  bloc.add(PlaceOfAncChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            CustomDatePicker(
                              labelText:
                                  l10n?.dateOfInspectionLabel ??
                                  'Date of inspection *',
                              hintText:
                                  l10n?.dateOfInspectionLabel ??
                                  'Date of inspection *',
                              initialDate:
                                  state.dateOfInspection ?? DateTime.now(),
                              onDateChanged: (d) {
                                bloc.add(DateOfInspectionChanged(d));
                                final lmp = bloc.state.lmpDate;
                                if (lmp != null && d != null) {
                                  final difference = d.difference(lmp).inDays;
                                  final weeks = (difference / 7).floor() + 1;
                                  bloc.add(
                                    WeeksOfPregnancyChanged(weeks.toString()),
                                  );
                                }
                              },
                              validator: (date) => validateDateRequired(date),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            CustomTextField(
                              labelText:
                                  l10n?.houseNumberLabel ?? 'House number',
                              hintText:
                                  l10n?.houseNumberLabel ?? 'House number',
                              initialValue: state.houseNumber,
                              readOnly: true,
                              onChanged: (v) => bloc.add(HouseNumberChanged(v)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText:
                                  l10n?.nameOfPregnantWomanLabel ??
                                  'Name of Pregnant Woman',
                              hintText:
                                  l10n?.nameOfPregnantWomanLabel ??
                                  'Name of Pregnant Woman',
                              readOnly: true,
                              key: ValueKey('woman_name_${state.womanName}'),
                              initialValue: state.womanName,
                              onChanged: (v) => bloc.add(WomanNameChanged(v)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText:
                                  l10n?.husbandNameLabel ?? "Husband's name",
                              readOnly: true,
                              hintText:
                                  l10n?.husbandNameLabel ?? "Husband's name",
                              key: ValueKey(
                                'husband_name_${state.husbandName}',
                              ),
                              initialValue: state.husbandName,
                              onChanged: (v) => bloc.add(HusbandNameChanged(v)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText: l10n?.rchNumberLabel ?? 'RCH number',
                              readOnly: true,
                              hintText: l10n?.rchNumberLabel ?? 'RCH number',
                              initialValue: state.rchNumber,
                              onChanged: (v) => bloc.add(RchNumberChanged(v)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            // LMP Date Picker
                            Container(
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(4),
                                ),
                              ),
                              child: CustomDatePicker(
                                labelText:
                                    l10n?.lmpDateLabel ??
                                    'Date of last menstrual period (LMP) *',
                                hintText:
                                    l10n?.lmpDateLabel ??
                                    'Date of last menstrual period (LMP) *',
                                initialDate: state.lmpDate ?? DateTime.now(),
                                readOnly: true,
                                onDateChanged: (d) {
                                  if (d != null) {
                                    bloc.add(LmpDateChanged(d));
                                    final base =
                                        bloc.state.dateOfInspection ??
                                        DateTime.now();
                                    final difference = base
                                        .difference(d)
                                        .inDays;
                                    final weeks = (difference / 7).floor() + 1;
                                    bloc.add(
                                      WeeksOfPregnancyChanged(weeks.toString()),
                                    );
                                  }
                                },
                                validator: (date) => validateDateRequired(date),
                              ),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomDatePicker(
                              labelText:
                                  l10n?.eddDateLabel ??
                                  'Expected date of delivery (EDD)',
                              hintText:
                                  l10n?.eddDateLabel ??
                                  'Expected date of delivery (EDD)',
                              initialDate: state.eddDate,
                              readOnly: true,
                              onDateChanged: (d) => bloc.add(EddDateChanged(d)),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              key: ValueKey(
                                'weeks_of_pregnancy_${state.weeksOfPregnancy}',
                              ),
                              labelText:
                                  l10n?.weeksOfPregnancyLabel ??
                                  'No. of weeks of pregnancy',
                              hintText:
                                  l10n?.weeksOfPregnancyLabel ??
                                  'No. of weeks of pregnancy',
                              initialValue: state.weeksOfPregnancy,
                             readOnly: true,
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  bloc.add(WeeksOfPregnancyChanged(v)),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n?.orderOfPregnancyLabel ??
                                      'Order of Pregnancy(Gravida)',
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _qtyButton(
                                      icon: Icons.remove,
                                      onTap: state.gravida > 1
                                          ? () => bloc.add(
                                              const GravidaDecremented(),
                                            )
                                          : null,
                                      enabled: state.gravida > 1,
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 44,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.outlineVariant,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${state.gravida > 0 ? state.gravida : 1}',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _qtyButton(
                                      icon: Icons.add,
                                      onTap: state.gravida < 15
                                          ? () => bloc.add(
                                              const GravidaIncremented(),
                                            )
                                          : null,
                                      enabled: state.gravida < 15,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 16,
                            ),
                            ApiDropdown<String>(
                              labelText:
                                  l10n?.isWomanBreastfeedingLabel ??
                                  'Is woman breastfeeding?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.isBreastFeeding.isEmpty
                                  ? null
                                  : state.isBreastFeeding,
                              getLabel: (s) => s,
                              onChanged: (v) =>
                                  bloc.add(IsBreastFeedingChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),

                            Divider(
                              color: const Color.fromRGBO(202, 196, 208, 1),
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomDatePicker(
                              labelText:
                                  l10n?.td1DateLabel ??
                                  'Date of T.D(Tetanus and adult diphtheria) 1',
                              hintText:
                                  'dd-mm-yyyy',
                              initialDate: state.td1Date,
                              readOnly: (() {
                                final prev = _prevLmpFromEc;
                                final curr = state.lmpDate;
                                if (prev != null && curr != null) {
                                  final years = _fullYearsBetween(prev, curr);
                                  return years < 3; // disable if gap < 3 years
                                }
                                return false;
                              })(),
                              onDateChanged: (d) => bloc.add(Td1DateChanged(d)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomDatePicker(
                              labelText:
                                  l10n?.td2DateLabel ??
                                  'Date of T.D(Tetanus and adult diphtheria) 2',
                              hintText:
                              'dd-mm-yyyy',
                              initialDate: state.td2Date,
                              readOnly: (() {
                                final inspect =
                                    state.dateOfInspection ?? DateTime.now();
                                final td1 = state.td1Date ?? _lastTd1DateFromDb;
                                if (td1 == null) {
                                  return true;
                                }
                                final days = inspect.difference(td1).inDays;
                                return days < 28;
                              })(),
                              onDateChanged: (d) => bloc.add(Td2DateChanged(d)),
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomDatePicker(
                              labelText:
                                  l10n?.tdBoosterDateLabel ??
                                  'Date of T.D(Tetanus and adult diphtheria) booster',
                              hintText:
                              'dd-mm-yyyy',
                              initialDate: state.tdBoosterDate,
                              readOnly: (() {
                                bool td2Eligible = false;
                                final inspect =
                                    state.dateOfInspection ?? DateTime.now();
                                final td1 = state.td1Date ?? _lastTd1DateFromDb;
                                if (inspect != null && td1 != null) {
                                  final days = inspect.difference(td1).inDays;
                                  td2Eligible = days >= 28;
                                }
                                if (td2Eligible) {
                                  return true;
                                }
                                final p = _prevLmpFromEc;
                                final c = state.lmpDate;
                                if (p != null && c != null) {
                                  final years = _fullYearsBetween(p, c);
                                  return years > 3;
                                }
                                return state.gravida < 2;
                              })(),
                              onDateChanged: (d) =>
                                  bloc.add(TdBoosterDateChanged(d)),
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            Builder(
                              builder: (context) {
                                final weeks =
                                    int.tryParse(
                                      state.weeksOfPregnancy ?? '0',
                                    ) ??
                                    0;
                                final isAfter12Weeks = weeks > 12;
                                final label = isAfter12Weeks
                                    ? 'Number of Iron & Folic Acid tablets given'
                                    : (l10n?.folicAcidTabletsLabel ??
                                          'Number of Folic Acid tablets given');
                                return CustomTextField(
                                  labelText: label,
                                  hintText: label,
                                  initialValue: state.folicAcidTablets,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      bloc.add(FolicAcidTabletsChanged(v)),
                                  validator: validateTabletCount,
                                );
                              },
                            ),

                            if (int.tryParse(state.weeksOfPregnancy) != null &&
                                int.parse(state.weeksOfPregnancy) >= 14) ...[
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),
                              CustomTextField(
                                labelText:l10n?.calciumVitaminD3TabletsLabel ??
                                    'Number of Calcium and Vitamin D3 tablets given',
                                hintText:l10n?.calciumVitaminD3TabletsLabel ??
                                    'Enter number of Calcium and Vitamin D3 tablets',
                                initialValue: state.calciumVitaminD3Tablets,
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    bloc.add(CalciumVitaminD3TabletsChanged(v)),
                                validator: validateTabletCount,
                              ),
                            ],

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            MultiSelect<String>(
                              items: [
                                MultiSelectItem(
                                  label: l10n?.tuberculosisLabel ?? 'Turbeculosis (TB)',
                                  value: l10n?.tuberculosisLabel ?? 'Turbeculosis (TB)',
                                ),
                                MultiSelectItem(
                                  label: l10n?.diseaseDiabetes ?? 'Diabetes',
                                  value: l10n?.diseaseDiabetes ?? 'Diabetes',
                                ),
                                MultiSelectItem(
                                  label: l10n?.hepetitisB ?? 'Hepetitis - B',
                                  value: l10n?.hepetitisB ?? 'Hepetitis - B',
                                ),
                                MultiSelectItem(
                                  label: l10n?.asthma ?? 'Asthma',
                                  value: l10n?.asthma ?? 'Asthma',
                                ),
                                MultiSelectItem(
                                  label: l10n?.highBP ?? 'High BP',
                                  value: l10n?.highBP ?? 'High BP',
                                ),
                                MultiSelectItem(
                                  label: l10n?.stirti ?? 'STI/RTI',
                                  value: l10n?.stirti ?? 'STI/RTI',
                                ),
                                MultiSelectItem(
                                  label: l10n?.heartDisease ?? 'Heart Disease',
                                  value: l10n?.heartDisease ?? 'Heart Disease',
                                ),
                                MultiSelectItem(
                                  label: l10n?.diseaseLiver ?? 'Liver Disease',
                                  value: l10n?.diseaseLiver ?? 'Liver Disease',
                                ),
                                MultiSelectItem(
                                  label: l10n?.diseaseKidney ?? 'Kidney Disease',
                                  value: l10n?.diseaseKidney ?? 'Kidney Disease',
                                ),
                                MultiSelectItem(
                                  label: l10n?.diseaseEpilepsy ?? 'Epilepsy',
                                  value: l10n?.diseaseEpilepsy ?? 'Epilepsy',
                                ),
                                MultiSelectItem(
                                  label: l10n?.diseaseOther ?? 'Other',
                                  value: l10n?.diseaseOther ?? 'Other',
                                ),
                              ],
                              selectedValues: state.selectedDiseases,
                              labelText:
                                  l10n?.preExistingDiseaseLabel ??
                                  'Pre - Existing disease',
                              hintText: l10n?.select ?? 'Select',

                              onSelectionChanged: (values) {
                                final selected = List<String>.from(values);
                                bloc.add(PreExistingDiseasesChanged(selected));

                                // Clear other disease field if 'Other' is not selected
                                if (!selected.contains(
                                  l10n?.diseaseOther ?? 'Other',
                                )) {
                                  bloc.add(OtherDiseaseChanged(''));
                                }
                              },
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            if (state.selectedDiseases.contains(
                              l10n?.diseaseOther ?? 'Other',
                            ))
                              CustomTextField(
                                labelText: 'Please specify other disease',
                                hintText: 'Please specify other disease',
                                initialValue: state.otherDisease,
                                onChanged: (v) =>
                                    bloc.add(OtherDiseaseChanged(v)),
                                validator: (value) {
                                  if (state.selectedDiseases.contains(
                                        l10n?.diseaseOther ?? 'Other',
                                      ) &&
                                      (value == null || value.isEmpty)) {
                                    return l10n?.requiredField ??
                                        'This field is required';
                                  }
                                  return null;
                                },
                              ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText: l10n?.weightKgLabel ?? 'Weight (Kg)',
                              hintText: l10n?.weightKgLabel ?? 'Weight (Kg)',
                              initialValue: state.weight,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(WeightChanged(v)),
                              validator: validateWeightKg,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText: l10n?.systolicLabel ?? 'Systolic',
                              hintText: l10n?.systolicLabel ?? 'Systolic',
                              initialValue: state.systolic,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(SystolicChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText: l10n?.diastolicLabel ?? 'Diastolic',
                              hintText: l10n?.diastolicLabel ?? 'Diastolic',
                              initialValue: state.diastolic,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(DiastolicChanged(v)),
                              readOnly: true,
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            CustomTextField(
                              labelText:
                                  l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                              hintText:
                                  l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                              initialValue: state.hemoglobin,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(HemoglobinChanged(v)),
                              readOnly: true,
                            ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            ApiDropdown<String>(
                              labelText:
                                  l10n?.anyHighRiskProblemLabel ??
                                  'Is there any high risk problem?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.highRisk.isEmpty
                                  ? null
                                  : state.highRisk,
                              getLabel: (s) => s,
                              onChanged: (v) =>
                                  bloc.add(HighRiskChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),
                            if (state.highRisk == 'Yes') ...[
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),
                              MultiSelect<String>(
                                items: const [
                                  'riskSevereAnemia',
                                  'riskPIH',
                                  'riskInfections',
                                  'riskGestationalDiabetes',
                                  'riskHypothyroidism',
                                  'riskTeenagePregnancy',
                                  'riskTwins',
                                  'riskMalPresentation',
                                  'riskPreviousCesarean',
                                  'riskPreviousHistory',
                                  'riskRhNegative',
                                ]
                                    .map(
                                      (risk) => MultiSelectItem<String>(
                                    label: () {
                                      switch (risk) {
                                        case 'riskSevereAnemia':
                                          return l10n?.riskSevereAnemia ?? '';
                                        case 'riskPIH':
                                          return l10n?.riskPIH ?? '';
                                        case 'riskInfections':
                                          return l10n?.riskInfections ?? '';
                                        case 'riskGestationalDiabetes':
                                          return l10n?.riskGestationalDiabetes ?? '';
                                        case 'riskHypothyroidism':
                                          return l10n?.riskHypothyroidism ?? '';
                                        case 'riskTeenagePregnancy':
                                          return l10n?.riskTeenagePregnancy ?? '';
                                        case 'riskTwins':
                                          return l10n?.riskTwins ?? '';
                                        case 'riskMalPresentation':
                                          return l10n?.riskMalPresentation ?? '';
                                        case 'riskPreviousCesarean':
                                          return l10n?.riskPreviousCesarean ?? '';
                                        case 'riskPreviousHistory':
                                          return l10n?.riskPreviousHistory ?? '';
                                        case 'riskRhNegative':
                                          return l10n?.riskRhNegative ?? '';
                                        default:
                                          return risk;
                                      }
                                    }(),
                                    value: risk,
                                  ),
                                )
                                    .toList(),
                                selectedValues: state.selectedRisks,
                                labelText: l10n?.selectRisks ??'Select risks',
                                hintText: l10n?.selectRisks ??'Select risks',
                                onSelectionChanged: (values) {
                                  bloc.add(
                                    SelectedRisksChanged(
                                      List<String>.from(values),
                                    ),
                                  );
                                },
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),
                              if (!(int.tryParse(state.weeksOfPregnancy) !=
                                      null &&
                                  int.parse(state.weeksOfPregnancy) > 30)) ...[
                                const SizedBox(height: 8),
                                ApiDropdown<String>(
                                  labelText:l10n?.abortionComplication ??
                                      'Any complication leading to abortion?',
                                  items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                                  value: state.hasAbortionComplication.isEmpty
                                      ? null
                                      : state.hasAbortionComplication,
                                  getLabel: (s) => s,
                                  onChanged: (v) => bloc.add(
                                    HasAbortionComplicationChanged(v ?? ''),
                                  ),
                                  hintText: l10n?.select ?? 'Select',
                                ),
                              ],
                              if (state.hasAbortionComplication == 'Yes') ...[
                                const SizedBox(height: 16),
                                CustomDatePicker(
                                  labelText: l10n?.dateOfAbortion ??'Date of Abortion',
                                  hintText:l10n?.dateOfAbortion ?? 'Date of Abortion',
                                  initialDate: state.abortionDate,
                                  onDateChanged: (d) =>
                                      bloc.add(AbortionDateChanged(d)),
                                ),
                              ],
                            ],
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                            if (int.tryParse(state.weeksOfPregnancy) != null &&
                                int.parse(state.weeksOfPregnancy) > 30) ...[
                              ApiDropdown<String>(
                                labelText:l10n?.didPregnantWomanGiveBirth ??
                                    'Did the pregnant woman give birth to a baby?',
                                items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                                value: state.givesBirthToBaby.isEmpty
                                    ? null
                                    : state.givesBirthToBaby,
                                getLabel: (s) => s,
                                onChanged: (v) =>
                                    bloc.add(GivesBirthToBaby(v ?? '')),
                                hintText: l10n?.select ?? 'Select',
                              ),
                              Divider(
                                color: AppColors.divider,
                                thickness: 0.5,
                                height: 0,
                              ),

                              if (state.givesBirthToBaby ==
                                  (l10n?.yes ?? 'Yes')) ...[
                                ApiDropdown<String>(
                                  labelText:l10n?.deliveryOutcomeLabel ?? 'Delivery outcome *',
                                  items: [
                                    "Live birth",
                                    "Still birth",
                                    "Newborn death",
                                  ],
                                  value: state.deliveryOutcome.isEmpty
                                      ? null
                                      : state.deliveryOutcome,
                                  getLabel: (s) {
                                    switch (s) {
                                      case 'Live birth':
                                        return l10n?.liveBirth ?? '';
                                      case 'Still birth':
                                        return l10n?.stillBirth ?? '';
                                      case 'Newborn death':
                                        return l10n?.newbornDeath ?? '';
                                      default:
                                        return s;
                                    }
                                  },
                                  onChanged: (v) =>
                                      bloc.add(DeliveryOutcomeChanged(v ?? '')),
                                  hintText: l10n?.select ?? 'Select',
                                  validator: state.givesBirthToBaby == 'Yes'
                                      ? validateDropdownRequired
                                      : null,
                                ),
                                Divider(
                                  color: AppColors.divider,
                                  thickness: 0.5,
                                  height: 0,
                                ),

                                if (state.deliveryOutcome == "Live birth" &&
                                    state.givesBirthToBaby ==
                                        (l10n?.yes ?? 'Yes')) ...[
                                  ApiDropdown<String>(
                                    labelText:l10n?.numberOfChildrenLabel ?? 'Number of Children *',
                                    items: ["One Child", "Twins", "Triplets"],
                                    value: state.numberOfChildren.isEmpty
                                        ? null
                                        : state.numberOfChildren,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'One Child':
                                          return l10n!.oneChild;
                                        case 'Twins':
                                          return l10n!.twins ;
                                        case 'Triplets':
                                          return l10n!.triplets ;
                                        default:
                                          return s;
                                      }
                                    },                                    onChanged: (v) => bloc.add(
                                      NumberOfChildrenChanged(v ?? ""),
                                    ),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],
                                if (state.numberOfChildren == "One Child" &&
                                    state.givesBirthToBaby ==
                                        (l10n?.yes ?? 'Yes') &&
                                    state.deliveryOutcome == "Live birth") ...[
                                  // Baby 1 Name
                                  CustomTextField(
                                    labelText:l10n?.babysName ?? "Baby's Name *",
                                    hintText:l10n?.enterBabyName ?? "Enter Baby's Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  // Baby 1 Gender
                                  ApiDropdown<String>(
                                    labelText:l10n?.babyGenderLabel ?? "Baby's Gender *",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty
                                        ? null
                                        : state.baby1Gender,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'male':
                                          return l10n?.male ?? '';
                                        case 'female':
                                          return l10n?.female ?? '';
                                        case 'transgender':
                                          return l10n?.transgender ?? '';
                                        default:
                                          return s;
                                      }
                                    },                                    onChanged: (v) =>
                                        bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  // Baby 1 Weight
                                  CustomTextField(
                                    labelText: l10n?.babyWeightLabel ?? "Baby's Weight (1200–4000gms) *",
                                    hintText:l10n?.enterBabyWeight ?? "Enter Baby's Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],
                                if (state.numberOfChildren == "Twins" &&
                                    state.givesBirthToBaby ==
                                        (l10n?.yes ?? 'Yes') &&
                                    state.deliveryOutcome == "Live birth") ...[
                                  CustomTextField(
                                    labelText:l10n?.firstBabyName ?? "First Baby  Name *",
                                    hintText:l10n?.enterFirstBabyName ?? "Enter First Baby  Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  ApiDropdown<String>(
                                    labelText:l10n?.firstBabyGender ?? "First Baby  Gender *",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty
                                        ? null
                                        : state.baby1Gender,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'male':
                                          return l10n?.male ?? '';
                                        case 'female':
                                          return l10n?.female ?? '';
                                        case 'transgender':
                                          return l10n?.transgender ?? '';
                                        default:
                                          return s;
                                      }
                                    },
                                    onChanged: (v) =>
                                        bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  CustomTextField(
                                    labelText:l10n?.firstBabyWeight ??
                                        "First Baby Weight (1200–4000gms) *",
                                    hintText: l10n?.enterFirstBabyWeight ?? "Enter First Baby  Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  // ========== BABY 2 ==========
                                  CustomTextField(
                                    labelText:l10n?.secondBabyName ?? "Second Baby  Name *",
                                    hintText:l10n?.enterSecondBabyName ?? "Enter Second Baby Name",
                                    initialValue: state.baby2Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby2NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  ApiDropdown<String>(
                                    labelText:l10n?.secondBabyGender ?? "Second Baby Gender *",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby2Gender.isEmpty
                                        ? null
                                        : state.baby2Gender,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'male':
                                          return l10n?.male ?? '';
                                        case 'female':
                                          return l10n?.female ?? '';
                                        case 'transgender':
                                          return l10n?.transgender ?? '';
                                        default:
                                          return s;
                                      }
                                    },                                    onChanged: (v) =>
                                        bloc.add(Baby2GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  CustomTextField(
                                    labelText:l10n?.secondBabyWeight ??
                                        "Second Baby Weight (1200–4000gms) *",
                                    hintText:l10n?.enterSecondBabyWeight ?? "Enter Second Baby Weight",
                                    initialValue: state.baby2Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby2WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],
                                if (state.numberOfChildren == "Triplets" &&
                                    state.givesBirthToBaby ==
                                        (l10n?.yes ?? 'Yes') &&
                                    state.deliveryOutcome == "Live birth") ...[
                                  // ========== BABY 1 ==========
                                  CustomTextField(
                                    labelText:l10n?.firstBabyName ?? "First Baby  Name *",
                                    hintText: l10n?.enterFirstBabyName ?? "Enter First Baby  Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  ApiDropdown<String>(
                                    labelText:l10n?.firstBabyGender ?? "First Baby Gender *",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty
                                        ? null
                                        : state.baby1Gender,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'male':
                                          return l10n?.male ?? '';
                                        case 'female':
                                          return l10n?.female ?? '';
                                        case 'transgender':
                                          return l10n?.transgender ?? '';
                                        default:
                                          return s;
                                      }
                                    },
                                    onChanged: (v) =>
                                        bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  CustomTextField(
                                    labelText:l10n?.firstBabyWeight ??
                                        "First Baby Weight (1200–4000gms) *",
                                    hintText:l10n?.enterFirstBabyWeight ?? "Enter First Baby Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  // ========== BABY 2 ==========
                                  CustomTextField(
                                    labelText:l10n?.secondBabyName ?? "Second Baby Name *",
                                    hintText:l10n?.enterSecondBabyName ?? "Enter Second Baby Name",
                                    initialValue: state.baby2Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby2NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  ApiDropdown<String>(
                                    labelText:l10n?.secondBabyGender ?? "Second Baby Gender *",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby2Gender.isEmpty
                                        ? null
                                        : state.baby2Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) =>
                                        bloc.add(Baby2GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  CustomTextField(
                                    labelText:l10n?.secondBabyWeight ?? "Second Baby Weight (1200–4000gms) *",
                                    hintText: l10n?.enterSecondBabyWeight ??"Enter Second Baby Weight",
                                    initialValue: state.baby2Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby2WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  // ========== BABY 3 ==========
                                  CustomTextField(
                                    labelText: l10n?.thirdBabyName ?? "Third Baby Name *",
                                    hintText: l10n?.enterThirdBabyName  ?? "Enter Third Baby Name",
                                    initialValue: state.baby3Name,
                                    onChanged: (v) =>
                                        bloc.add(Baby3NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  ApiDropdown<String>(
                                    labelText: l10n?.thirdBabyGender,
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby3Gender.isEmpty
                                        ? null
                                        : state.baby3Gender,
                                    getLabel: (s) {
                                      switch (s) {
                                        case 'male':
                                          return l10n?.male ?? '';
                                        case 'female':
                                          return l10n?.female ?? '';
                                        case 'transgender':
                                          return l10n?.transgender ?? '';
                                        default:
                                          return s;
                                      }
                                    },
                                    onChanged: (v) =>
                                        bloc.add(Baby3GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),

                                  CustomTextField(
                                    labelText:l10n?.thirdBabyWeight ?? "Third Baby Weight (1200–4000gms) *",
                                    hintText: l10n?.enterThirdBabyWeight ?? "Enter Third Baby Weight",
                                    initialValue: state.baby3Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        bloc.add(Baby3WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(
                                    color: AppColors.divider,
                                    thickness: 0.5,
                                    height: 0,
                                  ),
                                ],
                              ],
                            ],

                            ApiDropdown<String>(
                              labelText:
                                  l10n?.beneficiaryAbsentLabel ??
                                  'Is Beneficiary Absent?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.beneficiaryAbsent.isEmpty
                                  ? null
                                  : state.beneficiaryAbsent,
                              getLabel: (s) => s,
                              onChanged: (v) {
                                bloc.add(BeneficiaryAbsentChanged(v ?? ''));
                                // Clear absence reason when switching to 'No'
                                if (v != (l10n?.yes ?? 'Yes')) {
                                  bloc.add(AbsenceReasonChanged(''));
                                }
                              },
                              hintText: l10n?.select ?? 'Select',
                            ),
                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),

                            if (state.beneficiaryAbsent == (l10n?.yes ?? 'Yes'))
                              CustomTextField(
                                labelText: l10n?.reasonForAbsence,
                                hintText: l10n?.reasonForAbsence,
                                initialValue: state.absenceReason,
                                onChanged: (v) =>
                                    bloc.add(AbsenceReasonChanged(v)),
                                validator:
                                    null, // Made non-mandatory as requested
                              ),

                            Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            spreadRadius: 2,
                            offset: const Offset(0, 0), // TOP shadow
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 4.5.h,
                                  child: RoundButton(
                                    title:
                                        l10n?.previousVisitsButton ??
                                        'PREVIOUS VISITS',
                                    color: AppColors.primary,
                                    borderRadius: 4,
                                    onPress: () {
                                      final benId =
                                          widget
                                              .beneficiaryData?['BeneficiaryID']
                                              ?.toString() ??
                                          widget.beneficiaryData?['unique_key']
                                              ?.toString() ??
                                          '';
                                      Navigator.pushNamed(
                                        context,
                                        Route_Names.Previousvisit,
                                        arguments: {'beneficiaryId': benId},
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 45),
                              Expanded(
                                child: SizedBox(
                                  height: 4.5.h,
                                  child: RoundButton(
                                    title: state.isSubmitting
                                        ? (l10n?.savingButton ?? 'SAVING...')
                                        : (l10n?.saveButton ?? 'SAVE'),
                                    color: AppColors.primary,
                                    borderRadius: 4,
                                    onPress: () {
                                      final visitType = state.visitType;

                                      if (_formKey.currentState!.validate()) {
                                        bloc.add(const SubmitPressed());
                                      } else {
                                        if (visitType.isEmpty) {
                                          showAppSnackBar(
                                            context,
                                            l10n?.selectVisitTypeError ??
                                                "Please select visit type",
                                          );
                                        } else {
                                          showAppSnackBar(
                                            context,
                                            l10n?.pleaseFillFieldsCorrectly ??
                                                "Please fill all required fields correctly",
                                          );
                                        }
                                        _scrollToFirstError();
                                      }
                                    },
                                    disabled: state.isSubmitting,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _qtyButton({
  required IconData icon,
  required VoidCallback? onTap,
  required bool enabled,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        //color: enabled ? Colors.white : AppColors.outlineVariant.withOpacity(0.5),
        color: AppColors.primary,

        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 18, color: enabled ? Colors.white : Colors.white),
    ),
  );
}
