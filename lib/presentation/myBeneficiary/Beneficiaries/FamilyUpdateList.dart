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
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final pregnantCountMap = <String, int>{};
      final elderlyCountMap = <String, int>{};
      final child0to1Map = <String, int>{};
      final child1to2Map = <String, int>{};
      final child2to5Map = <String, int>{};

      /// Household -> configured head map
      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      /// --------- AGGREGATE COUNTS ----------
      for (final row in rows) {
        try {
          final info = Map<String, dynamic>.from(
            (row['beneficiary_info'] is String
                ? jsonDecode(row['beneficiary_info'])
                : row['beneficiary_info'] ?? {}),
          );

          final householdRefKey = (row['household_ref_key'] ?? '').toString();

          // Pregnant
          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes' ||
                  info['isPregnant'] == true;

          if (isPregnant) {
            pregnantCountMap[householdRefKey] =
                (pregnantCountMap[householdRefKey] ?? 0) + 1;
          }

          final dob = info['dob']?.toString();
          if (dob != null && dob.isNotEmpty) {
            final birthDate = DateTime.tryParse(dob);
            if (birthDate != null) {
              final now = DateTime.now();
              int ageInMonths =
                  (now.year - birthDate.year) * 12 +
                      now.month -
                      birthDate.month;
              if (now.day < birthDate.day) ageInMonths--;

              if (ageInMonths >= 0 && ageInMonths < 12) {
                child0to1Map[householdRefKey] =
                    (child0to1Map[householdRefKey] ?? 0) + 1;
              } else if (ageInMonths >= 12 && ageInMonths < 24) {
                child1to2Map[householdRefKey] =
                    (child1to2Map[householdRefKey] ?? 0) + 1;
              } else if (ageInMonths >= 24 && ageInMonths < 60) {
                child2to5Map[householdRefKey] =
                    (child2to5Map[householdRefKey] ?? 0) + 1;
              } else if (ageInMonths >= 65 * 12) {
                elderlyCountMap[householdRefKey] =
                    (elderlyCountMap[householdRefKey] ?? 0) + 1;
              }
            }
          }
        } catch (_) {}
      }

      /// --------- FAMILY HEAD FILTER ----------
      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          // Exclude migrated & death
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

          final configuredHeadKey = headKeyByHousehold[householdRefKey];

          final bool isConfiguredHead =
              configuredHeadKey != null && configuredHeadKey == uniqueKey;

          final relation = (info['relation_to_head'] ?? info['relation'] ?? '')
              .toString()
              .toLowerCase();

          final bool isHeadByRelation =
              relation == 'head' || relation == 'self';

          // ✅ NEW CONDITION
          final bool isFamilyHead =
              info['isFamilyHead'] == true ||
                  info['isFamilyHead']?.toString().toLowerCase() == 'true';

          return isConfiguredHead || isHeadByRelation || isFamilyHead;
        } catch (_) {
          return false;
        }
      }).toList();

      /// --------- MAP TO UI MODEL ----------
      final mapped = familyHeads.map<Map<String, dynamic>>((r) {
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
            final tlRaw = bi['totalLive'] ?? bi['totalLiveChildren'];
            int tl = 0;
            if (tlRaw is int) {
              tl = tlRaw;
            } else {
              tl = int.tryParse(tlRaw?.toString() ?? '') ?? 0;
            }
            totalExpectedChildren += tl;
            final pname = (bi['headName'] ?? bi['name'] ?? bi['memberName'] ?? bi['member_name'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            if (pname.isNotEmpty) {
              parentNames.add(pname);
            }
          }
        }

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

          final matchesFather = fatherName.isNotEmpty && parentNames.contains(fatherName);
          final matchesMother = motherName.isNotEmpty && parentNames.contains(motherName);
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
          'mohallaTola': (info['mohallaTola'] ?? info['tola'] ?? '').toString(),
          'totalMembers': membersForHousehold.length,
          'elderly': elderlyCountMap[householdRefKey] ?? 0,
          'pregnantWomen': pregnantCountMap[householdRefKey] ?? 0,
          'child0to1': child0to1Map[householdRefKey] ?? 0,
          'child1to2': child1to2Map[householdRefKey] ?? 0,
          'child2to5': child2to5Map[householdRefKey] ?? 0,
          'hasChildrenTarget': hasChildrenTarget,
          'remainingChildren': remainingChildren < 0 ? 0 : remainingChildren,
          '_raw': r,
        };
      }).toList();

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
                      const Icon(Icons.home, color: Colors.black54, size: 18),
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
