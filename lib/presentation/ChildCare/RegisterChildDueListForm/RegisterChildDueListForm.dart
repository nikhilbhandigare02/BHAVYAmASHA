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
import 'package:medixcel_new/data/Database/database_provider.dart';
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
  final String? createdDate;
  final String? weightGrams;
  final String? birthWeightGrams;

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
    this.createdDate,
    this.weightGrams,
    this.birthWeightGrams,
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
      createdDate: json['createdDate']?.toString(),
      weightGrams: json['weightGrams']?.toString(),
      birthWeightGrams: json['birthWeightGrams']?.toString(),
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
    'createdDate': createdDate,
    'weightGrams': weightGrams,
    'birthWeightGrams': birthWeightGrams,
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
    // Remove the WidgetsBinding callback - call directly
    _loadBeneficiaryData();
  }

  Future<void> _loadBeneficiaryData() async {
    if (!mounted) return;

    // Don't wrap in addPostFrameCallback since we're already in initState
    debugPrint('Loading member details...');

    try {
      final hhId = widget.arguments?['hhId']?.toString();
      final name = widget.arguments?['name']?.toString();

      final beneficiaryRefKey = widget.arguments?['beneficiary_ref_key']?.toString();
      if (beneficiaryRefKey != null && beneficiaryRefKey.isNotEmpty) {
        final db = await DatabaseProvider.instance.database;
        final rows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ? AND is_deleted = 0',
          whereArgs: [beneficiaryRefKey],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final row = rows.first;
          final infoStr = row['beneficiary_info']?.toString() ?? '{}';
          Map<String, dynamic> info = {};
          try {
            info = Map<String, dynamic>.from(jsonDecode(infoStr));
          } catch (_) {}

          final data = BeneficiaryData(
            name: (info['memberName']?.toString() ?? info['name']?.toString()),
            gender: info['gender']?.toString(),
            mobile: info['mobileNo']?.toString(),
            rchId: (info['rchId']?.toString() ?? info['RichID']?.toString() ?? info['RichIDChanged']?.toString()),
            fatherName: info['fatherName']?.toString(),
            motherName: info['motherName']?.toString(),
            dateOfBirth: info['dob']?.toString(),
            religion: info['religion']?.toString(),
            socialClass: info['category']?.toString(),
            uniqueKey: row['unique_key']?.toString(),
            createdDate: row['created_date_time']?.toString(),
            weightGrams: (info['weight']?.toString()),
            birthWeightGrams: (info['birthWeight']?.toString()),
          );

          setState(() {
            _beneficiaryData = data;
            _isLoading = false;
          });
          return;
        }
      }

      if (hhId == null || name == null) {
        debugPrint('Missing hhId or name in arguments');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      debugPrint('Loading beneficiary data for hhId: $hhId, name: $name');
      final db = await DatabaseProvider.instance.database;

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
      BeneficiaryData? beneficiaryData;

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

          debugPrint('\n=== House Details for HHID: ${row['id']} ===');
          debugPrint('Head Name: ${headDetails['headName']}');
          debugPrint('House No: ${headDetails['houseNo']}');

          // Check if the head matches the name
          final headName = headDetails['headName']?.toString().toLowerCase() ?? '';
          if (headName == name.toLowerCase()) {
            beneficiaryData = BeneficiaryData(
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
          if (memberDetails.isNotEmpty) {
            debugPrint('\n=== Member Details ===');
            debugPrint('Total members: ${memberDetails.length}');

            for (var member in memberDetails) {
              final memberName = member['memberName']?.toString().toLowerCase() ?? '';
              debugPrint('Checking member: $memberName');

              if (memberName == name.toLowerCase()) {
                debugPrint('\nFound matching member: $memberName');

                beneficiaryData = BeneficiaryData(
                  name: member['memberName']?.toString(),
                  gender: member['gender']?.toString(),
                  mobile: member['mobileNo']?.toString(),
                  rchId: member['richId']?.toString(),
                  fatherName: member['fatherName']?.toString(),
                  motherName: member['motherName']?.toString(),
                  dateOfBirth: member['dob']?.toString(),
                  religion: member['religion']?.toString(),
                  socialClass: member['category']?.toString(),
                  uniqueKey: member['unique_key']?.toString(),
                );
                break;
              }
            }
          }

          if (beneficiaryData != null) break;
        } catch (e) {
          debugPrint('Error processing beneficiary data: $e');
        }
      }

      if (mounted) {
        setState(() {
          _beneficiaryData = beneficiaryData;
          _isLoading = false;
        });

        if (beneficiaryData != null) {
          debugPrint('Successfully loaded beneficiary data:');
          debugPrint(beneficiaryData.toString());
        } else {
          debugPrint('No matching beneficiary found for hhId: $hhId and name: $name');
        }
      }
    } catch (e) {
      debugPrint('Error loading beneficiary data: $e');
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

    final args = widget.arguments ?? {};
    final hhId = args['hhId']?.toString();

    final bloc = RegisterChildFormBloc(
      beneficiaryId: (args['beneficiary_ref_key']?.toString() ?? args['beneficiaryId']?.toString()),
      householdId: hhId,
    );

    final data = _beneficiaryData;

    if (data != null) {
      if (data.name != null) bloc.add(ChildNameChanged(data.name!));
      if (data.gender != null) {
        String genderValue = data.gender!;
        if (genderValue.toLowerCase() == 'male') {
          genderValue = 'Male';
        } else if (genderValue.toLowerCase() == 'female') {
          genderValue = 'Female';
        } else {
          genderValue = 'Other';
        }
        bloc.add(GenderChanged(genderValue));
      }
      if (data.mobile != null) {
        bloc.add(MobileNumberChanged(data.mobile!));
        bloc.add(WhoseMobileNumberChanged('Self'));
      }
      if (data.fatherName != null) bloc.add(FatherNameChanged(data.fatherName!));
      if (data.motherName != null) bloc.add(MotherNameChanged(data.motherName!));
      if (data.rchId != null) bloc.add(RchIdChildChanged(data.rchId!));
      if (data.religion != null) bloc.add(ReligionChanged(data.religion!));
      if (data.socialClass != null) bloc.add(CasteChanged(data.socialClass!));
      if (data.dateOfBirth != null) {
        try {
          final dob = DateTime.tryParse(data.dateOfBirth!);
          if (dob != null) {
            bloc.add(DateOfBirthChanged(dob));
          }
        } catch (e) {
          debugPrint('Error parsing date of birth: $e');
        }
      }
      DateTime? regDt;
      if (data.createdDate != null) {
        regDt = DateTime.tryParse(data.createdDate!);
      }
      bloc.add(DateOfRegistrationChanged(regDt ?? DateTime.now()));
      if (data.weightGrams != null && data.weightGrams!.isNotEmpty) {
        bloc.add(WeightGramsChanged(data.weightGrams!));
      }
      if (data.birthWeightGrams != null && data.birthWeightGrams!.isNotEmpty) {
        bloc.add(BirthWeightGramsChanged(data.birthWeightGrams!));
      }
    } else if (args.isNotEmpty) {
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

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    labelText: l10n?.rchIdChildLabel ?? 'RCH ID (Child)',
                                    hintText: l10n?.rchChildSerialHint ?? 'Enter RCH ID of the child',
                                    initialValue: state.rchIdChild,
                                    onChanged: (v) => bloc.add(RchIdChildChanged(v)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 50,
                                  width: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: RoundButton(
                                      title: 'VERIFY',
                                      borderRadius: 8,
                                      fontSize: 12,
                                      onPress: () {
                                        // Add verification logic here
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: l10n?.rchChildSerialHint ?? 'Register Serial Number',
                              hintText: 'Enter serial number',
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
                              hintText: 'Enter mother\'s name',
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
                              hintText: 'Enter father\'s name',
                              initialValue: state.fatherName,
                              onChanged: (v) => bloc.add(FatherNameChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: "${l10n?.addressLabel} *" ?? 'Address',
                              hintText: 'Enter address',
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
                              labelText: "${l10n?.mobileNumberLabel} *" ?? 'Mobile number *',
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
                              hintText: 'Enter mother\'s RCH ID',
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
                              hintText: 'Enter weight',
                              initialValue: state.weightGrams,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => bloc.add(WeightGramsChanged(v)),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
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
                                  l10n?.other ?? 'Pichda varg',
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