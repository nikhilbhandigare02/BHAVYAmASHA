import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
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
    return Scaffold(
      appBar: AppHeader(screenTitle: 'प्रसव का परिणाम', showBack: true,),
      body: BlocListener<OutcomeFormBloc, OutcomeFormState>(
        // Always listen to state changes
        listenWhen: (previous, current) => true,
        listener: (context, state) {
          // Clear any existing snackbars to prevent stacking
          ScaffoldMessenger.of(context).clearSnackBars();
          
          // Show error message if exists
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
          
          // Show success message when form is successfully submitted
          if (state.submitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('डेटा सुरक्षित हो गया'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<OutcomeFormBloc, OutcomeFormState>(
          builder: (context, state) {
            final bloc = context.read<OutcomeFormBloc>();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(title: 'प्रसव परिणाम विवरण'),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDatePicker(
                        initialDate: state.deliveryDate,
                        isEditable: true,
                        labelText: 'प्रसव की तिथि *',
                        onDateChanged: (d) => bloc.add(DeliveryDateChanged(d)),
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'प्रसव के दौरान गर्भावस्था के सप्ताहों की संख्या।',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50, // box width
                              child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (v) => bloc.add(GestationWeeksChanged(v)),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero, // 👈 square corners
                                  ),
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

                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      CustomTextField(
                        labelText: 'प्रसव का समय (hh:mm)',
                        hintText: 'hh:mm',
                        initialValue: state.deliveryTime ?? '',
                        keyboardType: TextInputType.datetime,
                        onChanged: (v) => bloc.add(DeliveryTimeChanged(v)),
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Place of Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                      ),
                      ApiDropdown<String>(
                        items: const [
                          'चुनें',
                          'घर',
                          'उप-केन्द्र',
                          'पीएचसी',
                          'सीएचसी',
                          'जिला अस्पताल',
                          'निजी अस्पताल',
                        ],
                        getLabel: (s) => s,
                        value: state.placeOfDelivery.isEmpty
                            ? 'चुनें'
                            : state.placeOfDelivery,
                        onChanged: (v) =>
                            bloc.add(PlaceOfDeliveryChanged(v ?? '')),
                        hintText: 'चुनें',
                        labelText: 'डिलिवरी का स्थान *',
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      ApiDropdown<String>(
                        items: const [
                          'चुनें',
                          'सामान्य',
                          'सीज़ेरियन',
                          'वैक्यूम/फोर्सेप्स',
                        ],
                        getLabel: (s) => s,
                        value: state.deliveryType.isEmpty
                            ? 'चुनें'
                            : state.deliveryType,
                        onChanged: (v) =>
                            bloc.add(DeliveryTypeChanged(v ?? '')),
                        hintText: 'चुनें',
                        labelText: 'प्रसव का प्रकार',
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      ApiDropdown<String>(
                        items: const ['चुनें', 'हाँ', 'नहीं'],
                        getLabel: (s) => s,
                        value: state.complications.isEmpty
                            ? 'चुनें'
                            : state.complications,
                        onChanged: (v) =>
                            bloc.add(ComplicationsChanged(v ?? '')),
                        hintText: 'चुनें',
                        labelText: 'प्रसव के दौरान जटिलता? *',
                      ),
                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),
                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'प्रसव का परिणाम *',
                                style: const TextStyle(
                                  fontSize: 16,
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero, // 👈 square corners
                                  ),
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

                      Divider(
                        color: AppColors.divider,
                        thickness: 0.5,
                        height: 0,
                      ),

                      ApiDropdown<String>(
                        items: const ['चुनें', 'हाँ', 'नहीं'],
                        getLabel: (s) => s,
                        value: state.familyPlanningCounseling.isEmpty
                            ? 'चुनें'
                            : state.familyPlanningCounseling,
                        onChanged: (v) =>
                            bloc.add(FamilyPlanningCounselingChanged(v ?? '')),
                        hintText: 'चुनें',
                        labelText: 'परिवार नियोजन की परामर्श दी गई?',
                      ),
                    ],
                  ),

                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: SizedBox(
                      height: 44,
                      width: 140,
                      child: RoundButton(
                        title:'SAVE',
                        borderRadius: 8,
                        isLoading: state.submitting,
                        color: AppColors.primary,
                        onPress: () => context.read<OutcomeFormBloc>().add(
                          const OutcomeFormSubmitted(),
                      ),
                    ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ),
    Divider(color: AppColors.primary, thickness: 1, height: 0),

      ],
    );
  }
}


