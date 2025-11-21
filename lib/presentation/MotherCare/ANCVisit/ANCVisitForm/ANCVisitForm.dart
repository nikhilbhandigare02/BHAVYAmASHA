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
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../data/Local_Storage/tables/followup_form_data_table.dart';
import 'bloc/anvvisitform_bloc.dart';
import 'package:medixcel_new/core/widgets/MultiSelect/MultiSelect.dart';

class Ancvisitform extends StatefulWidget {
  final Map<String, dynamic>? beneficiaryData;

  const Ancvisitform({super.key, this.beneficiaryData});

  @override
  State<Ancvisitform> createState() => _AncvisitformState();
}

class _AncvisitformState extends State<Ancvisitform> {
  late final AnvvisitformBloc _bloc;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    final beneficiaryId = widget.beneficiaryData?['BeneficiaryID'] as String?;
    final householdRefKey = widget.beneficiaryData?['hhId'] as String?;

    if (beneficiaryId == null || householdRefKey == null) {
      throw ArgumentError('Missing required parameters: beneficiaryId or householdRefKey');
    }

    _bloc = AnvvisitformBloc(
      beneficiaryId: beneficiaryId,
      householdRefKey: householdRefKey,
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

  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date $dateString: $e');
      return null;
    }
  }

  // Update form fields with loaded data
  void _updateFormWithData(Map<String, dynamic> formData) {
    // Basic information
    _bloc.add(VisitTypeChanged(formData['visit_type'] ?? ''));
    _bloc.add(PlaceOfAncChanged(formData['place_of_anc'] ?? ''));
    _bloc.add(DateOfInspectionChanged(_parseDate(formData['date_of_inspection'])));
    _bloc.add(HouseNumberChanged(formData['house_number'] ?? ''));
    _bloc.add(WomanNameChanged(formData['woman_name'] ?? ''));
    _bloc.add(HusbandNameChanged(formData['husband_name'] ?? ''));
    _bloc.add(RchNumberChanged(formData['rch_number'] ?? ''));

    // Pregnancy information
    _bloc.add(LmpDateChanged(_parseDate(formData['lmp_date'])));
    _bloc.add(EddDateChanged(_parseDate(formData['edd_date'])));
    _bloc.add(WeeksOfPregnancyChanged(formData['weeks_of_pregnancy']?.toString() ?? ''));

    // Medical information
    _bloc.add(WeightChanged(formData['weight']?.toString() ?? ''));
    _bloc.add(SystolicChanged(formData['systolic']?.toString() ?? ''));
    _bloc.add(DiastolicChanged(formData['diastolic']?.toString() ?? ''));
    _bloc.add(HemoglobinChanged(formData['hemoglobin']?.toString() ?? ''));

    // Checkbox and boolean fields - convert to Yes/No strings
    if (formData['is_breast_feeding'] != null) {
      final isBreastFeeding = formData['is_breast_feeding'] == true || formData['is_breast_feeding'] == 'true';
      _bloc.add(IsBreastFeedingChanged(isBreastFeeding ? 'Yes' : 'No'));
    }

    if (formData['high_risk'] != null) {
      final isHighRisk = formData['high_risk'] == true || formData['high_risk'] == 'true';
      _bloc.add(HighRiskChanged(isHighRisk ? 'Yes' : 'No'));
    }

    // TD Vaccination dates
    _bloc.add(Td1DateChanged(_parseDate(formData['td1_date'])));
    _bloc.add(Td2DateChanged(_parseDate(formData['td2_date'])));
    _bloc.add(TdBoosterDateChanged(_parseDate(formData['td_booster_date'])));

    // Other fields
    _bloc.add(FolicAcidTabletsChanged(formData['folic_acid_tablets'] ?? ''));
    _bloc.add(PreExistingDiseaseChanged(formData['pre_existing_disease'] ?? ''));
  }

  Future<void> _initializeForm() async {
    final data = widget.beneficiaryData;
    String? houseNo;

    // Set beneficiary ID in the bloc if available
    if (data != null) {
      // Log the raw data to verify it's coming through correctly
      print('🔍 RAW BENEFICIARY DATA:');
      data.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });

      // Extract and ensure full IDs are used - preserve original values without modification
      final dataId = data['id']?.toString() ?? '';
      final dataBeneficiaryId = data['BeneficiaryID']?.toString() ?? '';
      final uniqueKey = data['unique_key']?.toString() ?? '';
      final hhId = data['hhId']?.toString() ?? '';

      // Try to load existing form data
      try {
        final localStorageDao = LocalStorageDao();
        final existingForms = await localStorageDao.getFollowupFormsByHouseholdAndBeneficiary(
          formType: FollowupFormDataTable.ancDueRegistration,
          householdId: hhId,
          beneficiaryId: dataBeneficiaryId.isNotEmpty ? dataBeneficiaryId : uniqueKey,
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
              if (formJson is Map && formJson['form_data'] is Map) {
                final formDataMap = formJson['form_data'] as Map<String, dynamic>;
                print('📝 Loaded form data: $formDataMap');

                // Update the form with the loaded data
                _updateFormWithData(formDataMap);
              }
            } catch (e) {
              print('❌ Error parsing form JSON: $e');
            }
          }

          // Process all forms to find matching beneficiary
          for (var form in existingForms) {
            // Try to extract and display name from form_json
            if (form['form_json'] != null) {
              try {
                final formDataJson = jsonDecode(form['form_json'] as String);
                final name = formDataJson['womanName'] ?? formDataJson['name'] ?? 'Not found';
                print('  - Name from form: $name');

                // If this is the current beneficiary, log more details
                if (form['beneficiary_ref_key'] == (dataBeneficiaryId.isNotEmpty ? dataBeneficiaryId : uniqueKey)) {
                  print('  👆 Current beneficiary match!');
                  final formJsonString = jsonEncode(formDataJson);
                  print('  📝 Full form data: ${formJsonString.length > 200 ? formJsonString.substring(0, 200) + '...' : formJsonString}');
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
              final formDataJson = jsonDecode(latestForm['form_json'] as String);
              print('\n✨ Found existing form data for this beneficiary');
            } catch (e) {
              print('⚠️ Error processing form data: $e');
            }
          }
        } else {
          print('ℹ️ No existing ANC forms found for this beneficiary');
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

      print('📌 Selected Beneficiary ID: $beneficiaryIdToUse (${beneficiaryIdToUse?.length ?? 0} chars)');
      print('📌 Household ID: $hhId (${hhId.length} chars)');

      if (beneficiaryIdToUse != null && beneficiaryIdToUse.isNotEmpty) {
        _bloc.add(BeneficiaryIdSet(beneficiaryIdToUse));

        try {
          final beneficiaryRow =
          await LocalStorageDao.instance.getBeneficiaryByUniqueKey(beneficiaryIdToUse);
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

            final womanName = (info['memberName'] ?? info['headName'])?.toString();
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
            if (beneficiaryInfo is Map && beneficiaryInfo['spouseName'] != null) {
              _bloc.add(HusbandNameChanged(beneficiaryInfo['spouseName'].toString()));
              print('👨 Set husband name from beneficiary_info: ${beneficiaryInfo['spouseName']}');
            }
          } catch (e) {
            print('⚠️ Error parsing beneficiary_info: $e');
          }
        }
      } else {
        print('⚠️ No valid beneficiary ID or unique key found in the provided data');
      }

      // Fetch house number from secure storage
      if (dataId.isNotEmpty || dataBeneficiaryId.isNotEmpty) {
        try {
          final storageData = await SecureStorageService.getUserData();
          if (storageData != null && storageData.isNotEmpty) {
            print('🔍 Found data in secure storage, searching for matching beneficiary...');

            try {
              final Map<String, dynamic> parsedData = jsonDecode(storageData);
              if (parsedData['visits'] is List) {
                for (var visit in parsedData['visits']) {
                  try {
                    final visitId = visit['id']?.toString();
                    final visitBeneficiaryId = visit['BeneficiaryID']?.toString();

                    // Try to get houseNo from different possible locations
                    String? visitHouseNo;

                    // 1. Check direct field first
                    visitHouseNo = visit['houseNo']?.toString();

                    // 2. Check nested in beneficiary_info.head_details if not found directly
                    if (visitHouseNo == null && visit['beneficiary_info'] is Map) {
                      final beneficiaryInfo = visit['beneficiary_info'] as Map;
                      if (beneficiaryInfo['head_details'] is Map) {
                        final headDetails = beneficiaryInfo['head_details'] as Map;
                        visitHouseNo = headDetails['houseNo']?.toString();
                        if (visitHouseNo != null) {
                          print('   - Found houseNo in beneficiary_info.head_details');
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
                        final rawBeneficiaryInfo = rawRow['beneficiary_info'] as Map;
                        if (rawBeneficiaryInfo['head_details'] is Map) {
                          final headDetails = rawBeneficiaryInfo['head_details'] as Map;
                          visitHouseNo = headDetails['houseNo']?.toString();
                          if (visitHouseNo != null) {
                            print('   - Found houseNo in _rawRow.beneficiary_info.head_details');
                          }
                        }
                      }
                    }

                    final isMatch = (dataId.isNotEmpty && (visitId == dataId || visitBeneficiaryId == dataId)) ||
                        (dataBeneficiaryId.isNotEmpty && (visitId == dataBeneficiaryId || visitBeneficiaryId == dataBeneficiaryId));

                    if (isMatch) {
                      houseNo = visitHouseNo;
                      print('🏠 Found matching beneficiary in secure storage');
                      print('   - ID: ${visitId ?? 'N/A'}');
                      print('   - BeneficiaryID: ${visitBeneficiaryId ?? 'N/A'}');
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
        print('ℹ️ No valid ID or BeneficiaryID provided for secure storage lookup');
      }

      // Use visitCount passed from previous screen to determine next ANC visit number
      try {
        final dynamic rawVisitCount = data['visitCount'];
        int visitCount = 0;

        if (rawVisitCount is int) {
          visitCount = rawVisitCount;
        } else if (rawVisitCount is String) {
          visitCount = int.tryParse(rawVisitCount) ?? 0;
        }

        final nextVisitNumber = visitCount + 1;
        print('🔢 visitCount from list screen: $visitCount, nextVisitNumber: $nextVisitNumber');

        _bloc.add(VisitNumberChanged(nextVisitNumber.toString()));
      } catch (e) {
        print('⚠️ Error processing visitCount from beneficiaryData: $e');
      }
    }

    // If no data but we have houseNo from storage, set it
    if (houseNo != null) {
      _bloc.add(HouseNumberChanged(houseNo));
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
                final msg = state.error!.isNotEmpty ? state.error! : (l10n?.somethingWentWrong ?? 'Something went wrong');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n?.saveSuccess ?? 'Saved successfully')));
                Navigator.pop(context, true);
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Text(l10n?.ancVisitLabel ?? 'ANC visit', style: TextStyle(fontSize: 14.sp)),
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
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            const SizedBox(height: 12),
                            ApiDropdown<String>(
                              labelText: l10n?.visitTypeLabel ?? 'Visit type *',
                              items: const [
                                'ANC', 'PMSMA'
                              ],
                              value: state.visitType.isEmpty ? null : state.visitType,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(VisitTypeChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                              validator: validateDropdownRequired,
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            ApiDropdown<String>(
                              labelText: l10n?.placeOfAncLabel ?? 'Place of ANC',
                              items: const [
                                'VHSND/Anganwadi',
                                'Health Sub-center/Health & Wealth Centre(HSC/HWC)',
                                'Primary Health Centre(PHC)',
                                'Community Health Centre(CHC)',
                                'Referral Hospital(RH)',
                                'District Hospital(DH)',
                                'Medical College Hospital(MCH)',
                                'PMSMA Site'
                              ],
                              value: state.placeOfAnc.isEmpty ? null : state.placeOfAnc,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(PlaceOfAncChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomDatePicker(
                              labelText: l10n?.dateOfInspectionLabel ?? 'Date of inspection *',
                              hintText: l10n?.dateOfInspectionLabel ?? 'Date of inspection *',
                              initialDate: state.dateOfInspection ?? DateTime.now(),
                              onDateChanged: (d) => bloc.add(DateOfInspectionChanged(d)),
                              validator: (date) => validateDateRequired(date),
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: l10n?.houseNumberLabel ?? 'House number',
                              hintText: l10n?.houseNumberLabel ?? 'House number',
                              initialValue: state.houseNumber,
                              onChanged: (v) => bloc.add(HouseNumberChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.nameOfPregnantWomanLabel ?? 'Name of Pregnant Woman',
                              hintText: l10n?.nameOfPregnantWomanLabel ?? 'Name of Pregnant Woman',
                              initialValue: state.womanName,
                              onChanged: (v) => bloc.add(WomanNameChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.husbandNameLabel ?? "Husband's name",
                              hintText: l10n?.husbandNameLabel ?? "Husband's name",
                              initialValue: state.husbandName,
                              onChanged: (v) => bloc.add(HusbandNameChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.rchNumberLabel ?? 'RCH number',
                              hintText: l10n?.rchNumberLabel ?? 'RCH number',
                              initialValue: state.rchNumber,
                              onChanged: (v) => bloc.add(RchNumberChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            // LMP Date Picker
                            Container(
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: CustomDatePicker(
                                labelText: l10n?.lmpDateLabel ?? 'Date of last menstrual period (LMP) *',
                                hintText: l10n?.lmpDateLabel ?? 'Date of last menstrual period (LMP) *',
                                initialDate: state.lmpDate ?? DateTime.now(),
                                onDateChanged: (d) {
                                  if (d != null) {
                                    bloc.add(LmpDateChanged(d));

                                    final today = DateTime.now();
                                    final difference = today.difference(d).inDays;
                                    final weeksOfPregnancy = (difference / 7).floor();

                                    // Add 1 to account for the first week of pregnancy
                                    final calculatedWeeks = weeksOfPregnancy + 1;

                                    bloc.add(WeeksOfPregnancyChanged(calculatedWeeks.toString()));
                                  }
                                },
                                validator: (date) => validateDateRequired(date),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomDatePicker(
                              labelText: l10n?.eddDateLabel ?? 'Expected date of delivery (EDD)',
                              hintText: l10n?.eddDateLabel ?? 'Expected date of delivery (EDD)',
                              initialDate: state.eddDate,
                              onDateChanged: (d) => bloc.add(EddDateChanged(d)),
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.weeksOfPregnancyLabel ?? 'No. of weeks of pregnancy',
                              hintText: l10n?.weeksOfPregnancyLabel ?? 'No. of weeks of pregnancy',
                              initialValue: state.weeksOfPregnancy,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(WeeksOfPregnancyChanged(v)),
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n?.orderOfPregnancyLabel ?? 'Order of Pregnancy(Gravida)', style: TextStyle(fontSize: 14.sp)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _qtyButton(icon: Icons.remove, onTap: () => bloc.add(const GravidaDecremented())),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 40,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.outlineVariant),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('${state.gravida}'),
                                    ),
                                    const SizedBox(width: 6),
                                    _qtyButton(icon: Icons.add, onTap: () => bloc.add(const GravidaIncremented())),
                                  ],
                                ),
                              ],
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 16),
                            ApiDropdown<String>(
                              labelText: l10n?.isWomanBreastfeedingLabel ?? 'Is woman breastfeeding?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.isBreastFeeding.isEmpty ? null : state.isBreastFeeding,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(IsBreastFeedingChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomDatePicker(
                              labelText: l10n?.td1DateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) 1',
                              hintText: l10n?.td1DateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) 1',
                              initialDate: state.td1Date,
                              onDateChanged: (d) => bloc.add(Td1DateChanged(d)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomDatePicker(
                              labelText: l10n?.td2DateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) 2',
                              hintText: l10n?.td2DateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) 2',
                              initialDate: state.td2Date,
                              readOnly: true,
                              onDateChanged: (d) => bloc.add(Td2DateChanged(d)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomDatePicker(
                              labelText: l10n?.tdBoosterDateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) booster',
                              hintText: l10n?.tdBoosterDateLabel ?? 'Date of T.D(Tetanus and adult diphtheria) booster',
                              initialDate: state.tdBoosterDate,
                              readOnly: true,
                              onDateChanged: (d) => bloc.add(TdBoosterDateChanged(d)),
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.folicAcidTabletsLabel ?? 'Number of Folic Acid tablets given',
                              hintText: l10n?.folicAcidTabletsLabel ?? 'Number of Folic Acid tablets given',
                              initialValue: state.folicAcidTablets,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(FolicAcidTabletsChanged(v)),
                              validator: validateTabletCount,
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            ApiDropdown<String>(
                              labelText: l10n?.preExistingDiseaseLabel ?? 'Pre - Existing disease',
                              items: [
                                l10n?.diseaseNone ?? 'None',
                                l10n?.diseaseDiabetes ?? 'Diabetes',
                                l10n?.diseaseHypertension ?? 'Hypertension',
                                l10n?.diseaseAnemia ?? 'Anemia',
                                l10n?.diseaseOther ?? 'Other',
                              ],
                              value: state.preExistingDisease.isEmpty ? null : state.preExistingDisease,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(PreExistingDiseaseChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.weightKgLabel ?? 'Weight (Kg)',
                              hintText: l10n?.weightKgLabel ?? 'Weight (Kg)',
                              initialValue: state.weight,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(WeightChanged(v)),
                              validator: validateWeightKg,
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.systolicLabel ?? 'Systolic',
                              hintText: l10n?.systolicLabel ?? 'Systolic',
                              initialValue: state.systolic,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(SystolicChanged(v)),
                              readOnly: true,
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.diastolicLabel ?? 'Diastolic',
                              hintText: l10n?.diastolicLabel ?? 'Diastolic',
                              initialValue: state.diastolic,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(DiastolicChanged(v)),
                              readOnly: true,
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            CustomTextField(
                              labelText: l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                              hintText: l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                              initialValue: state.hemoglobin,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(HemoglobinChanged(v)),
                              readOnly: true,
                            ),

                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            ApiDropdown<String>(
                              labelText: l10n?.anyHighRiskProblemLabel ?? 'Is there any high risk problem?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.highRisk.isEmpty ? null : state.highRisk,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(HighRiskChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),
                            if (state.highRisk == 'Yes') ...[
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                              MultiSelect<String>(
                                items: [
                                  'Severe Anemia',
                                  'Hypertensive Disorder',
                                  'Syphilis, HIV Positive, Hepatitis B, Hepatitis C',
                                  'Gestational Diabetes',
                                  'Hypothyroidism',
                                ].map((risk) => MultiSelectItem<String>(
                                  label: risk,
                                  value: risk,
                                )).toList(),
                                selectedValues: state.selectedRisks,
                                labelText: 'Select Risks',
                                hintText: 'Select Risks',
                                onSelectionChanged: (values) {
                                  bloc.add(SelectedRisksChanged(List<String>.from(values)));
                                },
                              ),
                              const SizedBox(height: 16),
                              ApiDropdown<String>(
                                labelText: 'Any complication leading to abortion?',
                                items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                                value: state.hasAbortionComplication.isEmpty ? null : state.hasAbortionComplication,
                                getLabel: (s) => s,
                                onChanged: (v) => bloc.add(HasAbortionComplicationChanged(v ?? '')),
                                hintText: l10n?.select ?? 'Select',
                              ),
                              if (state.hasAbortionComplication == 'Yes') ...[
                                const SizedBox(height: 16),
                                CustomDatePicker(
                                  labelText: 'Date of Abortion',
                                  hintText: 'Date of Abortion',
                                  initialDate: state.abortionDate,
                                  onDateChanged: (d) => bloc.add(AbortionDateChanged(d)),
                                ),
                              ],
                            ],
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                            if (int.tryParse(state.weeksOfPregnancy) != null &&
                                int.parse(state.weeksOfPregnancy) < 3) ...[
                              ApiDropdown<String>(
                                labelText: 'Did the pregnant woman give birth to a baby?',
                                items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                                value: state.givesBirthToBaby.isEmpty ? null : state.givesBirthToBaby,
                                getLabel: (s) => s,
                                onChanged: (v) => bloc.add(GivesBirthToBaby(v ?? '')),
                                hintText: l10n?.select ?? 'Select',
                              ),
                              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                              if (state.givesBirthToBaby == (l10n?.yes ?? 'Yes')) ...[
                                ApiDropdown<String>(
                                  labelText: 'Delivery outcome *',
                                  items: ["Live birth", "Still birth", "Newborn death"],
                                  value: state.deliveryOutcome.isEmpty ? null : state.deliveryOutcome,
                                  getLabel: (s) => s,
                                  onChanged: (v) => bloc.add(DeliveryOutcomeChanged(v ?? '')),
                                  hintText: l10n?.select ?? 'Select',
                                  validator: state.givesBirthToBaby == 'Yes' ? validateDropdownRequired : null,
                                ),
                                Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                if (state.deliveryOutcome == "Live birth") ...[
                                  ApiDropdown<String>(
                                    labelText: 'Number of Children *',
                                    items: ["One Child", "Twins", "Triplets"],
                                    value: state.numberOfChildren.isEmpty ? null : state.numberOfChildren,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(NumberOfChildrenChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                ],
                                if (state.numberOfChildren == "One Child") ...[
                                  // Baby 1 Name
                                  CustomTextField(
                                    labelText: "Baby's Name*",
                                    hintText: "Enter Baby's Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) => bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  // Baby 1 Gender
                                  ApiDropdown<String>(
                                    labelText: "Baby's Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty ? null : state.baby1Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  // Baby 1 Weight
                                  CustomTextField(
                                    labelText: "Baby's Weight (1200–4000gms)*",
                                    hintText: "Enter Baby's Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                ],
                                if (state.numberOfChildren == "Twins") ...[
                                  CustomTextField(
                                    labelText: "First Baby  Name*",
                                    hintText: "Enter First Baby  Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) => bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  ApiDropdown<String>(
                                    labelText: "First Baby  Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty ? null : state.baby1Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  CustomTextField(
                                    labelText: "First Baby Weight (1200–4000gms)*",
                                    hintText: "Enter First Baby  Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  // ========== BABY 2 ==========
                                  CustomTextField(
                                    labelText: "Second Baby  Name*",
                                    hintText: "Enter Second Baby Name",
                                    initialValue: state.baby2Name,
                                    onChanged: (v) => bloc.add(Baby2NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  ApiDropdown<String>(
                                    labelText: "Second Baby Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby2Gender.isEmpty ? null : state.baby2Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby2GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  CustomTextField(
                                    labelText: "Second Baby Weight (1200–4000gms)*",
                                    hintText: "Enter Second Baby Weight",
                                    initialValue: state.baby2Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby2WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                ],
                                if (state.numberOfChildren == "Triplets") ...[
                                  // ========== BABY 1 ==========
                                  CustomTextField(
                                    labelText: "First Baby  Name*",
                                    hintText: "Enter First Baby  Name",
                                    initialValue: state.baby1Name,
                                    onChanged: (v) => bloc.add(Baby1NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  ApiDropdown<String>(
                                    labelText: "First Baby Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby1Gender.isEmpty ? null : state.baby1Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby1GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  CustomTextField(
                                    labelText: "First Baby Weight (1200–4000gms)*",
                                    hintText: "Enter First Baby Weight",
                                    initialValue: state.baby1Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby1WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  // ========== BABY 2 ==========
                                  CustomTextField(
                                    labelText: "Second Baby Name*",
                                    hintText: "Enter Second Baby Name",
                                    initialValue: state.baby2Name,
                                    onChanged: (v) => bloc.add(Baby2NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  ApiDropdown<String>(
                                    labelText: "Second Baby Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby2Gender.isEmpty ? null : state.baby2Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby2GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  CustomTextField(
                                    labelText: "Second Baby Weight (1200–4000gms)*",
                                    hintText: "Enter Second Baby Weight",
                                    initialValue: state.baby2Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby2WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  // ========== BABY 3 ==========
                                  CustomTextField(
                                    labelText: "Third Baby Name*",
                                    hintText: "Enter Third Baby Name",
                                    initialValue: state.baby3Name,
                                    onChanged: (v) => bloc.add(Baby3NameChanged(v)),
                                    validator: validateRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  ApiDropdown<String>(
                                    labelText: "Third Baby Gender*",
                                    items: ["Male", "Female", "Transgender"],
                                    value: state.baby3Gender.isEmpty ? null : state.baby3Gender,
                                    getLabel: (s) => s,
                                    onChanged: (v) => bloc.add(Baby3GenderChanged(v ?? "")),
                                    hintText: l10n?.select ?? 'Select',
                                    validator: validateDropdownRequired,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                                  CustomTextField(
                                    labelText: "Third Baby Weight (1200–4000gms)*",
                                    hintText: "Enter Third Baby Weight",
                                    initialValue: state.baby3Weight,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(Baby3WeightChanged(v)),
                                    validator: validateBabyWeight,
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                ],
                              ],
                            ],

                            ApiDropdown<String>(
                              labelText: l10n?.beneficiaryAbsentLabel ?? 'Is Beneficiary Absent?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.beneficiaryAbsent.isEmpty ? null : state.beneficiaryAbsent,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(BeneficiaryAbsentChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: RoundButton(
                                  title: l10n?.previousVisitsButton ?? 'PREVIOUS VISITS',
                                  color: AppColors.primary,
                                  borderRadius: 8,
                                  onPress: () {
                                    Navigator.pushNamed(context, Route_Names.Previousvisit);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: RoundButton(
                                  title: state.isSubmitting ? (l10n?.savingButton ?? 'SAVING...') : (l10n?.saveButton ?? 'SAVE'),
                                  color: AppColors.primary,
                                  borderRadius: 8,
                                  onPress: () {
                                    // Validate the form before submission
                                    if (_formKey.currentState!.validate()) {
                                      // Form is valid, proceed with submission
                                      bloc.add(const SubmitPressed());
                                    } else {
                                      // Form is invalid, show error message
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please fill all required fields correctly')),
                                      );
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

Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 18, color: Colors.black87),
    ),
  );
}