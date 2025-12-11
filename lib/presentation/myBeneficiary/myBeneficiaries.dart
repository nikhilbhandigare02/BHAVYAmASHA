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

      final households = <String, List<Map<String, dynamic>>>{};
      for (final row in allBeneficiaries) {
        try {
          final hhId = row['household_ref_key']?.toString() ?? '';
          if (hhId.isEmpty) continue;
          
          final info = row['beneficiary_info'] is String 
              ? jsonDecode(row['beneficiary_info'] as String) 
              : (row['beneficiary_info'] as Map?) ?? {};
              
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
      
      int familyCount = households.length;
      int coupleCount = 0;
      int pregnantCount = 0;

      for (final members in households.values) {
        for (final member in members) {
          try {
            final info = member['info'] as Map;

            final gender = info['gender']?.toString().toLowerCase() ?? '';
            if (gender != 'female' && gender != 'f') continue;

            final maritalStatus = info['maritalStatus']?.toString().toLowerCase() ?? '';
            if (maritalStatus != 'married') continue;

            final dob = info['dob'];
            final age = _calculateAge(dob);
            if (age >= 15 && age <= 49) {
              coupleCount++;
            }
          } catch (e) {
            print('Error counting eligible couple: $e');
          }
        }
      }

      for (final members in households.values) {
        for (final member in members) {
          try {
            final info = Map<String, dynamic>.from(member['info'] as Map);
            if (_isPregnant(info)) {
              pregnantCount++;
            }
          } catch (e) {
            print('Error counting pregnant women: $e');
          }
        }
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
