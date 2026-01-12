import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import '../../RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';

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
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Use same data fetching logic as AllHouseHold_Screen.dart
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final currentUserKey = currentUserData?['unique_key']?.toString() ?? '';

      final households = await LocalStorageDao.instance.getAllHouseholds();

      // Query database directly to get eligible couple activities records for eligible_couple and tracking_due states
      final ecActivities = await db.rawQuery(
        '''
        SELECT * FROM eligible_couple_activities 
        WHERE current_user_key = ? AND is_deleted = 0 
        AND (eligible_couple_state LIKE '%eligible_couple%' OR eligible_couple_state LIKE '%tracking_due%')
        ORDER BY created_date_time ASC
      ''',
        [currentUserKey],
      );

      // Query database directly to get mother care activities records for ANC due count
      final motherCareActivities = await db.rawQuery(
        '''
        SELECT * FROM mother_care_activities 
        WHERE current_user_key = ? AND mother_care_state = 'anc_due' AND is_deleted = 0
        ORDER BY created_date_time ASC
      ''',
        [currentUserKey],
      );

      final pregnantCountMap = <String, int>{};
      final ancDueCountMap = <String, int>{};
      final elderlyCountMap = <String, int>{};
      final child0to1Map = <String, int>{};
      final child1to2Map = <String, int>{};
      final child2to5Map = <String, int>{};
      final eligibleCoupleTrackingDueCountMap = <String, int>{};

      /// --------- ELIGIBLE COUPLE COUNTS (ELIGIBLE_COUPLE OR TRACKING_DUE STATES) ----------
      final eligibleCoupleUniqueSet = <String, Set<String>>{};
      for (final ec in ecActivities) {
        try {
          final hhKey = (ec['household_ref_key'] ?? '').toString();
          final beneficiaryKey = (ec['beneficiary_ref_key'] ?? '').toString();
          if (hhKey.isEmpty || beneficiaryKey.isEmpty) continue;

          // Count unique beneficiaries per household with state containing 'eligible_couple' or 'tracking_due'
          eligibleCoupleUniqueSet.putIfAbsent(hhKey, () => <String>{});
          eligibleCoupleUniqueSet[hhKey]!.add(beneficiaryKey);
        } catch (_) {}
      }

      // Convert sets to counts
      for (final hhKey in eligibleCoupleUniqueSet.keys) {
        eligibleCoupleTrackingDueCountMap[hhKey] = eligibleCoupleUniqueSet[hhKey]!.length;
      }

      /// --------- ANC DUE COUNTS (PREGNANT WOMEN) ----------
      for (final ma in motherCareActivities) {
        try {
          final hhKey = (ma['household_ref_key'] ?? '').toString();
          if (hhKey.isEmpty) continue;

          // Count ANC due records for pregnant women calculation
          ancDueCountMap[hhKey] = (ancDueCountMap[hhKey] ?? 0) + 1;
        } catch (_) {}
      }

      /// --------- AGGREGATE COUNTS ----------
      List<Map<String, dynamic>> rows;
      try {
        rows = await LocalStorageDao.instance.getAllBeneficiaries();
      } catch (_) {
        rows = <Map<String, dynamic>>[];
      }
      for (final row in rows) {
        try {
          final info = Map<String, dynamic>.from(
            (row['beneficiary_info'] is String
                ? jsonDecode(row['beneficiary_info'])
                : row['beneficiary_info'] ?? {}),
          );

          final householdRefKey = (row['household_ref_key'] ?? '').toString();

          // Check if this is a child record (same logic as RegisterChildListScreen)
          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          final relation = info['relation']?.toString().toLowerCase() ?? '';
          final isChild = memberType == 'child' ||
              relation == 'child' ||
              memberType == 'Child' ||
              relation == 'daughter';

          // Pregnant
          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes' ||
                  info['isPregnant'] == true;

          if (isPregnant) {
            pregnantCountMap[householdRefKey] =
                (pregnantCountMap[householdRefKey] ?? 0) + 1;
          }

          final dob = info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
          if (dob != null && dob.toString().isNotEmpty) {
            DateTime? birthDate;

            // Use same date parsing logic as RegisterChildListScreen
            String dateStr = dob.toString();
            birthDate = DateTime.tryParse(dateStr);

            if (birthDate == null) {
              final timestamp = int.tryParse(dateStr);
              if (timestamp != null && timestamp > 0) {
                birthDate = DateTime.fromMillisecondsSinceEpoch(
                  timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                  isUtc: true,
                );
              }
            }

            if (birthDate != null) {
              final now = DateTime.now();
              int years = now.year - birthDate.year;
              int months = now.month - birthDate.month;
              int days = now.day - birthDate.day;

              if (days < 0) {
                final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
                final lastMonthYear = now.month - 1 < 1
                    ? now.year - 1
                    : now.year;
                final daysInLastMonth = DateTime(
                  lastMonthYear,
                  lastMonth + 1,
                  0,
                ).day;
                days += daysInLastMonth;
                months--;
              }

              if (months < 0) {
                months += 12;
                years--;
              }

              // Convert to total months for easier categorization
              int totalMonths = years * 12 + months;
              if (days < 0) totalMonths--; // Adjust if not yet reached birthday this month

              // Only categorize as child if memberType indicates it's a child
              if (isChild) {
                if (totalMonths >= 0 && totalMonths < 12) {
                  child0to1Map[householdRefKey] =
                      (child0to1Map[householdRefKey] ?? 0) + 1;
                } else if (totalMonths >= 12 && totalMonths <= 25) {
                  // Include exactly 2 years (24 months) in 1-2 year category
                  child1to2Map[householdRefKey] =
                      (child1to2Map[householdRefKey] ?? 0) + 1;
                } else if (totalMonths >= 26 && totalMonths < 60) {
                  // Above 2 years (25+ months) in 2-5 year category
                  child2to5Map[householdRefKey] =
                      (child2to5Map[householdRefKey] ?? 0) + 1;
                }
              }

              // Still check for elderly regardless of memberType
              if (totalMonths >= 65 * 12) {
                elderlyCountMap[householdRefKey] =
                    (elderlyCountMap[householdRefKey] ?? 0) + 1;
              }
            }
          }
        } catch (_) {}
      }

      List<Map<String, dynamic>> mapFromHouseholds() {
        int countMembersFromHouseholdInfo(Map<String, dynamic> hhInfo) {
          try {
            final rawAll = hhInfo['all_members'] ??
                hhInfo['allMembers'] ??
                hhInfo['members'];
            List<dynamic> list = const [];
            if (rawAll is List) {
              list = rawAll;
            } else if (rawAll is String && rawAll.trim().isNotEmpty) {
              final decoded = jsonDecode(rawAll);
              if (decoded is List) list = decoded;
            }

            int count = 0;
            for (final e in list) {
              if (e is Map) {
                if (e['memberDetails'] != null) count++;
                if (e['spouseDetails'] != null) count++;
              }
            }
            return count;
          } catch (_) {
            return 0;
          }
        }

        return households.map<Map<String, dynamic>>((hh) {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final hhInfoRaw = hh['household_info'];
          final hhInfo = hhInfoRaw is Map
              ? Map<String, dynamic>.from(hhInfoRaw)
              : <String, dynamic>{};

          final head = hhInfo['family_head_details'] is Map
              ? Map<String, dynamic>.from(hhInfo['family_head_details'])
              : <String, dynamic>{};

          final String headName = (head['name_of_family_head'] ??
              head['head_name'] ??
              hhInfo['head_name'] ??
              '')
              .toString();

          final String mobile = (head['mobile_no_of_family_head'] ??
              head['mobileNo'] ??
              head['mobile_no'] ??
              '')
              .toString();

          final dynamic houseNo =
              head['house_no'] ?? hhInfo['house_no'] ?? hhInfo['houseNo'] ?? 0;

          final mohalla = (head['mohalla_name'] ??
              head['mohalla'] ??
              hhInfo['mohalla_name'] ??
              hhInfo['mohalla'] ??
              '')
              .toString();

          final tola = (head['mohalla_tola'] ??
              head['tola'] ??
              hhInfo['mohalla_tola'] ??
              hhInfo['tola'] ??
              '')
              .toString();

          final displayId = hhRefKey.length > 11
              ? hhRefKey.substring(hhRefKey.length - 11)
              : hhRefKey;

          final totalMembers = countMembersFromHouseholdInfo(hhInfo);

          final rawWithRef = Map<String, dynamic>.from(hh);
          rawWithRef['household_ref_key'] = hhRefKey;

          return {
            'name': headName,
            'mobile': mobile,
            'hhId': displayId,
            'houseNo': houseNo,
            'mohalla': mohalla,
            'mohallaTola': tola,
            'totalMembers': totalMembers,
            'elderly': 0,
            'pregnantWomen': ancDueCountMap[hhRefKey] ?? 0,
            'eligibleCouples': eligibleCoupleTrackingDueCountMap[hhRefKey] ?? 0,
            'child0to1': 0,
            'child1to2': 0,
            'child2to5': 0,
            'hasChildrenTarget': false,
            'remainingChildren': 0,
            '_raw': rawWithRef,
          };
        }).toList();
      }

      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          if (householdRefKey.isEmpty) return false;

          if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;

          final rawInfo = r['beneficiary_info'];
          Map<String, dynamic> info;
          if (rawInfo is Map) {
            info = Map<String, dynamic>.from(rawInfo);
          } else if (rawInfo is String && rawInfo.isNotEmpty) {
            info = Map<String, dynamic>.from(jsonDecode(rawInfo));
          } else {
            info = {};
          }

          return info['isFamilyHead'] == true ||
              info['isFamilyHead']?.toString().toLowerCase() == 'true';
        } catch (_) {
          return false;
        }
      }).toList();

      List<Map<String, dynamic>> mapped;
      if (familyHeads.isNotEmpty) {
        mapped = familyHeads.map<Map<String, dynamic>>((r) {
          final info = Map<String, dynamic>.from(
            (r['beneficiary_info'] is String
                ? jsonDecode(r['beneficiary_info'])
                : r['beneficiary_info'] ?? {}),
          );

          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final membersForHousehold = rows.where((b) {
            return (b['household_ref_key'] ?? '') == householdRefKey &&
                b['is_deleted'] != 1;
          }).toList();

          int totalExpectedChildren = 0;
          final Set<String> parentNames = <String>{};
          final Set<int> childrenCounts = <int>{};

          for (final b in membersForHousehold) {
            final rawInfo = b['beneficiary_info'];
            Map<String, dynamic> bi;
            if (rawInfo is Map) {
              bi = Map<String, dynamic>.from(rawInfo);
            } else if (rawInfo is String && rawInfo.isNotEmpty) {
              bi = Map<String, dynamic>.from(jsonDecode(rawInfo));
            } else {
              bi = <String, dynamic>{};
            }

            final hasChildrenRaw = bi['hasChildren'] ?? bi['have_children'];
            final hasChildren = hasChildrenRaw == true ||
                hasChildrenRaw?.toString().toLowerCase() == 'yes';
            if (hasChildren) {
              final childrenRaw = bi['children'];
              int tl = 0;
              if (childrenRaw != null) {
                tl = int.tryParse(childrenRaw.toString()) ?? 0;
              } else {
                final tlRaw = bi['totalLive'] ?? bi['totalLiveChildren'];
                if (tlRaw is int) {
                  tl = tlRaw;
                } else {
                  tl = int.tryParse(tlRaw?.toString() ?? '') ?? 0;
                }
              }

              if (tl > 0) {
                childrenCounts.add(tl);
              }

              final pname = (bi['headName'] ??
                  bi['name'] ??
                  bi['memberName'] ??
                  bi['member_name'] ??
                  '')
                  .toString()
                  .trim()
                  .toLowerCase();
              if (pname.isNotEmpty) {
                parentNames.add(pname);
              }
            }
          }

          totalExpectedChildren = childrenCounts.fold(
            0,
                (sum, count) => sum + count,
          );

          int recordedChildren = 0;
          for (final b in membersForHousehold) {
            final rawInfo = b['beneficiary_info'];
            Map<String, dynamic> bi;
            if (rawInfo is Map) {
              bi = Map<String, dynamic>.from(rawInfo);
            } else if (rawInfo is String && rawInfo.isNotEmpty) {
              bi = Map<String, dynamic>.from(jsonDecode(rawInfo));
            } else {
              bi = <String, dynamic>{};
            }

            final fatherName = (bi['fatherName'] ?? bi['father_name'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final motherName = (bi['motherName'] ?? bi['mother_name'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            if (fatherName.isEmpty && motherName.isEmpty) {
              continue;
            }

            final matchesFather =
                fatherName.isNotEmpty && parentNames.contains(fatherName);
            final matchesMother =
                motherName.isNotEmpty && parentNames.contains(motherName);
            if (matchesFather || matchesMother) {
              recordedChildren += 1;
            }
          }

          final remainingChildren = totalExpectedChildren - recordedChildren;
          final hasChildrenTarget = totalExpectedChildren > 0;

          final uniqueKey = (r['unique_key'] ?? '').toString();
          final headId = uniqueKey.length > 11
              ? uniqueKey.substring(uniqueKey.length - 11)
              : uniqueKey;

          return {
            'name':
            (info['headName'] ?? info['memberName'] ?? info['name'] ?? '')
                .toString(),
            'mobile': (info['mobileNo'] ?? '').toString(),
            'hhId': headId,
            'houseNo': info['houseNo'] ?? 0,
            'mohalla': (info['mohalla'] ?? '').toString(),
            'mohallaTola': (info['mohallaTola'] ?? info['tola'] ?? '')
                .toString(),
            'totalMembers': membersForHousehold.length,
            'elderly': elderlyCountMap[householdRefKey] ?? 0,
            'pregnantWomen': ancDueCountMap[householdRefKey] ?? 0,
            'eligibleCouples':
            eligibleCoupleTrackingDueCountMap[householdRefKey] ?? 0,
            'child0to1': child0to1Map[householdRefKey] ?? 0,
            'child1to2': child1to2Map[householdRefKey] ?? 0,
            'child2to5': child2to5Map[householdRefKey] ?? 0,
            'hasChildrenTarget': hasChildrenTarget,
            'remainingChildren': remainingChildren < 0 ? 0 : remainingChildren,
            '_raw': r,
          };
        }).toList();
      } else {
        mapped = mapFromHouseholds();
      }

      /// --------- SORT ----------
      mapped.sort((a, b) {
        final ra = a['_raw'] as Map<String, dynamic>;
        final rb = b['_raw'] as Map<String, dynamic>;

        final ca = DateTime.tryParse(ra['created_date_time']?.toString() ?? '');
        final cb = DateTime.tryParse(rb['created_date_time']?.toString() ?? '');

        if (ca != null && cb != null) return cb.compareTo(ca);
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
      print('Error in _loadData: $e');
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
        screenTitle: l10n!.familyUpdate,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [

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
                      const Icon(Icons.home, color:AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (data['_raw']['household_ref_key']?.toString().length ?? 0) > 11 ? data['_raw']['household_ref_key'].toString().substring(data['_raw']['household_ref_key'].toString().length - 11) : (data['_raw']['household_ref_key']?.toString() ?? ''),
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
                  Row(
                    children: [
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mobileNo} : ",
                          data['mobile']?.toString() ?? 'N/A',
                          isWrappable: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoRow(
                          "${l10n?.mohalla} : ",
                          data['mohalla']?.toString() ?? data['mohallaTola']?.toString() ?? 'N/A',
                          isWrappable: true,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String? title, String value,{bool isWrappable = false}) {
    final t = AppLocalizations.of(context);
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
              value.isEmpty ? t!.na : value,
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
