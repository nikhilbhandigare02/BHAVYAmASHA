import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart' hide ApiDropdown;
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/utils/enums.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/Dropdown/Dropdown.dart';
import 'bloc/training_bloc.dart';

class Trainingform extends StatelessWidget {
  const Trainingform({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrainingBloc(),
      child: const _TrainingFormView(),
    );
  }
}

class _TrainingFormView extends StatefulWidget {
  const _TrainingFormView();
  @override
  State<_TrainingFormView> createState() => _TrainingFormViewState();
}

class _TrainingFormViewState extends State<_TrainingFormView> {
  final TextEditingController _placeCtrl = TextEditingController();
  final TextEditingController _daysCtrl = TextEditingController();

  @override
  void dispose() {
    _placeCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<TrainingBloc, TrainingState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == FormStatus.success) {

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.trainingSave)));
        } else if (state.status == FormStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppHeader(screenTitle: l10n.trainingFormTitle, showBack: true),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Training Type Dropdown
                BlocBuilder<TrainingBloc, TrainingState>(
                  builder: (context, state) {
                    return ApiDropdown<String>(
                      labelText: l10n.trainingTypeLabel,
                      items: state.trainingTypes.where((e) => e != 'Select').toList(),
                      getLabel: (item) => item,
                      value: state.trainingType,
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingTypeChanged(v ?? '')),
                      hintText: l10n.select,
                    );
                  },
                ),
                Divider(color: AppColors.divider, thickness: 0.5),

                BlocBuilder<TrainingBloc, TrainingState>(
                  builder: (context, state) {
                    return ApiDropdown<String>(
                      labelText: l10n.trainingNameLabel,
                      items: state.trainingNames.where((e) => e != 'Select').toList(),
                      getLabel: (item) => item,
                      value: state.trainingName,
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingNameChanged(v ?? '')),
                      hintText: l10n.select,
                    );
                  },
                ),
                Divider(color: AppColors.divider, thickness: 0.5),

                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.date != c.date,
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            l10n.trainingDateLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: state.date ?? now,
                              firstDate: DateTime(now.year - 5),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (picked != null) {
                              context.read<TrainingBloc>().add(TrainingDateChanged(picked));
                            }
                          },
                          child: AbsorbPointer(
                            child: CustomTextField(
                              labelText: '',
                              hintText: state.date == null
                                  ? l10n.dateHint
                                  : '${state.date!.day.toString().padLeft(2, '0')}-${state.date!.month.toString().padLeft(2, '0')}-${state.date!.year}',
                              readOnly: true,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Divider(color: AppColors.divider, thickness: 0.5),

                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.place != c.place,
                  builder: (context, state) {
                    _placeCtrl.value = TextEditingValue(
                      text: state.place ?? '',
                      selection: TextSelection.collapsed(offset: (state.place ?? '').length),
                    );
                    return CustomTextField(
                      labelText: l10n.trainingPlaceLabel,
                      hintText: l10n.trainingPlaceLabel,
                      initialValue: state.place ?? '',
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingPlaceChanged(v)),
                    );
                  },
                ),
                Divider(color: AppColors.divider, thickness: 0.5),

                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.days != c.days,
                  builder: (context, state) {
                    _daysCtrl.value = TextEditingValue(
                      text: state.days ?? '',
                      selection: TextSelection.collapsed(offset: (state.days ?? '').length),
                    );
                    return CustomTextField(
                      labelText: l10n.trainingDaysLabel,
                      hintText: l10n.trainingDaysLabel,
                      initialValue: state.days ?? '',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingDaysChanged(v)),
                    );
                  },
                ),
                Divider(color: AppColors.divider, thickness: 0.5),

              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BlocBuilder<TrainingBloc, TrainingState>(
            builder: (context, state) {
              final isLoading = state.status == FormStatus.submitting;
              return RoundButton(
                title: l10n.trainingSave,
                onPress: () => context.read<TrainingBloc>().add(const SubmitTraining()),
                isLoading: isLoading,
                disabled: !state.isValid || isLoading,
                width: double.infinity,
                height: 48,
              );
            },
          ),
        ),
      ),
    );
  }

}
