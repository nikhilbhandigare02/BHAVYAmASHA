import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/Database/tables/beneficiaries_table.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class Pregnancyoutcome extends StatefulWidget {
  const Pregnancyoutcome({super.key});

  @override
  State<Pregnancyoutcome> createState() => _PregnancyoutcomeState();
}

class _PregnancyoutcomeState extends State<Pregnancyoutcome> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _allData = [];

  @override
  void initState() {
    super.initState();
    _loadPregnancyCases();

  }



  Future<void> _loadPregnancyCases() async {
    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        setState(() {
          _allData = [];
          _filtered = [];
          _isLoading = false;
        });
        return;
      }

      const ancRefKey = 'bt7gs9rl1a5d26mz';

      final results = await db.rawQuery(
        '''
WITH LatestMCA AS (
  SELECT
    mca.*,
    ROW_NUMBER() OVER (
      PARTITION BY mca.beneficiary_ref_key
      ORDER BY mca.created_date_time DESC, mca.id DESC
    ) AS rn
  FROM mother_care_activities mca
  WHERE mca.is_deleted = 0
    AND mca.current_user_key = ?
),
DeliveryOutcomeOnly AS (
  SELECT *
  FROM LatestMCA
  WHERE rn = 1
    AND mother_care_state = 'delivery_outcome'
),
LatestANC AS (
  SELECT
    f.beneficiary_ref_key,
    f.form_json,
    ROW_NUMBER() OVER (
      PARTITION BY f.beneficiary_ref_key
      ORDER BY f.created_date_time DESC, f.id DESC
    ) AS rn
  FROM ${FollowupFormDataTable.table} f
  WHERE f.forms_ref_key = ?
    AND f.is_deleted = 0
    AND f.current_user_key = ?
)
SELECT
  d.beneficiary_ref_key,
  d.household_ref_key,
  d.created_date_time,
  d.id AS form_id,
  COALESCE(a.form_json, '{}') AS form_json
FROM DeliveryOutcomeOnly d
LEFT JOIN LatestANC a
  ON a.beneficiary_ref_key = d.beneficiary_ref_key
 AND a.rn = 1
ORDER BY d.created_date_time DESC
'''
      , [ashaUniqueKey, ancRefKey, ashaUniqueKey],
      );

      if (results.isEmpty) {
        setState(() {
          _allData = [];
          _filtered = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> processedData = [];

      for (final row in results) {
        try {
          final beneficiaryRefKey = row['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            continue;
          }

          Map<String, dynamic>? beneficiaryRow;

          try {
            beneficiaryRow = await LocalStorageDao.instance
                .getBeneficiaryByUniqueKey(beneficiaryRefKey);

            if (beneficiaryRow == null) {
              final fallback = await db.query(
                'beneficiaries_new',
                where:
                'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND current_user_key = ?',
                whereArgs: [beneficiaryRefKey, ashaUniqueKey],
                limit: 1,
              );

              if (fallback.isNotEmpty) {
                final legacy = Map<String, dynamic>.from(fallback.first);

                Map<String, dynamic> info = {};
                try {
                  final formJson = legacy['form_json'];
                  if (formJson is String && formJson.isNotEmpty) {
                    final decoded = jsonDecode(formJson);
                    if (decoded is Map) {
                      info = Map<String, dynamic>.from(decoded);
                    }
                  }
                } catch (_) {}

                beneficiaryRow = {
                  ...legacy,
                  'beneficiary_info': info,
                  'geo_location': {},
                  'death_details': {},
                };
              }
            }
          } catch (_) {}

          final formJsonStr = row['form_json']?.toString() ?? '{}';
          Map<String, dynamic> formJson = {};
          Map<String, dynamic> formData = {};
          try {
            final decoded = jsonDecode(formJsonStr);
            if (decoded is Map) {
              formJson = Map<String, dynamic>.from(decoded);
              final fd = formJson['form_data'];
              if (fd is Map) formData = Map<String, dynamic>.from(fd);
            }
          } catch (_) {}

          // First try to get name from beneficiary info if available
          String womanName = 'Unknown';
          if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
            try {
              final info = beneficiaryRow['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
                  : (beneficiaryRow['beneficiary_info'] is String
                  ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
                  : <String, dynamic>{});

              womanName = (info['headName'] ?? info['name'] ??info['memberName'] ?? info['spouseName']?? info['woman_name'] ?? 'Unknown').toString();
            } catch (e) {
              print('⚠️ Error parsing beneficiary_info: $e');
            }
          }

          if (womanName == 'Unknown') {
            womanName = (formData['woman_name'] ?? formData['name'] ?? formData['memberName'] ?? formData['headName'] ?? 'Unknown').toString();
          }

          // Try to get husband name from beneficiary info first
          String husbandName = 'N/A';
          if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
            try {
              final info = beneficiaryRow['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
                  : (beneficiaryRow['beneficiary_info'] is String
                  ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
                  : <String, dynamic>{});

              husbandName = (info['spouseName'] ?? info['spouse_name'] ?? info['husbandName'] ?? info['husband_name'] ?? 'N/A').toString();
            } catch (e) {
              print('⚠️ Error parsing beneficiary_info for spouse name: $e');
            }
          }

          if (husbandName == 'N/A') {
            husbandName = (formData['husband_name'] ?? formData['spouse_name'] ?? formData['spouseName'] ?? formData['husbandName'] ?? 'N/A').toString();
          }

          final lmpDate = formData['lmp_date']?.toString() ?? '';
          final eddDate = formData['edd_date']?.toString() ?? '';
          final weeksOfPregnancy = formData['weeks_of_pregnancy']?.toString() ?? '';
          final mobileNo = formData['mobile_no']?.toString() ?? '';

          // Calculate age and gender from beneficiary info
          String ageYearsDisplay = '';
          String gender = '';
          String mobileFromBeneficiary = mobileNo;

          if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
            try {
              final info = beneficiaryRow['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
                  : <String, dynamic>{};

              final dob = info['dob']?.toString();
              int ageYears = _calculateAge(dob);

              if (ageYears == 0) {
                final updateYearStr = info['updateYear']?.toString() ?? '';
                final approxAgeStr = info['approxAge']?.toString() ?? '';
                final parsedUpdateYear = int.tryParse(updateYearStr);
                if (parsedUpdateYear != null && parsedUpdateYear > 0) {
                  ageYears = parsedUpdateYear;
                } else if (approxAgeStr.isNotEmpty) {
                  final matches = RegExp(r"\d+").allMatches(approxAgeStr).toList();
                  if (matches.isNotEmpty) {
                    ageYears = int.tryParse(matches.first.group(0) ?? '') ?? 0;
                  }
                }
              }
              ageYearsDisplay = ageYears > 0 ? ageYears.toString() : '';

              gender = info['gender']?.toString() ?? '';
              if (gender.toLowerCase() == 'f') {
                gender = 'F';
              } else if (gender.toLowerCase() == 'female') {
                gender = 'F';
              }

              final m = (info['mobileNo']?.toString() ?? info['mobile']?.toString() ?? info['phone']?.toString() ?? '').trim();
              if (m.isNotEmpty) {
                mobileFromBeneficiary = m;
              }
            } catch (e) {
              print('⚠️ Error extracting beneficiary_info for $beneficiaryRefKey: $e');
            }
          }

          final ageGenderCombined = (ageYearsDisplay.isNotEmpty || gender.isNotEmpty)
              ? '${ageYearsDisplay.isNotEmpty ? ageYearsDisplay : 'N/A'} | ${gender.isNotEmpty ? gender : 'N/A'}'
              : 'N/A';

          processedData.add({
            'hhId': row['household_ref_key']?.toString() ?? '',
            'beneficiaryId': row['beneficiary_ref_key']?.toString() ?? '',
            'name': womanName,
            'husbandName': husbandName,
            'mobileNo': mobileFromBeneficiary,
            'lmpDate': lmpDate,
            'eddDate': eddDate,
            'weeksOfPregnancy': weeksOfPregnancy,
            'formId': row['form_id']?.toString() ?? '',
            'formData': formData,
            'age': ageGenderCombined,
            'beneficiaryRow': beneficiaryRow,
            '_rawRow': row,
          });
        } catch (e) {
          print(' Error processing delivery outcome row: $e');
        }
      }

      setState(() {
        _allData = processedData;
        _filtered = processedData;
        _isLoading = false;
      });
    } catch (e) {
      print(' Error loading pregnancy cases: $e');
      setState(() {
        _isLoading = false;
        _allData = [];
        _filtered = [];
      });
    }
  }

  String _calculatePregnancyWeeks(String lmpDate, String eddDate, String weeksPregnant) {
    if (weeksPregnant.isNotEmpty) {
      return '$weeksPregnant weeks';
    }

    try {
      DateTime? referenceDate;

      if (lmpDate.isNotEmpty) {
        referenceDate = DateTime.tryParse(lmpDate);
        if (referenceDate != null) {
          final weeks = (DateTime.now().difference(referenceDate).inDays / 7).floor();
          return '$weeks weeks (LMP)';
        }
      }

      if (eddDate.isNotEmpty) {
        referenceDate = DateTime.tryParse(eddDate);
        if (referenceDate != null) {
          final weeks = 40 - (referenceDate.difference(DateTime.now()).inDays / 7).floor();
          return '$weeks weeks (EDD)';
        }
      }
    } catch (e) {
      print('Error calculating pregnancy weeks: $e');
    }

    return 'N/A';
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }




  String _twoDigits(int n) => n >= 10 ? '$n' : '0$n';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n!.pregnancyOutcome,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [


                Expanded(
                  child: _filtered.isEmpty
                      ? _buildNoRecordCard(context)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final data = _filtered[index];
                            return _pregnancyCard(context, data);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _pregnancyCard(BuildContext context, Map<String, dynamic> data) {
    final Color primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final hhId = data['beneficiaryId']?.toString() ?? '';
    final displayHhId = hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId;
    final name = data['name'] ?? 'N/A';
    final ageGender = data['age'] ?? 'N/A';
    final status = 'Pregnant';

    return Container(
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
          // Header with HH ID
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
                      displayHhId,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Container(
            decoration: BoxDecoration(
              color: primary.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    name,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),

                // Age and Gender
                _infoRow('', ageGender, isWrappable: true),
  ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, {bool isWrappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13.sp,
              ),
              overflow: isWrappable ? null : TextOverflow.ellipsis,
              maxLines: isWrappable ? null : 1,
            ),
          ),
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
