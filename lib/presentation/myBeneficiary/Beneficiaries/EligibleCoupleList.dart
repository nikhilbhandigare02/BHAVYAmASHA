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
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';

class EligibleCoupleList extends StatefulWidget {
  const EligibleCoupleList({super.key});

  @override
  State<EligibleCoupleList> createState() => _EligibleCoupleListState();
}

class _EligibleCoupleListState extends State<EligibleCoupleList> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadEligibleCouples();
  }

  Future<void> _loadEligibleCouples() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      
      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        setState(() {
          _filtered = [];
        });
        return;
      }

      final query = '''
        SELECT DISTINCT b.*, e.eligible_couple_state, 
               e.created_date_time as registration_date
        FROM beneficiaries_new b
        INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
        WHERE b.is_deleted = 0 
          AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
          AND (b.is_death = 0 OR b.is_death IS NULL)
          AND e.eligible_couple_state = 'eligible_couple'
          AND e.is_deleted = 0
          AND e.current_user_key = ?
        ORDER BY b.created_date_time DESC
      ''';

      print('Executing query: $query');
      print('With param: $ashaUniqueKey');
      
      final rows = await db.rawQuery(query, [ashaUniqueKey]);
      print('Found ${rows.length} eligible couples');
      
      if (rows.isEmpty) {
        print('No eligible couples found for current user');
        setState(() {
          _filtered = [];
        });
        return;
      }
      
      final filteredRows = rows.map((row) {
        final Map<String, dynamic> mappedRow = Map<String, dynamic>.from(row);
        
        try {
          mappedRow['beneficiary_info'] = jsonDecode(mappedRow['beneficiary_info'] ?? '{}');
          mappedRow['geo_location'] = jsonDecode(mappedRow['geo_location'] ?? '{}');
          mappedRow['device_details'] = jsonDecode(mappedRow['device_details'] ?? '{}');
          mappedRow['app_details'] = jsonDecode(mappedRow['app_details'] ?? '{}');
          mappedRow['parent_user'] = jsonDecode(mappedRow['parent_user'] ?? '{}');
        } catch (e) {
          print('Error parsing JSON fields: $e');
        }
        
        return mappedRow;
      }).toList();
      
      print('Processed ${filteredRows.length} rows');

      final couples = <Map<String, dynamic>>[];

      // Process each eligible row
      for (final member in filteredRows) {
        final info = _toStringMap(member['beneficiary_info']);
        final memberUniqueKey = member['unique_key']?.toString() ?? '';
        
        // Check memberType and skip if child
        final memberType = info['memberType']?.toString().toLowerCase() ?? '';
        if (memberType == 'child') {
          print('Skipping child record: $memberUniqueKey');
          continue;
        }

        couples.add(_formatCoupleData(
          _toStringMap(member),
          info,
          <String, dynamic>{}, // Empty counterpart
          isHead: false,
        ));
      }

      print('Final couples list contains ${couples.length} items');
      setState(() {
        _filtered = couples;
      });
    } catch (e, stackTrace) {
      print('Error in _loadEligibleCouples: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _filtered = [];
      });
    }
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    if (!isFemale) return false;
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isMarried = maritalStatusRaw == 'married';
    if (!isMarried) return false;
    final dob = person['dob'];
    final age = _calculateAge(dob);
    final fpMethodRaw = person['fpMethod']?.toString().toLowerCase().trim() ?? '';
    final hpMethodRaw = person['hpMethod']?.toString().toLowerCase().trim() ?? '';
    final isSterilized = fpMethodRaw == 'female sterilization' || fpMethodRaw == 'male sterilization' || hpMethodRaw == 'female sterilization' || hpMethodRaw == 'male sterilization';
    return age >= 15 && age <= 49 && !isSterilized;
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
        screenTitle: l10n?.eligibleCoupleListTitle ?? 'Eligible Couple List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Expanded(
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
                      const Icon(Icons.home, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (data['hhId']?.toString().length ?? 0) > 11 ? data['hhId'].toString().substring(data['hhId'].toString().length - 11) : (data['hhId'] ?? ''),
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
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n?.badgeEligibleCouple ?? 'Eligible Couple',
                      style: const TextStyle(
                        color: Colors.green,
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

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['registration_date']?.toString() ?? '';
    final info = _toStringMap(row['beneficiary_info']);
    final head = _toStringMap(info['head_details']);
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender?.isNotEmpty == true ? gender![0].toUpperCase() + gender!.substring(1) : 'Not Available';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? female['richId']?.toString() ?? '';

    return {
      'hhId': hhId,
      'unique_key': uniqueKey,
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'Eligible Couple',
      'BeneficiaryID': uniqueKey,
      'RCH ID': richId,
      'name': name,  // Changed from 'Name' to 'name'
      'age_gender': '$age Y | $displayGender',  // Changed from 'age' to 'age_gender'
      'Age': '$displayGender | $age',
      'RCHID': richId,
    };
  }

  Map<String, dynamic> _toStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(value));
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }


}
