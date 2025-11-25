import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/Database/tables/beneficiaries_table.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../OutcomeForm/OutcomeForm.dart';

class DeliveryOutcomeScreen extends StatefulWidget {
  const DeliveryOutcomeScreen({super.key});

  @override
  State<DeliveryOutcomeScreen> createState() =>
      _DeliveryOutcomeScreenState();
}

class _DeliveryOutcomeScreenState
    extends State<DeliveryOutcomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allData = []; // Store all loaded data
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

  Future<void> _loadPregnancyOutcomeeCouples() async {
    setState(() { _isLoading = true; });

    try {
      final db = await DatabaseProvider.instance.database;

      // Directly use the key from the table file
      const ancRefKey = 'bt7gs9rl1a5d26mz'; // From followup_form_data_table.dart

      print('🔍 Using forms_ref_key: $ancRefKey for ANC forms');

      final ancForms = await db.rawQuery('''
        SELECT 
          f.beneficiary_ref_key,
          f.form_json,
          f.household_ref_key,
          f.forms_ref_key,
          f.created_date_time,
          f.id as form_id
        FROM ${FollowupFormDataTable.table} f
        WHERE 
          f.forms_ref_key = '$ancRefKey'
          AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
          AND f.is_deleted = 0
        ORDER BY f.created_date_time DESC
      ''');

      print('🔍 Found ${ancForms.length} ANC forms with gives_birth_to_baby: Yes');

      if (ancForms.isEmpty) {
        print('ℹ️ No ANC forms found with gives_birth_to_baby: Yes');
        setState(() {
          _isLoading = false;
          _allData = [];
          _filtered = [];
        });
        return;
      }

      // Process each form
      final List<Map<String, dynamic>> processedData = [];

      // In _loadPregnancyOutcomeeCouples method, update the form processing loop:

      for (final form in ancForms) {
        try {
          // Get beneficiary details
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            print('⚠️ Form missing beneficiary_ref_key: $form');
            continue;
          }

          Map<String, dynamic>? beneficiaryRow;
          try {
            // First try to get from beneficiaries_new table
            beneficiaryRow = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(beneficiaryRefKey);

            // If not found, try the old beneficiaries table (without _new suffix)
            if (beneficiaryRow == null) {
              print('ℹ️ Beneficiary not found in beneficiaries_new, trying beneficiaries table');
              final db = await DatabaseProvider.instance.database;
              final results = await db.query(
                'beneficiaries_new',
                where: 'unique_key = ? AND is_deleted = 0',
                whereArgs: [beneficiaryRefKey],
                limit: 1,
              );

              if (results.isNotEmpty) {
                beneficiaryRow = Map<String, dynamic>.from(results.first);
                // Parse the JSON fields
                beneficiaryRow['beneficiary_info'] = jsonDecode(beneficiaryRow['beneficiary_info'] ?? '{}');
                beneficiaryRow['geo_location'] = jsonDecode(beneficiaryRow['geo_location'] ?? '{}');
                beneficiaryRow['death_details'] = jsonDecode(beneficiaryRow['death_details'] ?? '{}');
              }
            }

            if (beneficiaryRow != null) {
              print('✅ Found beneficiary data: ${beneficiaryRow['beneficiary_info']}');
            } else {
              print('⚠️ Could not find beneficiary with unique_key=$beneficiaryRefKey in any table');
            }
          } catch (e) {
            print('⚠️ Error fetching beneficiary by unique_key=$beneficiaryRefKey: $e');
          }

          final formattedData = _formatCoupleData(
            form,
            {},
            {},
            isHead: true,
            beneficiaryRow: beneficiaryRow,
          );
          processedData.add(formattedData);

        } catch (e) {
          print('❌ Error processing form: $e');
          print('Form data: $form');
        }
      }

      print('✅ Processed ${processedData.length} out of ${ancForms.length} forms');

      // Set the data ONCE at the end
      setState(() {
        _allData = processedData;
        _filtered = processedData;
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error loading pregnancy outcome couples: $e');
      setState(() {
        _isLoading = false;
        _allData = [];
        _filtered = [];
      });
    }
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;

    // Check if this is a form with gives_birth_to_baby = 'Yes'
    if (person['gives_birth_to_baby']?.toString().toLowerCase() == 'yes') {
      return true;
    }

    // Original eligibility checks
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final gender = genderRaw == 'f' || genderRaw == 'female';
    final maritalStatus = maritalStatusRaw == 'married';
    final dob = person['dob'];
    final age = _calculateAge(dob);

    return gender && maritalStatus && age >= 15 && age <= 49;
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead, Map<String, dynamic>? beneficiaryRow}) {
    try {
      print('🔄 Formatting couple data for row: $row');

      // Parse form JSON to get the actual form data
      final formJson = row['form_json'] is String
          ? jsonDecode(row['form_json'] as String)
          : (row['form_json'] ?? {}) as Map<String, dynamic>;

      final formData = (formJson['form_data'] ?? formJson) as Map<String, dynamic>;
      print('📋 Form data: $formData');

      // Extract all required fields with proper fallbacks
      final womanName = (formData['woman_name'] ?? formData['name'] ?? 'Unknown').toString();
      final husbandName = (formData['husband_name'] ?? formData['spouse_name'] ?? 'N/A').toString();
      final rchNumber = (formData['rch_number'] ?? '').toString();
      final lmpDate = (formData['lmp_date'] ?? '').toString();
      final eddDate = (formData['edd_date'] ?? '').toString();
      final weeksOfPregnancy = (formData['weeks_of_pregnancy'] ?? '').toString();
      final createdAt = (formData['created_at'] ?? row['created_date_time'] ?? '').toString();
      final mobileNo = (formData['mobile_no'] ?? formData['phone'] ?? '').toString();
      final houseNumber = (formData['house_number'] ?? '').toString();

      // Get household and beneficiary info
      final hhRefKey = (formData['household_ref_key'] ?? row['household_ref_key'] ?? '').toString();
      final beneficiaryRefKey = (formData['beneficiary_ref_key'] ?? row['beneficiary_ref_key'] ?? '').toString();

      // Keep full household ID for data passing, will be truncated for display only
      final hhId = hhRefKey;

      // Calculate pregnancy weeks display from EDD/LMP
      int age = 0;
      String displayAge = '';

      if (eddDate.isNotEmpty) {
        final edd = DateTime.tryParse(eddDate);
        if (edd != null) {
          age = (DateTime.now().difference(edd).inDays / 7).round();
          displayAge = '$weeksOfPregnancy weeks (EDD: ${_formatDate(eddDate)})';
        }
      } else if (lmpDate.isNotEmpty) {
        final lmp = DateTime.tryParse(lmpDate);
        if (lmp != null) {
          age = (DateTime.now().difference(lmp).inDays / 7).round();
          displayAge = '$weeksOfPregnancy weeks (LMP: ${_formatDate(lmpDate)})';
        }
      }

      if (displayAge.isEmpty && weeksOfPregnancy.isNotEmpty) {
        displayAge = '$weeksOfPregnancy weeks';
      }

      String registrationDateDisplay = _formatDate(createdAt);
      String mobileFromBeneficiary = mobileNo;
      String gender = '';
      String ageYearsDisplay = '';

      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final createdDt = beneficiaryRow['created_date_time']?.toString() ?? '';
          if (createdDt.isNotEmpty) {
            registrationDateDisplay = _formatDate(createdDt);
          }

          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : <String, dynamic>{};

          final dob = info['dob']?.toString();
          final ageYears = _calculateAge(dob);
          ageYearsDisplay = ageYears.toString();

          gender = (info['gender']?.toString() ?? '').trim();
          if (gender.isNotEmpty) {
            final g = gender.toLowerCase();
            gender = g.startsWith('f') ? 'F' : (g.startsWith('m') ? 'M' : gender);
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

      final formattedData = {
        'hhId': hhId.isNotEmpty ? hhId : 'N/A',
        'household_id': hhRefKey,
        'RegistrationDate': registrationDateDisplay.isNotEmpty ? registrationDateDisplay : 'N/A',
        'BeneficiaryID': beneficiaryRefKey,
        'Name': womanName,
        'ageGender': ageGenderCombined,
        'RichID': rchNumber.isNotEmpty ? rchNumber : 'N/A',
        'mobileno': mobileFromBeneficiary.isNotEmpty ? mobileFromBeneficiary : 'N/A',
        'HusbandName': husbandName,
        'weeksOfPregnancy': weeksOfPregnancy.isNotEmpty ? weeksOfPregnancy : 'N/A',
        'eddDate': _formatDate(eddDate).isNotEmpty ? _formatDate(eddDate) : 'N/A',
        'lmpDate': _formatDate(lmpDate).isNotEmpty ? _formatDate(lmpDate) : 'N/A',
        'houseNumber': houseNumber.isNotEmpty ? houseNumber : 'N/A',
        '_rawRow': row,
      };

      print('✅ Formatted data for $womanName:');
      print('   - Household ID: ${formattedData['hhId']}');
      print('   - Registration Date: ${formattedData['RegistrationDate']}');
      print('   - Beneficiary ID: $beneficiaryRefKey');
      print('   - Name: $womanName');
      print('   - Mobile: ${formattedData['mobileno']}');

      return formattedData;
    } catch (e) {
      print('❌ Error formatting couple data: $e');
      return {
        'hhId': 'N/A',
        'RegistrationDate': 'N/A',
        'RegistrationType': 'Error',
        'BeneficiaryID': '',
        'Name': 'Error loading data',
        'age': 'N/A',
        'RichID': 'N/A',
        'mobileno': 'N/A',
        'HusbandName': 'N/A',
        'weeksOfPregnancy': 'N/A',
        'eddDate': 'N/A',
        'lmpDate': 'N/A',
        '_rawRow': row,
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == 'null') return '';
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
        // Don't reload, just show all data
        _filtered = _allData;
      } else {
        _filtered = _allData.where((e) {
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
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.pregnancyOutcome ?? '',
        showBack: false,
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
                hintText: l10n?.searchDelOutcome?? 'search Eligible Couple',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
              child: Text(
                'No pregnancy outcomes found',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey,
                ),
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

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    // Extract the data directly from the formatted data
    final hhId = data['hhId']?.toString() ?? 'N/A';
    final registrationDate = data['RegistrationDate']?.toString() ?? 'N/A';
    final registrationType = data['RegistrationType']?.toString() ?? 'General';
    final beneficiaryId = data['BeneficiaryID']?.toString() ?? 'N/A';
    final name = data['Name']?.toString() ?? 'N/A';
    final ageGender = data['ageGender']?.toString() ?? 'N/A';
    final richId = data['RichID']?.toString() ?? 'N/A';
    final mobileNo = data['mobileno']?.toString() ?? 'N/A';
    final husbandName = data['HusbandName']?.toString() ?? 'N/A';
    final weeksOfPregnancy = data['weeksOfPregnancy']?.toString() ?? 'N/A';
    final eddDate = data['eddDate']?.toString() ?? 'N/A';
    final displayHhId = (hhId.length > 11) ? hhId.substring(hhId.length - 11) : hhId;


    print('🔄 Rendering card for: $name');
    print('   - HH ID: $hhId, Reg Date: $registrationDate');
    print('   - Mobile: $mobileNo, RCH: $richId');

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () {
            final beneficiaryData = <String, dynamic>{};

            print('📋 Raw data: $data');

            // First try to get from _rawRow
            if (data['_rawRow'] is Map) {
              final rawRow = data['_rawRow'] as Map;
              final beneficiaryRefKey = rawRow['beneficiary_ref_key']?.toString() ?? '';

              beneficiaryData['unique_key'] = beneficiaryRefKey;
              beneficiaryData['BeneficiaryID'] = beneficiaryRefKey;

              print('🔑 Passing to form:');
              print('   - unique_key: ${beneficiaryData['household_id']}');
              print('   - BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }
            // Fallback to data['BeneficiaryID'] if _rawRow is not available
            else if (data['BeneficiaryID'] != null) {
              beneficiaryData['BeneficiaryID'] = data['BeneficiaryID'].toString();
              print('🔍 Using direct BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }

            if ((beneficiaryData['BeneficiaryID'] as String?)?.isEmpty ?? true) {
              print('❌ No BeneficiaryID could be determined!');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Missing beneficiary information')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutcomeFormPage(
                  beneficiaryData: {
                    ...beneficiaryData,
                    'householdId': data['household_id'] ?? data['_rawRow']?['household_ref_key'] ?? '',
                    'beneficiaryId': beneficiaryId,
                  },
                ),
              ),
            );
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
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$displayHhId',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        height: 24,
                        child: Image.asset('assets/images/sync.png'),
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
                          Expanded(child: _rowText('Registration Date', registrationDate)),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Beneficiary ID', beneficiaryId)),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('RCH ID', richId)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _rowText('Name', name)),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Age | Gender', ageGender)),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Mobile No.', mobileNo)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _rowText('Husband Name', husbandName)),
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

    final displayValue = (title == 'Beneficiary ID' && value.length > 11) 
        ? '${value.substring(value.length - 11)}'
        : value;
        
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
          displayValue,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

}