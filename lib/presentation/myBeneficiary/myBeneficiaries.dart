import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/Database/tables/beneficiaries_table.dart';
import 'package:sizer/sizer.dart';
import 'dart:convert';
import '../../data/SecureStorage/SecureStorage.dart';
import '../../l10n/app_localizations.dart';

import '../../core/config/routes/Route_Name.dart';
import 'Beneficiaries/AbortionList.dart';

class Mybeneficiaries extends StatefulWidget {
  const Mybeneficiaries({super.key});

  @override
  State<Mybeneficiaries> createState() => _MybeneficiariesState();
}

class _MybeneficiariesState extends State<Mybeneficiaries> {
  int familyUpdateCount = 0;
  int eligibleCoupleCount = 0;
  int pregnantWomenCount = 0;
  int pregnancyOutcomeCount = 0;
  int hbcnCount = 0;
  int lbwReferredCount = 0;
  int abortionListCount = 0;
  int deathRegisterCount = 0;
  int migratedOutCount = 0;
  int guestBeneficiaryCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final allBeneficiaries = await db.query(BeneficiariesTable.table);
      final households = await LocalStorageDao.instance.getAllHouseholds();

      // Build headKeyByHousehold map (same as _loadHeads)
      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      // Filter to get only family heads (same logic as _loadHeads)
      final familyHeads = allBeneficiaries.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          final configuredHeadKey = headKeyByHousehold[householdRefKey];

          // Exclude dead or migrated (same as _loadHeads)
          final isDeath = r['is_death'] == 1;
          final isMigrated = r['is_migrated'] == 1;
          if (isDeath || isMigrated) return false;

          bool isConfiguredHead = false;
          if (configuredHeadKey != null && configuredHeadKey.isNotEmpty) {
            isConfiguredHead = configuredHeadKey == uniqueKey;
          }

          bool isHeadByRelation = false;
          final rawInfo = r['beneficiary_info'];
          Map<String, dynamic> info;
          if (rawInfo is Map) {
            info = Map<String, dynamic>.from(rawInfo as Map);
          } else if (rawInfo is String && rawInfo.isNotEmpty) {
            info = Map<String, dynamic>.from(jsonDecode(rawInfo));
          } else {
            info = <String, dynamic>{};
          }

          final relation = (info['relation_to_head'] ?? info['relation'] ?? '')
              .toString()
              .toLowerCase();
          isHeadByRelation = relation == 'head';

          return isConfiguredHead || isHeadByRelation;
        } catch (_) {
          return false;
        }
      }).toList();

      int familyCount = familyHeads.length;

      // Group all beneficiaries by household for other counts
      final householdGroups = <String, List<Map<String, dynamic>>>{};
      for (final row in allBeneficiaries) {
        try {
          final hhId = row['household_ref_key']?.toString() ?? '';
          if (hhId.isEmpty) continue;

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : (row['beneficiary_info'] as Map?) ?? {};

          if (!householdGroups.containsKey(hhId)) {
            householdGroups[hhId] = [];
          }

          householdGroups[hhId]!.add({
            ...row,
            'info': info,
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      int coupleCount = 0;
      int pregnantCount = 0;

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

      for (final members in householdGroups.values) {
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
            coupleCount++;
          } catch (e) {
            print('Error counting eligible couple: $e');
          }
        }
      }

      final excludedStates = await db.query(
        'mother_care_activities',
        where: "mother_care_state IN ('delivery_outcome', 'hbnc_visit', 'pnc_mother')",
        columns: ['beneficiary_ref_key'],
        distinct: true,
      );
      final excludedBeneficiaryIds = excludedStates
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id!.isNotEmpty)
          .cast<String>()
          .toSet();

      String ancSql = """
        SELECT mca.*, bn.*, mca.id as mca_id, bn.id as beneficiary_id
        FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.mother_care_state = 'anc_due' 
          AND bn.is_deleted = 0
      """;
      final ancArgs = <Object?>[];
      if (excludedBeneficiaryIds.isNotEmpty) {
        ancSql += ' AND mca.beneficiary_ref_key NOT IN (${List.filled(excludedBeneficiaryIds.length, '?').join(',')})';
        ancArgs.addAll(excludedBeneficiaryIds);
      }
      final ancDueRecords = await db.rawQuery(ancSql, ancArgs);
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final processedBeneficiaries = <String>{};
      for (final members in householdGroups.values) {
        for (final member in members) {
          try {
            final info = Map<String, dynamic>.from(member['info'] as Map);
            final gender = info['gender']?.toString().toLowerCase() ?? '';
            final beneficiaryId = member['unique_key']?.toString() ?? '';
            if (beneficiaryId.isEmpty || excludedBeneficiaryIds.contains(beneficiaryId)) continue;
            final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);
            final isPreg = _isPregnant(info);
            if ((isPreg || isAncDue) && (gender == 'f' || gender == 'female')) {
              if (!processedBeneficiaries.contains(beneficiaryId)) {
                pregnantCount++;
                processedBeneficiaries.add(beneficiaryId);
              }
            }
          } catch (e) {
            print('Error counting pregnant women: $e');
          }
        }
      }

      for (final anc in ancDueRecords) {
        final beneficiaryId = anc['beneficiary_ref_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty || processedBeneficiaries.contains(beneficiaryId)) continue;
        pregnantCount++;
        processedBeneficiaries.add(beneficiaryId);
      }

      final poCount = await _getPregnancyOutcomeCount();
      final hbnc = await _getHBNCCount();
      final lbw = await _getLBWReferredCount();
      final abortion = await _getAbortionListCount();
      final death = await _getDeathRegisterCount();
      final migrated = await _getMigratedOutCount();
      final guest = await _getGuestBeneficiaryCount();

      // Update state
      if (mounted) {
        setState(() {
          familyUpdateCount = familyCount;
          eligibleCoupleCount = coupleCount;
          pregnantWomenCount = pregnantCount;
          pregnancyOutcomeCount = poCount;
          hbcnCount = hbnc;
          lbwReferredCount = lbw;
          abortionListCount = abortion;
          deathRegisterCount = death;
          migratedOutCount = migrated;
          guestBeneficiaryCount = guest;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading beneficiary counts: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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

  bool _isPregnant(Map<String, dynamic> person) {
    if (person.isEmpty) return false;
    final flag = person['isPregnant']?.toString().toLowerCase();
    final typoFlag = person['isPregrant']?.toString().toLowerCase();
    final statusFlag = person['pregnancyStatus']?.toString().toLowerCase();
    return flag == 'true' || flag == 'yes' || typoFlag == 'true' || typoFlag == 'yes' || statusFlag == 'pregnant';
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  Future<int> _getPregnancyOutcomeCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final ancRefKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
      if (ancRefKey.isEmpty) return 0;
      final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT beneficiary_ref_key) as c FROM ${FollowupFormDataTable.table} WHERE forms_ref_key = ? AND form_json LIKE ? AND is_deleted = 0',
        [ancRefKey, '%"gives_birth_to_baby":"Yes"%'],
      );
      final row = result.isNotEmpty ? result.first : null;
      final v = row?['c'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getHBNCCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final deliveryKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.deliveryOutcome] ?? '';
      if (deliveryKey.isEmpty) return 0;

      // --- 1. Get Current User Key ---
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // --- 2. Build Query with JOIN matching HBNCList screen selection ---
      String sql = '''
      SELECT COUNT(DISTINCT f.beneficiary_ref_key) as c 
      FROM ${FollowupFormDataTable.table} f
      INNER JOIN beneficiaries_new b ON f.beneficiary_ref_key = b.unique_key
      WHERE f.forms_ref_key = ? 
      AND f.is_deleted = 0 
      AND b.is_deleted = 0
    ''';

      List<Object?> args = [
        deliveryKey,
      ];

      // --- 3. Add User Condition ---
      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        sql += ' AND f.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      final result = await db.rawQuery(sql, args);

      final row = result.isNotEmpty ? result.first : null;
      final v = row?['c'];

      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    } catch (e) {
      print('Error counting HBNC: $e');
      return 0;
    }
  }

  Future<int> _getLBWReferredCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'is_deleted = 0 AND (is_adult = 0 OR is_adult IS NULL)',
      );
      int c = 0;
      for (final r in rows) {
        try {
          final infoStr = r['beneficiary_info']?.toString();
          if (infoStr == null || infoStr.isEmpty) continue;
          final decoded = jsonDecode(infoStr);
          if (decoded is! Map) continue;
          final info = Map<String, dynamic>.from(decoded);
          var weight = _parseNumFlexible(info['weight'])?.toDouble();
          var birthWeight = _parseNumFlexible(info['birthWeight'])?.toDouble();
          if (weight != null && weight > 20) weight = weight / 1000.0; // grams -> kg
          if (birthWeight != null && birthWeight <= 20) birthWeight = birthWeight * 1000.0; // kg -> grams
          final isLbw = (weight != null && birthWeight != null && weight <= 1.2 && birthWeight <= 1200);
          if (isLbw) c++;
        } catch (_) {}
      }
      return c;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getAbortionListCount() async {
    try {
      final forms = await LocalStorageDao.instance.getHighRiskANCVisits();
      int c = 0;
      for (final row in forms) {
        try {
          final fd = Map<String, dynamic>.from(row['form_data'] as Map);
          final v = fd['has_abortion_complication'];
          final s = v?.toString().toLowerCase() ?? '';
          if (s == 'yes') c++;
        } catch (_) {}
      }
      return c;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getDeathRegisterCount() async {
    try {
      final rows = await LocalStorageDao.instance.getDeathRecords();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getMigratedOutCount() async {
    try {
      final rows = await LocalStorageDao.instance.getMigratedBeneficiaries();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getGuestBeneficiaryCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'is_guest = 1 AND is_deleted = 0',
      );
      return rows.length;
    } catch (_) {
      return 0;
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<_BeneficiaryTileData> _items = [
      _BeneficiaryTileData(
        title: l10n.familyUpdate,
        asset: 'assets/images/family.png',
        count: isLoading ? 0 : familyUpdateCount,
      ),
      _BeneficiaryTileData(
        title: l10n.eligibleCoupleList,
        asset: 'assets/images/couple.png',
        count: isLoading ? 0 : eligibleCoupleCount,
      ),
      _BeneficiaryTileData(
        title: l10n.pregnantWomenList,
        asset: 'assets/images/pregnant-woman.png',
        count: isLoading ? 0 : pregnantWomenCount,
      ),
      _BeneficiaryTileData(
        title: l10n.pregnancyOutcome,
        asset: 'assets/images/mother.png',
        count: isLoading ? 0 : pregnancyOutcomeCount,
      ),
      _BeneficiaryTileData(
        title: l10n.hbcnList,
        asset: 'assets/images/pnc-mother.png',
        count: isLoading ? 0 : hbcnCount,
      ),
      _BeneficiaryTileData(
        title: l10n.lbwReferred,
        asset: 'assets/images/lbw.png',
        count: isLoading ? 0 : lbwReferredCount,
      ),
      _BeneficiaryTileData(
        title: l10n.abortionList,
        asset: 'assets/images/npcb-refer.png',
        count: isLoading ? 0 : abortionListCount,
      ),
      _BeneficiaryTileData(
        title: l10n.deathRegister,
        asset: 'assets/images/death2.png',
        count: isLoading ? 0 : deathRegisterCount,
      ),
      _BeneficiaryTileData(
        title: l10n.migratedOut,
        asset: 'assets/images/lbw.png',
        count: isLoading ? 0 : migratedOutCount,
      ),
      _BeneficiaryTileData(
        title: l10n.guestBeneficiaryList,
        asset: 'assets/images/beneficiaries.png',
        count: isLoading ? 0 : guestBeneficiaryCount,
      ),
    ];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(screenTitle: l10n.myBeneficiariesTitle, showBack: true,),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _BeneficiaryTile(
            data: item,
            onTap: () {
              switch (index) {
                case 0:
                  Navigator.pushNamed(context, Route_Names.FamliyUpdate);
                  break;
                case 1:
                  Navigator.pushNamed(context, Route_Names.EligibleCoupleList);
                  break;
                case 2:
                  Navigator.pushNamed(context, Route_Names.PregnantWomenList);
                  break;
                case 3:
                  Navigator.pushNamed(context, Route_Names.Pregnancyoutcome);
                  break;
                case 4:
                  Navigator.pushNamed(context, Route_Names.HBNCListBeneficiaries);
                  break;
                case 5:
                  Navigator.pushNamed(context, Route_Names.Lbwrefered);
                  break;
                 case 6:
                  Navigator.pushNamed(context, Route_Names.Abortionlist);
                   break;
                case 7:
                  Navigator.pushNamed(context, Route_Names.DeathRegister);
                  break;
                case 8:
                  Navigator.pushNamed(context, Route_Names.Migratedout);
                  break;
                case 9:
                  Navigator.pushNamed(context, Route_Names.Guestbeneficiaries);
                  break;
                default:
                  break;
              }
            },
          );
        },
      ),

    );
  }


}

class _BeneficiaryTileData {
  final String title;
  final String asset;
  final int count;
  final bool highlighted;

  const _BeneficiaryTileData({
    required this.title,
    required this.asset,
    required this.count,
    this.highlighted = false,
  });
}

class _BeneficiaryTile extends StatelessWidget {
  final _BeneficiaryTileData data;
  final VoidCallback? onTap;

  const _BeneficiaryTile({
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: data.highlighted ? 2 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.zero,
      color:  Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    data.asset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  style:  TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4A),
                  ),
                ),
              ),
              Text(
                data.count.toString(),
                style:  TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A86CF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
