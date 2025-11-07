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
import '../HouseHole_Beneficiery/HouseHold_Beneficiery.dart';

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
  Map<String, dynamic>? _headForm;
  final List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    LocalStorageDao.instance.getAllBeneficiaries();
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
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final mapped = rows.map<Map<String, dynamic>>((r) {
        final info = Map<String, dynamic>.from((r['beneficiary_info'] as Map?) ?? const {});
        final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
        // spouse may be stored either under head_details.spousedetails or at top-level spouse_details
        final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? (info['spouse_details'] as Map?) ?? const {});
        // children may be stored at top-level children_details (preferred) or under head_details.childrenDetails/childrendetails
        final dynamic childrenRaw = info['children_details'] ?? head['childrenDetails'] ?? head['childrendetails'];
        final List childrenList = childrenRaw is List
            ? childrenRaw
            : childrenRaw is Map
                ? childrenRaw.values.whereType<Map>().toList()
                : const [];
        final String name = (head['headName'] ?? '').toString();
        final String mobile = (head['mobileNo'] ?? '').toString();
        int totalMembers = 1;
        if ((head['maritalStatus'] ?? '').toString() == 'Married' && spouse.isNotEmpty) totalMembers++;
        // Count children from stored children details, fallback to head.children numeric if details absent
        int childrenCount = childrenList.length;
        if (childrenCount == 0) {
          childrenCount = int.tryParse((head['children'] ?? '0').toString()) ?? 0;
        }
        totalMembers += childrenCount;
        final int eligibleCouples = (head['maritalStatus'] ?? '') == 'Married' ? 1 : 0;
        // Calculate elderly count (head and spouse, age 65+)
        int elderly = 0;
        DateTime? parseDob(String? dobStr) {
          if (dobStr == null || dobStr.isEmpty) return null;
          try {
            return DateTime.parse(dobStr);
          } catch (_) {
            return null;
          }
        }
        int calcAge(DateTime? dob) {
          if (dob == null) return 0;
          final now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
          return age;
        }
        final headDob = parseDob(head['dob']?.toString());
        final spouseDob = parseDob(spouse['dob']?.toString());
        if (calcAge(headDob) >= 65) elderly++;
        if (calcAge(spouseDob) >= 65) elderly++;
        return {
          'name': name,
          'mobile': mobile,
          'totalMembers': totalMembers,
          'eligibleCouples': eligibleCouples,
          'elderly': elderly,
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
            //     Builder(builder: (_) {
            //       final int childrenTarget = int.tryParse((_headForm?['children'] ?? '').toString()) ?? 0;
            //       final int childrenAdded = _members.where((m) {
            //         final t = (m['Type'] ?? '');
            //         final r = (m['Relation'] ?? '');
            //         return t == 'Child' || t == 'Infant' || r == 'Son' || r == 'Daughter';
            //       }).length;
            //       final int remaining = (childrenTarget - childrenAdded).clamp(0, 9999);
            //       if (childrenTarget <= 0) return const SizedBox.shrink();
            //       return Padding(
            //         padding: EdgeInsets.all(2.w),
            //         child: Container(
            //           color: AppColors.background,
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //             children: [
            //               Text(
            //                 "${l10n!.memberRemainsToAdd} :",
            //                 style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning, fontSize: 17.sp),
            //               ),
            //               Text(
            //                 '$remaining ',
            //                 style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 17.sp),
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     }),          SafeArea(
            // child: Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            //   child: SizedBox(
            //     width: double.infinity,
            //     height: 35,
            //     child: RoundButton(
            //       title: l10n?.gridRegisterNewHousehold.toUpperCase() ?? 'NEW HOUSEHOLD REGISTRATION',
            //       color: AppColors.primary,
            //       borderRadius: 8,
            //       height: 6.h,
            //       onPress: () {
            //         Navigator.pushNamed(context, Route_Names.RegisterNewHousehold);
            //         },
            //     ),
            //   ),
            // ),
          // ),
        ], 
      ),
    );
  }


  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell( 
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HouseHold_BeneficiaryScreen(
              houseNo: data['houseNo']?.toString(),
              hhId: data['_raw']['household_ref_key']?.toString() ?? '',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white, // full card base
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
            // Top section
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
                      (data['_raw']['household_ref_key']?.toString().length ?? 0) > 11 ? data['_raw']['household_ref_key'].toString().substring(data['_raw']['household_ref_key'].toString().length - 11) : (data['_raw']['household_ref_key']?.toString() ?? ''),
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp),
                    ),
                  ),
                  Text(
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${data['_raw']['beneficiary_info']?['head_details']?['houseNo'] ?? ''}',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 24,
                    child: RoundButton(
                      icon: Icons.edit,
                      iconSize: 14.sp,
                      title: l10n?.edit ?? 'Edit',
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
                                'houseNo': data['houseNo']?.toString() ?? '',
                                'name': data['name']?.toString() ?? '',
                                'mobile': data['mobile']?.toString() ?? '',
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
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(0)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child:
                          _rowText(l10n?.thName ?? 'Name', data['name'])),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.mobileLabelSimple ?? 'Mobile no.',
                              data['mobile'])),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.rnhTotalMembers ??
                                  'No. of total members',
                              data['totalMembers'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _rowText(
                              l10n?.eligibleCouples ?? 'Eligible couples',
                              data['eligibleCouples'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.pregnantWomen ?? 'Pregnant women',
                              data['pregnantWomen'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.elderlyAbove65 ?? 'Elderly (>65 Y)',
                              data['elderly'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _rowText(
                              l10n?.children0to1 ?? '0-1 year old children',
                              data['child0to1'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.children1to2 ?? '1-2 year old children',
                              data['child1to2'].toString())),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _rowText(
                              l10n?.children2to5 ?? '2-5 year old children',
                              data['child2to5'].toString())),
                    ],
                  ),
                ],
              ),
            ),


            if (data['hasChildrenTarget'] == true &&
                data['remainingChildren'] > 0)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border(
                      top: BorderSide(
                          color: AppColors.outlineVariant, width: 0.5)),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  '${l10n?.memberRemainsToAdd ?? 'Remaining to add'}: '
                      '${data['remainingChildren']} '
                      'member${data['remainingChildren'] > 1 ? 's' : ''}',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp),
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
