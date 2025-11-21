import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../../../data/Local_Storage/tables/followup_form_data_table.dart';

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
        'beneficiaries',
        where: 'is_guest = 1 AND is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      print('Loaded guest beneficiaries count: ${results.length}');

      final List<Map<String, dynamic>> formatted = [];
      for (final row in results) {
        try {
          final rawInfo = row['beneficiary_info'] as String? ?? '{}';
          final info = jsonDecode(rawInfo) as Map<String, dynamic>;

          final name = (info['member_name']?.toString() ??
              info['memberName']?.toString() ??
              info['headName']?.toString() ??
              info['name']?.toString() ??
              'N/A');

          final dob = info['dob']?.toString();
          final age = (info['age']?.toString() ?? _calculateAge(dob));
          final gender = (info['gender']?.toString() ?? 'N/A');
          final fatherSpouse = (info['father_or_spouse_name']?.toString() ??
              info['fatherName']?.toString() ??
              info['spouseName']?.toString() ??
              'N/A');

          final uniqueKey = row['unique_key']?.toString() ?? '';
          final displayHhId = uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey;

          print('Guest row: unique_key=${row['unique_key']}, hhId=$displayHhId, name=$name, gender=$gender, age=$age, father_or_spouse=$fatherSpouse');
          print('Beneficiary info keys: ${info.keys.join(', ')}');

          formatted.add({
            'hhId': displayHhId,
            'name': name,
            'age | gender': '$age | $gender',
            'status': 'Guest',
            'father_spouse': fatherSpouse,
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

            // 🔸 Body
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
                    _rowText('Name', (data['name'] ?? 'N/A').toString()),
                    _rowText('Age | Gender', (data['age | gender'] ?? 'N/A').toString()),
                    _rowText('Father/Spouse', (data['father_spouse'] ?? 'N/A').toString()),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String value,{bool isWrappable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
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
            fontSize: 11.sp,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'N/A' : value,
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
