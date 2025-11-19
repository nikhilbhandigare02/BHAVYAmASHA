import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
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
              ? _buildEmptyState(context)
              : Expanded(
            child: _filtered.isEmpty
                ? _buildNoResults()
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

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No death records found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no death records in the database.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDeathRecords,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No matching records found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
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
          age = '$years years';
        }
      } catch (e) {
        print('Error parsing DOB: $e');
      }
    } else if (beneficiaryInfo['age'] != null) {
      age = '${beneficiaryInfo['age']} years';
    }

    final gender = (beneficiaryInfo['gender'] ?? '').toString().toLowerCase() == 'm' ? 'Male' : 'Female';
    final hhId = data['household_ref_key']?.toString() ?? 'N/A';
    final mobile = beneficiaryInfo['mobileNo'] ?? beneficiaryInfo['mobile'] ?? 'N/A';
    
    // Parse death details
    final deathDate = deathDetails['date_of_death'] ?? deathDetails['deathDate'] ?? 'Not recorded';
    final causeOfDeath = deathDetails['probable_cause_of_death'] ?? deathDetails['causeOfDeath'] ?? 'Not specified';
    final deathPlace = deathDetails['death_place'] ?? deathDetails['deathPlace'] ?? 'Not specified';
    final otherCause = deathDetails['other_cause_of_death'] ?? deathDetails['otherCause'];
    final deathReason = deathDetails['reason_of_death'] ?? deathDetails['deathReason'];
    final otherReason = deathDetails['other_reason'] ?? deathDetails['otherReason'];
    final recordedDate = deathDetails['recorded_date'] ?? deathDetails['recordedDate'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.person_off, color: Colors.red),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Age: $age • $gender • HH ID: ${hhId.length > 8 ? '...${hhId.substring(hhId.length - 8)}' : hhId}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Section
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('👤 Name', name),
                _buildInfoRow('🎂 Age', age),
                _buildInfoRow('👥 Gender', gender),
                _buildInfoRow('📱 Contact', mobile),
                _buildInfoRow('🏠 Household ID', hhId),
                
                // Death Details Section
                const SizedBox(height: 12),
                const Divider(),
                Text(
                  'Death Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('📅 Date of Death', _formatDate(deathDate)),
                _buildInfoRow('💀 Cause of Death', causeOfDeath),
                if (otherCause?.isNotEmpty == true) 
                  _buildInfoRow('   ↳ Other Cause', otherCause, padding: const EdgeInsets.only(left: 16, bottom: 4)),
                _buildInfoRow('🏠 Place of Death', deathPlace),
                if (deathReason?.isNotEmpty == true)
                  _buildInfoRow('📝 Reason', deathReason),
                if (otherReason?.isNotEmpty == true)
                  _buildInfoRow('   ↳ Other Reason', otherReason, padding: const EdgeInsets.only(left: 16, bottom: 4)),
                if (recordedDate?.isNotEmpty == true)
                  _buildInfoRow('📋 Recorded On', _formatDate(recordedDate)),
                
                // Additional Details Section
                if (deathDetails.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(
                    'Additional Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...deathDetails.entries.where((entry) => ![
                    'date_of_death', 'deathDate',
                    'probable_cause_of_death', 'causeOfDeath',
                    'death_place', 'deathPlace',
                    'other_cause_of_death', 'otherCause',
                    'reason_of_death', 'deathReason',
                    'other_reason', 'otherReason',
                    'recorded_date', 'recordedDate'
                  ].contains(entry.key))
                  .map((entry) => _buildInfoRow(
                    '• ${entry.key.replaceAll('_', ' ').replaceAllMapped(
                      RegExp(r'([A-Z])'), 
                      (match) => ' ${match.group(0)}'
                    ).toUpperCase().trim()}',
                    entry.value?.toString() ?? 'N/A',
                    padding: const EdgeInsets.only(left: 8, top: 2),
                  )).toList(),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDeathDetails(context, data);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Raw Data'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
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

  Widget _buildInfoRow(String label, String value, {EdgeInsetsGeometry? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeathDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Death Record Details'),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(data),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}