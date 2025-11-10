import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/presentation/MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../OutcomeForm/OutcomeForm.dart';

class HBNCListScreen extends StatefulWidget {
  const HBNCListScreen({super.key});

  @override
  State<HBNCListScreen> createState() =>
      _HBNCListScreenState();
}

class _HBNCListScreenState
    extends State<HBNCListScreen> {
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

  Future<void> _loadPregnancyOutcomeeCouples() async {
    setState(() { _isLoading = true; });

    try {
      final deliveryOutcomes = await SecureStorageService.getDeliveryOutcomes();

      final submittedBeneficiaryIds = <String>{};

      for (var outcome in deliveryOutcomes) {
        final isSubmitted = outcome['isSubmit'] == true;
        final beneficiaryId = outcome['beneficiaryId']?.toString();

        if (isSubmitted && beneficiaryId != null) {
          final id = beneficiaryId.length >= 11
              ? beneficiaryId.substring(beneficiaryId.length - 11)
              : beneficiaryId;
          submittedBeneficiaryIds.add(id);
        }
      }

      if (submittedBeneficiaryIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _filtered = [];
        });
        return;
      }

      // Get all beneficiaries and filter them
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final couples = <Map<String, dynamic>>[];

      for (final row in rows) {
        final uniqueKey = row['unique_key']?.toString() ?? '';

        // Check if this beneficiary is in our birthBeneficiaryIds set
        // Check if this beneficiary is in our submitted outcomes
        final beneficiaryId = uniqueKey.length >= 11
            ? uniqueKey.substring(uniqueKey.length - 11)
            : uniqueKey;

        if (submittedBeneficiaryIds.contains(beneficiaryId)) {
          final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
          final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
          final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});

          if (_isEligibleFemale(head)) {
            couples.add(_formatCoupleData(row, head, spouse, isHead: true));
          }

          if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
            couples.add(_formatCoupleData(row, spouse, head, isHead: false));
          }
        }
      }

      setState(() {
        _filtered = couples;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading pregnancy outcome couples: $e');
      setState(() {
        _isLoading = false;
        _filtered = [];
      });
    }
  }
  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final gender = genderRaw == 'f' || genderRaw == 'female';
    final maritalStatus = maritalStatusRaw == 'married';
    final dob = person['dob'];
    final age = _calculateAge(dob);
    return gender && maritalStatus && age >= 15 && age <= 49;
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['created_date_time']?.toString() ?? '';
    final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
    final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender == 'f' ? 'Female' : gender == 'm' ? 'Male' : 'Other';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? '';
    final mobile = female['mobileNo']?.toString() ?? '';
    final husbandName = isHead
        ? (headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString() ?? '')
        : (headOrSpouse['headName']?.toString() ?? headOrSpouse['memberName']?.toString() ?? '');

    final dynamic childrenRaw = info['children_details'] ?? head['childrendetails'] ?? head['childrenDetails'];
    Map<String, dynamic>? childrenSummary;
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
    return {
      'hhId': hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId,
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey,
      'Name': name,
      'age': age > 0 ? '$age Y / $displayGender' : 'N/A',
      'RichID': richId,
      'mobileno': mobile,
      'HusbandName': husbandName,
      'childrenSummary': childrenSummary,
      '_rawRow': row,
    };
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
    if (dateStr.isEmpty) return '';
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
        _loadPregnancyOutcomeeCouples();
      } else {
        _filtered = _filtered.where((e) {
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['Name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobileno'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<int> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getVisitCount');
        return 0;
      }

      print('🔍 Getting visit count for beneficiary: $beneficiaryId');
      final count = await SecureStorageService.getVisitCount(beneficiaryId);
      print('📊 Retrieved count for $beneficiaryId: $count');

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
                hintText: l10n?.searchEligibleCouple ?? 'search Eligible Couple',
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
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    final rowData = data['_rawRow'] ?? {};
    final beneficiaryInfo = rowData['beneficiary_info'] is String
        ? jsonDecode(rowData['beneficiary_info'])
        : (rowData['beneficiary_info'] ?? {});



    final beneficiaryId = (data['_rawRow']?['unique_key'] ?? '').toString();
    final formattedBeneficiaryId = beneficiaryId.length >= 11
        ? beneficiaryId.substring(beneficiaryId.length - 11)
        : beneficiaryId;

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

            if (data['_rawRow'] is Map) {
              final rawRow = data['_rawRow'] as Map;
              beneficiaryData['unique_key'] = rawRow['unique_key'];
              beneficiaryData['BeneficiaryID'] = rawRow['BeneficiaryID'];

              print('🔑 Passing to form:');
              print('   - unique_key: ${beneficiaryData['unique_key']}');
              print('   - BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HbncVisitScreen(beneficiaryData: beneficiaryData),
              ),
            );
          },

          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
                          data['hhId'] ?? '',
                          style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<int>(
                        future: _getVisitCount(beneficiaryId),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '${t?.visitsLabel ?? 'Visits:'} $count',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          );
                        },
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
                          Expanded(child: _rowText('Registration Date', data['RegistrationDate'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Registration Type', data['RegistrationType'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Rich ID', data['RichID']?.toString() ?? '')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _rowText(  'Name', data['Name'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText( 'Age', data['age']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _rowText('Husband Name', data['HusbandName'] ?? '')),                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _rowText( 'Mobile No.', data['mobileno']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _rowText('Previous Pnc Date', data['RegistrationDate'] ?? '')),
                          Expanded(
                              child: _rowText('Next Pnc Date', data['RegistrationDate'] ?? '')),
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
}
