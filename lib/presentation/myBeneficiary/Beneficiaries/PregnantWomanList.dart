import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'dart:convert';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/local_storage_dao.dart';

class PregnantWomenList extends StatefulWidget {
  const PregnantWomenList({super.key});

  @override
  State<PregnantWomenList> createState() => _PregnantWomenListState();
}

class _PregnantWomenListState extends State<PregnantWomenList> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

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

  Future<void> _loadPregnantWomen() async {
    setState(() { _isLoading = true; });
    
    try {
      final db = await DatabaseProvider.instance.database;
      final allBeneficiaries = await db.query('beneficiaries_new');
      final pregnantList = <Map<String, dynamic>>[];
      
      for (final row in allBeneficiaries) {
        try {
          final info = row['beneficiary_info'] is String 
              ? jsonDecode(row['beneficiary_info'] as String) 
              : (row['beneficiary_info'] as Map?) ?? {};
              
          if (_isPregnant(Map<String, dynamic>.from(info))) {
            pregnantList.add(_formatCardData(row, info));
          }
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }
      
      setState(() {
        _filtered = pregnantList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pregnant women: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isPregnant(Map<String, dynamic> person) {
    final flag = person['isPregnant']?.toString().toLowerCase();
    final typoFlag = person['isPregrant']?.toString().toLowerCase();
    final statusFlag = person['pregnancyStatus']?.toString().toLowerCase();
    return flag == 'yes' || typoFlag == 'yes' || statusFlag == 'pregnant';
  }
  Map<String, dynamic> _formatCardData(Map<String, dynamic> row, Map<String, dynamic> person) {
    try {
      final name = person['memberName']?.toString() ?? person['headName']?.toString() ?? '';

      final gender = person['gender']?.toString().trim().toLowerCase() ?? '';
      
      // Map gender to display format
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
      
      // Calculate age
      final age = _calculateAge(person['dob']);
      
      return {
        'hhId': row['household_ref_key']?.toString() ?? '',
        'name': name,
        'age_gender': '${age > 0 ? '$age Y' : 'N/A'} | $displayGender',
        'status': 'ANC DUE',
      };
    } catch (e) {
      print('Error formatting card data: $e');
      return {
        'hhId': row['household_ref_key']?.toString() ?? '',
        'name': 'Error loading data',
        'age_gender': 'N/A | N/A',
        'status': 'ERROR',
      };
    }
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

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _loadPregnantWomen();
      } else {
        _filtered = _filtered.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['name'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Pregnant Women List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [


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
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        // Navigator.pushNamed(context, Route_Names.FamliyUpdate);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, color: Colors.black54, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (data['hhId']?.toString().length ?? 0) > 11 ? data['hhId'].toString().substring(data['hhId'].toString().length - 11) : (data['hhId'] ?? ''),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      data['name'] ?? 'N/A',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _infoRow(
                    '',
                    data['age_gender'] ?? 'N/A | N/A',
                    isWrappable: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String? title, String value,{bool isWrappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$title ',
            style:  TextStyle(
              color: AppColors.background,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}