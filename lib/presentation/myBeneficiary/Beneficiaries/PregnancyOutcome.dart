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
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
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

          final womanName = formData['woman_name']?.toString() ?? 'Unknown';
          final husbandName = formData['husband_name']?.toString() ?? 'N/A';
          final lmpDate = formData['lmp_date']?.toString() ?? '';
          final eddDate = formData['edd_date']?.toString() ?? '';
          final weeksOfPregnancy = formData['weeks_of_pregnancy']?.toString() ?? '';
          final mobileNo = formData['mobile_no']?.toString() ?? '';

          processedData.add({
            'hhId': row['household_ref_key']?.toString() ?? '',
            'beneficiaryId': row['beneficiary_ref_key']?.toString() ?? '',
            'name': womanName,
            'husbandName': husbandName,
            'mobileNo': mobileNo,
            'lmpDate': lmpDate,
            'eddDate': eddDate,
            'weeksOfPregnancy': weeksOfPregnancy,
            'formId': row['form_id']?.toString() ?? '',
            'formData': formData,
            'age': _calculatePregnancyWeeks(lmpDate, eddDate, weeksOfPregnancy),
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

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allData;
      } else {
        _filtered = _allData.where((e) {
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobileNo'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return 'Invalid date';
      return '${_twoDigits(date.day)}-${_twoDigits(date.month)}-${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _twoDigits(int n) => n >= 10 ? '$n' : '0$n';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Pregnant Women List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by HH ID, Name or Mobile',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pregnant_woman_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No pregnancy cases found',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
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
    final hhId = data['hhId']?.toString() ?? '';
    final displayHhId = hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId;
    final name = data['name'] ?? 'N/A';
    final age = data['age'] ?? 'N/A';
    final gender = 'Female'; // Since these are pregnant women
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
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
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
                _infoRow('', '$age | $gender', isWrappable: true),
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
}
