  import 'dart:convert';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
  import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
  import 'package:medixcel_new/core/config/themes/CustomColors.dart';
  import 'package:medixcel_new/data/Database/User_Info.dart';
  import '../../core/config/routes/Route_Name.dart';
  import '../../core/widgets/Dropdown/Dropdown.dart';
  import '../../core/widgets/Dropdown/dropdown.dart' hide ApiDropdown;
  import '../../data/SecureStorage/SecureStorage.dart';
  import '../../l10n/app_localizations.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'bloc/profile_bloc.dart';
  import '../../core/widgets/DatePicker/DatePicker.dart';
  import '../../core/widgets/RoundButton/RoundButton.dart';

  class ProfileScreen extends StatefulWidget {
    final bool fromLogin;

    const ProfileScreen({
      super.key,
      this.fromLogin = false,
    });

    @override
    State<ProfileScreen> createState() => _ProfileScreenState();
  }

  String _toTitleCase(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _toCamelCase(String? text) {
    if (text == null || text.isEmpty) return '';
    final words = text.toLowerCase().split(RegExp(r'[\s_]+'));
    if (words.isEmpty) return '';
    return words.first + words.skip(1).map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join('');
  }

  class _ProfileScreenState extends State<ProfileScreen> {
    List<Country> countries = [
      Country(id: 1, name: 'Rural'),
      Country(id: 2, name: 'Urban'),
    ];
    Country? selectedCountry;
    String _userFullName = '';
    Map<String, dynamic> details = {};
    late final ProfileBloc _profileBloc;

    Map<String, dynamic> _getActualUserData() {
      return details;
    }



    DateTime? _parseDob(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return DateTime.tryParse(dateString);
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }


    String _calculateAge(DateTime? dob) {
      if (dob == null) return '';

      final now = DateTime.now();


      int years = now.year - dob.year;
      int months = now.month - dob.month;
      int days = now.day - dob.day;

      // Handle negative days/months
      if (days < 0) {
        final lastMonth = DateTime(now.year, now.month - 1, dob.day);
        days = now.difference(lastMonth).inDays + 1;
        months--;
      }

      if (months < 0) {
        months += 12;
        years--;
      }

      // Build the age string
      final parts = <String>[];
      if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
      if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');
      if (days > 0 || parts.isEmpty) parts.add('$days ${days == 1 ? 'day' : 'days'}');

      return parts.join(', ');
    }

    @override
    void initState() {
      super.initState();
      _profileBloc = context.read<ProfileBloc>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUserData();
      });
    }

    Future<void> _loadUserData() async {
      try {

        await UserInfo.printUserData();
        print('=== END USERS TABLE ===\n');

        final userData = await UserInfo.getCurrentUser();

        if (userData == null || userData.isEmpty) {
          return;
        }

        if (!mounted) {
          return;
        }

        if (!mounted) return;
        final bloc = context.read<ProfileBloc>();

        final username = userData['user_name']?.toString() ?? '';

        // Safely parse details
        try {
          details = userData['details'] is String
              ? jsonDecode(userData['details'] as String)
              : userData['details'] as Map<String, dynamic>? ?? {};
        } catch (e) {
          print('Error parsing user details: $e');
          return;
        }

        Map<String, dynamic> actualUserData = details;

        final name = actualUserData['name'] is Map ? Map<String, dynamic>.from(actualUserData['name']) : <String, dynamic>{};
        final workingLocation = actualUserData['working_location'] is Map
            ? Map<String, dynamic>.from(actualUserData['working_location'])
            : <String, dynamic>{};
        final contactInfo = actualUserData['contact_info'] is Map
            ? Map<String, dynamic>.from(actualUserData['contact_info'])
            : <String, dynamic>{};

        final areaOfWorking = _toCamelCase(actualUserData['area_of_working']?.toString().trim() ?? '');

        if (mounted) {
          setState(() {
            if (areaOfWorking.isNotEmpty) {
              try {
                selectedCountry = countries.firstWhere(
                  (c) => c.name.toLowerCase() == areaOfWorking,
                  orElse: () => countries.first
                );
              } catch (e) {
                selectedCountry = countries.isNotEmpty ? countries.first : null;
              }
            } else {
              selectedCountry = countries.isNotEmpty ? countries.first : null;
            }
          });
        }


        _userFullName = '${name['first_name'] ?? ''} ${name['middle_name'] ?? ''} ${name['last_name'] ?? ''}'.trim();

        try {

          final ashaId = workingLocation['asha_id']?.toString() ?? '';
           final firstName = name['first_name']?.toString().trim() ?? '';
          final middleName = name['middle_name']?.toString().trim() ?? '';
          final lastName = name['last_name']?.toString().trim() ?? '';

          final fullName = [firstName, middleName, lastName]
              .where((part) => part.isNotEmpty)
              .join(' ');

          bloc.add(AshaNameChanged(fullName));

          final fatherSpouse = actualUserData['father_or_spouse_name']?.toString() ?? '';


          final mobileNumber = contactInfo['mobile_number']?.toString() ?? '';
          final altMobileNumber = contactInfo['alternate_mobile_number']?.toString() ?? '';


          final state = _toCamelCase(workingLocation['state']?.toString().trim() ?? '');
          final division = _toCamelCase(workingLocation['division']?.toString().trim() ?? '');
          final district = _toCamelCase(workingLocation['district']?.toString().trim() ?? '');
          final block = _toCamelCase(workingLocation['block']?.toString().trim() ?? '');
          final panchayat = _toCamelCase(workingLocation['panchayat']?.toString().trim() ?? '');
          final village = _toCamelCase(workingLocation['village']?.toString().trim() ?? '');
          final tola = _toCamelCase(workingLocation['tola']?.toString().trim() ?? '');

          final hscName = workingLocation['hsc_name']?.toString() ?? '';
          final hscHfrId = workingLocation['hsc_hfr_id']?.toString() ?? '';

          // Bank Details
          final bankDetails = actualUserData['bank_account_details'] is Map
              ? Map<String, dynamic>.from(actualUserData['bank_account_details'])
              : <String, dynamic>{};
          final accountNumber = bankDetails['bank_account_number']?.toString() ?? '';
          final ifscCode = bankDetails['ifsc_code']?.toString() ?? '';

          // Other fields
          final populationCovered = actualUserData['population_covered_by_asha']?.toString() ?? '';
          final qualification = actualUserData['qualification']?.toString() ?? '';

          // Verification details
          final verificationDetails = actualUserData['verification_details'] is Map
              ? Map<String, dynamic>.from(actualUserData['verification_details'])
              : <String, dynamic>{};
          final aadharNumber = verificationDetails['aadhar_number']?.toString() ?? '';
          final panCardNumber = verificationDetails['pan_card_number']?.toString() ?? '';
          final voterId = verificationDetails['voter_id']?.toString() ?? '';

          // Additional fields from stored data
          final aadharBirthYear = actualUserData['aadhar_birth_year']?.toString() ?? '';
          final aadharName = actualUserData['aadhar_name']?.toString() ?? '';
          final uniqueKey = actualUserData['unique_key']?.toString() ?? '';

          // Extract additional contact/staff information if available
          final choName = workingLocation['cho_name']?.toString() ?? '';
          final choMobile = workingLocation['cho_mobile']?.toString() ?? '';
          final awwName = workingLocation['aww_name']?.toString() ?? '';
          final awwMobile = workingLocation['aww_mobile']?.toString() ?? '';
          final anganwadiCenterNo = workingLocation['anganwadi_center_no']?.toString() ?? '';
          final anm1Name = workingLocation['anm1_name']?.toString() ?? '';
          final anm1Mobile = workingLocation['anm1_mobile']?.toString() ?? '';
          final anm2Name = workingLocation['anm2_name']?.toString() ?? '';
          final anm2Mobile = workingLocation['anm2_mobile']?.toString() ?? '';
          final bcmName = workingLocation['bcm_name']?.toString() ?? '';
          final bcmMobile = workingLocation['bcm_mobile']?.toString() ?? '';
          final dcmName = workingLocation['dcm_name']?.toString() ?? '';
          final dcmMobile = workingLocation['dcm_mobile']?.toString() ?? '';


          // Update form fields using individual events
          if (mounted) {
            // Update basic information
            _profileBloc.add(AshaIdChanged(username));
            _profileBloc.add(AshaNameChanged(fullName));
            _profileBloc.add(FatherSpouseChanged(fatherSpouse));
            _profileBloc.add(MobileChanged(mobileNumber));
            _profileBloc.add(AltMobileChanged(altMobileNumber));

            // Update location information
            _profileBloc.add(StateChanged(state));
            _profileBloc.add(DivisionChanged(division));
            _profileBloc.add(DistrictChanged(district));
            _profileBloc.add(BlockChanged(block));
            _profileBloc.add(PanchayatChanged(panchayat));
            _profileBloc.add(VillageChanged(village));
            _profileBloc.add(TolaChanged(tola));

            // Update other fields
            _profileBloc.add(HscNameChanged(hscName));
            _profileBloc.add(AccountNumberChanged(accountNumber));
            _profileBloc.add(IfscChanged(ifscCode));
            _profileBloc.add(PopulationCoveredChanged(populationCovered));

            // Update area of working dropdown
            if (areaOfWorking.isNotEmpty) {
              _profileBloc.add(AreaOfWorkingChanged(areaOfWorking));
            }

            // Update additional staff/contact information
            _profileBloc.add(ChoNameChanged(choName));
            _profileBloc.add(ChoMobileChanged(choMobile));
            _profileBloc.add(AwwNameChanged(awwName));
            _profileBloc.add(AwwMobileChanged(awwMobile));
            _profileBloc.add(AnganwadiCenterNoChanged(anganwadiCenterNo));
            _profileBloc.add(Anm1NameChanged(anm1Name));
            _profileBloc.add(Anm1MobileChanged(anm1Mobile));
            _profileBloc.add(Anm2NameChanged(anm2Name));
            _profileBloc.add(Anm2MobileChanged(anm2Mobile));
            _profileBloc.add(BcmNameChanged(bcmName));
            _profileBloc.add(BcmMobileChanged(bcmMobile));
            _profileBloc.add(DcmNameChanged(dcmName));
            _profileBloc.add(DcmMobileChanged(dcmMobile));
          }

          // Handle dates
          if (actualUserData['date_of_birth'] != null) {
            try {
              final dob = DateTime.tryParse(actualUserData['date_of_birth'].toString());
              if (dob != null) {
                bloc.add(DobChanged(dob));
              }
            } catch (e) {
            }
          }

          if (actualUserData['date_of_joining'] != null) {
            try {
              final doj = DateTime.tryParse(actualUserData['date_of_joining'].toString());
              if (doj != null) {
                bloc.add(DojChanged(doj));
              }
            } catch (e) {

            }
          }

        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating form: ${e.toString()}')),
            );
          }
        }
       } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text('Failed to load profile data: ${e.toString()}')),
           );
         }
       }

    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final loginFlag =  SecureStorageService.getLoginFlag();

      return WillPopScope(
        onWillPop: () async {
          if (widget.fromLogin) {

            Navigator.of(context).pushReplacementNamed(Route_Names.homeScreen);
            return false;
          }

          return true;
        },
        child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppHeader(
              screenTitle: l10n.ashaProfile,
              showBack: true,
              onBackTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Route_Names.homeScreen,
                  (route) => false,
                );
              },
            ),
          body: SafeArea(
            child: BlocConsumer<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.profileUpdated)),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Route_Names.homeScreen,
                        (Route<dynamic> route) => false,
                  );
                }
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                }
              },
              builder: (context, state) {
                final bloc = context.read<ProfileBloc>();
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.areaOfWorking != current.areaOfWorking,
                        builder: (context, state) {
                          String displayValue = '';
                          if (state.areaOfWorking?.toLowerCase() == 'urban' || state.areaOfWorking?.toLowerCase() == 'rural') {
                            displayValue = state.areaOfWorking![0].toUpperCase() + state.areaOfWorking!.substring(1).toLowerCase();
                          } else {
                            displayValue = _toCamelCase(state.areaOfWorking);
                          }
                          return CustomTextField(
                            labelText: l10n.areaOfWorking, 
                            hintText: l10n.selectArea, 
                            initialValue: displayValue, 
                            readOnly: true
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.ashaId != current.ashaId,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('asha_id_field_${state.ashaId}'),
                            labelText: l10n.ashaIdLabel,
                            hintText: l10n.ashaIdHint,
                            initialValue: state.ashaId != null ? _toTitleCase(state.ashaId!.trim()) : '',
                            onChanged: (v) => bloc.add(AshaIdChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      Builder(
                        builder: (context) {
                          return CustomTextField(
                            key: ValueKey('asha_name_field_$_userFullName'),
                            labelText: l10n.ashaNameLabel,
                            hintText: l10n.ashaNameHint,
                            initialValue: state.ashaName != null ? _toTitleCase(state.ashaName!.trim()) : '',
                            onChanged: (v) {
                              _userFullName = v;
                              bloc.add(AshaNameChanged(v));
                            },
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      const SizedBox(height: 4),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.dob != current.dob,
                        builder: (context, state) {

                          final actualUserData = _getActualUserData();
                          final displayDob = state.dob ?? _parseDob(actualUserData['date_of_birth']?.toString());

                          return CustomDatePicker(
                            key: ValueKey('dob_field_${displayDob?.toIso8601String()}'),
                            labelText: l10n.dobLabel,
                            initialDate: displayDob,
                            isEditable: true,
                            hintText: l10n.dateHint,
                            onDateChanged: (d) => bloc.add(DobChanged(d)),
                            readOnly: true,

                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      const SizedBox(height: 4),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.dob != current.dob,
                        builder: (context, state) {
                          final actualUserData = _getActualUserData();
                          final dob = state.dob ?? _parseDob(actualUserData['date_of_birth']?.toString());
                          final ageText = dob != null ? _calculateAge(dob) : '';
                          return CustomTextField(
                            labelText: l10n.ageLabel,
                            hintText: _toTitleCase(ageText),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.mobile != current.mobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('mobile_field_${state.mobile}'),
                            labelText: l10n.mobileLabel,
                            hintText: l10n.mobileHint,
                            initialValue: state.mobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(MobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.altMobile != current.altMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('alt_mobile_field_${state.altMobile}'),
                            labelText: l10n.altMobileLabel,
                            hintText: l10n.altMobileHint,
                            initialValue: state.altMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(AltMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.fatherSpouse != current.fatherSpouse,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('father_spouse_field_${state.fatherSpouse}'),
                            labelText: l10n.fatherSpouseLabel,
                            hintText: l10n.fatherSpouseHint,
                            initialValue: state.fatherSpouse != null ? _toTitleCase(state.fatherSpouse!.trim()) : '',
                            onChanged: (v) => bloc.add(FatherSpouseChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      const SizedBox(height: 4),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.doj != current.doj,
                        builder: (context, state) {
                          final actualUserData = _getActualUserData();
                          final displayDoj = state.doj ?? (actualUserData['date_of_joining'] != null ? DateTime.tryParse(actualUserData['date_of_joining'].toString()) : null);
                          return CustomDatePicker(
                            key: ValueKey('doj_field_${displayDoj?.toIso8601String()}'),
                            labelText: l10n.dojLabel,
                            initialDate: displayDoj,

                            hintText: l10n.dojLabel,
                            onDateChanged: (d) => bloc.add(DojChanged(d)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      const SizedBox(height: 12),
                      Text(
                        l10n.bankDetailsTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                       const SizedBox(height: 12),
                                          Divider(color: AppColors.divider, thickness: 0.5),
                                        BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.accountNumber != current.accountNumber,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('account_number_field_${state.accountNumber}'),
                            labelText: l10n.accountNumberLabel,
                            hintText: l10n.accountNumberHint,
                            initialValue: state.accountNumber,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(AccountNumberChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.ifsc != current.ifsc,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('ifsc_field_${state.ifsc}'),
                            labelText: l10n.ifscLabel,
                            hintText: l10n.ifscHint,
                            initialValue: state.ifsc,
                            onChanged: (v) => bloc.add(IfscChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      // State field with value from API
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.stateName != current.stateName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('state_field_${state.stateName}'),
                            labelText: l10n.stateLabel,
                            hintText: l10n.stateHint,
                            initialValue: state.stateName,
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),


                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.division != current.division,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('division_field_${state.division}'),
                            labelText: l10n.divisionLabel,
                            hintText: l10n.divisionHint,
                            initialValue: state.division,
                            readOnly: true,

                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),


                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.district != current.district,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('district_field_${state.district}'),
                            labelText: l10n.districtLabel,
                            hintText: l10n.districtHint,
                            initialValue: state.district,
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),


                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.block != current.block,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('block_field_${state.block}'),
                            labelText: l10n.blockLabel,
                            hintText: l10n.blockHint,
                            initialValue: state.block,
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.panchayat != current.panchayat,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('panchayat_field_${state.panchayat}'),
                            labelText: l10n.panchayatLabel,
                            hintText: l10n.panchayatHint,
                            initialValue: state.panchayat,
                            onChanged: (v) => bloc.add(PanchayatChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.village != current.village,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('village_field_${state.village}'),
                            labelText: l10n.villageLabel,
                            hintText: l10n.villageHint,
                            initialValue: state.village,
                            onChanged: (v) => bloc.add(VillageChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.tola != current.tola,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('tola_field_${state.tola}'),
                            labelText: l10n.tolaLabel,
                            hintText: l10n.tolaHint,
                            initialValue: state.tola,
                            onChanged: (v) => bloc.add(TolaChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.mukhiyaName != current.mukhiyaName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('mukhiya_name_field_${state.mukhiyaName}'),
                            labelText: l10n.mukhiyaNameLabel,
                            hintText: l10n.mukhiyaNameHint,
                            initialValue: state.mukhiyaName,
                            onChanged: (v) => bloc.add(MukhiyaNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.mukhiyaMobile != current.mukhiyaMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('mukhiya_mobile_field_${state.mukhiyaMobile}'),
                            labelText: l10n.mukhiyaMobileLabel,
                            hintText: l10n.mukhiyaMobileHint,
                            initialValue: state.mukhiyaMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(MukhiyaMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.hwcName != current.hwcName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('hwc_name_field_${state.hwcName}'),
                            labelText: l10n.hwcNameLabel,
                            hintText: l10n.hwcNameHint,
                            initialValue: state.hwcName,
                            onChanged: (v) => bloc.add(HwcNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.hscName != current.hscName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('hsc_name_field_${state.hscName}'),
                            labelText: l10n.hscNameLabel,
                            hintText: l10n.hscNameHint,
                            initialValue: state.hscName,
                            onChanged: (v) => bloc.add(HscNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.fruName != current.fruName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('fru_name_field_${state.fruName}'),
                            labelText: l10n.fruNameLabel,
                            hintText: l10n.fruNameHint,
                            initialValue: state.fruName,
                            onChanged: (v) => bloc.add(FruNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.phcChc != current.phcChc,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('phc_chc_field_${state.phcChc}'),
                            labelText: l10n.phcChcLabel,
                            hintText: l10n.phcChcHint,
                            initialValue: state.phcChc,
                            onChanged: (v) => bloc.add(PhcChcChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.rhSdhDh != current.rhSdhDh,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('rh_sdh_dh_field_${state.rhSdhDh}'),
                            labelText: l10n.rhSdhDhLabel,
                            hintText: l10n.rhSdhDhHint,
                            initialValue: state.rhSdhDh,
                            onChanged: (v) => bloc.add(RhSdhDhChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      const SizedBox(height: 12),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          return CustomTextField(
                            key: const ValueKey('population_covered_field'),
                            labelText: l10n.populationCoveredLabel,
                            hintText: l10n.populationCoveredHint,
                            initialValue: state.populationCovered,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(PopulationCoveredChanged(v)),
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.ashaFacilitatorName != current.ashaFacilitatorName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('asha_facilitator_name_field_${state.ashaFacilitatorName}'),
                            labelText: l10n.ashaFacilitatorNameLabel,
                            hintText: l10n.ashaFacilitatorNameHint,
                            initialValue: state.ashaFacilitatorName,
                            onChanged: (v) => bloc.add(AshaFacilitatorNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.ashaFacilitatorMobile != current.ashaFacilitatorMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('asha_facilitator_mobile_field_${state.ashaFacilitatorMobile}'),
                            labelText: l10n.ashaFacilitatorMobileLabel,
                            hintText: l10n.ashaFacilitatorMobileHint,
                            initialValue: state.ashaFacilitatorMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(AshaFacilitatorMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.choName != current.choName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('cho_name_field_${state.choName}'),
                            labelText: l10n.choNameLabel,
                            hintText: l10n.choNameHint,
                            initialValue: state.choName,
                            onChanged: (v) => bloc.add(ChoNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.choMobile != current.choMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('cho_mobile_field_${state.choMobile}'),
                            labelText: l10n.choMobileLabel,
                            hintText: l10n.choMobileHint,
                            initialValue: state.choMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(ChoMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.awwName != current.awwName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('aww_name_field_${state.awwName}'),
                            labelText: l10n.awwNameLabel,
                            hintText: l10n.awwNameHint,
                            initialValue: state.awwName,
                            onChanged: (v) => bloc.add(AwwNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.awwMobile != current.awwMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('aww_mobile_field_${state.awwMobile}'),
                            labelText: l10n.awwMobileLabel,
                            hintText: l10n.awwMobileHint,
                            initialValue: state.awwMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(AwwMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.anganwadiCenterNo != current.anganwadiCenterNo,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('anganwadi_center_no_field_${state.anganwadiCenterNo}'),
                            labelText: l10n.anganwadiCenterNoLabel,
                            hintText: l10n.anganwadiCenterNoHint,
                            initialValue: state.anganwadiCenterNo,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(AnganwadiCenterNoChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.anm1Name != current.anm1Name,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('anm1_name_field_${state.anm1Name}'),
                            labelText: l10n.anm1NameLabel,
                            hintText: l10n.anm1NameHint,
                            initialValue: state.anm1Name,
                            onChanged: (v) => bloc.add(Anm1NameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.anm1Mobile != current.anm1Mobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('anm1_mobile_field_${state.anm1Mobile}'),
                            labelText: l10n.anm1MobileLabel,
                            hintText: l10n.anm1MobileHint,
                            initialValue: state.anm1Mobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(Anm1MobileChanged(v)),
                            readOnly: true,

                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.anm2Name != current.anm2Name,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('anm2_name_field_${state.anm2Name}'),
                            labelText: l10n.anm2NameLabel,
                            hintText: l10n.anm2NameHint,
                            initialValue: state.anm2Name,
                            onChanged: (v) => bloc.add(Anm2NameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.anm2Mobile != current.anm2Mobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('anm2_mobile_field_${state.anm2Mobile}'),
                            labelText: l10n.anm2MobileLabel,
                            hintText: l10n.anm2MobileHint,
                            initialValue: state.anm2Mobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(Anm2MobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.bcmName != current.bcmName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('bcm_name_field_${state.bcmName}'),
                            labelText: l10n.bcmNameLabel,
                            hintText: l10n.bcmNameHint,
                            initialValue: state.bcmName,
                            onChanged: (v) => bloc.add(BcmNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.bcmMobile != current.bcmMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('bcm_mobile_field_${state.bcmMobile}'),
                            labelText: l10n.bcmMobileLabel,
                            hintText: l10n.bcmMobileHint,
                            initialValue: state.bcmMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(BcmMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.dcmName != current.dcmName,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('dcm_name_field_${state.dcmName}'),
                            labelText: l10n.dcmNameLabel,
                            hintText: l10n.dcmNameHint,
                            initialValue: state.dcmName,
                            onChanged: (v) => bloc.add(DcmNameChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => previous.dcmMobile != current.dcmMobile,
                        builder: (context, state) {
                          return CustomTextField(
                            key: ValueKey('dcm_mobile_field_${state.dcmMobile}'),
                            labelText: l10n.dcmMobileLabel,
                            hintText: l10n.dcmMobileHint,
                            initialValue: state.dcmMobile,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(DcmMobileChanged(v)),
                            readOnly: true,
                          );
                        },
                      ),
                      Divider(color: AppColors.divider, thickness: 0.5),

                      const SizedBox(height: 24),
                      RoundButton(
                        title: l10n.updateButton,
                        height: 48,
                        onPress: () => bloc.add(const SubmitProfile()),
                        isLoading: state.submitting,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        )
      );
    }
    }


  class Country {
    final int id;
    final String name;

    Country({required this.id, required this.name});
  }
