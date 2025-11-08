import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'bloc/anvvisitform_bloc.dart';

class Ancvisitform extends StatefulWidget {
  final Map<String, dynamic>? beneficiaryData;

  const Ancvisitform({super.key, this.beneficiaryData});

  @override
  State<Ancvisitform> createState() => _AncvisitformState();
}

class _AncvisitformState extends State<Ancvisitform> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Create the bloc with the initial state
    final bloc = AnvvisitformBloc();

    // Prefill data if we have beneficiary data
    if (widget.beneficiaryData != null) {
      final data = widget.beneficiaryData!;
      final rawRow = data['_rawRow'] as Map<String, dynamic>?;

      // Set initial values
      bloc.add(LmpDateChanged(DateTime.now()));

      if (data['Name'] != null) {
        bloc.add(WomanNameChanged(data['Name'].toString()));
      }

      if (data['HusbandName'] != null) {
        bloc.add(HusbandNameChanged(data['HusbandName'].toString()));
      }

      if (rawRow?['rch_number'] != null) {
        bloc.add(RchNumberChanged(rawRow!['rch_number'].toString()));
      }

      if (rawRow?['house_number'] != null) {
        bloc.add(HouseNumberChanged(rawRow!['house_number'].toString()));
      } else if (data['hhId'] != null) {
        bloc.add(HouseNumberChanged(data['hhId'].toString()));
      }
    } else {
      // If no beneficiary data, just set LMP to current date
      bloc.add(LmpDateChanged(DateTime.now()));
    }

    return BlocProvider.value(
      value: bloc,
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
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text('${state.ancVisitNo}', style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          const SizedBox(height: 12),
                          ApiDropdown<String>(
                            labelText: l10n?.visitTypeLabel ?? 'Visit type *',
                            items: [
                              l10n?.visitTypeHome ?? 'Home',
                              l10n?.visitTypeSubcenter ?? 'Subcenter',
                              l10n?.visitTypePhc ?? 'PHC',
                              l10n?.visitTypeHospital ?? 'Hospital',
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
                              l10n?.visitTypeHome ?? 'Home',
                              l10n?.visitTypeSubcenter ?? 'Subcenter',
                              l10n?.visitTypePhc ?? 'PHC',
                              l10n?.visitTypeHospital ?? 'Hospital',
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
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: l10n?.diastolicLabel ?? 'Diastolic',
                            hintText: l10n?.diastolicLabel ?? 'Diastolic',
                            initialValue: state.diastolic,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(DiastolicChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                            hintText: l10n?.hemoglobinLabel ?? 'Hemoglobin (HB)',
                            initialValue: state.hemoglobin,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(HemoglobinChanged(v)),
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
