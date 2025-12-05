import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'bloc/cbac_form_bloc.dart';

class Cbacform extends StatefulWidget {
  final String? beneficiaryId;
  final String? hhid;

  const Cbacform({
    super.key,
    this.beneficiaryId,
    this.hhid,
  });

  @override
  State<Cbacform> createState() => _CbacformState();
}

class _CbacformState extends State<Cbacform> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final beneficiaryId = widget.beneficiaryId ?? args?['beneficiaryId']?.toString();
    final hhid = widget.hhid ?? args?['hhid']?.toString();

    print('🚀 Initializing CBAC Form with - beneficiaryId: $beneficiaryId, hhid: $hhid');
    
    return BlocProvider(
      create: (_) => CbacFormBloc(
        beneficiaryId: beneficiaryId,
        householdId: hhid,
      )..add(CbacOpened(
        beneficiaryId: beneficiaryId,
        hhid: hhid,
      )),
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
                p.missingKeys != c.missingKeys ||
                p.isSuccess != c.isSuccess,
            listener: (context, state) async {
              final l10n = AppLocalizations.of(context);
              
              // Handle form submission success
              if (state.isSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text( 'Form saved successfully'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                
                Future.delayed(const Duration(milliseconds: 500), () {
                  Navigator.of(context).pop();
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
                    title: Text(l10n?.cbacConsentTitle ?? 'Consent Form', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),),
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

                // Show only the first missing field label in SnackBar
                final firstKey = state.missingKeys.first;
                final firstLabel = labelForKey(firstKey);
                final msg = '${l10n.cbacPleaseFill}: $firstLabel';
                showAppSnackBar(context, msg);

              } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 👇 Keep layout stable — use SizedBox(width: 120) when hidden
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
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    onPressed: () =>
                                        context.read<CbacFormBloc>().add(const CbacPrevTab()),
                                    child: Text(
                                      l10n?.previousButton ?? 'PREVIOUS',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 120),

                            SizedBox(
                              height: 34,
                              child: RoundButton(
                                title: state.activeTab == tabs.length - 1
                                    ? (l10n?.saveButton ?? 'SAVE')
                                    : (l10n?.nextButton ?? 'NEXT'),
                                width: 120,
                                borderRadius: 4,
                                isLoading: state.submitting,
                                onPress: () {
                                  if (state.activeTab == tabs.length - 1) {
                                    context.read<CbacFormBloc>().add(const CbacSubmitted());
                                  } else {
                                    context.read<CbacFormBloc>().add(const CbacNextTab());
                                  }
                                },
                              ),
                            ),
                          ],
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
              userDetails = jsonDecode(user['details'] as String) as Map<String, dynamic>;
            } catch (e) {
              debugPrint('❌ Error parsing user details as JSON: $e');
              // Try alternative parsing method if JSON parsing fails
              _tryAlternativeParsing(user['details']!.toString());
              return;
            }
          }
        }

        // Extract values from the provided JSON structure
        final name = userDetails['name'] is Map ? userDetails['name'] as Map<String, dynamic> : {};
        final workingLocation = userDetails['working_location'] is Map 
            ? userDetails['working_location'] as Map<String, dynamic> 
            : {};

        // Extract name components
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
        final block = workingLocation['block']?.toString()?.trim() ?? '';

        debugPrint('🎯 EXTRACTED VALUES FROM USER DETAILS:');
        debugPrint('   First Name: "$firstName"');
        if (middleName.isNotEmpty) debugPrint('   Middle Name: "$middleName"');
        debugPrint('   Last Name: "$lastName"');
        debugPrint('   Full Name: "$fullName"');
        debugPrint('   HSC Name: "$hscName"');
        debugPrint('   District: "$district"');
        debugPrint('   Block: "$block"');

        // Use the actual name from details or fallback to username
        final finalAshaName = fullName.isNotEmpty ? fullName : user['user_name']?.toString()?.trim() ?? '';
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

  // Alternative parsing method using string manipulation
  void _tryAlternativeParsing(String detailsString) {
    try {
      debugPrint('🔄 Trying alternative parsing...');

      // Extract first_name using regex
      final firstNameMatch = RegExp(r'first_name:\s*([^,]+)').firstMatch(detailsString);
      final lastNameMatch = RegExp(r'last_name:\s*([^,]+)').firstMatch(detailsString);
      final hscNameMatch = RegExp(r'hsc_name:\s*([^,]+)').firstMatch(detailsString);
      final districtMatch = RegExp(r'district:\s*([^,]+)').firstMatch(detailsString);
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

  // Method to update bloc with form fields
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateFormFields(context);
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          children: [
            // ASHA Name Field - Should show "Sita Kumari"
            CustomTextField(
              key: ValueKey('ashaName_${_ashaName}'),
              hintText: l10n.ashaNameLabel,
              labelText: l10n.ashaNameLabel,
              initialValue: _ashaName,
              readOnly: _ashaName.isNotEmpty,
              onChanged: (v) {
                context.read<CbacFormBloc>().add(CbacFieldChanged('general.ashaName', v.trim()));
              },
            ),
            const Divider(height: 0.5),

            // ANM Name Field
            CustomTextField(
              hintText: l10n.anmNameLabel,
              labelText: l10n.anmNameLabel,
              initialValue: state.data['general.anmName']?.toString() ?? '',
              onChanged: (v) => context.read<CbacFormBloc>().add(CbacFieldChanged('general.anmName', v.trim())),
            ),
            const Divider(height: 0.5),

            // PHC/District Field - Should show "Muzaffarpur"
            CustomTextField(
              key: ValueKey('phc_${_district}'),
              hintText: l10n.phcNameLabel,
              labelText: l10n.phcNameLabel,
              initialValue: _district,
              onChanged: (v) => context.read<CbacFormBloc>().add(CbacFieldChanged('general.phc', v.trim())),
            ),
            const Divider(height: 0.5),

            // Village/Block Field - Should show "Bandra"
            CustomTextField(
              key: ValueKey('village_${_block}'),
              hintText: l10n.villageLabel,
              labelText: l10n.villageLabel,
              initialValue: _block,
              onChanged: (v) => context.read<CbacFormBloc>().add(CbacFieldChanged('general.village', v.trim())),
            ),
            const Divider(height: 0.5),

            // HSC Name Field - Should show "HSC Bandra"
            CustomTextField(
              key: ValueKey('hsc_${_hscName}'),
              hintText: l10n.hscNameLabel,
              labelText: l10n.hscNameLabel,
              initialValue: _hscName,
              readOnly: _hscName.isNotEmpty,
              onChanged: (v) => context.read<CbacFormBloc>().add(CbacFieldChanged('general.hsc', v.trim())),
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
        // Identification Number (shown only after Identification Type is selected)
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
              previous.data['personal.idType'] != current.data['personal.idType'] ||
              previous.data['personal.idNumber'] != current.data['personal.idNumber'],
          builder: (context, state) {
            final idType = (state.data['personal.idType'] ?? '').toString().trim();
            if (idType.isEmpty) {
              // Hide the field entirely until an ID type is chosen
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                CustomTextField(
                  hintText: 'Identification Number',
                  labelText: 'Identification Number',
                  initialValue: state.data['personal.idNumber']?.toString() ?? '',
                  onChanged: (v) =>
                      bloc.add(CbacFieldChanged('personal.idNumber', v.trim())),
                ),
                const Divider(height: 0.5),
              ],
            );
          },
        ),
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
        final bloc = BlocProvider.of<CbacFormBloc>(context);

        final age = state.data['partA.age'] as String?;
        final tobacco = state.data['partA.tobacco'] as String?;
        final alcohol = state.data['partA.alcohol'] as String?;
        final activity = state.data['partA.activity'] as String?;
        final waist = state.data['partA.waist'] as String?;
        final familyHx = state.data['partA.familyHistory'] as String?;
        final l10n = AppLocalizations.of(context)!;

        Widget header() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cbacQuestions, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                Text(l10n.cbacScore, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              ],
            );
        Widget rowScore(int score) => SizedBox(
              // width: 20,
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
                  SizedBox(
                    width: 325,
                    child: ApiDropdown<String>(
                      labelText: question,
                      hintText: 'Select Option',
                      labelFontSize: 13.sp,
                      items: items,
                      getLabel: (s) => s,
                      value: value,
                      onChanged: onChanged,
                      isExpanded: true,
                    ),
                  ),

                  rowScore(score),
                ],
              ),
              // const SizedBox(height: 6),
              const Divider(height: 0.5),
            ],
          );
        }

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

            qRow(
              question: l10n.cbacA_tobaccoQ,
              items: itemsTobacco,
              value: tobacco,
              onChanged: (v) => bloc.add(CbacFieldChanged('partA.tobacco', v)),
              score: scoreTobacco,
            ),
 
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
              style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
            ),
          ),
        );

    List<Widget> qRow(String question, String keyPath) => [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 305,
                child: BlocBuilder<CbacFormBloc, CbacFormState>(
                  buildWhen: (previous, current) => previous.data[keyPath] != current.data[keyPath],
                  builder: (context, state) {
                    return ApiDropdown<String>(
                      labelText: question,
                      hintText: 'Select Option',
                      labelFontSize: 13.sp,
                      items: [l10n.yes, l10n.no],
                      getLabel: (s) => s,
                      value: state.data[keyPath],
                      onChanged: (v) => bloc.add(CbacFieldChanged(keyPath, v)),
                      isExpanded: true,
                    );
                  },
                ),
              ),
              const Spacer(),
              const SizedBox(width: 28), // Placeholder for score to maintain alignment
            ],
          ),
          // const SizedBox(height: 4),
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
        ...qRow(l10n.cbacB_b1_chewPain, ' partB.b1.chewPain'),
        ...qRow("${l10n.cbacB_b1_druggs} **", 'partB.b1.druggs'),
        ...qRow("${l10n.cbacB_b1_tuberculosisFamily} **", 'partB.b1.Tuberculosis'),
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
        ...qRow(l10n.cbacB_b1_closeEyelidsDifficulty, 'partB.b1.closeEyelidsDifficulty'),
        ...qRow(l10n.cbacB_b1_holdingDifficulty, 'partB.b1.holdingDifficulty'),
        ...qRow(l10n.cbacB_b1_legWeaknessWalk, 'partB.b1.legWeaknessWalk'),

        // Female-specific questions - only show if gender is female
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) => previous.data['personal.gender'] != current.data['personal.gender'],
          builder: (context, state) {
            final isFemale = state.data['personal.gender'] == l10n.genderFemale;
            if (!isFemale) return const SizedBox.shrink();
            
            return Column(
              children: [
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

// In CBACForm.dart, replace the existing _PartCTabState class with this:

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:  TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
              const SizedBox(height: 6),
              Divider(
                color: Colors.grey.shade700,
                thickness: 0.8,
                height: 0,
              ),
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
                            visualDensity: const VisualDensity(
                              vertical: -2,
                            ),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              option,
                              style:  TextStyle(fontSize: 15.sp),
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
    final selected = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final displayText = selected.isEmpty ? 'Select Option' : selected.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
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
                    color: selected.isEmpty ? Colors.grey.shade700 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        const Divider(  // Added divider here
          height: 1,
          thickness: 0.5,
          color: Colors.grey,  // You can adjust the color as needed
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
              )
            ],
          ),
          child: Center(
            child: Text(
              l10n.cbacHeaderLungRisk,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cooking fuel multi-select
        BlocBuilder<CbacFormBloc, CbacFormState>(
          buildWhen: (previous, current) =>
          previous.data['partC.cookingFuel'] != current.data['partC.cookingFuel'],
          builder: (context, state) {
            final allOptions = [
              l10n.firewod,
              l10n.cropResidues,
              l10n.cowdung,
              l10n.coal,
              l10n.lpg,
              l10n.cbacC_fuelKerosene,
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
          previous.data['partC.businessRisk'] != current.data['partC.businessRisk'],
          builder: (context, state) {
            final allOptions = [
              l10n.cbacC_workingPollutedIndustries,
              l10n.burningOfGrabage,
              l10n.burningCrop,
              l10n.cbacC_workingSmokeyFactory,
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

        int scoreFromValue(String? v) {
          if (v == null) return 0;
          final idx = options.indexOf(v);
          return idx < 0 ? 0 : idx;
        }

        final total = scoreFromValue(q1) + scoreFromValue(q2);

        Widget header() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.cbacQuestions, style:  TextStyle(fontWeight: FontWeight.w600,fontSize: 15.sp)),
                Text(l10n.cbacScore, style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
              ],
            );

        Widget scoreBox(String? v) => SizedBox(
              width: 28,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(v == null ? '-' : '${scoreFromValue(v)}', style:  TextStyle(color: Colors.black54, fontSize: 14.sp)),
              ),
            );

        Widget row({required String question, required String? value, required void Function(String?) onChanged}) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: ApiDropdown<String>(
                      labelText: question,
                      hintText: 'Select Option',
                      labelFontSize: 13.sp,
                      items: options,
                      getLabel: (s) => s,
                      value: value,
                      onChanged: onChanged,
                      isExpanded: true,
                    ),
                  ),
                  const Spacer(),
                  scoreBox(value),
                ],
              ),
              // const SizedBox(height: 6),
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
