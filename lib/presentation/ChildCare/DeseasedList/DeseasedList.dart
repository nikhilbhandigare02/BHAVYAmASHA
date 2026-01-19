import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/beneficiaries_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class DeseasedList extends StatefulWidget {
  const DeseasedList({super.key});

  @override
  State<DeseasedList> createState() => _DeseasedListState();
}

class _DeseasedListState extends State<DeseasedList> {
  final TextEditingController _searchCtrl = TextEditingController();
  final LocalStorageDao _storageDao = LocalStorageDao();

  bool _isLoading = true;
  List<Map<String, dynamic>> _deceasedList = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDeceasedList();
  }

  Future<void> _loadDeceasedList() async {
    final t = AppLocalizations.of(context);
    try {
      setState(() {
        _isLoading = true;
      });

      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> deceasedBeneficiaries =
      await db.rawQuery(
        '''
  SELECT DISTINCT b.*,
         h.household_info AS household_data,
         h.created_date_time AS household_created_date,
         h.household_info AS hh_info
  FROM ${BeneficiariesTable.table} b
  LEFT JOIN (
      SELECT cca.beneficiary_ref_key, MAX(cca.created_date_time) AS latest_activity
      FROM child_care_activities cca
      WHERE cca.child_care_state IN ('registration_due', 'tracking_due')
        AND cca.is_deleted = 0
      GROUP BY cca.beneficiary_ref_key
  ) cca_max ON b.unique_key = cca_max.beneficiary_ref_key
  LEFT JOIN households h 
    ON b.household_ref_key = h.unique_key
  WHERE b.is_death = 1
    AND b.is_deleted = 0
    AND b.is_migrated = 0
    AND b.is_adult = 0
    ${ashaUniqueKey != null && ashaUniqueKey.isNotEmpty ? 'AND b.current_user_key = ?' : ''}
  ORDER BY b.created_date_time DESC
  ''',
        ashaUniqueKey != null && ashaUniqueKey.isNotEmpty
            ? [ashaUniqueKey]
            : [],
      );


      final transformed = deceasedBeneficiaries.map((beneficiary) {
        final beneficiaryInfo =
        jsonDecode(beneficiary['beneficiary_info']?.toString() ?? '{}');
        final householdData =
        jsonDecode(beneficiary['hh_info']?.toString() ?? '{}');
        final deathDetails =
        jsonDecode(beneficiary['death_details']?.toString() ?? '{}');

        String getValue(dynamic value, [String? defaultValue]) {
          if (value == null ||
              (value is String && value.trim().isEmpty) ||
              value == 'null') {
            return defaultValue ?? t?.na ?? 'N/A';
          }
          return value.toString();
        }

        String formatDate(dynamic dateValue, [String defaultValue = 'N/A']) {
          if (dateValue == null) return defaultValue;
          try {
            final date = DateTime.parse(dateValue.toString());
            return '${date.day.toString().padLeft(2, '0')}-'
                '${date.month.toString().padLeft(2, '0')}-'
                '${date.year}';
          } catch (_) {
            return defaultValue;
          }
        }

        String getAge() {
          if (beneficiaryInfo['years'] != null) {
            return getValue(beneficiaryInfo['years']);
          } else if (beneficiaryInfo['months'] != null) {
            return getValue(beneficiaryInfo['months']);
          } else if (beneficiaryInfo['days'] != null) {
            return getValue(beneficiaryInfo['days']);
          }

          if (beneficiaryInfo['dob'] != null) {
            try {
              final dob = DateTime.parse(beneficiaryInfo['dob']);

              // Parse date of death for age calculation
              DateTime? deathDate;
              String deathDateStr = (deathDetails['date_of_death'] ?? '').toString();

              if (deathDateStr.isNotEmpty && deathDateStr != 'null') {
                try {
                  deathDate = DateTime.parse(deathDateStr);
                } catch (_) {
                  // Try parsing as timestamp
                  final timestamp = int.tryParse(deathDateStr);
                  if (timestamp != null && timestamp > 0) {
                    deathDate = DateTime.fromMillisecondsSinceEpoch(
                      timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                      isUtc: true,
                    );
                  }
                }
              }

              // If death date not found, try modified_date_time from beneficiary record
              if (deathDate == null && beneficiary['modified_date_time'] != null) {
                final modifiedDateStr = beneficiary['modified_date_time'].toString();
                print('🔍 Debug: DeseasedList modified_date_time = $modifiedDateStr');
                try {
                  if (modifiedDateStr.isNotEmpty) {
                    deathDate = DateTime.parse(modifiedDateStr);
                    print('✅ Debug: DeseasedList successfully parsed modified_date_time: $deathDate');
                  }
                } catch (_) {
                  print('❌ Debug: DeseasedList failed to parse as string, trying timestamp...');
                  // Try parsing as timestamp
                  final timestamp = int.tryParse(modifiedDateStr);
                  if (timestamp != null && timestamp > 0) {
                    deathDate = DateTime.fromMillisecondsSinceEpoch(
                      timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                      isUtc: true,
                    );
                    print('✅ Debug: DeseasedList successfully parsed as timestamp: $deathDate');
                  }
                }
              }

              // Use death date for calculation, fallback to current date if death date not available
              final referenceDate = deathDate ?? DateTime.now();

              int age = referenceDate.year - dob.year;
              if (referenceDate.month < dob.month ||
                  (referenceDate.month == dob.month && referenceDate.day < dob.day)) {
                age--;
              }
              return age > 0 ? age.toString() : 'N/A';
            } catch (_) {}
          }
          return 'N/A';
        }

        final registrationDate =
            beneficiary['household_created_date'] ??
                beneficiary['created_date_time'];

        return {
          'hhId': getValue(
              householdData['household_id'] ??
                  beneficiary['household_ref_key']),
          'RegitrationDate': formatDate(registrationDate),
          'RegitrationType': getValue(
              beneficiaryInfo['beneficiaryType'] ??
                  (beneficiary['is_adult'] == 1 ? 'Adult' : 'Child')),
          'BeneficiaryID': getValue(beneficiary['unique_key']),
          'RchID': getValue(beneficiaryInfo['rch_id'], t?.na),
          'Name': getValue(
              beneficiaryInfo['name'] ??
                  beneficiaryInfo['headName'] ??
                  beneficiaryInfo['child_name']),
          'Age|Gender':
          '${getAge()} | ${getValue(beneficiaryInfo['gender'])}',
          'Mobileno.': getValue(
              beneficiaryInfo['mobileNo'] ??
                  householdData['mobile_number']),
          'FatherName': getValue(
              beneficiaryInfo['fatherName'] ??
                  beneficiaryInfo['father_name']),
          'MotherName': getValue(
              beneficiaryInfo['motherName'] ??
                  beneficiaryInfo['mother_name']),
          'causeOFDeath': getValue(
            deathDetails['cause_of_death'] ??
                deathDetails['probable_cause_of_death'],
          ),
          'reason': getValue(
              deathDetails['reason_of_death']),
          'place': getValue(
              deathDetails['death_place']),
          'DateofDeath': formatDate(
              deathDetails['date_of_death']),
          'age': getAge(),
          'gender': getValue(beneficiaryInfo['gender']),
          'is_synced': beneficiary['is_synced'],
        };
      }).toList();

      setState(() {
        _deceasedList = transformed;
        _filtered = List<Map<String, dynamic>>.from(_deceasedList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load deceased list: $e')),
      );
    }
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
        _filtered = List<Map<String, dynamic>>.from(_deceasedList);
      } else {
        _filtered = _deceasedList.where((e) {
          return (e['hhId']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['Name']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['Mobileno.']?.toString() ?? '').toLowerCase().contains(q) ||
              (e['BeneficiaryID']?.toString() ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n!.child_deseased_list,
        showBack: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        // Search Box (always visible)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: t!.child_deseased_search,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
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
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _deceasedList.isEmpty
                            ? t.noDeceasedChildrenFound
                            : t.noDeceasedChildrenFound,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final data = _filtered[index];
                      return _deceasedCard(context, data);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _deceasedCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
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
                    const Icon(Icons.home, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (data['hhId'] != null && data['hhId'].toString().length > 11)
                            ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                            : (data['hhId']?.toString() ?? ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Image.asset(
                      'assets/images/sync.png',
                      width: 25,
                      color: (data['is_synced'] ?? 0) == 1
                          ? null
                          : Colors.grey[500],
                    ),

                  ],
                ),
              ),

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
                      _rowText(l10n!.registrationDate, data['RegitrationDate'] ?? l10n.na),
                      _rowText(l10n.registrationTypeLabel, 'Child' ?? l10n.na),
                      _rowText(l10n.beneficiaryId,
                          (data['BeneficiaryID']?.toString().length ?? 0) > 11
                              ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11)
                              : (data['BeneficiaryID']?.toString() ?? l10n.na)
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(l10n.nameLabel, data['Name'] ?? l10n.na),
                      _rowText(l10n.ageGenderLabel, data['Age|Gender'] ?? l10n.na),
                      _rowText(l10n.rchIdLabel, data['RchID'] ?? l10n.na),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(l10n.fatherName, data['FatherName'] ?? l10n.na),
                      _rowText(l10n.mobileNo, data['Mobileno.'] ?? l10n.na),
                      _rowText(l10n.dateOfDeathLabel, data['DateofDeath'] ?? l10n.na),
                    ]),
                    const SizedBox(height: 8),
                    _buildRow([
                      _rowText(l10n.causeOfDeathLabel, data['causeOFDeath'] ?? l10n.na),
                      _rowText(l10n.reasonOfDeath, data['reason'] ?? l10n.na),
                      _rowText(l10n.placeLabel, data['place'] ?? l10n.na),
                    ]),
                  ],
                ),
              ),
            ],
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

  void _viewDetails(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deceasedChildDetails ?? 'Deceased Child Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Name', item['Name']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('HH ID', item['hhId']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Beneficiary ID', item['BeneficiaryID']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Age | Gender', item['Age|Gender']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Mobile', item['Mobileno.']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Father\'s Name', item['FatherName']?.toString() ?? l10n!.na),
              const SizedBox(height: 16),
              Text(
                l10n?.deathDetailsLabel ?? 'Death Details',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              const SizedBox(height: 8),
              _detailRow('Date of Death', item['DateofDeath']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Cause of Death', item['causeOFDeath']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Place of Death', item['place']?.toString() ?? l10n!.na),
              const SizedBox(height: 8),
              _detailRow('Reason', item['reason']?.toString() ?? l10n!.na),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.closeLabel ?? 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ],
    );
  }


}