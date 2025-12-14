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
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';

class EligibleCoupleList extends StatefulWidget {
  const EligibleCoupleList({super.key});

  @override
  State<EligibleCoupleList> createState() => _EligibleCoupleListState();
}

class _EligibleCoupleListState extends State<EligibleCoupleList> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadEligibleCouples();
  }

  Future<void> _loadEligibleCouples() async {
    try {
      final db = await DatabaseProvider.instance.database;

      // --- 1. Get Current User Key ---
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // --- 2. Build Query Condition ---
      String? where;
      List<Object?>? whereArgs;

      // Only apply filter if the key exists and is not empty
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        where = 'current_user_key = ?';
        whereArgs = [ashaUniqueKey];
      }

      final households = <String, List<Map<String, dynamic>>>{};

      // --- 3. Query with Filter ---
      final allBeneficiaries = await db.query(
          'beneficiaries_new',
          where: where,        // Applied the condition
          whereArgs: whereArgs // Passed the key
      );

      // --- Existing Processing Logic ---
      for (final row in allBeneficiaries) {
        try {
          final hhId = row['household_ref_key']?.toString() ?? '';
          if (hhId.isEmpty) continue;

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : (row['beneficiary_info'] as Map?) ?? {};

          if (info is! Map) continue;

          // Add to household group
          if (!households.containsKey(hhId)) {
            households[hhId] = [];
          }

          households[hhId]!.add({
            ...row,
            'info': info,
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      final trackingFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ?? '';
      final Map<String, String> latestFpMethod = {};
      if (trackingFormKey.isNotEmpty) {
        final trackingRows = await db.query(
          FollowupFormDataTable.table,
          columns: ['beneficiary_ref_key', 'form_json', 'created_date_time', 'id'],
          where: 'forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
          whereArgs: [trackingFormKey],
          orderBy: 'created_date_time DESC, id DESC',
        );
        for (final row in trackingRows) {
          final key = row['beneficiary_ref_key']?.toString() ?? '';
          if (key.isEmpty) continue;
          if (latestFpMethod.containsKey(key)) continue;
          final formJsonStr = row['form_json']?.toString() ?? '';
          if (formJsonStr.isEmpty) continue;
          try {
            final decoded = jsonDecode(formJsonStr);
            Map<String, dynamic> formData = decoded is Map<String, dynamic>
                ? Map<String, dynamic>.from(decoded)
                : <String, dynamic>{};
            if (decoded is Map && decoded['form_data'] is Map) {
              formData = Map<String, dynamic>.from(decoded['form_data'] as Map);
            }
            final fpMethod = formData['fp_method']?.toString().toLowerCase().trim();
            if (fpMethod != null) {
              latestFpMethod[key] = fpMethod;
            }
          } catch (_) {}
        }
      }
      final Set<String> sterilizedBeneficiaries = latestFpMethod.entries
          .where((e) => e.value == 'male sterilization' || e.value == 'female sterilization')
          .map((e) => e.key)
          .toSet();

      final couples = <Map<String, dynamic>>[];

      // Process each household
      for (final hhId in households.keys) {
        final members = households[hhId]!;
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in members) {
          try {
            final info = Map<String, dynamic>.from(member['info'] as Map);
            String rawRelation = (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
            rawRelation = rawRelation.replaceAll('_', ' ');
            if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
              rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
            }
            final relation = () {
              if (rawRelation == 'self' || rawRelation == 'head' || rawRelation == 'family head') return 'self';
              if (rawRelation == 'spouse' || rawRelation == 'wife' || rawRelation == 'husband') return 'spouse';
              return rawRelation;
            }();
            if (relation == 'self') {
              head = info;
            } else if (relation == 'spouse') {
              spouse = info;
            }
          } catch (_) {}
        }

        const allowedRelations = <String>{
          'self',
          'spouse',
          'husband',
          'son',
          'daughter',
          'father',
          'mother',
          'brother',
          'sister',
          'wife',
          'nephew',
          'niece',
          'grand father',
          'grand mother',
          'father in law',
          'mother in low',
          'grand son',
          'grand daughter',
          'son in law',
          'daughter in law',
          'other',
        };

        for (final member in members) {
          try {
            final info = Map<String, dynamic>.from(member['info'] as Map);
            String rawRelation = (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
            rawRelation = rawRelation.replaceAll('_', ' ');
            if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
              rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
            }
            if (!allowedRelations.contains(rawRelation)) continue;
            if (!_isEligibleFemale(info, head: head)) continue;
            final memberUniqueKey = member['unique_key']?.toString() ?? '';
            if (memberUniqueKey.isNotEmpty && sterilizedBeneficiaries.contains(memberUniqueKey)) continue;

            final gender = info['gender']?.toString().toLowerCase() ?? '';
            final dob = info['dob'];
            final age = _calculateAge(dob);
            couples.add({
              'hhId': hhId,
              'name': info['memberName']?.toString() ?? info['headName']?.toString() ?? 'Unknown',
              'age': age,
              'age_gender': _formatAgeGender(dob, gender),
              'mobile': info['mobileNo']?.toString() ?? '',
              'status': 'Eligible Couple',
              '_raw': member,
            });
          } catch (e) {
            print('Error processing household member: $e');
          }
        }
      }

      setState(() {
        _filtered = couples;
      });
    } catch (e) {
      print('Error loading eligible couples: $e');
    }
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    if (!isFemale) return false;
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isMarried = maritalStatusRaw == 'married';
    if (!isMarried) return false;
    final dob = person['dob'];
    final age = _calculateAge(dob);
    final fpMethodRaw = person['fpMethod']?.toString().toLowerCase().trim() ?? '';
    final hpMethodRaw = person['hpMethod']?.toString().toLowerCase().trim() ?? '';
    final isSterilized = fpMethodRaw == 'female sterilization' || fpMethodRaw == 'male sterilization' || hpMethodRaw == 'female sterilization' || hpMethodRaw == 'male sterilization';
    return age >= 15 && age <= 49 && !isSterilized;
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
