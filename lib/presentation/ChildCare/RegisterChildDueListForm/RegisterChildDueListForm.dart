import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'bloc/register_child_form_bloc.dart';

class RegisterChildDueListFormScreen extends StatelessWidget {
  const RegisterChildDueListFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => RegisterChildFormBloc(),
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.registrationDue ?? 'registration due',
          showBack: true,
        ),
        body: SafeArea(
          child: BlocConsumer<RegisterChildFormBloc, RegisterChildFormState>(
            listener: (context, state) {
              if (state.error != null && state.error!.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!)),
                );
              }
              if (state.isSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n?.saveSuccess ?? 'Saved successfully')),
                );
              }
            },
            builder: (context, state) {
              final bloc = context.read<RegisterChildFormBloc>();
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: Text(l10n?.description ?? 'Description', style: TextStyle(fontSize: 20),)),
                          Divider(color: AppColors.primary, thickness: 1, height: 0),

                          const SizedBox(height: 8),

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
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomDatePicker(
                            labelText: l10n?.dateOfRegistrationLabel ?? 'Date of Registration *',
                            initialDate: state.dateOfRegistration,
                            onDateChanged: (d) => bloc.add(DateOfRegistrationChanged(d)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.childNameLabel ?? "Child's name *",
                            hintText: 'Enter full name of the child',
                            initialValue: state.childName,
                            onChanged: (v) => bloc.add(ChildNameChanged(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ApiDropdown<String>(
                              labelText: l10n?.genderLabel ?? 'gender',
                              items: [l10n?.male ?? 'Male', l10n?.female ?? 'Female', l10n?.other ?? 'Other'],
                              value: state.gender.isEmpty ? null : state.gender,
                              getLabel: (s) => s,
                              onChanged: (v) => bloc.add(GenderChanged(v ?? '')),
                              hintText: l10n?.select ?? 'Select',
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.motherNameLabel ?? "Mother's name*",
                            hintText: 'Enter mother\'s  name',
                            initialValue: state.motherName,
                            onChanged: (v) => bloc.add(MotherNameChanged(v)),
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
                            labelText: l10n?.addressLabel ?? 'Address',
                            hintText: 'Enter address ',
                            initialValue: state.address,
                            onChanged: (v) => bloc.add(AddressChanged(v)),
                            maxLines: 2,
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
                            ),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.5, height: 0),

                          CustomTextField(
                            labelText: l10n?.mobileNumberLabel ?? 'Mobile number *',
                            hintText: 'Enter 10-digit mobile number',
                            initialValue: state.mobileNumber,
                            keyboardType: TextInputType.phone,
                            onChanged: (v) => bloc.add(MobileNumberChanged(v)),
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
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: SizedBox(
                        height: 44,
                        child: RoundButton(
                          title: state.isSubmitting ? (l10n?.savingButton ?? 'SAVING...') : (l10n?.saveButton ?? 'SAVE'),
                          color: AppColors.primary,
                          borderRadius: 8,
                          onPress: () => bloc.add(const SubmitPressed()),
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
}
