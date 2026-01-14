import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../EligibleCoupleUpdate/EligibleCoupleUpdateScreen.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';

class EligibleCoupleIdentifiedScreen extends StatefulWidget {
  const EligibleCoupleIdentifiedScreen({super.key});

  @override
  State<EligibleCoupleIdentifiedScreen> createState() =>
      _EligibleCoupleIdentifiedScreenState();
}

class _EligibleCoupleIdentifiedScreenState
    extends State<EligibleCoupleIdentifiedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEligibleCouples();
    _searchCtrl.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadEligibleCouples();

      debugPrint(
        '✅ Eligible Couples Count: ${_filtered.length}',
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }


  Map<String, dynamic> _toStringMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    return {};
  }

  int? _calculateAgeFromDob(String? dob) {
    if (dob == null || dob.isEmpty) return null;

    try {
      final DateTime dobDate = DateTime.parse(dob);
      final DateTime today = DateTime.now();

      int age = today.year - dobDate.year;

      if (today.month < dobDate.month ||
          (today.month == dobDate.month && today.day < dobDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return null;
    }
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

  Future<void> _loadEligibleCouples() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String currentUserKey =
          currentUserData?['unique_key']?.toString() ?? '';

      if (currentUserKey.isEmpty) {
        setState(() {
          _filtered = [];
          _isLoading = false;
        });
        return;
      }

      final query = '''
      SELECT DISTINCT b.*, 
             e.eligible_couple_state, 
             e.created_date_time AS registration_date
      FROM beneficiaries_new b
      INNER JOIN eligible_couple_activities e 
              ON b.unique_key = e.beneficiary_ref_key
      WHERE b.is_deleted = 0
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND (b.is_death = 0 OR b.is_death IS NULL)
        AND e.eligible_couple_state IN ('eligible_couple')
        AND e.is_deleted = 0
        AND e.current_user_key = ?
        AND b.current_user_key = ?
      ORDER BY b.created_date_time DESC;
    ''';

      final rows = await db.rawQuery(query, [currentUserKey, currentUserKey]);

      if (rows.isEmpty) {
        setState(() {
          _filtered = [];
          _isLoading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> couples = [];
      final Set<String> processedBeneficiaries = {};

      for (final row in rows) {
        try {
          final beneficiaryKey = row['unique_key']?.toString();
          if (beneficiaryKey == null || beneficiaryKey.isEmpty) continue;

          // ❌ Avoid duplicates
          if (processedBeneficiaries.contains(beneficiaryKey)) continue;

          // 🔹 Parse JSON fields
          final beneficiaryInfoStr = row['beneficiary_info']?.toString() ?? '{}';
          final Map<String, dynamic> info =
          Map<String, dynamic>.from(jsonDecode(beneficiaryInfoStr));

          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final maritalStatus =
              info['maritalStatus']?.toString().toLowerCase() ?? '';

          // ❌ Skip child
          if (memberType == 'child') continue;

          // ❌ Skip unmarried
          if (maritalStatus != 'married') continue;

          // 🔹 Age
          int? age;
          if (info['age'] != null) {
            age = int.tryParse(info['age'].toString());
          }
          age ??= _calculateAgeFromDob(info['dob']?.toString());

          if (age == null || age < 15 || age > 49) continue;

          // ❌ Skip sterilization cases
          final hasSterilization = await _hasSterilizationRecord(
            db,
            beneficiaryKey,
            currentUserKey,
          );

          if (hasSterilization) continue;

          // ✅ Mark processed
          processedBeneficiaries.add(beneficiaryKey);

          // 🔹 Normalize row before sending to UI
          final Map<String, dynamic> normalizedRow =
          Map<String, dynamic>.from(row);

          try {
            normalizedRow['beneficiary_info'] = info;
            normalizedRow['geo_location'] =
                jsonDecode(normalizedRow['geo_location'] ?? '{}');
            normalizedRow['device_details'] =
                jsonDecode(normalizedRow['device_details'] ?? '{}');
            normalizedRow['app_details'] =
                jsonDecode(normalizedRow['app_details'] ?? '{}');
            normalizedRow['parent_user'] =
                jsonDecode(normalizedRow['parent_user'] ?? '{}');
          } catch (_) {}

          // ✅ Add to list
          couples.add(
            _formatCoupleData(
              normalizedRow,
              info,
              <String, dynamic>{},
              isHead: false,
              shouldShowGuestBadge: false,
            ),
          );
        } catch (_) {
          continue;
        }
      }

      setState(() {
        _filtered = couples;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error in _loadEligibleCouples: $e');
      print(stackTrace);
      setState(() {
        _filtered = [];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead, bool shouldShowGuestBadge = false}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['registration_date']?.toString() ?? '';
    final info = _toStringMap(row['beneficiary_info']);
    final head = _toStringMap(info['head_details']);
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender?.isNotEmpty == true ? gender![0].toUpperCase() + gender!.substring(1) : 'Not Available';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? '';
    final mobile = female['mobile_no']?.toString() ?? female['mobileNo']?.toString() ?? 'Not Available';
    final husbandName = female['spouseName']?.toString() ??
        (isHead
            ? (headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString())
            : (headOrSpouse['headName']?.toString() ?? headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString()))
        ?? '';

    final dynamic childrenRaw = info['children_details'] ?? head['childrendetails'] ?? head['childrenDetails'];
    String last11(String s) => s.length > 11 ? s.substring(s.length - 11) : s;

    Map<String, dynamic>? childrenSummary;
    if (childrenRaw != null) {
      final childrenMap = _toStringMap(childrenRaw);
      childrenSummary = {
        'totalBorn': childrenMap['totalBorn'],
        'totalLive': childrenMap['totalLive'],
        'totalMale': childrenMap['totalMale'],
        'totalFemale': childrenMap['totalFemale'],
        'youngestAge': childrenMap['youngestAge'],
        'ageUnit': childrenMap['ageUnit'],
        'youngestGender': childrenMap['youngestGender'],
      }..removeWhere((k, v) => v == null);
    }
    return {
      'hhId': hhId,
      'hhIdShort': last11(hhId),
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': uniqueKey,
      'BeneficiaryIDShort': last11(uniqueKey) ,
      'Name': name,
      'age': age > 0 ? '$age Y | $displayGender' : 'N/A',
      'RCH ID': richId.isNotEmpty ? richId : 'Not Available',
      'mobileno': mobile,
      'HusbandName': husbandName.isNotEmpty ? husbandName : 'Not Available',
      'childrenSummary': childrenSummary,
      '_rawRow': row,
      'fullHhId': hhId,
      'fullBeneficiaryId': uniqueKey,
      'shouldShowGuestBadge': shouldShowGuestBadge,
    };
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _loadEligibleCouples();
      } else {
        _filtered = _filtered.where((e) {
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['Name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobileno'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.updatedEligibleCoupleListSubtitle ?? 'Eligible Couple List',
          showBack: true,
          icon1Image: 'assets/images/home.png',

          onIcon1Tap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(initialTabIndex: 1),
            ),
          ),
        ),
        drawer: const CustomDrawer(),
        body: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: l10n?.searchEligibleCouple ?? 'search Eligible Couple',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ),

            // Household List
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
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    final rowData = data['_rawRow'] ?? {};
    final beneficiaryInfo = rowData['beneficiary_info'] is String
        ? jsonDecode(rowData['beneficiary_info'])
        : (rowData['beneficiary_info'] ?? {});

    final headDetails = _toStringMap(beneficiaryInfo['head_details']);
    final spouseDetails = _toStringMap(beneficiaryInfo['spouse_details']);

    final childrenDetails = _toStringMap(
        beneficiaryInfo['children_details'] ??
            headDetails['childrendetails'] ??
            headDetails['childrenDetails']
    );
    final isMale = beneficiaryInfo['gender']?.toString().toLowerCase() == 'male';
    final spouseLabel = isMale ? (l10n?.wifeName ?? 'Wife Name') : (l10n?.husbandName ?? 'Husband Name');

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () async {

            final fullHhId = rowData['household_ref_key']?.toString() ?? '';
            final fullBeneficiaryId = rowData['unique_key']?.toString() ??
                data['fullBeneficiaryId']?.toString() ??
                data['BeneficiaryID']?.toString() ?? '';
            final name = data['Name']?.toString() ?? '' ;
            final richId = data['RichID']?.toString() ?? '';
            final mobile = data['mobileno']?.toString() ?? '';
            final husbandName = data['HusbandName']?.toString() ?? '';
            final ageGender = data['age']?.toString() ?? '';
            final registrationDate = data['RegistrationDate']?.toString() ?? '';

            print('🚀 Navigating to update screen with:');
            print('   Household ID (full): $fullHhId');
            print('   Beneficiary ID (full): $fullBeneficiaryId');
            print('   Name: $name');

            final result = await Navigator.pushNamed(
              context,
              Route_Names.UpdatedEligibleCoupleList,
              arguments: {
                'hhId': fullHhId,
                'name': name,

                'unique_key': fullBeneficiaryId,
                'RCH ID': richId,
                'mobile': mobile,
                'husbandName': husbandName,
                'ageGender': ageGender,
                'registrationDate': registrationDate,
                'formData': data,
              },
            );


            if (result == true) {
              _loadEligibleCouples();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
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
                // Header
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      Expanded(
                        child: Text(
                          data['hhIdShort'] ?? data['hhId'] ?? '',
                          style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(width: 8),
                      if (data['shouldShowGuestBadge'] == true || beneficiaryInfo['gender']?.toString().toLowerCase() == 'male')
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Guest',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/sync.png',
                        width: 24,
                        height: 24,
                        color: (data['_rawRow']?['is_synced'] == 1) ? null : Colors.grey,
                      ),
                    ],
                  ),
                ),
                // Body
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegistrationDate'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText(l10n?.registrationTypeLabel ??'Registration Type', data['RegistrationType'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryIDShort'] ?? data['BeneficiaryID'] ?? '')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _rowText(l10n?.nameLabel ??  'Name', data['Name'] ?? ''),
                                ),

                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['age']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText(l10n?.rchIdLabel ?? 'RCH ID', data['RCH ID']?.toString() ?? l10n!.na)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['mobileno']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox.shrink()),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _rowText(spouseLabel, data['HusbandName'] ?? '')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(color: AppColors.background, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 13.sp),
        ),
      ],
    );
  }
}
