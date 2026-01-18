import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';

class FamliyUpdate extends StatefulWidget {
  const FamliyUpdate({super.key});

  @override
  State<FamliyUpdate> createState() => _FamliyUpdateState();
}

class _FamliyUpdateState extends State<FamliyUpdate> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchCtrl.addListener(_onSearchChanged);
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
        _filtered = List<Map<String, dynamic>>.from(_items);
      } else {
        _filtered = _items.where((e) {
          final hhId = (e['hhId'] ?? '').toString().toLowerCase();
          final houseNo = (e['houseNo'] ?? '').toString().toLowerCase();
          final name = (e['name'] ?? '').toString().toLowerCase();
          final mobile = (e['mobile'] ?? '').toString().toLowerCase();

          final raw = (e['_raw'] as Map<String, dynamic>? ?? const {});
          final fullHhRef = (raw['household_ref_key'] ?? '').toString();
          final searchHhRef = fullHhRef.length > 11
              ? fullHhRef.substring(fullHhRef.length - 11).toLowerCase()
              : fullHhRef.toLowerCase();

          return hhId.contains(q) ||
              houseNo.contains(q) ||
              name.contains(q) ||
              mobile.contains(q) ||
              searchHhRef.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      /// ------------------ HOUSEHOLDS ------------------
      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
        orderBy: 'id DESC',
      );

      /// household_ref_key -> head_unique_key
      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhKey = hh['unique_key']?.toString() ?? '';
        final headId = hh['head_id']?.toString() ?? '';
        if (hhKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhKey] = headId;
        }
      }

      /// ------------------ ANC DUE ------------------
      final ancDueRows = await db.rawQuery(
        '''
      SELECT household_ref_key FROM mother_care_activities
      WHERE current_user_key = ?
        AND mother_care_state = 'anc_due'
      ''',
        [currentUserKey],
      );

      final Map<String, int> ancDueCountMap = {};
      for (final r in ancDueRows) {
        final hhKey = r['household_ref_key']?.toString();
        if (hhKey != null && hhKey.isNotEmpty) {
          ancDueCountMap[hhKey] = (ancDueCountMap[hhKey] ?? 0) + 1;
        }
      }

      /// ------------------ AGE & CATEGORY MAPS ------------------
      final Map<String, int> elderlyCountMap = {};
      final Map<String, int> child0to1Map = {};
      final Map<String, int> child1to2Map = {};
      final Map<String, int> child2to5Map = {};
      final Map<String, int> eligibleCoupleCountMap = {};

      /// ------------------ GROUP BY HOUSEHOLD ------------------
      final Map<String, List<Map<String, dynamic>>> byHousehold = {};
      for (final r in rows) {
        final hhKey = r['household_ref_key']?.toString();
        if (hhKey != null && hhKey.isNotEmpty) {
          byHousehold.putIfAbsent(hhKey, () => []).add(r);
        }
      }

      /// ------------------ ELIGIBLE COUPLES ------------------
      byHousehold.forEach((hhKey, members) {
        int count = 0;

        for (final m in members) {
          if (m['is_deleted'] == 1 || m['is_migrated'] == 1 || m['is_death'] == 1) {
            continue;
          }

          final info = m['beneficiary_info'] is String
              ? jsonDecode(m['beneficiary_info'])
              : (m['beneficiary_info'] ?? {});

          final marital = info['maritalStatus']?.toString().toLowerCase();
          if (marital != 'married') continue;

          final gender = info['gender']?.toString().toLowerCase();
          final isPregnant =
              info['isPregnant'] == true ||
                  info['isPregnant']?.toString().toLowerCase() == 'yes';

          if (gender == 'male') {
            count += 1;
          } else if (gender == 'female' && !isPregnant) {
            count += 1;
          }
        }

        count += ancDueCountMap[hhKey] ?? 0;
        eligibleCoupleCountMap[hhKey] = count;
      });

      /// ------------------ AGE CALCULATIONS ------------------
      for (final r in rows) {
        if (r['is_deleted'] == 1 || r['is_migrated'] == 1 || r['is_death'] == 1) {
          continue;
        }

        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : (r['beneficiary_info'] ?? {});

        final hhKey = r['household_ref_key']?.toString();
        if (hhKey == null || hhKey.isEmpty) continue;

        final dobRaw = info['dob'] ?? info['dateOfBirth'];
        if (dobRaw == null) continue;

        DateTime? dob = DateTime.tryParse(dobRaw.toString());
        if (dob == null) continue;

        final now = DateTime.now();
        int months =
            (now.year - dob.year) * 12 + (now.month - dob.month);
        if (now.day < dob.day) months--;

        final isChild =
            info['memberType']?.toString().toLowerCase() == 'child' ||
                info['relation']?.toString().toLowerCase() == 'child';

        if (isChild) {
          if (months < 12) {
            child0to1Map[hhKey] = (child0to1Map[hhKey] ?? 0) + 1;
          } else if (months <= 25) {
            child1to2Map[hhKey] = (child1to2Map[hhKey] ?? 0) + 1;
          } else if (months < 60) {
            child2to5Map[hhKey] = (child2to5Map[hhKey] ?? 0) + 1;
          }
        }

        if (months >= 65 * 12) {
          elderlyCountMap[hhKey] = (elderlyCountMap[hhKey] ?? 0) + 1;
        }
      }

      /// ------------------ FAMILY HEAD IDENTIFICATION (FINAL) ------------------
      final familyHeads = rows.where((r) {
        final hhKey = r['household_ref_key']?.toString();
        final uniqueKey = r['unique_key']?.toString();

        if (hhKey == null || uniqueKey == null) return false;
        if (r['is_deleted'] == 1 || r['is_migrated'] == 1 || r['is_death'] == 1) {
          return false;
        }

        return headKeyByHousehold[hhKey] == uniqueKey;
      }).toList();

      /// ------------------ MAP TO UI ------------------
      final List<Map<String, dynamic>> mapped = familyHeads.map((r) {
        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : (r['beneficiary_info'] ?? {});

        final hhKey = r['household_ref_key']?.toString() ?? '';

        return {
          'name': info['headName'] ?? info['name'] ?? '',
          'mobile': info['mobileNo'] ?? '',
          'hhId': r['unique_key'],
          'totalMembers': byHousehold[hhKey]?.length ?? 0,
          'elderly': elderlyCountMap[hhKey] ?? 0,
          'pregnantWomen': ancDueCountMap[hhKey] ?? 0,
          'eligibleCouples': eligibleCoupleCountMap[hhKey] ?? 0,
          'child0to1': child0to1Map[hhKey] ?? 0,
          'child1to2': child1to2Map[hhKey] ?? 0,
          'child2to5': child2to5Map[hhKey] ?? 0,
          '_raw': r,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _items = mapped;
          _filtered = List<Map<String, dynamic>>.from(mapped);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(screenTitle: l10n!.familyUpdate, showBack: true),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noDataFound,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.builder(
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseHold_BeneficiaryScreen(
              houseNo: data['houseNo']?.toString(),
              hhId: data['_raw']['household_ref_key']?.toString() ?? '',
            ),
          ),
        );

        if (mounted) {
          _loadData();
        }
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
                      const Icon(
                        Icons.home,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (data['_raw']['household_ref_key']?.toString().length ??
                                    0) >
                                11
                            ? data['_raw']['household_ref_key']
                                  .toString()
                                  .substring(
                                    data['_raw']['household_ref_key']
                                            .toString()
                                            .length -
                                        11,
                                  )
                            : (data['_raw']['household_ref_key']?.toString() ??
                                  ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
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
                  Row(
                    children: [
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mobileNo} : ",
                          data['mobile']?.toString() ?? l10n!.na,
                          isWrappable: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mohalla} : ",
                          data['mohalla']?.toString() ??
                              data['mohallaTola']?.toString() ??
                              l10n!.na,
                          isWrappable: true,
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

  Widget _infoRow(String? title, String value, {bool isWrappable = false}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$title ',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? l10n!.na : value,
              style: TextStyle(
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
