import 'package:flutter/material.dart';
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

class OutcomeFormPage extends StatelessWidget {
  const OutcomeFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OutcomeFormBloc(),
      child: const _OutcomeFormView(),
    );
  }
}

class _OutcomeFormView extends StatelessWidget {
  const _OutcomeFormView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n.deliveryOutcomeTitle,
        showBack: true,
      ),
      body: BlocListener<OutcomeFormBloc, OutcomeFormState>(
        listenWhen: (previous, current) => true,
        listener: (context, state) {
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
          }
        },
        child: Column(
          children: [
            _SectionHeader(title: l10n.deliveryOutcomeDetails),

            // 🔹 Form Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: const _OutcomeFormFields(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeFormFields extends StatelessWidget {
  const _OutcomeFormFields();

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
                  style:  TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,

                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (v) => bloc.add(GestationWeeksChanged(v)),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            l10n.placeOfDelivery,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ApiDropdown<String>(
          items: [
            l10n.select,
            l10n.home,
            l10n.subCenter,
            l10n.phc,
            l10n.chc,
            l10n.districtHospital,
            l10n.privateHospital,
          ],
          getLabel: (s) => s,
          value: state.placeOfDelivery.isEmpty ||
              ![l10n.select, l10n.home, l10n.subCenter, l10n.phc, l10n.chc, l10n.districtHospital, l10n.privateHospital]
                  .contains(state.placeOfDelivery)
              ? l10n.select
              : state.placeOfDelivery,
          onChanged: (v) => bloc.add(PlaceOfDeliveryChanged(v ?? '')),
          labelText: l10n.selectPlaceOfDelivery,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items: [
            l10n.select,
            l10n.normalDelivery,
            l10n.cesareanDelivery,
            l10n.assistedDelivery,
          ],
          getLabel: (s) => s,
          value: state.deliveryType.isEmpty ||
              ![l10n.select, l10n.normalDelivery, l10n.cesareanDelivery, l10n.assistedDelivery]
                  .contains(state.deliveryType)
              ? l10n.select
              : state.deliveryType,
          onChanged: (v) => bloc.add(DeliveryTypeChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.deliveryType,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items:  [l10n.select, l10n.yes, l10n.no],
          getLabel: (s) => s,
          value: state.complications.isEmpty ||
              ![l10n.select, l10n.yes, l10n.no].contains(state.complications)
              ? l10n.select
              : state.complications,
          onChanged: (v) => bloc.add(ComplicationsChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.complications,
        ),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l10n.outcomeCount}',
                  style:  TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: AppColors.divider, thickness: 0.5, height: 0),

        ApiDropdown<String>(
          items:  [l10n.select, l10n.yes, l10n.no],
          getLabel: (s) => s,
          value: state.familyPlanningCounseling.isEmpty
              ? l10n.select
              : state.familyPlanningCounseling,
          onChanged: (v) => bloc.add(FamilyPlanningCounselingChanged(v ?? '')),
          hintText: l10n.selectOption,
          labelText: l10n.familyPlanningCounseling,
        ),

        Divider(color: AppColors.divider, thickness: 0.5, height: 0),
        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: SizedBox(
            height: 44,
            width: 140,
            child: RoundButton(
              title: l10n.saveButton,
              borderRadius: 8,
              isLoading: state.submitting,
              color: AppColors.primary,
              onPress: () => context.read<OutcomeFormBloc>().add(
                const OutcomeFormSubmitted(),
              ),
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
        style:  TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.background,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
