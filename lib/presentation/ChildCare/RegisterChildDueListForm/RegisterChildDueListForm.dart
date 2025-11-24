import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/SnackBar/app_snackbar.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'bloc/register_child_form_bloc.dart';

class BeneficiaryData {
  final String? name;
  final String? gender;
  final String? mobile;
  final String? rchId;
  final String? fatherName;
  final String? motherName;
  final String? dateOfBirth;
  final String? religion;
  final String? socialClass;
  final String? uniqueKey;

  BeneficiaryData({
    this.name,
    this.gender,
    this.mobile,
    this.rchId,
    this.fatherName,
    this.motherName,
    this.dateOfBirth,
    this.religion,
    this.socialClass,
    this.uniqueKey,
  });

  factory BeneficiaryData.fromJson(Map<String, dynamic> json) {
    return BeneficiaryData(
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      mobile: json['mobile']?.toString(),
      rchId: json['rchId']?.toString(),
      fatherName: json['fatherName']?.toString(),
      motherName: json['motherName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      religion: json['religion']?.toString(),
      socialClass: json['socialClass']?.toString(),
      uniqueKey: json['uniqueKey']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'mobile': mobile,
        'rchId': rchId,
        'fatherName': fatherName,
        'motherName': motherName,
        'dateOfBirth': dateOfBirth,
        'religion': religion,
        'socialClass': socialClass,
        'uniqueKey': uniqueKey,
      };

  @override
  String toString() => 'BeneficiaryData(${toJson()})';
}

class RegisterChildDueListFormScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const RegisterChildDueListFormScreen({
    super.key,
    this.arguments,
  });

  @override
  State<RegisterChildDueListFormScreen> createState() => _RegisterChildDueListFormScreen();
  
  // Helper method to create the route with arguments
  static Route<dynamic> route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => RegisterChildDueListFormScreen(
        arguments: settings.arguments as Map<String, dynamic>?,
      ),
      settings: settings,
    );
  }
}

class _RegisterChildDueListFormScreen extends State<RegisterChildDueListFormScreen> {
  bool _isLoading = true;
  BeneficiaryData? _beneficiaryData;
  final _formKey = GlobalKey<FormState>();

  // Capture first validation error so we can also show it in a SnackBar
  static String? _firstError;

  static void _clearFirstError() {
    _firstError = null;
  }

  static String? _captureError(String? message) {
    if (message != null && _firstError == null) {
      _firstError = message;
    }
    return message;
  }

  @override
  void initState() {
    super.initState();
    _loadBeneficiaryData();
  }

  Future<void> _loadBeneficiaryData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    debugPrint('Loading member details...');

    try {
      final hhId = widget.arguments?['hhId']?.toString();
      final name = widget.arguments?['name']?.toString();

      if (hhId == null || name == null) {
        debugPrint('Missing hhId or name in arguments');
        return;
      }

      debugPrint('Loading beneficiary data for hhId: $hhId, name: $name');
      final db = await DatabaseProvider.instance.database;

      // First, try to find by household reference key
      var results = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ?',
        whereArgs: [hhId],
      );

      if (results.isEmpty) {
        results = await db.query(
          'beneficiaries_new',
          where: 'id = ?',
          whereArgs: [hhId],
        );
      }

      debugPrint('Found ${results.length} beneficiaries');

      for (var row in results) {
        try {
          final beneficiaryInfoStr = row['beneficiary_info'] as String?;
          if (beneficiaryInfoStr == null || beneficiaryInfoStr.isEmpty) {
            debugPrint('Empty beneficiary_info for row ${row['id']}');
            continue;
          }

          final beneficiaryInfo = jsonDecode(beneficiaryInfoStr);
          final headDetails = beneficiaryInfo['head_details'] ?? {};
          final memberDetails = beneficiaryInfo['member_details'] as List<dynamic>? ?? [];

          // Debug head details
          debugPrint('\n=== House Details for HHID: ${row['id']} ===');
          debugPrint('Head Name: ${headDetails['headName']}');
          debugPrint('House No: ${headDetails['houseNo']}');

          if (memberDetails.isNotEmpty) {
            debugPrint('\n=== Member Details ===');
            debugPrint('Total members: ${memberDetails.length}');

            for (var i = 0; i < memberDetails.length; i++) {
              final member = memberDetails[i];
              debugPrint('\nMember ${i + 1}:');
              debugPrint('Name: ${member['memberName']}');
              debugPrint('Gender: ${member['gender']}');
              debugPrint('DOB: ${member['dob']}');
              debugPrint('Mobile: ${member['mobileNo']}');
              debugPrint('Father: ${member['fatherName']}');
              debugPrint('Mother: ${member['motherName']}');
              debugPrint('Relation: ${member['relation']}');
              debugPrint('Mobile Owner: ${member['mobileOwner']}');
              debugPrint('Religion: ${member['religion']}');
              debugPrint('Category: ${member['category']}');
              debugPrint('Birth Certificate: ${member['birthCertificate']}');
              debugPrint('Education: ${member['education']}');
              debugPrint('Occupation: ${member['occupation']}');
              debugPrint('Bank Account: ${member['bankAcc']}');
              debugPrint('IFSC: ${member['ifsc']}');
              debugPrint('Voter ID: ${member['voterId']}');
              debugPrint('Ration ID: ${member['rationId']}');
              debugPrint('PH ID: ${member['phId']}');
              debugPrint('ABHA Address: ${member['abhaAddress']}');
              debugPrint('RCH ID: ${member['richId']}');
              debugPrint('Weight: ${member['weight']}');
              debugPrint('School: ${member['school']}');
              debugPrint('Unique Key: ${member['unique_key']}');

              // If this member matches the name we're looking for, set as beneficiary data
              if ((member['memberName']?.toString().toLowerCase() ?? '') == name.toLowerCase()) {
                _beneficiaryData = BeneficiaryData(
                  name: member['memberName']?.toString(),
                  gender: member['gender']?.toString(),
                  mobile: member['mobileNo']?.toString(),
                  fatherName: member['fatherName']?.toString(),
                  motherName: member['motherName']?.toString(),
                  dateOfBirth: member['dob']?.toString(),
                  religion: member['religion']?.toString(),
                  socialClass: member['category']?.toString(),
                  uniqueKey: member['unique_key']?.toString(),
                );

                // Set all form fields using BLoC events
                if (mounted) {
                  final bloc = context.read<RegisterChildFormBloc>();

                  // Basic info
                  if (member['memberName'] != null) {
                    bloc.add(ChildNameChanged(member['memberName'].toString()));
                  }

                  // Gender
                  if (member['gender'] != null) {
                    bloc.add(GenderChanged(
                      member['gender'].toString().toLowerCase() == 'male'
                          ? 'Male'
                          : member['gender'].toString().toLowerCase() == 'female'
                              ? 'Female'
                              : 'Other'
                    ));
                  }

                  // Date of Birth
                  if (member['dob'] != null) {
                    try {
                      final dob = DateTime.tryParse(member['dob'].toString());
                      if (dob != null) {
                        bloc.add(DateOfBirthChanged(dob));
                      }
                    } catch (e) {
                      debugPrint('Error parsing date of birth: $e');
                    }
                  }

                  // Mobile number
                  if (member['mobileNo'] != null) {
                    bloc.add(MobileNumberChanged(member['mobileNo'].toString()));
                    bloc.add(WhoseMobileNumberChanged('Self'));
                  }

                  // Parents info
                  if (member['fatherName'] != null) {
                    bloc.add(FatherNameChanged(member['fatherName'].toString()));
                  }

                  if (member['motherName'] != null) {
                    bloc.add(MotherNameChanged(member['motherName'].toString()));
                  }

                  // RCH ID
                  if (member['richId'] != null) {
                    bloc.add(RchIdChildChanged(member['richId'].toString()));
                  }

                  // Religion
                  if (member['religion'] != null) {
                    bloc.add(ReligionChanged(member['religion'].toString()));
                  }

                  // Caste/Social Class
                  if (member['category'] != null) {
                    bloc.add(CasteChanged(member['category'].toString()));
                  }

                  // Birth Certificate
                  if (member['birthCertificate'] != null) {
                    final hasCertificate = member['birthCertificate'].toString().toLowerCase() == 'yes';
                    bloc.add(BirthCertificateIssuedChanged(hasCertificate ? 'Yes' : 'No'));
                    if (hasCertificate && member['birthCertificateNumber'] != null) {
                      bloc.add(BirthCertificateNumberChanged(member['birthCertificateNumber'].toString()));
                    }
                  }

                  // Weight
                  if (member['weight'] != null) {
                    bloc.add(WeightGramsChanged(member['weight'].toString()));
                  }

                  // Set registration date to today
                  bloc.add(DateOfRegistrationChanged(DateTime.now()));
                }
              }
            }
          }

          // Also check if the head matches the name
          final headName = headDetails['headName']?.toString().toLowerCase() ?? '';
          if (headName == name.toLowerCase()) {
            _beneficiaryData = BeneficiaryData(
              name: headDetails['headName']?.toString(),
              gender: headDetails['gender']?.toString(),
              mobile: headDetails['mobileNo']?.toString(),
              fatherName: headDetails['fatherName']?.toString(),
              dateOfBirth: headDetails['dob']?.toString(),
              religion: headDetails['religion']?.toString(),
              socialClass: headDetails['category']?.toString(),
              uniqueKey: row['unique_key']?.toString(),
            );
            break;
          }

          // Check members
          debugPrint('Checking ${memberDetails.length} member(s)');
          for (var member in memberDetails) {
            final memberName = member['memberName']?.toString().toLowerCase() ?? '';
            debugPrint('Checking member: $memberName');

            if (memberName == name.toLowerCase()) {
              _beneficiaryData = BeneficiaryData(
                name: member['memberName']?.toString(),
                gender: member['gender']?.toString(),
                mobile: member['mobileNo']?.toString(),
                fatherName: member['fatherName']?.toString(),
                motherName: headDetails['headName']?.toString(),
                dateOfBirth: member['dob']?.toString(),
                religion: member['religion']?.toString(),
                socialClass: member['category']?.toString(),
                uniqueKey: member['unique_key']?.toString(),
              );
              break;
            }
          }

          if (_beneficiaryData != null) break;
        } catch (e) {
          debugPrint('Error parsing beneficiary data: $e');
        }
      }

      if (_beneficiaryData != null) {
        debugPrint('Successfully loaded beneficiary data:');
        debugPrint(_beneficiaryData.toString());
      } else {
        debugPrint('No matching beneficiary found for hhId: $hhId and name: $name');
      }
    } catch (e) {
      debugPrint('Error loading beneficiary data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get arguments
    final args = widget.arguments ?? {};
    final hhId = args['hhId']?.toString();
    final name = args['name']?.toString();

    // Initialize BLoC with beneficiary_ref_key and householdId
    final bloc = RegisterChildFormBloc(
      beneficiaryId: (args['beneficiary_ref_key']?.toString() ?? args['beneficiaryId']?.toString()),
      householdId: hhId,
    );

    // Set initial values from loaded data
    final data = _beneficiaryData;

    if (data != null) {
      if (data.name != null) bloc.add(ChildNameChanged(data.name!));
      if (data.gender != null) bloc.add(GenderChanged(data.gender!));
      if (data.mobile != null) bloc.add(MobileNumberChanged(data.mobile!));
      if (data.fatherName != null) bloc.add(FatherNameChanged(data.fatherName!));
      if (data.rchId != null) bloc.add(RchIdChildChanged(data.rchId!));
      if (data.motherName != null) debugPrint('Mother\'s name: ${data.motherName}');
      if (data.religion != null) debugPrint('Religion: ${data.religion}');
      if (data.socialClass != null) debugPrint('Social Class: ${data.socialClass}');
      if (data.dateOfBirth != null) debugPrint('Date of Birth: ${data.dateOfBirth}');
    } else if (args.isNotEmpty) {
      // Fallback to arguments if no data loaded
      if (args['name'] != null) bloc.add(ChildNameChanged(args['name'].toString()));
      if (args['gender'] != null) bloc.add(GenderChanged(args['gender'].toString()));
      if (args['mobile'] != null) bloc.add(MobileNumberChanged(args['mobile'].toString()));
      if (args['fatherName'] != null) bloc.add(FatherNameChanged(args['fatherName'].toString()));
      if (args['rchId'] != null) bloc.add(RchIdChildChanged(args['rchId'].toString()));
    }

    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.registrationDue ?? 'registration due',
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<RegisterChildFormBloc, RegisterChildFormState>(
            listener: (context, state) {
              if (state.error != null && state.error!.isNotEmpty) {
                showAppSnackBar(context, state.error!);
              }
              if (state.isSuccess) {
                showAppSnackBar(context, l10n?.saveSuccess ?? 'Saved successfully');
                // Pop with result after successful save
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.pop(context, {
                      'saved': true,
                      'beneficiaryId': _beneficiaryData?.uniqueKey ?? '',
                      'name': _beneficiaryData?.name ?? '',
                      'hhId': widget.arguments?['hhId']?.toString() ?? '',
                    });
                  }
                });
              }
            },
            builder: (context, state) {
              final bloc = context.read<RegisterChildFormBloc>();
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                          const SizedBox(height: 5),

                          CustomTextField(
                            labelText: l10n?.rchIdChildLabel ?? 'RCH ID (Child)',
                            hintText: l10n?.rchChildSerialHint ?? 'Enter RCH ID of the child',
                            initialValue: state.rchIdChild,
                            onChanged: (v) => bloc.add(RchIdChildChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomTextField(
                            labelText: l10n?.rchChildSerialHint ?? 'Register Serial Number',
                            hintText: 'Enter serial number ',
                            initialValue: state.registerSerialNumber,
                            onChanged: (v) => bloc.add(SerialNumberOFRegister(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          CustomDatePicker(
                            labelText: l10n?.dateOfBirthLabel ?? 'Date of Birth *',
                            initialDate: state.dateOfBirth,
                            onDateChanged: (d) => bloc.add(DateOfBirthChanged(d)),
                            validator: (date) {
                              if (date == null) {
                                return _captureError('Date of Birth is required');
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomDatePicker(
                            labelText: l10n?.dateOfRegistrationLabel ?? 'Date of Registration *',
                            initialDate: state.dateOfRegistration,
                            onDateChanged: (d) => bloc.add(DateOfRegistrationChanged(d)),
                            validator: (date) {
                              if (date == null) {
                                return _captureError('Date of Registration is required');
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.childNameLabel ?? "Child's name *",
                            hintText: 'Enter full name of the child',
                            initialValue: state.childName,
                            onChanged: (v) => bloc.add(ChildNameChanged(v)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return _captureError("Child's name is required");
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ApiDropdown<String>(
                              labelText: "${l10n?.genderLabel} *" ?? 'gender',
                              items: [l10n?.male ?? 'Male', l10n?.female ?? 'Female', l10n?.other ?? 'Other'],
                              value: state.gender.isEmpty ? null : state.gender,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(GenderChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _captureError('Gender is required');
                                }
                                return null;
                              },
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: "${l10n?.motherNameLabel} *" ?? "Mother's name*",
                            hintText: 'Enter mother\'s  name',
                            initialValue: state.motherName,
                            onChanged: (v) => bloc.add(MotherNameChanged(v)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return _captureError("Mother's name is required");
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.fatherNameLabel ?? "Father's name",
                            hintText: 'Enter father\'s   name',
                            initialValue: state.fatherName,
                            onChanged: (v) => bloc.add(FatherNameChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: "${l10n?.addressLabel} *" ?? 'Address',
                            hintText: 'Enter address ',
                            initialValue: state.address,
                            onChanged: (v) => bloc.add(AddressChanged(v)),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return _captureError('Address is required');
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: ApiDropdown<String>(
                              labelText: "${l10n?.whoseMobileNumberLabel} *" ?? 'Whose mobile number is this',
                              items: [
                                l10n?.headOfFamily ?? 'Head of the family',
                                l10n?.mother ?? 'Mother',
                                l10n?.father ?? 'Father',
                                l10n?.other ?? 'Other',
                              ],
                              value: state.whoseMobileNumber.isEmpty ? null : state.whoseMobileNumber,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(WhoseMobileNumberChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return _captureError('Whose mobile number is required');
                                }
                                return null;
                              },
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText:"${ l10n?.mobileNumberLabel} *" ?? 'Mobile number *',
                            hintText: 'Enter 10-digit mobile number',
                            initialValue: state.mobileNumber,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(MobileNumberChanged(v)),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return _captureError('Mobile number is required');
                              }
                              final regex = RegExp(r'^[6-9]\d{9}$');
                              if (!regex.hasMatch(text)) {
                                return _captureError('Mobile no. must be 10 digits and start with 6-9');
                              }
                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.mothersRchIdLabel ?? "Mother's RCH ID number",
                            hintText: 'Enter mother\'s RCH ID  ',
                            initialValue: state.mothersRchIdNumber,
                            onChanged: (v) => bloc.add(MothersRchIdNumberChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ApiDropdown<String>(
                              labelText: l10n?.birthCertificateIssuedLabel ?? 'Has the birth certificate been issued?',
                              items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                              value: state.birthCertificateIssued.isEmpty ? null : state.birthCertificateIssued,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(BirthCertificateIssuedChanged(v ?? '')),
                              hintText: l10n?.choose ?? 'choose',
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.birthCertificateNumberLabel ?? 'Birth Certificate Number',
                            hintText: 'Enter birth certificate number if available',
                            initialValue: state.birthCertificateNumber,
                            onChanged: (v) => bloc.add(BirthCertificateNumberChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.weightGramLabel ?? 'Weight (g)',
                            hintText: 'Enter weight  ',
                            initialValue: state.weightGrams,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(WeightGramsChanged(v)),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                // Not required
                                return null;
                              }

                              final parsed = int.tryParse(text);
                              if (parsed == null) {
                                return _captureError('Please enter a valid weight in grams');
                              }

                              if (parsed < 500 || parsed > 12500) {
                                return _captureError('Weight must be between 500 and 12500 grams');
                              }

                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: 'Birth weight (g)',
                            hintText: 'Enter birth weight',
                            initialValue: state.birthWeightGrams,
                            keyboardType: TextInputType.number,
                            onChanged: (v) => bloc.add(BirthWeightGramsChanged(v)),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                // Not required
                                return null;
                              }

                              final parsed = int.tryParse(text);
                              if (parsed == null) {
                                return _captureError('Please enter a valid birth weight in grams');
                              }

                              if (parsed < 1200 || parsed > 4000) {
                                return _captureError('Birth weight must be between 1200 and 4000 grams');
                              }

                              return null;
                            },
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ApiDropdown<String>(
                              labelText: l10n?.religionLabel ?? 'Religion',
                              items: [
                                l10n?.religionHindu ?? 'Hindu',
                                l10n?.religionMuslim ?? 'Muslim',
                                l10n?.religionChristian ?? 'Christian',
                                l10n?.religionSikh ?? 'Sikh',
                                l10n?.other ?? 'Other',
                              ],
                              value: state.religion.isEmpty ? null : state.religion,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(ReligionChanged(v ?? '')),
                              hintText: l10n?.choose ?? 'choose',
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ApiDropdown<String>(
                              labelText: l10n?.casteLabel ?? 'Caste',
                              items: [
                                l10n?.casteGeneral ?? 'General',
                                l10n?.casteObc ?? 'OBC',
                                l10n?.casteSc ?? 'SC',
                                l10n?.casteSt ?? 'ST',
                                l10n?.other ?? 'Other',
                              ],
                              value: state.caste.isEmpty ? null : state.caste,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(CasteChanged(v ?? '')),
                              hintText: l10n?.choose ?? 'choose',
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                        ],
                      ),
                    ),
                  ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        height: 44,
                        child: RoundButton(
                          title: state.isSubmitting ? (l10n?.savingButton ?? 'SAVING...') : (l10n?.saveButton ?? 'SAVE'),
                          color: AppColors.primary,
                          borderRadius: 8,
                          onPress: () {
                            _clearFirstError();
                            final form = _formKey.currentState;
                            if (form == null) return;

                            final isValid = form.validate();
                            if (!isValid) {
                              final msg = _firstError ?? 'Please correct the highlighted fields.';
                              showAppSnackBar(context, msg);
                              return;
                            }

                            bloc.add(const SubmitPressed());
                          },
                          disabled: state.isSubmitting,
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

  @override
  void dispose() {
    super.dispose();
  }
}
