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
import 'dart:convert';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';
import 'bloc/anvvisitform_bloc.dart';

class Ancvisitform extends StatefulWidget {
  final Map<String, dynamic>? beneficiaryData;

  const Ancvisitform({super.key, this.beneficiaryData});

  @override
  State<Ancvisitform> createState() => _AncvisitformState();
}

class _AncvisitformState extends State<Ancvisitform> {
  late final AnvvisitformBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AnvvisitformBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    final data = widget.beneficiaryData;
    String? houseNo;
    
    // Set beneficiary ID in the bloc if available
    if (data != null) {
      print('🔍 Initializing form with beneficiary data: ${jsonEncode(data)}');
      
      final dataId = data['id']?.toString();
      final dataBeneficiaryId = data['BeneficiaryID']?.toString();
      final uniqueKey = data['unique_key']?.toString();
      
      print('🔑 Extracted IDs - dataId: $dataId, dataBeneficiaryId: $dataBeneficiaryId, uniqueKey: $uniqueKey');
      
      // Use the most specific ID available
      String? beneficiaryIdToUse;
      
      if (dataId != null) {
        beneficiaryIdToUse = dataId;
        print('📌 Using ID from dataId: $dataId');
      } else if (dataBeneficiaryId != null) {
        beneficiaryIdToUse = dataBeneficiaryId;
        print('📌 Using ID from dataBeneficiaryId: $dataBeneficiaryId');
      } else if (uniqueKey != null) {
        beneficiaryIdToUse = uniqueKey;
        print('📌 Using unique_key as ID: $uniqueKey');
      }
      
      if (beneficiaryIdToUse != null) {
        _bloc.add(BeneficiaryIdSet(beneficiaryIdToUse));
      } else {
        print('⚠️ No valid beneficiary ID or unique key found in the provided data');
      }
      
      if (dataId != null || dataBeneficiaryId != null) {
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
                    
                    final isMatch = (dataId != null && (visitId == dataId || visitBeneficiaryId == dataId)) ||
                                 (dataBeneficiaryId != null && (visitId == dataBeneficiaryId || visitBeneficiaryId == dataBeneficiaryId));
                    
                    if (isMatch) {
                      houseNo = visitHouseNo;
                      print('🏠 Found matching beneficiary in secure storage');
                      print('   - ID: ${visitId ?? 'N/A'}');
                      print('   - BeneficiaryID: ${visitBeneficiaryId ?? 'N/A'}');
                      print('   - House No: ${houseNo ?? 'Not found'}');
                      
                      // Print the full visit data for debugging
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
    }
    
    // Set initial values
    _bloc.add(LmpDateChanged(DateTime.now()));

    if (data != null) {
      // Set name if available
      if (data['Name'] != null) {
        _bloc.add(WomanNameChanged(data['Name'].toString()));
      }

      // Set husband's name if available
      if (data['HusbandName'] != null) {
        _bloc.add(HusbandNameChanged(data['HusbandName'].toString()));
      }

      // Set RCH number if available
      final rchNumber = data['_rawRow']?['rch_number'];
      if (rchNumber != null) {
        _bloc.add(RchNumberChanged(rchNumber.toString()));
      }

      // Set house number - prefer secure storage value over raw data
      if (houseNo != null) {
        _bloc.add(HouseNumberChanged(houseNo));
      } else {
        final rawHouseNo = data['_rawRow']?['houseNo'];
        if (rawHouseNo != null) {
          _bloc.add(HouseNumberChanged(rawHouseNo.toString()));
        }
      }

      // Set beneficiary ID from the first available source
      if (data['id'] != null) {
        _bloc.add(BeneficiaryIdSet(data['id'].toString()));
      } else if (data['_rawRow']?['id'] != null) {
        _bloc.add(BeneficiaryIdSet(data['_rawRow']!['id'].toString()));
      } else if (data['BeneficiaryID'] != null) {
        _bloc.add(BeneficiaryIdSet(data['BeneficiaryID'].toString()));
      }
    }  // If no data but we have houseNo from storage, set it
      if (houseNo != null) {
        _bloc.add(HouseNumberChanged(houseNo));
      }
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
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              final bloc = context.read<AnvvisitformBloc>();

              return Column(
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
                          FutureBuilder<int>(
                            future: state.beneficiaryId != null && state.beneficiaryId!.isNotEmpty
                                ? SecureStorageService.getSubmissionCount(state.beneficiaryId!)
                                : Future.value(0),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text(
                                  '$count',
                                  style:  TextStyle(fontSize: 14.sp, ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          const SizedBox(height: 12),
                          ApiDropdown<String>(
                            labelText: l10n?.visitTypeLabel ?? 'Visit type *',
                            items: [
                              'ANC', 'PMSMA'
                            ],
                            value: state.visitType.isEmpty ? null : state.visitType,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(VisitTypeChanged(v ?? '')),
                            hintText: l10n?.select ?? 'Select',
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          ApiDropdown<String>(
                            labelText: l10n?.placeOfAncLabel ?? 'Place of ANC',
                            items: [
                              'VHSND/Anganwadi', 'Health Sub-center/Health & Wealth Centre(HSC/HWC)','Primary Health Centre(PHC)','Community Health Centre(CHC)','Referral Hospital(RH)','District Hospital(DH)','Medical College Hospital(MCH)','PMSMA Site'
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

                          Container(
                            decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.all(Radius.circular(4))),
                            child: CustomDatePicker(
                              labelText: l10n?.lmpDateLabel ?? 'Date of last menstrual period (LMP) *',
                              hintText: l10n?.lmpDateLabel ?? 'Date of last menstrual period (LMP) *',
                              initialDate: state.lmpDate ?? DateTime.now(),
                              onDateChanged: (d) => bloc.add(LmpDateChanged(d)),
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
                              Text(l10n?.orderOfPregnancyLabel ?? 'Order of Pregnancy(Gravida)', style: TextStyle(fontSize: 14.sp),),
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
                                onPress: () => bloc.add(const SubmitPressed()),
                                disabled: state.isSubmitting,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
