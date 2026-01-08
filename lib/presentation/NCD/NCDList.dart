import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/Loader/Loader.dart';
import '../../core/widgets/RoundButton/RoundButton.dart';
import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/tables/followup_form_data_table.dart' as ffd;
import '../../data/SecureStorage/SecureStorage.dart';
import '../HomeScreen/HomeScreen.dart';
import 'NCD_CBAC_DETAIL.dart';


class Ncdlist extends StatefulWidget {
  const Ncdlist({super.key});

  @override
  State<Ncdlist> createState() => _NCDHomeState();
}

class _NCDHomeState extends State<Ncdlist> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  List<Map<String, dynamic>> _allHouseholds = [];
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadCBACFormsData();
  }

  Future<void> _loadCBACFormsData() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> result = await db.query(
        ffd.FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND TRIM(current_user_key) = ?',
        whereArgs: ['vl7o6r9b6v3fbesk', ashaUniqueKey],
      );

      debugPrint('CBAC Forms Data (${result.length} records)');


      debugPrint('CBAC Forms Data (${result.length} records):');

      List<Map<String, dynamic>> households = [];

      for (var form in result) {
        try {
          final formJson = jsonDecode(form['form_json']);
          final formData = formJson['form_data'] ?? {};

          // Extract data from form_data
          String name = formData['name'] ?? formData['personal']?['name'] ?? 'N/A';
          String age = formData['age']?.toString() ?? formData['personal']?['age']?.toString() ?? 'N/A';
          String gender = formData['gender'] ?? formData['personal']?['gender'] ?? 'N/A';
          String mobile = formData['mobile'] ?? formData['personal']?['mobile'] ?? 'N/A';
          String fatherName = formData['father'] ?? formData['personal']?['father'] ?? '';
          String husbandName = formData['husband'] ?? formData['personal']?['husband'] ?? '';
          String wifeName = formData['wife'] ?? formData['personal']?['wife'] ?? '';
          String village = formData['village'] ?? 'N/A';
          String address = formData['address'] ?? '';

          // Format registration date from created_at in form_json
          String registrationDate = 'N/A';
          if (formJson['created_at'] != null) {
            try {
              DateTime dateTime = DateTime.parse(formJson['created_at'].toString());
              registrationDate = DateFormat('dd-MM-yyyy').format(dateTime);
            } catch (e) {
              debugPrint('Error parsing created_at from form_json: $e');
            }
          }

          // Extract last 11 digits for household and beneficiary IDs
          String hhId = formJson['household_ref_key']?.toString() ?? 'N/A';
          if (hhId != 'N/A' && hhId.length > 11) {
            hhId = hhId.substring(hhId.length - 11);
          }

          String beneficiaryId = formJson['beneficiary_id']?.toString() ?? 'N/A';
          if (beneficiaryId != 'N/A' && beneficiaryId.length > 11) {
            beneficiaryId = beneficiaryId.substring(beneficiaryId.length - 11);
          }

          households.add({
            'hhId': hhId,
            'RegitrationDate': registrationDate,
            'RegitrationType': 'General',
            'BeneficiaryID': beneficiaryId,
            'Tola/Mohalla': address.isNotEmpty ? address : 'N/A',
            'village': village,
            'RichID': form['id']?.toString() ?? 'N/A',
            'Name': name,
            'Age|Gender': '$age Y | $gender',
            'Mobileno.': mobile,
            'FatherName': fatherName.isNotEmpty ? fatherName : 'N/A',
            'HusbandName': husbandName.isNotEmpty ? husbandName : 'N/A',
            'WifeName': wifeName.isNotEmpty ? wifeName : 'N/A',
            'formId': form['id'], // Store only the form ID
          });

          debugPrint('Processed Form ID: ${form['id']}');
        } catch (e) {
          debugPrint('Error parsing form JSON: $e');
        }
      }

      if (mounted) {
        setState(() {
          _allHouseholds = households;
          _filtered = List<Map<String, dynamic>>.from(households);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading CBAC forms data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_allHouseholds);
      } else {
        _filtered = _allHouseholds.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['Name'] as String).toLowerCase().contains(q) ||
              (e['Mobileno.'] as String).toLowerCase().contains(q) ||
              (e['village'] as String).toLowerCase().contains(q) ||
              (e['Tola/Mohalla'] as String).toLowerCase().contains(q) ||
              (e['BeneficiaryID'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.ncdListTitle ?? 'NCD List',
        showBack: false,
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const CenterBoxLoader()
          : _filtered.isEmpty
          ? Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.noRecordFound ?? 'No Record Found',
                  style: TextStyle(
                      fontSize: 17.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:l10n?.searchHousehold ?? 'Household Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final data = _filtered[index];
                return _householdCard(context, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 Household Card UI - Now fully tappable
// Fix the _householdCard method with proper null handling:

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CBACDetailScreen(
                  formId: data['formId'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Colors.black54, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['hhId']?.toString() ?? l10n?.na ?? 'N/A',
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.black54,
                        size: 16),
                  ],
                ),
              ),

              // Card Body
              Container(
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.95),
                  borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(6)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow([
                      _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          data['RegitrationDate']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.registrationTypeLabel ?? 'Registration Type',
                          data['RegitrationType']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          data['BeneficiaryID']?.toString() ?? 'N/A'
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(
                          l10n?.villageLabel ?? 'Village',
                          data['village']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.mohallaTolaName ?? 'Tola/Mohalla',
                          data['Tola/Mohalla']?.toString() ?? 'N/A'  // FIXED: Use actual key
                      ),
                      _rowText(
                          'RCH ID',
                          data['RichID']?.toString() ?? 'N/A'
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(
                          l10n?.thName ?? 'Name',
                          data['Name']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.ageGenderLabel ?? 'Age | Gender',
                          data['Age|Gender']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.toString() ?? 'N/A'
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(
                          l10n?.fatherNameLabel ?? 'Father Name',
                          data['FatherName']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.husbandName ?? 'Husband Name',
                          data['HusbandName']?.toString() ?? 'N/A'
                      ),
                      _rowText(
                          l10n?.wifeName ?? 'Wife Name',
                          data['WifeName']?.toString() ?? 'N/A'
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ]
      ],
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
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: AppColors.background,
              fontWeight: FontWeight.w400,
              fontSize: 13.sp),
        ),
      ],
    );
  }
}