import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/Dropdown/Dropdown.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/utils/Validations.dart';
import 'bloc/children_bloc.dart';
import '../HeadDetails/bloc/add_family_head_bloc.dart' as head_bloc;
import '../../AddNewFamilyMember/bloc/addnewfamilymember_bloc.dart' as member_bloc;

class Childrendetaills extends StatefulWidget {
  const Childrendetaills({super.key});

  @override
  State<Childrendetaills> createState() => _ChildrendetaillsState();
}

class _ChildrendetaillsState extends State<Childrendetaills> {
  String? _youngestAgeError;

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
          Expanded(child: Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),)),
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
          context.read<head_bloc.AddFamilyHeadBloc>()
              .add(head_bloc.ChildrenChanged(state.totalLive.toString()));
        } catch (_) {}
        try {
          context.read<member_bloc.AddnewfamilymemberBloc>()
              .add(member_bloc.ChildrenChanged(state.totalLive.toString()));
        } catch (_) {}
      },
      child: BlocBuilder<ChildrenBloc, ChildrenState>(
        builder: (context, state) {
          String? _validateYoungestAge(String raw, {String? overrideUnit}) {
            final unit = overrideUnit ?? state.ageUnit;
            
            if (raw.isNotEmpty && raw.trim().isNotEmpty) {
              if (unit == null || unit.isEmpty) {
                return 'Please select age unit';
              }
              
              final msg = Validations.validateYoungestChildAge(l, raw, unit);
              
              if (msg != null) {
                if (msg.startsWith(l.selectAgeUnit)) {
                  return null;
                }
                return l.selectAgeUnit;
              }
            }
            
            return null;
          }
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
                        onChanged: (v) {
                          context.read<ChildrenBloc>().add(ChUpdateYoungestAge(v.trim()));
                          setState(() {
                            _youngestAgeError = _validateYoungestAge(v);
                          });
                        },
                        initialValue: state.youngestAge,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 52,
                      height: 36,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        onChanged: (value) {
                          context.read<ChildrenBloc>().add(ChUpdateYoungestAge(value.trim()));
                          setState(() {
                            _youngestAgeError = _validateYoungestAge(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_youngestAgeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Text(
                    _youngestAgeError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              Divider(color: AppColors.divider, thickness: 0.5, height: 0),

              _section(
                ApiDropdown<String>(
                  labelText: l.ageUnitOfYoungest,
                  items: [l.days, l.months, l.years],
                  getLabel: (s) => s,
                  value: state.ageUnit,
                  onChanged: (v) {
                    context.read<ChildrenBloc>().add(ChUpdateAgeUnit(v));
                    setState(() {
                      _youngestAgeError = _validateYoungestAge(
                        state.youngestAge ?? '',
                        overrideUnit: v,
                      );
                    });
                  },                ),
              ),
              Divider(color: AppColors.divider, thickness: 0.5, height: 0),


                _section(
                  ApiDropdown<String>(
                    labelText: l.genderOfYoungest,
                    items: const ['Male', 'Female','Transgender'],
                    getLabel: (s) {
                      switch (s) {
                        case 'Male':
                          return l.genderMale;
                        case 'Female':
                          return l.genderFemale;
                        case 'Transgender':
                          return l.transgender;
                        default:
                          return s;
                      }
                    },
                    value: state.youngestGender,
                    onChanged: (v) {
                      context.read<ChildrenBloc>().add(ChUpdateYoungestGender(v));
                      // Trigger validation when gender changes
                      setState(() {
                        _youngestAgeError = _validateYoungestAge(state.youngestAge ?? '');
                      });
                    },
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
