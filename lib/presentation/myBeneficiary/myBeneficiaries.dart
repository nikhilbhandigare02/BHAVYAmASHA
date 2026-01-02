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
  String? ashaUniqueKey;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      // Get family update count using the new DAO function
      final familyCount = await LocalStorageDao.instance.getFamilyUpdateCount();

      final poCount = await _getPregnancyOutcomeCount();
      final hbnc = await _getHBNCCount();
      final ecCount = await _getEligibleCoupleCount();
      final pwCount = await _getPregnantWomenCount();
      final lbw = await _getLBWReferredCount();
      final abortion = await _getAbortionListCount();
      final death = await _getDeathRegisterCount();
      final migrated = await _getMigratedOutCount();
      final guest = await _getGuestBeneficiaryCount();

      // Update state
      if (mounted) {
        setState(() {
          familyUpdateCount = familyCount;
          eligibleCoupleCount = ecCount;
          pregnantWomenCount = pwCount;
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

  Future<List<Map<String, dynamic>>> _getAncDueRecords() async {
    final db = await DatabaseProvider.instance.database;

    final currentUserData = await SecureStorageService.getCurrentUserData();
    final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
      return [];
    }

    final rows = await db.rawQuery(
      '''
    WITH RankedMCA AS (
      SELECT
        mca.*,
        ROW_NUMBER() OVER (
          PARTITION BY mca.beneficiary_ref_key
          ORDER BY mca.created_date_time DESC, mca.id DESC
        ) AS rn
      FROM mother_care_activities mca
      WHERE
        mca.is_deleted = 0
        AND mca.current_user_key = ?
    )
    SELECT r.*
    FROM RankedMCA r
    INNER JOIN beneficiaries_new bn
      ON r.beneficiary_ref_key = bn.unique_key
    WHERE
      r.rn = 1
      AND r.mother_care_state = 'anc_due'
      AND bn.is_deleted = 0
    ORDER BY r.created_date_time DESC; 
    ''',
      [ashaUniqueKey],
    );

    return rows;
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

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        return 0;
      }

      const ancRefKey = 'bt7gs9rl1a5d26mz';

      final results = await db.rawQuery(
        '''
WITH LatestMCA AS (
  SELECT
    mca.*,
    ROW_NUMBER() OVER (
      PARTITION BY mca.beneficiary_ref_key
      ORDER BY mca.created_date_time DESC, mca.id DESC
    ) AS rn
  FROM mother_care_activities mca
  WHERE mca.is_deleted = 0
    AND mca.current_user_key = ?
),
DeliveryOutcomeOnly AS (
  SELECT *
  FROM LatestMCA
  WHERE rn = 1
    AND mother_care_state = 'delivery_outcome'
),
LatestANC AS (
  SELECT
    f.beneficiary_ref_key,
    f.form_json,
    ROW_NUMBER() OVER (
      PARTITION BY f.beneficiary_ref_key
      ORDER BY f.created_date_time DESC, f.id DESC
    ) AS rn
  FROM ${FollowupFormDataTable.table} f
  WHERE
    f.forms_ref_key = ?
    AND f.is_deleted = 0
    AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
    AND f.current_user_key = ?
)
SELECT
  d.beneficiary_ref_key
FROM DeliveryOutcomeOnly d
LEFT JOIN LatestANC a
  ON a.beneficiary_ref_key = d.beneficiary_ref_key
 AND a.rn = 1
''',
        [ashaUniqueKey, ancRefKey, ashaUniqueKey],
      );

      return results.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getHBNCCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return 0;
      const deliveryOutcomeKey = '4r7twnycml3ej1vg';

      final validBeneficiaries = await db.rawQuery('''
      SELECT DISTINCT mca.beneficiary_ref_key 
      FROM mother_care_activities mca
      WHERE mca.mother_care_state IN ('pnc_mother', 'pnc_mother')
      AND mca.is_deleted = 0
      AND mca.current_user_key = ?
    ''', [ashaUniqueKey]);

      if (validBeneficiaries.isEmpty) return 0;

      final beneficiaryKeys = validBeneficiaries
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id!.isNotEmpty)
          .cast<String>()
          .toList();

      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');
      final dbOutcomes = await db.rawQuery('''
  SELECT DISTINCT ffd.beneficiary_ref_key
  FROM followup_form_data ffd
  INNER JOIN beneficiaries_new bn
      ON bn.unique_key = ffd.beneficiary_ref_key
  WHERE ffd.forms_ref_key = ?
    AND ffd.current_user_key = ?
    AND bn.current_user_key = ?
    AND bn.is_deleted = 0
    AND ffd.beneficiary_ref_key IN ($placeholders)
''', [
        deliveryOutcomeKey,
        ashaUniqueKey,
        ashaUniqueKey,
        ...beneficiaryKeys
      ]);

      final count = dbOutcomes.length;
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getEligibleCoupleCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';
      if (currentUserKey.isEmpty) return 0;

      final query = '''
        SELECT DISTINCT b.*, e.eligible_couple_state 
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND e.current_user_key = ?
        ORDER BY b.created_date_time DESC
      ''';

      final rows = await db.rawQuery(query, [currentUserKey]);
      if (rows.isEmpty) return 0;

      int count = 0;
      for (final row in rows) {
        try {
          final Map<String, dynamic> mappedRow = Map<String, dynamic>.from(row);
          Map<String, dynamic> info = {};
          try {
            info = jsonDecode(mappedRow['beneficiary_info'] ?? '{}');
          } catch (_) {}
          final gender = (info['gender']?.toString().toLowerCase() ?? '');
          if (gender == 'male') continue;
          count++;
        } catch (_) {}
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getPregnantWomenCount() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final processedBeneficiaries = <String>{};
      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final pregnantWomen = <Map<String, dynamic>>[];
      for (final row in rows) {
        try {
          final rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;
          final Map<String, dynamic> info = rawInfo is String
              ? Map<String, dynamic>.from(jsonDecode(rawInfo))
              : Map<String, dynamic>.from(rawInfo as Map);

          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          final isPregnant = _isPregnant(info);
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            pregnantWomen.add({'BeneficiaryID': beneficiaryId, 'unique_key': beneficiaryId});
            processedBeneficiaries.add(beneficiaryId);
          }
        } catch (_) {}
      }

      for (final anc in ancDueRecords) {
        final beneficiaryId = anc['beneficiary_ref_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty || processedBeneficiaries.contains(beneficiaryId)) continue;
        pregnantWomen.add({'BeneficiaryID': beneficiaryId, 'unique_key': beneficiaryId});
      }

      final byBeneficiary = <String, Map<String, dynamic>>{};
      for (final item in pregnantWomen) {
        final benId = item['BeneficiaryID']?.toString() ?? '';
        final uniqueKey = item['unique_key']?.toString() ?? '';
        final key = benId.isNotEmpty ? benId : uniqueKey;
        if (key.isEmpty) continue;
        byBeneficiary[key] = item;
      }

      return byBeneficiary.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getLBWReferredCount() async {
    try {
      final db = await DatabaseProvider.instance.database;


      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final rows = await db.query(
        BeneficiariesTable.table,
        // 2. Add current_user_key condition
        where: 'is_deleted = 0 AND (is_adult = 0 OR is_adult IS NULL) AND current_user_key = ?',
        whereArgs: [ashaUniqueKey],
      );

      int count = 0;

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

          // Flexible LBW condition logic - matches _loadLbwChildren()
          bool isLbw = false;

          if (weight != null && birthWeight != null) {
            // Both present: BOTH must satisfy their conditions
            isLbw = (weight <= 1.6 && birthWeight <= 1600);
          } else if (weight != null && birthWeight == null) {
            // Only weight present: check weight condition only
            isLbw = (weight <= 1.6);
          } else if (weight == null && birthWeight != null) {
            // Only birthWeight present: check birthWeight condition only
            isLbw = (birthWeight <= 1600);
          }
          // If both are null, isLbw remains false

          if (isLbw) count++;

        } catch (e) {
          print('Error processing beneficiary LBW row in count: $e');
        }
      }

      return count;
    } catch (e) {
      print('Error loading LBW count: $e');
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
