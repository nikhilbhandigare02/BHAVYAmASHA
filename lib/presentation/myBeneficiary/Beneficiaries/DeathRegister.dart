import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'dart:convert';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class DeathRegister extends StatefulWidget {
  const DeathRegister({super.key});

  @override
  State<DeathRegister> createState() => _DeathRegisterState();
}

class _DeathRegisterState extends State<DeathRegister> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deathRecords = [];
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _searchCtrl.addListener(_onSearchChanged);
    _loadDeathRecords();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String> _getMemberType(String uniqueKey) async {
    try {
      final beneficiary = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
      if (beneficiary != null && beneficiary['beneficiary_info'] is Map) {
        final beneficiaryInfo = Map<String, dynamic>.from(beneficiary['beneficiary_info']);
        return beneficiaryInfo['memberType']?.toString() ?? 'Adult';
      }
    } catch (e) {
      print('Error fetching memberType for $uniqueKey: $e');
    }
    return 'Adult';
  }

  Future<void> _loadDeathRecords() async {
    try {
      print('🔍 [DeathRegister] Fetching death records...');
      final records = await LocalStorageDao.instance.getDeathRecords();
      print('✅ [DeathRegister] Fetched ${records.length} death records');

      // Debug: Print first few records
      for (var i = 0; i < (records.length < 3 ? records.length : 3); i++) {
        print('📝 Record ${i + 1}: ${records[i]}');
      }

      if (mounted) {
        setState(() {
          _deathRecords = records;
          _filtered = List<Map<String, dynamic>>.from(_deathRecords);
          _isLoading = false;
          print('🔄 [DeathRegister] State updated with ${_deathRecords.length} records');
        });
      }
    } catch (e, stackTrace) {
      print('❌ [DeathRegister] Error loading death records: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_deathRecords);
      } else {
        _filtered = _deathRecords.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['mobile']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['mohalla']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.deathRegisterTitle ?? 'Death Register',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.searchHint ?? 'Search by ID/Name/Contact',
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadDeathRecords,
                  tooltip: 'Refresh data',
                ),
              ),
            ),
          ),

          _isLoading
              ? const Expanded(child: Center(child: CircularProgressIndicator()))
              : _deathRecords.isEmpty
              ? _buildNoRecordCard(context)
              : Expanded(
            child: _filtered.isEmpty
                ? _buildNoRecordCard(context)
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

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final Color primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    // Extract data with null safety
    final beneficiaryInfo = data['beneficiary_info'] is Map ? Map<String, dynamic>.from(data['beneficiary_info']) : {};
    final deathDetails = data['death_details'] is Map ? Map<String, dynamic>.from(data['death_details']) : {};

    // Parse beneficiary info
    final name = beneficiaryInfo['memberName'] ??
        beneficiaryInfo['headName'] ??
        beneficiaryInfo['name'] ?? 'Unknown';

    // Calculate age from DOB if available
    String age = 'N/A';
    if (beneficiaryInfo['dob'] != null) {
      try {
        final dob = DateTime.tryParse(beneficiaryInfo['dob']);
        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
            years--;
          }
          age = '$years Y';
        }
      } catch (e) {
        print('Error parsing DOB: $e');
      }
    } else if (beneficiaryInfo['age'] != null) {
      age = '${beneficiaryInfo['age']} years';
    }

    final gender = (beneficiaryInfo['gender'] ?? '').toString().toLowerCase() == 'm' ? 'M' : 'F';
    final hhId = data['household_ref_key']?.toString() ?? 'N/A';
    final uniqueKey = data['unique_key']?.toString() ?? '';

    final deathDate = deathDetails['date_of_death'] ?? deathDetails['deathDate'] ?? 'Not recorded';
    final deathPlace = deathDetails['death_place'] ?? deathDetails['deathPlace'] ?? 'Not specified';

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
                      (hhId.length) > 11 ? hhId.substring(hhId.length - 11) : hhId,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // MemberType Badge
                FutureBuilder<String>(
                  future: _getMemberType(uniqueKey),
                  builder: (context, snapshot) {
                    final memberType = snapshot.data ?? 'Adult';
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        memberType,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Row: Name and Date of Death
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            _formatDate(deathDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$age | $gender',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        deathPlace ?? "N/A",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not recorded';
    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return dateString;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

}
