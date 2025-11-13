import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import '../../../data/Local_Storage/database_provider.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../TrackEligibleCouple/TrackEligibleCoupleScreen.dart';

class UpdatedEligibleCoupleListScreen extends StatefulWidget {
  const UpdatedEligibleCoupleListScreen({super.key});

  @override
  State<UpdatedEligibleCoupleListScreen> createState() =>
      _UpdatedEligibleCoupleListScreenState();
}

class _UpdatedEligibleCoupleListScreenState
    extends State<UpdatedEligibleCoupleListScreen> {
  final TextEditingController _search = TextEditingController();
  int _tab = 0; // 0 = All, 1 = Protected, 2 = Unprotected
  List<Map<String, dynamic>> _households = [];
  Map<String, dynamic>? _initialData;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the arguments passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _initialData = args;
      print('📋 Received initial data: ${_initialData?.keys}');
      _processInitialData();
    }
    _loadCouples();
  }

  void _processInitialData() {
    if (_initialData == null) return;
    
    print('🔍 Processing initial data: ${_initialData?.keys}');

    
    if (_initialData?['searchTerm'] != null) {
      _search.text = _initialData!['searchTerm'].toString();
    }
    
    // If you need to select a specific tab based on the data
    if (_initialData?['status'] == 'Protected') {
      _tab = 1;
    } else if (_initialData?['status'] == 'Unprotected') {
      _tab = 2;
    }
  }

  Future<void> _loadCouples() async {
    setState(() { _isLoading = true; });
    print('🔍 Starting to load couples...');
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    print('📊 Total beneficiaries: ${rows.length}');
    final couples = <Map<String, dynamic>>[];

    // Group by household
    final households = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final hhKey = row['household_ref_key']?.toString() ?? '';
      households.putIfAbsent(hhKey, () => []).add(row);
    }
    print('🏠 Households found: ${households.length}');

    // Process each household
    int eligibleCount = 0;
    for (final household in households.values) {
      // Find head and spouse
      Map<String, dynamic>? head;
      Map<String, dynamic>? spouse;

      for (final member in household) {
        try {
          // Handle both String and Map types for beneficiary_info
          final dynamic infoRaw = member['beneficiary_info'];
          final Map<String, dynamic> info = infoRaw is String 
              ? jsonDecode(infoRaw) 
              : Map<String, dynamic>.from(infoRaw ?? {});
              
          final relation = (info['relation_to_head'] as String?)?.toLowerCase() ?? '';
          print('👥 Processing member: ${info['memberName'] ?? info['headName']} (Relation: $relation)');

          if (relation == 'self') {
            head = info;
            head!['_row'] = Map<String, dynamic>.from(member);
            print('  👤 Found head: ${head['memberName'] ?? head['headName']}');
          } else if (relation == 'spouse') {
            spouse = info;
            spouse!['_row'] = Map<String, dynamic>.from(member);
            print('  👥 Found spouse: ${spouse['memberName'] ?? spouse['headName']}');
          }
        } catch (e) {
          print('❌ Error processing household member: $e');
          if (e is Error) {
            print('Stack trace: ${e.stackTrace}');
          }
        }
      }

      // Check if head is eligible female
      if (head != null && _isEligibleFemale(head)) {
        final isFp = head['_row']?['is_family_planning'] == true ||
                   head['_row']?['is_family_planning'] == 1 ||
                   head['_row']?['is_family_planning']?.toString().toLowerCase() == 'yes';
        print('  ✅ Eligible head: ${head['memberName'] ?? head['headName']} (FP: $isFp)');
        final coupleData = _formatData(
          head['_row'] ?? {},
          head,
          spouse ?? {},
          isHead: true,
          isFamilyPlanning: isFp,
        );
        print('  📝 Added couple data: ${coupleData['Name']} (Protected: ${coupleData['is_family_planning']})');
        couples.add(coupleData);
        eligibleCount++;
      } else if (head != null) {
        print('  ❌ Ineligible head: ${head['memberName'] ?? head['headName']}');
        print('     Gender: ${head['gender']}, Marital: ${head['maritalStatus']}');
      }

      // Check if spouse is eligible female
      if (spouse != null && _isEligibleFemale(spouse)) {
        final isFp = spouse['_row']?['is_family_planning'] == true ||
                   spouse['_row']?['is_family_planning'] == 1 ||
                   spouse['_row']?['is_family_planning']?.toString().toLowerCase() == 'yes';
        print('  ✅ Eligible spouse: ${spouse['memberName'] ?? spouse['headName']} (FP: $isFp)');
        final coupleData = _formatData(
          spouse['_row'] ?? {},
          spouse,
          head ?? {},
          isHead: false,
          isFamilyPlanning: isFp,
        );
        print('  📝 Added couple data: ${coupleData['Name']} (Protected: ${coupleData['is_family_planning']})');
        couples.add(coupleData);
        eligibleCount++;
      } else if (spouse != null) {
        print('  ❌ Ineligible spouse: ${spouse['memberName'] ?? spouse['headName']}');
        print('     Gender: ${spouse['gender']}, Marital: ${spouse['maritalStatus']}');
      }
    }
    print('🏁 Finished processing. Found $eligibleCount eligible couples out of ${rows.length} beneficiaries');
    print('📋 Total couples: ${couples.length}');
    print('🔒 Protected: ${couples.where((c) => c['is_family_planning'] == true).length}');
    print('🔓 Unprotected: ${couples.where((c) => c['is_family_planning'] != true).length}');
    
    if (mounted) {
      setState(() {
        _households = couples;
        _isLoading = false;
        print('🔄 UI Updated with ${_households.length} couples');
        print('🔍 Current tab: ${_tab == 0 ? 'All' : _tab == 1 ? 'Protected' : 'Unprotected'}');
        print('🔍 Filtered count: ${_filtered.length}');
      });
    }
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    final isMarried = maritalStatusRaw == 'married';
    final dob = person['dob'];
    final age = _calculateAge(dob);
    return isFemale && isMarried && age >= 15 && age <= 49;
  }

  Map<String, dynamic> _formatData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> counterpart, {
    required bool isHead,
    bool isFamilyPlanning = false,
  }) {
    final hhId = (row['household_ref_key']?.toString() ?? '');
    final beneficiary_ref = (row['unique_key']?.toString() ?? '');
    final uniqueKey = (row['unique_key']?.toString() ?? '');
    final createdDate = row['created_date_time']?.toString() ?? '';
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final age = _calculateAge(female['dob']);
    final gender = (female['gender']?.toString().toLowerCase() ?? '');
    final displayAgeGender = age > 0
        ? '$age Y / ${gender == 'f' || gender == 'female' ? 'Female' : gender == 'm' || gender == 'male' ? 'Male' : 'Other'}'
        : 'N/A';
    final mobile = female['mobileNo']?.toString() ?? '';
    final husbandName = isHead
        ? (counterpart['memberName']?.toString() ?? counterpart['spouseName']?.toString() ?? '')
        : (counterpart['headName']?.toString() ?? counterpart['memberName']?.toString() ?? '');

    String last11(String s) => s.length > 11 ? s.substring(s.length - 11) : s;

    return {
      'hhId': last11(hhId),
      'beneficiary_ref': beneficiary_ref,
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': last11(uniqueKey),
      'Name': name,
      'age': displayAgeGender,
      'RichID': female['RichID']?.toString() ?? '',
      'mobileno': mobile,
      'HusbandName': husbandName,
      'status': isFamilyPlanning ? 'Protected' : 'Unprotected',
      'is_family_planning': isFamilyPlanning,
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

  bool _isProtected(Map<String, dynamic> data) {
    // Check is_family_planning flag (1 = true, 0 = false)
    if (data['is_family_planning'] == true || 
        data['is_family_planning'] == 1 || 
        data['is_family_planning']?.toString().toLowerCase() == 'yes') {
      return true;
    }
    
    // Check status field
    final status = data['status']?.toString().toLowerCase();
    if (status == 'protected') return true;
    
    // For backward compatibility, check other common protection status fields
    final dynamic raw = data['ProtectionStatus'] ??
        data['Protection'] ??
        data['protected'] ??
        data['isProtected'] ??
        data['Protected'] ??
        data['IsProtected'];

    if (raw is bool) return raw;
    if (raw == null) return false;
    final v = raw.toString().trim().toLowerCase();
    return v == 'protected' || v == 'y' || v == 'yes' || v == 'true' || v == '1';
  }

  List<Map<String, dynamic>> get _protectedList =>
      _households.where((e) => _isProtected(e)).toList();

  List<Map<String, dynamic>> get _unprotectedList =>
      _households.where((e) => !_isProtected(e)).toList();

  List<Map<String, dynamic>> get _filtered {
    print('🔄 Filtering couples (tab: $_tab)');
    List<Map<String, dynamic>> base;
    switch (_tab) {
      case 1:
        base = _protectedList;
        print('🔒 Showing protected list: ${base.length} items');
        break;
      case 2:
        base = _unprotectedList;
        print('🔓 Showing unprotected list: ${base.length} items');
        break;
      default:
        base = _households;
        print('📋 Showing all couples: ${base.length} items');
    }
    if (_search.text.isEmpty) return base;
    final q = _search.text.toLowerCase();
    return base
        .where((data) =>
            (data['Name']?.toString().toLowerCase().contains(q) ?? false) ||
            (data['HusbandName']?.toString().toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: t?.updatedEligibleCoupleListTitle ?? 'Updated Eligible Couple List',
        showBack: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Box
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t?.updatedEligibleCoupleSearchHint ?? 'Search Updated Eligible Couple',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
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

            // 🟦 Tabs
            Padding(
              padding:  EdgeInsets.only(left: 12.0, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TabChip(
                    label: '${t?.tabAll ?? 'ALL'} (${_households.length})',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _TabChip(
                    label: '${t?.tabProtected ?? 'PROTECTED'} (${_protectedList.length})',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                  _TabChip(
                    label: '${t?.tabUnprotected ?? 'UNPROTECTED'} (${_unprotectedList.length})',
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _filtered.isNotEmpty
                  ? ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _householdCard(context, data);
                },
              )
                  : Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 40, horizontal: 16),
                  child: Text(
                    t?.noRecordFound ?? 'No Record Found.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: () async {
        final isProtected = _isProtected(data);
        final result = await Navigator.push(
          context,
          TrackEligibleCoupleScreen.route(
            beneficiaryId: data['BeneficiaryID'].toString(),
            isProtected: isProtected,
            beneficiaryRefKey: data['beneficiary_ref']?.toString(),
          ),
        );
        
        if (result == true && mounted) {
          await _loadCouples();
        }
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
                      data['hhId']?.toString() ?? '',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data['status'] ?? '',
                      style:  TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      Expanded(child: _rowText(t?.registrationDateLabel ?? 'Registration Date', data['RegistrationDate']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.registrationTypeLabel ?? 'Registration Type', data['RegistrationType']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryID']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(t?.nameOfMemberLabel ?? 'Name', data['Name']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.ageLabelSimple ?? 'Age', data['age']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.richIdLabel ?? 'Rich ID', data['RichID']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(t?.mobileLabelSimple ?? 'Mobile No.', data['mobileno']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(t?.spouseNameLabel ?? 'Husband Name', data['HusbandName']?.toString() ?? '')),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.85),
            fontSize: 14.sp,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.primary;
    final unselectedBorder = AppColors.outlineVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? selectedColor : unselectedBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
