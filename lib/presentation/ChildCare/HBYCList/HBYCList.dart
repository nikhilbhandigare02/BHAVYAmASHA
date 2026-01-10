import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

class HBYCList extends StatefulWidget {
  const HBYCList({super.key});

  @override
  State<HBYCList> createState() => _HBYCListState();
}

class _HBYCListState extends State<HBYCList> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<Map<String, dynamic>> _hbycChildren = [];
  late List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final Map<String, bool> _syncCache = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadHBYCChildren();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _isHbycSynced(String beneficiaryId) async {
    if (beneficiaryId.isEmpty) return false;
    
    // Check cache first
    final cacheKey = 'hbyc_$beneficiaryId';
    if (_syncCache.containsKey(cacheKey)) {
      return _syncCache[cacheKey] ?? false;
    }
    
    try {
      final db = await DatabaseProvider.instance.database;
      
      debugPrint('Checking sync status for beneficiary: $beneficiaryId in beneficiaries_new table');
      
      final rows = await db.query(
        'beneficiaries_new',
        columns: ['is_synced'],
        where: 'unique_key = ?',
        whereArgs: [beneficiaryId],
        limit: 1,
        orderBy: 'created_date_time DESC',
      );
      
      bool isSynced = false;
      
      if (rows.isNotEmpty) {
        // Check both integer 1 and string '1' for compatibility
        isSynced = rows.first['is_synced'] == 1 || rows.first['is_synced'] == '1';
        debugPrint('Sync status for $beneficiaryId from beneficiaries_new: ${isSynced ? 'Synced' : 'Not Synced'} (value: ${rows.first['is_synced']})');
      } else {
        debugPrint('No record found in beneficiaries_new for beneficiary: $beneficiaryId');
      }
      
      // Update cache
      _syncCache[cacheKey] = isSynced;
      return isSynced;
    } catch (e) {
      debugPrint('Error checking sync status for $beneficiaryId: $e');
      return false;
    }
  }

  // Calculate age in months from date of birth
  int _calculateAgeInMonths(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return 0;
    
    try {
      final dob = DateTime.parse(dobStr);
      final now = DateTime.now();
      final months = (now.year - dob.year) * 12 + now.month - dob.month;
      return months;
    } catch (e) {
      print('Error calculating age for DOB: $dobStr - $e');
      return 0;
    }
  }

  // Check if age is between 3 and 15 months
  bool _isAgeInRange(String? dobStr) {
    final months = _calculateAgeInMonths(dobStr);
    return months >= 3 && months <= 15;
  }

  // Format date to 'dd-MM-yyyy'
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Format age and gender string
  String _formatAgeGender(String? dob, String? gender) {
    final months = _calculateAgeInMonths(dob);
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    
    String ageText = years > 0 
        ? '$years Y${remainingMonths > 0 ? ' $remainingMonths M' : ''}'
        : '$months M';
        
    return '$ageText | ${gender ?? 'N/A'}';
  }

  // Check if case is closed for a beneficiary
  Future<bool> _isCaseClosed(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final caseClosureRecords = await db.query(
        'followup_form_data',
        where: 'beneficiary_ref_key = ? AND form_json LIKE ?',
        whereArgs: [beneficiaryRefKey, '%case_closure%'],
      );
      
      for (final record in caseClosureRecords) {
        try {
          final formJson = record['form_json'] as String?;
          if (formJson != null) {
            final formData = jsonDecode(formJson);
            final formDataMap = formData['form_data'] as Map<String, dynamic>? ?? {};
            final caseClosure = formDataMap['case_closure'] as Map<String, dynamic>? ?? {};
            if (caseClosure['is_case_closure'] == true) {
              return true;
            }
          }
        } catch (e) {
          debugPrint('Error checking case closure: $e');
        }
      }
    } catch (e) {
      debugPrint('Error querying case closure: $e');
    }
    return false;
  }

  // Future<void> _loadHBYCChildren() async {
  //   if (!mounted) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final db = await DatabaseProvider.instance.database;
  //
  //
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     String whereClause;
  //     List<Object?> whereArgs;
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       whereClause = 'is_deleted = ? AND is_adult = ? AND current_user_key = ?';
  //       whereArgs = [0, 0, ashaUniqueKey];
  //     } else {
  //       whereClause = 'is_deleted = ? AND is_adult = ?';
  //       whereArgs = [0, 0];
  //     }
  //
  //     final List<Map<String, dynamic>> rows = await db.query(
  //       'beneficiaries_new',
  //       where: whereClause,
  //       whereArgs: whereArgs,
  //     );
  //
  //     final hbycChildren = <Map<String, dynamic>>[];
  //
  //     for (final row in rows) {
  //       final rowHhId = row['household_ref_key']?.toString();
  //       if (rowHhId == null) continue;
  //
  //       final info = row['beneficiary_info'] is String
  //           ? jsonDecode(row['beneficiary_info'] as String)
  //           : row['beneficiary_info'];
  //
  //       if (info is! Map) continue;
  //
  //       final memberType = info['memberType']?.toString() ?? '';
  //       final dob = info['dob']?.toString();
  //
  //       // Only process child members with age between 3-15 months and not case closed
  //       if (memberType == 'Child' && _isAgeInRange(dob)) {
  //         final beneficiaryId = row['unique_key']?.toString() ?? '';
  //
  //         // Skip if case is closed for this beneficiary
  //         if (beneficiaryId.isNotEmpty && await _isCaseClosed(beneficiaryId)) {
  //           continue;
  //         }
  //
  //         final name = info['name']?.toString() ??
  //                     info['memberName']?.toString() ??
  //                     info['member_name']?.toString() ??
  //                     info['memberNameLocal']?.toString() ??
  //                     '';
  //
  //         final gender = info['gender']?.toString() ?? '';
  //         final ageGender = _formatAgeGender(dob, gender);
  //
  //         final richId = info['RichIDChanged']?.toString() ??
  //                       info['richIdChanged']?.toString() ??
  //                       info['richId']?.toString() ?? '';
  //
  //         final card = <String, dynamic>{
  //           'hhId': rowHhId,
  //           'RegitrationDate': _formatDate(row['created_date_time']?.toString()),
  //           'RegitrationType': 'HBYC',
  //           'BeneficiaryID': beneficiaryId,
  //           'RchID': richId,
  //           'Name': name,
  //           'Age|Gender': ageGender,
  //           '_raw': row,
  //           '_info': info,
  //         };
  //
  //         hbycChildren.add(card);
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         _hbycChildren = List<Map<String, dynamic>>.from(hbycChildren);
  //         _filtered = List<Map<String, dynamic>>.from(hbycChildren);
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Error loading HBYC children: $e');
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }


  Future<void> _loadHBYCChildren() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;

      /* ------------------------------------------------------------
     * STEP 1: Fetch deceased beneficiaries from followup forms
     * ------------------------------------------------------------ */
      final deceasedChildren = await db.rawQuery('''
      SELECT DISTINCT beneficiary_ref_key, form_json
      FROM followup_form_data
      WHERE form_json LIKE '%"reason_of_death":%'
    ''');

      final Set<String> deceasedIds = {};

      for (final child in deceasedChildren) {
        try {
          final jsonData = jsonDecode(child['form_json'] as String);
          final formData = jsonData['form_data'] as Map<String, dynamic>?;
          final caseClosure = formData?['case_closure'] as Map<String, dynamic>?;

          if (caseClosure?['is_case_closure'] == true &&
              caseClosure?['reason_of_death']
                  ?.toString()
                  .toLowerCase() ==
                  'death') {
            final id = child['beneficiary_ref_key']?.toString();
            if (id != null && id.isNotEmpty) {
              deceasedIds.add(id);
            }
          }
        } catch (_) {}
      }

      /* ------------------------------------------------------------
     * STEP 2: Get current ASHA user key
     * ------------------------------------------------------------ */
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      /* ------------------------------------------------------------
     * STEP 3: Build beneficiary query
     * ------------------------------------------------------------ */
      String whereClause =
          'is_deleted = ? AND is_adult = ? AND is_death = ?';
      List<dynamic> whereArgs = [0, 0, 0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final List<Map<String, dynamic>> rows = await db.query(
        'beneficiaries_new',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_date_time DESC',
      );

      /* ------------------------------------------------------------
     * STEP 4: Process rows
     * ------------------------------------------------------------ */
      final List<Map<String, dynamic>> hbycChildren = [];

      for (final row in rows) {
        try {
          final hhId = row['household_ref_key']?.toString();
          if (hhId == null || hhId.isEmpty) continue;

          /* ---------- Parse beneficiary_info ---------- */
          Map<String, dynamic> info = {};
          try {
            if (row['beneficiary_info'] is String) {
              info = jsonDecode(row['beneficiary_info'] as String);
            } else if (row['beneficiary_info'] is Map) {
              info = Map<String, dynamic>.from(
                  row['beneficiary_info'] as Map);
            }
          } catch (_) {
            continue;
          }

          /* ---------- CHILD CONDITION (NEW) ---------- */
          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final relation =
              info['relation']?.toString().toLowerCase() ?? '';

          final isChild = memberType == 'child' ||
              relation == 'child' ||
              relation == 'son' ||
              relation == 'daughter';

          if (!isChild) continue;

          /* ---------- DOB & Age Check (3–15 months) ---------- */
          final dob = info['date_of_birth']?.toString() ??
              info['dob']?.toString();
          if (!_isAgeInRange(dob)) continue;

          /* ---------- Beneficiary ID ---------- */
          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          /* ---------- Death Filters ---------- */
          if (deceasedIds.contains(beneficiaryId)) continue;
          if ((row['is_death'] ?? 0) == 1) continue;

          /* ---------- Case Closed ---------- */
          if (await _isCaseClosed(beneficiaryId)) continue;

          /* ---------- Extract Fields ---------- */
          final name = _getValueFromMap(info, [
            'name',
            'child_name',
            'memberName',
            'member_name',
            'memberNameLocal'
          ]);

          final gender = _getValueFromMap(info, ['gender', 'sex']);

          final rchId = _getValueFromMap(info, [
            'rch_id',
            'rchId',
            'RichIDChanged',
            'richIdChanged',
            'richId'
          ]);

          final registrationDate =
              row['created_date_time']?.toString() ??
                  info['registration_date']?.toString() ??
                  info['createdAt']?.toString();

          /* ---------- Build Card ---------- */
          final t = AppLocalizations.of(context);
          final card = <String, dynamic>{
            'hhId': hhId,
            'RegitrationDate': _formatDate(registrationDate),
            'RegitrationType': 'Child',
            'BeneficiaryID': beneficiaryId,
            'RchID': rchId.isNotEmpty ?rchId : t!.na,
            'Name': name.isNotEmpty ? name : 'Unnamed Child',
            'Age|Gender': _formatAgeGender(dob, gender),
            'DOB': _formatDate(dob),
            'Gender': gender,
            '_raw': row,
            '_info': info,
          };

          hbycChildren.add(card);
        } catch (e) {
          debugPrint('⚠️ Error processing HBYC row: $e');
        }
      }

      /* ------------------------------------------------------------
     * STEP 5: Update UI
     * ------------------------------------------------------------ */
      if (mounted) {
        setState(() {
          _hbycChildren = List<Map<String, dynamic>>.from(hbycChildren);
          _filtered = List<Map<String, dynamic>>.from(hbycChildren);
          _isLoading = false;
        });

        debugPrint('✅ Loaded ${hbycChildren.length} HBYC children');
      }
    } catch (e) {
      debugPrint('❌ Error loading HBYC children: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getValueFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  // Handle search functionality
  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_hbycChildren);
      } else {
        _filtered = _hbycChildren.where((e) {
          return (e['hhId']?.toString().toLowerCase().contains(q) ?? false) ||
                 (e['Name']?.toString().toLowerCase().contains(q) ?? false) ||
                 (e['BeneficiaryID']?.toString().toLowerCase().contains(q) ?? false) ||
                 (e['RchID']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle:  l10n?.hbycListTitle ?? 'HBYC List',
        showBack: true,

      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  l10n?.searchHintHbycBen ?? 'Search HBYC',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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



          // 📋 List of HBYC Children
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                       l10n!.noHbycChildrenFound,
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
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

  // 🧱 Household Card UI
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              Route_Names.HBYCChildCareForm,
              arguments: {
                'isBeneficiary': true,
                'hhid': data['hhId']?.toString() ?? '',
                'name': data['Name']?.toString() ?? '',
                'beneficiaryId': data['BeneficiaryID']?.toString() ?? '',
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
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
                // Header Row
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data['hhId']!.toString().length > 11
                              ? '${data['hhId']?.toString().substring(data['hhId'].toString().length - 11)}'
                              : data['hhId']?.toString() ?? '',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<bool>(
                        future: _isHbycSynced(data['BeneficiaryID']?.toString() ?? ''),
                        builder: (context, snapshot) {
                          final isSynced = snapshot.data == true;
                          return Image.asset(
                            'assets/images/sync.png',
                            width: 25,
                            color: isSynced ? null : Colors.grey[500],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Card Body
                Container(
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow([
                        _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate']),
                        _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType']),
                        _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', 
                          data['BeneficiaryID']!.toString().length > 11
                              ? '${data['BeneficiaryID']?.toString().substring(data['BeneficiaryID'].toString().length - 11)}'
                              : data['BeneficiaryID']?.toString() ?? ''
                        ),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.nameLabel ?? 'Name', data['Name']),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']),
                        _rowText(l10n?.rchIdLabel ?? 'RCH ID', data['RchID'] ?? l10n?.na),
                      ]),


                    ],
                  ),
                ),
              ],
            ),
          ),
        ),


      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ]
      ],
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
