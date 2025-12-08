import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
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
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final pregnantCountMap = <String, int>{};
      final elderlyCountMap = <String, int>{};
      final child0to1Map = <String, int>{};
      final child1to2Map = <String, int>{};
      final child2to5Map = <String, int>{};

      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      for (final row in rows) {
        try {
          final info = Map<String, dynamic>.from(
            (row['beneficiary_info'] is String
                ? Map<String, dynamic>.from(jsonDecode(row['beneficiary_info']))
                : (row['beneficiary_info'] as Map?) ?? const {}),
          );

          final householdRefKey = (row['household_ref_key'] ?? '').toString();

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes' ||
              info['isPregnant'] == true;
          if (isPregnant) {
            pregnantCountMap[householdRefKey] =
                (pregnantCountMap[householdRefKey] ?? 0) + 1;
          }

          final dob = info['dob']?.toString();
          if (dob != null && dob.isNotEmpty) {
            try {
              final birthDate = DateTime.parse(dob);
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
            } catch (e) {
              print('Error parsing DOB: $dob, error: $e');
            }
          }
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          final configuredHeadKey = headKeyByHousehold[householdRefKey];

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

      final mapped = familyHeads.map<Map<String, dynamic>>((r) {
        final info = r['beneficiary_info'] is String
            ? Map<String, dynamic>.from(jsonDecode(r['beneficiary_info']))
            : Map<String, dynamic>.from(
                (r['beneficiary_info'] as Map?) ?? const {},
              );

        // Get household ref key and id (display)
        final householdRefKey = (r['household_ref_key'] ?? '').toString();
        final hhId = householdRefKey.length > 11
            ? householdRefKey.substring(householdRefKey.length - 11)
            : householdRefKey;

        // Fetch all beneficiaries related to this household_ref_key
        final membersForHousehold = rows.where((b) {
          final ref = (b['household_ref_key'] ?? '').toString();
          final isDeleted = b['is_deleted'] == 1;
          return ref == householdRefKey && !isDeleted;
        }).toList();

        final totalMembers = membersForHousehold.length;

        final name =
            (info['headName'] ?? info['memberName'] ?? info['name'] ?? '')
                .toString();
        final mobile = (info['mobileNo'] ?? '').toString();

        String houseNo = '';
        if (info['houseNo'] != null) {
          houseNo = info['houseNo'].toString();
        } else if (r['beneficiary_info'] is Map &&
            r['beneficiary_info']?['houseNo'] != null) {
          houseNo = r['beneficiary_info']['houseNo'].toString();
        }

        // Get head ID (last 11 digits of unique_key)
        final uniqueKey = (r['unique_key'] ?? '').toString();
        final headId = uniqueKey.length > 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        final maritalStatus = (info['maritalStatus'] ?? '').toString();
        final eligibleCouples = maritalStatus == 'Married' ? 1 : 0;
        final elderly = elderlyCountMap[householdRefKey] ?? 0;

        // Children remaining to be added (mirror RegisterNewHouseHold logic,
        // but using DB members instead of in-memory _members list).
        final child0to1 = child0to1Map[householdRefKey] ?? 0;
        final child1to2 = child1to2Map[householdRefKey] ?? 0;
        final child2to5 = child2to5Map[householdRefKey] ?? 0;

        // How many children the head declared in the registration form.

        int declaredChildren = 0;

        final dynamic childrenField = info['children'];
        if (childrenField is List) {
          declaredChildren = childrenField.length;
        } else if (childrenField is num) {
          declaredChildren = childrenField.toInt();
        } else if (childrenField is String && childrenField.trim().isNotEmpty) {
          declaredChildren = int.tryParse(childrenField.trim()) ?? 0;
        }

        if (declaredChildren == 0) {
          final dynamic totalBornField =
              info['totalBorn'] ?? info['total_children'];
          if (totalBornField is num) {
            declaredChildren = totalBornField.toInt();
          } else if (totalBornField is String &&
              totalBornField.trim().isNotEmpty) {
            declaredChildren = int.tryParse(totalBornField.trim()) ?? 0;
          }
        }
        final int childrenTarget = declaredChildren;

        // Calculate total children from all members (excluding head and spouse)
        int childrenAdded = 0;
        int headChildren = 0;
        int memberChildren = 0;

        for (final member in membersForHousehold) {
          final memberInfo = member['beneficiary_info'] is String
              ? jsonDecode(member['beneficiary_info'])
              : member['beneficiary_info'] ?? {};
          
          final relation = (memberInfo['relation_to_head'] ?? memberInfo['relation'] ?? '').toString().toLowerCase();
          
          // Skip head and spouse for children count
          if (relation == 'self' || relation == 'head' || relation == 'spouse') {
            // Get head's children count
            if (relation == 'self' || relation == 'head') {
              final dynamic childrenField = memberInfo['children'];
              if (childrenField is num) {
                headChildren = childrenField.toInt();
              } else if (childrenField is String && childrenField.trim().isNotEmpty) {
                headChildren = int.tryParse(childrenField.trim()) ?? 0;
              } else if (childrenField is List) {
                headChildren = childrenField.length;
              }
            }
            continue;
          }
          
          // Count this as an added child
          childrenAdded++;
          
          // If this is a member with children, add to memberChildren
          final dynamic memberChildCount = memberInfo['children'];
          if (memberChildCount != null) {
            if (memberChildCount is num) {
              memberChildren += memberChildCount.toInt();
            } else if (memberChildCount is String && memberChildCount.trim().isNotEmpty) {
              memberChildren += int.tryParse(memberChildCount.trim()) ?? 0;
            } else if (memberChildCount is List) {
              memberChildren += memberChildCount.length;
            }
          }
        }

        // Calculate total target children (head's children + member's children)
        final int totalChildrenTarget = headChildren + memberChildren;
        
        // Calculate remaining children to add
        final int remainingChildren = totalChildrenTarget > childrenAdded
            ? (totalChildrenTarget - childrenAdded)
            : 0;

        // Show remaining count if there's a target or if we've added children
        final bool hasChildrenTarget = totalChildrenTarget > 0 || childrenAdded > 0;

        return {
          'name': name,
          'mobile': mobile,
          'hhId': headId,
          'houseNo': houseNo.isNotEmpty ? houseNo : 0,
          'totalMembers': totalMembers,
          'remainingChildren': remainingChildren,
          'eligibleCouples': eligibleCouples,
          'elderly': elderly,
          'pregnantWomen': pregnantCountMap[householdRefKey] ?? 0,
          'child0to1': child0to1,
          'child1to2': child1to2,
          'child2to5': child2to5,
          'hasChildrenTarget': hasChildrenTarget,
          'remainingChildren': remainingChildren > 0 ? remainingChildren : 0,
          '_raw': r,
        };
      }).toList();

      mapped.sort((a, b) {
        final ra = a['_raw'] as Map<String, dynamic>? ?? const {};
        final rb = b['_raw'] as Map<String, dynamic>? ?? const {};

        final createdA = DateTime.tryParse(
          (ra['created_date_time'] ?? '').toString(),
        );
        final createdB = DateTime.tryParse(
          (rb['created_date_time'] ?? '').toString(),
        );

        if (createdA != null && createdB != null) {
          return createdB.compareTo(createdA); // newest first
        }

        final modifiedA = DateTime.tryParse(
          (ra['modified_date_time'] ?? '').toString(),
        );
        final modifiedB = DateTime.tryParse(
          (rb['modified_date_time'] ?? '').toString(),
        );

        if (modifiedA != null && modifiedB != null) {
          return modifiedB.compareTo(modifiedA);
        }

        return 0;
      });

      if (mounted) {
        setState(() {
          _items = mapped;
          _filtered = List<Map<String, dynamic>>.from(_items);
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
                      (data['_raw']['household_ref_key']?.toString().length ?? 0) > 11 ? data['_raw']['household_ref_key'].toString().substring(data['_raw']['household_ref_key'].toString().length - 11) : (data['_raw']['household_ref_key']?.toString() ?? ''),
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp),
                    ),
                  ),
                  Text(
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${data['houseNo'] ?? data['_raw']['beneficiary_info']?['houseNo'] ?? ''}',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp),
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
                          final hhKey = data['_raw']['household_ref_key']?.toString() ?? '';
                          if (hhKey.isEmpty) {
                            return;
                          }

                          final members = await LocalStorageDao.instance.getBeneficiariesByHousehold(hhKey);
                          if (members.isEmpty) {
                            return;
                          }

                          Map<String, dynamic>? headRow;
                          final configuredHeadKey = data['_raw']['unique_key']?.toString();
                          if (configuredHeadKey != null && configuredHeadKey.isNotEmpty) {
                            for (final m in members) {
                              if ((m['unique_key'] ?? '').toString() == configuredHeadKey) {
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
                            info = Map<String, dynamic>.from(jsonDecode(rawInfo) as Map);
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
                          map['head_unique_key'] = headRow['unique_key']?.toString() ?? '';
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
                              } else if (rawSpInfo is String && rawSpInfo.isNotEmpty) {
                                try {
                                  sInfo = Map<String, dynamic>.from(jsonDecode(rawSpInfo) as Map);
                                } catch (_) {
                                  continue;
                                }
                              } else {
                                continue;
                              }

                              final rel = (sInfo['relation_to_head'] ?? sInfo['relation'])
                                  ?.toString()
                                  .toLowerCase();
                              if (rel == 'spouse') {
                                spouseRow = m;
                                break;
                              }
                            }

                            if (spouseRow != null) {
                              final rawSpInfo = spouseRow['beneficiary_info'];
                              Map<String, dynamic> spInfo;
                              if (rawSpInfo is Map<String, dynamic>) {
                                spInfo = rawSpInfo;
                              } else if (rawSpInfo is String && rawSpInfo.isNotEmpty) {
                                spInfo = Map<String, dynamic>.from(jsonDecode(rawSpInfo) as Map);
                              } else {
                                spInfo = <String, dynamic>{};
                              }

                              map['spouse_unique_key'] = spouseRow['unique_key']?.toString() ?? '';
                              if (spouseRow['id'] != null) {
                                map['spouse_id_pk'] = spouseRow['id'].toString();
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
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(0)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child:
                          _rowText(l10n?.thName ?? 'Name', data['name'])),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.mobileLabelSimple ?? 'Mobile no.',
                              data['mobile'])),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.rnhTotalMembers ??
                                  'No. of total members',
                              data['totalMembers'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _rowText(
                              l10n?.eligibleCouples ?? 'Eligible couples',
                              data['eligibleCouples'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.pregnantWomen ?? 'Pregnant women',
                              data['pregnantWomen'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.elderlyAbove65 ?? 'Elderly (>65 Y)',
                              data['elderly'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _rowText(
                              l10n?.children0to1 ?? '0-1 year old children',
                              data['child0to1'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.children1to2 ?? '1-2 year old children',
                              data['child1to2'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.children2to5 ?? '2-5 year old children',
                              data['child2to5'].toString())),
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
                  borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border(
                      top: BorderSide(
                          color: AppColors.outlineVariant, width: 0.5)),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(

                  children: [
                    Text(
                      '${l10n?.memberRemainsToAdd ?? 'Remaining to add'}: ',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp),
                    ),
                    SizedBox(width: 15.w,),
                    Text( '${data['remainingChildren']} '
                        '${data['remainingChildren'] > 1 ? '' : ''}',)
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
