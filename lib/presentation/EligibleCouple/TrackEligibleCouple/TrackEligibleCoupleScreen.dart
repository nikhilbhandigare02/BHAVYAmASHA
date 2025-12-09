import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../core/utils/enums.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import 'PreviousVisits.dart';
import 'bloc/track_eligible_couple_bloc.dart';

class TrackEligibleCoupleScreen extends StatelessWidget {
  final String beneficiaryId;
  final bool isProtected;
  final String? beneficiaryRefKey;

  const TrackEligibleCoupleScreen({
    super.key,
    required this.beneficiaryId,
    this.isProtected = false,
    this.beneficiaryRefKey,
  });

  static Route route({
    required String beneficiaryId,
    bool isProtected = false,
    String? beneficiaryRefKey,
  }) =>
      MaterialPageRoute(
        builder: (context) => TrackEligibleCoupleScreen(
          beneficiaryId: beneficiaryId,
          isProtected: isProtected,
          beneficiaryRefKey: beneficiaryRefKey,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) => TrackEligibleCoupleBloc(
        beneficiaryId: beneficiaryId,
        beneficiaryRefKey: beneficiaryRefKey,
        isProtected: isProtected,
      ),
      child: BlocListener<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            if (state.isPregnant == true) {
              showConfirmationDialog(
                context: context,
                title:l10n?.formSavedSuccessfully ?? 'Form has been saved successfully',
                message:
               l10n?.pregnantAddedToAnc ?? 'Pregnant beneficiary has been added to antenatal care (ANC) list.',
                yesText:l10n?.okay ??  'Okay',
                onYes: () => Navigator.pop(context),
                titleBackgroundColor: AppColors.background,
                titleTextColor: AppColors.primary,
                messageTextColor: Colors.black87,
                yesButtonColor: AppColors.primary,
                dialogBackgroundColor: Colors.white,
              );
            } else {
              showAppSnackBar(context,l10n?.formSavedSuccess ??  'Form saved successfully');
              Navigator.of(context).pop(true);
            }
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


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: t?.eligibleCoupleTrackingDue ?? 'Eligible Couple Tracking Due',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  context
                      .read<TrackEligibleCoupleBloc>()
                      .add(VisitDateChanged(date));
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
                    text: state.financialYear.isEmpty
                        ? 'YYYY'
                        : state.financialYear,
                  ),
                );
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 8),

            // Is Pregnant
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

            // Conditional Sections for Pregnant
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                if (state.isPregnant == true) {
                  final lmp = state.lmpDate;
                  final edd = state.eddDate;

                  String formatDate(DateTime? d) {
                    if (d == null) return '';
                    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString()}';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomDatePicker(
                        labelText: '${t?.lmpDateLabelText ?? 'एलएमपी की तिथि'} *',
                        hintText: t?.dateHint,
                        initialDate: lmp,
                        onDateChanged: (date) {
                          if (date != null) {
                            final edd = date.add(const Duration(days: 277));
                            context.read<TrackEligibleCoupleBloc>()
                              ..add(LmpDateChanged(date))
                              ..add(EddDateChanged(edd));
                          } else {
                            context.read<TrackEligibleCoupleBloc>()
                              ..add(const LmpDateChanged(null))
                              ..add(const EddDateChanged(null));
                          }
                        },
                        isEditable: true,
                        firstDate: DateTime.now().subtract(const Duration(days: 280)), // ~9 months ago
                        lastDate: DateTime.now().add(const Duration(days: 30)), // 1 month from now
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText:
                        '${t?.eddDateLabel ?? 'प्रसव की संभावित तिथि'} *',
                        hintText:'dd-mm-yyyy',
                        readOnly: true,
                        controller: TextEditingController(
                          text: formatDate(edd),
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Family Planning section (hidden when pregnant)
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                if (state.isPregnant == true) {
                  return const SizedBox.shrink();
                }
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
                      hintText: t?.select ?? 'Select',
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(FpAdoptingChanged(value));
                        }
                      },
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Dependent questions for family planning
                    if (state.fpAdopting == true) ...[
                      ApiDropdown<String>(
                        labelText: t?.methodOfContraception ?? 'Method of contraception',
                        items: const [
                          'Condom',
                          'Mala -N (Daily contraceptive pill)',
                          'Atra Injection',
                          'Copper -T (IUCD)',
                          'Chhaya (Weekly contraceptive pill)',
                          'ECP (Emergency contraceptive pill)',
                          'Male Sterilization',
                          'Female Sterilization',
                          'Any Other Specify'
                        ],
                        getLabel: (value) {
                          switch (value) {
                            case 'Condom':
                              return t!.condom;
                            case 'Mala -N (Daily contraceptive pill)':
                              return t!.malaN;
                            case 'Atra Injection':
                              return t!.atraInjection;
                            case 'Copper -T (IUCD)':
                              return t!.copperT;
                            case 'Chhaya (Weekly contraceptive pill)':
                              return t!.chhaya;
                            case 'ECP (Emergency contraceptive pill)':
                              return t!.ecp;
                            case 'Male Sterilization':
                              return t!.maleSterilization;
                            case 'Female Sterilization':
                              return t!.femaleSterilization;
                            case 'Any Other Specify':
                              return t!.anyOtherSpecifyy;
                            default:
                              return value;
                          }
                        },
                        value: state.fpMethod,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<TrackEligibleCoupleBloc>().add(FpMethodChanged(value));
                          }
                        },
                      ),

                      /*ApiDropdown<String>(
                        labelText: 'Method of contraception' ?? 'गर्भनिरोधक का तरीका',
                        items: const [
                          'Condom',
                          'Mala -N (Daily contraceptive pill)',
                          'Atra Injection',
                          'Copper -T (IUCD)',
                          'Chhaya (Weekly contraceptive pill)',
                          'ECP (Emergency contraceptive pill)',
                          'Male Sterilization',
                          'Female Sterilization',
                          'Any Other Specify'
                        ],
                        getLabel: (value) => value,
                        value: state.fpMethod,
                        onChanged: (value) {
                          if (value != null) {
                            context
                                .read<TrackEligibleCoupleBloc>()
                                .add(FpMethodChanged(value));
                          }
                        },
                      ),*/
                      const Divider(thickness: 1, color: Colors.grey),
                    ],

                    if (state.fpMethod == 'Atra Injection' && state.fpAdopting == true) ...[
                      CustomDatePicker(
                        labelText: t?.dateOfAntraInjection ?? 'Date of Antra Injection',
                        hintText: 'dd-mm-yyyy',
                        initialDate: state.antraInjectionDateChanged,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context
                                .read<TrackEligibleCoupleBloc>()
                                .add(FpAntraInjectionDateChanged(date));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],


                    if (state.fpMethod == 'Copper -T (IUCD)' && state.fpAdopting == true) ...[
                      CustomDatePicker(
                        labelText:t?.dateOfRemoval ?? 'Date of removal',
                        initialDate: state.removalDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context
                                .read<TrackEligibleCoupleBloc>()
                                .add(RemovalDAteChange(date));
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      CustomTextField(
                        labelText: t?.reasonForRemoval ?? 'Reason for Removal',
                        hintText:t?.enterReasonForRemoval ??  'Enter reason for removal',
                        initialValue: state.removalReasonChanged,
                        onChanged: (value) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(RemovalReasonChanged(value));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],

                    if (state.fpMethod == 'Condom' && state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:t?.quantityOfCondoms ?? 'Quantity of Condoms',
                        hintText: t?.quantityOfCondoms ?? 'Quantity of condoms',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(CondomQuantity(value));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod == 'Chhaya (Weekly contraceptive pill)' && state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:t?.quantityOfChhaya ??  'Quantity of Chhaya (Weekly contraceptive pill)',
                        hintText:t?.quantityOfChhaya ?? 'Quantity of Chhaya (Weekly contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.chhaya,
                        onChanged: (value) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(ChayaQuantity(value));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod == 'ECP (Emergency contraceptive pill)' && state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText: t?.quantityOfECP ?? 'Quantity of ECP (Emergency contraceptive pill)',
                        hintText: t?.quantityOfECP ?? 'Quantity of ECP (Emergency contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.ecp,
                        onChanged: (value) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(ECPQuantity(value));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod == 'Mala -N (Daily contraceptive pill)' && state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText: t?.quantityOfMalaN ?? 'Quantity of Mala -N (Daily contraceptive pill)',
                        hintText: t?.quantityOfMalaN ??'Quantity of Mala -N (Daily contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.mala,
                        onChanged: (value) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(MalaQuantity(value));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],


                  ],
                );
              },
            ),

            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                final t = AppLocalizations.of(context);
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    ApiDropdown<bool>(
                      labelText: t?.isBeneficiaryAbsent ?? 'Is Beneficiary Absent',
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

                    if (state.beneficiaryAbsentCHanged == true) ...[
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: t?.reasonForAbsent ?? 'Reason for absent',
                        hintText: t?.enterReason ?? 'Enter reason',
                        onChanged: (val) {
                          context
                              .read<TrackEligibleCoupleBloc>()
                              .add(BeneficiaryAbsentReasonChanged(val));
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],

                  ],
                );
              },
            ),
          ],
        ),
      ),

      // Bottom Buttons
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              spreadRadius: 2,
              offset: const Offset(0, 0), // TOP shadow
            ),
          ],
        ),
        child: SafeArea(
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
                            builder: (context) =>
                                PreviousVisitsScreen(beneficiaryId: beneficiaryId),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize:  Size.fromHeight(4.5.h),
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
                  const SizedBox(width: 50),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize:  Size.fromHeight(4.5.h),
                      ),
                      child: state.status == FormStatus.submitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        t?.saveButton ?? 'संरक्षित करें',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 15.sp,
                        ),
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
