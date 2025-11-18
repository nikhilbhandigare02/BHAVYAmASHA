import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../../../data/Local_Storage/tables/followup_form_data_table.dart';

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

      print('🔎 Loading followup_form_data for forms_ref_key (childRegistrationDue): $formsRefKey');

      final rows = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [formsRefKey],
      );

      print('🔎 Total rows found in ${FollowupFormDataTable.table} for childRegistrationDue: ${rows.length}');

      for (final row in rows) {
        try {
          print('🧾 followup_form_data row => ID: ${row['id']}, household_ref_key: ${row['household_ref_key']}, beneficiary_ref_key: ${row['beneficiary_ref_key']}, forms_ref_key: ${row['forms_ref_key']}');
          print('🧾 form_json: ${row['form_json']}');
        } catch (e) {
          print('Error printing followup_form_data row: $e');
        }
      }

      final List<Map<String, dynamic>> lbwChildren = [];

      for (final row in rows) {
        try {
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

          final weightStr = formData['weight_grams']?.toString() ?? '';
          final birthWeightStr = formData['birth_weight_grams']?.toString() ?? '';

          final weight = double.tryParse(weightStr);
          final birthWeight = double.tryParse(birthWeightStr);

          // Filter: either current weight OR birth weight less than 1600 grams
          final isLbw = (weight != null && weight < 1600) ||
              (birthWeight != null && birthWeight < 1600);

          if (!isLbw) continue;

          final childName = formData['child_name']?.toString() ?? 'Unknown';
          final genderRaw = formData['gender'];
          final dobRaw = formData['date_of_birth'];

          final age = _calculateAge(dobRaw);
          final ageGender = _formatAgeGender(dobRaw, genderRaw);

          lbwChildren.add({
            'hhId': hhId,
            'name': childName,
            'age': age,
            'age_gender': ageGender,
            'status': 'LBW',
            '_raw': row,
          });
        } catch (e) {
          print('Error processing LBW child row: $e');
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
