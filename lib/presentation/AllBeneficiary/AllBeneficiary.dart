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

        // 🚫 Skip migrated beneficiaries
        final int isMigrated = row['is_migrated'] ?? 0;
        if (isMigrated == 1) {
          continue;
        }

        // Parse beneficiary info safely
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

        final bool isChild =
            (info['memberType']?.toString().toLowerCase() == 'child') ||
                (relation.toLowerCase() == 'child');

        final String registrationType = isChild ? 'Child' : 'General';

        beneficiaries.add({
          'hhId': hhId,
          'unique_key': uniqueKey,
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
          ),
          'Mobileno.': info['mobileNo']?.toString() ?? '',
          'FatherName': info['fatherName']?.toString() ?? '',
          'WifeName': '',
          'HusbandName': '',
          'SpouseName': '',
          'SpouseGender': '',
          'Relation': relation,
          'is_synced': row['is_synced'] ?? 0,
          'is_death': row['is_death'] ?? 0,
        });
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

      // 🔃 Sort by registration date (latest first)
      beneficiaries.sort((a, b) {
        final da = DateTime.tryParse(
            (a['RegitrationDate'] ?? '').toString());
        final db = DateTime.tryParse(
            (b['RegitrationDate'] ?? '').toString());
        if (da != null && db != null) {
          return db.compareTo(da);
        }
        return 0;
      });

      setState(() {
        _allBeneficiaries = beneficiaries;
        _filtered = beneficiaries;
        _isLoading = false;
      });
    }
  }


  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      DateTime? dob;
      try {
        dob = DateTime.tryParse(dobRaw.toString());
      } catch (_) {}
      if (dob != null) {
        age = '${DateTime.now().difference(dob).inDays ~/ 365}';
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
          : 'N/A'; // Return original or N/A if empty
    }
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    final gender = (data['Gender']?.toString().toLowerCase() ?? '');
    final isFemale = gender == 'female' || gender == 'f';
    final isChild =
        data['RegitrationType']?.toString().toLowerCase() == 'child';

    // Store the complete beneficiary ID from unique_key (not from BeneficiaryID which is trimmed)
    final String completeBeneficiaryId =
        data['unique_key']?.toString() ??
        data['BeneficiaryID']?.toString() ??
        'N/A';

    // Create display version (last 11 digits)
    final String displayBeneficiaryId =
        (completeBeneficiaryId.length > 11 && completeBeneficiaryId != 'N/A')
        ? completeBeneficiaryId.substring(completeBeneficiaryId.length - 11)
        : completeBeneficiaryId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: (data['is_death'] == 1) ? null : () async {
            // Pass complete household data to next screen
            await Navigator.pushNamed(
              context,
              Route_Names.addFamilyMember,
              arguments: {
                'isBeneficiary': true,
                'isEdit': true,
                // This flag indicates we came from AllBeneficiary and
                // member should be saved/updated immediately on Add.
                'isMemberDetails': true,
                'beneficiaryId': completeBeneficiaryId,
                'hhId': data['hhId']?.toString() ?? '',
                'headName': data['Name']?.toString() ?? '',
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

            // After returning from edit screen, reload data so updates are visible
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
                // Header Row
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
                            'Deceased',
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

                // Card Body
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
                      _buildRow([
                        _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          _formatDate(
                            data['RegitrationDate']?.toString() ?? '',
                          ),
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
                        ), // Display trimmed version
                      ]),
                      const SizedBox(height: 8),

                      // Second row: Name, Age|Gender, Mobile
                      _buildRow([
                        _rowText(
                          l10n?.nameLabel ?? 'Name',
                          data['Name']?.toString().isNotEmpty == true
                              ? data['Name']
                              : (l10n?.na ?? 'N/A'),
                        ),
                        _rowText(
                          l10n?.ageGenderLabel ?? 'Age | Gender',
                          data['Age|Gender']?.toString().isNotEmpty == true
                              ? data['Age|Gender']
                              : (l10n?.na ?? 'N/A'),
                        ),
                        _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.toString().isNotEmpty == true
                              ? data['Mobileno.']
                              : (l10n?.na ?? 'N/A'),
                        ),
                      ]),
                      const SizedBox(height: 8),

                      if (isChild) ...[
                        // For Child records
                        _buildRow([
                          _rowText(
                            l10n?.rchIdLabel ?? 'RCH ID',
                            isFemale
                                ? (data['RichID']?.toString().isNotEmpty == true
                                ? data['RichID']
                                : (l10n?.notAvailable ?? 'Not Available'))
                                : (l10n?.na ?? 'N/A'),
                          ),
                          _rowText(
                            l10n?.fatherName ?? 'Father Name',
                            data['FatherName']?.toString().isNotEmpty == true
                                ? data['FatherName']
                                : (l10n?.notAvailable ?? 'Not Available'),
                          ),
                          _rowText('', ''), // Empty cell for layout
                        ]),
                      ] else ...[
                        // For General records (Head/Spouse/Other)
                        if (data['SpouseName']?.toString().isNotEmpty == true)
                          _buildRow([
                            _rowText(
                              data['SpouseGender'] == 'female'
                                  ? (l10n?.wifeName ?? 'Wife Name')
                                  : (l10n?.husbandName ?? 'Husband Name'),
                              data['SpouseName'],
                            ),
                            _rowText('', ''), // Empty cell for layout
                            _rowText('', ''), // Empty cell for layout
                          ])
                        else
                          _buildRow([
                            _rowText(
                              l10n?.thRelation ?? 'Relation',
                              data['Relation']?.toString().isNotEmpty == true
                                  ? data['Relation']
                                  : (l10n?.na ?? 'N/A'),
                            ),
                            _rowText('', ''),
                            _rowText('', ''),
                          ]),
                      ],
                      const SizedBox(height: 8),

                      _buildRow([
                        _rowText(
                          l10n?.userVillageLabel ?? 'Village',
                          data['village']?.toString().isNotEmpty == true
                              ? data['village']
                              : (l10n?.na ?? 'N/A'),
                        ),
                        _rowText(
                          l10n?.tolaMohalla ?? 'Tola/Mohalla',
                          data['Tola/Mohalla']?.toString().isNotEmpty == true
                              ? data['Tola/Mohalla']
                              : (l10n?.na ?? 'N/A'),
                        ),
                        _rowText('', ''), // Empty cell for layout
                      ]),
                    ],
                  ),
                ),
              ],
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
                width: 100,
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
