import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';

class Guestbeneficiaries extends StatefulWidget {
  const Guestbeneficiaries({super.key});

  @override
  State<Guestbeneficiaries> createState() => _GuestbeneficiariesState();
}

class _GuestbeneficiariesState extends State<Guestbeneficiaries> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuestBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
  }



  Future<void> _loadGuestBeneficiaries() async {
    setState(() => _isLoading = true);
    _filtered = [];

    try {
      final db = await DatabaseProvider.instance.database;
      final results = await db.query(
        'beneficiaries_new',
        where: 'is_guest = 1 AND is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      print('Loaded guest beneficiaries count: ${results.length}');

      final List<Map<String, dynamic>> formatted = [];
      for (final row in results) {
        try {
          final rawInfo = row['beneficiary_info'] as String? ?? '{}';
          final info = jsonDecode(rawInfo) as Map<String, dynamic>;
          final parentUserRaw = row['parent_user']?.toString() ?? '';
          Map<String, dynamic> parentUser = {};
          if (parentUserRaw.isNotEmpty) {
            try {
              parentUser = jsonDecode(parentUserRaw) as Map<String, dynamic>;
              print('parentUser: $parentUser');
            } catch (_) {}
          }

          final name = (info['member_name']?.toString() ??
              info['memberName']?.toString() ??
              info['headName']?.toString() ??
              info['name']?.toString() ??
              'N/A');

          final dob = info['dob']?.toString();
          final ageShort = _formatAgeShort(info['age'], dob);
          final gender = (info['gender']?.toString() ?? 'N/A');
          final fatherSpouse = (info['father_or_spouse_name']?.toString() ??
              info['fatherName']?.toString() ??
              info['spouseName']?.toString() ??
              'N/A');

          final mobile = (info['mobile_no']?.toString() ??
              info['mobileNo']?.toString() ??
              info['mobile']?.toString() ??
              info['mobile_number']?.toString() ??
              '');

          // ASHA / HSC from parent_user JSON
          final ashaName = parentUser['asha_name']?.toString() ?? '';
          final hscName = parentUser['hsc_name']?.toString() ?? '';

          // RCH ID from beneficiary info
          final rchId = (info['RCH_ID']?.toString() ??
              info['rch_number']?.toString() ??
              info['richId']?.toString() ??
              info['RichID']?.toString() ??
              '');

          // beneficiary_state can be string or JSON array
          String status = (row['beneficiary_state']?.toString() ?? '').trim();
          if (status.startsWith('[')) {
            try {
              final decoded = jsonDecode(status);
              if (decoded is List) {
                status = decoded.whereType<String>().join(', ');
              }
            } catch (_) {}
          }

          final uniqueKey = row['unique_key']?.toString() ?? '';
          final displayHhId = uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey;

          print('Guest row: unique_key=${row['unique_key']}, hhId=$displayHhId, name=$name, gender=$gender, age=$ageShort, father_or_spouse=$fatherSpouse');
          print('Beneficiary info keys: ${info.keys.join(', ')}');

          formatted.add({
            'hhId': displayHhId,
            'name': name,
            'age | gender': '$ageShort | $gender',
            'status': status.isNotEmpty ? status : 'Guest',
            'father_spouse': fatherSpouse,
            'mobileNo': mobile,
            'asha_name': ashaName,
            'hsc_name': hscName,
            'rchId': rchId,
          });
        } catch (e) {
          print('Error decoding beneficiary_info for a guest row: $e');
        }
      }

      setState(() {
        _filtered = formatted;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading guest beneficiaries: $e');
      setState(() => _isLoading = false);
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;

      if (now.day < birthDate.day) {
        months--;
      }
      if (months < 0) {
        years--;
        months += 12;
      }

      if (years > 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$months ${months == 1 ? 'month' : 'months'}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAgeShort(dynamic ageValue, String? dob) {
    try {
      if (ageValue != null) {
        final s = ageValue.toString().trim().toLowerCase();
        final n = int.tryParse(s);
        if (n != null && n > 0) {
          return '$n Y';
        }
        final yearMatch = RegExp(r"(\d+)\s*year").firstMatch(s);
        final monthMatch = RegExp(r"(\d+)\s*month").firstMatch(s);
        final dayMatch = RegExp(r"(\d+)\s*day").firstMatch(s);
        final y = yearMatch != null ? int.tryParse(yearMatch.group(1)!) ?? 0 : 0;
        final m = monthMatch != null ? int.tryParse(monthMatch.group(1)!) ?? 0 : 0;
        final d = dayMatch != null ? int.tryParse(dayMatch.group(1)!) ?? 0 : 0;
        if (y > 0) return '$y Y';
        if (m > 0) return '$m M';
        if (d > 0) return '$d D';
      }
      if (dob == null || dob.isEmpty) return 'N/A';
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;
      int days = now.difference(birthDate).inDays;
      if (now.day < birthDate.day) {
        months--;
      }
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0) {
        return '$years Y';
      }
      if (months > 0) {
        return '$months M';
      }
      return '${days > 0 ? days : 0} D';
    } catch (_) {
      return 'N/A';
    }
  }





  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Guest Beneficiaries',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No guest beneficiaries found',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ),
          )
              : Expanded(
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
                        data['hhId'] ?? '',
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
                      color: Colors.green.withOpacity(0.15), // ✅ Background color
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      data['status'] ?? '',
                      style: const TextStyle(
                        color: Colors.green, // ✅ Text color
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow([
                    _rowText('Name', (data['name'] ?? data['Name'] ?? '').toString()),
                    _rowText('RCH ID', (data['rchId'] ?? data['RchID'] ?? data['richId'] ?? data['RichID'] ?? '').toString()),
                    _rowText('ASHA', (data['asha_name'] ?? data['ashaName'] ?? data['asha'] ?? data['facilitator_name'] ?? '').toString()),
                  ]),
                  const SizedBox(height: 10),
                  _buildRow([
                    _rowText('Father/Spouse Name', (data['father_spouse'] ?? data['FatherName'] ?? data['fatherName'] ?? data['Husband'] ?? data['spouseName'] ?? '').toString()),
                    _rowText('Age | Gender', (data['age | gender'] ?? data['Age|Gender'] ?? '').toString()),
                    _rowText('HSC', (data['hsc_name'] ?? data['hsc'] ?? (data['hsc_id']?.toString() ?? '')).toString()),
                  ]),
                  const SizedBox(height: 10),
                  _buildRow([
                    _rowText('Mobile Number', (data['mobileNo'] ?? data['mobile'] ?? data['mobile_number'] ?? data['Mobileno.'] ?? '').toString()),
                    _rowText('Status', (data['status'] ?? '').toString()),
                    const SizedBox.shrink(),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ]
      ],
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          (value.trim().isEmpty || value.trim().toLowerCase() == 'n/a' || value.trim().toLowerCase() == 'null') ? 'Not Available' : value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
