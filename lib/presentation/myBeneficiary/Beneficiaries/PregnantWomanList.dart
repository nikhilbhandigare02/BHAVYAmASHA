import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'dart:convert';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class PregnantWomenList extends StatefulWidget {
  const PregnantWomenList({super.key});

  @override
  State<PregnantWomenList> createState() => _PregnantWomenListState();
}

class _PregnantWomenListState extends State<PregnantWomenList> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPregnantWomen() async {
    setState(() { _isLoading = true; });

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];
      final processedBeneficiaries = <String>{};

      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final row in rows) {
        try {
          final rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;
          final Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo) as Map<String, dynamic>
              : Map<String, dynamic>.from(rawInfo as Map);

          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          final isPregnant = _isPregnant(info);
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

          if ((isPregnant || isAncDue) && (gender == 'f' || gender == 'female')) {
            final item = _formatCardData(row, info);
            item['status'] = isAncDue ? 'ANC DUE' : 'Pregnant';
            item['isAncDue'] = isAncDue;
            item['unique_key'] = beneficiaryId;
            item['BeneficiaryID'] = beneficiaryId;
            item['created_date_time'] = row['created_date_time']?.toString() ?? '';
            pregnantWomen.add(item);
            processedBeneficiaries.add(beneficiaryId);
          }
        } catch (_) {}
      }

      for (final anc in ancDueRecords) {
        final beneficiaryId = anc['beneficiary_ref_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty || processedBeneficiaries.contains(beneficiaryId)) continue;
        final hhId = anc['household_ref_key']?.toString() ?? '';
        final displayId = beneficiaryId.length > 11 ? beneficiaryId.substring(beneficiaryId.length - 11) : beneficiaryId;
        final item = {
          'hhId': hhId,
          'name': 'ANC Due - $displayId',
          'age_gender': 'N/A | N/A',
          'status': 'ANC DUE',
          'unique_key': beneficiaryId,
          'BeneficiaryID': beneficiaryId,
          'created_date_time': anc['created_date_time']?.toString() ?? '',
        };
        pregnantWomen.add(item);
      }

      final byBeneficiary = <String, Map<String, dynamic>>{};
      for (final item in pregnantWomen) {
        final benId = item['BeneficiaryID']?.toString() ?? '';
        final uniqueKey = item['unique_key']?.toString() ?? '';
        final key = benId.isNotEmpty ? benId : uniqueKey;
        if (key.isEmpty) continue;
        byBeneficiary[key] = item;
      }

      final dedupedList = byBeneficiary.values.toList();
      dedupedList.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_date_time']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['created_date_time']?.toString() ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _filtered = dedupedList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false); 
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAncDueRecords() async {
    final db = await DatabaseProvider.instance.database;

    final currentUserData = await SecureStorageService.getCurrentUserData();
    final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
      return [];
    }

    final rows = await db.rawQuery(
      '''
    WITH RankedMCA AS (
      SELECT
        mca.*,
        ROW_NUMBER() OVER (
          PARTITION BY mca.beneficiary_ref_key
          ORDER BY mca.created_date_time DESC, mca.id DESC
        ) AS rn
      FROM mother_care_activities mca
      WHERE
        mca.is_deleted = 0
        AND mca.current_user_key = ?
    )
    SELECT r.*
    FROM RankedMCA r
    INNER JOIN beneficiaries_new bn
      ON r.beneficiary_ref_key = bn.unique_key
    WHERE
      r.rn = 1
      AND r.mother_care_state = 'anc_due'
      AND bn.is_deleted = 0
    ORDER BY r.created_date_time DESC; 
    ''',
      [ashaUniqueKey],
    );

    return rows;
  }

  bool _isPregnant(Map<String, dynamic> person) {
    final flag = person['isPregnant']?.toString().toLowerCase();
    final typoFlag = person['isPregrant']?.toString().toLowerCase();
    final statusFlag = person['pregnancyStatus']?.toString().toLowerCase();
    return flag == 'yes' || typoFlag == 'yes' || statusFlag == 'pregnant';
  }

  Map<String, dynamic> _formatCardData(Map<String, dynamic> row, Map<String, dynamic> person) {
    try {
      final name = person['memberName']?.toString() ?? person['headName']?.toString() ?? '';

      final gender = person['gender']?.toString().trim().toLowerCase() ?? '';
      
      // Map gender to display format
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
      
      // Calculate age
      final age = _calculateAge(person['dob']);
      
      return {
        'hhId': row['household_ref_key']?.toString() ?? '',
        'name': name,
        'age_gender': '${age > 0 ? '$age Y' : 'N/A'} | $displayGender',
        'status': 'Pregnant',
      };
    } catch (e) {
      print('Error formatting card data: $e');
      return {
        'hhId': row['household_ref_key']?.toString() ?? '',
        'name': 'Error loading data',
        'age_gender': 'N/A | N/A',
        'status': 'ERROR',
      };
    }
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

  String _getLocalizedBadge(String badge, AppLocalizations? l10n) {
    switch (badge) {
      case 'ANC DUE':
        return l10n?.categoryANC ?? 'ANC DUE';
      case 'Pregnant':
        return l10n?.badgePregnant ?? 'Pregnant';
      default:
        return badge;
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _loadPregnantWomen();
      } else {
        _filtered = _filtered.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['name'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n!.pregnantWomenList,
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
        // Navigator.pushNamed(context, Route_Names.FamliyUpdate);
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getLocalizedBadge(data['status'] ?? '', l10n),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      data['name'] ?? 'N/A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _infoRow(
                    '',
                    data['age_gender'] ?? 'N/A | N/A',
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
}
