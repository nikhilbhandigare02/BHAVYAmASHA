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
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
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
  }) => MaterialPageRoute(
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
                title:
                    l10n?.formSavedSuccessfully ??
                    'Form has been saved successfully',
                message:
                    l10n?.pregnantAddedToAnc ??
                    'Pregnant beneficiary has been added to antenatal care (ANC) list.',
                yesText: l10n?.okay ?? 'Okay',
                onYes: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                titleBackgroundColor: AppColors.background,
                titleTextColor: AppColors.primary,
                messageTextColor: Colors.black87,
                yesButtonColor: AppColors.primary,
                dialogBackgroundColor: Colors.white,
              );
            } else {
              showAppSnackBar(
                context,
                l10n?.formSavedSuccess ?? 'Form saved successfully',
              );
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

  Future<bool> _hasActiveMotherCare(String beneficiaryKey) async {
    if (beneficiaryKey.isEmpty) return false;
    final rec = await LocalStorageDao.instance
        .getMotherCareActivityByBeneficiary(beneficiaryKey);
    return rec != null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle:
            t?.eligibleCoupleTrackingDue ?? 'Eligible Couple Tracking Due',
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
                  context.read<TrackEligibleCoupleBloc>().add(
                    VisitDateChanged(date),
                  );
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
                DateTime? parseFinancialYear(String? yearStr) {
                  if (yearStr == null || yearStr.isEmpty) return null;
                  try {
                    final year = yearStr.split('-').first;
                    return DateTime(int.parse(year));
                  } catch (e) {
                    return null;
                  }
                }

                String formatFinancialYear(DateTime date) {
                  final year = date.year;
                  return '$year-${(year + 1).toString().substring(2)}';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t?.financialYearLabel ?? 'वित्तीय वर्ष',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () async {
                          final currentDate =
                              parseFinancialYear(state.financialYear) ??
                              DateTime.now();

                          final DateTime? picked = await showDialog<DateTime>(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: Container(
                                  width: 300,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          t?.financialYearLabel ??
                                              'Select Year',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Container(
                                        height: 300,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: YearPicker(
                                          firstDate: DateTime(
                                            DateTime.now().year - 100,
                                          ),
                                          lastDate: DateTime.now(),
                                          initialDate: currentDate,
                                          selectedDate: currentDate,
                                          onChanged: (DateTime dateTime) {
                                            Navigator.pop(context, dateTime);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (picked != null) {
                            // Format the year as YYYY-YY (e.g., 2025-26)
                            final formattedYear = '${picked.year}';
                            if (!context.mounted) return;
                            context.read<TrackEligibleCoupleBloc>().add(
                              FinancialYearChanged(formattedYear),
                            );
                          }
                        },
                        child: Container(
                          // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                state.financialYear.isNotEmpty
                                    ? state.financialYear
                                    : t?.financialYearLabel ?? 'Select Year',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: state.financialYear.isEmpty
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 1, color: Colors.grey),
            const SizedBox(height: 8),

            // Is Pregnant
            BlocBuilder<TrackEligibleCoupleBloc, TrackEligibleCoupleState>(
              builder: (context, state) {
                final beneficiaryKey =
                    state.beneficiaryRefKey ?? state.beneficiaryId;

                return FutureBuilder<bool>(
                  future: _hasActiveMotherCare(beneficiaryKey),
                  builder: (context, snapshot) {
                    final hasActiveMotherCare = snapshot.data == true;

                    return ApiDropdown<bool>(
                      labelText: t?.isPregnantLabel ?? 'क्या महिला गर्भवती है?',
                      items: [true, false],
                      getLabel: (value) =>
                          value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                      value: state.isPregnant,
                      readOnly: hasActiveMotherCare,
                      onChanged: hasActiveMotherCare
                          ? null
                          : (value) {
                              if (value != null) {
                                context.read<TrackEligibleCoupleBloc>().add(
                                  IsPregnantChanged(value),
                                );
                              }
                            },
                    );
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
                        labelText:
                            '${t?.lmpDateLabelText ?? 'एलएमपी की तिथि'} *',
                        hintText: t?.dateHint,
                        initialDate: lmp,
                        onDateChanged: (date) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            LmpDateChanged(date),
                          );
                        },
                        isEditable: true,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 276),
                        ),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 31),
                        ),
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 8),
                      CustomDatePicker(
                        labelText:
                            '${t?.eddDateLabel ?? 'प्रसव की संभावित तिथि'} *',
                        hintText: t?.dateHint,
                        initialDate: edd,
                        onDateChanged: (date) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            EddDateChanged(date),
                          );
                        },
                        readOnly: true,
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
                      labelText:
                          t?.fpAdoptingLabel ??
                          'क्या आप/आपका साथी परिवार नियोजन अपना रहे हैं?',
                      items: [true, false],
                      getLabel: (value) =>
                          value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                      value: state.fpAdopting,
                      hintText: t?.select ?? 'Select',
                      onChanged: (value) {
                        if (value != null) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            FpAdoptingChanged(value),
                          );
                        }
                      },
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Dependent questions for family planning
                    if (state.fpAdopting == true) ...[
                      ApiDropdown<String>(
                        labelText:
                            t?.methodOfContraception ??
                            'Method of contraception',
                        items: const [
                          'Condom',
                          'Mala -N (Daily contraceptive pill)',
                          'Atra Injection',
                          'Copper -T (IUCD)',
                          'Chhaya (Weekly contraceptive pill)',
                          'ECP (Emergency contraceptive pill)',
                          'Male Sterilization',
                          'Female Sterilization',
                          'Any Other Specify',
                        ],
                        getLabel: (value) {
                          switch (value) {
                            case 'Condom':
                              return t?.condom ?? 'Condom';
                            case 'Mala -N (Daily contraceptive pill)':
                              return t?.malaN ??
                                  'Mala -N (Daily contraceptive pill)';
                            case 'Atra Injection':
                              return t?.atraInjection ?? 'Atra Injection';
                            case 'Copper -T (IUCD)':
                              return t?.copperT ?? 'Copper -T (IUCD)';
                            case 'Chhaya (Weekly contraceptive pill)':
                              return t?.chhaya ??
                                  'Chhaya (Weekly contraceptive pill)';
                            case 'ECP (Emergency contraceptive pill)':
                              return t?.ecp ??
                                  'ECP (Emergency contraceptive pill)';
                            case 'Male Sterilization':
                              return t?.maleSterilization ??
                                  'Male Sterilization';
                            case 'Female Sterilization':
                              return t?.femaleSterilization ??
                                  'Female Sterilization';
                            case 'Any Other Specify':
                              return t?.anyOtherSpecifyy ?? 'Any Other Specify';
                            default:
                              return value;
                          }
                        },
                        value: state.fpMethod,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<TrackEligibleCoupleBloc>().add(
                              FpMethodChanged(value),
                            );
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

                    if (state.fpMethod == 'Atra Injection' &&
                        state.fpAdopting == true) ...[
                      CustomDatePicker(
                        labelText:
                            t?.dateOfAntraInjection ??
                            'Date of Antra Injection',
                        hintText: 'dd-mm-yyyy',
                        initialDate: state.antraInjectionDateChanged,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context.read<TrackEligibleCoupleBloc>().add(
                              FpAntraInjectionDateChanged(date),
                            );
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],

                    if (state.fpMethod == 'Copper -T (IUCD)' &&
                        state.fpAdopting == true) ...[
                      CustomDatePicker(
                        labelText: t?.dateOfRemoval ?? 'Date of removal',
                        initialDate: state.removalDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          if (date != null) {
                            context.read<TrackEligibleCoupleBloc>().add(
                              RemovalDAteChange(date),
                            );
                          }
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                      CustomTextField(
                        labelText: t?.reasonForRemoval ?? 'Reason for Removal',
                        hintText:
                            t?.enterReasonForRemoval ??
                            'Enter reason for removal',
                        initialValue: state.removalReasonChanged,
                        onChanged: (value) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            RemovalReasonChanged(value),
                          );
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],

                    if (state.fpMethod == 'Condom' &&
                        state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:
                            t?.quantityOfCondoms ?? 'Quantity of Condoms',
                        hintText: t?.quantityOfCondoms ?? 'Quantity of condoms',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            CondomQuantity(value),
                          );
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod ==
                            'Chhaya (Weekly contraceptive pill)' &&
                        state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:
                            t?.quantityOfChhaya ??
                            'Quantity of Chhaya (Weekly contraceptive pill)',
                        hintText:
                            t?.quantityOfChhaya ??
                            'Quantity of Chhaya (Weekly contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.chhaya,
                        onChanged: (value) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            ChayaQuantity(value),
                          );
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod ==
                            'ECP (Emergency contraceptive pill)' &&
                        state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:
                            t?.quantityOfECP ??
                            'Quantity of ECP (Emergency contraceptive pill)',
                        hintText:
                            t?.quantityOfECP ??
                            'Quantity of ECP (Emergency contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.ecp,
                        onChanged: (value) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            ECPQuantity(value),
                          );
                        },
                      ),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                    if (state.fpMethod ==
                            'Mala -N (Daily contraceptive pill)' &&
                        state.fpAdopting == true) ...[
                      CustomTextField(
                        labelText:
                            t?.quantityOfMalaN ??
                            'Quantity of Mala -N (Daily contraceptive pill)',
                        hintText:
                            t?.quantityOfMalaN ??
                            'Quantity of Mala -N (Daily contraceptive pill)',
                        keyboardType: TextInputType.number,
                        initialValue: state.mala,
                        onChanged: (value) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            MalaQuantity(value),
                          );
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
                      labelText:
                          t?.isBeneficiaryAbsent ?? 'Is Beneficiary Absent',
                      items: [true, false],
                      getLabel: (value) =>
                          value ? (t?.yes ?? 'हाँ') : (t?.no ?? 'नहीं'),
                      value: state.beneficiaryAbsentCHanged,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            BeneficiaryAbsentCHanged(value),
                          );
                        }
                      },
                    ),
                    const Divider(thickness: 1, color: Colors.grey),

                    if (state.beneficiaryAbsentCHanged == true) ...[
                      const SizedBox(height: 8),
                      CustomTextField(
                        labelText: t?.reasonForAbsent ?? 'Reason for absent',
                        hintText: t?.reasonForAbsent ?? 'Enter reason',
                        onChanged: (val) {
                          context.read<TrackEligibleCoupleBloc>().add(
                            BeneficiaryAbsentReasonChanged(val),
                          );
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
                            builder: (context) => PreviousVisitsScreen(
                              beneficiaryId: beneficiaryId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize: Size.fromHeight(4.5.h),
                      ),
                      child: Text(
                        t?.previousVisitsButton ?? 'पिछला पेज',
                        style: TextStyle(
                          color: AppColors.background,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled
                          ? () {
                              context.read<TrackEligibleCoupleBloc>().add(
                                const SubmitTrackForm(),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize: Size.fromHeight(4.5.h),
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
                                fontSize: 14.sp,
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
