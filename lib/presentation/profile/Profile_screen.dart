import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

import '../../core/widgets/Dropdown/dropdown.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/profile_bloc.dart';
import '../../core/widgets/DatePicker/DatePicker.dart';
import '../../core/widgets/RoundButton/RoundButton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  List<Country> countries = [
    Country(id: 1, name: 'India'),
    Country(id: 2, name: 'USA'),
    Country(id: 3, name: 'UK'),
  ];
  Country? selectedCountry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => ProfileBloc(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppHeader(screenTitle: l10n.ashaProfile, showBack: true),
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
                  CustomTextField(
                    labelText: l10n.ashaNameLabel,
                    hintText: l10n.ashaNameHint,
                    onChanged: (v) => bloc.add(AshaNameChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  const SizedBox(height: 4),
                  CustomDatePicker(
                    labelText: l10n.dobLabel,
                    initialDate: state.dob,
                    isEditable: true,
                    hintText: l10n.dateHint,
                    onDateChanged: (d) => bloc.add(DobChanged(d)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  const SizedBox(height: 4),
                  CustomTextField(
                    labelText: l10n.ageLabel,
                    hintText: '${state.ageYears} ${l10n.yearsSuffix}',
                    readOnly: true,
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
                    hintText: l10n.dateHint,
                    onDateChanged: (d) => bloc.add(DojChanged(d)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),

                  const SizedBox(height: 12),
                  Text(l10n.bankDetailsTitle, style: Theme.of(context).textTheme.titleMedium),
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
                  CustomTextField(
                    labelText: l10n.stateLabel,
                    hintText: l10n.stateHint,
                    onChanged: (v) => bloc.add(StateChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.divisionLabel,
                    hintText: l10n.divisionHint,
                    onChanged: (v) => bloc.add(DivisionChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.districtLabel,
                    hintText: l10n.districtHint,
                    onChanged: (v) => bloc.add(DistrictChanged(v)),
                  ),
                  Divider(color: AppColors.divider, thickness: 0.5),
                  CustomTextField(
                    labelText: l10n.blockLabel,
                    hintText: l10n.blockHint,
                    onChanged: (v) => bloc.add(BlockChanged(v)),
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
    );
  }
}
class Country {
  final int id;
  final String name;

  Country({required this.id, required this.name});
}
