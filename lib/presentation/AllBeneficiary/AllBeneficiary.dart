import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../data/Database/local_storage_dao.dart';
import '../HomeScreen/HomeScreen.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class AllBeneficiaryScreen extends StatefulWidget {
  const AllBeneficiaryScreen({super.key});

  @override
  State<AllBeneficiaryScreen> createState() => _AllBeneficiaryScreenState();
}

class _AllBeneficiaryScreenState extends State<AllBeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  late List<Map<String, dynamic>> _filtered;
  List<Map<String, dynamic>> _allBeneficiaries = [];

  @override
  void initState() {
    super.initState();

    _loadData().then((_) {
      print('✅ Total beneficiaries loaded: ${_allBeneficiaries.length}');
    });

    _searchCtrl.addListener(_onSearchChanged);
  }


  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final beneficiaries = <Map<String, dynamic>>[];
    final dao = LocalStorageDao();

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries(
        isMigrated: 0, // DB-level filter
      );

      print('=== AllBeneficiary Screen - Data Loading ===');
      print('Total records from database: ${rows.length}');

      for (int i = 0; i < rows.length; i++) {
        print('\n--- Record $i ---');
        print('beneficiary_info: ${rows[i]['beneficiary_info']}');
        print('household_ref_key: ${rows[i]['household_ref_key']}');
        print('unique_key: ${rows[i]['unique_key']}');
        print('created_date_time: ${rows[i]['created_date_time']}');
        print('is_migrated: ${rows[i]['is_migrated']}');
      }
      print('=== End of Data Loading ===\n');

      for (final row in rows) {

        final int isMigrated = row['is_migrated'] ?? 0;
        if (isMigrated == 1) {
          continue;
        }

        Map<String, dynamic> info;
        try {
          if (row['beneficiary_info'] is String) {
            info = jsonDecode(row['beneficiary_info'] as String)
            as Map<String, dynamic>;
          } else if (row['beneficiary_info'] is Map) {
            info = Map<String, dynamic>.from(row['beneficiary_info'] as Map);
          } else {
            info = <String, dynamic>{};
          }
        } catch (e) {
          print('Error parsing beneficiary info: $e');
          info = <String, dynamic>{};
        }

        // Debug: Print all available keys in beneficiary info
        print('🔍 Available keys in beneficiary info: ${info.keys.toList()}');
        print('👤 Full beneficiary info: $info');

        final String hhId = row['household_ref_key']?.toString() ?? '';
        final String createdDate =
            row['created_date_time']?.toString() ?? '';
        final String gender =
            info['gender']?.toString().toLowerCase() ?? '';
        final String richId =
            info['RichIDChanged']?.toString() ??
                info['richIdChanged']?.toString() ??
                '';

        // Unified display name
        final String displayName =
        (info['name'] ??
            info['memberName'] ??
            info['headName'] ??
            '')
            .toString();

        final String uniqueKey = row['unique_key']?.toString() ?? '';
        final String beneficiaryId = uniqueKey.length > 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        final String relation =
            info['relation_to_head']?.toString() ??
                info['relation']?.toString() ??
                'N/A';

        final String village = info['village']?.toString() ?? '';
        final String mohalla = info['mohalla']?.toString() ?? '';
        final String maritalStatus = info['maritalStatus']?.toString() ?? '';
        final t = AppLocalizations.of(context);
        final bool isChild =
            (info['memberType']?.toString().toLowerCase() == 'child') ||
                (relation.toLowerCase() == 'child');

        final String registrationType = isChild ? 'Child' : 'General';
        final fatherName =
            _nonEmpty(info['father_name']) ??
                _nonEmpty(info['fatherName']) ??
                t!.na;
        beneficiaries.add({
          'hhId': hhId,
          'unique_key': uniqueKey,
          'created_date_time': createdDate,
          'RegitrationDate': createdDate,
          'RegitrationType': registrationType,
          'BeneficiaryID': beneficiaryId,
          'Tola/Mohalla': mohalla,
          'village': village,
          'RichID': richId,
          'Gender': gender,
          'Name': displayName,
          'Age|Gender': _formatAgeGender(
            info['dob'],
            info['gender'],
            row['is_death'] ?? 0,
            row['death_details'],
            row['modified_date_time'],
          ),
          'Mobileno.': info['mobileNo']?.toString() ?? '',
          'FatherName': fatherName,
          'MotherName': info['motherName']?.toString() ?? info['mother_name']?.toString() ?? info['mother']?.toString() ?? '',
          'WifeName': info['wifeName']?.toString() ?? info['wife_name']?.toString() ?? info['wife']?.toString() ?? info['spouse_name']?.toString() ?? '',
          'HusbandName': info['husbandName']?.toString() ?? info['husband_name']?.toString() ?? info['husband']?.toString() ?? info['spouse_name']?.toString() ?? '',
          'SpouseName': info['spouseName']?.toString() ?? info['spouse_name']?.toString() ?? info['spouse']?.toString() ?? '',
          'SpouseGender': info['spouseGender']?.toString() ?? info['spouse_gender']?.toString() ?? info['gender']?.toString() ?? '',
          'Relation': relation,
          'MaritalStatus': maritalStatus,
          'is_synced': row['is_synced'] ?? 0,
          'is_death': row['is_death'] ?? 0,
          '_rawInfo': info, // Store raw beneficiary info for fallback access
        });

        // Debug: Print extracted spouse names
        print('💑 Extracted spouse names:');
        print('  - WifeName: ${info['wifeName'] ?? info['wife_name'] ?? info['wife'] ?? info['spouse_name'] ?? 'NOT FOUND'}');
        print('  - HusbandName: ${info['husbandName'] ?? info['husband_name'] ?? info['husband'] ?? info['spouse_name'] ?? 'NOT FOUND'}');
        print('  - SpouseName: ${info['spouseName'] ?? info['spouse_name'] ?? info['spouse'] ?? 'NOT FOUND'}');
      }
    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      print('\n=== Data Processing Complete ===');
      print('Total beneficiaries processed: ${beneficiaries.length}');

      for (int i = 0; i < beneficiaries.length; i++) {
        print('\nBeneficiary $i:');
        print('  Name: ${beneficiaries[i]['Name']}');
        print('  Type: ${beneficiaries[i]['RegitrationType']}');
        print('  Household: ${beneficiaries[i]['hhId']}');
      }

      print('=== End Processing ===\n');

      // 🔃 Sort by created_date_time (latest first) - using original database field
      // 🔃 Sort by created_date_time (latest first – date + time)
      beneficiaries.sort((a, b) {
        DateTime parseDate(dynamic value) {
          if (value == null) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }

          try {
            final dt = DateTime.parse(value.toString());
            return dt.toLocal(); // IMPORTANT: handle Z (UTC)
          } catch (_) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
        }

        final DateTime dateA = parseDate(a['created_date_time']);
        final DateTime dateB = parseDate(b['created_date_time']);

        // Latest first
        return dateB.compareTo(dateA);
      });


      setState(() {
        _allBeneficiaries = beneficiaries;
        _filtered = beneficiaries;
        _isLoading = false;
      });
    }
  }
  String? _nonEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw, int isDeath, dynamic deathDetailsRaw, dynamic modifiedDateTimeRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      DateTime? dob;
      try {
        dob = DateTime.tryParse(dobRaw.toString());
      } catch (_) {}
      if (dob != null) {
        DateTime referenceDate = DateTime.now();

        // Only calculate age using death date if is_death equals 1
        if (isDeath == 1) {
          DateTime? deathDate;

          // First try to get date from death_details
          if (deathDetailsRaw != null) {
            Map<String, dynamic> deathDetails = {};
            try {
              if (deathDetailsRaw is String) {
                deathDetails = jsonDecode(deathDetailsRaw as String) as Map<String, dynamic>;
              } else if (deathDetailsRaw is Map) {
                deathDetails = Map<String, dynamic>.from(deathDetailsRaw as Map);
              }

              // Parse date of death
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
            } catch (e) {
              print('Error parsing death details: $e');
            }
          }

          // If death date not found, try modified_date_time
          if (deathDate == null && modifiedDateTimeRaw != null) {
            print('🔍 Debug: modifiedDateTimeRaw = $modifiedDateTimeRaw');
            try {
              final modifiedDateStr = modifiedDateTimeRaw.toString();
              if (modifiedDateStr.isNotEmpty) {
                deathDate = DateTime.parse(modifiedDateStr);
                print('✅ Debug: Successfully parsed modified_date_time: $deathDate');
              }
            } catch (_) {
              print('❌ Debug: Failed to parse modified_date_time as string, trying timestamp...');
              // Try parsing as timestamp
              final timestamp = int.tryParse(modifiedDateTimeRaw.toString());
              if (timestamp != null && timestamp > 0) {
                deathDate = DateTime.fromMillisecondsSinceEpoch(
                  timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                  isUtc: true,
                );
                print('✅ Debug: Successfully parsed modified_date_time as timestamp: $deathDate');
              }
            }
          }

          // Use death date if found, otherwise use current date
          if (deathDate != null) {
            referenceDate = deathDate;
          }
        }

        age = '${referenceDate.difference(dob).inDays ~/ 365}';
      }
    }
    String displayGender = gender == 'm' || gender == 'male'
        ? 'Male'
        : gender == 'f' || gender == 'female'
        ? 'Female'
        : 'Other';
    return '$age Y | $displayGender';
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
        _filtered = List<Map<String, dynamic>>.from(_allBeneficiaries);
      } else {
        _filtered = _allBeneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['village']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Tola/Mohalla']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridAllBeneficiaries ?? 'All Beneficiaries',
        showBack: false,
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),

      body: _isLoading
          ? const CenterBoxLoader()
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:
                l10n?.searchBeneficiaries ?? "Beneficiaries Search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ),

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

          // ➕ Add New Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: RoundButton(
                  title:
                  (l10n?.gridNewHouseholdRegister ??
                      'New Household Registration')
                      .toUpperCase(),
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 45,
                  onPress: () {
                    Navigator.pushNamed(
                      context,
                      Route_Names.addFamilyHead,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      DateTime? date = DateTime.tryParse(dateString);

      if (date == null && dateString.contains('-')) {
        final parts = dateString.split(' ');
        final datePart = parts[0]; // Get just the date part
        final dateSegments = datePart.split('-');

        if (dateSegments.length == 3) {
          // If it's already in dd-mm-yyyy format, just return it as is
          if (dateSegments[0].length == 2 && dateSegments[2].length == 4) {
            return datePart;
          }
          // If it's in yyyy-mm-dd format, reformat it
          else if (dateSegments[0].length == 4 && dateSegments[2].length == 2) {
            return '${dateSegments[2]}-${dateSegments[1]}-${dateSegments[0]}';
          }
        }
      }

      // If we have a valid date, format it
      if (date != null) {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        return '$day-$month-$year';
      }

      // If all else fails, return the original string (or N/A if empty)
      return dateString.isNotEmpty ? dateString : 'N/A';
    } catch (e) {
      return dateString.isNotEmpty
          ? dateString
          : 'N/A';
    }
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    final gender = (data['Gender']?.toString().toLowerCase() ?? '');
    final isFemale = gender == 'female' || gender == 'f';
    final isMale = gender == 'male' || gender == 'm';
    final isChild =
        data['RegitrationType']?.toString().toLowerCase() == 'child';
    final isGeneral =
        data['RegitrationType']?.toString().toLowerCase() == 'general';

    // Marital status logic - need to extract from data or assume based on relation
    final String relation = data['Relation']?.toString().toLowerCase() ?? '';
    final String maritalStatus = data['MaritalStatus']?.toString().toLowerCase() ?? '';

    final bool isUnmarried = relation.isEmpty ||
        relation == 'son' ||
        relation == 'daughter' ||
        relation == 'brother' ||
        relation == 'sister' ||
        relation == 'grandson' ||
        relation == 'granddaughter' ||
        relation == 'nephew' ||
        relation == 'niece' ||
        relation == 'father' ||
        isChild; // Children are considered unmarried

    //final bool isMarried = !isUnmarried && !isChild;
    final isMarried = maritalStatus == 'married' && !isChild;

    // Helper functions to get data with fallback to raw beneficiary info
    String getMobileNumber() {
      // Check regular data first
      String mobile = data['Mobileno.']?.toString() ?? '';

      if (mobile.isNotEmpty) return mobile;

      // Check raw beneficiary info for mobileNo
      final rawInfo = data['_rawInfo'] as Map<String, dynamic>?;
      if (rawInfo != null) {
        mobile = rawInfo['mobileNo']?.toString() ?? '';
        if (mobile.isNotEmpty) return mobile;
      }

      return mobile;
    }

    String getVillage() {
      // Check regular data first
      String village = data['village']?.toString() ?? '';
      if (village.isNotEmpty) return village;

      // Check raw beneficiary info for village
      final rawInfo = data['_rawInfo'] as Map<String, dynamic>?;
      if (rawInfo != null) {
        village = rawInfo['village']?.toString() ?? '';
        if (village.isNotEmpty) return village;
      }

      return village;
    }

    String getMohalla() {
      // Check regular data first
      String mohalla = data['Tola/Mohalla']?.toString() ?? '';
      if (mohalla.isNotEmpty) return mohalla;

      // Check raw beneficiary info for mohalla fields
      final rawInfo = data['_rawInfo'] as Map<String, dynamic>?;
      if (rawInfo != null) {
        mohalla = rawInfo['mohalla']?.toString() ?? '';
        if (mohalla.isNotEmpty) return mohalla;

        mohalla = rawInfo['mohallaTola']?.toString() ?? '';
        if (mohalla.isNotEmpty) return mohalla;
      }

      return mohalla;
    }

    final String completeBeneficiaryId =
        data['unique_key']?.toString() ??
            data['BeneficiaryID']?.toString() ??
            'N/A';

    final String displayBeneficiaryId =
    (completeBeneficiaryId.length > 11 && completeBeneficiaryId != 'N/A')
        ? completeBeneficiaryId.substring(completeBeneficiaryId.length - 11)
        : completeBeneficiaryId;
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: (data['is_death'] == 1) ? null : () async {
            await Navigator.pushNamed(
              context,
              Route_Names.addFamilyMember,
              arguments: {
                'isBeneficiary': true,
                'isEdit': true,

                'isMemberDetails': true,
                'beneficiaryId': completeBeneficiaryId,
                'hhId': data['hhId']?.toString() ?? '',
                'headName': data['Name']?.toString() ?? data['headName']?.toString() ??'',
                'headGender': data['Gender']?.toString() ?? '',
                'spouseName': data['SpouseName']?.toString() ?? '',
                'spouseGender': data['SpouseGender']?.toString() ?? '',
                'relation': data['Relation']?.toString() ?? '',
                'village': data['village']?.toString() ?? '',
                'tolaMohalla': data['Tola/Mohalla']?.toString() ?? '',
                'householdData': data,
              },
            );

            debugPrint(' Navigation to AddFamilyMember:');
            debugPrint('   HHID: ${data['hhId']}');
            debugPrint(
              '   Complete Beneficiary ID (from unique_key): $completeBeneficiaryId',
            );

            debugPrint('   Head Name: ${data['Name']}');
            debugPrint('   Spouse Name: ${data['SpouseName']}');

            await _loadData();
            _onSearchChanged();
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
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (data['hhId']?.toString().length ?? 0) > 11
                              ? data['hhId'].toString().substring(
                            data['hhId'].toString().length - 11,
                          )
                              : (data['hhId'] ?? ''),
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (data['is_death'] == 1)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            // border: Border.all(
                            //   color: Colors.red.withOpacity(0.5),
                            //   width: 0.5,
                            // ),
                          ),
                          child: Text(
                            l10n!.deceased,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Image.asset(
                        'assets/images/sync.png',
                        width: 25,
                        height: 25,
                        color: (data['is_synced'] == 1) ? null : Colors.grey,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(6),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Common fields for all categories
                      _buildRow([
                        _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          _formatDate(data['RegitrationDate']?.toString() ?? ''),
                        ),
                        _rowText(
                          l10n?.registrationTypeLabel ?? 'Registration Type',
                          isChild
                              ? (l10n?.memberTypeChild ?? 'Child')
                              : (l10n?.categoryGeneral ?? 'General'),
                        ),
                        _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          displayBeneficiaryId,
                        ),
                      ]),
                      const SizedBox(height: 8),

                      _buildRow([
                        _rowText(l10n?.nameLabel ?? 'Name', data['Name']?.toString().isNotEmpty == true ? data['Name'] : (l10n?.na ?? 'N/A')),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']?.toString().isNotEmpty == true ? data['Age|Gender'] : (l10n?.na ?? 'N/A')),
                        // Category-specific third field
                        if (isChild)
                          _rowText(
                            l10n?.rchIdLabel ?? 'RCH ID',
                            data['RichID']?.toString().trim().isNotEmpty == true
                                ? data['RichID'].toString()
                                : (l10n?.notAvailable ?? 'Not Available'),
                          )
                        else if (isFemale && !isChild)
                          _rowText(
                            l10n?.rchIdLabel ?? 'RCH ID',
                            data['RichID']?.toString().trim().isNotEmpty == true
                                ? data['RichID'].toString()
                                : (l10n?.notAvailable ?? 'Not Available'),
                          )
                        else if (isMale && !isChild)
                        _rowText(
    l10n?.tolaMohalla ?? 'Tola/Mohalla',
    getMohalla().isNotEmpty
    ? getMohalla()
        : (l10n?.na ?? 'N/A'),
    ),
                            /*_rowText(
                              l10n?.mobileLabelSimple ?? 'Mobile No.',
                              getMobileNumber().isNotEmpty
                                  ? getMobileNumber()
                                  : (l10n?.na ?? 'N/A'),
                            )*/
                      ]),
                      const SizedBox(height: 8),

                      // CATEGORY 1: Children (male/female) - show father name, mobile, village, tola/mohalla
                      if (isChild) ...[
                        _buildRow([
                          // Father name for children - first column
                          if ((data['FatherName']?.toString().isNotEmpty == true) ||
                              (data['SpouseName']?.toString().isNotEmpty == true))
                            _rowText(
                              l10n?.fatherName ?? 'Father Name',
                              data['FatherName']?.toString().isNotEmpty == true
                                  ? data['FatherName']
                                  : data['SpouseName'],
                            )
                          else
                            _rowText('', ''),
                          // Mobile number for children - second column
                          _rowText(
                            l10n?.mobileLabelSimple ?? 'Mobile No.',
                            getMobileNumber().isNotEmpty
                                ? getMobileNumber()
                                : (l10n?.na ?? 'NA'),
                          ),
                          // Village for children - third column
                          _rowText(
                            l10n?.userVillageLabel ?? 'Village',
                            getVillage().isNotEmpty
                                ? getVillage()
                                : (l10n?.na ?? 'N/A'),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        _buildRow([
                          _rowText(
                            l10n?.tolaMohalla ?? 'Tola/Mohalla',
                            getMohalla().isNotEmpty
                                ? getMohalla()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText('', ''), // Empty cell for layout
                          _rowText('', ''), // Empty cell for layout
                        ]),
                      ],

                      if (isFemale && isMarried) ...[
                        _buildRow([
                          if (data['HusbandName']?.toString().isNotEmpty == true)
                            _rowText(
                              l10n?.husbandName ?? 'Husband Name',
                              data['HusbandName'],
                            )
                          else if (data['SpouseName']?.toString().isNotEmpty == true)
                            _rowText(
                              l10n?.husbandName ?? 'Husband Name',
                              data['SpouseName'],
                            )
                          else if ((data['FatherName']?.toString().isNotEmpty == true))
                              _rowText(
                                l10n?.fatherName ?? 'Father Name',
                                data['FatherName']?.toString().isNotEmpty == true
                                    ? data['FatherName']
                                    : t!.na,
                              )
                          else
                            _rowText('', ''),
                          _rowText(
                            l10n?.mobileLabelSimple ?? 'Mobile No.',
                            getMobileNumber().isNotEmpty
                                ? getMobileNumber()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText(
                            l10n?.userVillageLabel ?? 'Village',
                            getVillage().isNotEmpty
                                ? getVillage()
                                : (l10n?.na ?? 'N/A'),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        _buildRow([
                          _rowText(
                            l10n?.tolaMohalla ?? 'Tola/Mohalla',
                            getMohalla().isNotEmpty
                                ? getMohalla()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText('', ''), // Empty cell for layout
                          _rowText('', ''), // Empty cell for layout
                        ]),
                      ],

                      if (maritalStatus=='unmarried' && isGeneral) ...[
                        _buildRow([
                          if ((data['FatherName']?.toString().isNotEmpty == true) ||
                              (data['SpouseName']?.toString().isNotEmpty == true))
                            _rowText(
                              l10n?.fatherName ?? 'Father Name',
                              data['FatherName']?.toString().isNotEmpty == true
                                  ? data['FatherName']
                                  : data['SpouseName'],
                            )
                          else
                            _rowText('', ''),
                          if (isFemale)
                            _rowText(
                              l10n?.rchIdLabel ?? 'RCH ID',
                              data['RichID']?.toString().trim().isNotEmpty == true
                                  ? data['RichID'].toString()
                                  : (l10n?.notAvailable ?? 'Not Available'),
                            )
                          else
                            _rowText(
                              l10n?.mobileLabelSimple ?? 'Mobile No.',
                              getMobileNumber().isNotEmpty
                                  ? getMobileNumber()
                                  : (l10n?.na ?? 'N/A'),
                            ),
                          _rowText(
                            l10n?.userVillageLabel ?? 'Village',
                            getVillage().isNotEmpty
                                ? getVillage()
                                : (l10n?.na ?? 'N/A'),
                          ),
                        ]),
                        /* const SizedBox(height: 8),
                        _buildRow([
                          _rowText(
                            l10n?.tolaMohalla ?? 'Tola/Mohalla',
                            getMohalla().isNotEmpty
                                ? getMohalla()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText('', ''), // Empty cell for layout
                          _rowText('', ''), // Empty cell for layout
                        ]),*/
                      ],

                      // CATEGORY 3: Married males - show wife name, mobile, village, tola/mohalla
                      if (isMale && isMarried && !isChild) ...[
                        _buildRow([
                          if (data['WifeName']?.toString().isNotEmpty == true)
                            _rowText(
                              l10n?.wifeName ?? 'Wife Name',
                              data['WifeName'],
                            )
                          else if (data['SpouseName']?.toString().isNotEmpty == true)
                            _rowText(
                              l10n?.wifeName ?? 'Wife Name',
                              data['SpouseName'],
                            )
                          else
                            _rowText('', ''),
                          _rowText(
                            l10n?.mobileLabelSimple ?? 'Mobile No.',
                            getMobileNumber().isNotEmpty
                                ? getMobileNumber()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText(
                            l10n?.userVillageLabel ?? 'Village',
                            getVillage().isNotEmpty
                                ? getVillage()
                                : (l10n?.na ?? 'N/A'),
                          ),
                        ]),
                        const SizedBox(height: 8),

                        /*_buildRow([
                          _rowText(
                            l10n?.tolaMohalla ?? 'Tola/Mohalla',
                            getMohalla().isNotEmpty
                                ? getMohalla()
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText('', ''), // Empty cell for layout
                          _rowText('', ''), // Empty cell for layout
                        ]),*/
                      ],

                      // CATEGORY 4: Unmarried males/females with general registration - show father name, village, tola/mohalla

                    ],
                  ),
                )],
            ),
          ),
        ),

        if (_isEligibleForCBAC(data['Age|Gender'] as String))
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 8),
            child: SizedBox(
              height: 32,
              child: RoundButton(
                title: l10n!.cbac,
                color: AppColors.primary,
                borderRadius: 6,
                width: 140,
                onPress: () {
                  final beneficiaryData = {
                    'beneficiaryId':
                    data['unique_key']?.toString() ??
                        '', // Use complete ID from unique_key
                    'hhid': data['hhId']?.toString() ?? '',
                    'name': data['Name']?.toString() ?? '',
                    'age':
                    data['Age|Gender']?.toString().split(' ').first ?? '',
                    'gender': data['Gender']?.toString().toLowerCase() ?? '',
                    'mobile': data['Mobileno.']?.toString() ?? '',
                    'village': data['village']?.toString() ?? '',
                    'tolaMohalla': data['Tola/Mohalla']?.toString() ?? '',
                    'fatherName': data['FatherName']?.toString() ?? '',
                    'husbandName': data['HusbandName']?.toString() ?? '',
                    'wifeName': data['WifeName']?.toString() ?? '',
                    'relation': data['Relation']?.toString() ?? '',
                  };

                  if (beneficiaryData['beneficiaryId']!.isEmpty ||
                      beneficiaryData['hhid']!.isEmpty) {
                    debugPrint(
                      'Warning: Missing required data for CBAC - BeneficiaryID: ${beneficiaryData['beneficiaryId']}, hhId: ${beneficiaryData['hhid']}',
                    );
                    debugPrint('Available data keys: ${data.keys.join(', ')}');
                  }

                  Navigator.pushNamed(
                    context,
                    Route_Names.cbacScreen,
                    arguments: beneficiaryData,
                  );

                  if (beneficiaryData['beneficiaryId']!.isNotEmpty &&
                      beneficiaryData['hhid']!.isNotEmpty) {
                    debugPrint('✅ CBAC Navigation Data:');
                    debugPrint(
                      '   Beneficiary ID: ${beneficiaryData['beneficiaryId']}',
                    );
                    debugPrint('   Household ID: ${beneficiaryData['hhid']}');
                    debugPrint('   Name: ${beneficiaryData['name']}');
                    debugPrint('   Age: ${beneficiaryData['age']}');
                    debugPrint('   Gender: ${beneficiaryData['gender']}');
                    debugPrint('   Mobile: ${beneficiaryData['mobile']}');
                  } else {
                    debugPrint(
                      '❌ Missing data - BeneficiaryID: ${beneficiaryData['beneficiaryId']}, hhId: ${beneficiaryData['hhid']}',
                    );
                  }
                },
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
        ],
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

  bool _isEligibleForCBAC(String ageGender) {
    try {
      final ageStr = ageGender.split(' ').first;
      final age = int.tryParse(ageStr) ?? 0;
      return age >= 30;
    } catch (e) {
      debugPrint('Error checking CBAC eligibility: $e');
      return false;
    }
  }
}
