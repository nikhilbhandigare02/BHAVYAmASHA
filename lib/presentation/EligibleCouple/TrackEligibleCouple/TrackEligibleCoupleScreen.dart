import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/utils/enums.dart';
import 'bloc/track_eligible_couple_bloc.dart';

class TrackEligibleCoupleScreen extends StatelessWidget {
  const TrackEligibleCoupleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackEligibleCoupleBloc(),
      child: const _TrackEligibleCoupleView(),
    );
  }
}

class _TrackEligibleCoupleView extends StatelessWidget {
  const _TrackEligibleCoupleView();

  String _fmt(DateTime? d) {
    if (d == null) return 'dd-mm-yyyy';
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(screenTitle: t?.trackEligibleCoupleTitle ?? 'योग्य दम्पतियों की ट्रैकिंग', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visit Date
              _label(t?.visitDateLabel ?? 'भ्रमण की तिथि'),
              BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
                buildWhen: (p, c) => p.visitDate != c.visitDate,
                builder: (context, state) {
                  return InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.visitDate ?? now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                      );
                      context.read<TrackEligibleCoupleBloc>().add(VisitDateChanged(picked));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(border: UnderlineInputBorder()),
                      child: Text(_fmt(state.visitDate), style: TextStyle(color: state.visitDate == null ? Colors.black45 : Colors.black)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Financial Year
              _label(t?.financialYearLabel ?? 'वित्तीय वर्ष'),
              BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
                buildWhen: (p, c) => p.financialYear != c.financialYear,
                builder: (context, state) {
                  return InputDecorator(
                    decoration: const InputDecoration(border: UnderlineInputBorder()),
                    child: Text(state.financialYear.isEmpty ? 'YYYY' : state.financialYear, style: TextStyle(color: state.financialYear.isEmpty ? Colors.black45 : Colors.black)),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Pregnant?
              _label(t?.isPregnantLabel ?? 'क्या महिला गर्भवती है?'),
              BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
                builder: (context, state) {
                  final value = state.isPregnant == null ? null : (state.isPregnant! ? 'हाँ' : 'नहीं');
                  return DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(hintText: t?.selectArea ?? 'चुनें', border: const UnderlineInputBorder()),
                    items: const [DropdownMenuItem(value: 'हाँ', child: Text('हाँ')), DropdownMenuItem(value: 'नहीं', child: Text('नहीं'))],
                    onChanged: (v) => context.read<TrackEligibleCoupleBloc>().add(IsPregnantChanged(v == 'हाँ')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Conditional sections
              BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
                builder: (context, state) {
                  if (state.isPregnant == true) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('${t?.lmpDateLabel ?? 'एलएमपी की तिथि'} *'),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: state.lmpDate ?? now,
                              firstDate: DateTime(now.year - 5),
                              lastDate: DateTime(now.year + 5),
                            );
                            context.read<TrackEligibleCoupleBloc>().add(LmpDateChanged(picked));
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(border: UnderlineInputBorder()),
                            child: Text(_fmt(state.lmpDate), style: TextStyle(color: state.lmpDate == null ? Colors.black45 : Colors.black)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _label('${t?.eddDateLabel ?? 'प्रसव होने की संभावित तिथि'} *'),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: state.eddDate ?? now,
                              firstDate: DateTime(now.year - 5),
                              lastDate: DateTime(now.year + 5),
                            );
                            context.read<TrackEligibleCoupleBloc>().add(EddDateChanged(picked));
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(border: UnderlineInputBorder()),
                            child: Text(_fmt(state.eddDate), style: TextStyle(color: state.eddDate == null ? Colors.black45 : Colors.black)),
                          ),
                        ),
                      ],
                    );
                  } else if (state.isPregnant == false) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(t?.fpAdoptingLabel ?? 'क्या आप/आपका साथी परिवार नियोजन अपना रहे हैं?'),
                        DropdownButtonFormField<String>(
                          value: state.fpAdopting == null ? null : (state.fpAdopting! ? 'हाँ' : 'नहीं'),
                          decoration: InputDecoration(hintText: t?.selectArea ?? 'चुनें', border: const UnderlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'हाँ', child: Text('हाँ')),
                            DropdownMenuItem(value: 'नहीं', child: Text('नहीं')),
                          ],
                          onChanged: (v) => context.read<TrackEligibleCoupleBloc>().add(FpAdoptingChanged(v == 'हाँ')),
                        ),
                        const SizedBox(height: 12),
                        _label(t?.fpMethodLabel ?? 'गर्भनिरोधक का तरीका'),
                        DropdownButtonFormField<String>(
                          value: state.fpMethod,
                          decoration: InputDecoration(hintText: t?.selectArea ?? 'चुनें', border: const UnderlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'कंडोम', child: Text('कंडोम')),
                            DropdownMenuItem(value: 'माला-एन (साप्ताहिक गर्भनिरोधक गोली)', child: Text('माला-एन (साप्ताहिक गर्भनिरोधक गोली)')),
                            DropdownMenuItem(value: 'गोलियाँ', child: Text('गोलियाँ')),
                            DropdownMenuItem(value: 'आईयूडी', child: Text('आईयूडी')),
                            DropdownMenuItem(value: 'अन्य', child: Text('अन्य')),
                          ],
                          onChanged: (v) => context.read<TrackEligibleCoupleBloc>().add(FpMethodChanged(v ?? '')),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
          builder: (context, state) {
            final enabled = state.isValid && state.status != FormStatus.submitting;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child:  Text('पिछले पेज', style: TextStyle(color: AppColors.background),),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: enabled ? () => context.read<TrackEligibleCoupleBloc>().add(const SubmitTrackForm()) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,

                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: state.status == FormStatus.submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        :  Text('संरक्षित करें', style: TextStyle(color: AppColors.background),),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      );
}

