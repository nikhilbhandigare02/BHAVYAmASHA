import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class HBNCListBeneficiaries extends StatefulWidget {
  const HBNCListBeneficiaries({super.key});

  @override
  State<HBNCListBeneficiaries> createState() => _HBNCListBeneficiariesState();
}

class _HBNCListBeneficiariesState extends State<HBNCListBeneficiaries> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPregnancyOutcomeeCouples();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {

  }
 
  Future<List<Map<String, dynamic>>> _getDeliveryOutcomeData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey = '4r7twnycml3ej1vg';
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final validBeneficiaries = await db.rawQuery('''
      SELECT DISTINCT mca.beneficiary_ref_key 
      FROM mother_care_activities mca
      WHERE mca.mother_care_state ='pnc_mother'
      AND mca.is_deleted = 0
      AND mca.current_user_key = ?
    ''', [ashaUniqueKey]);

      if (validBeneficiaries.isEmpty) {
        print('No beneficiaries found with pnc_mother or hbnc_visit state');
        return [];
      }

      final beneficiaryKeys = validBeneficiaries.map((e) => e['beneficiary_ref_key']).toList();
      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');

      final query = '''
      SELECT * FROM followup_form_data 
      WHERE forms_ref_key = ? 
      AND current_user_key = ?
      AND beneficiary_ref_key IN ($placeholders)
      AND (is_deleted IS NULL OR is_deleted = 0)
      ORDER BY created_date_time DESC
    ''';

      final results = await db.rawQuery(
        query,
        [deliveryOutcomeKey, ashaUniqueKey, ...beneficiaryKeys],
      );

      print('Fetched ${results.length} delivery outcome records with valid mother care states');
      return results;
    } catch (e) {
      print('Error fetching delivery outcome data: $e');
      return [];
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;
      
      if (now.day < birthDate.day) {
        months--;
      }
      if (months < 0) {
        years--;
        months += 12;
      }
      
      if (years > 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$months ${months == 1 ? 'month' : 'months'}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _loadPregnancyOutcomeeCouples() async {
    setState(() => _isLoading = true);
    _filtered = [];
    final Set<String> processedBeneficiaries = <String>{};

    try {
      final dbOutcomes = await _getDeliveryOutcomeData();

      if (dbOutcomes.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final List<Map<String, dynamic>> formattedData = [];

      for (final outcome in dbOutcomes) {
        try {
          final formJson = jsonDecode(outcome['form_json'] as String);
          final formData = formJson['form_data'] ?? {};
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) continue;

          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }
          processedBeneficiaries.add(beneficiaryRefKey);

          final db = await DatabaseProvider.instance.database;
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiaryResults.isEmpty) continue;

          final beneficiary = beneficiaryResults.first;
          final beneficiaryInfoRaw = beneficiary['beneficiary_info'] as String? ?? '{}';
          
          Map<String, dynamic> beneficiaryInfo;
          try {
            beneficiaryInfo = jsonDecode(beneficiaryInfoRaw);
          } catch (e) {
            continue;
          }

          final name = beneficiaryInfo['memberName']?.toString() ??
              beneficiaryInfo['headName']?.toString() ?? 'N/A';
          final dob = beneficiaryInfo['dob']?.toString();
          final age = _calculateAge(dob);
          final gender = beneficiaryInfo['gender']?.toString() ?? 'N/A';
          final hhId = beneficiary['household_ref_key']?.toString() ?? 'N/A';
          
          final displayHhId = hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId;
          formattedData.add({
            'hhId': displayHhId,
            'name': name,
            'age | gender': '$age | $gender',
            'status': 'PNC',
            'beneficiaryRefKey': beneficiaryRefKey,
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      setState(() {
        _filtered = formattedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadPregnancyOutcomeeCouples: $e');
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); 

    return Scaffold(
      appBar: AppHeader(
        screenTitle:l10n!.hbcnList,
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
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
                        data['hhId'] ?? '',
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
                      color: Colors.green.withOpacity(0.15), // ✅ Background color
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n?.badgePNC ?? 'PNC',
                      style: const TextStyle(
                        color: Colors.green, // ✅ Text color
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                ],
              ),
            ),

            // 🔸 Body
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
                  _infoRow(data['name']),
                  const SizedBox(height: 8),
                  _infoRow(
                    data['age | gender'] ?? '',
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

  Widget _infoRow(String value,{bool isWrappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
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
