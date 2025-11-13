import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../ANCVisitForm/ANCVisitForm.dart';

class Ancvisitlistscreen extends StatefulWidget {
  const Ancvisitlistscreen({super.key});

  @override
  State<Ancvisitlistscreen> createState() => _AncvisitlistscreenState();
}

class _AncvisitlistscreenState extends State<Ancvisitlistscreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  Future<void> _loadPregnantWomen() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];

      print('ℹ️ Found ${rows.length} beneficiaries to process');

      for (final row in rows) {
        try {
          // Parse the beneficiary info
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) {
            print('⚠️ Skipping - No beneficiary_info found');
            continue;
          }

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print('⚠️ Error parsing beneficiary_info: $e');
            continue;
          }

          // Check if isPregnant is 'Yes'
          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) {
            print('ℹ️ Skipping - isPregnant is not Yes');
            continue;
          }

          // Process the person if they are pregnant
          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final gender = info['gender']?.toString().toLowerCase() ?? '';

          // Only include female beneficiaries who are pregnant
          if (gender == 'f' || gender == 'female') {
            print('  🤰 Found pregnant woman: $name');
            final personData = _processPerson(row, info, isPregnant: true);
            if (personData != null) {
              print('  ✅ Added pregnant woman: ${personData['Name']}');
              pregnantWomen.add(personData);
            }
          }
        } catch (e, stackTrace) {
          print('⚠️ Error processing beneficiary row: $e');
          print('Stack trace: $stackTrace');
        }
      }

      setState(() {
        _allData = pregnantWomen;
        _filtered = pregnantWomen;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Fatal error in _loadPregnantWomen: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _processPerson(
      Map<String, dynamic> row,
      Map<String, dynamic> person, {
        required bool isPregnant,
      }) {
    try {
      final name = person['memberName'] ?? person['headName'] ?? 'Unknown';
      final gender = person['gender']?.toString().toLowerCase() ?? '';
      final dob = person['dob'];
      final age = _calculateAge(dob);
      final spouseName = person['spouseName'] ?? person['headName'] ?? '';

      // Only include if pregnant
      if (!isPregnant) return null;

      return {
        'id': row['id']?.toString() ?? '',
        'unique_key': row['unique_key']?.toString() ?? '',
        'BeneficiaryID': row['id']?.toString() ?? '',
        'hhId': person['hhId'] ?? 'N/A',
        'Name': name,
        'Age': age?.toString() ?? 'N/A',
        'Gender': 'Female',
        'RCH ID': person['RCH_ID'] ?? person['RichID'] ?? 'N/A',
        'Mobile No': person['mobileNo'] ?? '',
        'Husband': spouseName,
        'LMP': person['lmp'] ?? 'N/A',
        'EDD': person['edd'] ?? 'N/A',
        'RegistrationDate': person['registrationDate'] ?? 'N/A',
        'beneficiary_info': jsonEncode(person),
        '_rawRow': row,
      };
    } catch (e) {
      print('⚠️ Error processing person: $e');
      return null;
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    try {
      DateTime? birthDate;
      if (dob is String) {
        birthDate = DateTime.tryParse(dob);
      } else if (dob is DateTime) {
        birthDate = dob;
      }

      if (birthDate == null) return null;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      print('⚠️ Error calculating age: $e');
      return null;
    }
  }

  Future<int> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) return 0;


      final count = await LocalStorageDao.instance.getANCVisitCount(beneficiaryId);
      print('✅ Visit count for $beneficiaryId: $count');
      return count;
    } catch (e) {
      print('❌ Error getting visit count: $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadPregnantWomen();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filtered = _allData;
      });
    } else {
      setState(() {
        _filtered = _allData.where((e) {
          return (e['Name']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['Age']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['RCH ID']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['Husband']?.toString().toLowerCase().contains(q) ?? false) ||
              (e['BeneficiaryID']?.toString().toLowerCase().contains(q) ?? false);
        }).toList();
      });
    }
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pregnant_woman, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No pregnant women found',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Register new ANC cases in the family registration',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          itemCount: _filtered.length,
          itemBuilder: (context, index) {
            final item = _filtered[index];
            return _ancCard(context, item);
          },
        ),
      ),
    );
  }

  Widget _ancCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;

    final registrationDate = data['RegistrationDate'] is String && data['RegistrationDate'].isNotEmpty
        ? data['RegistrationDate']
        : l10n?.notAvailable ?? 'N/A';

    final ageGender = '${data['Age']}/F';

    final uniqueKey = data['unique_key']?.toString() ?? data['BeneficiaryID']?.toString() ?? '';
    final beneficiaryId = uniqueKey;

    final husbandName = data['Husband'] is String && data['Husband'].isNotEmpty
        ? data['Husband']
        : l10n?.notAvailable ?? 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Ancvisitform(beneficiaryData: data),
          ),
        ).then((_) => _onRefresh());
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
                        data['hhId'] ?? 'N/A',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
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
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('❌ Error fetching visit count: ${snapshot.error}');
                        return Text(
                          '${l10n?.visitsLabel ?? 'Visits :'} ?',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        );
                      }

                      final count = snapshot.data ?? 0;
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

            // Colored body
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Row: 6 items
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          data['BeneficiaryID'] ?? 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(
                          l10n?.nameLabel ?? 'Name',
                          data['Name'] ?? 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 55,
                        child: _rowText(
                          l10n?.ageLabel ?? 'Age/Gender',
                          ageGender,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 49,
                        child: _rowText(
                          l10n?.husbandLabel ?? 'Husband',
                          husbandName,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          registrationDate,
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 7 - 13,
                        child: _rowText(
                          l10n?.rchIdLabel ?? 'RCH ID',
                          data['RCH ID'] ?? 'N/A',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Second Row: 5 items (LMP, EDD, and ANC visits)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 30,
                        child: _rowText('LMP', data['LMP'] ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText('EDD', data['EDD'] ?? 'N/A'),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText(
                          l10n?.firstAncLabel ?? 'First ANC',
                          l10n?.notAvailable ?? 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 35,
                        child: _rowText(
                          l10n?.secondAncLabel ?? 'Second ANC',
                          l10n?.notAvailable ?? 'N/A',
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 30,
                        child: _rowText(
                          l10n?.thirdAncLabel ?? 'Third ANC',
                          l10n?.notAvailable ?? 'N/A',
                        ),
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
          style: TextStyle(
            color: AppColors.background,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 12.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
            await _onRefresh();
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 4),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                          color: AppColors.onSurface, fontSize: 14.sp),
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
                hintText: l10n?.ancVisitSearchHint ?? 'Search pregnant women',
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
                  borderSide:
                  BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),
          _buildList(),
        ],
      ),
    );
  }
}