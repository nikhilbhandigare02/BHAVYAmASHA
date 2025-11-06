import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../MigrtionSplitScreen/MigrationSplitScreen.dart';

class HouseHold_BeneficiaryScreen extends StatefulWidget {
  final String? houseNo;
  final String? hhId;
  
  const HouseHold_BeneficiaryScreen({
    super.key,
    this.houseNo,
    this.hhId,
  });

  @override
  State<HouseHold_BeneficiaryScreen> createState() =>
      _HouseHold_BeneficiaryScreenState();
}

class _HouseHold_BeneficiaryScreenState
    extends State<HouseHold_BeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();


  late List<Map<String, dynamic>> _filtered;
  List<Map<String, dynamic>> _beneficiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _loadBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      debugPrint('Fetched ${rows.length} beneficiaries from LocalStorageDao');

      final List<Map<String, dynamic>> beneficiaries = [];

      for (final row in rows) {
        final rowHhId = row['household_ref_key']?.toString() ?? '';
        final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
        final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
        final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});
        final headHouseNo = head['houseNo']?.toString() ?? '';
        // Show if either hhId or houseNo matches (if both are provided, both must match)
        final matchByHhId = widget.hhId != null && rowHhId == widget.hhId;
        final matchByHouseNo = widget.houseNo != null && headHouseNo == widget.houseNo;
        final match = (widget.hhId != null && widget.houseNo != null)
          ? (matchByHhId && matchByHouseNo)
          : (matchByHhId || matchByHouseNo);
        if (match) {
          // Head card
          if (head.isNotEmpty) {
            final gender = (head['gender']?.toString().toLowerCase() ?? '');
            final regType = 'General';
            final isFemale = gender == 'female' || gender == 'f';
            final isChild = regType.toLowerCase() == 'child';
            final richId = head['RichIDChanged']?.toString() ?? head['richIdChanged']?.toString() ?? '';
            final card = {
              'hhId': rowHhId,
              'RegitrationDate': row['created_date_time']?.toString() ?? '',
              'RegitrationType': regType,
              'BeneficiaryID': row['id']?.toString() ?? '',
              'Name': head['headName']?.toString() ?? '',
              'Age|Gender': _formatAgeGender(head['dob'], head['gender']),
              'Mobileno.': head['mobileNo']?.toString() ?? '',
              'RelationName': spouse['memberName']?.toString() ?? '',
              'Relation': 'Head',
              'MaritalStatus': head['maritalStatus']?.toString() ?? '',
              '_raw': row,
            };
            if (isFemale || isChild) {
              card['Rich_id'] = richId;
            }
            beneficiaries.add(card);
          }
          // Spouse card (if exists)
          if (spouse.isNotEmpty) {
            final gender = (spouse['gender']?.toString().toLowerCase() ?? '');
            final regType = 'General';
            final isFemale = gender == 'female' || gender == 'f';
            final isChild = regType.toLowerCase() == 'child';
            final richId = spouse['RichIDChanged']?.toString() ?? spouse['richIdChanged']?.toString() ?? '';
            final card = {
              'hhId': rowHhId,
              'RegitrationDate': row['created_date_time']?.toString() ?? '',
              'RegitrationType': regType,
              'BeneficiaryID': row['id']?.toString() ?? '',
              'Name': spouse['memberName']?.toString() ?? '',
              'Age|Gender': _formatAgeGender(spouse['dob'], spouse['gender']),
              'Mobileno.': spouse['mobileNo']?.toString() ?? '',
              'RelationName': head['headName']?.toString() ?? '',
              'Relation': 'Spouse',
              'MaritalStatus': spouse['maritalStatus']?.toString() ?? '',
              '_raw': row,
            };
            if (isFemale || isChild) {
              card['Rich_id'] = richId;
            }
            beneficiaries.add(card);
          }
          break;
        }
      }

      if (mounted) {
        setState(() {
          _beneficiaries = beneficiaries;
          _filtered = List<Map<String, dynamic>>.from(beneficiaries);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading beneficiaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      DateTime? dob;
      try {
        dob = DateTime.tryParse(dobRaw.toString());
      } catch (_) {}
      if (dob != null) {
        age = '${DateTime.now().difference(dob).inDays ~/ 365}';
      }
    }
    String displayGender = gender == 'm' || gender == 'male'
        ? 'Male'
        : gender == 'f' || gender == 'female'
            ? 'Female'
            : 'Other';
    return '$age Y | $displayGender';
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_beneficiaries);
      } else {
        _filtered = _beneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: widget.houseNo != null
            ? '${l10n?.householdBeneficiaryTitle ?? 'Household'} '
            : l10n?.householdBeneficiaryTitle ?? 'Household Beneficiary',
        showBack: true,
        icon1Image: 'assets/images/left-right-arrow.png',
        onIcon1Tap: () =>
            Navigator.pushNamed(context, Route_Names.MigrationSplitOption),
        icon3Image: 'assets/images/home.png',
        onIcon3Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.householdBeneficiarySearch ??
                    'Household Beneficiary Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoColumn(
                      l10n?.villageLabel ?? 'Village',
                      l10n?.notAvailable ?? 'Not Available'),
                  _infoColumn(
                      l10n?.mohallaTolaNameLabel ?? 'Tola/Mohalla',
                      l10n?.notAvailable ?? 'Not Available'),
                ],
              ),
            ),
          ),

          // List
          _isLoading
              ? const Expanded(
              child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
              ? Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _beneficiaries.isEmpty
                      ? 'No beneficiaries found. Add a new beneficiary to get started.'
                      : 'No matching beneficiaries found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _loadBeneficiaries,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _householdCard(context, data);
                },
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 35,
                child: RoundButton(
                  title: (l10n?.addNewBeneficiaryButton ??
                      'Add New Beneficiary')
                      .toUpperCase(),
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 50,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.addFamilyMember);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Route_Names.addFamilyMember,
          arguments: {'isEdit': false,'name': data['Name'],},

        );
      },
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
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null && data['hhId'].toString().length > 11) ? data['hhId'].toString().substring(data['hhId'].toString().length - 11) : (data['hhId'] ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png',
                      width: 7.w,
                      height: 7.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText('Registration Date', data['RegitrationDate'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Registration Type', data['RegitrationType'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Beneficiary ID',
  data['Relation'] == 'Head'
    ? ((data['_raw']['unique_key']?.toString().length ?? 0) > 11 ? data['_raw']['unique_key'].toString().substring(data['_raw']['unique_key'].toString().length - 11) : (data['_raw']['unique_key']?.toString() ?? ''))
    : ((data['_raw']['spouse_key']?.toString().length ?? 0) > 11 ? data['_raw']['spouse_key'].toString().substring(data['_raw']['spouse_key'].toString().length - 11) : (data['_raw']['spouse_key']?.toString() ?? ''))
)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText('Name', data['Name'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Age | Gender', data['Age|Gender'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Mobile no.', data['Mobileno.'] ?? '')),
                    ],
                  ),
                  if (((data['Relation'] == 'Head' || data['Relation'] == 'Spouse') && ((data['Age|Gender']?.toString().toLowerCase().contains('female') ?? false) || (data['RegitrationType']?.toString().toLowerCase() == 'child'))))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _rowText('Rich_id', data['Rich_id'] ?? ''),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          data['Relation'] == 'Head' 
                              ? 'Wife Name'
                              : data['Relation'] == 'Spouse' 
                                  ? 'Husband Name' 
                                  : data['Relation'] == 'Wife' 
                                      ? 'Husband Name'
                                      : 'Father Name', 
                          data['RelationName'] ?? ''
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (data['MotherName'] != null && data['MotherName'] != 'N/A')
                        Expanded(
                          child: _rowText(
                            'Mother Name',
                            data['MotherName'] ?? 'N/A',
                          ),
                        ),
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
            color: AppColors.background,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.background,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ],
    );
  }

}
