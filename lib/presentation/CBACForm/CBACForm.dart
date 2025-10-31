import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'bloc/cbac_form_bloc.dart';

class Cbacform extends StatefulWidget {
  const Cbacform({super.key});

  @override
  State<Cbacform> createState() => _CbacformState();
}

class _CbacformState extends State<Cbacform> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => CbacFormBloc()..add(const CbacOpened()),
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n.cbacFormTitle,
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<CbacFormBloc, CbacFormState>(
            listenWhen: (p, c) =>
                p.consentDialogShown != c.consentDialogShown ||
                p.consentAgreed != c.consentAgreed ||
                p.errorMessage != c.errorMessage ||
                p.missingKeys != c.missingKeys,
            listener: (context, state) async {
              final l10n = AppLocalizations.of(context);
              if (state.consentDialogShown && !state.consentAgreed) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(l10n?.cbacConsentTitle ?? 'Consent Form', style: TextStyle(fontSize: 15.sp),),
                    content: Text(
                      l10n?.cbacConsentBody ?? 'I have been explained by the ASHA, the purpose for which the information and measurement findings is being collected from me, in a language I understand and I give my consent to collect the information and measurement findings on my personal health profile.',
                      style:  TextStyle(fontSize: 15.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<CbacFormBloc>().add(const CbacConsentDisagreed());
                          Navigator.of(context).maybePop();
                        },
                        child: Text(l10n?.cbacConsentDisagree ?? 'DISAGREE'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<CbacFormBloc>().add(const CbacConsentAgreed());
                        },
                        child: Text(l10n?.cbacConsentAgree ?? 'AGREE'),
                      ),
                    ],
                  ),
                );
              }
              if (state.missingKeys.isNotEmpty && l10n != null) {
                String labelForKey(String k) {
                  switch (k) {
                    case 'partA.age':
                      return l10n.cbacA_ageQ;
                    case 'partA.tobacco':
                      return l10n.cbacA_tobaccoQ;
                    case 'partA.alcohol':
                      return l10n.cbacA_alcoholQ;
                    case 'partA.activity':
                      return l10n.cbacA_activityQ;
                    case 'partA.waist':
                      return l10n.cbacA_waistQ;
                    case 'partA.familyHistory':
                      return l10n.cbacA_familyQ;
                    case 'partB.b1.cough2w':
                      return l10n.cbacB_b1_cough2w;
                    case 'partB.b1.bloodMucus':
                      return l10n.cbacB_b1_bloodMucus;
                    case 'partB.b1.fever2w':
                      return l10n.cbacB_b1_fever2w;
                    case 'partB.b1.weightLoss':
                      return l10n.cbacB_b1_weightLoss;
                    case 'partB.b1.nightSweat':
                      return l10n.cbacB_b1_nightSweat;
                    case 'partB.b2.excessBleeding':
                      return l10n.cbacB_b2_excessBleeding;
                    case 'partB.b2.depression':
                      return l10n.cbacB_b2_depression;
                    case 'partB.b2.uterusProlapse':
                      return l10n.cbacB_b2_uterusProlapse;
                  }
                  return k;
                }
                final msg = '${l10n.cbacPleaseFill}: ' + state.missingKeys.map(labelForKey).join(', ');
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            },
            builder: (context, state) {
              final l10n = AppLocalizations.of(context);
              final tabs = [
                Tab(text: l10n?.cbacTabGeneral ?? 'GENERAL INFORMATION'),
                Tab(text: l10n?.cbacTabPersonal ?? 'PERSONAL INFORMATION'),
                Tab(text: l10n?.cbacTabPartA ?? 'PART A'),
                Tab(text: l10n?.cbacTabPartB ?? 'PART B'),
                Tab(text: l10n?.cbacTabPartC ?? 'PART C'),
                Tab(text: l10n?.cbacTabPartD ?? 'PART D'),
              ];

              final pages = [
                _GeneralInfoTab(),
                _PersonalInfoTab(),
                _PartATab(),
                _PartBTab(),
                _PartCTab(),
                _PartDTab(),
              ];

              return DefaultTabController(
                key: ValueKey(state.activeTab),
                initialIndex: state.activeTab,
                length: tabs.length,
                child: Column(
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          isScrollable: true,
                          indicatorColor: Theme.of(context).colorScheme.onPrimary,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                          indicatorWeight: 3.0,
                          tabs: tabs,
                          onTap: (_) {}, // navigation is controlled by buttons
                      ),
                    ),),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: pages,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8), // 👈 add corner radius
                              ),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8), // 👈 match same radius
                                  ),
                                ),
                                onPressed: state.activeTab == 0
                                    ? null
                                    : () => context.read<CbacFormBloc>().add(const CbacPrevTab()),
                                child: Text(
                                  l10n?.previousButton ?? 'PREVIOUS',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )

                          ),
                          SizedBox(
                            height: 44,
                            child: RoundButton(
                              title: state.activeTab == tabs.length - 1
                                  ? (l10n?.saveButton ?? 'SAVE')
                                  : (l10n?.nextButton ?? 'NEXT'),
                              width: 120,
                              borderRadius: 8,
                              isLoading: state.submitting,
                              onPress: () {
                                if (state.activeTab == tabs.length - 1) {
                                  // TODO: submit handling
                                } else {
                                  context.read<CbacFormBloc>().add(const CbacNextTab());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}


class _GeneralInfoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CbacFormBloc>();
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      children: [
        CustomTextField(
          hintText: l10n.ashaNameLabel,
          labelText: l10n.ashaNameLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('general.ashaName', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.anmNameLabel,
          labelText: l10n.anmNameLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('general.anmName', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.phcNameLabel,
          labelText: l10n.phcNameLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('general.phc', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.villageLabel,
          labelText: l10n.villageLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('general.village', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.hscNameLabel,
          labelText: l10n.hscNameLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('general.hsc', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomDatePicker(
          hintText: l10n.dateLabel,
          labelText: l10n.dateLabel,
          initialDate: DateTime.now(),
          isEditable: false,
          onDateChanged: null,
        ),
        const Divider(height: 0.5),

      ],
    );
  }
}

class _PersonalInfoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CbacFormBloc>();
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      children: [
        CustomTextField(
          hintText: l10n.nameLabelSimple,
          labelText: l10n.nameLabelSimple,
          onChanged: (v) => bloc.add(CbacFieldChanged('personal.name', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.husbandFatherNameLabel,
          labelText: l10n.husbandFatherNameLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('personal.father', v.trim())),
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.ageLabel,
          labelText: l10n.ageLabel,
          keyboardType: TextInputType.number,
          onChanged: (v) => bloc.add(CbacFieldChanged('personal.age', v.trim())),
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['personal.gender'] != current.data['personal.gender'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.genderLabel,
              labelText: l10n.genderLabel,
              items: [l10n.genderMale, l10n.genderFemale, l10n.genderOther],
              value: state.data['personal.gender'],
              getLabel: (s) => s,
              onChanged: (v) => bloc.add(CbacFieldChanged('personal.gender', v)),
            );
          },
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.addressLabel,
          labelText: l10n.addressLabel,
          onChanged: (v) => bloc.add(CbacFieldChanged('personal.address', v.trim())),
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['personal.idType'] != current.data['personal.idType'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.identificationTypeLabel,
              labelText: l10n.identificationTypeLabel,
              items: [l10n.idTypeAadhaar, l10n.idTypeVoterId, l10n.uid,],
              value: state.data['personal.idType'],
              getLabel: (s) => s,
              onChanged: (v) => bloc.add(CbacFieldChanged('personal.idType', v)),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['personal.hasConditions'] != current.data['personal.hasConditions'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.affiliatedToStateInsuranceLabel,
              labelText: l10n.affiliatedToStateInsuranceLabel,
              items: [l10n.yes, l10n.no],
              value: state.data['personal.hasConditions'],
              getLabel: (s) => s,
              onChanged: (v) => bloc.add(CbacFieldChanged('personal.hasConditions', v)),
            );
          },
        ),
        const Divider(height: 0.5),
        CustomTextField(
          hintText: l10n.mobileTelephoneLabel,
          labelText: l10n.mobileTelephoneLabel,
          keyboardType: TextInputType.number,
          onChanged: (v) => bloc.add(CbacFieldChanged('personal.mobile', v.trim())),
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['personal.disability'] != current.data['personal.disability'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.disabilityQuestionLabel,
              labelText: l10n.disabilityQuestionLabel,
              items: [l10n.disabilityVisualImpairment, l10n.disabilityPhysicallyHandicap, l10n.disabilityBedridden, l10n.disabilityNeedHelp],
              value: state.data['personal.disability'],
              getLabel: (s) => s,
              onChanged: (v) => bloc.add(CbacFieldChanged('personal.disability', v)),
            );
          },
        ),
      ],
    );
  }
}

class _PartATab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CbacFormBloc, CbacFormState>(
      builder: (context, state) {
        final bloc = context.read<CbacFormBloc>();

        final age = state.data['partA.age'] as String?;
        final tobacco = state.data['partA.tobacco'] as String?; // Yes/No
        final alcohol = state.data['partA.alcohol'] as String?; // Yes/No
        final activity = state.data['partA.activity'] as String?; // Yes/No (Yes = meets 150m)
        final waist = state.data['partA.waist'] as String?; // 80 or less / 81-90 / 90+ (dropdown)
        final familyHx = state.data['partA.familyHistory'] as String?; // Yes/No
        final l10n = AppLocalizations.of(context)!;

        Widget header() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cbacQuestions, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                Text(l10n.cbacScore, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ],
            );
        Widget rowScore(int score) => SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('$score', style: const TextStyle(color: Colors.black54)),
              ),
            );

        Widget qRow({
          required String question,
          required List<String> items,
          required String? value,
          required void Function(String?) onChanged,
          required int score,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style:  TextStyle(fontSize: 14.sp),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 160,
                    child: ApiDropdown<String>(
                      hintText: '',
                      items: items,
                      getLabel: (s) => s,
                      value: value,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  rowScore(score),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 0.5),
            ],
          );
        }

        // Localized option lists
        final itemsAge = <String>[
          l10n.cbacA_ageLT30,
          l10n.cbacA_age30to39,
          l10n.cbacA_age40to49,
          l10n.cbacA_age50to69,
        ];
        final itemsTobacco = <String>[
          l10n.cbacA_tobNever,
          l10n.cbacA_tobSometimes,
          l10n.cbacA_tobDaily,
        ];
        final itemsYesNo = <String>[l10n.yes, l10n.no];
        final itemsActivity = <String>[
          l10n.cbacA_actLT150,
          l10n.cbacA_actGT150,
        ];
        final itemsWaist = <String>[
          l10n.cbacA_waistLE80,
          l10n.cbacA_waist81to90,
          l10n.cbacA_waistGT90,
        ];

        // Compute scores from localized selections via indices
        final idxAge = age == null ? -1 : itemsAge.indexOf(age);
        final scoreAge = switch (idxAge) { 1 => 1, 2 => 2, 3 => 3, _ => 0 };
        final idxTob = tobacco == null ? -1 : itemsTobacco.indexOf(tobacco);
        final scoreTobacco = idxTob <= 0 ? 0 : 1;
        final idxAlcohol = alcohol == null ? -1 : itemsYesNo.indexOf(alcohol);
        final scoreAlcohol = idxAlcohol == 0 ? 1 : 0;
        final idxActivity = activity == null ? -1 : itemsActivity.indexOf(activity);
        final scoreActivity = idxActivity == 0 ? 1 : 0;
        final idxWaist = waist == null ? -1 : itemsWaist.indexOf(waist);
        final scoreWaist = switch (idxWaist) { 1 => 1, 2 => 2, _ => 0 };
        final idxFamily = familyHx == null ? -1 : itemsYesNo.indexOf(familyHx);
        final scoreFamily = idxFamily == 0 ? 2 : 0;
        final total = scoreAge + scoreTobacco + scoreAlcohol + scoreActivity + scoreWaist + scoreFamily;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            header(),
            const SizedBox(height: 8),

            qRow(
              question: l10n.cbacA_ageQ,
              items: itemsAge,
              value: age,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.age', v)),
              score: scoreAge,
            ),

            // Tobacco row
            qRow(
              question: l10n.cbacA_tobaccoQ,
              items: itemsTobacco,
              value: tobacco,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.tobacco', v)),
              score: scoreTobacco,
            ),

            // Alcohol row
            qRow(
              question: l10n.cbacA_alcoholQ,
              items: itemsYesNo,
              value: alcohol,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.alcohol', v)),
              score: scoreAlcohol,
            ),

            qRow(
              question: l10n.cbacA_waistQ,
              items: itemsWaist,
              value: waist,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.waist', v)),
              score: scoreWaist,
            ),

            qRow(
              question: l10n.cbacA_activityQ,
              items: itemsActivity,
              value: activity,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.activity', v)),
              score: scoreActivity,
            ),
            // Waist measurement row


            // Family history row
            qRow(
              question: l10n.cbacA_familyQ,
              items: itemsYesNo,
              value: familyHx,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.familyHistory', v)),
              score: scoreFamily,
            ),

            const SizedBox(height: 8),
            Text(l10n.cbacTotalScorePartA(total), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }
}

class _PartBTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CbacFormBloc>();
    final l10n = AppLocalizations.of(context)!;

    Widget chip(String text) => Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              )
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );

    List<Widget> qRow(String question, String keyPath) => [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  question,
                  style:  TextStyle(fontSize: 15.sp),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 180,
                child: BlocBuilder<CbacFormBloc, CbacFormState>(
                  buildWhen: (previous, current) => previous.data[keyPath] != current.data[keyPath],
                  builder: (context, state) {
                    return ApiDropdown<String>(
                      items: [l10n.yes, l10n.no],
                      getLabel: (s) => s,
                      value: state.data[keyPath],
                      onChanged: (v) => bloc.add(CbacFieldChanged(keyPath, v)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 0.5),
        ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        chip(l10n.cbacPartB1),
        ...qRow(l10n.cbacB_b1_breath, 'partB.b1.breath'),
        ...qRow(l10n.cbacB_b1_cough2w, 'partB.b1.cough2w'),
        ...qRow(l10n.cbacB_b1_bloodMucus, 'partB.b1.bloodMucus'),
        ...qRow(l10n.cbacB_b1_fever2w, 'partB.b1.fever2w'),
        ...qRow(l10n.cbacB_b1_weightLoss, 'partB.b1.weightLoss'),
        ...qRow(l10n.cbacB_b1_nightSweat, 'partB.b1.nightSweat'),
        ...qRow(l10n.cbacB_b1_seizures, 'partB.b1.seizures'),
        ...qRow(l10n.cbacB_b1_openMouth, 'partB.b1.openMouth'),
        ...qRow(l10n.cbacB_b1_ulcers, 'partB.b1.ulcers'),
        ...qRow(l10n.cbacB_b1_swellingMouth, 'partB.b1.swellingMouth'),
        ...qRow(l10n.cbacB_b1_rashMouth, 'partB.b1.rashMouth'),
        ...qRow(l10n.cbacB_b1_chewPain, 'partB.b1.chewPain'),
        ...qRow(l10n.cbacB_b1_druggs, 'partB.b1.druggs'),
        ...qRow(l10n.cbacB_b1_tuberculosisFamily, 'partB.b1.Tuberculosis'),
        ...qRow(l10n.cbacB_b1_history, 'partB.b1.history'),
        ...qRow(l10n.cbacB_b1_palmsSores, 'partB.b1.palms'),
        ...qRow(l10n.cbacB_b1_tingling, 'partB.b1.tingling'),

        // Additional Part B1 (as per image)
        ...qRow(l10n.cbacB_b1_visionBlurred, 'partB.b1.visionBlurred'),
        ...qRow(l10n.cbacB_b1_readingDifficulty, 'partB.b1.readingDifficulty'),
        ...qRow(l10n.cbacB_b1_eyePain, 'partB.b1.eyePain'),
        ...qRow(l10n.cbacB_b1_eyeRedness, 'partB.b1.eyeRedness'),
        ...qRow(l10n.cbacB_b1_hearingDifficulty, 'partB.b1.hearingDifficulty'),
        ...qRow(l10n.cbacB_b1_changeVoice, 'partB.b1.changeVoice'),
        ...qRow(l10n.cbacB_b1_skinRashDiscolor, 'partB.b1.skinRashDiscolor'),
        ...qRow(l10n.cbacB_b1_skinThick, 'partB.b1.skinThick'),
        ...qRow(l10n.cbacB_b1_skinLump, 'partB.b1.skinLump'),
        ...qRow(l10n.cbacB_b1_numbnessHotCold, 'partB.b1.numbnessHotCold'),
        ...qRow(l10n.cbacB_b1_scratchesCracks, 'partB.b1.scratchesCracks'),
        ...qRow(l10n.cbacB_b1_tinglingNumbness, 'partB.b1.tinglingNumbness'),
        ...qRow(l10n.cbacB_b1_closeEyelidsDifficulty, 'partB.b1.closeEyelidsDifficulty'),
        ...qRow(l10n.cbacB_b1_holdingDifficulty, 'partB.b1.holdingDifficulty'),
        ...qRow(l10n.cbacB_b1_legWeaknessWalk, 'partB.b1.legWeaknessWalk'),

        chip(l10n.cbacPartB2),
        ...qRow(l10n.cbacB_b2_breastLump, 'partB.b2.breastLump'),
        ...qRow(l10n.cbacB_b2_nippleBleed, 'partB.b2.nippleBleed'),
        ...qRow(l10n.cbacB_b2_breastShapeDiff, 'partB.b2.breastShapeDiff'),
        ...qRow(l10n.cbacB_b2_excessBleeding, 'partB.b2.excessBleeding'),
        ...qRow(l10n.cbacB_b2_depression, 'partB.b2.depression'),
        ...qRow(l10n.cbacB_b2_uterusProlapse, 'partB.b2.uterusProlapse'),
        ...qRow(l10n.cbacB_b2_postMenopauseBleed, 'partB.b2.postMenopauseBleed'),
        ...qRow(l10n.cbacB_b2_postIntercourseBleed, 'partB.b2.postIntercourseBleed'),
        ...qRow(l10n.cbacB_b2_smellyDischarge, 'partB.b2.smellyDischarge'),
        ...qRow(l10n.cbacB_b2_irregularPeriods, 'partB.b2.irregularPeriods'),
        ...qRow(l10n.cbacB_b2_jointPain, 'partB.b2.jointPain'),
      ],
    );
  }
}

class _PartCTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CbacFormBloc>();
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              )
            ],
          ),
          child: Center(
            child: Text(l10n.cbacHeaderLungRisk, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),

        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['partC.cookingFuel'] != current.data['partC.cookingFuel'],
          builder: (context, state) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(l10n.cbacC_fuelQ, style: TextStyle(fontSize: 15.sp),)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 180,
                  child: ApiDropdown<String>(
                    items: [l10n.firewod, l10n.cropResidues, l10n.cowdung, l10n.coal,l10n.lpg, l10n.cbacC_fuelKerosene],
                    getLabel: (s) => s,
                    value: state.data['partC.cookingFuel'],
                    onChanged: (v) => bloc.add(CbacFieldChanged('partC.cookingFuel', v)),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Divider(height: 0.5),

        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['partC.businessRisk'] != current.data['partC.businessRisk'],
          builder: (context, state) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(l10n.cbacC_businessRiskQ, style: TextStyle(fontSize: 15.sp),)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 180,
                  child: ApiDropdown<String>(
                    items: [l10n.cbacC_workingPollutedIndustries, l10n.burningOfGrabage, l10n.burningCrop, l10n.cbacC_workingSmokeyFactory],
                    getLabel: (s) => s,
                    value: state.data['partC.businessRisk'],
                    onChanged: (v) => bloc.add(CbacFieldChanged('partC.businessRisk', v)),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Divider(height: 0.5),
      ],
    );
  }
}

class _PartDTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CbacFormBloc, CbacFormState>(
      builder: (context, state) {
        final bloc = context.read<CbacFormBloc>();
        final q1 = state.data['partD.q1'] as String?;
        final q2 = state.data['partD.q2'] as String?;

        // Dropdown labels and their implicit indices used as scores
        final l10n = AppLocalizations.of(context)!;
        final options = [
          l10n.cbacD_opt0,
          l10n.cbacD_opt1,
          l10n.cbacD_opt2,
          l10n.cbacD_opt3,
        ];

        int scoreFromValue(String? v) {
          if (v == null) return 0;
          final idx = options.indexOf(v);
          return idx < 0 ? 0 : idx;
        }

        final total = scoreFromValue(q1) + scoreFromValue(q2);

        Widget header() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cbacQuestions, style:  TextStyle(fontWeight: FontWeight.w600,fontSize: 14.sp)),
                Text(l10n.cbacScore, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ],
            );

        Widget scoreBox(String? v) => SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(v == null ? '-' : '${scoreFromValue(v)}', style: const TextStyle(color: Colors.black54)),
              ),
            );

        Widget row({required String question, required String? value, required void Function(String?) onChanged}) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(question, style:  TextStyle(fontSize: 14.sp))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: ApiDropdown<String>(
                      hintText: '',
                      items: options,
                      getLabel: (s) => s,
                      value: value,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  scoreBox(value),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 0.5),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            header(),
            const SizedBox(height: 8),
            row(
              question: l10n.cbacD_q1,
              value: q1,
              onChanged: (v) => bloc.add(CbacFieldChanged('partD.q1', v)),
            ),
            row(
              question: l10n.cbacD_q2,
              value: q2,
              onChanged: (v) => bloc.add(CbacFieldChanged('partD.q2', v)),
            ),
            const SizedBox(height: 12),
            Text(l10n.cbacTotalScorePartD(total), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
      },
    );
  }
}
