import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/utils/enums.dart';
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
        appBar: AppHeader(screenTitle: l10n.trainingFormTitle, showBack: true,),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(l10n.trainingTypeLabel),
                BlocBuilder<TrainingBloc, TrainingState>(
                  builder: (context, state) {
                    return DropdownButtonFormField<String>(
                      value: state.trainingType,
                      decoration: InputDecoration(hintText: l10n.select, border: const UnderlineInputBorder()),
                      items: state.trainingTypes
                          .map((e) => DropdownMenuItem<String>(value: e == 'Select' ? null : e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingTypeChanged(v ?? '')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _label(l10n.trainingNameLabel),
                BlocBuilder<TrainingBloc, TrainingState>(
                  builder: (context, state) {
                    return DropdownButtonFormField<String>(
                      value: state.trainingName,
                      decoration: InputDecoration(hintText: l10n.select, border: const UnderlineInputBorder()),
                      items: state.trainingNames
                          .map((e) => DropdownMenuItem<String>(value: e == 'Select' ? null : e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingNameChanged(v ?? '')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _label(l10n.trainingDateLabel),
                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.date != c.date,
                  builder: (context, state) {
                    final text = state.date == null
                        ? l10n.dateHint
                        : '${state.date!.day.toString().padLeft(2, '0')}-${state.date!.month.toString().padLeft(2, '0')}-${state.date!.year}';
                    return InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.date ?? now,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 5),
                        );
                        context.read<TrainingBloc>().add(TrainingDateChanged(picked));
                      },
                      child:  InputDecorator(
                        decoration: InputDecoration(border: UnderlineInputBorder()),
                        child: Text(text, style: TextStyle(color: state.date == null ? Colors.black45 : Colors.black)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _label(l10n.trainingPlaceLabel),
                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.place != c.place,
                  builder: (context, state) {
                    _placeCtrl.value = TextEditingValue(text: state.place ?? '', selection: TextSelection.collapsed(offset: (state.place ?? '').length));
                    return TextFormField(
                      controller: _placeCtrl,
                      decoration: InputDecoration(hintText: l10n.trainingPlaceLabel, border: const UnderlineInputBorder()),
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingPlaceChanged(v)),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _label(l10n.trainingDaysLabel),
                BlocBuilder<TrainingBloc, TrainingState>(
                  buildWhen: (p, c) => p.days != c.days,
                  builder: (context, state) {
                    _daysCtrl.value = TextEditingValue(text: state.days ?? '', selection: TextSelection.collapsed(offset: (state.days ?? '').length));
                    return TextFormField(
                      controller: _daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: l10n.trainingDaysLabel, border: const UnderlineInputBorder()),
                      onChanged: (v) => context.read<TrainingBloc>().add(TrainingDaysChanged(v)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: BlocBuilder<TrainingBloc, TrainingState>(
            builder: (context, state) {
              final enabled = state.isValid && state.status != FormStatus.submitting;
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3787CF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: enabled ? () => context.read<TrainingBloc>().add(const SubmitTraining()) : null,
                  child: state.status == FormStatus.submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.trainingSave),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }
}
