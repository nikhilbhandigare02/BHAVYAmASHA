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
import '../../../data/Database/tables/mother_care_activities_table.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../../../data/Database/local_storage_dao.dart';
import '../OutcomeForm/OutcomeForm.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';

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
  bool _isLoading = false;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _loadPregnancyOutcomeeCouples();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh every time this screen becomes active
    if (_lastRefresh == null || DateTime.now().difference(_lastRefresh!).inMilliseconds > 300) {
      _loadPregnancyOutcomeeCouples();
    }
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

      const ancRefKey = 'bt7gs9rl1a5d26mz';

      print('🔍 Using forms_ref_key: $ancRefKey for ANC forms');

      final ancForms = await db.rawQuery('''
        WITH LatestForms AS (
          SELECT
            f.beneficiary_ref_key,
            f.form_json,
            f.household_ref_key,
            f.forms_ref_key,
            f.created_date_time,
            f.id as form_id,
            ROW_NUMBER() OVER (
              PARTITION BY f.beneficiary_ref_key
              ORDER BY f.created_date_time DESC, f.id DESC
            ) as rn
          FROM ${FollowupFormDataTable.table} f
          WHERE
            f.forms_ref_key = '$ancRefKey'
            AND f.is_deleted = 0
            AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
        )
        SELECT * FROM LatestForms WHERE rn = 1
       
        UNION
       
        -- Also include any records with mother_care_state = 'delivery_outcome' that might not be in the forms
        SELECT
          mca.beneficiary_ref_key,
          '{}' as form_json,
          mca.household_ref_key,
          '' as forms_ref_key,
          mca.created_date_time,
          mca.id as form_id,
          1 as rn
        FROM ${MotherCareActivitiesTable.table} mca
        WHERE
          mca.mother_care_state = 'delivery_outcome'
          AND mca.is_deleted = 0
          AND mca.beneficiary_ref_key NOT IN (
            SELECT beneficiary_ref_key
            FROM ${FollowupFormDataTable.table}
            WHERE forms_ref_key = '$ancRefKey'
            AND is_deleted = 0
            AND form_json LIKE '%"gives_birth_to_baby":"Yes"%'
          )
        ORDER BY created_date_time DESC
      ''');

      print('🔍 Found ${ancForms.length} ANC forms with gives_birth_to_baby: Yes');


      print('🔍 Found ${ancForms.length} ANC forms with gives_birth_to_baby: Yes');

// For each form, fetch and print the beneficiary details
      for (var form in ancForms) {
        final beneficiaryRefKey = form['beneficiary_ref_key'] as String?;
        if (beneficiaryRefKey == null) {
          print('⚠️ Form missing beneficiary_ref_key: $form');
          continue;
        }

        print('\n📋 Processing ANC Form for beneficiary: $beneficiaryRefKey');

        try {
          // Fetch the beneficiary record
          final db = await DatabaseProvider.instance.database;
          final beneficiary = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiary.isNotEmpty) {
            final beneficiaryData = beneficiary.first;
            print('👤 Beneficiary Record:');
            print('   - Unique Key: ${beneficiaryData['unique_key']}');
            print('   - Household Ref Key: ${beneficiaryData['household_ref_key']}');

            final beneficiaryInfo = beneficiaryData['beneficiary_info'];
            if (beneficiaryInfo != null) {
              try {

                final infoJson = beneficiaryInfo is String ? beneficiaryInfo : jsonEncode(beneficiaryInfo);
                final info = jsonDecode(infoJson) as Map<String, dynamic>;

                print('   - Beneficiary Info:');
                info.forEach((key, value) {
                  print('     - $key: $value');
                });
              } catch (e) {
                print('   - Error parsing beneficiary_info: $e');
                print('   - Raw beneficiary_info type: ${beneficiaryInfo.runtimeType}');
                print('   - Raw beneficiary_info value: $beneficiaryInfo');
              }
            } else {
              print('   - No beneficiary_info available');
            }
          } else {
            print('❌ No beneficiary found for ref key: $beneficiaryRefKey');
          }
        } catch (e) {
          print('❌ Error fetching beneficiary: $e');
        }
      }



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



      for (final form in ancForms) {
        try {
          // Get beneficiary details
          final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            print('⚠️ Form missing beneficiary_ref_key: $form');
            continue;
          }

          final deliveryOutcomeKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.deliveryOutcome];
          final existingOutcome = await db.query(
            FollowupFormDataTable.table,
            where: 'forms_ref_key = ? AND beneficiary_ref_key = ? AND is_deleted = 0',
            whereArgs: [deliveryOutcomeKey, beneficiaryRefKey],
            limit: 1,
          );
          if (existingOutcome.isNotEmpty) {
            continue;
          }

          Map<String, dynamic>? beneficiaryRow;
          try {

            beneficiaryRow = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(beneficiaryRefKey);


            if (beneficiaryRow == null) {
              print('ℹ️ Beneficiary not found in beneficiaries_new, trying beneficiaries table');
              final db = await DatabaseProvider.instance.database;
              final results = await db.query(
                'beneficiaries_new',
                where: 'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
                whereArgs: [beneficiaryRefKey],
                limit: 1,
              );

              if (results.isNotEmpty) {
                final legacy = Map<String, dynamic>.from(results.first);
                Map<String, dynamic> info = {};
                try {
                  final form = legacy['form_json'];
                  if (form is String && form.isNotEmpty) {
                    final decoded = jsonDecode(form);
                    if (decoded is Map) {
                      info = Map<String, dynamic>.from(decoded);
                    }
                  }
                } catch (_) {}

                if (!info.containsKey('dob') && info['date_of_birth'] != null) {
                  info['dob'] = info['date_of_birth'];
                }
                if (!info.containsKey('mobileNo') && info['mobile_no'] != null) {
                  info['mobileNo'] = info['mobile_no'];
                }

                beneficiaryRow = {
                  ...legacy,
                  'beneficiary_info': info,
                  'geo_location': {},
                  'death_details': {},
                };
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

  // Add this new method to check sync status
  Future<bool> _isSynced(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final result = await db.query(
        'mother_care_activities',
        where: 'beneficiary_ref_key = ? AND mother_care_state = ? ',
        whereArgs: [beneficiaryRefKey, 'delivery_outcome'],
        orderBy: 'created_date_time DESC',
        // limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['is_synced'] == 1;
      }
      return false;
    } catch (e) {
      print('Error checking sync status: $e');
      return false;
    }
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;


    if (person['gives_birth_to_baby']?.toString().toLowerCase() == 'yes') {
      return true;
    }

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

      // First try to get name from beneficiary info if available
      String womanName = 'Unknown';
      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : (beneficiaryRow['beneficiary_info'] is String
              ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
              : <String, dynamic>{});

          womanName = (info['headName'] ?? info['name'] ?? info['woman_name'] ?? 'Unknown').toString();
        } catch (e) {
          print('⚠️ Error parsing beneficiary_info: $e');
        }
      }

      // Fallback to form data if name not found in beneficiary info
      if (womanName == 'Unknown') {
        womanName = (formData['woman_name'] ?? formData['name'] ?? formData['memberName'] ?? formData['headName'] ?? 'Unknown').toString();
      }

      // Try to get husband name from beneficiary info first
      String husbandName = 'N/A';
      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : (beneficiaryRow['beneficiary_info'] is String
              ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
              : <String, dynamic>{});

          husbandName = (info['spouseName'] ?? info['spouse_name'] ?? info['husbandName'] ?? info['husband_name'] ?? 'N/A').toString();
        } catch (e) {
          print('⚠️ Error parsing beneficiary_info for spouse name: $e');
        }
      }

      // Fallback to form data if not found in beneficiary info
      if (husbandName == 'N/A') {
        husbandName = (formData['husband_name'] ?? formData['spouse_name'] ?? formData['spouseName'] ?? formData['husbandName'] ?? 'N/A').toString();
      }
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
          int ageYears = _calculateAge(dob);

          if (ageYears == 0) {
            final updateYearStr = info['updateYear']?.toString() ?? '';
            final approxAgeStr = info['approxAge']?.toString() ?? '';
            final parsedUpdateYear = int.tryParse(updateYearStr);
            if (parsedUpdateYear != null && parsedUpdateYear > 0) {
              ageYears = parsedUpdateYear;
            } else if (approxAgeStr.isNotEmpty) {
              final matches = RegExp(r"\d+").allMatches(approxAgeStr).toList();
              if (matches.isNotEmpty) {
                ageYears = int.tryParse(matches.first.group(0) ?? '') ?? 0;
              }
            }
          }
          ageYearsDisplay = ageYears > 0 ? ageYears.toString() : '';

          gender = 'F';

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
      print('❌ Error formatting   couple data: $e');
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
        screenTitle: 'Delivery Outcome List',
        showBack: true,



      ),

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


            if (data['_rawRow'] is Map) {
              final rawRow = data['_rawRow'] as Map;
              final beneficiaryRefKey = rawRow['beneficiary_ref_key']?.toString() ?? '';

              beneficiaryData['unique_key'] = beneficiaryRefKey;
              beneficiaryData['BeneficiaryID'] = beneficiaryRefKey;

              print('🔑 Passing to form:');
              print('   - unique_key: ${beneficiaryData['household_id']}');
              print('   - BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }

            else if (data['BeneficiaryID'] != null) {
              beneficiaryData['BeneficiaryID'] = data['BeneficiaryID'].toString();
              print('🔍 Using direct BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }

            if ((beneficiaryData['BeneficiaryID'] as String?)?.isEmpty ?? true) {
              print('❌ No BeneficiaryID could be determined!');
              showAppSnackBar(context, 'Error: Missing beneficiary information');
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutcomeFormPage(
                  beneficiaryData: {
                    ...beneficiaryData,
                    'householdId': data['household_id'] ?? data['_rawRow']?['household_ref_key'] ?? '',
                    'beneficiaryId': beneficiaryData['BeneficiaryID'],
                  },
                ),
              ),
            ).then((_) {
              _loadPregnancyOutcomeeCouples();
            });
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
                      FutureBuilder<bool>(
                        future: _isSynced(beneficiaryId),
                        builder: (context, snapshot) {
                          final isSynced = snapshot.data ?? false;
                          return SizedBox(
                            width: 60,
                            height: 24,
                            child: Image.asset(
                              'assets/images/sync.png',
                              color: isSynced ? null : Colors.grey[500],
                            ),
                          );
                        },
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
                          Expanded(
                            child: FutureBuilder<String>(
                              future: () async {
                                try {
                                  final db = await DatabaseProvider.instance.database;
                                  final beneficiaryKey = (data['_rawRow']?['beneficiary_ref_key']?.toString() ?? data['BeneficiaryID']?.toString() ?? '').trim();
                                  if (beneficiaryKey.isEmpty) return ageGender;
                                  final rows = await db.query(
                                    BeneficiariesTable.table,
                                    where: 'unique_key = ?',
                                    whereArgs: [beneficiaryKey],
                                    limit: 1,
                                  );
                                  if (rows.isEmpty) return ageGender;
                                  final infoRaw = rows.first['beneficiary_info']?.toString() ?? '';
                                  Map<String, dynamic> info = {};
                                  if (infoRaw.isNotEmpty) {
                                    try { info = Map<String, dynamic>.from(jsonDecode(infoRaw)); } catch (_) {}
                                  }
                                  final dobStr = info['dob']?.toString() ?? '';
                                  final gender = info['gender']?.toString() ?? '';
                                  DateTime? dob;
                                  if (dobStr.isNotEmpty) {
                                    dob = DateTime.tryParse(dobStr);
                                    if (dob == null) {
                                      final parts = dobStr.split(RegExp(r'[-/]'));
                                      if (parts.length == 3) {
                                        int p0 = int.tryParse(parts[0]) ?? 0;
                                        int p1 = int.tryParse(parts[1]) ?? 0;
                                        int p2 = int.tryParse(parts[2]) ?? 0;
                                        if (parts[0].length == 4) {
                                          dob = DateTime(p0, p1, p2);
                                        } else {
                                          dob = DateTime(p2, p1, p0);
                                        }
                                      }
                                    }
                                  }
                                  String computed = ageGender;
                                  if (dob != null) {
                                    final now = DateTime.now();
                                    int age = now.year - dob.year;
                                    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                                      age -= 1;
                                    }
                                    if (gender.isNotEmpty) {
                                      computed = '$age | $gender';
                                    } else {
                                      computed = '$age';
                                    }
                                  } else if (gender.isNotEmpty) {
                                    computed = gender;
                                  }
                                  return computed;
                                } catch (_) {
                                  return ageGender;
                                }
                              }(),
                              builder: (context, snapshot) {
                                final val = snapshot.data ?? ageGender;
                                return _rowText('Age | Gender', val);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FutureBuilder<String>(
                              future: () async {
                                try {
                                  final db = await DatabaseProvider.instance.database;
                                  final beneficiaryKey = (data['_rawRow']?['beneficiary_ref_key']?.toString() ?? data['BeneficiaryID']?.toString() ?? '').trim();
                                  if (beneficiaryKey.isEmpty) return mobileNo;
                                  final rows = await db.query(
                                    BeneficiariesTable.table,
                                    where: 'unique_key = ?',
                                    whereArgs: [beneficiaryKey],
                                    limit: 1,
                                  );
                                  if (rows.isEmpty) return mobileNo;
                                  final infoRaw = rows.first['beneficiary_info']?.toString() ?? '';
                                  Map<String, dynamic> info = {};
                                  if (infoRaw.isNotEmpty) {
                                    try { info = Map<String, dynamic>.from(jsonDecode(infoRaw)); } catch (_) {}
                                  }
                                  final mobile = info['mobileNo']?.toString() ?? mobileNo;
                                  return mobile.isNotEmpty ? mobile : mobileNo;
                                } catch (_) {
                                  return mobileNo;
                                }
                              }(),
                              builder: (context, snapshot) {
                                final val = snapshot.data ?? mobileNo;
                                return _rowText('Mobile No.', val);
                              },
                            ),
                          ),
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