import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'bloc/eligible_coule_update_bloc.dart';

class EligibleCoupleUpdateScreen extends StatelessWidget {
  const EligibleCoupleUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EligibleCouleUpdateBloc(),
      child: const _EligibleCoupleUpdateView(),
    );
  }
}

class _CountBox extends StatelessWidget {
  final Widget child;
  const _CountBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Center(child: child),
    );
  }
}

class _EligibleCoupleUpdateView extends StatelessWidget {
  const _EligibleCoupleUpdateView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        screenTitle: 'Eligible Couple',
        showBack: true,
      ),
      body: SafeArea(
        child: BlocConsumer<EligibleCouleUpdateBloc, EligibleCouleUpdateState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated successfully')),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<EligibleCouleUpdateBloc>();

            Widget _buildCountBoxField(String value, Function(String) onChanged) {
              return SizedBox(
                width: 40,
                height: 40,
                child: _CountBox(
                  child: TextField(
                    controller: TextEditingController(text: value),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Registration through', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: 'RCH ID',
                          initialValue: state.rchId,
                          onChanged: (v) => bloc.add(RchIdChanged(v)),
                          keyboardType: TextInputType.number,
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5, height: 0,),
                        CustomDatePicker(
                          labelText: 'Registration Date',
                          initialDate: state.registrationDate,
                          onDateChanged: (d) => bloc.add(RegistrationDateChanged(d)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: 'Name of woman *',
                          initialValue: state.womanName,
                          onChanged: (v) => bloc.add(WomanNameChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: 'Current age(in years) *',
                          initialValue: state.currentAge,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => bloc.add(CurrentAgeChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: 'Age at marriage(in years)',
                          initialValue: state.ageAtMarriage,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => bloc.add(AgeAtMarriageChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: 'Address',
                          initialValue: state.address,
                          maxLines: 2,
                          onChanged: (v) => bloc.add(AddressChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: 'Whose mobile no.',
                          items: const ['Husband', 'Wife', 'Other'],
                          value: state.whoseMobile.isEmpty ? null : state.whoseMobile,
                          getLabel: (s) => s,
                          onChanged: (v) => bloc.add(WhoseMobileChanged(v ?? '')),
                          hintText: 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: 'Mobile no. *',
                          initialValue: state.mobileNo,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          onChanged: (v) => bloc.add(MobileNoChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: 'Religion',
                          items: const ['Hindu', 'Muslim', 'Christian', 'Sikh', 'Other'],
                          value: state.religion.isEmpty ? null : state.religion,
                          getLabel: (s) => s,
                          onChanged: (v) => bloc.add(ReligionChanged(v ?? '')),
                          hintText: 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: 'Category',
                          items: const ['General', 'OBC', 'SC', 'ST', 'Other'],
                          value: state.category.isEmpty ? null : state.category,
                          getLabel: (s) => s,
                          onChanged: (v) => bloc.add(CategoryChanged(v ?? '')),
                          hintText: 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        const SizedBox(height: 12),

                        Text('Children Details', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),



                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: Text('Total number of children born')),
                                  _buildCountBoxField(state.totalChildrenBorn, (v) => bloc.add(TotalChildrenBornChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: Text('Total number of live children')),
                                  _buildCountBoxField(state.totalLiveChildren, (v) => bloc.add(TotalLiveChildrenChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: Text('Total number of male children')),
                                  _buildCountBoxField(state.totalMaleChildren, (v) => bloc.add(TotalMaleChildrenChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: Text('Total number of female children')),
                                  _buildCountBoxField(state.totalFemaleChildren, (v) => bloc.add(TotalFemaleChildrenChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(child: Text('Age of youngest child')),
                                  _buildCountBoxField(state.youngestChildAge, (v) => bloc.add(YoungestChildAgeChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),

                        ApiDropdown<String>(
                          labelText: 'Age of youngest child unit',
                          items: const ['Years', 'Months'],
                          value: state.youngestChildAgeUnit.isEmpty ? null : state.youngestChildAgeUnit,
                          getLabel: (s) => s,
                          onChanged: (v) => bloc.add(YoungestChildAgeUnitChanged(v ?? '')),
                          hintText: 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: 'Gender of youngest child',
                          items: const ['Male', 'Female'],
                          value: state.youngestChildGender.isEmpty ? null : state.youngestChildGender,
                          getLabel: (s) => s,
                          onChanged: (v) => bloc.add(YoungestChildGenderChanged(v ?? '')),
                          hintText: 'Select',
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: RoundButton(
                      title: state.isSubmitting ? 'UPDATING...' : 'UPDATE',
                      onPress: () => context.read<EligibleCouleUpdateBloc>().add(const SubmitPressed()),
                      disabled: state.isSubmitting,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
