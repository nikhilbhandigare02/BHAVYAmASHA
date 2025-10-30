import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/routes/Route_Name.dart';

class UpdatedEligibleCoupleListScreen extends StatefulWidget {
  const UpdatedEligibleCoupleListScreen({super.key});

  @override
  State<UpdatedEligibleCoupleListScreen> createState() =>
      _UpdatedEligibleCoupleListScreenState();
}

class _UpdatedEligibleCoupleListScreenState
    extends State<UpdatedEligibleCoupleListScreen> {
  final TextEditingController _search = TextEditingController();
  int _tab = 0; // 0 = All, 1 = Protected, 2 = Unprotected
  List<Map<String, dynamic>> _households = [];

  @override
  void initState() {
    super.initState();
    // Static demo data
    _households = [
      {
        'hhId': 'HH001',
        'RegistrationDate': '10-10-2025',
        'RegistrationType': 'GA',
        'BeneficiaryID': 'VA001',
        'Name': 'Rohit Chavan',
        'age': 30,
        'RichID': 123,
        'mobileno': '9923175398',
        'HusbandName': 'Sagar Chavan',
        'ProtectionStatus': 'Unprotected',
      },
      {
        'hhId': 'HH002',
        'RegistrationDate': '11-10-2025',
        'RegistrationType': 'GA',
        'BeneficiaryID': 'VA002',
        'Name': 'Anita Patil',
        'age': 28,
        'RichID': 124,
        'mobileno': '9876543210',
        'HusbandName': 'Ravi Patil',
        'Protection': 'Protected',
      },
      {
        'hhId': 'HH003',
        'RegistrationDate': '12-10-2025',
        'RegistrationType': 'GA',
        'BeneficiaryID': 'VA003',
        'Name': 'Ramesh Jadhav',
        'age': 32,
        'RichID': 125,
        'mobileno': '9998887776',
        'HusbandName': 'Vikram Jadhav',
        'Protected': 'Y',
      },
      {
        'hhId': 'HH004',
        'RegistrationDate': '13-10-2025',
        'RegistrationType': 'GA',
        'BeneficiaryID': 'VA004',
        'Name': 'Sneha More',
        'age': 26,
        'RichID': 126,
        'mobileno': '9988776655',
        'HusbandName': 'Nilesh More',
        'isProtected': false,
      },
      {
        'hhId': 'HH005',
        'RegistrationDate': '14-10-2025',
        'RegistrationType': 'GA',
        'BeneficiaryID': 'VA005',
        'Name': 'Kiran Deshmukh',
        'age': 29,
        'RichID': 127,
        'mobileno': '9012345678',
        'HusbandName': 'Amit Deshmukh',
        'IsProtected': 1,
      },
    ];
  }

  bool _isProtected(Map<String, dynamic> data) {
    final dynamic raw = data['ProtectionStatus'] ??
        data['Protection'] ??
        data['protected'] ??
        data['isProtected'] ??
        data['Protected'] ??
        data['IsProtected'];

    if (raw is bool) return raw;
    if (raw == null) return false;
    final v = raw.toString().trim().toLowerCase();
    return v == 'protected' || v == 'y' || v == 'yes' || v == 'true' || v == '1';
  }

  List<Map<String, dynamic>> get _protectedList =>
      _households.where((e) => _isProtected(e)).toList();

  List<Map<String, dynamic>> get _unprotectedList =>
      _households.where((e) => !_isProtected(e)).toList();

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> base;
    switch (_tab) {
      case 1:
        base = _protectedList;
        break;
      case 2:
        base = _unprotectedList;
        break;
      default:
        base = _households;
    }
    if (_search.text.isEmpty) return base;
    final q = _search.text.toLowerCase();
    return base
        .where((data) =>
            (data['Name']?.toString().toLowerCase().contains(q) ?? false) ||
            (data['HusbandName']?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: t?.updatedEligibleCoupleListTitle ?? 'Updated Eligible Couple List',
        showBack: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Box
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t?.updatedEligibleCoupleSearchHint ?? 'Search Updated Eligible Couple',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ),

            // 🟦 Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: Row(
                children: [
                  _TabChip(
                    label: '${t?.tabAll ?? 'ALL'} (${_households.length})',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 16),
                  _TabChip(
                    label: '${t?.tabProtected ?? 'PROTECTED'} (${_protectedList.length})',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  const SizedBox(width: 16),
                  _TabChip(
                    label: '${t?.tabUnprotected ?? 'UNPROTECTED'} (${_unprotectedList.length})',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 📋 List Section
            Expanded(
              child: _filtered.isNotEmpty
                  ? ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _householdCard(context, data);
                },
              )
                  : Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 40, horizontal: 16),
                  child: Text(
                    t?.noRecordFound ?? 'No Record Found.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📦 Household Card
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context,  Route_Names.TrackEligibleCoupleScreen);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
                      data['hhId']?.toString() ?? '',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: Image.asset('assets/images/sync.png'),
                  ),
                ],
              ),
            ),

            // Body
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(t?.registrationDateLabel ?? 'Registration Date', data['RegistrationDate']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.registrationTypeLabel ?? 'Registration Type', data['RegistrationType']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryID']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(t?.nameOfMemberLabel ?? 'Name', data['Name']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.ageLabelSimple ?? 'Age', data['age']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.richIdLabel ?? 'Rich ID', data['RichID']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(t?.mobileLabelSimple ?? 'Mobile No.', data['mobileno']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.spouseNameLabel ?? 'Husband Name', data['HusbandName']?.toString() ?? '')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primary;
    final unselectedBorder = AppColors.outlineVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? selectedColor : unselectedBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
