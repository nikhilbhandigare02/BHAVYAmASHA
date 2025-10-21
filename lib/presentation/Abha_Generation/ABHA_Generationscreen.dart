import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../core/utils/enums.dart' show PostApiStatus;
import 'bloc/abha_generation_bloc.dart';

class AbhaGenerationscreen extends StatefulWidget {
  const AbhaGenerationscreen({super.key});

  @override
  State<AbhaGenerationscreen> createState() => _AbhaGenerationscreenState();
}

class _AbhaGenerationscreenState extends State<AbhaGenerationscreen> {
  final _formKey = GlobalKey<FormState>();

  List<String> get _consentTexts => const [
    'I am voluntarily sharing my Aadhaar Number / Virtual ID issued by the Unique Identification Authority of India ("UIDAI"), and my demographic information for the purpose of creating an Ayushman Bharat Health Account number ("ABHA number") and Ayushman Bharat Health Account address ("ABHA Address"). I authorize NHA to use my Aadhaar number / Virtual ID for performing Aadhaar based authentication with UIDAI as per the provisions of the Aadhaar (Targeted Delivery of Financial and other Subsidies, Benefits and Services) Act, 2016 for the aforesaid purpose. I understand that UIDAI will share my e-KYC details, or response of "Yes" with NHA upon successful authentication.',
    'I intend to create Ayushman Bharat Health Account Number ("ABHA number") and Ayushman Bharat Health Account address ("ABHA Address") using document other than Aadhaar.',
    'I consent to usage of my ABHA address and ABHA number for linking of my legacy (past) government health records and those which will be generated during this encounter.',
    'I authorize the sharing of all my health records with healthcare provider(s) for the purpose of providing healthcare services to me during this encounter',
    'I consent to the anonymization and subsequent use of my government health records for public health purposes.',
    'I, Rohit Chavan, confirm that I have duly informed and explained the beneficiary of the contents of consent for aforementioned purposes.',
    'I, (beneficiary name), have been explained about the consent as stated above and hereby provide my consent for the aforementioned purposes.',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => AbhaGenerationBloc(),
      child: Scaffold(
        appBar: AppHeader(screenTitle: l10n?.gridAbhaGeneration ?? 'ABHA Generation', showBack: true),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: BlocConsumer<AbhaGenerationBloc, AbhaGenerationState>(
              listenWhen: (p, c) =>
              p.postApiStatus != c.postApiStatus ||
                  p.errorMessage != c.errorMessage,
              listener: (context, state) {
                if (state.postApiStatus == PostApiStatus.error &&
                    state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!)),
                  );
                }
                if (state.postApiStatus == PostApiStatus.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('OTP generated successfully')),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        children: [
                          /// 📱 Mobile Number Field
                          CustomTextField(
                            labelText: l10n?.mobileLabelSimple ?? 'Mobile Number',
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            onChanged: (v) => context
                                .read<AbhaGenerationBloc>()
                                .add(AbhaUpdateMobile(v.trim())),
                          ),
                          Divider(
                              color: AppColors.divider,
                              thickness: 0.5,
                              height: 0),

                          const SizedBox(height: 12),

                          /// 🧾 Declaration Card (includes Aadhaar field + consent list)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding:
                                  EdgeInsets.fromLTRB(12, 12, 12, 8),
                                  child: Text(
                                    'I hereby declare that:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ),

                                /// 🆔 Aadhaar Number inside the card
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: CustomTextField(
                                    labelText: 'Aadhaar Number',
                                    keyboardType: TextInputType.number,
                                    maxLength: 12,
                                    onChanged: (v) => context
                                        .read<AbhaGenerationBloc>()
                                        .add(AbhaUpdateAadhaar(v.trim())),
                                  ),
                                ),

                                const Divider(height: 0),

                                /// 🧾 Consent items
                                ...List.generate(_consentTexts.length, (i) {
                                  final checked = i < state.consents.length
                                      ? state.consents[i]
                                      : false;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Transform.scale(
                                            scale: 0.8,
                                            child: Checkbox(
                                              value: checked,
                                              onChanged: (_) => context
                                                  .read<AbhaGenerationBloc>()
                                                  .add(AbhaToggleConsent(i)),
                                              materialTapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                              visualDensity:
                                              const VisualDensity(
                                                  horizontal: -4,
                                                  vertical: -4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _consentTexts[i],
                                              textAlign: TextAlign.justify,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                height: 1.3,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 🔘 Generate OTP Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        height: 42,
                        width: double.infinity,
                        child: RoundButton(
                          title: 'GENERATE OTP',
                          onPress: () => context
                              .read<AbhaGenerationBloc>()
                              .add(AbhaGenerateOtp()),
                          color: AppColors.primary,
                          borderRadius: 8,
                          isLoading: state.postApiStatus ==
                              PostApiStatus.loading,
                          disabled: !state.isFormValid,
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
