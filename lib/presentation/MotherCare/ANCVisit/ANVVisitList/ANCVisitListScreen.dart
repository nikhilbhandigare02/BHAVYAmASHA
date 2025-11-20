import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';

import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
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


          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) {
            print('ℹ️ Skipping - isPregnant is not Yes');
            continue;
          }

          // Process the person if they are pregnant
          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final gender = info['gender']?.toString().toLowerCase() ?? '';

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


      final Map<String, Map<String, dynamic>> byBeneficiary = {};
      for (final item in pregnantWomen) {
        final benId = item['BeneficiaryID']?.toString() ?? '';
        final uniqueKey = item['unique_key']?.toString() ?? '';
        final key = benId.isNotEmpty ? benId : uniqueKey;
        if (key.isEmpty) continue;
         byBeneficiary[key] = item;
      }

      final dedupedList = byBeneficiary.values.toList();

      setState(() {
        _allData = dedupedList;
        _filtered = dedupedList;
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

  String _getLast11Chars(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }


  DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
    final days = noOfWeeks * 7;
    return startDate.add(Duration(days: days));
  }


  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  Map<String, DateTime> _calculateAncDateRanges(DateTime lmp) {
    final ranges = <String, DateTime>{};

    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = _dateAfterWeeks(lmp, 12);

    ranges['2nd_anc_start'] = _dateAfterWeeks(lmp, 14);
    ranges['2nd_anc_end'] = _dateAfterWeeks(lmp, 24);

    // 3rd ANC: 26 to 34 weeks from LMP
    ranges['3rd_anc_start'] = _dateAfterWeeks(lmp, 26);
    ranges['3rd_anc_end'] = _dateAfterWeeks(lmp, 34);

    // 4th ANC: 36 weeks from LMP to EDD
    ranges['4th_anc_start'] = _dateAfterWeeks(lmp, 36);
    ranges['4th_anc_end'] = _calculateEdd(lmp);

    // PMSMA: 4-week window immediately AFTER 4th ANC (40–44 weeks from LMP)
    ranges['pmsma_start'] = _dateAfterWeeks(lmp, 40);
    ranges['pmsma_end'] = _dateAfterWeeks(lmp, 44);

    return ranges;
  }

  // Format date to dd/MM/yyyy format
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

      // Store COMPLETE IDs
      final householdRefKey = row['household_ref_key']?.toString() ?? '';
      final uniqueKey = row['unique_key']?.toString() ?? '';

      // Get TRIMMED versions for display only
      final householdRefKeyDisplay = _getLast11Chars(householdRefKey);
      final uniqueKeyDisplay = _getLast11Chars(uniqueKey);

      final registrationDate = row['created_date_time']?.toString() ?? '';

      // Only include if pregnant
      if (!isPregnant) return null;

      // Format registration date if available
      String formattedDate = 'N/A';
      if (registrationDate.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(registrationDate);
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        } catch (e) {
          print('⚠️ Error parsing date: $e');
        }
      }

      return {
        'id': row['id']?.toString() ?? '',
        // COMPLETE IDs for passing to next screen
        'unique_key': uniqueKey,
        'BeneficiaryID': uniqueKey,
        'hhId': householdRefKey,
        // DISPLAY versions (trimmed) for UI only
        'unique_key_display': uniqueKeyDisplay,
        'BeneficiaryID_display': uniqueKeyDisplay,
        'hhId_display': householdRefKeyDisplay,
        // Other fields
        'Name': name,
        'Age': age?.toString() ?? 'N/A',
        'Gender': 'Female',
        'RCH ID': person['RCH_ID'] ?? person['RichID'] ?? 'N/A',
        'Mobile No': person['mobileNo'] ?? '',
        'Husband': spouseName,
        'RegistrationDate': formattedDate,
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

    // Use COMPLETE IDs for functionality
    final uniqueKey = data['unique_key']?.toString() ?? '';
    final beneficiaryId = data['BeneficiaryID']?.toString() ?? '';
    final hhId = data['hhId']?.toString() ?? '';

    // Use DISPLAY versions for UI
    final uniqueKeyDisplay = data['unique_key_display']?.toString() ?? data['BeneficiaryID_display']?.toString() ?? '';
    final hhIdDisplay = data['hhId_display']?.toString() ?? '';

    final husbandName = data['Husband'] is String && data['Husband'].isNotEmpty
        ? data['Husband']
        : l10n?.notAvailable ?? 'N/A';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        // Get the visit count before navigating
        final visitCount = await (beneficiaryId.isNotEmpty
            ? _getVisitCount(beneficiaryId)
            : Future.value(0));

        final formData = Map<String, dynamic>.from(data);

        formData['hhId'] = hhId;
        formData['BeneficiaryID'] = beneficiaryId;
        formData['unique_key'] = uniqueKey;

        formData['visitCount'] = visitCount;

        print('Passing visitCount to form: $visitCount');


        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Ancvisitform(beneficiaryData: formData),
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
                        hhIdDisplay.isNotEmpty ? hhIdDisplay : 'N/A',
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
                  // First Row: 6 items - use DISPLAY version (trimmed)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 25,
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          uniqueKeyDisplay.isNotEmpty ? uniqueKeyDisplay : 'N/A',
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

                  // ANC Visit Date Ranges
                  FutureBuilder<int>(
                    future: beneficiaryId.isNotEmpty
                        ? _getVisitCount(beneficiaryId)
                        : Future.value(0),
                    builder: (context, snapshot) {
                      final visitCount = snapshot.data ?? 0;

                      // Derive LMP date for this beneficiary
                      DateTime? lmpDate;
                      try {
                        final rawRow = data['_rawRow'] as Map<String, dynamic>?;
                        dynamic rawInfo = rawRow?['beneficiary_info'];
                        Map<String, dynamic> info;

                        if (rawInfo is String && rawInfo.isNotEmpty) {
                          info = jsonDecode(rawInfo) as Map<String, dynamic>;
                        } else if (rawInfo is Map) {
                          info = Map<String, dynamic>.from(rawInfo as Map);
                        } else {
                          info = <String, dynamic>{};
                        }

                        final lmpRaw = info['lmp']?.toString();
                        if (lmpRaw != null && lmpRaw.isNotEmpty) {
                          // Handle possible ISO-like strings (e.g., 2025-11-14T00:00:00.000)
                          String dateStr = lmpRaw;
                          if (dateStr.contains('T')) {
                            dateStr = dateStr.split('T')[0];
                          }
                          lmpDate = DateTime.tryParse(dateStr);
                        }
                      } catch (e) {
                        print('⚠️ Error deriving LMP date: $e');
                      }

                      // Fallback: use registration date if LMP is unavailable
                      if (lmpDate == null) {
                        try {
                          final parts = registrationDate.split('/');
                          if (parts.length == 3) {
                            lmpDate = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                          } else {
                            lmpDate = DateTime.now();
                          }
                        } catch (e) {
                          print('⚠️ Error parsing fallback registration date: $e');
                          lmpDate = DateTime.now();
                        }
                      }

                      final ancRanges = _calculateAncDateRanges(lmpDate!);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ancDateBox(
                            'First ANC',
                            ancRanges['1st_anc_start']!,
                            ancRanges['1st_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Second ANC',
                            ancRanges['2nd_anc_start']!,
                            ancRanges['2nd_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Third ANC',
                            ancRanges['3rd_anc_start']!,
                            ancRanges['3rd_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'Fourth ANC',
                            ancRanges['4th_anc_start']!,
                            ancRanges['4th_anc_end']!,
                          ),
                          const SizedBox(width: 4),
                          _ancDateBox(
                            'PMAMA',
                            ancRanges['pmsma_start']!,
                            ancRanges['pmsma_end']!,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _ancDateRow(String label, DateTime startDate, DateTime endDate) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ancDateBox(String label, DateTime startDate, DateTime endDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDate(startDate)}\n${_formatDate(endDate)}',
            style: TextStyle(
              color: AppColors.background,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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