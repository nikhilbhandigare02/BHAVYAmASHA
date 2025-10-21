import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'bloc/anvvisitform_bloc.dart';

class Ancvisitform extends StatefulWidget {
  const Ancvisitform({super.key});

  @override
  State<Ancvisitform> createState() => _AncvisitformState();
}

class _AncvisitformState extends State<Ancvisitform> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnvvisitformBloc(),
      child: Scaffold(
        appBar: const AppHeader(
          screenTitle: 'ANC Visit Form',
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<AnvvisitformBloc, AnvvisitformState>(
            listener: (context, state) {
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
              }
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
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
                            child: Text('ANC visit', style: Theme.of(context).textTheme.titleSmall),
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
                            labelText: 'Visit type *',
                            items: const ['Home', 'Subcenter', 'PHC', 'Hospital'],
                            value: state.visitType.isEmpty ? null : state.visitType,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(VisitTypeChanged(v ?? '')),
                            hintText: 'Select',
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          ApiDropdown<String>(
                            labelText: 'Place of ANC',
                            items: const ['Home', 'Subcenter', 'PHC', 'Hospital'],
                            value: state.placeOfAnc.isEmpty ? null : state.placeOfAnc,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(PlaceOfAncChanged(v ?? '')),
                            hintText: 'Select',
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomDatePicker(
                            labelText: 'Date of inspection *',
                            initialDate: state.dateOfInspection,
                            onDateChanged: (d) => bloc.add(DateOfInspectionChanged(d)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: 'House number',
                            initialValue: state.houseNumber,
                            onChanged: (v) => bloc.add(HouseNumberChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Name of Pregnant Woman',
                            initialValue: state.womanName,
                            onChanged: (v) => bloc.add(WomanNameChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: "Husband's name",
                            initialValue: state.husbandName,
                            onChanged: (v) => bloc.add(HusbandNameChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'RCH number',
                            initialValue: state.rchNumber,
                            onChanged: (v) => bloc.add(RchNumberChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Container(
                            decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.all(Radius.circular(4))),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: CustomDatePicker(
                              labelText: 'Date of last menstrual period (LMP) *',
                              initialDate: state.lmpDate,
                              onDateChanged: (d) => bloc.add(LmpDateChanged(d)),
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomDatePicker(
                            labelText: 'Expected date of delivery (EDD)',
                            initialDate: state.eddDate,
                            onDateChanged: (d) => bloc.add(EddDateChanged(d)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'No. of weeks of pregnancy',
                            initialValue: state.weeksOfPregnancy,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(WeeksOfPregnancyChanged(v)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order of Pregnancy(Gravida)'),
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
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 16),
                          ApiDropdown<String>(
                            labelText: 'Is woman breastfeeding?',
                            items: const ['Yes', 'No'],
                            value: state.isBreastFeeding.isEmpty ? null : state.isBreastFeeding,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(IsBreastFeedingChanged(v ?? '')),
                            hintText: 'Select',
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomDatePicker(
                            labelText: 'Date of T.D(Tetanus and adult diphtheria) 1',
                            initialDate: state.td1Date,
                            onDateChanged: (d) => bloc.add(Td1DateChanged(d)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomDatePicker(
                            labelText: 'Date of T.D(Tetanus and adult diphtheria) 2',
                            initialDate: state.td2Date,
                            onDateChanged: (d) => bloc.add(Td2DateChanged(d)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomDatePicker(
                            labelText: 'Date of T.D(Tetanus and adult diphtheria) booster',
                            initialDate: state.tdBoosterDate,
                            onDateChanged: (d) => bloc.add(TdBoosterDateChanged(d)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Number of Folic Acid tablets given',
                            initialValue: state.folicAcidTablets,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(FolicAcidTabletsChanged(v)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ApiDropdown<String>(
                            labelText: 'Pre - Existing disease',
                            items: const ['None', 'Diabetes', 'Hypertension', 'Anemia', 'Other'],
                            value: state.preExistingDisease.isEmpty ? null : state.preExistingDisease,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(PreExistingDiseaseChanged(v ?? '')),
                            hintText: 'Select',
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Weight (Kg)',
                            initialValue: state.weight,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(WeightChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Systolic',
                            initialValue: state.systolic,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(SystolicChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Diastolic',
                            initialValue: state.diastolic,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(DiastolicChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: 'Hemoglobin (HB)',
                            initialValue: state.hemoglobin,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(HemoglobinChanged(v)),
                          ),

                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ApiDropdown<String>(
                            labelText: 'Is there any high risk problem?',
                            items: const ['Yes', 'No'],
                            value: state.highRisk.isEmpty ? null : state.highRisk,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(HighRiskChanged(v ?? '')),
                            hintText: 'Select',
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ApiDropdown<String>(
                            labelText: 'Is Beneficiary Absent?',
                            items: const ['Yes', 'No'],
                            value: state.beneficiaryAbsent.isEmpty ? null : state.beneficiaryAbsent,
                            getLabel: (s) => s,
                            onChanged: (v) => bloc.add(BeneficiaryAbsentChanged(v ?? '')),
                            hintText: 'Select',
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
                                title: 'PREVIOUS VISITS',
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
                                title: state.isSubmitting ? 'SAVING...' : 'SAVE',
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
