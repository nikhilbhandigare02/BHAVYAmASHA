import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/RoundButton/RoundButton.dart';
import '../../../l10n/app_localizations.dart';
import 'bloc/outcome_form_bloc.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';

class OutcomeFormPage extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;

  const OutcomeFormPage({super.key, required this.beneficiaryData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutcomeFormBloc()
        ..add(OutcomeFormInitialized(
          householdId: beneficiaryData['householdId']?.toString(),
          beneficiaryId: beneficiaryData['beneficiaryId']?.toString(),
        )),
      child: _OutcomeFormView(beneficiaryData: beneficiaryData),
    );
  }
}

class _OutcomeFormView extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;

  _OutcomeFormView({required this.beneficiaryData}) {
    print('OutcomeFormView created with beneficiaryData: $beneficiaryData');
  }

  void _logState(OutcomeFormState state) {
    print('Current state - householdId: ${state.householdId}, beneficiaryId: ${state.beneficiaryId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(screenTitle: l10n.deliveryOutcomeTitle, showBack: true),
      body: SafeArea(
        bottom: true,
        child: BlocConsumer<OutcomeFormBloc, OutcomeFormState>(
          listenWhen: (previous, current) => true,
          listener: (context, state) {
            _logState(state);
            ScaffoldMessenger.of(context).clearSnackBars();

            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }

            if (state.submitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.dataSavedSuccessMessage),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            return Column(
              children: [

                _SectionHeader(title: l10n.deliveryOutcomeDetails),
 
                FutureBuilder<int>(
                  future: () async {
                    try {
                      final beneficiaryId = beneficiaryData['BeneficiaryID']?.toString();
                      print('🔍 Checking submission count for BeneficiaryID: $beneficiaryId');

                      if (beneficiaryId == null || beneficiaryId.isEmpty) {
                        print('⚠️ No valid BeneficiaryID found in beneficiaryData: $beneficiaryData');
                        return 0;
                      }

                      final count = await SecureStorageService.getSubmissionCount(beneficiaryId);
                      print('✅ Found $count submissions for BeneficiaryID: $beneficiaryId');
                      return count;
                    } catch (e) {
                      print('❌ Error getting submission count: $e');
                      return 0;
                    }
                  }(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder<void>(
                  future: () async {
                    try {
                      final db = await DatabaseProvider.instance.database;
                      final beneficiaryId = beneficiaryData['BeneficiaryID']?.toString() ?? beneficiaryData['beneficiaryId']?.toString() ?? beneficiaryData['unique_key']?.toString() ?? '';
                      final ancKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
                      if (beneficiaryId.isEmpty || ancKey.isEmpty) return;
                      final results = await db.query(
                        FollowupFormDataTable.table,
                        where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
                        whereArgs: [beneficiaryId, ancKey],
                        orderBy: 'created_date_time DESC',
                        limit: 1,
                      );
                      if (results.isEmpty) return;
                      final formJsonRaw = results.first['form_json']?.toString() ?? '';
                      final createdAt = results.first['created_date_time']?.toString() ?? '';
                      DateTime? createdDate;
                      try {
                        createdDate = DateTime.tryParse(createdAt);
                      } catch (_) {}
                      if (createdDate != null) {
                        context.read<OutcomeFormBloc>().add(DeliveryDateChanged(createdDate));
                      }
                      if (formJsonRaw.isEmpty) return;
                      final decoded = jsonDecode(formJsonRaw);
                      if (decoded is Map && decoded['form_data'] is Map) {
                        final fd = Map<String, dynamic>.from(decoded['form_data'] as Map);
                        final flag = (fd['gives_birth_to_baby']?.toString() ?? '').toLowerCase();
                        if (flag == 'yes') {
                          print('ANC record with gives_birth_to_baby YES: ${results.first}');
                        }
                        final weeks = fd['weeks_of_pregnancy']?.toString() ?? '';
                        if (weeks.isNotEmpty) {
                          context.read<OutcomeFormBloc>().add(GestationWeeksChanged(weeks));
                        }
                        final children = fd['number_of_children']?.toString() ?? '';
                        if (children.isNotEmpty) {
                          final t = children.trim().toLowerCase();
                          String numeric;
                          if (t == 'one child' || t == 'one' || t == '1') {
                            numeric = '1';
                          } else if (t == 'twins' || t == 'two' || t == '2') {
                            numeric = '2';
                          } else if (t == 'triplets' || t == 'three' || t == '3') {
                            numeric = '3';
                          } else {
                            final n = int.tryParse(children);
                            numeric = n?.toString() ?? children;
                          }
                          context.read<OutcomeFormBloc>().add(OutcomeCountChanged(numeric));
                        }
                      }
                    } catch (e) {
                      print('Error loading ANC gives_birth_to_baby record: $e');
                    }
                  }(),
                  builder: (context, snapshot) => const SizedBox.shrink(),
                ),

                // Form Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: _OutcomeFormFields(beneficiaryData: beneficiaryData),
                  ),
                ),
              ],
            )
           ;
          }
        ),
      ),
    );
  }
}

class _OutcomeFormFields extends StatelessWidget {
  final Map<String, dynamic> beneficiaryData;
  
  const _OutcomeFormFields({required this.beneficiaryData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<OutcomeFormBloc>();
    final state = context.watch<OutcomeFormBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomDatePicker(
          initialDate: state.deliveryDate,
          isEditable: true,
          labelText: l10n.deliveryDate,
          onDateChanged: (d) => bloc.add(DeliveryDateChanged(d)),
          readOnly: true,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            children: [
              Expanded( 
                child: Text(
                  l10n.gestationWeeks,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bloc.add(GestationWeeksChanged(v)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  controller: TextEditingController(text: state.gestationWeeks),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        CustomTextField(
          labelText: l10n.deliveryTime,
          hintText: l10n.deliveryTimeHint,
          initialValue: state.deliveryTime ?? '',
          keyboardType: TextInputType.datetime,
          onChanged: (v) => bloc.add(DeliveryTimeChanged(v)),
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),


        ApiDropdown<String>(
          items: [

            'Institutional',
            'Non-Institutional',
            'Other',
          ],
          getLabel: (s) => s,
          value:
              state.placeOfDelivery.isEmpty ||
                  ![
                    l10n.select,
                    'Institutional',
                    'Non-Institutional',
                    'Other',
                  ].contains(state.placeOfDelivery)
              ? l10n.select
              : state.placeOfDelivery,
          onChanged: (v) => bloc.add(PlaceOfDeliveryChanged(v ?? '')),
          labelText: l10n.selectPlaceOfDelivery,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.placeOfDelivery == 'Other') ...[
          const SizedBox(height: 8),
          CustomTextField(
            labelText: 'Enter other place of delivery',
            hintText: 'Enter place',
            initialValue: state.otherPlaceOfDeliveryName ?? '',
            onChanged: (v) => bloc.add(OtherPlaceOfDeliveryNameChanged(v)),
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        // Replace the institutional dropdowns section with this fixed code:

        if (state.placeOfDelivery == 'Institutional') ...[
          const SizedBox(height: 16),
          ApiDropdown<String>(
            items: [
              l10n.select,
              'Public',
              'Private',
            ],
            getLabel: (s) => s,
            value: (state.institutionalPlaceType == null ||
                state.institutionalPlaceType!.isEmpty ||
                ![l10n.select, 'Public', 'Private'].contains(state.institutionalPlaceType))
                ? l10n.select
                : state.institutionalPlaceType!,
            onChanged: (v) => bloc.add(InstitutionalPlaceTypeChanged(v ?? '')),
            labelText: 'Type of Institution',
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
          if (state.institutionalPlaceType == 'Public') ...[
            ApiDropdown<String>(
              items: [
                l10n.select,
                'Sub-Center',
                'PHC',
                'CHC',
                'RH',
                'DH',
                'MCH',
              ],
              getLabel: (s) => s,
              value: (state.institutionalPlaceOfDelivery == null ||
                  state.institutionalPlaceOfDelivery!.isEmpty ||
                  ![l10n.select, 'Sub-Center', 'PHC', 'CHC', 'RH', 'DH', 'MCH']
                      .contains(state.institutionalPlaceOfDelivery))
                  ? l10n.select
                  : state.institutionalPlaceOfDelivery!,
              onChanged: (v) => bloc.add(InstitutionalPlaceOfDeliveryChanged(v ?? '')),
              labelText: 'Institutional place of delivery',
            ),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            const SizedBox(height: 8),

          ] else if (state.institutionalPlaceType == 'Private') ...[
            ApiDropdown<String>(
              items: [
                l10n.select,
                'Nursing Home',
                'Hospital',
              ],
              getLabel: (s) => s,
              value: (state.institutionalPlaceOfDelivery == null ||
                  state.institutionalPlaceOfDelivery!.isEmpty ||
                  ![l10n.select, 'Nursing Home', 'Hospital']
                      .contains(state.institutionalPlaceOfDelivery))
                  ? l10n.select
                  : state.institutionalPlaceOfDelivery!,
              onChanged: (v) => bloc.add(InstitutionalPlaceOfDeliveryChanged(v ?? '')),
              labelText: 'Institutional place of delivery',
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            const SizedBox(height: 8),
            ApiDropdown<String>(
              items: [
                l10n.select,
                'ANM',
                'LHV',
                'Doctor',
                'Staff Nurse',
                'Relative TBA',
              ],
              getLabel: (s) => s,
              value: (state.conductedBy == null ||
                  state.conductedBy!.isEmpty ||
                  ![l10n.select, 'ANM', 'LHV', 'Doctor', 'Staff Nurse', 'Relative TBA'].contains(state.conductedBy))
                  ? l10n.select
                  : state.conductedBy!,
              onChanged: (v) => bloc.add(ConductedByChanged(v ?? '')),
              labelText: 'Who conducted the delivery?',
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          ],
          const SizedBox(height: 8),
          ApiDropdown<String>(
            items: [
              l10n.select,
              'ANM',
              'LHV',
              'Doctor',
              'Staff Nurse',
              'Relative TBA',
            ],
            getLabel: (s) => s,
            value: (state.conductedBy == null ||
                state.conductedBy!.isEmpty ||
                ![l10n.select, 'ANM', 'LHV', 'Doctor', 'Staff Nurse', 'Relative TBA'].contains(state.conductedBy))
                ? l10n.select
                : state.conductedBy!,
            onChanged: (v) => bloc.add(ConductedByChanged(v ?? '')),
            labelText: 'Who conducted the delivery?',
          ),
          const SizedBox(height: 8),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        if (state.placeOfDelivery == 'Non-Institutional') ...[

          ApiDropdown<String>(
            items: [
              l10n.select,
              'Home based delivery',
              'In transit',
              'Other',
            ],
            getLabel: (s) => s,
            value: (state.nonInstitutionalPlaceType == null ||
                state.nonInstitutionalPlaceType!.isEmpty ||
                ![l10n.select, 'Home based delivery', 'In transit', 'Other']
                    .contains(state.nonInstitutionalPlaceType))
                ? l10n.select
                : state.nonInstitutionalPlaceType!,
            onChanged: (v) => bloc.add(NonInstitutionalPlaceTypeChanged(v ?? '')),
            labelText: 'Non-institutional place of delivery',
          ),

          const SizedBox(height: 8),
          if (state.nonInstitutionalPlaceType == 'Other') ...[
            CustomTextField(
              labelText: 'Enter name of other non-institutional delivery',
              hintText: 'Enter name',
              initialValue: state.otherNonInstitutionalPlaceName ?? '',
              onChanged: (v) => bloc.add(OtherNonInstitutionalPlaceNameChanged(v)),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          ] else if (state.nonInstitutionalPlaceType == 'In transit') ...[
            ApiDropdown<String>(
              items: [
                l10n.select,
                'Transit Ambulance',
                'Other',
              ],
              getLabel: (s) => s,
              value: (state.transitPlace == null ||
                  state.transitPlace!.isEmpty ||
                  ![l10n.select, 'Transit Ambulance', 'Other']
                      .contains(state.transitPlace))
                  ? l10n.select
                  : state.transitPlace!,
              onChanged: (v) => bloc.add(TransitPlaceChanged(v ?? '')),
              labelText: 'Transit place',
            ),
            const SizedBox(height: 8),
            if (state.transitPlace == 'Other') ...[
              CustomTextField(
                labelText: 'Enter other transit place',
                hintText: 'Enter place',
                initialValue: state.otherTransitPlaceName ?? '',
                onChanged: (v) => bloc.add(OtherTransitPlaceNameChanged(v)),
              ),
              const SizedBox(height: 8),
            ],
          ],
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [
            l10n.select,
            l10n.normalDelivery,
            l10n.cesareanDelivery,
            l10n.assistedDelivery,
          ],
          getLabel: (s) => s,
          value:
              state.deliveryType.isEmpty ||
                  ![
                    l10n.select,
                    l10n.normalDelivery,
                    l10n.cesareanDelivery,
                    l10n.assistedDelivery,
                  ].contains(state.deliveryType)
              ? l10n.select
              : state.deliveryType,
          onChanged: (v) => bloc.add(DeliveryTypeChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.deliveryType,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [l10n.select, l10n.yes, l10n.no],
          getLabel: (s) => s,
          value:
              state.complications.isEmpty ||
                  ![
                    l10n.select,
                    l10n.yes,
                    l10n.no,
                  ].contains(state.complications)
              ? l10n.select
              : state.complications,
          onChanged: (v) => bloc.add(ComplicationsChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.complications,
        ),
        if (state.complications == l10n.yes) ...[
          const SizedBox(height: 8),
          ApiDropdown<String>(
            items: [
              l10n.select,
              'Convulsion',
              'Ante Partumhhaenorhage',
              'Pregnancy Induced Hypertension',
              'Repeated Abortion',
              'Mother death',
              'Congenital Anomaly',
              'Blood Transfusion',
              'Obstructed Labour',
              'PPH',
              'Any other',
            ],
            getLabel: (s) => s,
            value: (state.complicationType == null ||
                state.complicationType!.isEmpty ||
                ![l10n.select, 'Convulsion', 'Ante Partumhhaenorhage', 'Pregnancy Induced Hypertension', 'Repeated Abortion', 'Mother death', 'Congenital Anomaly', 'Blood Transfusion', 'Obstructed Labour', 'PPH', 'Any other']
                    .contains(state.complicationType))
                ? l10n.select
                : state.complicationType!,
            onChanged: (v) => bloc.add(ComplicationTypeChanged(v ?? '')),
            labelText: 'Complication',
          ),
          const SizedBox(height: 8),
          if (state.complicationType == 'Any other') ...[
            CustomTextField(
              labelText: 'Enter other complication during delivery',
              hintText: 'Enter complication',
              initialValue: state.otherComplicationName ?? '',
              onChanged: (v) => bloc.add(OtherComplicationNameChanged(v)),
            ),
            const SizedBox(height: 8),
          ],
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        ],
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.black, // Default text color
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: l10n.outcomeCount.endsWith('*')
                            ? l10n.outcomeCount.substring(0, l10n.outcomeCount.length - 1)
                            : l10n.outcomeCount,
                      ),
                      if (l10n.outcomeCount.endsWith('*'))
                        TextSpan(
                          text: '*',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bloc.add(OutcomeCountChanged(v)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1.5),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  controller: TextEditingController(text: state.outcomeCount),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [l10n.select, l10n.yes, l10n.no],
          getLabel: (s) => s,
          value: state.familyPlanningCounseling.isEmpty
              ? l10n.select
              : state.familyPlanningCounseling,
          onChanged: (v) => bloc.add(FamilyPlanningCounselingChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.familyPlanningCounseling,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        if (state.familyPlanningCounseling == 'Yes') ...[
          const SizedBox(height: 8),
          ApiDropdown<String>(
            labelText: 'Family Planning Method',
            items: const [
              'Select',
              'Condom',
              'Mala -N (Daily Contraceptive pill)',
              'Atra injection',
              'Copper -T (IUCD)',
              'Chhaya (Weekly Contraceptive pill)',
              'ECP (Emergency Contraceptive pill)',
              'Male Sterilization',
              'Female Sterilization',
              'Any Other Specify'
            ],
            getLabel: (value) => value,
            value: state.fpMethod ?? 'Select',
            onChanged: (value) {
              if (value != null) {
                context.read<OutcomeFormBloc>().add(FpMethodChanged(value));
              }
            },
          ),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Copper -T (IUCD)') ...[
          CustomDatePicker(
            labelText: 'Date of removal',
            initialDate: state.removalDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              if (date != null) {
                context.read<OutcomeFormBloc>().add(RemovalDateChanged(date));
              }
            },
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
          CustomTextField(
            labelText: 'Reason for Removal',
            hintText: 'Enter reason for removal',
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(RemovalReasonChanged(value));
            },
            controller: TextEditingController(text: state.removalReason ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Condom') ...[
          CustomTextField(
            labelText: 'Quantity of Condoms',
            hintText: 'Enter quantity',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(CondomQuantityChanged(value));
            },
            controller: TextEditingController(text: state.condomQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Mala -N (Daily Contraceptive pill)') ...[
          CustomTextField(
            labelText: 'Quantity of Mala -N (Daily Contraceptive pill)',
            hintText: 'Enter quantity',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(MalaQuantityChanged(value));
            },
            controller: TextEditingController(text: state.malaQuantity ?? ''),

          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'Chhaya (Weekly Contraceptive pill)') ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'Chhaya (Weekly Contraceptive pill)',
              hintText: 'Enter quantity',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(ChhayaQuantityChanged(value));
            },
            controller: TextEditingController(text: state.chhayaQuantity ?? ''),
          ),
          const SizedBox(height: 8),
        ],

        if (state.fpMethod == 'ECP (Emergency Contraceptive pill)') ...[
          CustomTextField(
            labelText: 'ECP (Emergency Contraceptive pill)',
            hintText: 'Enter quantity',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<OutcomeFormBloc>().add(ECPQuantityChanged(value));
            },
            controller: TextEditingController(text: state.ecpQuantity ?? ''),
          ),
          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
          const SizedBox(height: 8),
        ],

        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: SizedBox(
            height: 34,
            width: 140,
            child: RoundButton(
              title: l10n.saveButton,
              borderRadius: 4,
              isLoading: state.submitting,
              color: AppColors.primary,
              onPress: () {
                final bloc = context.read<OutcomeFormBloc>();
                final beneficiaryData =
                    (context
                                .findAncestorWidgetOfExactType<
                                  BlocProvider<OutcomeFormBloc>
                                >()
                                ?.child
                            as _OutcomeFormView)
                        .beneficiaryData;
                bloc.add(
                  OutcomeFormSubmitted(beneficiaryData: beneficiaryData),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.background,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
