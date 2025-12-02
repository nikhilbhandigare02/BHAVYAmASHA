import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/Database/tables/beneficiaries_table.dart';

class Lbwrefered extends StatefulWidget {
  const Lbwrefered({super.key});

  @override
  State<Lbwrefered> createState() => _Lbwrefered();
}

class _Lbwrefered extends State<Lbwrefered> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadLbwChildren();
  }

  Future<void> _loadLbwChildren() async {
    final db = await DatabaseProvider.instance.database;

    try {
      final formsRefKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.childRegistrationDue] ??
              '2ol35gbp7rczyvn6';

      print('🔎 Loading LBW from beneficiaries and followup tables');

      final List<Map<String, dynamic>> lbwChildren = [];
      final Set<String> beneficiaryKeys = <String>{};

      // 1) From beneficiaries_new: is_adult = 0 and beneficiary_info has weight <= 1.2 AND birthWeight <= 1200
      final benRows = await db.query(
        BeneficiariesTable.table,
        where: 'is_deleted = 0 AND is_adult = 0',
      );
      print('🔎 Beneficiaries rows: ${benRows.length}');
      for (final row in benRows) {
        try {
          final infoStr = row['beneficiary_info']?.toString() ?? '';
          if (infoStr.isEmpty) continue;
          Map<String, dynamic>? info;
          try {
            final decoded = jsonDecode(infoStr);
            if (decoded is Map) {
              info = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
          if (info == null || info!.isEmpty) continue;

          final weight = _parseNum(info!['weight']);
          final birthWeight = _parseNum(info!['birthWeight']);

          final bool isLbwBen = (weight != null && weight.toDouble() <= 1.2) &&
              (birthWeight != null && birthWeight.toDouble() <= 1200);
          if (!isLbwBen) continue;

          final uniqueKey = row['unique_key']?.toString() ?? '';
          if (uniqueKey.isNotEmpty) beneficiaryKeys.add(uniqueKey);

          final hhId = row['household_ref_key']?.toString() ?? '';
          final name = info!['name']?.toString() ?? 'Unknown';
          final ageGender = _formatAgeGender(info!['dob'], info!['gender']);

          lbwChildren.add({
            'hhId': hhId,
            'name': name,
            'age_gender': ageGender,
            'status': 'LBW',
            'unique_key': uniqueKey,
            'source': 'beneficiary',
          });
        } catch (e) {
          print('Error processing beneficiary LBW row: $e');
        }
      }

      // 2) From followup_form_data: childRegistrationDue forms with weight/birth_weight in grams
      final fuRows = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [formsRefKey],
      );
      print('🔎 Followup rows: ${fuRows.length}');
      for (final row in fuRows) {
        try {
          final beneficiaryRefKey = row['beneficiary_ref_key']?.toString() ?? '';
          if (beneficiaryRefKey.isNotEmpty && beneficiaryKeys.contains(beneficiaryRefKey)) {
            // Skip duplicates: prefer beneficiaries table record
            continue;
          }

          final hhId = row['household_ref_key']?.toString() ?? '';
          if (hhId.isEmpty) continue;

          final formJsonStr = row['form_json']?.toString() ?? '';
          if (formJsonStr.isEmpty) continue;

          final decoded = jsonDecode(formJsonStr);
          if (decoded is! Map) continue;

          final formData = decoded['form_data'] is Map
              ? Map<String, dynamic>.from(decoded['form_data'])
              : <String, dynamic>{};
          if (formData.isEmpty) continue;

          final weight = _parseNum(formData['weight_grams'])?.toDouble();
          final birthWeight = _parseNum(formData['birth_weight_grams'])?.toDouble();

          final isLbw = (weight != null && weight < 1600) ||
              (birthWeight != null && birthWeight < 1600);
          if (!isLbw) continue;

          final childName = formData['child_name']?.toString() ?? 'Unknown';
          final ageGender = _formatAgeGender(formData['date_of_birth'], formData['gender']);

          lbwChildren.add({
            'hhId': hhId,
            'name': childName,
            'age_gender': ageGender,
            'status': 'LBW',
            'beneficiary_ref_key': beneficiaryRefKey,
            'source': 'followup',
          });
        } catch (e) {
          print('Error processing followup LBW row: $e');
        }
      }

      setState(() {
        _filtered = lbwChildren;
      });
    } catch (e) {
      print('Error loading LBW children: $e');
      setState(() {
        _filtered = [];
      });
    }
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String ageDisplay = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');

    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      DateTime? dob;
      try {
        dob = DateTime.tryParse(dobRaw.toString());
      } catch (_) {}

      if (dob != null) {
        final now = DateTime.now();
        final diffDays = now.difference(dob).inDays;

        if (diffDays >= 365) {
          // Show in years
          final years = diffDays ~/ 365;
          ageDisplay = '${years}Y';
        } else if (diffDays >= 30) {
          // Show in months
          final months = diffDays ~/ 30;
          ageDisplay = '${months}M';
        } else if (diffDays >= 0) {
          // Show in days (for < 1 month)
          ageDisplay = '${diffDays}D';
        }
      }
    }

    String displayGender = gender == 'm' || gender == 'male'
        ? 'Male'
        : gender == 'f' || gender == 'female'
        ? 'Female'
        : 'Other';

    return '$ageDisplay | $displayGender';
  }

  num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    // Try double first, then int
    final d = double.tryParse(s);
    if (d != null) return d;
    final i = int.tryParse(s);
    if (i != null) return i;
    return null;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.eligibleCoupleListTitle ?? 'Eligible Couple List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [

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

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {

      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (data['hhId']?.toString().length ?? 0) > 11 ? data['hhId'].toString().substring(data['hhId'].toString().length - 11) : (data['hhId'] ?? ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                ],
              ),
            ),


            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoRow(
                    '',
                    data['age_gender'] ?? '',
                    isWrappable: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String? title, String value,{bool isWrappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$title ',
            style:  TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
