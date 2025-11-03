import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:sizer/sizer.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';

import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import '../../HomeScreen/HomeScreen.dart';

class AllhouseholdScreen extends StatefulWidget {
  const AllhouseholdScreen({super.key});

  @override
  State<AllhouseholdScreen> createState() => _AllhouseholdScreenState();
}

class _AllhouseholdScreenState extends State<AllhouseholdScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
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
        _filtered = List<Map<String, dynamic>>.from(_items);
      } else {
        _filtered = _items.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['houseNo'] as String).toLowerCase().contains(q) ||
              (e['name'] as String).toLowerCase().contains(q) ||
              (e['mobile'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final rows = await LocalStorageDao.instance.getAllHouseholds();
    final mapped = rows.map<Map<String, dynamic>>((r) {
      final info = Map<String, dynamic>.from((r['household_info'] as Map?) ?? const {});
      final head = Map<String, dynamic>.from((info['headdetails'] as Map?) ?? const {});
      final spouse = Map<String, dynamic>.from((info['spousedetails'] as Map?) ?? const {});
      final List<dynamic> membersRaw = (info['memberdetails'] as List?) ?? const <dynamic>[];
      final List<Map<String, dynamic>> members = membersRaw
          .whereType<Map>()
          .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
          .toList();

      final String hhId = (r['unique_key'] ?? r['id']?.toString() ?? '').toString();
      final String houseNo = (head['houseNo'] ?? '').toString();
      final String name = (head['headName'] ?? '').toString();
      final String mobile = (head['mobileNo'] ?? '').toString();
      final int totalMembers = 1 + members.length + (spouse.isNotEmpty ? 1 : 0);

      final String headMarital = (head['maritalStatus'] ?? '').toString();
      final int eligibleCouples = headMarital == 'Married' ? (totalMembers - 1).clamp(0, totalMembers) : 0;

      int preg = 0;
      final List<Map<String, dynamic>> all = [head, if (spouse.isNotEmpty) spouse, ...members];
      for (final m in all) {
        final v = m['isPregnant'];
        if (v == 1 || v == 'Yes' || v == true) { preg = 1; break; }
      }

      int elderly = 0;
      int child0to1 = 0;
      int child1to2 = 0;
      int child2to5 = 0;
      for (final m in all) {
        int? ageYears;
        final String? dobIso = m['dob'] as String?;
        if (dobIso != null && dobIso.isNotEmpty) {
          final dob = DateTime.tryParse(dobIso);
          if (dob != null) {
            final now = DateTime.now();
            ageYears = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
            final ageMonths = (now.year - dob.year) * 12 + (now.month - dob.month) - (now.day < dob.day ? 1 : 0);
            if (ageMonths <= 12) child0to1++;
            else if (ageMonths <= 24) child1to2++;
            else if (ageMonths <= 60) child2to5++;
          }
        }
        ageYears ??= int.tryParse((m['approxAge'] ?? '').toString());
        if (ageYears != null && ageYears >= 65) elderly++;
      }

      return {
        'hhId': hhId,
        'houseNo': houseNo,
        'name': name,
        'mobile': mobile,
        'totalMembers': totalMembers,
        'eligibleCouples': eligibleCouples,
        'pregnantWomen': preg,
        'elderly': elderly,
        'child0to1': child0to1,
        'child1to2': child1to2,
        'child2to5': child2to5,
        '_raw': r,
      };
    }).toList();

      if (mounted) {
        setState(() {
          _items = mapped;
          _filtered = List<Map<String, dynamic>>.from(_items);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Optionally show error message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to load household data')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridAllHousehold ?? 'All Household',
        showBack: false,
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: CustomDrawer(),
      body: _isLoading
          ? const CenterBoxLoader()
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l10n?.searchHousehold ?? 'Household search',
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
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            ('No data found'),
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final data = _filtered[index];
                            return _householdCard(context, data);
                          },
                        ),
                ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 35,
                child: RoundButton(
                  title: l10n?.gridRegisterNewHousehold.toUpperCase() ?? 'NEW HOUSEHOLD REGISTRATION',
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 6.h,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.RegisterNewHousehold);
                    },
                ),
              ),
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
        Navigator.pushNamed(
          context,
          Route_Names.houseHoldBeneficiaryScreen,
          arguments: data,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
            boxShadow: [
              // Bottom shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, 2), // down
              ),
              // Top shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, -2), // up
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
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
                      data['hhId'] ?? '',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 14.sp),
                    ),
                  ),
                  Text(
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${data['houseNo']}',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 14.sp),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 24,
                    child: RoundButton(
                      icon: Icons.edit,
                      iconSize: 14.sp,
                      title:  l10n?.edit ?? 'Edit',
                      color: AppColors.primary,
                      borderRadius: 4,
                      height: 3.h,
                      fontSize: 14.sp,
                      onPress: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddNewFamilyHeadScreen(
                              isEdit: true,
                              initial: {
                                'houseNo': data['houseNo'],
                                'name': data['name'],
                                'mobile': data['mobile'],
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.thName ?? 'Name', data['name'])),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.mobileLabelSimple ?? 'Mobile no.', data['mobile'])),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.rnhTotalMembers ?? 'No. of total members', data['totalMembers'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.eligibleCouples ?? 'Eligible couples', data['eligibleCouples'].toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.pregnantWomen ?? 'Pregnant women', data['pregnantWomen'].toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.elderlyAbove65 ?? 'Elderly (>65 Y)', data['elderly'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.children0to1 ?? '0-1 year old children', data['child0to1'].toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.children1to2 ?? '1-2 year old children', data['child1to2'].toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText(l10n?.children2to5 ?? '2-5 year old children', data['child2to5'].toString())),
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
}
