import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
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

  // Helper method to extract house number from household_info JSON structure
  String _extractHouseNumberFromHouseholdInfo(Map<String, dynamic> householdInfo) {
    if (householdInfo.isEmpty) return '';
    
    // Try to get from family_head_details first
    final familyHeadDetails = householdInfo['family_head_details'];
    if (familyHeadDetails != null) {
      Map<String, dynamic> headInfo;
      if (familyHeadDetails is Map) {
        headInfo = Map<String, dynamic>.from(familyHeadDetails);
      } else if (familyHeadDetails is String && familyHeadDetails.isNotEmpty) {
        try {
          headInfo = Map<String, dynamic>.from(jsonDecode(familyHeadDetails));
        } catch (_) {
          headInfo = <String, dynamic>{};
        }
      } else {
        headInfo = <String, dynamic>{};
      }
      
      final houseNo = headInfo['house_no']?.toString().trim() ?? 
                     headInfo['houseNo']?.toString().trim() ?? '';
      if (houseNo.isNotEmpty && houseNo != '0') {
        return houseNo;
      }
    }
    
    // If not found in family_head_details, try to extract from all_members
    final allMembersRaw = householdInfo['all_members'];
    if (allMembersRaw != null) {
      List<dynamic> allMembers;
      if (allMembersRaw is List) {
        allMembers = allMembersRaw;
      } else if (allMembersRaw is String && allMembersRaw.isNotEmpty) {
        try {
          final parsed = jsonDecode(allMembersRaw);
          if (parsed is List) {
            allMembers = parsed;
          } else {
            return '';
          }
        } catch (_) {
          return '';
        }
      } else {
        return '';
      }
      
      // Iterate through all members to find house number
      for (final member in allMembers) {
        if (member is Map) {
          final memberData = Map<String, dynamic>.from(member);
          
          // Check in memberDetails
          final memberDetails = memberData['memberDetails'];
          if (memberDetails != null && memberDetails is Map) {
            final houseNo = memberDetails['house_no']?.toString().trim() ?? 
                           memberDetails['houseNo']?.toString().trim() ?? '';
            if (houseNo.isNotEmpty && houseNo != '0') {
              return houseNo;
            }
          }
          
          // Check in spouseDetails
          final spouseDetails = memberData['spouseDetails'];
          if (spouseDetails != null && spouseDetails is Map) {
            final houseNo = spouseDetails['house_no']?.toString().trim() ?? 
                           spouseDetails['houseNo']?.toString().trim() ?? '';
            if (houseNo.isNotEmpty && houseNo != '0') {
              return houseNo;
            }
          }
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
    
    // If not found in beneficiary_new, try households table address column
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
          
          // If not found in address column, check household_info column
          final householdInfoRaw = household['household_info'];
          if (householdInfoRaw != null) {
            Map<String, dynamic> householdInfo;
            if (householdInfoRaw is Map) {
              householdInfo = Map<String, dynamic>.from(householdInfoRaw);
            } else if (householdInfoRaw is String && householdInfoRaw.isNotEmpty) {
              try {
                householdInfo = Map<String, dynamic>.from(jsonDecode(householdInfoRaw));
              } catch (_) {
                householdInfo = <String, dynamic>{};
              }
            } else {
              householdInfo = <String, dynamic>{};
            }
            
            final houseNoFromInfo = _extractHouseNumberFromHouseholdInfo(householdInfo);
            if (houseNoFromInfo.isNotEmpty) {
              return houseNoFromInfo;
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

  Future<bool> _hasSterilizationRecord(
      Database db,
      String beneficiaryKey,
      String ashaUniqueKey,
      ) async {
    final rows = await db.query(
      FollowupFormDataTable.table,
      where: '''
      beneficiary_ref_key = ?
      AND current_user_key = ?
      AND is_deleted = 0
      AND forms_ref_key = ?
    ''',
      whereArgs: [
        beneficiaryKey,
        ashaUniqueKey,
        FollowupFormDataTable
            .formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue],
      ],
    );

    for (final row in rows) {
      try {
        final formJsonStr = row['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;

        final Map<String, dynamic> formJson =
        Map<String, dynamic>.from(jsonDecode(formJsonStr));

        final trackingDue =
        formJson['eligible_couple_tracking_due_from'];

        if (trackingDue is Map<String, dynamic>) {

          final method =
          trackingDue['method_of_contraception']
              ?.toString()
              .toLowerCase();

          if (
          (method == 'female_sterilization' ||
              method == 'male_sterilization' || method == 'male sterilization' || method == 'female sterilization')) {
            return true;
          }
        }
      } catch (_) {
        continue;
      }
    }

    return false;
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

      final elderlyCountMap = <String, int>{};
      final child0to1Map = <String, int>{};
      final child1to2Map = <String, int>{};
      final child2to5Map = <String, int>{};
      final eligibleCoupleCountMap = <String, int>{};

      final ancDueBeneficiaries = <String>{};
      for (final ma in motherCareActivities) {
        final key = (ma['beneficiary_ref_key'] ?? '').toString();
        if (key.isNotEmpty) ancDueBeneficiaries.add(key);
      }

      final beneficiariesByHousehold = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final hhKey = (row['household_ref_key'] ?? '').toString();
        if (hhKey.isNotEmpty) {
          beneficiariesByHousehold.putIfAbsent(hhKey, () => []);
          beneficiariesByHousehold[hhKey]!.add(row);
        }
      }

      for (final hhKey in beneficiariesByHousehold.keys) {
        int male = 0;
        int female = 0;

        for (final b in beneficiariesByHousehold[hhKey]!) {
          if (b['is_deleted'] == 1 ||
              b['is_migrated'] == 1 ||
              b['is_death'] == 1) continue;

          Map<String, dynamic> info;
          try {
            info = b['beneficiary_info'] is String
                ? jsonDecode(b['beneficiary_info'])
                : Map<String, dynamic>.from(b['beneficiary_info'] ?? {});
          } catch (_) {
            continue;
          }

          final marital =
          info['maritalStatus']?.toString().toLowerCase().trim();
          if (marital != 'married') continue;

          // Check for sterilization record
          final beneficiaryKey = b['unique_key']?.toString() ?? '';
          if (beneficiaryKey.isNotEmpty) {
            final hasSterilization = await _hasSterilizationRecord(db, beneficiaryKey, currentUserKey);
            if (hasSterilization) continue;
          }

          final gender = info['gender']?.toString().toLowerCase();
          if (gender == 'male') male++;
          if (gender == 'female') female++;
        }

        eligibleCoupleCountMap[hhKey] = male + female;
      }

      for (final row in rows) {
        if (row['is_deleted'] == 1 ||
            row['is_migrated'] == 1 ||
            row['is_death'] == 1) {
          continue;
        }

        final hhKey = (row['household_ref_key'] ?? '').toString();
        if (hhKey.isEmpty) continue;

        Map<String, dynamic> info;
        try {
          info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'])
              : Map<String, dynamic>.from(row['beneficiary_info'] ?? {});
        } catch (_) {
          continue;
        }

        final memberType = info['memberType']?.toString().toLowerCase() ?? '';
        final relation = info['relation']?.toString().toLowerCase() ?? '';
        final isChild = memberType == 'child' ||
            relation == 'child' ||
            relation == 'son' ||
            relation == 'daughter';

        final dob =
            info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
        if (dob == null || dob.toString().isEmpty) continue;

        DateTime? birthDate = DateTime.tryParse(dob.toString());
        if (birthDate == null) continue;

        final age = _calculateDetailedAge(birthDate);
        final totalMonths = age['totalMonths'] as int;

        if (isChild) {
          if (totalMonths < 12) {
            child0to1Map[hhKey] = (child0to1Map[hhKey] ?? 0) + 1;
          } else if (totalMonths < 24) {
            child1to2Map[hhKey] = (child1to2Map[hhKey] ?? 0) + 1;
          } else if (totalMonths < 60) {
            child2to5Map[hhKey] = (child2to5Map[hhKey] ?? 0) + 1;
          }
        }
        else if (totalMonths >= 65 * 12) {
          elderlyCountMap[hhKey] = (elderlyCountMap[hhKey] ?? 0) + 1;
        }
      }

      final familyHeads = rows.where((r) {
        if (r['is_deleted'] == 1 ||
            r['is_migrated'] == 1 ||
            r['is_death'] == 1) return false;

        Map<String, dynamic> info;
        try {
          info = r['beneficiary_info'] is String
              ? jsonDecode(r['beneficiary_info'])
              : Map<String, dynamic>.from(r['beneficiary_info'] ?? {});
        } catch (_) {
          return false;
        }

        return info['isFamilyhead'] == true;
      }).toList();

      /// ---------------- MAP FINAL DATA ----------------
      final mapped = familyHeads.map<Map<String, dynamic>>((r) {
        final info = r['beneficiary_info'] is String
            ? jsonDecode(r['beneficiary_info'])
            : Map<String, dynamic>.from(r['beneficiary_info'] ?? {});

        final hhKey = (r['household_ref_key'] ?? '').toString();
        final members =
            beneficiariesByHousehold[hhKey]?.where((e) => e['is_deleted'] != 1).toList() ?? [];

        int pregnant = 0;
        for (final m in members) {
          if (ancDueBeneficiaries.contains(m['unique_key'])) {
            pregnant++;
          }
        }

        return {
          'name': info['headName'] ?? info['name'] ?? '',
          'mobile': info['mobileNo'] ?? '',
          'houseNo': _getHouseNumber({'_raw': r}, _households),
          'totalMembers': members.length,
          'elderly': elderlyCountMap[hhKey] ?? 0,
          'pregnantWomen': pregnant,
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
