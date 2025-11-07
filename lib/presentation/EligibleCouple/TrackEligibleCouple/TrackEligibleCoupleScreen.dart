import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../core/utils/enums.dart';
import 'PreviousVisits.dart';
import 'bloc/track_eligible_couple_bloc.dart';

class TrackEligibleCoupleScreen extends StatelessWidget {
  final String beneficiaryId;
  final bool isProtected;

  const TrackEligibleCoupleScreen({
    super.key, 
    required this.beneficiaryId,
    this.isProtected = false,
  });

  static Route route({required String beneficiaryId, bool isProtected = false}) => MaterialPageRoute(
    builder: (context) => TrackEligibleCoupleScreen(
      beneficiaryId: beneficiaryId,
      isProtected: isProtected,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackEligibleCoupleBloc(
        beneficiaryId: beneficiaryId,
        isProtected: isProtected,
      ),
      child: BlocListener<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            Navigator.of(context).pop(true);
          }
        },
        child: _TrackEligibleCoupleView(beneficiaryId: beneficiaryId),
      ),
    );
  }
}

class _TrackEligibleCoupleView extends StatelessWidget {
  final String beneficiaryId;
  
  const _TrackEligibleCoupleView({required this.beneficiaryId});

  // Date formatter is now handled by CustomDatePicker

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
          screenTitle:
          t?.trackEligibleCoupleTitle ?? 'योग्य दम्पतियों की ट्रैकिंग',
          showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:  Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visit Date
            CustomDatePicker(
              labelText: t?.visitDateLabel ?? 'भ्रमण की तिथि',
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                if (date != null) {
                  context.read<TrackEligibleCoupleBloc>().add(VisitDateChanged(date));
                }
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 8),

            // Financial Year
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              buildWhen: (previous, current) =>
              previous.financialYear != current.financialYear,
              builder: (context, state) {
                return CustomTextField(
                  labelText: t?.financialYearLabel ?? 'वित्तीय वर्ष',
                  readOnly: true,
                  controller: TextEditingController(
                    text: state.financialYear.isEmpty ? 'YYYY' : state.financialYear,
                  ),
                );
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 8),

            // Pregnant?
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                return ApiDropdown<bool>(
                  labelText: t?.isPregnantLabel ?? 'क्या महिला गर्भवती है?',
                  items: [true, false],
                  getLabel: (value) =>
                  value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                  value: state.isPregnant,
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<TrackEligibleCoupleBloc>()
                          .add(IsPregnantChanged(value));
                    }
                  },
                );
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 8),

            // Conditional sections
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                if (state.isPregnant == true) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomDatePicker(
                        labelText: '${t?.lmpDateLabel ?? 'एलएमपी की तिथि'} *',
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context.read<TrackEligibleCoupleBloc>().add(LmpDateChanged(date));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 8),

                      CustomDatePicker(
                        labelText: '${t?.eddDateLabel ?? 'प्रसव की संभावित तिथि'} *',
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context.read<TrackEligibleCoupleBloc>().add(EddDateChanged(date));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                  );
                } else if (state.isPregnant == false) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ApiDropdown<bool>(
                        labelText: t?.fpAdoptingLabel ??
                            'क्या आप/आपका साथी परिवार नियोजन अपना रहे हैं?',
                        items: [true, false],
                        getLabel: (value) =>
                        value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                        value: state.fpAdopting,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<TrackEligibleCoupleBloc>().add(FpAdoptingChanged(value));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 8),

                      if (state.fpAdopting == true) ...[
                        ApiDropdown<String>(
                          labelText: t?.fpMethodLabel ?? 'गर्भनिरोधक का तरीका',
                          items: const [
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
                          value: state.fpMethod,
                          onChanged: (value) {
                            if (value != null) {
                              context.read<TrackEligibleCoupleBloc>().add(FpMethodChanged(value));
                            }
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),

                      ],

                      if(state.fpMethod == 'Copper -T (IUCD)')...[
                        CustomDatePicker(
                          labelText:  'Date of removal',
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                          onDateChanged: (date) {
                            if (date != null) {
                              context.read<TrackEligibleCoupleBloc>().add(RemovalDAteChange(date));
                            }
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),

                        CustomTextField(
                          labelText: 'Reason for Removal',
                          hintText: 'Enter reason for removal',
                          onChanged: (value) {
                            context.read<TrackEligibleCoupleBloc>().add(RemovalReasonChanged(value));
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],
                      // Quantities based on FP method
                      if (state.fpMethod == 'Condom') ...[
                        CustomTextField(
                          labelText: 'Quantity of Condoms',
                          hintText: 'Enter quantity',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<TrackEligibleCoupleBloc>().add(CondomQuantity(value));
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],
                      if (state.fpMethod == 'Mala -N (Daily Contraceptive pill)') ...[
                        CustomTextField(
                          labelText: 'Quantity of Mala -N (Daily Contraceptive pill)',
                          hintText: 'Enter quantity',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<TrackEligibleCoupleBloc>().add(MalaQuantity(value));
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],
                      if (state.fpMethod == 'Chhaya (Weekly Contraceptive pill)') ...[
                        CustomTextField(
                          labelText: 'Chhaya (Weekly Contraceptive pill)',
                          hintText: 'Enter quantity',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<TrackEligibleCoupleBloc>().add(ChayaQuantity(value));
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],
                      if (state.fpMethod == 'ECP (Emergency Contraceptive pill)') ...[
                        CustomTextField(
                          labelText: 'ECP (Emergency Contraceptive pill)',
                          hintText: 'Enter quantity',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            context.read<TrackEligibleCoupleBloc>().add(ECPQuantity(value));
                          },
                        ),
                        const Divider(thickness: 1, color: Colors.grey),
                      ],

                      ApiDropdown<bool>(
                        labelText: 'Is Beneficiary Absent',
                        items: [true, false],
                        getLabel: (value) =>
                        value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                        value: state.beneficiaryAbsentCHanged,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<TrackEligibleCoupleBloc>()
                                .add(BeneficiaryAbsentCHanged(value));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 12),
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
            final enabled =
                state.isValid && state.status != FormStatus.submitting;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreviousVisitsScreen(beneficiaryId: beneficiaryId),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      t?.previousButton ?? 'पिछला पेज',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: enabled
                        ? () {
                      context
                          .read<TrackEligibleCoupleBloc>()
                          .add(const SubmitTrackForm());
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: state.status == FormStatus.submitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Text(t?.saveButton ?? 'संरक्षित करें',
                        style: TextStyle(
                            color: AppColors.background, fontSize: 15.sp)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
