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
  final String? birthCertificate;
  final String? village;
  final String? mobileOwner;
  final String? otherReligion;
  final String? otherCategory;

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
    this.birthCertificate,
    this.village,
    this.mobileOwner,
    this.otherReligion,
    this.otherCategory,
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
      birthCertificate: json['birthCertificate']?.toString(),
      village: json['village']?.toString(),
      mobileOwner: json['mobileOwner']?.toString(),
      otherReligion: json['otherReligion']?.toString(),
      otherCategory: json['otherCategory']?.toString(),
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
    'birthCertificate': birthCertificate,
    'village': village,
    'mobileOwner': mobileOwner,
    'otherReligion': otherReligion,
    'otherCategory': otherCategory,
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

    debugPrint('Loading member details...');

    try {
      final passedVillage = widget.arguments?['village']?.toString();
      debugPrint('Received navigation arguments: ${widget.arguments}');
      debugPrint('Passed village: ${passedVillage ?? ''}');
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
          final headDetails = (info['head_details'] is Map)
              ? Map<String, dynamic>.from(info['head_details'])
              : <String, dynamic>{};

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
            birthCertificate: info['birthCertificate']?.toString(),
            village: ((passedVillage?.trim().isNotEmpty ?? false) ? passedVillage : (info['village']?.toString() ?? headDetails['village']?.toString())),
            mobileOwner: (info['mobileOwner']?.toString() ?? headDetails['mobileOwner']?.toString()),
            otherReligion: (info['other_religion']?.toString() ?? headDetails['other_religion']?.toString() ?? info['otherReligion']?.toString() ?? headDetails['otherReligion']?.toString()),
            otherCategory: (info['other_category']?.toString() ?? headDetails['other_category']?.toString() ?? info['otherCategory']?.toString() ?? headDetails['otherCategory']?.toString()),

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
              village: ((passedVillage?.trim().isNotEmpty ?? false) ? passedVillage : (beneficiaryInfo['village']?.toString() ?? headDetails['village']?.toString())),
              mobileOwner: headDetails['mobileOwner']?.toString(),
              otherReligion: (headDetails['other_religion']?.toString() ?? headDetails['otherReligion']?.toString()),
              otherCategory: (headDetails['other_category']?.toString() ?? headDetails['otherCategory']?.toString()),
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
                  village: (beneficiaryInfo['village']?.toString() ?? headDetails['village']?.toString()),
                  mobileOwner: member['mobileOwner']?.toString(),
                  otherReligion: (member['other_religion']?.toString() ?? member['otherReligion']?.toString()),
                  otherCategory: (member['other_category']?.toString() ?? member['otherCategory']?.toString()),
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

      if ((passedVillage?.trim().isEmpty ?? true) && (beneficiaryData == null || (beneficiaryData.village == null || (beneficiaryData.village?.trim().isEmpty ?? true)))) {
        if (hhId != null && hhId.isNotEmpty) {
          String? villageNameFromBeneficiaries;
          final rowsByHh = await db.query(
            'beneficiaries_new',
            columns: ['beneficiary_info'],
            where: 'household_ref_key = ? AND is_deleted = 0',
            whereArgs: [hhId],
          );
          for (final r in rowsByHh) {
            final infoStr = r['beneficiary_info']?.toString() ?? '{}';
            Map<String, dynamic> info = {};
            try { info = Map<String, dynamic>.from(jsonDecode(infoStr)); } catch (_) {}
            final v1 = info['village_name']?.toString();
            final v2 = info['village']?.toString();
            final v = ((v1 ?? '').trim().isNotEmpty) ? v1 : v2;
            if ((v ?? '').trim().isNotEmpty) { villageNameFromBeneficiaries = v; break; }
          }
          if (villageNameFromBeneficiaries != null && villageNameFromBeneficiaries.trim().isNotEmpty) {
            beneficiaryData = BeneficiaryData(
              name: beneficiaryData?.name,
              gender: beneficiaryData?.gender,
              mobile: beneficiaryData?.mobile,
              rchId: beneficiaryData?.rchId,
              fatherName: beneficiaryData?.fatherName,
              motherName: beneficiaryData?.motherName,
              dateOfBirth: beneficiaryData?.dateOfBirth,
              religion: beneficiaryData?.religion,
              socialClass: beneficiaryData?.socialClass,
              uniqueKey: beneficiaryData?.uniqueKey,
              createdDate: beneficiaryData?.createdDate,
              weightGrams: beneficiaryData?.weightGrams,
              birthWeightGrams: beneficiaryData?.birthWeightGrams,
              birthCertificate: beneficiaryData?.birthCertificate,
              village: villageNameFromBeneficiaries,
              mobileOwner: beneficiaryData?.mobileOwner,
              otherReligion: beneficiaryData?.otherReligion,
              otherCategory: beneficiaryData?.otherCategory,
            );
          }
        }
      }

      if ((passedVillage?.trim().isEmpty ?? true) && (beneficiaryData == null || (beneficiaryData.village == null || (beneficiaryData.village?.trim().isEmpty ?? true)))) {
        String? villageName;
        final hhRows = await db.query(
          'households',
          where: 'unique_key = ? OR id = ?',
          whereArgs: [hhId, hhId],
          limit: 1,
        );
        if (hhRows.isNotEmpty) {
          final headId = hhRows.first['head_id']?.toString();
          if (headId != null && headId.isNotEmpty) {
            final headRows = await db.query(
              'beneficiaries_new',
              where: 'unique_key = ? AND is_deleted = 0',
              whereArgs: [headId],
              limit: 1,
            );
            if (headRows.isNotEmpty) {
              final infoStr2 = headRows.first['beneficiary_info']?.toString() ?? '{}';
              Map<String, dynamic> info2 = {};
              try {
                info2 = Map<String, dynamic>.from(jsonDecode(infoStr2));
              } catch (_) {}
              final head2 = (info2['head_details'] is Map)
                  ? Map<String, dynamic>.from(info2['head_details'])
                  : <String, dynamic>{};
              villageName = (info2['village']?.toString() ?? head2['village']?.toString());
            }
          }
        }
        if (villageName != null && villageName.trim().isNotEmpty) {
          beneficiaryData = BeneficiaryData(
            name: beneficiaryData?.name,
            gender: beneficiaryData?.gender,
            mobile: beneficiaryData?.mobile,
            rchId: beneficiaryData?.rchId,
            fatherName: beneficiaryData?.fatherName,
            motherName: beneficiaryData?.motherName,
            dateOfBirth: beneficiaryData?.dateOfBirth,
            religion: beneficiaryData?.religion,
            socialClass: beneficiaryData?.socialClass,
            uniqueKey: beneficiaryData?.uniqueKey,
            createdDate: beneficiaryData?.createdDate,
            weightGrams: beneficiaryData?.weightGrams,
            birthWeightGrams: beneficiaryData?.birthWeightGrams,
            birthCertificate: beneficiaryData?.birthCertificate,
            village: villageName,
            mobileOwner: beneficiaryData?.mobileOwner,
          );
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
      }
      final String? ownerLabel = () {
        final raw = data.mobileOwner?.toLowerCase() ?? '';
        if (raw.isEmpty) return null;
        final headLabel = l10n?.headOfFamily ?? 'Head of the family';
        final motherLabel = l10n?.mother ?? 'Mother';
        final fatherLabel = l10n?.father ?? 'Father';
        final otherLabel = l10n?.other ?? 'Other';
        if (raw.contains('head')) return headLabel;
        if (raw == 'self') return headLabel;
        if (raw == 'mother') return motherLabel;
        if (raw == 'father') return fatherLabel;
        return otherLabel;
      }();
      if (ownerLabel != null && ownerLabel.isNotEmpty) {
        bloc.add(WhoseMobileNumberChanged(ownerLabel));
      }
      if (data.fatherName != null) bloc.add(FatherNameChanged(data.fatherName!));
      if (data.motherName != null) bloc.add(MotherNameChanged(data.motherName!));
      if (data.rchId != null) bloc.add(RchIdChildChanged(data.rchId!));
      if (data.religion != null) bloc.add(ReligionChanged(data.religion!));
      if (data.religion != null && data.religion == 'Other') {
        final val = data.otherReligion?.trim();
        if (val != null && val.isNotEmpty) {
          bloc.add(CustomReligionChanged(val));
        }
      }
      if (data.socialClass != null) bloc.add(CasteChanged(data.socialClass!));
      if (data.socialClass != null && data.socialClass == 'Other') {
        final val = data.otherCategory?.trim();
        if (val != null && val.isNotEmpty) {
          bloc.add(CustomCasteChanged(val));
        }
      }
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
      if (data.birthCertificate != null && data.birthCertificate!.isNotEmpty) {
        bloc.add(BirthCertificateIssuedChanged(data.birthCertificate!));
      }
      if (data.village != null && data.village!.trim().isNotEmpty) {
        bloc.add(AddressChanged(data.village!.trim()));
      }
    } else if (args.isNotEmpty) {
      if (args['name'] != null) bloc.add(ChildNameChanged(args['name'].toString()));
      if (args['gender'] != null) bloc.add(GenderChanged(args['gender'].toString()));
      if (args['mobile'] != null) bloc.add(MobileNumberChanged(args['mobile'].toString()));
      if (args['fatherName'] != null) bloc.add(FatherNameChanged(args['fatherName'].toString()));
      if (args['rchId'] != null) bloc.add(RchIdChildChanged(args['rchId'].toString()));
      if (args['village'] != null && args['village'].toString().trim().isNotEmpty) {
        bloc.add(AddressChanged(args['village'].toString().trim()));
      }
    }
    List<String> _getMobileOwnerList(String gender) {
      const common = [];

      gender = gender.toLowerCase();

      if (gender == 'female') {
        return [
          'Self',
          'Husband',
          'Father',
          'Mother',
          'Son',
          'Daughter',
          'Father In Law',
          'Mother In Law',
          'Neighbour',
          'Relative',
          'Other',
        ];
      }

      if (gender == 'male') {
        return [
          'Self',
          'Wife',
          'Father',
          'Mother',
          'Son',
          'Daughter',
          'Father In Law',
          'Mother In Law',
          'Neighbour',
          'Relative',
          'Other',
        ];
      }

      if (gender == 'transgender') {
        return [
          'Self',
          'Husband',
          'Wife',
          'Father',
          'Mother',
          'Son',
          'Daughter',
          'Father In Law',
          'Mother In Law',
          'Neighbour',
          'Relative',
          'Other',
        ];
      }

      // Fallback if gender is unknown
      return [
        'Self',
        'Husband',
        'Wife',
        'Father',
        'Mother',
        'Son',
        'Daughter',
        'Father In Law',
        'Mother In Law',
        'Neighbour',
        'Relative',
        'Other',
        ...common,
      ];
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
                                    maxLength: 12,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(RchIdChildChanged(v)),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isNotEmpty) {
                                        final regex = RegExp(r'^\d{12}$');
                                        if (!regex.hasMatch(text)) {
                                          return _captureError(l10n?.rch_id_must_be_12_digits);
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 50,
                                  width: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: state.isSubmitting
                                        ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      ),
                                    )
                                        : RoundButton(
                                      title: l10n!.verify,
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
                              hintText: l10n?.enterSerialNumber,
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
                                  return _captureError(l10n?.pleaseEnterDob);
                                }
                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomDatePicker(
                              labelText: l10n?.registrationDateLabel ?? 'Date of Registration *',
                              initialDate: state.dateOfRegistration,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0), // End of current month
                              onDateChanged: (d) => bloc.add(DateOfRegistrationChanged(d)),
                              validator: (date) {
                                if (date == null) {
                                  return _captureError(l10n?.pleaseEnterDor);

                                }
                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: l10n?.childNameLabel ?? "Child's name *",
                              hintText: l10n?.enterFullNameChild,
                              initialValue: state.childName,
                              onChanged: (v) => bloc.add(ChildNameChanged(v)),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return _captureError(l10n!.enterFullNameChild);
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
                                    return _captureError(l10n?.pleaseEnterGender);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: "${l10n?.motherNameLabel} *" ?? "Mother's name*",
                              hintText: l10n?.enterMothersName,
                              initialValue: state.motherName,
                              onChanged: (v) => bloc.add(MotherNameChanged(v)),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return _captureError(l10n?.pleaseEnterMothersName);
                                }
                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: l10n?.fatherNameLabel ?? "Father's name",
                              hintText: l10n?.fatherNameHint,
                              initialValue: state.fatherName,
                              onChanged: (v) => bloc.add(FatherNameChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: "${l10n?.addressLabel} *" ?? 'Address',
                              hintText:l10n?.enterAddress,
                              initialValue: state.address,
                              onChanged: (v) => bloc.add(AddressChanged(v)),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return _captureError(l10n?.pleaseEnterAddress);
                                }
                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: ApiDropdown<String>(
                                labelText: "${l10n?.whoseMobileLabel} *" ?? 'Whose mobile number is this',
                                items: _getMobileOwnerList(state.gender ?? ''),
                                getLabel: (s) {
                                  switch (s) {
                                    case 'Self':
                                      return "${l10n?.self}";

                                    case 'Husband':
                                      return '${l10n?.husbandLabel} ';

                                    case 'Mother':
                                      return '${l10n?.mother} ';

                                    case 'Father':
                                      return '${l10n?.father}';

                                    case 'Wife':
                                      return '${l10n?.wife} ';

                                    case 'Son':
                                      return '${l10n?.son}';

                                    case 'Daughter':
                                      return '${l10n?.daughter} ';

                                    case 'Mother In Law':
                                      return '${l10n?.motherInLaw} ';

                                    case 'Father In Law':
                                      return '${l10n?.fatherInLaw}';

                                    case 'Neighbour':
                                      return '${l10n?.neighbour} ';

                                    case 'Relative':
                                      return "${l10n?.relative} ";

                                    case 'Other':
                                      return '${l10n?.other} ';

                                    default:
                                      return s;
                                  }
                                },
                                value: state.whoseMobileNumber.isEmpty ? null : state.whoseMobileNumber,

                                onChanged: (v) => bloc.add(WhoseMobileNumberChanged(v ?? '')),
                                hintText: l10n!.select ?? 'Select',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _captureError(l10n?.pleaseEnterWhoseMobileNumber);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: "${l10n?.mobileNumberLabel} *" ?? 'Mobile number *',
                              hintText: l10n?.enter10DigitMobileNumber,
                              initialValue: state.mobileNumber,
                              keyboardType: TextInputType.phone,
                              onChanged: (v) => bloc.add(MobileNumberChanged(v)),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return _captureError(l10n?.pleaseEnterMobileNumber);
                                }
                                final regex = RegExp(r'^[6-9]\d{9}$');
                                if (!regex.hasMatch(text)) {
                                  return _captureError(l10n?.mobileMustBe10DigitsAndStartWith);
                                }
                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Expanded(
                                  child: CustomTextField(
                                    labelText: l10n?.mothersRchIdLabel ?? "Mother's RCH ID number",
                                    hintText: l10n?.mothersRchIdLabel,
                                    initialValue: state.mothersRchIdNumber,
                                    maxLength: 12,
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => bloc.add(MothersRchIdNumberChanged(v)),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isNotEmpty) {
                                        final regex = RegExp(r'^\d{12}$');
                                        if (!regex.hasMatch(text)) {
                                          return _captureError("Mother's RCH ID must be exactly 12 digits");
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                // const SizedBox(width: 10),
                                // SizedBox(
                                //   height: 50,
                                //   width: 80,
                                //   child: Padding(
                                //     padding: const EdgeInsets.only(top: 20),
                                //     child: state.isSubmitting
                                //         ? const Center(
                                //       child: SizedBox(
                                //         width: 24,
                                //         height: 24,
                                //         child: CircularProgressIndicator(strokeWidth: 3),
                                //       ),
                                //     )
                                //         : RoundButton(
                                //       title: l10n!.verify,
                                //       borderRadius: 8,
                                //       fontSize: 12,
                                //       onPress: () {
                                //         // Add verification logic here
                                //       },
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ApiDropdown<String>(
                                labelText: l10n?.birthCertificateIssuedLabel ?? 'Has the birth certificate been issued?',
                                items: [l10n?.yes ?? 'Yes', l10n?.no ?? 'No'],
                                value: _beneficiaryData?.birthCertificate?.isNotEmpty == true
                                    ? _beneficiaryData?.birthCertificate
                                    : (state.birthCertificateIssued.isEmpty ? null : state.birthCertificateIssued),
                                getLabel: (s) => s,
                                onChanged: (v) => bloc.add(BirthCertificateIssuedChanged(v ?? '')),
                                hintText: l10n?.select ?? 'choose',
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText: l10n?.birthCertificateNumberLabel ?? 'Birth Certificate Number',
                              hintText: l10n?.enterBirthCertificateNumber,
                              initialValue: state.birthCertificateNumber,
                              onChanged: (v) => bloc.add(BirthCertificateNumberChanged(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText:l10n?.child_weight,
                              hintText: l10n?.enterWeight,
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
                                  return _captureError(l10n?.enterValidWeight);
                                }

                                if (parsed < 500 || parsed > 12500) {
                                  return _captureError(l10n?.weightRangeError);
                                }

                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            CustomTextField(
                              labelText:l10n?.birthWeightRange,
                              hintText:l10n?.enterBirthWeight,
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
                                  return _captureError(l10n?.enterValidBirthWeight);
                                }

                                if (parsed < 1200 || parsed > 4000) {
                                  return _captureError(l10n?.enterValidBirthWeight);
                                }

                                return null;
                              },
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ApiDropdown<String>(
                                    labelText: l10n?.religionLabel ?? 'Religion',
                                    items: [
                                      l10n?.religionHindu ?? 'Hindu',
                                      l10n?.religionMuslim ?? 'Muslim',
                                      l10n?.religionChristian ?? 'Christian',
                                      l10n?.religionSikh ?? 'Sikh',
                                      l10n?.religionBuddhism ?? 'Buddism',
                                     l10n?.religionJainism ?? 'Jainism',
                                      l10n?.religionParsi ?? 'Parsi',
                                      l10n?.religionNotDisclosed ?? 'Do not want to disclose',
                                      l10n?.other ?? 'Other',
                                    ],
                                    value: state.religion.isEmpty ? null : state.religion,
                                    getLabel: (s) => s,
                                    onChanged: (v) {
                                      bloc.add(ReligionChanged(v ?? ''));
                                      // Clear custom religion when changing from 'Other' to something else
                                      if (v != 'Other') {
                                        bloc.add(CustomReligionChanged(''));
                                      }
                                    },
                                    hintText: l10n?.select ?? 'choose',
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                  if (state.religion == 'Other')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: CustomTextField(
                                        labelText: l10n?.specifyReligionLabel,
                                        hintText: l10n?.enterReligion,
                                        initialValue: state.customReligion,
                                        onChanged: (v) => bloc.add(CustomReligionChanged(v)),
                                        validator: (value) {
                                          if (state.religion == 'Other' && (value == null || value.trim().isEmpty)) {
                                            return l10n?.pleaseSpecifyReligion;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                            // Caste Dropdown with Other Option
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ApiDropdown<String>(
                                    labelText: 'Category',
                                    items: [
                                      'Do not want to disclose',
                                      'General',
                                      'OBC',
                                      'SC',
                                      'ST',
                                      'Pichda Varg 1',
                                      'Pichda Varg 2',
                                      'Atyant Pichda Varg',
                                      "Don't Know",
                                      "Other",
                                    ],
                                    value: state.caste.isEmpty ? null : state.caste,
                                    getLabel: (s) => s,
                                    onChanged: (v) {
                                      bloc.add(CasteChanged(v ?? ''));
                                      // Clear custom caste when changing from 'Other' to something else
                                      if (v != 'Other') {
                                        bloc.add(CustomCasteChanged(''));
                                      }
                                    },
                                    hintText: l10n!.select ?? 'choose',
                                  ),
                                  Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                                  if (state.caste == 'Other')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: CustomTextField(
                                        labelText: l10n.specifyCategoryShort,
                                        hintText: l10n.enter_category,
                                        initialValue: state.customCaste,
                                        onChanged: (v) => bloc.add(CustomCasteChanged(v)),
                                        validator: (value) {
                                          if (state.caste == 'Other' && (value == null || value.trim().isEmpty)) {
                                            return l10n.specifyCategory;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.5, height: 0),
                          ],
                        ),
                      ),
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: SizedBox(
                          height: 34,
                          child: RoundButton(
                            title: state.isSubmitting ? (l10n?.savingButton ?? 'SAVING...') : (l10n?.saveButton ?? 'SAVE'),
                            color: AppColors.primary,
                            borderRadius: 4,
                            onPress: () {
                              _clearFirstError();
                              final form = _formKey.currentState;
                              if (form == null) return;

                              final isValid = form.validate();
                              if (!isValid) {
                                final msg = _firstError ?? l10n.correctHighlightedFields;
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
