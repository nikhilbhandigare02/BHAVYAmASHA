import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

class Routinescreen extends StatefulWidget {
  const Routinescreen({super.key});

  @override
  State<Routinescreen> createState() => _RoutinescreenState();
}

class _RoutinescreenState extends State<Routinescreen> {
  final Map<String, bool> _expanded = {};
  bool _isLoading = true;

  List<Map<String, dynamic>> _pwList = [];
  final List<Map<String, dynamic>> _child0to1 = [];
  final List<Map<String, dynamic>> _child1to2 = [];
  final List<Map<String, dynamic>> _child2to5 = [];
  final List<Map<String, dynamic>> _poornTikakaran = [];
  final List<Map<String, dynamic>> _sampoornTikakaran = [];

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _loadSampoornTikakaran();
    _loadPoornTikakaran();
    _loadChild0to1();
    _loadChild1to2();
    _loadChild2to5();
  }

  Future<void> _loadSampoornTikakaran() async {
    print('Starting to load Sampoorn Tikakaran data...');
    try {
      print('Calling getChildTrackingDueFor16Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor16Year();
      print('Received ${rows.length} rows from database');

      setState(() {
        _sampoornTikakaran.clear();
        for (var row in rows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map ?
          (formData['form_data'] ?? formData) :
          formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _sampoornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _sampoornTikakaran: ${_sampoornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadSampoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadPregnantWomen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];

      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print('Error parsing beneficiary_info: $e');
            continue;
          }

          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final gender = info['gender']?.toString().toLowerCase() ?? '';
          if (gender != 'f' && gender != 'female') continue;

          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final age = _calculateAge(info['dob']);
          final mobile = info['mobileNo'] ?? '';
          final lmp = info['lmp']?.toString();


          Map<String, DateTime> ancDates = {};
          String nextVisit = 'N/A';
          if (lmp != null && lmp.isNotEmpty) {
            try {
              final lmpDate = DateTime.tryParse(lmp.split('T')[0]);
              if (lmpDate != null) {
                ancDates = _calculateAncDateRanges(lmpDate);
                nextVisit = _getNextVisitDate(ancDates);  // Now nextVisit is properly initialized
              }
            } catch (e) {
              print('Error calculating ANC dates: $e');
            }
          }

          pregnantWomen.add({
            'name': name,
            'age': age,
            'gender': 'महिला',
            'mobile': mobile,
            'id': row['unique_key']?.toString() ?? '',
            'ancDates': ancDates ,
            'nextVisit': nextVisit,
            'badge': 'ANC',
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      setState(() {
        _pwList = pregnantWomen;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pregnant women: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _loadPoornTikakaran() async {
    print('Starting to load Poorn Tikakaran (9-year) data...');
    try {
      print('Calling getChildTrackingDueFor9Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor9Year();
      print('Received ${rows.length} rows from database');

      setState(() {
        _poornTikakaran.clear();
        for (var row in rows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map
              ? (formData['form_data'] ?? formData)
              : formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _poornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _poornTikakaran: ${_poornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadPoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadChild0to1() async {
    print('Loading children 0-1 year data...');
    try {
      // Load all age groups for 0-1 year
      final birthDose = await LocalStorageDao.instance.getChildTrackingForBirthDose();
      final sixWeeks = await LocalStorageDao.instance.getChildTrackingFor6Weeks();
      final tenWeeks = await LocalStorageDao.instance.getChildTrackingFor10Weeks();
      final fourteenWeeks = await LocalStorageDao.instance.getChildTrackingFor14Weeks();

      setState(() {
        _child0to1.clear();
        // Combine all age groups into one list
        _addFormDataToList(_child0to1, birthDose);
        _addFormDataToList(_child0to1, sixWeeks);
        _addFormDataToList(_child0to1, tenWeeks);
        _addFormDataToList(_child0to1, fourteenWeeks);
        print('Total items in _child0to1: ${_child0to1.length}');
      });
    } catch (e) {
      print('Error in _loadChild0to1: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadChild1to2() async {
    print('Loading children 1-2 years data...');
    try {
      final rows = await LocalStorageDao.instance.getChildTrackingFor16To24Months();
      _updateChildList(_child1to2, rows, '1-2 years');
    } catch (e) {
      print('Error in _loadChild1to2: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadChild2to5() async {
    print('Loading children 2-5 years data...');
    try {
      final rows = await LocalStorageDao.instance.getChildTrackingFor5To6Years();
      _updateChildList(_child2to5, rows, '2-5 years');
    } catch (e) {
      print('Error in _loadChild2to5: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

// Helper method to update child list
  void _updateChildList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows, String logName) {
    setState(() {
      targetList.clear();
      _addFormDataToList(targetList, sourceRows);
      print('Total items in $logName: ${targetList.length}');
    });
  }

// Helper method to add form data to list
  void _addFormDataToList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows) {
    for (var row in sourceRows) {
      final formData = row['form_json'];
      final formDataContent = formData is Map ? (formData['form_data'] ?? formData) : formData;

      if (formDataContent != null) {
        targetList.add({
          'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
          'age': formDataContent['age'] ?? 'N/A',
          'gender': formDataContent['gender'] ?? 'N/A',
          'father_name': formDataContent['father_name'] ?? 'N/A',
          'mother_name': formDataContent['mother_name'] ?? 'N/A',
          'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
          'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
          'registration_date': formDataContent['registration_date'] ?? 'N/A',
          'household_id': formDataContent['household_id'] ?? 'N/A',
          'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
          'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
        });
      }
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
      return null;
    }
  }

  Map<String, DateTime> _calculateAncDateRanges(DateTime lmp) {
    final ranges = <String, DateTime>{};
    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = _dateAfterWeeks(lmp, 12);
    ranges['2nd_anc_start'] = _dateAfterWeeks(lmp, 14);
    ranges['2nd_anc_end'] = _dateAfterWeeks(lmp, 24);
    ranges['3rd_anc_start'] = _dateAfterWeeks(lmp, 26);
    ranges['3rd_anc_end'] = _dateAfterWeeks(lmp, 34);
    ranges['4th_anc_start'] = _dateAfterWeeks(lmp, 36);
    ranges['4th_anc_end'] = _calculateEdd(lmp);
    ranges['pmsma_start'] = _dateAfterWeeks(lmp, 40);
    ranges['pmsma_end'] = _dateAfterWeeks(lmp, 44);
    return ranges;
  }

  DateTime _dateAfterWeeks(DateTime startDate, int weeks) {
    return startDate.add(Duration(days: weeks * 7));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _getNextVisitDate(Map<String, DateTime> ancDates) {
    final now = DateTime.now();

     final ancWindows = [
      {'key': '1st_anc_start', 'label': '1st ANC'},
      {'key': '2nd_anc_start', 'label': '2nd ANC'},
      {'key': '3rd_anc_start', 'label': '3rd ANC'},
      {'key': '4th_anc_start', 'label': '4th ANC'},
      {'key': 'pmsma_start', 'label': 'PMSMA'},
    ];

    for (var window in ancWindows) {
      final startDate = ancDates[window['key']];
      if (startDate != null && startDate.isAfter(now)) {
        return '${window['label']} (${_formatDate(startDate)})';
      }
    }

    // If all visits are in the past, return the last one
    final lastVisit = ancDates['pmsma_end'];
    if (lastVisit != null) {
      return 'Last Visit: ${_formatDate(lastVisit)}';
    }

    return 'No visit scheduled';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

     final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.routine, showBack: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _sectionTile(l10n.routinePwList, _pwList),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList0to1, _child0to1),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList1to2, _child1to2),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList2to5, _child2to5),
          const SizedBox(height: 12),
          _sectionTile(l10n.routinePoornTikakaran, _poornTikakaran),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineSampoornTikakaran, _sampoornTikakaran),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTile(String title, List<Map<String, dynamic>> items) {
    final l10n = AppLocalizations.of(context)!;

    final isOpen = _expanded[title] ?? false;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded[title] = !isOpen;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style:  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color:AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[
          const Divider(height: 1, color: Color(0xFFD3E7FF)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  l10n.noRecordFound,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: _routineCard(item),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final ancDates = item['ancDates'] as Map<String, dynamic>?;
    final mobile = item['mobile']?.toString() ?? '';
    final isSampoornTikakaran = item['age']?.toString().contains('16') ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.home, color: primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    (item['beneficiary_ref_key'] ?? item['id'] ?? '-').toString(),
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 12.sp),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F7E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    item['badge']?.toString() ?? 'ANC',
                    style: const TextStyle(color: Color(0xFF0E7C3A), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name']?.toString() ?? '-',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item['age'] ?? '-'} सा | ${item['gender'] ?? '-'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l10n!.antenatal} ${item['nextVisit'] ?? '-'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.mobileLabel} ${item['mobile'] ?? '-'}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _makePhoneCall(mobile),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.phone, color: primary, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset('assets/images/hrp.png'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),


               ],
            ),
          ),
        ],
      ),
    );
  }


}
