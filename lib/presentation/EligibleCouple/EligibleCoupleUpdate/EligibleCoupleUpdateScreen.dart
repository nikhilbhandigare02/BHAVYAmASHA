import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/DatePicker/DatePicker.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'bloc/eligible_coule_update_bloc.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: t?.eligibleCoupleUpdateTitle ?? 'Eligible Couple',
        showBack: true,
      ),
      body: SafeArea(
        child: BlocConsumer<EligibleCouleUpdateBloc, EligibleCouleUpdateState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),);
            }
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t?.profileUpdated ?? 'Updated successfully')),
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
                        Text(t?.registrationThroughTitle ?? 'Registration through', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        CustomTextField(
                          labelText: t?.rchIdLabel ?? 'RCH ID',
                          hintText: t?.rchIdLabel ?? 'RCH ID',
                          initialValue: state.rchId,
                          onChanged: (v) => bloc.add(RchIdChanged(v)),
                          keyboardType: TextInputType.number,
                        ),
                        // Divider(color: AppColors.divider, thickness: 0.5, height: 0,),
                        // CustomDatePicker(
                        //   labelText: t?.registrationDateLabel ?? 'Registration Date',
                        //   initialDate: state.registrationDate,
                        //   onDateChanged: (d) => bloc.add(RegistrationDateChanged(d)),
                        // ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: (t?.nameOfWomanLabel ?? 'Name of woman') + ' *',
                          hintText: (t?.nameOfWomanLabel ?? 'Name of woman') + ' *',
                          initialValue: state.womanName,
                          onChanged: (v) => bloc.add(WomanNameChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: (t?.currentAgeLabel ?? 'Current age (in years)') + ' *',
                          hintText: (t?.currentAgeLabel ?? 'Current age (in years)') + ' *',
                          initialValue: state.currentAge,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => bloc.add(CurrentAgeChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: t?.ageAtMarriageInYearsLabel ?? 'Age at marriage (in years)',
                          hintText: t?.ageAtMarriageInYearsLabel ?? 'Age at marriage (in years)',
                          initialValue: state.ageAtMarriage,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => bloc.add(AgeAtMarriageChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: t?.addressLabel ?? 'Address',
                          hintText: t?.addressLabel ?? 'Address',
                          initialValue: state.address,
                          maxLines: 2,
                          onChanged: (v) => bloc.add(AddressChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: t?.whoseMobileLabel ?? 'Whose mobile no.',
                          items: const [
                            'Self',
                            'Wife',
                            'Father',
                            'Mother',
                            'Son',
                            'Daughter',
                            'Father in Law',
                            'Mother in Law',
                            'Neighbour',
                            'Relative',
                            'Other',
                          ],
                          getLabel: (s) {
                            switch (s) {
                              case 'Self':
                                return t!.self;
                              case 'Wife':
                                return t!.wife;
                              case 'Father':
                                return t!.father;
                              case 'Mother':
                                return t!.mother;
                              case 'Son':
                                return t!.son;
                              case 'Daughter':
                                return t!.daughter;
                              case 'Father in Law':
                                return t!.fatherInLaw;
                              case 'Mother in Law':
                                return t!.motherInLaw;
                              case 'Neighbour':
                                return t!.neighbour;
                              case 'Relative':
                                return t!.relative;
                              case 'Other':
                                return t!.other;
                              default:
                                return s;
                            }
                          },
                          value: state.whoseMobile.isEmpty ? null : state.whoseMobile,
                          onChanged: (v) => bloc.add(WhoseMobileChanged(v ?? '')),
                          hintText: t?.select ?? 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        CustomTextField(
                          labelText: (t?.mobileLabelSimple ?? 'Mobile no.') + ' *',
                          hintText: (t?.mobileLabelSimple ?? 'Mobile no.') + ' *',
                          initialValue: state.mobileNo,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          onChanged: (v) => bloc.add(MobileNoChanged(v)),
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: t?.religionLabel ?? 'Religion',
                          items: const ['Do not want to disclose', 'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhism', 'Jainism', 'Parsi', 'Other'],
                          getLabel: (s) {
                            switch (s) {
                              case 'Do not want to disclose':
                                return t!.religionNotDisclosed;
                              case 'Hindu':
                                return t!.religionHindu;
                              case 'Muslim':
                                return t!.religionMuslim;
                              case 'Christian':
                                return t!.religionChristian;
                              case 'Sikh':
                                return t!.religionSikh;
                              case 'Buddhism':
                                return t!.religionBuddhism;
                              case 'Jainism':
                                return t!.religionJainism;
                              case 'Parsi':
                                return t!.religionParsi;
                              case 'Other':
                                return t!.religionOther;
                              default:
                                return s;
                            }
                          },
                          value: state.religion.isEmpty ? null : state.religion,

                          onChanged: (v) => bloc.add(ReligionChanged(v ?? '')),
                          hintText: t?.select ?? 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: t?.categoryLabel ?? 'Category',
                          items: const ['NotDisclosed', 'General', 'OBC', 'SC', 'ST', 'PichdaVarg1', 'PichdaVarg2', 'AtyantPichdaVarg', 'DontKnow', 'Other'],
                          getLabel: (s) {
                            switch (s) {
                              case 'NotDisclosed':
                                return t!.categoryNotDisclosed;
                              case 'General':
                                return t!.categoryGeneral;
                              case 'OBC':
                                return t!.categoryOBC;
                              case 'SC':
                                return t!.categorySC;
                              case 'ST':
                                return t!.categoryST;
                              case 'PichdaVarg1':
                                return t!.categoryPichdaVarg1;
                              case 'PichdaVarg2':
                                return t!.categoryPichdaVarg2;
                              case 'AtyantPichdaVarg':
                                return t!.categoryAtyantPichdaVarg;
                              case 'DontKnow':
                                return t!.categoryDontKnow;
                              case 'Other':
                                return t!.religionOther;
                              default:
                                return s;
                            }
                          },
                          value: state.category.isEmpty ? null : state.category,
                          onChanged: (v) => bloc.add(CategoryChanged(v ?? '')),
                          hintText: t?.select ?? 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        const SizedBox(height: 12),

                        Text(t?.childrenDetailsTitle ?? 'Children Details', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),



                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: Text(t?.totalChildrenBornLabel ?? 'Total number of children born', style: TextStyle(fontSize: 15.sp),)),
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
                                  Expanded(child: Text(t?.totalLiveChildrenLabel ?? 'Total number of live children',style: TextStyle(fontSize: 15.sp))),
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
                                  Expanded(child: Text(t?.totalMaleChildrenLabel ?? 'Total number of male children',style: TextStyle(fontSize: 15.sp))),
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
                                  Expanded(child: Text(t?.totalFemaleChildrenLabel ?? 'Total number of female children',style: TextStyle(fontSize: 15.sp))),
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
                                  Expanded(child: Text(t?.youngestChildAgeLabel ?? 'Age of youngest child')),
                                  _buildCountBoxField(state.youngestChildAge, (v) => bloc.add(YoungestChildAgeChanged(v))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Divider(color: AppColors.divider, thickness: 0.5,height: 0,),

                        ApiDropdown<String>(
                          labelText: t?.youngestChildAgeUnitLabel ?? 'Age of youngest child unit',
                          items: const ['Years', 'Months', 'Day'],
                          value: state.youngestChildAgeUnit.isEmpty ? null : state.youngestChildAgeUnit,
                          getLabel: (s) {
                            switch (s) {
                              case 'Years':
                                return t!.years;
                              case 'Months':
                                return t!.months;
                              case 'Day':
                                return t!.days;
                              default:
                                return s;
                            }
                          },
                          onChanged: (v) => bloc.add(YoungestChildAgeUnitChanged(v ?? '')),
                          hintText: t?.select ?? 'Select',
                        ),
                        Divider(color: AppColors.divider, thickness: 0.5,height: 0,),
                        ApiDropdown<String>(
                          labelText: t?.youngestChildGenderLabel ?? 'Gender of youngest child',
                          items: const ['Male', 'Female','Transgender'],
                          value: state.youngestChildGender.isEmpty ? null : state.youngestChildGender,
                          getLabel: (s) {
                            switch (s) {
                              case 'Male':
                                return t!.genderMale;
                              case 'Female':
                                return t!.genderFemale;
                              case 'Transgender':
                                return t!.transgender;
                              default:
                                return s;
                            }
                          },
                          onChanged: (v) => bloc.add(YoungestChildGenderChanged(v ?? '')),
                          hintText: t?.select ?? 'Select',
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
                      title: state.isSubmitting ? 'UPDATING...' : (t?.updateButton ?? 'UPDATE'),
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
