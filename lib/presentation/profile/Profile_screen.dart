import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import '../../core/config/routes/Route_Name.dart';
import '../../core/widgets/Dropdown/Dropdown.dart';
import '../../core/widgets/Dropdown/dropdown.dart' hide ApiDropdown;
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

class _ProfileScreenState extends State<ProfileScreen> {
  List<Country> countries = [
    Country(id: 1, name: 'rural'),
    Country(id: 2, name: 'urban'),
  ];
  Country? selectedCountry;
  String _userFullName = '';
  Map<String, dynamic> details = {};
  late final ProfileBloc _profileBloc;

  
  // Helper method to parse date string
  DateTime? _parseDob(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.tryParse(dateString);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }
  
  // Helper method to calculate age in years, months, and days
  String _calculateAge(DateTime? dob) {
    if (dob == null) return '';
    
    final now = DateTime.now();
    
    // Calculate years
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
      print('1. Starting to load user data...');

      final userData = await UserInfo.getCurrentUser();
      print('2. Raw user data from database: ${userData?.toString()}');

      if (userData == null || userData.isEmpty) {
        print('Error: No user data found in local database');
        return;
      }

      if (!mounted) {
        print('Widget not mounted, skipping state updates');
        return;
      }

      print('3. Found user data, processing...');

      // Ensure the widget is still mounted and get the BLoC instance
      if (!mounted) return;
      final bloc = context.read<ProfileBloc>();

      // Safely parse details
      try {
        details = userData['details'] is String
            ? jsonDecode(userData['details'] as String)
            : userData['details'] as Map<String, dynamic>? ?? {};
      } catch (e) {
        print('Error parsing user details: $e');
        return;
      }

      print('4. Extracted details: $details');

      final name = details['name'] is Map ? Map<String, dynamic>.from(details['name']) : <String, dynamic>{};
      final workingLocation = details['working_location'] is Map
          ? Map<String, dynamic>.from(details['working_location'])
          : <String, dynamic>{};
      final contactInfo = details['contact_info'] is Map
          ? Map<String, dynamic>.from(details['contact_info'])
          : <String, dynamic>{};

      print('5. Extracted name: $name');
      print('6. Extracted working location: $workingLocation');
      print('7. Extracted contact info: $contactInfo');

      // Set selected country based on area_of_working
      final areaOfWorking = details['area_of_working']?.toString().toLowerCase().trim() ?? '';
      print('8. Area of working from API: $areaOfWorking');
      
      if (mounted) {
        setState(() {
          if (areaOfWorking.isNotEmpty) {
            try {
              selectedCountry = countries.firstWhere(
                (c) => c.name.toLowerCase() == areaOfWorking,
                orElse: () => countries.first
              );
              print('9. Set selected country to: ${selectedCountry?.name}');
            } catch (e) {
              print('Error setting area of working: $e');
              selectedCountry = countries.isNotEmpty ? countries.first : null;
            }
          } else {
            selectedCountry = countries.isNotEmpty ? countries.first : null;
          }
        });
      }
      
      // Store the name in a class-level variable to use in the widget
      _userFullName = '${name['first_name'] ?? ''} ${name['middle_name'] ?? ''} ${name['last_name'] ?? ''}'.trim();
      print('Stored user full name: $_userFullName');

      try {
        // Basic Information
        final ashaId = workingLocation['asha_id']?.toString() ?? '';

        // Build full name from name parts
        final firstName = name['first_name']?.toString().trim() ?? '';
        final middleName = name['middle_name']?.toString().trim() ?? '';
        final lastName = name['last_name']?.toString().trim() ?? '';

        // Combine name parts with proper spacing
        final fullName = [firstName, middleName, lastName]
            .where((part) => part.isNotEmpty)
            .join(' ');

        print('Building full name from: $firstName, $middleName, $lastName');
        print('Resulting full name: $fullName');

        // Update the BLoC state with the full name
        bloc.add(AshaNameChanged(fullName));
        print('Dispatched AshaNameChanged with: $fullName');

        final fatherSpouse = details['father_or_spouse_name']?.toString() ?? '';

        // Contact Information
        final mobileNumber = contactInfo['mobile_number']?.toString() ?? '';
        final altMobileNumber = contactInfo['alternate_mobile_number']?.toString() ?? '';

        // Working Location
        final state = workingLocation['state']?.toString() ?? '';
        final division = workingLocation['division']?.toString() ?? '';
        final district = workingLocation['district']?.toString() ?? '';
        final block = workingLocation['block']?.toString() ?? '';
        final panchayat = workingLocation['panchayat']?.toString() ?? '';
        final village = workingLocation['village']?.toString() ?? '';
        final tola = workingLocation['tola']?.toString() ?? '';

        print('State from API: $state');
        print('Division from API: $division');
        print('District from API: $district');
        print('Block from API: $block');

        // HSC Information
        final hscName = workingLocation['hsc_name']?.toString() ?? '';
        final hscHfrId = workingLocation['hsc_hfr_id']?.toString() ?? '';

        // Bank Details
        final bankDetails = details['bank_account_details'] is Map
            ? Map<String, dynamic>.from(details['bank_account_details'])
            : <String, dynamic>{};
        final accountNumber = bankDetails['bank_account_number']?.toString() ?? '';
        final ifscCode = bankDetails['ifsc_code']?.toString() ?? '';

        // Other fields
        final populationCovered = details['population_covered_by_asha']?.toString() ?? '';

        // Update form fields using individual events
        if (mounted) {
          // Update basic information
          _profileBloc.add(AshaIdChanged(ashaId));
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
          _profileBloc.add(HwcNameChanged(hscHfrId));
          _profileBloc.add(AccountNumberChanged(accountNumber));
          _profileBloc.add(IfscChanged(ifscCode));
          _profileBloc.add(PopulationCoveredChanged(populationCovered));

          print('Dispatched all field updates');
        }

        // Handle dates
        if (details['date_of_birth'] != null) {
          try {
            final dob = DateTime.tryParse(details['date_of_birth'].toString());
            if (dob != null) {
              bloc.add(DobChanged(dob));
            }
          } catch (e) {
            print('Error parsing date of birth: $e');
          }
        }

        if (details['date_of_joining'] != null) {
          try {
            final doj = DateTime.tryParse(details['date_of_joining'].toString());
            if (doj != null) {
              bloc.add(DojChanged(doj));
            }
          } catch (e) {
            print('Error parsing date of joining: $e');
          }
        }

      } catch (e) {
        print('Error updating form fields: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating form: ${e.toString()}')),
          );
        }
      }
     } catch (e) {
       print('Error loading user data: $e');
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

    return WillPopScope(
      onWillPop: () async {
        if (widget.fromLogin) {
          // If user came from login, navigate to home instead of login
          Navigator.of(context).pushReplacementNamed(Route_Names.homeScreen);
          return false;
        }
        // If user came from drawer, allow normal back navigation
        return true;
      },
      child: BlocProvider(
        create: (_) => ProfileBloc(),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppHeader(
            screenTitle: l10n.ashaProfile,
            showBack: true,
            onBackTap: widget.fromLogin
                ? () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      Route_Names.homeScreen,
                      (route) => false,
                    );
                  }
                : null,
          ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.profileUpdated)),
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
                  ApiDropdown<Country>(
                    labelText: l10n.areaOfWorking,
                    items: countries,
                    value: selectedCountry,
                    getLabel: (country) => country.name,
                    hintText: l10n.selectArea,
                    onChanged: (value) {
                      setState(() => selectedCountry = value);
                      if (value != null) {
                        bloc.add(AreaOfWorkingChanged(value.name));
                      }
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.ashaIdLabel,
                    hintText: l10n.ashaIdHint,
                    onChanged: (v) => bloc.add(AshaIdChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  // ASHA Name field with direct value from API
                  Builder(
                    builder: (context) {
                      print('Building ASHA Name field with direct value: $_userFullName');
                      return CustomTextField(
                        key: ValueKey('asha_name_field_$_userFullName'),
                        labelText: l10n.ashaNameLabel,
                        hintText: l10n.ashaNameHint,
                        initialValue: _userFullName,
                        onChanged: (v) {
                          _userFullName = v;
                          bloc.add(AshaNameChanged(v));
                        },
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 4),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.dob != current.dob,
                    builder: (context, state) {

                      final displayDob = state.dob ?? _parseDob(details['date_of_birth']?.toString());
                      
                      return CustomDatePicker(
                        key: ValueKey('dob_field_${displayDob?.toIso8601String()}'),
                        labelText: l10n.dobLabel,
                        initialDate: displayDob,
                        isEditable: true,
                        hintText: l10n.dateHint,
                        onDateChanged: (d) => bloc.add(DobChanged(d)),
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  const SizedBox(height: 4),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.dob != current.dob,
                    builder: (context, state) {
                      final dob = state.dob ?? _parseDob(details['date_of_birth']?.toString());
                      final ageText = dob != null ? _calculateAge(dob) : '';
                      return CustomTextField(
                        labelText: l10n.ageLabel,
                        hintText: ageText,
                        readOnly: true,
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.mobileLabel,
                    hintText: l10n.mobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(MobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.altMobileLabel,
                    hintText: l10n.altMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(AltMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.fatherSpouseLabel,
                    hintText: l10n.fatherSpouseHint,
                    onChanged: (v) => bloc.add(FatherSpouseChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 4),
                  CustomDatePicker(
                    labelText: l10n.dojLabel,
                    initialDate: state.doj,
                    isEditable: true,
                    hintText: l10n.dojLabel,
                    onDateChanged: (d) => bloc.add(DojChanged(d)),
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
                                    CustomTextField(
                    labelText: l10n.accountNumberLabel,
                    hintText: l10n.accountNumberHint,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => bloc.add(AccountNumberChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.ifscLabel,
                    hintText: l10n.ifscHint,
                    onChanged: (v) => bloc.add(IfscChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  // State field with value from API
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.stateName != current.stateName,
                    builder: (context, state) {
                      print('Rebuilding state field with value: ${state.stateName}');
                      return CustomTextField(
                        key: ValueKey('state_field_${state.stateName}'),
                        labelText: l10n.stateLabel,
                        hintText: l10n.stateHint,
                        initialValue: state.stateName,
                        onChanged: (v) {},
                        readOnly: true,
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  // Division field with value from API
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.division != current.division,
                    builder: (context, state) {
                      print('Rebuilding division field with value: ${state.division}');
                      return CustomTextField(
                        key: ValueKey('division_field_${state.division}'),
                        labelText: l10n.divisionLabel,
                        hintText: l10n.divisionHint,
                        initialValue: state.division,
                        onChanged: (v) {},
                        readOnly: true,
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  // District field with value from API
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.district != current.district,
                    builder: (context, state) {
                      print('Rebuilding district field with value: ${state.district}');
                      return CustomTextField(
                        key: ValueKey('district_field_${state.district}'),
                        labelText: l10n.districtLabel,
                        hintText: l10n.districtHint,
                        initialValue: state.district,
                        onChanged: (v) {},
                        readOnly: true,
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  // Block field with value from API
                  BlocBuilder<ProfileBloc, ProfileState>(
                    buildWhen: (previous, current) => previous.block != current.block,
                    builder: (context, state) {
                      print('Rebuilding block field with value: ${state.block}');
                      return CustomTextField(
                        key: ValueKey('block_field_${state.block}'),
                        labelText: l10n.blockLabel,
                        hintText: l10n.blockHint,
                        initialValue: state.block,
                        onChanged: (v) {},
                        readOnly: true,
                      );
                    },
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.panchayatLabel,
                    hintText: l10n.panchayatHint,
                    onChanged: (v) => bloc.add(PanchayatChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.villageLabel,
                    hintText: l10n.villageHint,
                    onChanged: (v) => bloc.add(VillageChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.tolaLabel,
                    hintText: l10n.tolaHint,
                    onChanged: (v) => bloc.add(TolaChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.mukhiyaNameLabel,
                    hintText: l10n.mukhiyaNameHint,
                    onChanged: (v) => bloc.add(MukhiyaNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.mukhiyaMobileLabel,
                    hintText: l10n.mukhiyaMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(MukhiyaMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.hwcNameLabel,
                    hintText: l10n.hwcNameHint,
                    onChanged: (v) => bloc.add(HwcNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.hscNameLabel,
                    hintText: l10n.hscNameHint,
                    onChanged: (v) => bloc.add(HscNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.fruNameLabel,
                    hintText: l10n.fruNameHint,
                    onChanged: (v) => bloc.add(FruNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.phcChcLabel,
                    hintText: l10n.phcChcHint,
                    onChanged: (v) => bloc.add(PhcChcChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.rhSdhDhLabel,
                    hintText: l10n.rhSdhDhHint,
                    onChanged: (v) => bloc.add(RhSdhDhChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 12),
                  CustomTextField(
                    labelText: l10n.populationCoveredLabel,
                    hintText: l10n.populationCoveredHint,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => bloc.add(PopulationCoveredChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.ashaFacilitatorNameLabel,
                    hintText: l10n.ashaFacilitatorNameHint,
                    onChanged: (v) => bloc.add(AshaFacilitatorNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.ashaFacilitatorMobileLabel,
                    hintText: l10n.ashaFacilitatorMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(AshaFacilitatorMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.choNameLabel,
                    hintText: l10n.choNameHint,
                    onChanged: (v) => bloc.add(ChoNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.choMobileLabel,
                    hintText: l10n.choMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(ChoMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.awwNameLabel,
                    hintText: l10n.awwNameHint,
                    onChanged: (v) => bloc.add(AwwNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.awwMobileLabel,
                    hintText: l10n.awwMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(AwwMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.anganwadiCenterNoLabel,
                    hintText: l10n.anganwadiCenterNoHint,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => bloc.add(AnganwadiCenterNoChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.anm1NameLabel,
                    hintText: l10n.anm1NameHint,
                    onChanged: (v) => bloc.add(Anm1NameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.anm1MobileLabel,
                    hintText: l10n.anm1MobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(Anm1MobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.anm2NameLabel,
                    hintText: l10n.anm2NameHint,
                    onChanged: (v) => bloc.add(Anm2NameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.anm2MobileLabel,
                    hintText: l10n.anm2MobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(Anm2MobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.bcmNameLabel,
                    hintText: l10n.bcmNameHint,
                    onChanged: (v) => bloc.add(BcmNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.bcmMobileLabel,
                    hintText: l10n.bcmMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(BcmMobileChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.dcmNameLabel,
                    hintText: l10n.dcmNameHint,
                    onChanged: (v) => bloc.add(DcmNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.dcmMobileLabel,
                    hintText: l10n.dcmMobileHint,
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => bloc.add(DcmMobileChanged(v)),
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
