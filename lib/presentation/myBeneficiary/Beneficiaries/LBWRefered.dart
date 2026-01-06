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
import '../../../data/SecureStorage/SecureStorage.dart';

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

    final currentUserData = await SecureStorageService.getCurrentUserData();
    String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    try {
      print('🔍 Loading LBW children from beneficiaries table (flexible thresholds)');

      final rows = await db.query(
        'beneficiaries_new',
        where: 'is_deleted = 0 AND (is_adult = 0 OR is_adult IS NULL) AND current_user_key = ?',
        whereArgs: [ashaUniqueKey], // Pass the key as an argument
      );

      print('🔎 Beneficiaries fetched: ${rows.length}');

      final List<Map<String, dynamic>> lbwChildren = [];
      int passed = 0;

      for (final row in rows) {
        try {
          final hhId = row['household_ref_key']?.toString() ?? '';
          if (hhId.isEmpty) continue;

          final infoStr = row['beneficiary_info']?.toString();
          if (infoStr == null || infoStr.isEmpty) continue;

          Map<String, dynamic>? info;
          try {
            final decoded = jsonDecode(infoStr);
            if (decoded is Map) info = Map<String, dynamic>.from(decoded);
          } catch (_) {}
          if (info == null || info.isEmpty) continue;

          var weight = _parseNumFlexible(info['weight'])?.toDouble();
          var birthWeight = _parseNumFlexible(info['birthWeight'])?.toDouble();

          bool isLbw = false;

          if (weight != null && birthWeight != null) {
            isLbw = (weight <= 1.6 && birthWeight <= 1600);
          } else if (weight != null && birthWeight == null) {
            isLbw = (weight <= 1.6);
          } else if (weight == null && birthWeight != null) {
            isLbw = (birthWeight <= 1600);
          }

          if (!isLbw) continue;
          passed++;

          final name = (info['name'] ?? info['memberName'] ?? '').toString();
          final genderRaw = info['gender'];
          final dobRaw = info['dob'] ?? info['dateOfBirth'];

          final ageGender = _formatAgeGender(dobRaw, genderRaw);
          final weightDisplay = _formatWeight(weight, birthWeight);

          lbwChildren.add({
            'hhId': hhId,
            'name': name.isEmpty ? 'Unknown' : name,
            'age_gender': ageGender,
            'weight_display': weightDisplay,
            'status': 'LBW',
            '_raw': row,
          });
        } catch (e) {
          print('Error processing beneficiary LBW row: $e');
        }
      }

      print('✅ Beneficiaries passing flexible LBW filter: $passed');

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

  num? _parseNumFlexible(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    String s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'[^0-9\.-]'), '');
    if (s.isEmpty) return null;
    final d = double.tryParse(s);
    if (d != null) return d;
    final i = int.tryParse(s);
    if (i != null) return i;
    return null;
  }

  String _formatWeight(double? weight, double? birthWeight) {
    if (weight != null) {
      // Show current weight in kg with one decimal place
      return '${weight.toStringAsFixed(1)} kg';
    }
    if (birthWeight != null) {
      // Show birth weight in grams, rounded to nearest gram
      return '${birthWeight.round()} g';
    }
    return 'N/A';
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
        screenTitle: l10n!.lbwReferred,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          _filtered.isEmpty
              ? _buildNoRecordCard(context)
              : Expanded(
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
    final l10n = AppLocalizations.of(context);

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
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n?.badgeLBW ?? 'LBW',
                      style: const TextStyle(
                        color: Colors.red,
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
                              fontWeight: FontWeight.bold,
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
                    trailing: data['weight_display'] ?? '',
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

  Widget _infoRow(String? title, String value,{String? trailing, bool isWrappable = false}) {
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
          if (trailing != null && trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoRecordCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
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
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
