import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';

class UpdatedEligibleCoupleListScreen extends StatefulWidget {
  const UpdatedEligibleCoupleListScreen({super.key});

  @override
  State<UpdatedEligibleCoupleListScreen> createState() =>
      _UpdatedEligibleCoupleListScreenState();
}

class _AutofillCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController richIdCtrl;
  final TextEditingController ageAtMarriageCtrl;
  final TextEditingController villageCtrl;
  final TextEditingController mohallaCtrl;
  final TextEditingController mobileCtrl;
  final String? mobileOwner;
  final String? religion;
  final String? category;
  final void Function(String? owner, String? religion, String? category) onChanged;
  final Map<String, dynamic>? childrenSummary;

  const _AutofillCard({
    required this.nameCtrl,
    required this.richIdCtrl,
    required this.ageAtMarriageCtrl,
    required this.villageCtrl,
    required this.mohallaCtrl,
    required this.mobileCtrl,
    required this.mobileOwner,
    required this.religion,
    required this.category,
    required this.onChanged,
    required this.childrenSummary,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ownerOptions = <String>['Self', 'Husband', 'Father', 'Other'];
    final religionOptions = <String>['Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 'Jain', 'Other'];
    final categoryOptions = <String>['SC', 'ST', 'OBC', 'General', 'Other'];
    String? owner = mobileOwner;
    String? rel = religion;
    String? cat = category;
    if (owner != null && !ownerOptions.contains(owner)) ownerOptions.add(owner);
    if (rel != null && !rel.isEmpty && !religionOptions.contains(rel)) religionOptions.add(rel);
    if (cat != null && !cat.isEmpty && !categoryOptions.contains(cat)) categoryOptions.add(cat);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t?.updatedEligibleCoupleListTitle ?? 'Updated Eligible Couple', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(t?.nameOfMemberLabel ?? 'Name', nameCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _tf(t?.richIdLabel ?? 'Rich ID', richIdCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _tf(t?.ageAtMarriageLabel ?? 'Age At Marriage', ageAtMarriageCtrl, keyboard: TextInputType.number)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tf(t?.villageLabel ?? 'Village', villageCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _tf(t?.mohallaTolaNameLabel ?? 'Tola/Mohalla', mohallaCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _tf(t?.mobileLabelSimple ?? 'Mobile No.', mobileCtrl, keyboard: TextInputType.phone)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _dd('Mobile Owner', ownerOptions, owner, (v){ owner = v; onChanged(owner, rel, cat); })),
              const SizedBox(width: 12),
              Expanded(child: _dd(t?.religionLabel ?? 'Religion', religionOptions, rel, (v){ rel = v; onChanged(owner, rel, cat); })),
              const SizedBox(width: 12),
              Expanded(child: _dd(t?.categoryLabel ?? 'Category', categoryOptions, cat, (v){ cat = v; onChanged(owner, rel, cat); })),
            ]),
            if (childrenSummary != null) ...[
              const SizedBox(height: 10),
              Text('Children Details', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 6, children: [
                _badge('Total Born', (childrenSummary!['totalBorn'] ?? '').toString()),
                _badge('Total Live', (childrenSummary!['totalLive'] ?? '').toString()),
                _badge('Male', (childrenSummary!['totalMale'] ?? '').toString()),
                _badge('Female', (childrenSummary!['totalFemale'] ?? '').toString()),
                _badge('Youngest', [childrenSummary!['youngestAge'], childrenSummary!['ageUnit']].where((e) => (e ?? '').toString().isNotEmpty).join(' ')),
                _badge('Gender', (childrenSummary!['youngestGender'] ?? '').toString()),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController c, {TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 4),
      TextField(controller: c, keyboardType: keyboard, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
    ]);
  }

  Widget _dd(String label, List<String> options, String? value, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: value != null && options.contains(value) ? value : (options.contains('Other') ? 'Other' : null),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      ),
    ]);
  }

  Widget _badge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Text(value.isEmpty ? 'N/A' : value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _UpdatedEligibleCoupleListScreenState extends State<UpdatedEligibleCoupleListScreen> with WidgetsBindingObserver {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _richIdCtrl = TextEditingController();
  final TextEditingController _ageAtMarriageCtrl = TextEditingController();
  final TextEditingController _villageCtrl = TextEditingController();
  final TextEditingController _mohallaCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  String? _mobileOwner;
  String? _religion;
  String? _category;
  Map<String, dynamic>? _childrenSummary;
  List<Map<String, dynamic>> _allCouples = [];
  int _selectedTab = 0;
  bool _isLoading = true;
  Map<dynamic, dynamic>? _navArgs;

  @override
  void initState() {
    super.initState();
    print('\n🔵 ====== INIT STATE CALLED ======');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  @override
  void didChangeDependencies() {
    print('\n🔵 ====== DID CHANGE DEPENDENCIES CALLED ======');
    super.didChangeDependencies();
    print('🔵 Getting route arguments...');
    final route = ModalRoute.of(context);
    print('🔵 Route found: ${route != null}');
    
    if (route == null) {
      print('❌ ERROR: ModalRoute is null!');
      return;
    }
    
    print('🔵 Route settings: ${route.settings}');
    final args = route.settings.arguments;
    print('🔵 Arguments found: ${args != null}');
    print('\n🟢 ====== DID CHANGE DEPENDENCIES ======');
    print('🟢 Received args type: ${args?.runtimeType}');
    
    if (args != null) {
      print('🟢 Args keys: ${args is Map ? (args as Map).keys.join(', ') : 'Not a Map'}');
      print('🟢 Args content: $args');
    } else {
      print('🟢 No arguments received');
    }
    
    if (args is Map && _navArgs == null) {
      try {
        // Convert args to Map<String, dynamic>
        final Map<String, dynamic> typedArgs = args.map((key, value) => 
          MapEntry(key.toString(), value));
          
        _navArgs = Map<dynamic, dynamic>.from(typedArgs);
        print('🟢 _navArgs set with ${_navArgs?.length} items');
        
        final preFilter = typedArgs['preFilter'] as String?;
        if (preFilter != null && preFilter.isNotEmpty) {
          _search.text = preFilter;
          print('🟢 Set search filter: $preFilter');
        }
        
        _processNavigationData(typedArgs);
      } catch (e) {
        print('❌ ERROR in didChangeDependencies: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } else {
      print('ℹ️ Skipping _processNavigationData - args is not a Map or _navArgs already set');
    }
    
    print('🔵 Calling _loadCouples()');
    _loadCouples();
    
    // Force a rebuild to ensure we catch any missing data
    if (mounted) {
      print('🔵 Forcing rebuild...');
      setState(() {});
    }
  }

  // Helper method to safely get string from dynamic map
  String safeGetString(dynamic map, String key) {
    if (map is Map && map[key] != null) {
      return map[key].toString();
    }
    return '';
  }

  void _processNavigationData(Map<String, dynamic> args) {
    try {
      print('\n🔍 ====== PROCESSING NAVIGATION DATA ======');
      print('🔍 Args type: ${args.runtimeType}');
      print('🔍 Args content: $args');
      
      // Extract all possible fields with null safety using safeGetString
      final name = safeGetString(args, 'Name');
      final richId = safeGetString(args, 'RichID');
      final mobileNo = safeGetString(args, 'mobileNo');
      final village = safeGetString(args, 'village');
      final mohalla = safeGetString(args, 'mohalla');
      final mobileOwner = safeGetString(args, 'mobileOwner');
      final religion = safeGetString(args, 'religion');
      final category = safeGetString(args, 'category');
      final caste = safeGetString(args, 'caste');
      
      // Update the form fields
      _nameCtrl.text = name;
      _richIdCtrl.text = richId;
      _mobileCtrl.text = mobileNo;
      _villageCtrl.text = village;
      _mohallaCtrl.text = mohalla;
      _mobileOwner = mobileOwner.isNotEmpty ? mobileOwner : 'Self';
      _religion = religion;
      _category = category.isNotEmpty ? category : caste;
      
      // Handle children details if available
      if (args['childrenSummary'] != null) {
        try {
          final childrenMap = Map<String, dynamic>.from(args['childrenSummary'] as Map);
          _childrenSummary = {
            'totalBorn': childrenMap['totalBorn'],
            'totalLive': childrenMap['totalLive'],
            'totalMale': childrenMap['totalMale'],
            'totalFemale': childrenMap['totalFemale'],
            'youngestAge': childrenMap['youngestAge'],
            'ageUnit': childrenMap['ageUnit'],
            'youngestGender': childrenMap['youngestGender'],
          }..removeWhere((k, v) => v == null);
          print('👶 Children summary updated');
        } catch (e) {
          print('⚠️ Error parsing children details: $e');
          _childrenSummary = null;
        }
      } else {
        _childrenSummary = null;
      }
      
      // Log the updated values
      print('✅ Form fields updated:');
      print('   👤 Name: $name');
      print('   🆔 Rich ID: $richId');
      print('   📱 Mobile: $mobileNo (Owner: $_mobileOwner)');
      print('   🏠 Village: $village');
      print('   🏘️ Mohalla: $mohalla');
      print('   🕯️ Religion: $religion');
      print('   🏷️ Category: ${_category}');
      print('   👶 Children Summary: ${_childrenSummary?.keys.join(', ') ?? 'None'}');
      
      // Force UI update
      if (mounted) {
        setState(() {});
      };
      print('📱 Mobile: ${_mobileCtrl.text} (Owner: $_mobileOwner)');
      print('🛐 Religion: $_religion');
      print('🏷️ Category: $_category');
      
      setState(() {});

    } catch (e) {
      print('❌ ERROR in _processNavigationData: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadCouples() async {
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    final List<Map<String, dynamic>> couples = [];
    for (final row in rows) {
      final rowMap = Map<String, dynamic>.from(row as Map);
      final info = Map<String, dynamic>.from((rowMap['beneficiary_info'] as Map?) ?? const <String, dynamic>{});
      final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const <String, dynamic>{});
      final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const <String, dynamic>{});

      // Female eligible in head
      if (_isEligibleFemale(head)) {
        couples.add(_formatData(row, head, spouse, isHead: true));
      }
      // Female eligible in spouse
      if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
        couples.add(_formatData(row, spouse, head, isHead: false));
      }
    }
    if (mounted) {
      setState(() {
        _allCouples = couples;
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

  Map<String, dynamic> _formatData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> counterpart, {required bool isHead}) {
    final hhId = (row['household_ref_key']?.toString() ?? '');
    final uniqueKey = (row['unique_key']?.toString() ?? '');
    final createdDate = row['created_date_time']?.toString() ?? '';
    final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const <String, dynamic>{});
    final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const <String, dynamic>{});
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

    // children summary (top-level children_details or head childrendetails/childrenDetails)
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
      'hhId': last11(hhId),
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': last11(uniqueKey),
      'Name': name,
      'age': displayAgeGender,
      'RichID': female['RichID']?.toString() ?? '',
      'mobileno': mobile,
      'HusbandName': husbandName,
      'status': 'Unprotected',
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

  bool _isProtected(Map<String, dynamic> data) {
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
      _allCouples.where((e) => _isProtected(e)).toList();

  List<Map<String, dynamic>> get _unprotectedList =>
      _allCouples.where((e) => !_isProtected(e)).toList();

  List<Map<String, dynamic>> get _filteredCouples {
    List<Map<String, dynamic>> base;
    switch (_selectedTab) {
      case 1:
        base = _protectedList;
        break;
      case 2:
        base = _unprotectedList;
        break;
      default:
        base = _allCouples;
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
    _nameCtrl.dispose();
    _richIdCtrl.dispose();
    _ageAtMarriageCtrl.dispose();
    _villageCtrl.dispose();
    _mohallaCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: t?.updatedEligibleCoupleListTitle ?? 'Eligible Couple List',
        showBack: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_navArgs != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: _AutofillCard(
                  nameCtrl: _nameCtrl,
                  richIdCtrl: _richIdCtrl,
                  ageAtMarriageCtrl: _ageAtMarriageCtrl,
                  villageCtrl: _villageCtrl,
                  mohallaCtrl: _mohallaCtrl,
                  mobileCtrl: _mobileCtrl,
                  mobileOwner: _mobileOwner,
                  religion: _religion,
                  category: _category,
                  onChanged: (owner, rel, cat) {
                    setState(() {
                      _mobileOwner = owner;
                      _religion = rel;
                      _category = cat;
                    });
                  },
                  childrenSummary: _childrenSummary,
                ),
              ),
            ],
            // 🔍 Search Box
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _search,
                onChanged: (value) {
                  setState(() {
                    _allCouples = _allCouples
                    .where((couple) => couple['Name']
                        .toString()
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                    .toList();
                  });
                },
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
                    label: '${t?.tabAll ?? 'ALL'} (${_allCouples.length})',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _TabChip(
                    label: '${t?.tabProtected ?? 'PROTECTED'} (${_protectedList.length})',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                  _TabChip(
                    label: '${t?.tabUnprotected ?? 'UNPROTECTED'} (${_unprotectedList.length})',
                    selected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _filteredCouples.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          t?.noRecordFound ?? 'No Record Found.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCouples.length,
                      itemBuilder: (context, index) {
                        return _householdCard(context, _filteredCouples[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 📦 Household Card
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Route_Names.TrackEligibleCoupleScreen,
          arguments: data,
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
