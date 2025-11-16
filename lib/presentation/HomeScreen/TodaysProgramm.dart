import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/Local_Storage/local_storage_dao.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../l10n/app_localizations.dart';
import '../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import '../EligibleCouple/TrackEligibleCouple/TrackEligibleCoupleScreen.dart';
import '../MotherCare/ANCVisit/ANCVisitForm/ANCVisitForm.dart';
import '../MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';

class TodayProgramSection extends StatefulWidget {
  final int? selectedGridIndex;
  final Function(int) onGridTap;
  final Map<String, List<String>> apiData;

  const TodayProgramSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    required this.apiData,
  });

  @override
  State<TodayProgramSection> createState() => _TodayProgramSectionState();
}

class _TodayProgramSectionState extends State<TodayProgramSection> {
  String? _expandedKey;
  List<Map<String, dynamic>> _familySurveyItems = [];
  List<Map<String, dynamic>> _eligibleCoupleItems = [];
  List<Map<String, dynamic>> _ancItems = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGridTap(0);
    });

    _loadFamilySurveyItems();
    _loadEligibleCoupleItems();
    _loadAncItems();
  }

  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }

  Future<void> _launchPhoneDialer(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty || mobile == '-') return;
    final uri = Uri(scheme: 'tel', path: mobile.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isExpanded(String key) {
    return _expandedKey == key;
  }

  Future<void> _loadAncItems() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();

      final List<Map<String, dynamic>> items = [];

      for (final row in rows) {
        try {
          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw as Map);

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final genderRaw = info['gender']?.toString().toLowerCase();
          if (genderRaw != 'f' && genderRaw != 'female') continue;

          final name = (info['memberName'] ?? info['headName'] ?? info['name'])
              ?.toString()
              .trim();
          if (name == null || name.isEmpty) continue;

          String ageText = '-';
          final dobRaw =
              info['dob']?.toString() ?? info['dateOfBirth']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            try {
              String dateStr = dobRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              final birthDate = DateTime.tryParse(dateStr);
              if (birthDate != null) {
                final now = DateTime.now();
                int ageYears = now.year - birthDate.year;
                if (now.month < birthDate.month ||
                    (now.month == birthDate.month &&
                        now.day < birthDate.day)) {
                  ageYears--;
                }
                if (ageYears >= 0) {
                  ageText = '${ageYears}y';
                }
              }
            } catch (_) {}
          }

          if (ageText == '-') {
            final years = info['years']?.toString();
            final approxAge = info['approxAge']?.toString();
            ageText = (years != null && years.isNotEmpty)
                ? '${years}Y'
                : (approxAge != null && approxAge.isNotEmpty)
                    ? '${approxAge}y'
                    : '-';
          }

          final mobile = (info['mobileNo'] ?? info['phone'])?.toString();

          String lastVisitDate = '-';
          DateTime? lastVisitDt;

          String? modifiedRaw = row['modified_date_time']?.toString();
          String? createdRaw = row['created_date_time']?.toString();

          String? pickDateStr(String? raw) {
            if (raw == null || raw.isEmpty) return null;
            String s = raw;
            if (s.contains('T')) {
              s = s.split('T')[0];
            }
            return s;
          }

          String? modifiedStr = pickDateStr(modifiedRaw);
          String? createdStr = pickDateStr(createdRaw);

          if (modifiedStr != null) {
            lastVisitDt = DateTime.tryParse(modifiedStr);
            lastVisitDate = modifiedStr;
          } else if (createdStr != null) {
            lastVisitDt = DateTime.tryParse(createdStr);
            lastVisitDate = createdStr;
          }

          DateTime? lmpDate;
          try {
            final lmpRaw = info['lmp']?.toString();
            if (lmpRaw != null && lmpRaw.isNotEmpty) {
              String dateStr = lmpRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              lmpDate = DateTime.tryParse(dateStr);
            }
          } catch (_) {}

          if (lmpDate == null) {
            lmpDate = lastVisitDt ?? DateTime.now();
          }

          final ancRanges = _calculateAncDateRangesForToday(lmpDate);
          final currentAncLastDueDate = ancRanges['4th_anc_end'];

          String currentAncLastDueDateText = '-';
          if (currentAncLastDueDate != null) {
            currentAncLastDueDateText =
                '${currentAncLastDueDate.year.toString().padLeft(4, '0')}-${currentAncLastDueDate.month.toString().padLeft(2, '0')}-${currentAncLastDueDate.day.toString().padLeft(2, '0')}';
          }

          final householdRefKey = row['household_ref_key']?.toString() ?? '';

          String rawId = row['unique_key']?.toString() ?? '';
          if (rawId.length > 11) {
            rawId = rawId.substring(rawId.length - 11);
          }

          final uniqueKey = row['unique_key']?.toString() ?? '';

          items.add({
            'id': rawId, // trimmed for display
            'household_ref_key': householdRefKey, // full household key
            'hhId': householdRefKey, // explicit for ANCVisitForm
            'unique_key': uniqueKey, // full beneficiary key
            'BeneficiaryID': uniqueKey,
            'name': name,
            'age': ageText,
            'gender': 'Female',
            'last Visit date': lastVisitDate,
            'Current ANC last due date': currentAncLastDueDateText,
            'mobile': mobile ?? '-',
            'badge': 'ANC',
            // Keep raw data for forms that expect it
            'beneficiary_info': jsonEncode(info),
            '_rawRow': row,
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _ancItems = items;
        });
      }
    } catch (_) {}
  }

  Map<String, DateTime> _calculateAncDateRangesForToday(DateTime lmp) {
    final ranges = <String, DateTime>{};

    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = lmp.add(const Duration(days: 12 * 7));

    ranges['2nd_anc_start'] = lmp.add(const Duration(days: 14 * 7));
    ranges['2nd_anc_end'] = lmp.add(const Duration(days: 24 * 7));

    ranges['3rd_anc_start'] = lmp.add(const Duration(days: 26 * 7));
    ranges['3rd_anc_end'] = lmp.add(const Duration(days: 34 * 7));

    ranges['4th_anc_start'] = lmp.add(const Duration(days: 36 * 7));
    ranges['4th_anc_end'] = lmp.add(const Duration(days: 40 * 7));

    ranges['pmsma_start'] = lmp.add(const Duration(days: 40 * 7));
    ranges['pmsma_end'] = lmp.add(const Duration(days: 44 * 7));

    return ranges;
  }

  Future<void> _loadFamilySurveyItems() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      // Build map of household_ref_key -> configured head unique_key (head_id)
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
          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          // Only include household head records similar to AllHouseHold_Screen
          final householdRefKey = (row['household_ref_key'] ?? '').toString();
          final uniqueKey = (row['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;
          final configuredHeadKey = headKeyByHousehold[householdRefKey];
          if (configuredHeadKey == null || configuredHeadKey.isEmpty) continue;
          if (configuredHeadKey != uniqueKey) continue;

          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw as Map);

          final name = (info['headName'] ?? info['memberName'] ?? info['name'])
              ?.toString()
              .trim();
          if (name == null || name.isEmpty) continue;

          final gender = info['gender']?.toString();

          // Prefer calculating age from DOB if available
          String ageText = '-';
          final dobRaw =
              info['dob']?.toString() ?? info['dateOfBirth']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            try {
              String dateStr = dobRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              final birthDate = DateTime.tryParse(dateStr);
              if (birthDate != null) {
                final now = DateTime.now();
                int ageYears = now.year - birthDate.year;
                if (now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day)) {
                  ageYears--;
                }
                if (ageYears >= 0) {
                  ageText = '${ageYears}y';
                }
              }
            } catch (_) {
              // Fallback below if DOB parsing fails
            }
          }

          if (ageText == '-') {
            final years = info['years']?.toString();
            final approxAge = info['approxAge']?.toString();
            ageText = (years != null && years.isNotEmpty)
                ? '${years}Y'
                : (approxAge != null && approxAge.isNotEmpty)
                ? '${approxAge}y'
                : '-';
          }

          final mobile = (info['mobileNo'] ?? info['phone'])?.toString();

          String lastSurveyDate = '-';
          DateTime? lastSurveyDt;

          String? modifiedRaw = row['modified_date_time']?.toString();
          String? createdRaw = row['created_date_time']?.toString();

          String? pickDateStr(String? raw) {
            if (raw == null || raw.isEmpty) return null;
            String s = raw;
            if (s.contains('T')) {
              s = s.split('T')[0];
            }
            return s;
          }

          // Derive lastSurveyDate from modified_date_time if available, otherwise created_date_time
          String? modifiedStr = pickDateStr(modifiedRaw);
          String? createdStr = pickDateStr(createdRaw);

          if (modifiedStr != null) {
            lastSurveyDt = DateTime.tryParse(modifiedStr);
            lastSurveyDate = modifiedStr;
          } else if (createdStr != null) {
            lastSurveyDt = DateTime.tryParse(createdStr);
            lastSurveyDate = createdStr;
          }

          // 6-month filter intentionally disabled as per latest requirement
          // if (lastSurveyDt == null) {
          //   continue;
          // }
          // final now = DateTime.now();
          // final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
          // if (!lastSurveyDt.isBefore(sixMonthsAgo)) {
          //   // last survey is within the last 6 months -> skip
          //   continue;
          // }

          String rawId =
              row['unique_key']?.toString() ??
              row['server_id']?.toString() ??
              '-';
          if (rawId.length > 11) {
            rawId = rawId.substring(rawId.length - 11);
          }

          items.add({
            'id': rawId,
            'household_ref_key': row['household_ref_key']?.toString(),
            'name': name,
            'age': ageText,
            'gender': gender ?? '-',
            'last survey date': lastSurveyDate,
            'Next HBNC due date': '-',
            'mobile': mobile ?? '-',
            'badge': 'Family',
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _familySurveyItems = items;
        });
      }
    } catch (_) {}
  }

  // Helper similar to EligibleCoupleIdentifiedScreen
  Map<String, dynamic> _toStringMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    return {};
  }

  bool _isEligibleFemaleEc(Map<String, dynamic> person) {
    if (person.isEmpty) return false;

    final gender = person['gender']?.toString().toLowerCase();
    final isFemale = gender == 'f' || gender == 'female';
    if (!isFemale) return false;

    final maritalStatus = person['maritalStatus']?.toString().toLowerCase();
    if (maritalStatus != 'married') return false;

    final age = _calculateAgeEc(person['dob']);
    return age >= 15 && age <= 49;
  }

  int _calculateAgeEc(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadEligibleCoupleItems() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final couples = <Map<String, dynamic>>[];

      // Group by household
      final households = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        households.putIfAbsent(hhKey, () => []).add(row);
      }

      for (final household in households.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in household) {
          final info = _toStringMap(member['beneficiary_info']);
          final relation =
              (info['relation_to_head'] as String?)?.toLowerCase() ?? '';

          if (relation == 'self') {
            head = info;
            head['_row'] = Map<String, dynamic>.from(member);
          } else if (relation == 'spouse') {
            spouse = info;
            spouse['_row'] = Map<String, dynamic>.from(member);
          }
        }

        if (head != null && _isEligibleFemaleEc(head)) {
          final formatted = _formatEligibleCoupleForTodayProgram(
            head['_row'] ?? {},
            head,
            spouse ?? {},
            isHead: true,
          );
          if (formatted != null) couples.add(formatted);
        }

        if (spouse != null && _isEligibleFemaleEc(spouse)) {
          final formatted = _formatEligibleCoupleForTodayProgram(
            spouse['_row'] ?? {},
            spouse,
            head ?? {},
            isHead: false,
          );
          if (formatted != null) couples.add(formatted);
        }
      }

      if (mounted) {
        setState(() {
          _eligibleCoupleItems = couples;
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic>? _formatEligibleCoupleForTodayProgram(
    Map<String, dynamic> row,
    Map<String, dynamic> female,
    Map<String, dynamic> headOrSpouse, {
    required bool isHead,
  }) {
    try {
      final uniqueKey = row['unique_key']?.toString() ?? '';
      final householdRefKey = row['household_ref_key']?.toString() ?? '';
      final createdDate = row['created_date_time']?.toString() ?? '';
      final modifiedDate = row['modified_date_time']?.toString() ?? '';

      DateTime? lastDt;
      String? pickDateStr(String raw) {
        if (raw.isEmpty) return null;
        String s = raw;
        if (s.contains('T')) {
          s = s.split('T')[0];
        }
        return s;
      }

      final modStr = pickDateStr(modifiedDate);
      final creStr = pickDateStr(createdDate);
      if (modStr != null) {
        lastDt = DateTime.tryParse(modStr);
      } else if (creStr != null) {
        lastDt = DateTime.tryParse(creStr);
      }

      if (lastDt == null) return null;
      // 30-day filter intentionally disabled as per latest requirement
      // final now = DateTime.now();
      // final diffDays = now.difference(lastDt).inDays;
      // if (diffDays < 30) {
      //   // Updated less than 1 month ago -> skip
      //   return null;
      // }

      final name =
          female['memberName']?.toString() ??
          female['headName']?.toString() ??
          '';

      final genderRaw = female['gender']?.toString().toLowerCase();
      final genderDisplay = genderRaw == 'f'
          ? 'Female'
          : genderRaw == 'm'
          ? 'Male'
          : 'Female';

      final ageYears = _calculateAgeEc(female['dob']);
      final ageText = ageYears > 0 ? '${ageYears}y' : '-';
      final mobile = female['mobileNo']?.toString() ?? '';

      final lastVisitDate =
          '${lastDt.year.toString().padLeft(4, '0')}-${lastDt.month.toString().padLeft(2, '0')}-${lastDt.day.toString().padLeft(2, '0')}';

      String rawId = uniqueKey;
      if (rawId.length > 11) {
        rawId = rawId.substring(rawId.length - 11);
      }

      return {
        'id': rawId, // trimmed for display
        'beneficiaryId': uniqueKey, // full beneficiary ID for tracking
        'household_ref_key': householdRefKey,
        'name': name,
        'age': ageText,
        'gender': genderDisplay,
        'last Visit date': lastVisitDate,
        'mobile': mobile.isNotEmpty ? mobile : '-',
        'badge': 'EligibleCouple',
      };
    } catch (_) {
      return null;
    }
  }

  List<Widget> _getAncListItems() {
    final List<Map<String, dynamic>> ancItems = _ancItems;

    return ancItems.map((item) => _routineCard(item)).toList();
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    final badge = item['badge']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        final confirmed = await showConfirmationDialog(
          context: context,
          message: 'Move forward?',
          yesText: 'Yes',
          noText: 'No',
        );

        if (confirmed != true) {
          return;
        }

        if (badge == 'Family') {
          final hhKey = item['household_ref_key']?.toString() ?? '';
          if (hhKey.isEmpty) return;

          Map<String, String> initial = {};
          try {
            // Load household to find configured head_id
            final households = await LocalStorageDao.instance.getAllHouseholds();
            String? headId;
            for (final hh in households) {
              final key = (hh['unique_key'] ?? '').toString();
              if (key == hhKey) {
                headId = (hh['head_id'] ?? '').toString();
                break;
              }
            }

            // Load all beneficiaries for this household
            final members = await LocalStorageDao.instance.getBeneficiariesByHousehold(hhKey);

            Map<String, dynamic>? headRow;
            if (headId != null && headId.isNotEmpty) {
              for (final m in members) {
                if ((m['unique_key'] ?? '').toString() == headId) {
                  headRow = m;
                  break;
                }
              }
            }

            headRow ??= members.isNotEmpty ? members.first : null;

            if (headRow != null) {
              final rawInfo = headRow['beneficiary_info'];
              Map<String, dynamic> info;
              if (rawInfo is Map<String, dynamic>) {
                info = rawInfo;
              } else if (rawInfo is String && rawInfo.isNotEmpty) {
                info = jsonDecode(rawInfo) as Map<String, dynamic>;
              } else {
                info = <String, dynamic>{};
              }

              // Convert all primitive fields to String for AddNewFamilyHeadScreen.initial
              final map = <String, String>{};
              info.forEach((key, value) {
                if (value != null) {
                  map[key] = value.toString();
                }
              });

              // Try to attach spouse info (separate beneficiary where spouse_key == head unique_key)
              try {
                Map<String, dynamic>? spouseRow;
                final headUnique = (headRow['unique_key'] ?? '').toString();
                for (final m in members) {
                  if ((m['spouse_key'] ?? '').toString() == headUnique) {
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
                    spInfo = jsonDecode(rawSpInfo) as Map<String, dynamic>;
                  } else {
                    spInfo = <String, dynamic>{};
                  }

                  spInfo.forEach((key, value) {
                    if (value != null) {
                      map['sp_$key'] = value.toString();
                    }
                  });
                }
              } catch (_) {}

              // Ensure some core fields are present/fallbacks from card item
              map['headName'] ??= item['name']?.toString() ?? '';
              map['mobileNo'] ??= item['mobile']?.toString() ?? '';
              initial = map;
            }
          } catch (_) {
            // If anything fails, fall back to minimal initial data
            initial = {
              'headName': item['name']?.toString() ?? '',
              'mobileNo': item['mobile']?.toString() ?? '',
            };
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewFamilyHeadScreen(
                isEdit: true,
                initial: initial,
              ),
            ),
          );
        } else if (badge == 'EligibleCouple') {
          final beneficiaryId = item['beneficiaryId']?.toString() ?? '';
          if (beneficiaryId.isEmpty) return;

          Navigator.push(
            context,
            TrackEligibleCoupleScreen.route(
              beneficiaryId: beneficiaryId,
            ),
          );
        } else if (badge == 'ANC') {
          // Navigate to ANC Visit Form with full beneficiary data
          final hhId = item['hhId']?.toString() ??
              item['household_ref_key']?.toString() ?? '';
          final beneficiaryId = item['BeneficiaryID']?.toString() ??
              item['unique_key']?.toString() ?? '';
          if (hhId.isEmpty || beneficiaryId.isEmpty) return;

          final formData = Map<String, dynamic>.from(item);
          formData['hhId'] = hhId;
          formData['BeneficiaryID'] = beneficiaryId;
          formData['unique_key'] = item['unique_key']?.toString() ?? beneficiaryId;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Ancvisitform(beneficiaryData: formData),
            ),
          );
        } else if (badge == 'HBNC') {
          // Navigate to HBNC Visit Form; pass the item as beneficiaryData
          final beneficiaryData = Map<String, dynamic>.from(item);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HbncVisitScreen(
                beneficiaryData: beneficiaryData,
              ),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.home, color: primary, size: 15.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (item['household_ref_key']?.toString().isNotEmpty ?? false)
                          ? _last11(item['household_ref_key']?.toString())
                          : _last11(item['id']?.toString()),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  if (badge != 'Family')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F7E9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF0E7C3A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? '-',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item['age'] ?? '-'} | ${item['gender'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (badge == 'ANC') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current ANC last due date: ${item['Current ANC last due date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'Family') ...[
                          Text(
                            'Last survey date: ${item['last survey date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'EligibleCouple') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'HBNC') ...[
                          Text(
                            'Last HBNC due date: ${item['last HBNC due date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'RI') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          'Mobile: ${item['mobile'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _launchPhoneDialer(item['mobile']?.toString()),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.phone, color: primary, size: 24),
                        ),
                      ),
                      if (badge != 'Family') ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              badge == 'ANC'
                                  ? 'assets/images/pregnant-woman.png'
                                  : badge == 'EligibleCouple'
                                  ? 'assets/images/couple.png'
                                  : badge == 'HBNC'
                                  ? 'assets/images/pnc-mother.png'
                                  : 'assets/images/capsule2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate total count for To Do Visits card across all expansion tiles
    final familyCount = _familySurveyItems.length;
    final eligibleCoupleCount = _eligibleCoupleItems.length;
    final ancCount = _ancItems.length;
    final hbncCount = widget.apiData[l10n.listHBNC]?.length ?? 0;
    final riCount = widget.apiData[l10n.listRoutineImmunization]?.length ?? 0;
    final totalToDoCount =
        familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid Boxes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(0),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 0
                        ? AppColors.primary
                        : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/schedule.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                "$totalToDoCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 0
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.toDoVisits,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              color: widget.selectedGridIndex == 0
                                  ? AppColors.onPrimary
                                  : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Grid Box 2
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(1),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 1
                        ? AppColors.primary
                        : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/comment.png',
                                    width: 6.w,
                                    height: 6.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              Text(
                                "0",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 1
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.completedVisits,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              color: widget.selectedGridIndex == 1
                                  ? AppColors.onPrimary
                                  : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ExpansionTile list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              // Control ExpansionTile animation speed globally
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Column(
              children: [
                for (var entry in widget.apiData.entries) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: ExpansionTile(
                      key: ValueKey('${entry.key}_$_expandedKey'),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedKey = expanded ? entry.key : null;
                        });
                      },
                      initiallyExpanded: _expandedKey == entry.key,
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: _expandedKey == entry.key
                              ? Colors.blueAccent
                              : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key == l10n.listFamilySurvey
                                ? "${_familySurveyItems.length}"
                                : entry.key == l10n.listEligibleCoupleDue
                                    ? "${_eligibleCoupleItems.length}"
                                    : entry.key == l10n.listANC
                                        ? "${_ancItems.length}"
                                        : "${entry.value.length}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _expandedKey == entry.key ? 0.5 : 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.keyboard_arrow_down_outlined,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      children: entry.key == l10n.listANC
                          ? (_ancItems.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('No data found'),
                                    ),
                                  ),
                                ]
                              : _getAncListItems())
                          : entry.key == l10n.listFamilySurvey
                          ? (_familySurveyItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('No data found'),
                                      ),
                                    ),
                                  ]
                                : _familySurveyItems
                                      .map((item) => _routineCard(item))
                                      .toList())
                          : entry.key == l10n.listEligibleCoupleDue
                          ? (_eligibleCoupleItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('No data found'),
                                      ),
                                    ),
                                  ]
                                : _eligibleCoupleItems
                                      .map((item) => _routineCard(item))
                                      .toList())
                          : entry.key == l10n.listHBNC
                          ? entry.value
                                .map(
                                  (name) => _routineCard({
                                    'id': '-',
                                    'name': name,
                                    'age': '-',
                                    'gender': '-',
                                    'last HBNC due date': '-',
                                    'mobile': '-',
                                    'badge': 'HBNC',
                                  }),
                                )
                                .toList()
                          : entry.key == l10n.listRoutineImmunization
                          ? entry.value
                                .map(
                                  (name) => _routineCard({
                                    'id': '-',
                                    'name': name,
                                    'age': '-',
                                    'gender': '-',
                                    'last Visit date': '-',
                                    'mobile': '-',
                                    'badge': 'Child Tracking',
                                  }),
                                )
                                .toList()
                          : entry.value
                                .map((item) => ListTile(title: Text(item)))
                                .toList(),
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 1, height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
