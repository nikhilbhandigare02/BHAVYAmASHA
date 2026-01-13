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

  String _getMemberTypeFromAgeGender(String ageString, String gender) {
    // Extract numeric age from age string
    int age = 0;
    if (ageString != 'Not Available') {
      if (ageString.contains('Y') || ageString.contains('years')) {
        final match = RegExp(r'\d+').firstMatch(ageString);
        age = int.tryParse(match?.group(0) ?? '0') ?? 0;
      } else if (ageString.contains('M')) {
        age = 0;
      } else if (ageString.contains('D')) {
        age = 0;
      }
    }

    if (age >= 15) {
      return gender == 'Female' ? 'Pregnant Women' : 'Adult';
    } else {
      return 'Child';
    }
  }

  String _getLocalizedMemberType(String memberType, AppLocalizations? l10n) {
    switch (memberType.toLowerCase()) {
      case 'adult':
        return l10n?.badgeAdult ?? 'Adult';
      case 'child':
        return l10n?.badgeChild ?? 'Child';
      case 'pregnant women':
        return l10n?.pregnantWomen ?? 'Pregnant Women';
      default:
        return memberType; // Return the original value if no match
    }
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
          print(
            '🔄 [DeathRegister] State updated with ${_deathRecords.length} records',
          );
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
          _isLoading
              ? const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    // Extract data with null safety
    final beneficiaryInfo = data['beneficiary_info'] is Map
        ? Map<String, dynamic>.from(data['beneficiary_info'])
        : {};
    final deathDetails = data['death_details'] is Map
        ? Map<String, dynamic>.from(data['death_details'])
        : {};

    // Parse beneficiary info
    final name =
        beneficiaryInfo['memberName'] ??
            beneficiaryInfo['headName'] ??
            beneficiaryInfo['name'] ??
            'Unknown';

    // Calculate age from DOB to date of death if available using same logic as RegisterChildListScreen
    String age = 'Not Available';
    if (beneficiaryInfo['dob'] != null) {
      try {
        String dateStr = beneficiaryInfo['dob'].toString();
        DateTime? dob;

        dob = DateTime.tryParse(dateStr);

        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }

        if (dob != null) {
          // Parse date of death for age calculation
          DateTime? deathDate;
          String deathDateStr = (deathDetails['date_of_death'] ??
              deathDetails['deathDate'] ??
              deathDetails['dateOfDeath'] ??
              beneficiaryInfo['date_of_death'] ??
              beneficiaryInfo['deathDate'] ??
              beneficiaryInfo['dateOfDeath'] ?? '').toString();
          
          if (deathDateStr.isNotEmpty && deathDateStr != '') {
            deathDate = DateTime.tryParse(deathDateStr);
            
            if (deathDate == null) {
              final timestamp = int.tryParse(deathDateStr);
              if (timestamp != null && timestamp > 0) {
                deathDate = DateTime.fromMillisecondsSinceEpoch(
                  timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                  isUtc: true,
                );
              }
            }
          }
          
          // If death date not found, try modified_date_time from data record
          if (deathDate == null && data['modified_date_time'] != null) {
            try {
              final modifiedDateStr = data['modified_date_time'].toString();
              print('🔍 Debug: DeathRegister modified_date_time = $modifiedDateStr');
              if (modifiedDateStr.isNotEmpty) {
                deathDate = DateTime.tryParse(modifiedDateStr);
                
                if (deathDate == null) {
                  final timestamp = int.tryParse(modifiedDateStr);
                  if (timestamp != null && timestamp > 0) {
                    deathDate = DateTime.fromMillisecondsSinceEpoch(
                      timestamp > 1000000000000 ? timestamp : timestamp * 1000,
                      isUtc: true,
                    );
                    print('✅ Debug: DeathRegister successfully parsed as timestamp: $deathDate');
                  }
                } else {
                  print('✅ Debug: DeathRegister successfully parsed as date: $deathDate');
                }
              }
            } catch (e) {
              print('❌ Debug: DeathRegister error parsing modified_date_time: $e');
            }
          }

          final referenceDate = deathDate ?? DateTime.now();
          
          int years = referenceDate.year - dob.year;
          int months = referenceDate.month - dob.month;
          int days = referenceDate.day - dob.day;

          if (days < 0) {
            final lastMonth = referenceDate.month - 1 < 1 ? 12 : referenceDate.month - 1;
            final lastMonthYear = referenceDate.month - 1 < 1 ? referenceDate.year - 1 : referenceDate.year;
            final daysInLastMonth = DateTime(
              lastMonthYear,
              lastMonth + 1,
              0,
            ).day;
            days += daysInLastMonth;
            months--;
          }

          if (months < 0) {
            months += 12;
            years--;
          }

          if (years > 0) {
            age = '$years Y';
          } else if (months > 0) {
            age = '$months M';
          } else {
            age = '$days D';
          }
        }
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    } else if (beneficiaryInfo['age'] != null) {
      age = '${beneficiaryInfo['age']} years';
    }

    final genderRaw = (beneficiaryInfo['gender'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final gender = genderRaw == 'm' || genderRaw == 'male'
        ? 'Male'
        : genderRaw == 'f' || genderRaw == 'female'
        ? 'Female'
        : 'Other';
    final hhId = data['household_ref_key']?.toString() ?? 'N/A';
    final uniqueKey = data['unique_key']?.toString() ?? '';

    final deathDate =
        deathDetails['date_of_death'] ??
            deathDetails['deathDate'] ??
            deathDetails['dateOfDeath'] ??
            beneficiaryInfo['date_of_death'] ??
            beneficiaryInfo['deathDate'] ??
            beneficiaryInfo['dateOfDeath'] ??
            data['modified_date_time'] ??
            '';
    final deathPlace =
        deathDetails['death_place'] ??
            deathDetails['deathPlace'] ??
            beneficiaryInfo['death_place'] ??
            beneficiaryInfo['deathPlace'] ??
            '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
                      (hhId.length) > 11
                          ? hhId.substring(hhId.length - 11)
                          : hhId,
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getLocalizedMemberType(_getMemberTypeFromAgeGender(age, gender), l10n),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText('', name)),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('', "Date :${_formatDate(deathDate)}")),


                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _rowText('', '$age | $gender')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('', "${l10n?.place_of_death}: ${deathPlace}")),
                    ],
                  ),
                ],
              ),
            ),
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
          style:  TextStyle(color: AppColors.background, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 13.sp),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.tryParse(dateString);
      if (date == null) return dateString;
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
