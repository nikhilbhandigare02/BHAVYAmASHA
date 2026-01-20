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
  List<Map<String, dynamic>> _households = []; // Store households data for fallback

  // Helper method to extract house number from household address
  String _extractHouseNumberFromAddress(Map<String, dynamic> addressData) {
    if (addressData.isEmpty) return '';
    
    // Try common house number fields in address data
    final houseNoFields = [
      'houseNo',
      'house_no',
      'houseNumber',
      'house_number',
      'houseno',
      'building_no',
      'buildingNumber',
      'building_no',
      'address_line1',
      'addressLine1',
    ];
    
    for (final field in houseNoFields) {
      final value = addressData[field]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    // If no specific field found, try to extract from full address
    final fullAddress = addressData['full_address']?.toString() ?? 
                       addressData['address']?.toString() ?? 
                       addressData['complete_address']?.toString() ?? '';
    
    if (fullAddress.isNotEmpty) {
      // Try to extract house number from the beginning of address
      final lines = fullAddress.split(',');
      for (final line in lines) {
        final trimmed = line.trim();
        // Look for patterns like "House No: 123", "H.No. 123", "123", etc.
        if (RegExp(r'^\d+').hasMatch(trimmed) || 
            RegExp(r'(?i)house\s*(no|number)?\s*[:\-]?\s*\d+').hasMatch(trimmed) ||
            RegExp(r'(?i)h\.?\.?\s*no\.?\s*[:\-]?\s*\d+').hasMatch(trimmed)) {
          return trimmed;
        }
      }
    }
    
    return '';
  }

  // Helper method to get house number with fallback logic
  String _getHouseNumber(Map<String, dynamic> data, List<Map<String, dynamic>> households) {
    // First try to get from beneficiary_new table
    final beneficiaryHouseNo = data['houseNo']?.toString() ?? 
                              data['_raw']['beneficiary_info']?['houseNo']?.toString() ?? '';
    
    if (beneficiaryHouseNo.isNotEmpty && beneficiaryHouseNo != '0') {
      return beneficiaryHouseNo;
    }
    
    // If not found in beneficiary_new, try households table
    final householdRefKey = data['_raw']['household_ref_key']?.toString() ?? '';
    if (householdRefKey.isNotEmpty) {
      for (final household in households) {
        if (household['unique_key']?.toString() == householdRefKey) {
          final addressData = household['address'] as Map<String, dynamic>?;
          if (addressData != null) {
            final houseNoFromAddress = _extractHouseNumberFromAddress(addressData);
            if (houseNoFromAddress.isNotEmpty) {
              return houseNoFromAddress;
            }
          }
        }
      }
    }
    
    return '';
  }

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

  DateTime _resolveSortDate(Map<String, dynamic> raw) {
    dynamic value = raw['modified_date_time'];

    if (value == null || value.toString().isEmpty) {
      value = raw['created_date_time'];
    }

    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final str = value.toString();

    // ISO 8601: 2026-01-08T13:38:14.074Z
    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed.toUtc();

    // Timestamp (seconds or milliseconds)
    final ts = int.tryParse(str);
    if (ts != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        ts > 1000000000000 ? ts : ts * 1000,
        isUtc: true,
      );
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Helper function to calculate detailed age and categorize children
  Map<String, dynamic> _calculateDetailedAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
      final lastMonthYear = now.month - 1 < 1 ? now.year - 1 : now.year;
      final daysInLastMonth = DateTime(lastMonthYear, lastMonth + 1, 0).day;
      days += daysInLastMonth;
      months--;
    }

    if (months < 0) {
      months += 12;
      years--;
    }

    // Convert to total months for categorization
    int totalMonths = years * 12 + months;
    
    // Calculate total days for more precise age tracking
    int totalDays = now.difference(birthDate).inDays;

    String ageCategory = '';
    if (totalMonths >= 0 && totalMonths < 12) {
      ageCategory = '0-1 years';
    } else if (totalMonths >= 12 && totalMonths < 24) {
      ageCategory = '1-2 years';
    } else if (totalMonths >= 24 && totalMonths < 60) {
      ageCategory = '2-5 years';
    } else if (totalMonths >= 65 * 12) {
      ageCategory = '65+ years';
    } else {
      ageCategory = 'Other';
    }

    return {
      'years': years,
      'months': months,
      'days': days,
      'totalMonths': totalMonths,
      'totalDays': totalDays,
      'ageCategory': ageCategory,
      'ageText': '${years}y ${months}m ${days}d',
    };
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

      // Get households data with proper JSON parsing using LocalStorageDao
      _households = await LocalStorageDao.instance.getAllHouseholds();

      final households = await db.query(
        'households',
        where: 'is_deleted = 0 AND current_user_key = ?',
        whereArgs: [currentUserKey],
        orderBy: 'created_date_time DESC',
      );

      final motherCareActivities = await db.rawQuery(
        '''
        SELECT mca.* FROM mother_care_activities mca
        INNER JOIN beneficiaries_new bn ON mca.beneficiary_ref_key = bn.unique_key
        WHERE mca.current_user_key = ? 
        AND mca.mother_care_state = 'anc_due'
        AND mca.is_deleted = 0
        AND bn.is_deleted = 0
        ORDER BY mca.created_date_time ASC
      ''',
        [currentUserKey],
      );

      final ancDueCountMap = <String, int>{};
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


      final eligibleCoupleCountMap = <String, int>{};

      final beneficiariesByHousehold = <String, List<Map<String, dynamic>>>{};

// Group beneficiaries by household
      for (final row in rows) {
        final householdRefKey = (row['household_ref_key'] ?? '').toString();
        if (householdRefKey.isNotEmpty) {
          beneficiariesByHousehold.putIfAbsent(householdRefKey, () => []);
          beneficiariesByHousehold[householdRefKey]!.add(row);
        }
      }

// Calculate eligible couples per household
      for (final householdRefKey in beneficiariesByHousehold.keys) {
        final householdBeneficiaries =
        beneficiariesByHousehold[householdRefKey]!;

        int marriedMaleCount = 0;
        int marriedFemaleCount = 0;

        debugPrint(
            'AllHouseHold: Calculating eligible couples for household: $householdRefKey');

        for (final beneficiary in householdBeneficiaries) {
          try {
            // Skip deleted / migrated / death
            if (beneficiary['is_deleted'] == 1 ||
                beneficiary['is_migrated'] == 1 ||
                beneficiary['is_death'] == 1) {
              continue;
            }

            // Parse beneficiary_info safely
            final rawInfo = beneficiary['beneficiary_info'];
            Map<String, dynamic> info;

            if (rawInfo is Map) {
              info = Map<String, dynamic>.from(rawInfo);
            } else if (rawInfo is String && rawInfo.isNotEmpty) {
              info = Map<String, dynamic>.from(jsonDecode(rawInfo));
            } else {
              continue;
            }

            // ✅ STRICT MARITAL STATUS CHECK
            final maritalStatus = info['maritalStatus']
                ?.toString()
                .trim()
                .toLowerCase();

            if (maritalStatus != 'married') {
              // ❌ skip single / widowed / divorced / separated / null
              continue;
            }

            // Gender check
            final gender =
                info['gender']?.toString().trim().toLowerCase() ?? '';

            if (gender == 'male') {
              marriedMaleCount++;
            } else if (gender == 'female') {
              marriedFemaleCount++;
            }
          } catch (e) {
            continue;
          }
        }

        // ✅ Eligible individuals count (as per your existing logic)
        final eligibleIndividuals =
            marriedMaleCount + marriedFemaleCount;

        eligibleCoupleCountMap[householdRefKey] = eligibleIndividuals;

        debugPrint(
            'AllHouseHold: Household $householdRefKey → Married males: $marriedMaleCount, Married females: $marriedFemaleCount, Eligible individuals: $eligibleIndividuals');
      }


      final ancDueBeneficiaries = <String>{}; // Set of beneficiary_ref_keys with ANC due

      for (final ma in motherCareActivities) {
        try {
          final beneficiaryKey = (ma['beneficiary_ref_key'] ?? '').toString();
          if (beneficiaryKey.isEmpty) continue;

          ancDueBeneficiaries.add(beneficiaryKey);
          debugPrint('AllHouseHold: ANC due - Beneficiary: $beneficiaryKey');
        } catch (_) {}
      }

      debugPrint('AllHouseHold: Found ${ancDueBeneficiaries.length} beneficiaries with ANC due');

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
          final isChild =
              memberType == 'child' ||
              relation == 'child' ||
              memberType == 'Child' ||
              relation == 'daughter';

          final dob =
              info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
          if (dob != null && dob.toString().isNotEmpty) {
            DateTime? birthDate;

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
              // Use the helper function to calculate detailed age
              final ageDetails = _calculateDetailedAge(birthDate);
              final totalMonths = ageDetails['totalMonths'] as int;

              final name = (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString();
              debugPrint('AllHouseHold: Age calculation for $name:');
              debugPrint('  - DOB: $birthDate');
              debugPrint('  - Age: ${ageDetails['ageText']} (${ageDetails['totalDays']} days)');
              debugPrint('  - Category: ${ageDetails['ageCategory']}');
              debugPrint('  - Is child: $isChild');

              if (isChild) {
                if (totalMonths >= 0 && totalMonths < 12) {
                  child0to1Map[householdRefKey] =
                      (child0to1Map[householdRefKey] ?? 0) + 1;
                  debugPrint('  - Added to 0-1 years category');
                } else if (totalMonths >= 12 && totalMonths < 24) {
                  // 1 year to less than 2 years
                  child1to2Map[householdRefKey] =
                      (child1to2Map[householdRefKey] ?? 0) + 1;
                  debugPrint('  - Added to 1-2 years category');
                } else if (totalMonths >= 24 && totalMonths < 60) {
                  // 2 years to less than 5 years
                  child2to5Map[householdRefKey] =
                      (child2to5Map[householdRefKey] ?? 0) + 1;
                  debugPrint('  - Added to 2-5 years category');
                }
              }

              if (totalMonths >= 65 * 12) {
                elderlyCountMap[householdRefKey] =
                    (elderlyCountMap[householdRefKey] ?? 0) + 1;
                debugPrint('  - Added to elderly (65+) category');
              }
            }
          }
        } catch (_) {}
      }

      // Debug summary for age categorization
      debugPrint('AllHouseHold: Age categorization summary:');
      for (final householdRefKey in beneficiariesByHousehold.keys) {
        final child0to1 = child0to1Map[householdRefKey] ?? 0;
        final child1to2 = child1to2Map[householdRefKey] ?? 0;
        final child2to5 = child2to5Map[householdRefKey] ?? 0;
        final elderly = elderlyCountMap[householdRefKey] ?? 0;

        if (child0to1 > 0 || child1to2 > 0 || child2to5 > 0 || elderly > 0) {
          debugPrint('  Household $householdRefKey: 0-1y: $child0to1, 1-2y: $child1to2, 2-5y: $child2to5, 65+: $elderly');
        }
      }

      /// --------- FAMILY HEAD FILTER ----------
      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;

          Map<String, dynamic> info;
          try {
            final rawInfo = r['beneficiary_info'];
            if (rawInfo is String && rawInfo.isNotEmpty) {
              info = jsonDecode(rawInfo) as Map<String, dynamic>;
            } else if (rawInfo is Map) {
              info = Map<String, dynamic>.from(rawInfo);
            } else {
              info = <String, dynamic>{};
            }
          } catch (e) {
            print('⚠️ Error parsing beneficiary info: $e');
            info = <String, dynamic>{};
          }

          final isFamilyhead = info['isFamilyhead'];
          if (isFamilyhead) return true;



          // Check if household head_id matches beneficiary unique_key
         /* for (final household in households) {
            final headId = (household['head_id'] ?? '').toString();
           // if (headId == uniqueKey) {
              return true;
         //   }
          }*/
          return false;
        } catch (_) {
          return false;
        }
      }).toList();

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
        final Set<int> childrenCounts =
            <int>{};

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
          final hasChildren =
              hasChildrenRaw == true ||
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

            final pname =
                (bi['headName'] ??
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

        // Sum unique children counts (avoiding duplicates from head/spouse)
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
          //  continue;
          }

          final matchesFather =
              fatherName.isNotEmpty && parentNames.contains(fatherName);
          final matchesMother =
              motherName.isNotEmpty && parentNames.contains(motherName);
          if (matchesFather || matchesMother) {
            recordedChildren++;
          }
        }

        final remainingChildren = recordedChildren;
        final hasChildrenTarget = totalExpectedChildren > 0;

        final uniqueKey = (r['unique_key'] ?? '').toString();
        final headId = uniqueKey.length > 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        final householdRefKeyFromRaw = (r['household_ref_key'] ?? '').toString();

        int pregnantWomenCount = 0;
        for (final member in membersForHousehold) {
          final memberUniqueKey = (member['unique_key'] ?? '').toString();
          if (ancDueBeneficiaries.contains(memberUniqueKey)) {
            pregnantWomenCount++;
          }
        }

        debugPrint('AllHouseHold: Mapping for household $householdRefKeyFromRaw - Pregnant women: $pregnantWomenCount');

        // Create a temporary data map to use with the helper method
        final tempData = {
          'houseNo': info['houseNo'] ?? 0,
          '_raw': r,
        };
        
        final houseNumber = _getHouseNumber(tempData, _households);

        return {
          'name': (info['headName'] ?? info['memberName'] ?? info['name'] ?? '')
              .toString(),
          'mobile': (info['mobileNo'] ?? '').toString(),
          'hhId': headId,
          'houseNo': houseNumber.isNotEmpty ? houseNumber : 0,
          'totalMembers': membersForHousehold.length,
          'elderly': elderlyCountMap[householdRefKeyFromRaw] ?? 0,
          'pregnantWomen': pregnantWomenCount,
          'eligibleCouples':
              eligibleCoupleCountMap[householdRefKeyFromRaw] ?? 0,
          'child0to1': child0to1Map[householdRefKeyFromRaw] ?? 0,
          'child1to2': child1to2Map[householdRefKeyFromRaw] ?? 0,
          'child2to5': child2to5Map[householdRefKeyFromRaw] ?? 0,
          'hasChildrenTarget': hasChildrenTarget,
          'remainingChildren': remainingChildren,
          '_raw': r,
        };
      }).toList();

      final Set<String> hhWithBeneficiaries = rows
          .map((e) => (e['household_ref_key'] ?? '').toString())
          .where((k) => k.isNotEmpty)
          .toSet();

      final List<Map<String, dynamic>> fallbackMapped = [];
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        if (hhRefKey.isEmpty) continue;
        if (hhWithBeneficiaries.contains(hhRefKey)) continue;

        Map<String, dynamic> hhInfo;
        final rawHhInfo = hh['household_info'];
        if (rawHhInfo is Map) {
          hhInfo = Map<String, dynamic>.from(rawHhInfo);
        } else if (rawHhInfo is String && rawHhInfo.isNotEmpty) {
          try {
            hhInfo = Map<String, dynamic>.from(jsonDecode(rawHhInfo));
          } catch (_) {
            hhInfo = <String, dynamic>{};
          }
        } else {
          hhInfo = <String, dynamic>{};
        }

        final headInfoRaw = hhInfo['family_head_details'];
        Map<String, dynamic> headInfo = {};
        if (headInfoRaw is Map) {
          headInfo = Map<String, dynamic>.from(headInfoRaw);
        } else if (headInfoRaw is String && headInfoRaw.isNotEmpty) {
          try {
            headInfo = Map<String, dynamic>.from(jsonDecode(headInfoRaw));
          } catch (_) {}
        }

        final isHeadA =
            headInfo['isFamilyHead'] == true ||
            (headInfo['isFamilyHead']?.toString().toLowerCase() == 'true');
        final isHeadB =
            headInfo['isFamilyhead'] == true ||
            (headInfo['isFamilyhead']?.toString().toLowerCase() == 'true');
        final isHead = isHeadA || isHeadB;
       // if (!isHead) continue;

        String name =
            (headInfo['name_of_family_head'] ??
                    headInfo['headName'] ??
                    headInfo['memberName'] ??
                    headInfo['name'] ??
                    '')
                .toString();
        String mobile =
            (headInfo['mobile_no_of_family_head'] ?? headInfo['mobileNo'] ?? '')
                .toString();
        
        // Use the helper method to get house number with fallback logic
        String houseNo = (headInfo['house_no'] ?? headInfo['houseNo'] ?? '').toString();
        if (houseNo.isEmpty) {
          // Try to get from household address using the helper method
          final householdData = _households.where((h) => h['unique_key']?.toString() == hhRefKey).firstOrNull;
          if (householdData != null) {
            final addressData = householdData['address'] as Map<String, dynamic>?;
            if (addressData != null) {
              houseNo = _extractHouseNumberFromAddress(addressData);
            }
          }
        }

        int totalMembers = 1;
        final allMembersRaw = hhInfo['all_members'];
        if (allMembersRaw is List) {
          totalMembers = allMembersRaw.length;
        } else if (allMembersRaw is String && allMembersRaw.isNotEmpty) {
          try {
            final parsed = jsonDecode(allMembersRaw);
            if (parsed is List) {
              totalMembers = parsed.length;
            }
          } catch (_) {}
        }

        final headId = hhRefKey.length > 11
            ? hhRefKey.substring(hhRefKey.length - 11)
            : hhRefKey;

        fallbackMapped.add({
          'name': name,
          'mobile': mobile,
          'hhId': headId,
          'houseNo': houseNo,
          'totalMembers': totalMembers,
          'elderly': 0,
          'pregnantWomen': 0,
          'eligibleCouples': 0,
          'child0to1': 0,
          'child1to2': 0,
          'child2to5': 0,
          'hasChildrenTarget': false,
          'remainingChildren': 0,
          '_raw': {
            'household_ref_key': hhRefKey,
            'created_date_time': hh['created_date_time']?.toString(),
            'unique_key': hh['head_id']?.toString(),
          },
        });
      }

      final List<Map<String, dynamic>> combined = [
        ...mapped,
        ...fallbackMapped,
      ];


      combined.sort((a, b) {
        final ra = a['_raw'] as Map<String, dynamic>;
        final rb = b['_raw'] as Map<String, dynamic>;

        final int idA = int.tryParse(ra['id']?.toString() ?? '') ?? 0;
        final int idB = int.tryParse(rb['id']?.toString() ?? '') ?? 0;

        return idB.compareTo(idA);
      });



      if (mounted) {
        setState(() {
          _items = combined;
          _filtered = List<Map<String, dynamic>>.from(combined);
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
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${_getHouseNumber(data, _households)}',
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
                          (() {
                            final count = data['pregnantWomen'].toString();
                            debugPrint('AllHouseHold: UI displaying pregnant women count: $count for household ${data['_raw']['household_ref_key']}');
                            return count;
                          })(),
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
