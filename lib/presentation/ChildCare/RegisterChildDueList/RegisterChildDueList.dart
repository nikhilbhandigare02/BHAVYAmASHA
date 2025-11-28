import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/database_provider.dart';
import '../RegisterChildDueListForm/RegisterChildDueListForm.dart';

class RegisterChildDueList extends StatefulWidget {
  const RegisterChildDueList({super.key});

  @override
  State<RegisterChildDueList> createState() => _RegisterChildDueListState();
}

class _RegisterChildDueListState extends State<RegisterChildDueList> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _childBeneficiaries = [];
  late List<Map<String, dynamic>> _filtered;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _childBeneficiaries = [];
    _loadChildBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChildBeneficiaries() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;

      // First, get all child care activities with registration_due status
      final List<Map<String, dynamic>> childActivities = await db.query(
        'child_care_activities',
        where: 'child_care_state = ?',
        whereArgs: ['registration_due'],
        orderBy: 'created_date_time DESC',
      );

      debugPrint('🎯 Found ${childActivities.length} child care activities with registration_due status');

      final childBeneficiaries = <Map<String, dynamic>>[];

      for (final activity in childActivities) {
        final beneficiaryRefKey = activity['beneficiary_ref_key']?.toString();
        final householdRefKey = activity['household_ref_key']?.toString();
        
        if (beneficiaryRefKey == null || householdRefKey == null) {
          debugPrint('⚠️ Skipping child care activity with null beneficiary_ref_key or household_ref_key');
          continue;
        }

        debugPrint('\n🔍 Processing child care activity for beneficiary: $beneficiaryRefKey');

        // Get the beneficiary record
        final List<Map<String, dynamic>> beneficiaryRows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ?',
          whereArgs: [beneficiaryRefKey],
          limit: 1,
        );

        if (beneficiaryRows.isEmpty) {
          debugPrint('⚠️ No beneficiary found for child care activity: $beneficiaryRefKey');
          continue;
        }

        final row = beneficiaryRows.first;
        
        // Parse beneficiary_info
        dynamic info;
        try {
          if (row['beneficiary_info'] is String) {
            info = jsonDecode(row['beneficiary_info'] as String);
          } else {
            info = row['beneficiary_info'];
          }
        } catch (e) {
          debugPrint('❌ Error parsing beneficiary_info: $e');
          continue;
        }

        if (info is! Map) {
          debugPrint('⚠️ beneficiary_info is not a Map, skipping');
          continue;
        }

        final memberData = Map<String, dynamic>.from(info);
        final memberType = memberData['memberType']?.toString() ?? '';

        debugPrint('📝 Member Type: "$memberType"');

        // Only process if memberType is "Child"
        if (memberType.toLowerCase() == 'child') {
          debugPrint('✅ Found Child member');

          final name = memberData['memberName']?.toString() ??
              memberData['name']?.toString() ??
              memberData['member_name']?.toString() ??
              memberData['memberNameLocal']?.toString() ??
              memberData['Name']?.toString() ?? '';

          debugPrint('👶 Child Name: "$name"');

          if (name.isEmpty) {
            debugPrint('⚠️ Skipping child with empty name');
            continue;
          }

          final isAlreadyRegistered = await _isChildRegistered(db, householdRefKey, name);

          if (isAlreadyRegistered) {
            debugPrint('⏭️ Child already registered: $name in household: $householdRefKey - SKIPPING');
            continue;
          }

          debugPrint('✅ Child NOT registered yet: $name - ADDING TO LIST');

          final fatherName = memberData['fatherName']?.toString() ?? '';
          final motherName = memberData['motherName']?.toString() ?? '';
          final mobileNo = memberData['mobileNo']?.toString() ?? '';
          final richId = memberData['RichIDChanged']?.toString() ?? '';
          final beneficiaryId = row['unique_key']?.toString() ?? '';

          final card = <String, dynamic>{
            'hhId': householdRefKey,
            'RegitrationDate': _formatDate(activity['created_date_time']?.toString() ?? row['created_date_time']?.toString()),
            'RegitrationType': 'Child',
            'BeneficiaryID': beneficiaryId,
            'RchID': richId,
            'Name': name,
            'Age|Gender': _formatAgeGender(memberData['dob'], memberData['gender']),
            'Mobileno.': mobileNo,
            'FatherName': fatherName,
            'MotherName': motherName,
            '_raw': row,
            '_memberData': memberData,
            '_activityData': activity,
          };

          debugPrint('📋 Created card: ${card['Name']}');
          childBeneficiaries.add(card);
        } else {
          debugPrint('⏭️ Skipping non-child member type: $memberType');
        }
      }

      debugPrint('\n📊 FINAL RESULTS:');
      debugPrint('Total children found: ${childBeneficiaries.length}');
      for (final child in childBeneficiaries) {
        debugPrint('  - ${child['Name']} (HH: ${child['hhId']})');
      }

      if (mounted) {
        setState(() {
          _childBeneficiaries = List<Map<String, dynamic>>.from(childBeneficiaries);
          _filtered = List<Map<String, dynamic>>.from(childBeneficiaries);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading child beneficiaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isChildRegistered(Database db, String hhId, String childName) async {
    try {
      final normalizedSearchName = childName.trim().toLowerCase();
      debugPrint('\n🔍 Checking registration for: "$childName" in household: "$hhId"');

      final results = await db.query(
        'followup_form_data',
        where: 'household_ref_key = ?',
        whereArgs: [hhId],
      );

      debugPrint('📊 Found ${results.length} form records for household: $hhId');

      if (results.isEmpty) {
        debugPrint('✅ No existing registration forms found');
        return false;
      }

      for (int i = 0; i <results.length; i++) {
        final row = results[i];
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) {
            continue;
          }

          final formData = jsonDecode(formJson);
          final formType = (formData['form_type']?.toString() ?? '').toLowerCase();

          if (formType != 'child_registration_due') {
            continue;
          }

          if (formData['form_data'] == null || formData['form_data'] is! Map) {
            continue;
          }

          final formDataMap = formData['form_data'] as Map<String, dynamic>;
          final childNameInForm = formDataMap['child_name']?.toString() ?? '';

          if (childNameInForm.isEmpty) {
            continue;
          }

          final normalizedStoredName = childNameInForm.trim().toLowerCase();

          if (normalizedStoredName == normalizedSearchName) {
            debugPrint('✅ MATCH FOUND! Child already registered');
            return true;
          }
        } catch (e) {
          debugPrint('❌ Error parsing form data: $e');
          continue;
        }
      }

      debugPrint('✅ No existing registration found');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking registration: $e');
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');

    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        String dateStr = dobRaw.toString();
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
          final now = DateTime.now();
          int years = now.year - dob.year;
          int months = now.month - dob.month;
          int days = now.day - dob.day;

          if (days < 0) {
            final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
            final lastMonthYear = now.month - 1 < 1 ? now.year - 1 : now.year;
            final daysInLastMonth = DateTime(lastMonthYear, lastMonth + 1, 0).day;
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
        debugPrint('Error parsing date of birth: $e');
      }
    }

    String displayGender;
    switch (gender) {
      case 'm':
      case 'male':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
        displayGender = 'Female';
        break;
      default:
        displayGender = 'Other';
    }

    return '$age | $displayGender';
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_childBeneficiaries);
      } else {
        _filtered = _childBeneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['FatherName']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['RchID']?.toString().toLowerCase() ?? '').contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.childRegisteredDueListTitle ?? 'Register Child Due List',
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
                hintText: l10n?.searchHintRegisterChildDueList ?? 'Search...',
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No children found for registration',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Children with "registration_due" status will appear here',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 12),
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
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
        onTap: () {
          final name = data['Name'] ?? '';
          final ageGender = data['Age|Gender']?.toString().split(' | ') ?? [];
          final gender = ageGender.length > 1 ? ageGender[1] : '';
          final mobile = data['Mobileno.'] ?? '';
          final hhId = data['hhId']?.toString() ?? '';

          final fatherName = data['FatherName'] ?? '';
          final beneficiaryId = (data['_raw'] is Map && (data['_raw']['unique_key'] != null))
              ? data['_raw']['unique_key'].toString()
              : (data['BeneficiaryID']?.toString() ?? '');

          final args = <String, dynamic>{
            'hhId': hhId,
            'name': name,
            'gender': gender,
            'mobile': mobile,

            'fatherName': fatherName,
            'beneficiaryId': beneficiaryId,
            'beneficiary_ref_key': beneficiaryId,
          };

          // Schedule the navigation for after the current build
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterChildDueListFormScreen(
                  arguments: args,
                ),
              ),
            );

            // Handle the result after navigation
            if (mounted && result != null && result is Map<String, dynamic>) {
              if (result['saved'] == true) {
                // Schedule the refresh after the current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _loadChildBeneficiaries();
                  }
                });
              }
            }
          });
        },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                   Icon(Icons.home, color: AppColors.primary, size: 15.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null && data['hhId'].toString().length > 11)
                          ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                          : (data['hhId']?.toString() ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sync, size: 24, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType'] ?? 'Child')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          (data['BeneficiaryID']?.toString().length ?? 0) > 11
                              ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11)
                              : (data['BeneficiaryID']?.toString() ?? 'N/A'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.nameLabelSimple ?? 'Name', data['Name'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender'] ?? 'N/A')),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(
                        l10n?.rchIdLabel ?? 'RCH ID',
                        data['RchID']?.isNotEmpty == true ? data['RchID'] : 'N/A',
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] : 'N/A',
                        ),
                      ),
                      const SizedBox(width: 140),
                      Expanded(
                        child: _rowText(
                          l10n?.fatherNameLabel ?? 'Father\'s Name',
                          data['FatherName']?.isNotEmpty == true ? data['FatherName'] : 'N/A',
                        ),
                      ),
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
    final Color primary = Theme.of(context).primaryColor;
    final bool isLight = primary.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}