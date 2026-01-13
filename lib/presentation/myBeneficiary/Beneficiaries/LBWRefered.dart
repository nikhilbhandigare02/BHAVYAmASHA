import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class Lbwrefered extends StatefulWidget {
  const Lbwrefered({super.key});

  @override
  State<Lbwrefered> createState() => _Lbwrefered();
}

class _Lbwrefered extends State<Lbwrefered> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadLbwChildren();
  }

  int? normalizeToGrams(dynamic value) {
    if (value == null) return null;

    final num? v = num.tryParse(value.toString());
    if (v == null || v <= 0) return null;

    // ✅ Convert ONLY newborn-range kg values (≤ 3 kg)
    if (v > 0 && v <= 3) {
      return (v * 1000).round(); // kg → grams
    }

    // ✅ Already grams (typical gram range)
    if (v > 100) {
      return v.round();
    }

    // ❌ Ignore values like 8, 10, etc. (kg for older child)
    return null;
  }

  bool _isBelowOrEqualTwoYears(
      Map<String, dynamic> info, dynamic dobRaw) {
    // Prefer explicit age fields
    final years = int.tryParse(info['years']?.toString() ?? '');
    final months = int.tryParse(info['months']?.toString() ?? '');

    if (years != null) {
      if (years > 2) return false;
      if (years < 2) return true;
      if (months != null && months > 0) return false;
      return true;
    }

    // Fallback to DOB
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        DateTime? dob = DateTime.tryParse(dobRaw.toString());

        if (dob == null) {
          final ts = int.tryParse(dobRaw.toString());
          if (ts != null) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              ts > 1000000000000 ? ts : ts * 1000,
              isUtc: true,
            );
          }
        }

        if (dob != null) {
          final now = DateTime.now();
          final ageInMonths =
              (now.year - dob.year) * 12 + (now.month - dob.month);
          return ageInMonths <= 24;
        }
      } catch (_) {}
    }

    return false;
  }


  Future<void> _loadLbwChildren() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      print('🔍 Loading LBW children (≤ 2 years only)');

      final rows = await db.query(
        'beneficiaries_new',
        where:
        'is_deleted = 0 '
            'AND (is_adult = 0 OR is_adult IS NULL) '
            'AND current_user_key = ? '
            'AND is_death = 0 '
            'AND is_migrated = 0',
        whereArgs: [ashaUniqueKey],
      );

      print('📦 Total child beneficiaries fetched: ${rows.length}');

      final List<Map<String, dynamic>> lbwChildren = [];

      for (final row in rows) {
        try {
          // ---------- Parse beneficiary_info ----------
          final infoStr = row['beneficiary_info']?.toString();
          if (infoStr == null || infoStr.isEmpty) continue;

          final Map<String, dynamic> info =
          jsonDecode(infoStr) as Map<String, dynamic>;

          // 🚫 Skip if child age > 2 years
          final bool isUnderTwo =
          _isBelowOrEqualTwoYears(info, info['dob'] ?? info['dateOfBirth']);
          if (!isUnderTwo) continue;

          final int? weightGm = normalizeToGrams(info['weight']);
          final int? birthWeightGm =
          normalizeToGrams(info['birthWeight']);

          bool isLbw = false;
          if (weightGm != null && weightGm <= 1600) isLbw = true;
          if (birthWeightGm != null && birthWeightGm <= 1600) isLbw = true;

          if (!isLbw) continue;

          // ---------- UI DATA ----------
          final String name =
          (info['name'] ?? info['memberName'] ?? 'Unknown').toString();

          final ageGender = _formatAgeGender(
            info['dob'] ?? info['dateOfBirth'],
            info['gender'],
            info: info,
          );

          dynamic rawWeight;
          bool isBirthWeight = false;

          if (info['weight'] != null &&
              info['weight'].toString().trim().isNotEmpty) {
            rawWeight = info['weight'];
          } else if (info['birthWeight'] != null &&
              info['birthWeight'].toString().trim().isNotEmpty) {
            rawWeight = info['birthWeight'];
            isBirthWeight = true;
          }

          String formatWeight(dynamic value, {bool isBirthWeight = false}) {
            if (value == null) return '--';

            final num? v = num.tryParse(value.toString());
            if (v == null || v <= 0) return '--';

            // Birth weight → always grams
            if (isBirthWeight) {
              return '${v.round()} gms';
            }

            // grams
            if (v > 100) {
              return '${v.round()} g';
            }

            // kg
            return '${v.toString()} kg';
          }

          lbwChildren.add({
            'hhId': row['household_ref_key']?.toString(),
            'beneficiaryKey': row['unique_key']?.toString(),
            'name': name,
            'age_gender': ageGender,
            'weight_display': formatWeight(
              rawWeight,
              isBirthWeight: isBirthWeight,
            ),
            'status': 'LBW',
            '_raw': row,
          });
        } catch (e) {
          print('⚠️ Error processing LBW row: $e');
        }
      }

      print('✅ Final LBW children count (≤2 years): ${lbwChildren.length}');

      setState(() {
        _filtered = lbwChildren;
      });
    } catch (e, st) {
      print('❌ LBW load error: $e');
      print(st);
      setState(() {
        _filtered = [];
      });
    }
  }



  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw, {Map<String, dynamic>? info}) {
    String age = 'Not Available';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');

    // 🔹 Use explicit age fields if available (more reliable than DOB calculation)
    if (info != null) {
      final years = int.tryParse(info['years']?.toString() ?? '');
      final months = int.tryParse(info['months']?.toString() ?? '');
      final days = int.tryParse(info['days']?.toString() ?? '');
      
      if (years != null && years > 0) {
        age = '$years Y';
      } else if (months != null && months > 0) {
        age = '$months M';
      } else if (days != null && days > 0) {
        age = '$days D';
      }
    }

    // 🔹 Fallback to DOB calculation if no explicit age fields
    if (age == 'Not Available' && dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        String dateStr = dobRaw.toString();
        DateTime? dob;

        dob = DateTime.tryParse(dateStr);

        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }

        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          int months = now.month - dob.month;
          int days = now.day - dob.day;

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

          if (years > 0) {
            age = '$years Y';
          } else if (months > 0) {
            age = '$months M';
          } else {
            age = '$days D';
          }
        }
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }

    String displayGender;
    switch (gender) {
      case 'm':
      case 'male':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
        displayGender = 'Female';
        break;
      default:
        displayGender = 'Other';
    }

    return '$age | $displayGender';
  }


  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n!.lbwReferred,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          _filtered.isEmpty
              ? _buildNoRecordCard(context)
              : Expanded(
                  child: ListView.builder(
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
      onTap: () {

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
                        (data['beneficiaryKey']?.toString().length ?? 0) > 11 ? data['beneficiaryKey'].toString().substring(data['beneficiaryKey'].toString().length - 11) : (data['beneficiaryKey'] ?? ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n?.badgeLBW ?? 'LBW',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
      _infoRow(
        '',
        data['age_gender'] ?? '',
        // 🔹 Updated Line: Checks if data exists, then adds label
        trailing: (data['weight_display'] != null && data['weight_display'].toString().isNotEmpty)
            ? '${'Weight'}: ${data['weight_display']}'
            : '',
        isWrappable: true,
      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String? title, String value,{String? trailing, bool isWrappable = false}) {
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
          if (trailing != null && trailing.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              trailing,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoRecordCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n?.noRecordFound ?? 'No Record Found',
                style: TextStyle(
                  fontSize: 17.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
