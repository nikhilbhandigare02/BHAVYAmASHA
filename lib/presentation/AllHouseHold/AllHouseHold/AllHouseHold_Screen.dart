import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../HouseHole_Beneficiery/HouseHold_Beneficiery.dart';

class AllhouseholdScreen extends StatefulWidget {
  const AllhouseholdScreen({super.key});

  @override
  State<AllhouseholdScreen> createState() => _AllhouseholdScreenState();
}

class _AllhouseholdScreenState extends State<AllhouseholdScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  Map<String, dynamic>? _headForm;
  final List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    LocalStorageDao.instance.getAllBeneficiaries();
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
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      /// ---------------- HOUSEHOLDS ----------------
      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
        orderBy: 'created_date_time DESC',
      );

      /// ---------------- EC ACTIVITIES ----------------
      final ecActivities = await db.rawQuery(
        '''
      SELECT * FROM eligible_couple_activities
      WHERE current_user_key = ? AND is_deleted = 0
      AND (eligible_couple_state LIKE '%eligible_couple%'
           OR eligible_couple_state LIKE '%tracking_due%')
      ''',
        [currentUserKey],
      );

      /// ---------------- MOTHER CARE ACTIVITIES ----------------
      final motherCareActivities = await db.rawQuery(
        '''
      SELECT * FROM mother_care_activities
      WHERE current_user_key = ?
      AND mother_care_state = 'anc_due'
      AND is_deleted = 0
      ''',
        [currentUserKey],
      );

      /// =========================================================
      /// LATEST DATE PER HOUSEHOLD (IMPORTANT)
      /// =========================================================
      final Map<String, DateTime> latestDateByHousehold = {};

      void updateLatestDate(String hhKey, String? dateStr) {
        if (hhKey.isEmpty || dateStr == null) return;
        final dt = DateTime.tryParse(dateStr);
        if (dt == null) return;

        if (!latestDateByHousehold.containsKey(hhKey) ||
            dt.isAfter(latestDateByHousehold[hhKey]!)) {
          latestDateByHousehold[hhKey] = dt;
        }
      }

      /// ---- From beneficiaries ----
      for (final r in rows) {
        updateLatestDate(
          (r['household_ref_key'] ?? '').toString(),
          r['created_date_time']?.toString(),
        );
      }

      /// ---- From EC activities ----
      for (final ec in ecActivities) {
        updateLatestDate(
          (ec['household_ref_key'] ?? '').toString(),
          ec['created_date_time']?.toString(),
        );
      }

      /// ---- From mother care activities ----
      for (final mc in motherCareActivities) {
        updateLatestDate(
          (mc['household_ref_key'] ?? '').toString(),
          mc['created_date_time']?.toString(),
        );
      }

      /// =========================================================
      /// EXISTING COUNT LOGIC (UNCHANGED)
      /// =========================================================
      final elderlyCountMap = <String, int>{};
      final child0to1Map = <String, int>{};
      final child1to2Map = <String, int>{};
      final child2to5Map = <String, int>{};
      final ancDueCountMap = <String, int>{};
      final eligibleCoupleTrackingDueCountMap = <String, int>{};

      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhRefKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhRefKey] = headId;
        }
      }

      /// ---- Eligible couples unique count ----
      final ecSet = <String, Set<String>>{};
      for (final ec in ecActivities) {
        final hhKey = (ec['household_ref_key'] ?? '').toString();
        final benKey = (ec['beneficiary_ref_key'] ?? '').toString();
        if (hhKey.isEmpty || benKey.isEmpty) continue;

        ecSet.putIfAbsent(hhKey, () => <String>{});
        ecSet[hhKey]!.add(benKey);
      }
      ecSet.forEach(
            (k, v) => eligibleCoupleTrackingDueCountMap[k] = v.length,
      );

      /// ---- ANC due count ----
      for (final mc in motherCareActivities) {
        final hhKey = (mc['household_ref_key'] ?? '').toString();
        if (hhKey.isEmpty) continue;
        ancDueCountMap[hhKey] = (ancDueCountMap[hhKey] ?? 0) + 1;
      }

      /// =========================================================
      /// FAMILY HEAD FILTER + UI MAPPING
      /// =========================================================
      final familyHeads = rows.where((r) {
        if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;
        final hhKey = (r['household_ref_key'] ?? '').toString();
        final uk = (r['unique_key'] ?? '').toString();
        if (hhKey.isEmpty || uk.isEmpty) return false;

        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : r['beneficiary_info'] ?? {};

        final relation =
        (info['relation_to_head'] ?? info['relation'] ?? '')
            .toString()
            .toLowerCase();

        return headKeyByHousehold[hhKey] == uk ||
            relation == 'head' ||
            relation == 'self' ||
            info['isFamilyHead'] == true;
      }).toList();

      final mapped = familyHeads.map<Map<String, dynamic>>((r) {
        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : r['beneficiary_info'] ?? {};

        final hhKey = (r['household_ref_key'] ?? '').toString();

        return {
          'name': info['name'] ?? '',
          'mobile': info['mobileNo'] ?? '',
          'hhId': hhKey.length > 11 ? hhKey.substring(hhKey.length - 11) : hhKey,
          'elderly': elderlyCountMap[hhKey] ?? 0,
          'pregnantWomen': ancDueCountMap[hhKey] ?? 0,
          'eligibleCouples':
          eligibleCoupleTrackingDueCountMap[hhKey] ?? 0,
          'child0to1': child0to1Map[hhKey] ?? 0,
          'child1to2': child1to2Map[hhKey] ?? 0,
          'child2to5': child2to5Map[hhKey] ?? 0,
          'latestDate': latestDateByHousehold[hhKey],
          '_raw': r,
        };
      }).toList();

      /// =========================================================
      /// FINAL SORT (LATEST FIRST)
      /// =========================================================
      mapped.sort((a, b) {
        final da = a['latestDate'] as DateTime?;
        final dbb = b['latestDate'] as DateTime?;

        if (da != null && dbb != null) return dbb.compareTo(da);
        if (da != null) return -1;
        if (dbb != null) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _items = mapped;
          _filtered = List<Map<String, dynamic>>.from(mapped);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridAllHousehold ?? 'All Household',
        showBack: false,
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: CustomDrawer(),
      body: _isLoading
          ? const CenterBoxLoader()
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l10n?.searchHousehold ?? 'Household search',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Padding(
                //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                //   child: Align(
                //     alignment: Alignment.centerLeft,
                //     child: Text(
                //       'Total Households: ${_items.length}',
                //       style: const TextStyle(
                //         fontWeight: FontWeight.w600,
                //         color: Colors.black87,
                //       ),
                //     ),
                //   ),
                // ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            (l10n?.noDataFound ?? 'No data found'),
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
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 35,
                      child: RoundButton(
                        title:
                            l10n?.newHouseholdRegistration ??
                            'NEW HOUSEHOLD REGISTRATION',
                        color: AppColors.primary,
                        borderRadius: 8,
                        height: 6.h,
                        onPress: () {
                          Navigator.pushNamed(
                            context,
                            Route_Names.RegisterNewHousehold,
                          );
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white, // full card base
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
            // Top section
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
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
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Text(
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${data['houseNo'] ?? data['_raw']['beneficiary_info']?['houseNo'] ?? ''}',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 24,
                    child: RoundButton(
                      icon: Icons.edit,
                      iconSize: 14.sp,
                      title: l10n?.edit ?? 'Edit',
                      color: AppColors.primary,
                      borderRadius: 4,
                      height: 3.h,
                      fontSize: 14.sp,
                      onPress: () async {
                        try {
                          final hhKey =
                              data['_raw']['household_ref_key']?.toString() ??
                              '';
                          if (hhKey.isEmpty) {
                            return;
                          }

                          final members = await LocalStorageDao.instance
                              .getBeneficiariesByHousehold(hhKey);
                          if (members.isEmpty) {
                            return;
                          }

                          Map<String, dynamic>? headRow;
                          final configuredHeadKey = data['_raw']['unique_key']
                              ?.toString();
                          if (configuredHeadKey != null &&
                              configuredHeadKey.isNotEmpty) {
                            for (final m in members) {
                              if ((m['unique_key'] ?? '').toString() ==
                                  configuredHeadKey) {
                                headRow = m;
                                break;
                              }
                            }
                          }

                          headRow ??= members.first;

                          Map<String, dynamic> info;
                          final rawInfo = headRow['beneficiary_info'];
                          if (rawInfo is Map<String, dynamic>) {
                            info = rawInfo;
                          } else if (rawInfo is String && rawInfo.isNotEmpty) {
                            info = Map<String, dynamic>.from(
                              jsonDecode(rawInfo) as Map,
                            );
                          } else {
                            info = <String, dynamic>{};
                          }

                          final map = <String, String>{};
                          info.forEach((key, value) {
                            if (value != null) {
                              map[key] = value.toString();
                            }
                          });

                          map['hh_unique_key'] = hhKey;
                          map['head_unique_key'] =
                              headRow['unique_key']?.toString() ?? '';
                          if (headRow['id'] != null) {
                            map['head_id_pk'] = headRow['id'].toString();
                          }

                          try {
                            Map<String, dynamic>? spouseRow;

                            for (final m in members) {
                              final rawSpInfo = m['beneficiary_info'];
                              Map<String, dynamic> sInfo;
                              if (rawSpInfo is Map<String, dynamic>) {
                                sInfo = rawSpInfo;
                              } else if (rawSpInfo is String &&
                                  rawSpInfo.isNotEmpty) {
                                try {
                                  sInfo = Map<String, dynamic>.from(
                                    jsonDecode(rawSpInfo) as Map,
                                  );
                                } catch (_) {
                                  continue;
                                }
                              } else {
                                continue;
                              }

                              final rel =
                                  (sInfo['relation_to_head'] ??
                                          sInfo['relation'])
                                      ?.toString()
                                      .toLowerCase();
                              if (rel == 'spouse' ||
                                  rel == 'wife' ||
                                  rel == 'husband') {
                                spouseRow = m;
                                break;
                              }
                            }

                            if (spouseRow != null) {
                              final rawSpInfo = spouseRow['beneficiary_info'];
                              Map<String, dynamic> spInfo;
                              if (rawSpInfo is Map<String, dynamic>) {
                                spInfo = rawSpInfo;
                              } else if (rawSpInfo is String &&
                                  rawSpInfo.isNotEmpty) {
                                spInfo = Map<String, dynamic>.from(
                                  jsonDecode(rawSpInfo) as Map,
                                );
                              } else {
                                spInfo = <String, dynamic>{};
                              }

                              map['spouse_unique_key'] =
                                  spouseRow['unique_key']?.toString() ?? '';
                              if (spouseRow['id'] != null) {
                                map['spouse_id_pk'] = spouseRow['id']
                                    .toString();
                              }

                              spInfo.forEach((key, value) {
                                if (value != null) {
                                  map['sp_$key'] = value.toString();
                                }
                              });
                            }
                          } catch (_) {}

                          map['headName'] ??= data['name']?.toString() ?? '';
                          map['mobileNo'] ??= data['mobile']?.toString() ?? '';

                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddNewFamilyHeadScreen(
                                isEdit: true,
                                initial: map,
                              ),
                            ),
                          );
                        } catch (_) {}
                      },
                    ),
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(0),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(l10n?.thName ?? 'Name', data['name']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile no.',
                          data['mobile'],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.rnhTotalMembers ?? 'No. of total members',
                          data['totalMembers'].toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.eligibleCouples ?? 'Eligible couples',
                          data['eligibleCouples'].toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.pregnantWomen ?? 'Pregnant women',
                          data['pregnantWomen'].toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.elderlyAbove65 ?? 'Elderly (>65 Y)',
                          data['elderly'].toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.children0to1 ?? '0-1 year old children',
                          data['child0to1'].toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.children1to2 ?? '1-2 year old children',
                          data['child1to2'].toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.children2to5 ?? '2-5 year old children',
                          data['child2to5'].toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (data['hasChildrenTarget'] == true &&
                ((data['remainingChildren'] ?? 0) as int) > 0)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      '${l10n?.memberRemainsToAdd ?? 'Remaining to add'}: ',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Text(
                      '${data['remainingChildren']} '
                      '${data['remainingChildren'] > 1 ? '' : ''}',
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
}
