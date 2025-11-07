import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import 'bloc/anc_visit_list_bloc.dart';

class Ancvisitlistscreen extends StatefulWidget {
  const Ancvisitlistscreen({super.key});

  @override
  State<Ancvisitlistscreen> createState() => _AncvisitlistscreenState();
}

class _AncvisitlistscreenState extends State<Ancvisitlistscreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final AncVisitListBloc _ancVisitListBloc = AncVisitListBloc();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _ancVisitListBloc.add(FetchFamilyPlanningBeneficiaries());
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _ancVisitListBloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBeneficiaryCard(Map<String, dynamic> beneficiary) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    
    // Extract data from beneficiary info
    final name = _getBeneficiaryName(beneficiary);
    final hhId = (beneficiary['hhId'] ?? beneficiary['id'] ?? '').toString();
    final mobile = beneficiary['mobile'] ?? beneficiary['phone'] ?? '';
    final houseNo = beneficiary['houseNo'] ?? beneficiary['house_number'] ?? '';
    final age = beneficiary['age']?.toString() ?? '';
    final husbandName = beneficiary['husband_name'] ?? beneficiary['spouse_name'] ?? '';
    final registrationDate = beneficiary['registration_date'] ?? beneficiary['created_at'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        // Navigator.pushNamed(context, Route_Names.Ancvisitform, arguments: beneficiary);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        hhId.toString(),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n?.visitsLabel ?? 'Visits'}: 0',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Image.asset(
                      'assets/Images/sync.png',
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),

            // Blue body
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First row of details - Basic Information
                  _buildDetailRow(
                    context,
                    left1: _buildDetailItem(l10n?.beneficiaryIdLabel ?? 'ID', hhId),
                    right1: _buildDetailItem(l10n?.nameLabel ?? 'Name', name),
                    left2: _buildDetailItem(l10n?.ageLabel ?? 'Age', age),
                    right2: _buildDetailItem(l10n?.mobileLabel ?? 'Mobile', mobile),
                    bottom: _buildDetailItem(l10n?.houseNoLabel ?? 'House No', houseNo),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Second row of details - Family Planning Info
                  _buildDetailRow(
                    context,
                    left1: _buildDetailItem(l10n?.husbandLabel ?? 'Husband', husbandName.isNotEmpty ? husbandName : 'N/A'),
                    right1: _buildDetailItem('Marital Status', 'Married'),
                    left2: _buildDetailItem('Registration', registrationDate.isNotEmpty ? registrationDate : 'N/A'),
                    right2: _buildDetailItem('Status', 'Active'),
                    bottom: _buildDetailItem('Family Planning', 'Enrolled'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required Widget left1,
    required Widget right1,
    required Widget left2,
    required Widget right2,
    required Widget bottom,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left1),
            const SizedBox(width: 8),
            Expanded(child: right1),
            const SizedBox(width: 8),
            Expanded(child: left2),
            const SizedBox(width: 8),
            Expanded(child: right2),
          ],
        ),
        const SizedBox(height: 8),
        bottom,
      ],
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  String _getBeneficiaryName(Map<String, dynamic> beneficiary) {
    // Try different possible name fields and ensure they're converted to string
    final name = (beneficiary['name'] ??
                beneficiary['beneficiary_name'] ??
                beneficiary['fullName'] ??
                beneficiary['beneficiaryName'] ??
                '${beneficiary['first_name'] ?? ''} ${beneficiary['last_name'] ?? ''}').toString().trim();
    
    // If we still don't have a name, show the ID or a default
    if (name.isEmpty) {
      return beneficiary['id'] != null 
          ? 'Beneficiary #${beneficiary['id']}'
          : 'Unnamed Beneficiary';
    }
    
    return name;
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => _ancVisitListBloc..add(FetchFamilyPlanningBeneficiaries()),
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.ancVisitListTitle ?? 'Family Planning Beneficiaries',
          showBack: true,
          icon1: Icons.refresh,
          onIcon1Tap: () {
            _ancVisitListBloc.add(FetchFamilyPlanningBeneficiaries());
          },
        ),
        body: BlocBuilder<AncVisitListBloc, AncVisitListState>(
          bloc: _ancVisitListBloc,
        builder: (context, state) {
          if (state is AncVisitListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AncVisitListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _ancVisitListBloc.add(FetchFamilyPlanningBeneficiaries()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is AncVisitListLoaded) {
            final beneficiaries = state.beneficiaries;
            final filteredBeneficiaries = _filterBeneficiaries(
              beneficiaries,
              _searchCtrl.text.trim(),
            );

            if (filteredBeneficiaries.isEmpty) {
              return Column(
                children: [
                  _buildSearchField(),
                  const Expanded(
                    child: Center(
                      child: Text('No family planning beneficiaries found.'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildSearchField(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredBeneficiaries.length,
                    itemBuilder: (context, index) {
                      return _buildBeneficiaryCard(filteredBeneficiaries[index]);
                    },
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildSearchField(),
              Expanded(
                child: Center(
                  child: Text(
                    'No data available. Pull down to refresh.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ));
  }

  Widget _buildSearchField() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: l10n?.ancVisitSearchHint ?? 'ANC Visit Search',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterBeneficiaries(
      List<Map<String, dynamic>> beneficiaries, String query) {
    if (query.isEmpty) return beneficiaries;

    final q = query.toLowerCase();
    return beneficiaries.where((beneficiary) {
      return (beneficiary['name']?.toString().toLowerCase().contains(q) ?? false) ||
             (beneficiary['mobile']?.toString().contains(q) ?? false) ||
             (beneficiary['hhId']?.toString().contains(q) ?? false) ||
             (beneficiary['houseNo']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }


}
