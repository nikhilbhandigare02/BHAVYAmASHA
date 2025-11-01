import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../../core/config/themes/CustomColors.dart';
import 'bloc/children_bloc.dart';
import '../HeadDetails/bloc/add_family_head_bloc.dart';

class Childrendetaills extends StatefulWidget {
  const Childrendetaills({super.key});

  @override
  State<Childrendetaills> createState() => _ChildrendetaillsState();
}

class _ChildrendetaillsState extends State<Childrendetaills> {
  Widget _section(Widget child) => child;

  Widget _counterRow({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14.sp),)),
          Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: RoundButton(title: '-', onPress: onMinus),
              ),
              const SizedBox(width: 8),
              Container(
                width: 52,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$value', style: TextStyle(fontSize: 14.sp),),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: RoundButton(title: '+', onPress: onPlus),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocListener<ChildrenBloc, ChildrenState>(
      listener: (context, state) {
        try {
          context.read<AddFamilyHeadBloc>().add(ChildrenChanged(state.totalLive.toString()));
        } catch (_) {}
      },
      child: BlocBuilder<ChildrenBloc, ChildrenState>(
        builder: (context, state) {
          return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              children: [
              _section(
                _counterRow(
                  label: l.totalChildrenBorn,
                  value: state.totalBorn,
                  onMinus: () => context.read<ChildrenBloc>().add(ChDecrementBorn()),
                  onPlus: () => context.read<ChildrenBloc>().add(ChIncrementBorn()),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                _counterRow(
                  label: l.totalLiveChildren,
                  value: state.totalLive,
                  onMinus: () => context.read<ChildrenBloc>().add(ChDecrementLive()),
                  onPlus: () => context.read<ChildrenBloc>().add(ChIncrementLive()),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                _counterRow(
                  label: l.totalMaleChildren,
                  value: state.totalMale,
                  onMinus: () => context.read<ChildrenBloc>().add(ChDecrementMale()),
                  onPlus: () => context.read<ChildrenBloc>().add(ChIncrementMale()),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                _counterRow(
                  label: l.totalFemaleChildren,
                  value: state.totalFemale,
                  onMinus: () => context.read<ChildrenBloc>().add(ChDecrementFemale()),
                  onPlus: () => context.read<ChildrenBloc>().add(ChIncrementFemale()),
                ),
              ),
              if (state.totalLive > 0 && (state.totalMale + state.totalFemale) != state.totalLive)
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 4, bottom: 8),
                  child: Text(
                    l.malePlusFemaleError,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        labelText: l.youngestChildAge,
                        hintText: l.youngestChildAge,
                        readOnly: true,
                        onChanged: (v) => context.read<ChildrenBloc>().add(ChUpdateYoungestAge(v.trim())),
                        initialValue: state.youngestAge,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        onChanged: (value) {
                          context.read<ChildrenBloc>().add(ChUpdateYoungestAge(value.trim()));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                ApiDropdown<String>(
                  labelText: l.ageUnitOfYoungest,
                  items: [l.days, l.months, l.years],
                  getLabel: (s) => s,
                  value: state.ageUnit,
                  onChanged: (v) => context.read<ChildrenBloc>().add(ChUpdateAgeUnit(v)),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                ApiDropdown<String>(
                  labelText: l.genderOfYoungest,
                  items: const ['Male', 'Female'],
                  getLabel: (s) {
                    switch (s) {
                      case 'Male':
                        return l.genderMale;
                      case 'Female':
                        return l.genderFemale;
                      default:
                        return s;
                    }
                  },
                  value: state.youngestGender,
                  onChanged: (v) => context.read<ChildrenBloc>().add(ChUpdateYoungestGender(v)),
                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),
            ],
          );
        },
      ),
    );
  }
}
