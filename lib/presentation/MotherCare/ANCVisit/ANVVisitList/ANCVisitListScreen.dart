import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';


import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';
import '../ANCVisitForm/ANCVisitForm.dart';


class Ancvisitlistscreen extends StatefulWidget {
  const Ancvisitlistscreen({super.key});

  @override
  State<Ancvisitlistscreen> createState() => _AncvisitlistscreenState();
}

class _AncvisitlistscreenState extends State<Ancvisitlistscreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;


  Future<void> _loadEligibleCouples() async {
    setState(() { _isLoading = true; });
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final couples = <Map<String, dynamic>>[];

      print('ℹ️ Found ${rows.length} beneficiaries to process');

      for (final row in rows) {
        try {
          // Check if is_family_planning is 1
          final isFamilyPlanning = row['is_family_planning'] == 1 ||
              row['is_family_planning'] == '1' ||
              (row['is_family_planning']?.toString().toLowerCase() == 'true');

          if (!isFamilyPlanning) {
            print('ℹ️ Skipping - is_family_planning flag is not set');
            continue;
          }

          // Parse the beneficiary info
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) {
            print('⚠️ Skipping - No beneficiary_info found');
            continue;
          }

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print('⚠️ Error parsing beneficiary_info: $e');
            continue;
          }

          // Extract head and spouse details with null safety
          final head = (info['head_details'] is Map)
              ? Map<String, dynamic>.from(info['head_details'] as Map)
              : <String, dynamic>{};

          final spouse = (info['spouse_details'] is Map)
              ? Map<String, dynamic>.from(info['spouse_details'] as Map)
              : <String, dynamic>{};

          print('ℹ️ Processing household: ${head['headName'] ?? 'Unknown'}');

          // Process head if exists
          if (head.isNotEmpty) {
            print('  👤 Processing head of household');
            final coupleData = _processPerson(row, head, spouse, isHead: true);
            if (coupleData != null) {
              print('  ✅ Added eligible head: ${coupleData['Name']}');
              couples.add(coupleData);
            }
          }

          // Process spouse if exists
          if (spouse.isNotEmpty) {
            print('  👥 Processing spouse');
            final coupleData = _processPerson(row, spouse, head, isHead: false);
            if (coupleData != null) {
              print('  ✅ Added eligible spouse: ${coupleData['Name']}');
              couples.add(coupleData);
            }
          }
        } catch (e, stackTrace) {
          print('⚠️ Error processing beneficiary row: $e');
          print('Stack trace: $stackTrace');
        }
      }

      print('✅ Found ${couples.length} eligible couples');

      // Save the data to secure storage with proper structure
      try {
        print('\n📦 Current secure storage data:');
        String? existingData = await SecureStorageService.getUserData();
        print('   - Raw data: ${existingData ?? 'No data found'}');

        Map<String, dynamic> dataToStore = {};

        if (existingData != null && existingData.isNotEmpty) {
          try {
            dataToStore = jsonDecode(existingData);
            print('   - Decoded data: ${dataToStore.toString()}');
          } catch (e) {
            print('⚠️ Error parsing existing secure storage data: $e');
          }
        } else {
          print('   - No existing data in secure storage, will create new');
        }

        // Update the visits list
        dataToStore['visits'] = couples;
        final dataToStoreJson = jsonEncode(dataToStore);

        print('\n💾 Saving to secure storage:');
        print('   - Couples count: ${couples.length}');
        print('   - First couple: ${couples.isNotEmpty ? couples.first.toString() : 'No couples'}');
        print('   - Data size: ${dataToStoreJson.length} characters');

        // Save back to secure storage
        await SecureStorageService.saveUserData(dataToStoreJson);

        // Verify the data was saved correctly
        final savedData = await SecureStorageService.getUserData();
        if (savedData != null && savedData.isNotEmpty) {
          print('\n✅ Successfully saved to secure storage:');
          print('   - Raw saved data: ${savedData.length} characters');
          try {
            final savedJson = jsonDecode(savedData);
            print('   - Decoded saved data: ${savedJson.toString()}');
            if (savedJson['visits'] is List) {
              print('   - Saved visits count: ${savedJson['visits'].length}');

              // Print BeneficiaryID and unique_key for each visit
              if (savedJson['visits'] is List) {
                print('\n🔍 Extracted Beneficiary IDs and Unique Keys:');
                final visits = savedJson['visits'] as List;
                for (int i = 0; i < visits.length; i++) {
                  final visit = visits[i] as Map<String, dynamic>;
                  print('\n🔹 Visit #${i + 1}:');
                  print(
                      '   - BeneficiaryID: ${visit['BeneficiaryID'] ?? 'N/A'}');

                  // Get the _rawRow to access unique_key
                  if (visit['_rawRow'] is Map) {
                    final rawRow = visit['_rawRow'] as Map;
                    print('   - Unique Key: ${rawRow['unique_key'] ?? 'N/A'}');
                  } else {
                    print('   - Unique Key: Not available (no _rawRow)');
                  }

                  // Print additional info for reference
                  print('   - Name: ${visit['Name'] ?? 'N/A'}');
                  print('   - HH ID: ${visit['hhId'] ?? 'N/A'}');
                }
              }
            }} catch (e) {
            print('⚠️ Error parsing saved data: $e');
          }
        } else {
          print('⚠️ Failed to verify saved data - secure storage is empty');
        }
      } catch (e, stackTrace) {
        print('⚠️ Error saving to secure storage: $e');
        print('Stack trace: $stackTrace');
      }

      setState(() {
        _filtered = couples;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      print('❌ Fatal error in _loadEligibleCouples: $e');
      print('Stack trace: $stackTrace');
      setState(() { _isLoading = false; });
    }
  }

  Map<String, dynamic>? _processPerson(Map<String, dynamic> row, Map<String, dynamic> person, Map<String, dynamic> otherPerson, {required bool isHead}) {
    try {
      final gender = (person['gender']?.toString().toLowerCase()?.trim() ?? '');

      String maritalStatus = (person['maritalStatus']?.toString().toLowerCase()?.trim() ??
          person['marital_status']?.toString().toLowerCase()?.trim() ??
          otherPerson['maritalStatus']?.toString().toLowerCase()?.trim() ??
          otherPerson['marital_status']?.toString().toLowerCase()?.trim() ??
          '');

      final isPregnant = person['isPregnant']?.toString().toLowerCase() == 'true' ||
          person['isPregnant']?.toString().toLowerCase() == 'yes' ||
          person['pregnancyStatus']?.toString().toLowerCase() == 'pregnant';

      final dob = person['dob'] ?? person['dateOfBirth'];
      final age = _calculateAge(dob);

      final name = (person['name'] ??
          person['memberName'] ??
          person['headName'] ??
          person['beneficiary_name'] ??
          'Unknown').toString().trim();

      print('ℹ️ Processing person: $name');
      print('  - Gender: $gender, Marital Status: $maritalStatus, Age: $age, Pregnant: $isPregnant');

      final isEligible = (gender == 'f' || gender == 'female') &&
          (maritalStatus == 'married' || maritalStatus == 'm') &&
          (age != null && age >= 15 && age <= 49) &&
          isPregnant;

      if (!isEligible) {
        print('ℹ️ Skipping - Not eligible: '
            'Name: $name, '
            'Gender: $gender, '
            'Marital Status: $maritalStatus, '
            'Age: $age, '
            'Pregnant: $isPregnant');
        return null;
      }

      print('✅ Found eligible beneficiary: $name');

      return _formatCoupleData(row, person, otherPerson, isHead: isHead);
    } catch (e, stackTrace) {
      print('⚠️ Error processing person: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead}) {
    try {
      print('🔍 Formatting couple data...');

      final hhId = row['household_ref_key']?.toString() ?? '';
      final uniqueKey = row['unique_key']?.toString() ?? '';
      final createdDate = row['created_date_time']?.toString() ?? '';
      final info = Map<String, dynamic>.from((row['beneficiary_info'] is Map ? row['beneficiary_info'] : const {}) as Map);

      // Use the full unique key as the BeneficiaryID
      final beneficiaryId = uniqueKey;

      final name = (female['name'] ??
          female['memberName'] ??
          female['headName'] ??
          female['beneficiary_name'] ??
          'Unknown').toString().trim();

      final gender = (female['gender']?.toString().toLowerCase()?.trim() ?? '');
      final displayGender = gender == 'f' ? 'Female' :
      gender == 'm' ? 'Male' :
      gender == 'female' ? 'Female' :
      gender == 'male' ? 'Male' : 'Other';

      final dob = female['dob'] ?? female['dateOfBirth'];
      final age = _calculateAge(dob);

      final richId = (female['RichID'] ??
          female['richId'] ??
          female['abhaId'] ??
          female['abha_id'] ?? '').toString();

      final mobile = (female['mobileNo'] ??
          female['mobile'] ??
          female['phoneNumber'] ??
          female['phone_number'] ?? '').toString();

      String husbandName = '';
      if (isHead) {
        husbandName = (headOrSpouse['memberName'] ??
            headOrSpouse['spouseName'] ??
            headOrSpouse['name'] ?? '').toString().trim();
      } else {
        husbandName = (headOrSpouse['headName'] ??
            headOrSpouse['memberName'] ??
            headOrSpouse['name'] ?? '').toString().trim();
      }



      Map<String, dynamic>? childrenSummary;
      final dynamic childrenRaw = info['children_details'];
      if (childrenRaw is Map) {
        childrenSummary = {
          'totalBorn': childrenRaw['totalBorn'],
          'totalLive': childrenRaw['totalLive'],
          'totalMale': childrenRaw['totalMale'],
          'totalFemale': childrenRaw['totalFemale'],
          'youngestAge': childrenRaw['youngestAge'],
          'ageUnit': childrenRaw['ageUnit'],
          'youngestGender': childrenRaw['youngestGender'],
        }..removeWhere((k, v) => v == null);
      }

      print('🔑 Formatted BeneficiaryID: $beneficiaryId (from uniqueKey: $uniqueKey)');
      return {
        'hhId': hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId,
        'RegistrationDate': _formatDate(createdDate),
        'RegistrationType': 'General',
        'BeneficiaryID': uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey,
        'Name': name,
        'age': (age ?? 0) > 0 ? '$age Y / $displayGender' : 'N/A',
        'RichID': richId,
        'mobileno': mobile,
        'HusbandName': husbandName,
        'childrenSummary': childrenSummary,
        '_rawRow': row,
      };
    } catch (e) {
      print('⚠️ Error formatting couple data: $e');
      return {};
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    try {
      String dateStr = dob.toString();
      // Handle different date formats
      if (dateStr.contains('T')) {
        dateStr = dateStr.split('T')[0];
      }

      final birthDate = DateTime.tryParse(dateStr);
      if (birthDate == null) {
        print('⚠️ Could not parse date: $dob');
        return null;
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      print('⚠️ Error calculating age for $dob: $e');
      return null;
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

  Future<int> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getVisitCount');
        return 0;
      }

      print('🔍 Getting visit count for beneficiary: $beneficiaryId');
      final count = await SecureStorageService.getSubmissionCount(beneficiaryId);
      print('📊 Retrieved count for $beneficiaryId: $count');

      // Debug: List all keys in secure storage to verify
      try {
        final allKeys = await const FlutterSecureStorage().readAll();
        print('🔑 All secure storage keys:');
        allKeys.forEach((key, value) {
          if (key.startsWith('submission_count_')) {
            print('   - $key: $value');
          }
        });
      } catch (e) {
        print('⚠️ Error reading secure storage keys: $e');
      }

      return count;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return 0;
    }
  }



  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadEligibleCouples();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _loadEligibleCouples();
    } else {
      setState(() {
        _filtered = _filtered.where((e) {
          return (e['hhId']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['Name']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['mobileno']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['HusbandName']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.ancVisitListTitle ?? 'ANC Visit List',
        showBack: true,
        icon1Widget: InkWell(
          onTap: () async {
            setState(() {
              _isLoading = true; // show loader
            });
            await _loadEligibleCouples(); // fetch new data
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                // const Icon(Icons.refresh, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
                    child: Text(
                      'Refresh',
                      style: TextStyle(color: AppColors.onSurface, fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.ancVisitSearchHint ?? 'ANC Visit Search',
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

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
            child: Text(
              'No ANC beneficiaries found',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEligibleCouples,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _ancCard(context, data);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _ancCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    final registrationDate = data['RegistrationDate'] is String && data['RegistrationDate'].isNotEmpty
        ? data['RegistrationDate']
        : l10n?.notAvailable ?? 'N/A';

    final ageGender = data['age'] is String && data['age'].isNotEmpty
        ? data['age']
        : l10n?.notAvailable ?? 'N/A';

    final uniqueKey = data['_rawRow']?['unique_key']?.toString() ??
        data['BeneficiaryID']?.toString() ?? '';

    print('🔑 ANC Card - Full Unique Key for count: $uniqueKey');

    final beneficiaryId = uniqueKey;

    final husbandName = data['HusbandName'] is String && data['HusbandName'].isNotEmpty
        ? data['HusbandName']
        : l10n?.notAvailable ?? 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        final beneficiaryData = <String, dynamic>{};

        if (data['_rawRow'] is Map) {
          final rawRow = data['_rawRow'] as Map;
          beneficiaryData['unique_key'] = rawRow['unique_key'];
          beneficiaryData['BeneficiaryID'] = rawRow['BeneficiaryID'];

          print('🔑 Passing to form:');
          print('   - unique_key: ${beneficiaryData['unique_key']}');
          print('   - BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
        }

        // Use pushReplacement with a callback to refresh data when returning
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Ancvisitform(beneficiaryData: beneficiaryData),
          ),
        ).then((_) {
          // This will be called when we return from ANCVisitForm
          _loadEligibleCouples();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        data['hhId'] ?? '',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w500, fontSize: 14.sp),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<int>(
                    future: beneficiaryId.isNotEmpty
                        ? _getVisitCount(beneficiaryId)
                        : Future.value(0),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          '${l10n?.visitsLabel ?? 'Visits :'} ...',
                          style: TextStyle(color: primary, fontWeight: FontWeight.w500, fontSize: 14.sp),
                        );
                      }

                      if (snapshot.hasError) {
                        print('❌ Error fetching visit count: ${snapshot.error}');
                        return Text(
                          '${l10n?.visitsLabel ?? 'Visits :'} ?',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 14.sp),
                        );
                      }

                      final count = snapshot.data ?? 0;
                      print('✅ Fetched count $count for beneficiary: $beneficiaryId');

                      return Text(
                        '${l10n?.visitsLabel ?? 'Visits :'} $count',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 25,
                    child: Image.asset('assets/images/sync.png'),
                  )
                ],
              ),
            ),

            // Blue body
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- First Row: 6 items (auto-wraps if space is tight) ---
                  Wrap(
                    spacing: 8, // horizontal gap
                    runSpacing: 8, // vertical gap if wrapped
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryID'] ?? ''),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(l10n?.nameLabel ?? 'Name', data['Name'] ?? ''),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(l10n?.ageLabel ?? 'Age/Gender', ageGender),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 49,
                        child: _rowText(l10n?.husbandLabel ?? 'Husband', husbandName),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width /4 - 25,
                        child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', registrationDate),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 7 - 13,
                        child: _rowText(l10n?.rchIdLabel ?? 'RCH ID', 'N/A'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // --- Second Row: 5 items ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 30,
                        child: _rowText(l10n?.firstAncLabel ?? 'First ANC', l10n?.notAvailable ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText(l10n?.secondAncLabel ?? 'Second ANC', l10n?.notAvailable ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText(l10n?.thirdAncLabel ?? 'Third ANC', l10n?.notAvailable ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText( 'Fourth ANC', l10n?.notAvailable ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 30,
                        child: _rowText(l10n?.pmsmaLabel ?? 'PMSMA', l10n?.notAvailable ?? 'N/A'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(color: AppColors.background, fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 12.sp),
        ),
      ],
    );
  }

}