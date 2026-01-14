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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData().then((_) {
        debugPrint('ELIGIBLE COUPLES COUNT: ${_items.length}');
      });
    });
    LocalStorageDao.instance.getAllBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // Helper function to extract beneficiary info from a row
  Map<String, dynamic> _getBeneficiaryInfo(Map<String, dynamic> beneficiary) {
    try {
      final rawInfo = beneficiary['beneficiary_info'];
      Map<String, dynamic> info;
      if (rawInfo is Map) {
        info = Map<String, dynamic>.from(rawInfo);
      } else if (rawInfo is String && rawInfo.isNotEmpty) {
        info = Map<String, dynamic>.from(jsonDecode(rawInfo));
      } else {
        info = <String, dynamic>{};
      }
      return info;
    } catch (_) {
      return <String, dynamic>{};
    }
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
    if (mounted) setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      /// ---------- HOUSEHOLDS ----------
      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
        orderBy: 'created_date_time DESC',
      );

      final Map<String, Map<String, dynamic>> householdByKey = {
        for (final h in households)
          (h['unique_key'] ?? '').toString(): h,
      };

      Map<String, dynamic> extractHouseholdExtra(Map<String, dynamic> hh) {
        final familyHead = _safeJson(hh['family_head_details']);
        return {
          'name': (familyHead['name'] ?? familyHead['headName'] ?? '').toString(),
          'houseNo': _extractHouseNo(hh),
          'mobile': '',
        };
      }

      /// ---------- ANC DUE ----------
      final motherCareActivities = await db.rawQuery(
        '''
      SELECT household_ref_key FROM mother_care_activities
      WHERE current_user_key = ? AND mother_care_state = 'anc_due'
      ''',
        [currentUserKey],
      );

      final ancDueCountMap = <String, int>{};
      for (final m in motherCareActivities) {
        final hhKey = (m['household_ref_key'] ?? '').toString();
        if (hhKey.isNotEmpty) {
          ancDueCountMap[hhKey] = (ancDueCountMap[hhKey] ?? 0) + 1;
        }
      }

      /// ---------- GROUP BENEFICIARIES ----------
      final Map<String, List<Map<String, dynamic>>> beneficiariesByHH = {};
      for (final r in rows) {
        final hhKey = (r['household_ref_key'] ?? '').toString();
        if (hhKey.isNotEmpty) {
          beneficiariesByHH.putIfAbsent(hhKey, () => []).add(r);
        }
      }

      /// ---------- ELIGIBLE COUPLES ----------
      final eligibleCoupleCountMap = <String, int>{};

      beneficiariesByHH.forEach((hhKey, members) {
        int marriedMales = 0;
        int marriedFemales = 0;

        for (final b in members) {
          if (b['is_deleted'] == 1 || b['is_migrated'] == 1 || b['is_death'] == 1) continue;

          final info = _safeJson(b['beneficiary_info']);
          if ((info['maritalStatus'] ?? '').toString().toLowerCase() != 'married') continue;

          final gender = (info['gender'] ?? '').toString().toLowerCase();
          if (gender == 'male') marriedMales++;
          if (gender == 'female') marriedFemales++;
        }

        eligibleCoupleCountMap[hhKey] =
            marriedMales + marriedFemales + (ancDueCountMap[hhKey] ?? 0);
      });

      /// ---------- FAMILY HEADS ----------
      final familyHeads = rows.where((r) {
        final hhKey = (r['household_ref_key'] ?? '').toString();
        if (hhKey.isEmpty) return false;
        if (r['is_deleted'] == 1 || r['is_migrated'] == 1 || r['is_death'] == 1) return false;

        final info = _safeJson(r['beneficiary_info']);
        final rel = (info['relation_to_head'] ?? info['relation'] ?? '')
            .toString()
            .toLowerCase();

        return rel == 'head' || rel == 'self' || info['isFamilyHead'] == true;
      }).toList();

      /// ---------- MAP TO UI ----------
      final mapped = familyHeads.map<Map<String, dynamic>>((r) {
        final info = _safeJson(r['beneficiary_info']);
        final hhKey = (r['household_ref_key'] ?? '').toString();
        final hh = householdByKey[hhKey];
        final hhExtra = hh != null ? extractHouseholdExtra(hh) : {};
        final members = beneficiariesByHH[hhKey] ?? [];

        final uniqueKey = (r['unique_key'] ?? '').toString();
        final headId = uniqueKey.length > 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        return {
          'name': (info['headName'] ??
              info['memberName'] ??
              info['name'] ??
              hhExtra['name'] ??
              '')
              .toString(),
          'mobile': (info['mobileNo'] ?? '').toString(),
          'hhId': headId,
          'houseNo': info['houseNo'] ?? hhExtra['houseNo'] ?? '',
          'totalMembers': members.isNotEmpty ? members.length : 1,
          'elderly': 0,
          'pregnantWomen': ancDueCountMap[hhKey] ?? 0,
          'eligibleCouples': eligibleCoupleCountMap[hhKey] ?? 0,
          'child0to1': 0,
          'child1to2': 0,
          'child2to5': 0,
          'hasChildrenTarget': false,
          'remainingChildren': 0,
          '_raw': r,
        };
      }).toList();

      /// ---------- FALLBACK HOUSEHOLDS ----------
      final existingHH = mapped.map((e) => e['_raw']['household_ref_key']).toSet();
      final fallbackMapped = <Map<String, dynamic>>[];

      for (final hh in households) {
        final hhKey = (hh['unique_key'] ?? '').toString();
        if (existingHH.contains(hhKey)) continue;

        final extra = extractHouseholdExtra(hh);

        fallbackMapped.add({
          'name': extra['name'],
          'mobile': '',
          'hhId': hhKey.length > 11 ? hhKey.substring(hhKey.length - 11) : hhKey,
          'houseNo': extra['houseNo'],
          'totalMembers': 1,
          'elderly': 0,
          'pregnantWomen': 0,
          'eligibleCouples': 0,
          'child0to1': 0,
          'child1to2': 0,
          'child2to5': 0,
          'hasChildrenTarget': false,
          'remainingChildren': 0,
          '_raw': {
            'household_ref_key': hhKey,
            'created_date_time': hh['created_date_time'],
          },
        });
      }

      final combined = [...mapped, ...fallbackMapped];

      combined.sort((a, b) {
        final da = _resolveSortDate(a['_raw']);
        final db = _resolveSortDate(b['_raw']);
        return db.compareTo(da);
      });

      if (mounted) {
        setState(() {
          _items = combined;
          _filtered = List<Map<String, dynamic>>.from(combined);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _safeJson(dynamic value) {
    try {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty && value != '{}') {
        return Map<String, dynamic>.from(jsonDecode(value));
      }
    } catch (_) {}
    return {};
  }

  DateTime _resolveSortDate(Map<String, dynamic> raw) {
    try {
      final v = raw['created_date_time'];
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _extractHouseNo(Map<String, dynamic> hh) {
    // ---------- 1️⃣ household_info ----------
    final householdInfo = _safeJson(hh['household_info']);

    final h1 = householdInfo['houseNo']?.toString().trim();
    if (h1 != null && h1.isNotEmpty && h1 != ',') return h1;

    final h2 = householdInfo['house_no']?.toString().trim();
    if (h2 != null && h2.isNotEmpty && h2 != ',') return h2;

    // ---------- 2️⃣ address table JSON ----------
    final address = _safeJson(hh['address']);

    final h3 = address['house_no']?.toString().trim();
    if (h3 != null && h3.isNotEmpty && h3 != ',') return h3;

    final h4 = address['houseNo']?.toString().trim();
    if (h4 != null && h4.isNotEmpty && h4 != ',') return h4;

    return '';
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
