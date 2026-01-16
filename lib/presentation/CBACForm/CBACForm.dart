import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'bloc/cbac_form_bloc.dart';
import '../HomeScreen/HomeScreen.dart';

class Cbacform extends StatefulWidget {
  final String? beneficiaryId;
  final String? hhid;

  const Cbacform({super.key, this.beneficiaryId, this.hhid});

  @override
  State<Cbacform> createState() => _CbacformState();
}

class _CbacformState extends State<Cbacform> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final beneficiaryId =
        widget.beneficiaryId ?? args?['beneficiaryId']?.toString();
    final hhid = widget.hhid ?? args?['hhid']?.toString();

    print(
      '🚀 Initializing CBAC Form with - beneficiaryId: $beneficiaryId, hhid: $hhid',
    );

    return BlocProvider(
      create: (_) =>
          CbacFormBloc(beneficiaryId: beneficiaryId, householdId: hhid)
            ..add(CbacOpened(beneficiaryId: beneficiaryId, hhid: hhid)),
      child: Scaffold(
        appBar: AppHeader(screenTitle: l10n.cbacFormTitle, showBack: true),
        body: SafeArea(
          child: BlocConsumer<CbacFormBloc, CbacFormState>(
            listenWhen: (p, c) =>
                p.consentDialogShown != c.consentDialogShown ||
                p.consentAgreed != c.consentAgreed ||
                p.errorMessage != c.errorMessage ||
                p.missingKeys != c.missingKeys ||
                p.isSuccess != c.isSuccess,
            listener: (context, state) async {
              final l10n = AppLocalizations.of(context);

              // Handle form submission success
              if (state.isSuccess) {
                showAppSnackBar(context, 'form submitted successfully');

                Future.delayed(const Duration(milliseconds: 400), () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialTabIndex: 1),
                      ),
                      (route) => false,
                    );
                  });
                });
              }

              if (state.consentDialogShown && !state.consentAgreed) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    title: Text(
                      l10n?.cbacConsentTitle ?? 'Consent Form',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      l10n?.cbacConsentBody ??
                          'I have been explained by the ASHA, the purpose for which the information and measurement findings is being collected from me, in a language I understand and I give my consent to collect the information and measurement findings on my personal health profile.',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<CbacFormBloc>().add(
                            const CbacConsentDisagreed(),
                          );
                          Navigator.of(context).maybePop();
                        },
                        child: Text(l10n?.cbacConsentDisagree ?? 'DISAGREE'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<CbacFormBloc>().add(
                            const CbacConsentAgreed(),
                          );
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
                    case 'partB.b1.druggs':
                      return l10n.cbacB_b1_druggs;
                    case 'partB.b1.Tuberculosis':
                      return l10n.cbacB_b1_tuberculosisFamily;
                    case 'partB.b1.history':
                      return l10n.cbacB_b1_history;
                    case 'partB.b2.excessBleeding':
                      return l10n.cbacB_b2_excessBleeding;
                    case 'partB.b2.depression':
                      return l10n.cbacB_b2_depression;
                    case 'partB.b2.uterusProlapse':
                      return l10n.cbacB_b2_uterusProlapse;
                  }
                  return k;
                }


                final firstKey = state.missingKeys.first;
                final firstLabel = labelForKey(firstKey);
                final msg = '${l10n.cbacPleaseFill} $firstLabel';
                showAppSnackBar(context, msg);
              } else if (state.errorMessage != null &&
                  state.errorMessage!.isNotEmpty) {
                showAppSnackBar(context, state.errorMessage!);
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
                          indicatorColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          labelColor: Theme.of(context).colorScheme.onPrimary,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.7),
                          indicatorWeight: 3.0,
                          tabs: tabs,
                          onTap: (idx) {
                            context
                                .read<CbacFormBloc>()
                                .add(CbacTabChanged(idx));
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        children: pages,
                      ),
                    ),
                    Container(
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Builder(
                          builder: (tabContext) {
                            final isLastTab = state.activeTab == 5;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [

                                if (state.activeTab != 0)
                                  SizedBox(
                                    height: 34,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        onPressed: () => tabContext
                                            .read<CbacFormBloc>()
                                            .add(const CbacPrevTab()),
                                        child: Text(
                                          'PREV',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 120),

                                SizedBox(
                                  height: 34,
                                  child: RoundButton(
                                    title: isLastTab
                                        ? (l10n?.submit ?? 'SUBMIT')
                                        : (l10n?.nextButton ?? 'NEXT'),
                                    width: 100,
                                    borderRadius: 4,
                                    isLoading: state.submitting,
                                    onPress: () {
                                      if (isLastTab) {
                                        tabContext.read<CbacFormBloc>().add(
                                              const CbacSubmitted(),
                                            );
                                      } else {
                                        tabContext.read<CbacFormBloc>().add(
                                              const CbacNextTab(),
                                            );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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

class _GeneralInfoTab extends StatefulWidget {
  @override
  _GeneralInfoTabState createState() => _GeneralInfoTabState();
}

class _GeneralInfoTabState extends State<_GeneralInfoTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String _ashaName = '';
  String _hscName = '';
  String _district = '';
  String _block = '';
  bool _fieldsInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      debugPrint('🔍 Loading user data for auto-fill...');

      // Get the current user using UserInfo
      final user = await UserInfo.getCurrentUser();

      if (user != null) {
        debugPrint('✅ Found current user: ${user['user_name']}');

        // Handle the case where details might be a string or already a map
        Map<String, dynamic> userDetails = {};

        if (user['details'] != null) {
          if (user['details'] is Map) {
            userDetails = Map<String, dynamic>.from(user['details'] as Map);
          } else if (user['details'] is String) {
            try {
              // Try to parse the string as JSON
              userDetails =
                  jsonDecode(user['details'] as String) as Map<String, dynamic>;
            } catch (e) {
              debugPrint('❌ Error parsing user details as JSON: $e');
              // Try alternative parsing method if JSON parsing fails
              _tryAlternativeParsing(user['details']!.toString());
              return;
            }
          }
        }

        // Extract values from the provided JSON structure
        final name = userDetails['name'] is Map
            ? userDetails['name'] as Map<String, dynamic>
            : {};
        final workingLocation = userDetails['working_location'] is Map
            ? userDetails['working_location'] as Map<String, dynamic>
            : {};

        final firstName = name['first_name']?.toString()?.trim() ?? '';
        final middleName = name['middle_name']?.toString()?.trim() ?? '';
        final lastName = name['last_name']?.toString()?.trim() ?? '';

        // Construct full name with middle name if available
        String fullName = '';
        if (middleName.isNotEmpty) {
          fullName = '$firstName $middleName $lastName'.trim();
        } else {
          fullName = '$firstName $lastName'.trim();
        }

        // Extract location details
        final hscName = workingLocation['hsc_name']?.toString()?.trim() ?? '';
        final district = workingLocation['district']?.toString()?.trim() ?? '';
        final block = workingLocation['village']?.toString()?.trim() ?? '';

        debugPrint('🎯 EXTRACTED VALUES FROM USER DETAILS:');
        debugPrint('   First Name: "$firstName"');
        if (middleName.isNotEmpty) debugPrint('   Middle Name: "$middleName"');
        debugPrint('   Last Name: "$lastName"');
        debugPrint('   Full Name: "$fullName"');
        debugPrint('   HSC Name: "$hscName"');
        debugPrint('   District: "$district"');
        debugPrint('   Block: "$block"');

        // Use the actual name from details or fallback to username
        final finalAshaName = fullName.isNotEmpty
            ? fullName
            : user['user_name']?.toString()?.trim() ?? '';
        final finalHscName = hscName;
        final finalDistrict = district;
        final finalBlock = block;

        debugPrint('🎯 FINAL VALUES FOR AUTO-FILL:');
        debugPrint('   ASHA Name: "$finalAshaName"');
        debugPrint('   HSC Name: "$finalHscName"');
        debugPrint('   District: "$finalDistrict"');
        debugPrint('   Block: "$finalBlock"');

        if (mounted) {
          setState(() {
            _ashaName = finalAshaName;
            _hscName = finalHscName;
            _district = finalDistrict;
            _block = finalBlock;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('❌ No active user found in local database');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _tryAlternativeParsing(String detailsString) {
    try {
      debugPrint('🔄 Trying alternative parsing...');

      // Extract first_name using regex
      final firstNameMatch = RegExp(
        r'first_name:\s*([^,]+)',
      ).firstMatch(detailsString);
      final lastNameMatch = RegExp(
        r'last_name:\s*([^,]+)',
      ).firstMatch(detailsString);
      final hscNameMatch = RegExp(
        r'hsc_name:\s*([^,]+)',
      ).firstMatch(detailsString);
      final districtMatch = RegExp(
        r'district:\s*([^,]+)',
      ).firstMatch(detailsString);
      final blockMatch = RegExp(r'block:\s*([^,}]+)').firstMatch(detailsString);

      String firstName = firstNameMatch?.group(1)?.trim() ?? '';
      String lastName = lastNameMatch?.group(1)?.trim() ?? '';
      String hscName = hscNameMatch?.group(1)?.trim() ?? '';
      String district = districtMatch?.group(1)?.trim() ?? '';
      String block = blockMatch?.group(1)?.trim() ?? '';

      // Clean up the values (remove trailing commas, etc.)
      firstName = firstName.replaceAll(RegExp(r'[,\s]*$'), '');
      lastName = lastName.replaceAll(RegExp(r'[,\s]*$'), '');
      hscName = hscName.replaceAll(RegExp(r'[,\s]*$'), '');
      district = district.replaceAll(RegExp(r'[,\s]*$'), '');
      block = block.replaceAll(RegExp(r'[,\s]*$'), '');

      debugPrint('🎯 ALTERNATIVE PARSING RESULTS:');
      debugPrint('   First Name: "$firstName"');
      debugPrint('   Last Name: "$lastName"');
      debugPrint('   HSC Name: "$hscName"');
      debugPrint('   District: "$district"');
      debugPrint('   Block: "$block"');

      if (mounted) {
        setState(() {
          _ashaName = '$firstName $lastName'.trim();
          _hscName = hscName;
          _district = district;
          _block = block;
        });
      }
    } catch (e) {
      debugPrint('❌ Alternative parsing also failed: $e');
    }
  }

  void _updateFormFields(BuildContext context) {
    if (_fieldsInitialized || _isLoading) return;

    final bloc = BlocProvider.of<CbacFormBloc>(context);

    debugPrint('🔄 UPDATING FORM FIELDS WITH EXTRACTED DATA:');
    debugPrint('   ASHA Name: "$_ashaName"');
    debugPrint('   HSC Name: "$_hscName"');
    debugPrint('   District: "$_district"');
    debugPrint('   Block: "$_block"');

    if (_ashaName.isNotEmpty) {
      bloc.add(CbacFieldChanged('general.ashaName', _ashaName));
      debugPrint('   ✅ Set ASHA Name: $_ashaName');
    }
    if (_hscName.isNotEmpty) {
      bloc.add(CbacFieldChanged('general.hsc', _hscName));
      debugPrint('   ✅ Set HSC Name: $_hscName');
    }
    if (_district.isNotEmpty) {
      bloc.add(CbacFieldChanged('general.phc', _district));
      debugPrint('   ✅ Set District: $_district');
    }
    if (_block.isNotEmpty) {
      bloc.add(CbacFieldChanged('general.village', _block));
      debugPrint('   ✅ Set Block: $_block');
    }

    _fieldsInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<CbacFormBloc, CbacFormState>(
      builder: (context, state) {
        // Update form fields after build is complete
        final screeningDate = state.data['general.screeningDate'] as String?;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateFormFields(context);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            // ASHA Name Field - Should show "Sita Kumari"
            CustomTextField(
              key: ValueKey('ashaName_${_ashaName}'),
              hintText: l10n.ashaNameHint,
              labelText: l10n.ashaNameHint,
              initialValue: _ashaName,
              readOnly: _ashaName.isNotEmpty,
              onChanged: (v) {
                context.read<CbacFormBloc>().add(
                  CbacFieldChanged('general.ashaName', v.trim()),
                );
              },
            ),
            const Divider(height: 0.5),

            // ANM Name Field
            CustomTextField(
              hintText: l10n.anmNameLabel,
              labelText: l10n.anmNameLabel,
              initialValue: state.data['general.anmName']?.toString() ?? '',
              onChanged: (v) => context.read<CbacFormBloc>().add(
                CbacFieldChanged('general.anmName', v.trim()),
              ),
            ),
            const Divider(height: 0.5),

            CustomTextField(
              // key: ValueKey('phc_${_district}'),
              hintText: l10n.phcNameLabel,
              labelText: l10n.phcNameLabel,
              //initialValue: _district,
              onChanged: (v) => context.read<CbacFormBloc>().add(
                CbacFieldChanged('general.phc', v.trim()),
              ),
            ),
            const Divider(height: 0.5),

            CustomTextField(
              key: ValueKey('village_${_block}'),
              hintText: l10n.villageLabel,
              labelText: l10n.villageLabel,
              initialValue: _block,
              onChanged: (v) => context.read<CbacFormBloc>().add(
                CbacFieldChanged('general.village', v.trim()),
              ),
            ),
            const Divider(height: 0.5),

            CustomTextField(
              key: ValueKey('hsc_${_hscName}'),
              hintText: l10n.hscNameLabelCbac,
              labelText: l10n.hscNameLabelCbac,
              initialValue: _hscName,
              readOnly: _hscName.isNotEmpty,
              onChanged: (v) => context.read<CbacFormBloc>().add(
                CbacFieldChanged('general.hsc', v.trim()),
              ),
            ),
            const Divider(height: 0.5),

            Opacity(
              opacity: 0.7,
              child: CustomDatePicker(
                hintText: l10n.dateLabel,
                labelText: l10n.dateLabel,
                initialDate: DateTime.now(),
                isEditable: false,
                readOnly: true,
                onDateChanged: null,
              ),
            ),
            const Divider(height: 0.5),
          ],
        );
      },
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
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (p, c) =>
              p.data['personal.name'] != c.data['personal.name'],
          builder: (context, state) {
            return CustomTextField(
              hintText: l10n.nameLabelSimple,
              labelText: l10n.nameLabelSimple,
              initialValue: state.data['personal.name']?.toString() ?? '',
              onChanged: (v) =>
                  bloc.add(CbacFieldChanged('personal.name', v.trim())),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (p, c) =>
              p.data['personal.father'] != c.data['personal.father'],
          builder: (context, state) {
            return CustomTextField(
              hintText: l10n.husbandFatherNameLabel,
              labelText: l10n.husbandFatherNameLabel,
              initialValue: state.data['personal.father']?.toString() ?? '',
              onChanged: (v) =>
                  bloc.add(CbacFieldChanged('personal.father', v.trim())),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (p, c) => p.data['personal.age'] != c.data['personal.age'],
          builder: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final txt = state.data['personal.age']?.toString().trim();
              final hasPartA =
                  (state.data['partA.age']?.toString().isNotEmpty ?? false) &&
                  (state.data['partA.age_code']?.toString().isNotEmpty ??
                      false);
              final n = int.tryParse(txt ?? '');
              if (!hasPartA && n != null) {
                String label;
                String code;
                if (n <= 29) {
                  label = '0 to 29 years';
                  code = 'AGE_0_29';
                } else if (n <= 39) {
                  label = '30 to 39 years';
                  code = 'AGE_30_39';
                } else if (n <= 49) {
                  label = '40 to 49 years';
                  code = 'AGE_40_49';
                } else if (n <= 59) {
                  label = '50 to 59 years';
                  code = 'AGE_50_59';
                } else {
                  label = 'Over 59 years';
                  code = 'AGE_GE60';
                }
                bloc.add(CbacFieldChanged('partA.age', label));
                bloc.add(CbacFieldChanged('partA.age_code', code));
              }
            });
            return CustomTextField(
              hintText: l10n.ageLabelSimple,
              labelText: l10n.ageLabelSimple,
              keyboardType: TextInputType.number,
              initialValue: state.data['personal.age']?.toString() ?? '',
              unitLetterSuffix: (l10n.yearsSuffix.isNotEmpty
                  ? l10n.yearsSuffix[0]
                  : 'Y'),
              onChanged: (v) {
                final val = v.trim();
                bloc.add(CbacFieldChanged('personal.age', val));
                final n = int.tryParse(val);
                if (n != null) {
                  String label;
                  String code;
                  if (n <= 29) {
                    label = '0 to 29 years';
                    code = 'AGE_0_29';
                  } else if (n <= 39) {
                    label = '30 to 39 years';
                    code = 'AGE_30_39';
                  } else if (n <= 49) {
                    label = '40 to 49 years';
                    code = 'AGE_40_49';
                  } else if (n <= 59) {
                    label = '50 to 59 years';
                    code = 'AGE_50_59';
                  } else {
                    label = 'Over 59 years';
                    code = 'AGE_GE60';
                  }
                  bloc.add(CbacFieldChanged('partA.age', label));
                  bloc.add(CbacFieldChanged('partA.age_code', code));
                }
              },
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.gender'] !=
              current.data['personal.gender'],
          builder: (context, state) {
            final genderValue = state.data['personal.gender'] as String? ?? '';
            
            return CustomTextField(
              hintText: l10n.genderLabel,
              labelText: l10n.genderLabel,
              initialValue: genderValue,
              onChanged: (v) {
                bloc.add(CbacFieldChanged('personal.gender', v));
                final currentFather =
                    (state.data['personal.father']?.toString().trim() ?? '');
                if (currentFather.isNotEmpty) {
                  return;
                }
                final fatherName =
                    (state.data['beneficiary.fatherName']
                        ?.toString()
                        .trim() ??
                    '');
                final spouseName =
                    (state.data['beneficiary.spouseName']
                        ?.toString()
                        .trim() ??
                    '');
                if (v.toLowerCase() == 'male' || v.toLowerCase() == 'm') {
                  if (fatherName.isNotEmpty) {
                    bloc.add(CbacFieldChanged('personal.father', fatherName));
                  }
                } else {
                  final pick = spouseName.isNotEmpty
                      ? spouseName
                      : fatherName;
                  if (pick.isNotEmpty) {
                    bloc.add(CbacFieldChanged('personal.father', pick));
                  }
                }
              },
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (p, c) =>
              p.data['personal.address'] != c.data['personal.address'],
          builder: (context, state) {
            return CustomTextField(
              hintText: l10n.addressLabel,
              labelText: l10n.addressLabel,
              initialValue: state.data['personal.address']?.toString() ?? '',
              onChanged: (v) =>
                  bloc.add(CbacFieldChanged('personal.address', v.trim())),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.idType'] !=
              current.data['personal.idType'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.identificationTypeLabel,
              labelText: l10n.identificationTypeLabel,
              items: [l10n.idTypeAadhaar, l10n.idTypeVoterId, l10n.uid],
              value: state.data['personal.idType'],
              getLabel: (s) => s,
              onChanged: (v) {
                bloc.add(CbacFieldChanged('personal.idType', v));
                if ((v ?? '') == l10n.idTypeVoterId) {
                  final s = context.read<CbacFormBloc>().state;
                  final voter = s.data['beneficiary.voterId']?.toString();
                  if (voter != null && voter.isNotEmpty) {
                    bloc.add(CbacFieldChanged('personal.idNumber', voter));
                  }
                }
              },
            );
          },
        ),
        const Divider(height: 0.5),
        // Identification Number (shown only after Identification Type is selected)
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.idType'] !=
                  current.data['personal.idType'] ||
              previous.data['personal.idNumber'] !=
                  current.data['personal.idNumber'],
          builder: (context, state) {
            final idType = (state.data['personal.idType'] ?? '')
                .toString()
                .trim();
            if (idType.isEmpty) {
              // Hide the field entirely until an ID type is chosen
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                CustomTextField(
                  hintText: l10n.identificationNumber,
                  labelText: l10n.identificationNumber,
                  initialValue:
                      state.data['personal.idNumber']?.toString() ?? '',
                  onChanged: (v) =>
                      bloc.add(CbacFieldChanged('personal.idNumber', v.trim())),
                ),
                const Divider(height: 0.5),
              ],
            );
          },
        ),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.hasConditions'] !=
              current.data['personal.hasConditions'],
          builder: (context, state) {
            return ApiDropdown<String>(
              hintText: l10n.idTypeStateInsurance,
              labelText: l10n.idTypeStateInsurance,
              items: [l10n.yes, l10n.no],
              value: state.data['personal.hasConditions'],
              getLabel: (s) => s,
              onChanged: (v) =>
                  bloc.add(CbacFieldChanged('personal.hasConditions', v)),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (p, c) =>
              p.data['personal.mobile'] != c.data['personal.mobile'],
          builder: (context, state) {
            return CustomTextField(
              hintText: l10n.mobileTelephoneLabel,
              labelText: l10n.mobileTelephoneLabel,
              keyboardType: TextInputType.number,
              initialValue: state.data['personal.mobile']?.toString() ?? '',
              onChanged: (v) =>
                  bloc.add(CbacFieldChanged('personal.mobile', v.trim())),
            );
          },
        ),
        const Divider(height: 0.5),
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.disability'] !=
              current.data['personal.disability'],
          builder: (context, state) {
            final selected =
                state.data['personal.disability']?.toString() ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApiDropdown<String>(
                  hintText: l10n.disabilityQuestionLabel,
                  labelText: l10n.disabilityQuestionLabel,
                  items: [
                    l10n.disabilityVisualImpairment,
                    l10n.disabilityPhysicallyHandicap,
                    l10n.disabilityBedridden,
                    l10n.disabilityNeedHelp,
                  ],
                  value: state.data['personal.disability'],
                  getLabel: (s) => s,
                  onChanged: (v) =>
                      bloc.add(CbacFieldChanged('personal.disability', v)),
                ),
                const Divider(height: 0.5),
                if (selected.isNotEmpty) ...[
                  CustomTextField(
                    hintText:
                        'Details (if any selected from above list, give details)',
                    labelText:
                        'Details (if any selected from above list, give details)',
                    initialValue:
                        state.data['personal.disabilityDetails']?.toString() ??
                        '',
                    onChanged: (v) => bloc.add(
                      CbacFieldChanged('personal.disabilityDetails', v.trim()),
                    ),
                  ),
                  const Divider(height: 0.5),
                ],
              ],
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
        final bloc = BlocProvider.of<CbacFormBloc>(context);
        final l10n = AppLocalizations.of(context)!;

        // --- 1. Load Data ---
        final age = state.data['partA.age'] as String?;
        final tobacco = state.data['partA.tobacco'] as String?;
        final alcohol = state.data['partA.alcohol'] as String?;
        final activity = state.data['partA.activity'] as String?;
        final waist = state.data['partA.waist'] as String?;
        final familyHx = state.data['partA.familyHistory'] as String?;

        // --- 2. Auto-calculate Age Logic ---
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if ((age == null || age.isEmpty)) {
            final personalAgeTxt = state.data['personal.age']
                ?.toString()
                .trim();
            final n = int.tryParse(personalAgeTxt ?? '');
            if (n != null) {
              String label;
              String code;
              if (n <= 29) {
                label = '0 to 29 years';
                code = 'AGE_0_29';
              } else if (n <= 39) {
                label = '30 to 39 years';
                code = 'AGE_30_39';
              } else if (n <= 49) {
                label = '40 to 49 years';
                code = 'AGE_40_49';
              } else if (n <= 59) {
                label = '50 to 59 years';
                code = 'AGE_50_59';
              } else {
                label = 'Over 59 years';
                code = 'AGE_GE60';
              }
              bloc.add(CbacFieldChanged('partA.age', label));
              bloc.add(CbacFieldChanged('partA.age_code', code));
            }
          }
        });

        // --- 3. Helper Widget for Rows ---
        TableRow buildQRow({
          required String question,
          required List<String> items,
          required String? value,
          required void Function(String?) onChanged,
          required int? score,
          bool readOnly = false,
        }) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ApiDropdown<String>(
                  labelText: question,
                  hintText: l10n.select,
                  labelFontSize: 15.sp,
                  items: items,
                  getLabel: (s) => s,
                  value: value,
                  onChanged: onChanged,
                  isExpanded: true,
                  readOnly: readOnly,
                ),
              ),
              Center(
                child: Text(
                  score?.toString() ?? '-',
                  style: TextStyle(color: Colors.black87, fontSize: 15.sp),
                ),
              ),
            ],
          );
        }

        // --- 4. Define Lists & Codes ---
        final itemsAge = <String>[
          '0 to 29 ${l10n.years}',
          '30 to 39  ${l10n.years}',
          '40 to 49  ${l10n.years}',
          '50 to 59  ${l10n.years}',
          'Over 59  ${l10n.years}',
        ];
        final itemsTobacco = <String>[
          l10n.cbacA_tobNever,
          l10n.cbacA_tobSometimes,
          l10n.cbacA_tobDaily,
        ];
        // itemsYesNo: [0: No, 1: Yes]
        final itemsYesNo = <String>[l10n.no, l10n.yes];

        final itemsActivity = <String>[
          l10n.cbacA_actLT150,
          l10n.cbacA_actGT150,
        ];

        final genderCode = state.data['personal.gender_code']?.toString();
        final isFemale =
            genderCode == 'F' ||
            state.data['personal.gender'] == l10n.genderFemale;

        final itemsWaist = isFemale
            ? <String>[
                l10n.cbacA_waistLE80,
                l10n.cbacA_waist81to90,
                l10n.cbacA_waistGT90,
              ]
            : <String>['90 cm or less', '91 to 100 cm', 'More than 100 cm'];

        final codeAge = <String>[
          'AGE_0_29',
          'AGE_30_39',
          'AGE_40_49',
          'AGE_50_59',
          'AGE_GE60',
        ];
        final codeTob = <String>['TOB_NEVER', 'TOB_SOMETIMES', 'TOB_DAILY'];
        final codeYesNo = <String>['NO', 'YES'];
        final codeActivity = <String>['ACT_LT150', 'ACT_GE150'];
        final codeWaist = isFemale
            ? <String>['WAIST_LE80', 'WAIST_81_90', 'WAIST_GT90']
            : <String>['WAIST_LE90', 'WAIST_91_100', 'WAIST_GT100'];

        // --- 5. Auto-populate Codes ---
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.data['partA.age_code'] == null && age != null) {
            final idx = itemsAge.indexOf(age);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partA.age_code', codeAge[idx]));
            }
          }
          if (state.data['partA.tobacco_code'] == null && tobacco != null) {
            final idx = itemsTobacco.indexOf(tobacco);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partA.tobacco_code', codeTob[idx]));
            }
          }
          if (state.data['partA.alcohol_code'] == null && alcohol != null) {
            final idx = itemsYesNo.indexOf(alcohol);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partA.alcohol_code', codeYesNo[idx]));
            }
          }
          if (state.data['partA.activity_code'] == null && activity != null) {
            final idx = itemsActivity.indexOf(activity);
            if (idx >= 0) {
              bloc.add(
                CbacFieldChanged('partA.activity_code', codeActivity[idx]),
              );
            }
          }
          if (state.data['partA.waist_code'] == null && waist != null) {
            final idx = itemsWaist.indexOf(waist);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partA.waist_code', codeWaist[idx]));
            }
          }
          if (state.data['partA.familyHistory_code'] == null &&
              familyHx != null) {
            final idx = itemsYesNo.indexOf(familyHx);
            if (idx >= 0) {
              bloc.add(
                CbacFieldChanged('partA.familyHistory_code', codeYesNo[idx]),
              );
            }
          }
        });

        // --- 6. Calculate Scores ---
        final ageCodeVal = state.data['partA.age_code']?.toString();

        final int? scoreAge = ageCodeVal == null
            ? null
            : switch (ageCodeVal) {
                'AGE_30_39' => 1,
                'AGE_40_49' => 2,
                'AGE_50_59' => 3,
                'AGE_50_69' => 3,
                'AGE_GE60' => 4,
                _ => 0,
              };

        final int? scoreTobacco = tobacco == null
            ? null
            : (itemsTobacco.indexOf(tobacco) <= 0
                  ? 0
                  : itemsTobacco.indexOf(tobacco));

        // UPDATED ALCOHOL: Index 1 (Yes) = 1, Index 0 (No) = 0
        final int? scoreAlcohol = alcohol == null
            ? null
            : (itemsYesNo.indexOf(alcohol) == 1 ? 1 : 0);

        final int? scoreActivity = activity == null
            ? null
            : (itemsActivity.indexOf(activity) == 0 ? 1 : 0);

        final int? scoreWaist = waist == null
            ? null
            : switch (itemsWaist.indexOf(waist)) {
                1 => 1,
                2 => 2,
                _ => 0,
              };

        // UPDATED FAMILY HISTORY: Index 1 (Yes) = 2, Index 0 (No) = 0
        final int? scoreFamily = familyHx == null
            ? null
            : (itemsYesNo.indexOf(familyHx) == 1 ? 2 : 0);

        final total =
            (scoreAge ?? 0) +
            (scoreTobacco ?? 0) +
            (scoreAlcohol ?? 0) +
            (scoreActivity ?? 0) +
            (scoreWaist ?? 0) +
            (scoreFamily ?? 0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside: BorderSide(width: 0.5, color: Colors.black12),
              ),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.cbacQuestions,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        l10n.cbacScore,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                buildQRow(
                  question: l10n.cbacA_ageQ,
                  items: itemsAge,
                  value: age,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.age', v));
                    final idx = v == null ? -1 : itemsAge.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partA.age_code', codeAge[idx]),
                      );
                    }
                  },
                  score: scoreAge,
                  readOnly: true,
                ),
                buildQRow(
                  question: l10n.cbacA_tobaccoQ,
                  items: itemsTobacco,
                  value: tobacco,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.tobacco', v));
                    final idx = v == null ? -1 : itemsTobacco.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partA.tobacco_code', codeTob[idx]),
                      );
                    }
                  },
                  score: scoreTobacco,
                ),
                buildQRow(
                  question: l10n.cbacA_alcoholQ,
                  items: itemsYesNo,
                  value: alcohol,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.alcohol', v));
                    final idx = v == null ? -1 : itemsYesNo.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partA.alcohol_code', codeYesNo[idx]),
                      );
                    }
                  },
                  score: scoreAlcohol,
                ),
                buildQRow(
                  question: l10n.cbacA_waistQ,
                  items: itemsWaist,
                  value: waist,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.waist', v));
                    final idx = v == null ? -1 : itemsWaist.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partA.waist_code', codeWaist[idx]),
                      );
                    }
                  },
                  score: scoreWaist,
                ),
                buildQRow(
                  question: l10n.cbacA_activityQ,
                  items: itemsActivity,
                  value: activity,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.activity', v));
                    final idx = v == null ? -1 : itemsActivity.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged(
                          'partA.activity_code',
                          codeActivity[idx],
                        ),
                      );
                    }
                  },
                  score: scoreActivity,
                ),
                buildQRow(
                  question: l10n.cbacA_familyQ,
                  items: itemsYesNo,
                  value: familyHx,
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partA.familyHistory', v));
                    final idx = v == null ? -1 : itemsYesNo.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged(
                          'partA.familyHistory_code',
                          codeYesNo[idx],
                        ),
                      );
                    }
                  },
                  score: scoreFamily,
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.cbacTotalScorePartA(''),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14.sp),
        ),
      ),
    );

    List<Widget> qRow(String question, String keyPath) => [
      Row(
        children: [
          Expanded(
            child: BlocBuilder<CbacFormBloc, CbacFormState>(
              buildWhen: (previous, current) =>
                  previous.data[keyPath] != current.data[keyPath],
              builder: (context, state) {
                return ApiDropdown<String>(
                  labelText: question,
                  hintText: l10n.select,
                  labelFontSize: 15.sp,
                  items: [l10n.no, l10n.yes],
                  getLabel: (s) => s,
                  value: state.data[keyPath],
                  onChanged: (v) => bloc.add(CbacFieldChanged(keyPath, v)),
                  isExpanded: true,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      const Divider(height: 0.5),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        chip(l10n.cbacPartB1),
        ...qRow("${l10n.cbacB_b1_breath}", 'partB.b1.breath'),
        ...qRow("${l10n.cbacB_b1_cough2w} *", 'partB.b1.cough2w'),
        ...qRow("${l10n.cbacB_b1_bloodMucus} *", 'partB.b1.bloodMucus'),
        ...qRow("${l10n.cbacB_b1_fever2w} *", 'partB.b1.fever2w'),
        ...qRow("${l10n.cbacB_b1_weightLoss} *", 'partB.b1.weightLoss'),
        ...qRow("${l10n.cbacB_b1_nightSweat} *", 'partB.b1.nightSweat'),
        ...qRow(l10n.cbacB_b1_seizures, 'partB.b1.seizures'),
        ...qRow(l10n.cbacB_b1_openMouth, 'partB.b1.openMouth'),
        ...qRow(l10n.cbacB_b1_ulcers, 'partB.b1.ulcers'),
        ...qRow(l10n.cbacB_b1_swellingMouth, 'partB.b1.swellingMouth'),
        ...qRow(l10n.cbacB_b1_rashMouth, 'partB.b1.rashMouth'),
        ...qRow(l10n.cbacB_b1_chewPain, 'partB.b1.chewPain'),
        ...qRow("${l10n.cbacB_b1_druggs} **", 'partB.b1.druggs'),
        ...qRow(
          "${l10n.cbacB_b1_tuberculosisFamily} **",
          'partB.b1.Tuberculosis',
        ),
        ...qRow("${l10n.cbacB_b1_history} **", 'partB.b1.history'),
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
        ...qRow(
          l10n.cbacB_b1_closeEyelidsDifficulty,
          'partB.b1.closeEyelidsDifficulty',
        ),
        ...qRow(l10n.cbacB_b1_holdingDifficulty, 'partB.b1.holdingDifficulty'),
        ...qRow(l10n.cbacB_b1_legWeaknessWalk, 'partB.b1.legWeaknessWalk'),

        // Female-specific questions - only show if gender is female
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.gender'] !=
              current.data['personal.gender'],
          builder: (context, state) {
            final isFemale =
                state.data['personal.gender_code'] == 'F' ||
                state.data['personal.gender'] == 'Female';
            if (!isFemale) return const SizedBox.shrink();

            return Column(
              children: [
                chip(l10n.cbacPartB2),
                ...qRow(l10n.cbacB_b2_breastLump, 'partB.b2.breastLump'),
                ...qRow(l10n.cbacB_b2_nippleBleed, 'partB.b2.nippleBleed'),
                ...qRow(
                  l10n.cbacB_b2_breastShapeDiff,
                  'partB.b2.breastShapeDiff',
                ),
                ...qRow(
                  " ${l10n.cbacB_b2_excessBleeding}***",
                  'partB.b2.excessBleeding',
                ),
                ...qRow(
                  "${l10n.cbacB_b2_depression}***",
                  'partB.b2.depression',
                ),
                ...qRow(
                  "${l10n.cbacB_b2_uterusProlapse}***",
                  'partB.b2.uterusProlapse',
                ),
                ...qRow(
                  l10n.cbacB_b2_postMenopauseBleed,
                  'partB.b2.postMenopauseBleed',
                ),
                ...qRow(
                  l10n.cbacB_b2_postIntercourseBleed,
                  'partB.b2.postIntercourseBleed',
                ),
                ...qRow(
                  l10n.cbacB_b2_smellyDischarge,
                  'partB.b2.smellyDischarge',
                ),
                ...qRow(
                  l10n.cbacB_b2_irregularPeriods,
                  'partB.b2.irregularPeriods',
                ),
                ...qRow(l10n.cbacB_b2_jointPain, 'partB.b2.jointPain'),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PartCTab extends StatefulWidget {
  @override
  State<_PartCTab> createState() => _PartCTabState();
}

class _PartCTabState extends State<_PartCTab> {
  Future<void> _showMultiSelectDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Set<String> selected,
    required Function(Set<String>) onSelected,
  }) async {
    final current = Set<String>.from(selected);
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 15.sp,
                ),
              ),
              const SizedBox(height: 6),
              Divider(color: Colors.grey.shade700, thickness: 0.8, height: 0),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  StatefulBuilder(
                    builder: (ctx2, setStateDialog) {
                      final isChecked = current.contains(option);
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Transform.scale(
                          scale: 1.0,
                          child: CheckboxListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -2),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              option,
                              style: TextStyle(fontSize: 15.sp),
                            ),
                            value: isChecked,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  current.add(option);
                                } else {
                                  current.remove(option);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                onSelected(current);
                Navigator.of(ctx).pop();
              },
              child: Text(l10n.ok ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMultiSelectField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    final selected = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final displayText = selected.isEmpty ? l10n!.select : selected.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            await _showMultiSelectDialog(
              context: context,
              title: label,
              options: options,
              selected: selected,
              onSelected: (newSelection) {
                final joined = newSelection.join(', ');
                onChanged(joined);
              },
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: selected.isEmpty
                        ? Colors.grey.shade700
                        : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
        const Divider(
          // Added divider here
          height: 1,
          thickness: 0.5,
          color: Colors.grey, // You can adjust the color as needed
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

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
              ),
            ],
          ),
          child: Center(child: Text(l10n.cbacHeaderLungRisk)),
        ),
        const SizedBox(height: 16),

        // Cooking fuel multi-select
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['partC.cookingFuel'] !=
              current.data['partC.cookingFuel'],
          builder: (context, state) {
            final allOptions = [
              l10n.firewod,
              l10n.cropResidues,
              l10n.cowdung,
              l10n.coal,
              l10n.cbacC_fuelKerosene,
              l10n.lpg,

            ];

            return _buildMultiSelectField(
              context: context,
              label: l10n.cbacC_fuelQ,
              value: state.data['partC.cookingFuel']?.toString() ?? '',
              options: allOptions,
              onChanged: (value) {
                bloc.add(CbacFieldChanged('partC.cookingFuel', value));
              },
            );
          },
        ),

        const SizedBox(height: 16),

        // Business/occupation risk multi-select
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['partC.businessRisk'] !=
              current.data['partC.businessRisk'],
          builder: (context, state) {
            final allOptions = [
              l10n.burningCrop,
              l10n.burningOfGrabage,
              l10n.cbacC_workingSmokeyFactory,
              l10n.cbacC_workingPollutedIndustries,



              // l10n.cbacC_workingMines,
              // l10n.cbacC_workingConstruction,
              // l10n.cbacC_workingBrickKilns,
              // l10n.cbacC_workingStoneQuarries,
              // l10n.cbacC_workingCementIndustries,
              // l10n.cbacC_workingCottonIndustries,
              // l10n.cbacC_workingChemicalIndustries,
              // l10n.cbacC_workingTextileIndustries,
              // l10n.cbacC_workingOtherIndustries,
            ];

            return _buildMultiSelectField(
              context: context,
              label: l10n.cbacC_businessRiskQ,
              value: state.data['partC.businessRisk']?.toString() ?? '',
              options: allOptions,
              onChanged: (value) {
                bloc.add(CbacFieldChanged('partC.businessRisk', value));
              },
            );
          },
        ),
      ],
    );
  }
}

class _PartDTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CbacFormBloc, CbacFormState>(
      builder: (context, state) {
        final bloc = BlocProvider.of<CbacFormBloc>(context);
        final q1 = state.data['partD.q1'] as String?;
        final q2 = state.data['partD.q2'] as String?;

        final l10n = AppLocalizations.of(context)!;
        final options = [
          l10n.cbacD_opt0,
          l10n.cbacD_opt1,
          l10n.cbacD_opt2,
          l10n.cbacD_opt3,
        ];
        final codeOptions = ['D_OPT0', 'D_OPT1', 'D_OPT2', 'D_OPT3'];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (state.data['partD.q1_code'] == null && q1 != null) {
            final idx = options.indexOf(q1);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partD.q1_code', codeOptions[idx]));
            }
          }
          if (state.data['partD.q2_code'] == null && q2 != null) {
            final idx = options.indexOf(q2);
            if (idx >= 0) {
              bloc.add(CbacFieldChanged('partD.q2_code', codeOptions[idx]));
            }
          }
        });

        // --- 1. Scoring Logic Changed to return int? (nullable) ---
        int? getScore(String? v) {
          if (v == null) return null; // Returns null so UI shows '-'
          final idx = options.indexOf(v);
          return idx < 0 ? null : idx;
        }

        final scoreQ1 = getScore(q1);
        final scoreQ2 = getScore(q2);

        // Calculate total (treating nulls as 0 for the sum)
        final total = (scoreQ1 ?? 0) + (scoreQ2 ?? 0);

        int computePartAScore() {
          final ageCode = state.data['partA.age_code'] as String?;
          final tobCode = state.data['partA.tobacco_code'] as String?;
          final alcoholCode = state.data['partA.alcohol_code'] as String?;
          final activityCode = state.data['partA.activity_code'] as String?;
          final waistCode = state.data['partA.waist_code'] as String?;
          final familyCode = state.data['partA.familyHistory_code'] as String?;

          int scoreAge;
          if (ageCode != null) {
            switch (ageCode) {
              case 'AGE_30_39':
                scoreAge = 1;
                break;
              case 'AGE_40_49':
                scoreAge = 2;
                break;
              case 'AGE_50_69':
              case 'AGE_50_59':
              case 'AGE_GE60':
                scoreAge = 3;
                break;
              default:
                scoreAge = 0;
            }
          } else {
            final a = state.data['partA.age'] as String?;
            if (a != null) {
              final itemsAgeNew = [
                '0 to 29 years',
                '30 to 39 years',
                '40 to 49 years',
                '50 to 59 years',
                'Over 59 years',
              ];
              final idxNew = itemsAgeNew.indexOf(a);
              if (idxNew == 1) {
                scoreAge = 1;
              } else if (idxNew == 2) {
                scoreAge = 2;
              } else if (idxNew == 3 || idxNew == 4) {
                scoreAge = 3;
              } else {
                final itemsAgeLegacy = [
                  'Less than 30 years',
                  '30-39 years',
                  '40-49 years',
                  '50-69 years',
                ];
                final idxLegacy = itemsAgeLegacy.indexOf(a);
                scoreAge = switch (idxLegacy) {
                  1 => 1,
                  2 => 2,
                  3 => 3,
                  _ => 0,
                };
              }
            } else {
              scoreAge = 0;
            }
          }

          final scoreTobacco = tobCode != null
              ? (tobCode == 'TOB_NEVER' ? 0 : 1)
              : (() {
            final v = state.data['partA.tobacco'] as String?;
            final itemsTobacco = ['Never consumed', 'Sometimes', 'Daily'];
            final idx = v == null ? -1 : itemsTobacco.indexOf(v);
            return idx <= 0 ? 0 : 1;
          })();

          final scoreAlcohol = alcoholCode != null
              ? (alcoholCode == 'YES' ? 1 : 0)
              : (() {
            final v = state.data['partA.alcohol'] as String?;
            final isYes = v != null && v.toLowerCase() == 'yes';
            return isYes ? 1 : 0;
          })();

          final scoreActivity = activityCode != null
              ? (activityCode == 'ACT_LT150' ? 1 : 0)
              : (() {
            final v = state.data['partA.activity'] as String?;
            final itemsActivity = [
              'Less than 150 minutes per week',
              '150 minutes or more per week',
            ];
            final idx = v == null ? -1 : itemsActivity.indexOf(v);
            return idx == 0 ? 1 : 0;
          })();

          int scoreWaist;
          if (waistCode != null) {
            switch (waistCode) {
              case 'WAIST_81_90':
                scoreWaist = 1;
                break;
              case 'WAIST_GT90':
                scoreWaist = 2;
                break;
              case 'WAIST_91_100':
                scoreWaist = 1;
                break;
              case 'WAIST_GT100':
                scoreWaist = 2;
                break;
              default:
                scoreWaist = 0;
            }
          } else {
            final genderCode = state.data['personal.gender_code']?.toString();
            final v = state.data['partA.waist'] as String?;
            int idx = -1;
            if (genderCode == 'M') {
              final itemsWaistMale = [
                '90 cm or less',
                '91 to 100 cm',
                'More than 100 cm',
              ];
              idx = v == null ? -1 : itemsWaistMale.indexOf(v);
            } else {
              final itemsWaistFemale = ['≤ 80 cm', '81-90 cm', '> 90 cm'];
              idx = v == null ? -1 : itemsWaistFemale.indexOf(v);
            }
            scoreWaist = switch (idx) {
              1 => 1,
              2 => 2,
              _ => 0,
            };
          }

          final scoreFamily = familyCode != null
              ? (familyCode == 'YES' ? 2 : 0)
              : (() {
            final v = state.data['partA.familyHistory'] as String?;
            final isYes = v != null && v.toLowerCase() == 'yes';
            return isYes ? 2 : 0;
          })();

          return scoreAge +
              scoreTobacco +
              scoreAlcohol +
              scoreActivity +
              scoreWaist +
              scoreFamily;
        }

        final partAScore = computePartAScore();

        // --- 2. Update Helper Widget to accept Score ---
        TableRow buildRow({
          required String question,
          required String? value,
          required void Function(String?) onChanged,
          required int? score, // Added score parameter
        }) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ApiDropdown<String>(
                  labelText: question,
                  hintText: l10n.select,
                  labelFontSize: 15.sp,
                  items: options,
                  getLabel: (s) => s,
                  value: value,
                  onChanged: onChanged,
                  isExpanded: true,
                ),
              ),
              Center(
                child: Text(
                  // --- 3. Display '-' if score is null ---
                  score?.toString() ?? '-',
                  style: TextStyle(color: Colors.black87, fontSize: 15.sp),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside: BorderSide(width: 0.5, color: Colors.black12),
              ),
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.cbacQuestions,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        l10n.cbacScore,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                buildRow(
                  question: l10n.cbacD_q1,
                  value: q1,
                  score: scoreQ1, // Pass computed score
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partD.q1', v));
                    final idx = v == null ? -1 : options.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partD.q1_code', codeOptions[idx]),
                      );
                    }
                  },
                ),
                buildRow(
                  question: l10n.cbacD_q2,
                  value: q2,
                  score: scoreQ2, // Pass computed score
                  onChanged: (v) {
                    bloc.add(CbacFieldChanged('partD.q2', v));
                    final idx = v == null ? -1 : options.indexOf(v);
                    if (idx >= 0) {
                      bloc.add(
                        CbacFieldChanged('partD.q2_code', codeOptions[idx]),
                      );
                    }
                  },
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.cbacTotalScorePartD(''),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (partAScore >= 4 || (partAScore + total) >= 4) ...[
              const SizedBox(height: 8),
              Text(
                'Suspected NCD case, please visit the nearest HWC or call 104',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                  fontSize: 17.sp,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
