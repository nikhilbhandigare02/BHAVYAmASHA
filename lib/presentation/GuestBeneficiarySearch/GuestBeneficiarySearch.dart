import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/Dropdown/dropdown.dart';
import 'package:medixcel_new/core/widgets/TextField/TextField.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/repositories/GuestBeneficiaryRepository.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/SnackBar/app_snackbar.dart';
import '../myBeneficiary/Beneficiaries/GuestBeneficiaries.dart';
import 'bloc/guest_beneficiary_search_bloc.dart';
import 'bloc/guest_beneficiary_search_event.dart';
import 'bloc/guest_beneficiary_search_state.dart';

class GuestBeneficiarySearch extends StatefulWidget {
  const GuestBeneficiarySearch({super.key});

  @override
  State<GuestBeneficiarySearch> createState() => _GuestBeneficiarySearchState();
}

class _GuestBeneficiarySearchState extends State<GuestBeneficiarySearch> {
  final List<String> districts = const ['Patna', 'Maner'];
  final List<String> categories = const ['ANC', 'PNC', 'RI',];
  final List<String> genders = const ['Male', 'Female', 'Transgender'];
  final List<String> blocks = const [];

  // Build search results widget
  Widget _buildSearchResults(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      entry.value?.toString() ?? 'N/A',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 12),
            // Log the full response for debugging
            OutlinedButton(
              onPressed: () {
                log('Full response data: $data');

                showAppSnackBar(context, 'Check console for full response data'!);

              },
              child: const Text('View Raw Data (Check Console)'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => GuestBeneficiarySearchBloc(
        repo: GuestBeneficiaryRepository(),
      ),
      child: Builder(builder: (context) {
        // Add listener for state changes
        return BlocListener<GuestBeneficiarySearchBloc, GuestBeneficiarySearchState>(
          listener: (context, state) {
            // Handle error state
            if (state.status == GbsStatus.failure && state.errorMessage != null) {

              showAppSnackBar(context, state.errorMessage!);

            }
            // Handle success state
            else if (state.status == GbsStatus.success) {
              log('✅ Search completed successfully');
              // Navigate to GuestBeneficiaries screen after a short delay to show success state
              Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Guestbeneficiaries(),
                  ),
                );
              });
            }
          },
          child:
          Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppHeader(
            screenTitle: l10n.guestSearchTitle,
            showBack: true,
          ),
          body: BlocBuilder<GuestBeneficiarySearchBloc, GuestBeneficiarySearchState>(
            builder: (context, state) {
              // Show loading indicator when searching
              if (state.status == GbsStatus.loading) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Search Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            labelText: l10n.beneficiaryNumberLabel,
                            hintText: '',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateBeneficiaryNo(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.6),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Text(
                                l10n.or,
                                style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          ApiDropdown<String>(
                            labelText: l10n.districtLabelSimple,
                            items: districts,
                            value: state.district,
                            getLabel: (s) => s,
                            hintText: l10n.select,
                            onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateDistrict(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.6),
                          ApiDropdown<String>(
                            labelText: l10n.blockLabelSimple,
                            items: blocks,
                            value: state.block,
                            getLabel: (s) => s,
                            hintText: l10n.select,
                            onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateBlock(v)),
                          ),
                          Divider(color: AppColors.divider, thickness: 0.6),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    // TODO: Localize if needed
                                    l10n.advanceFilter,
                                    style: TextStyle(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Material(
                                  elevation: 2,
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => context.read<GuestBeneficiarySearchBloc>().add(const GbsToggleAdvanced()),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.filter_alt_outlined,
                                        color: AppColors.onPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (state.showAdvanced) ...[
                            ApiDropdown<String>(
                              labelText: l10n.categoryLabel,
                              items: categories,
                              value: state.category,
                              getLabel: (s) => s,
                              hintText: l10n.select,
                              onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateCategory(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.6),

                            Container(
                              color: AppColors.surfaceVariant,
                              child: ApiDropdown<String>(
                                labelText: l10n.genderLabel,
                                items: genders,
                                value: state.gender,
                                getLabel: (s) => s,
                                hintText: l10n.select,
                                onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateGender(v)),
                              ),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.6),

                            CustomTextField(
                              labelText: l10n.ageLabelSimple,
                              hintText: '',
                              keyboardType: TextInputType.number,
                              onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateAge(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.6),

                            CustomTextField(
                              labelText: l10n.mobileLabelSimple,
                              hintText: 'Enter 10 digit number',
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                               // FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => context.read<GuestBeneficiarySearchBloc>().add(GbsUpdateMobile(v)),
                            ),
                            Divider(color: AppColors.divider, thickness: 0.6),
                          ],

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: state.status == GbsStatus.submitting
                                ? const Center(child: CircularProgressIndicator())
                                : RoundButton(
                                    title: l10n.search,
                                    height: 45,
                                    color: AppColors.primary,
                                    onPress: () {
                                      // Dismiss keyboard when searching
                                      FocusScope.of(context).unfocus();
                                      context.read<GuestBeneficiarySearchBloc>().add(const GbsSubmitSearch());
                                    },
                                    icon: Icons.search,
                                  ),
                          ),

                          const SizedBox(height: 16),

                          if (state.status == GbsStatus.success && state.beneficiaryData != null)
                            _buildSearchResults(context, state.beneficiaryData!),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      height: 35,
                      width: double.infinity,
                      child: RoundButton(
                        title: l10n.showGuestBeneficiaryList,
                        color: AppColors.primary,
                        onPress: () {},
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ));
      }),
    );
  }
}
