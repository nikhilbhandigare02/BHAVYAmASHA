import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../data/Local_Storage/local_storage_dao.dart';

class FamliyUpdate extends StatefulWidget {
  const FamliyUpdate({super.key});

  @override
  State<FamliyUpdate> createState() => _FamliyUpdateState();
}

class _FamliyUpdateState extends State<FamliyUpdate> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadHeads();
  }

  Future<void> _loadHeads() async {
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    final heads = <Map<String, dynamic>>[];
    for (final row in rows) {
      final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
      final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
      if (head.isNotEmpty) {
        heads.add({
          'hhId': row['household_ref_key']?.toString() ?? '',
          'name': head['headName']?.toString() ?? '',
          'mobile': head['mobileNo']?.toString() ?? '',
          'mohalla': head['mohalla']?.toString() ?? '',
        });
      }
    }
    setState(() {
      _filtered = heads;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: 'Family Update',
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
        Navigator.pushNamed(
          context,
          Route_Names.FamliyUpdate,
          arguments: {'isBeneficiary': true},
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
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
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['hhId'] ?? '',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
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
                  _infoRow('', data['name'], isBold: true),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _infoRow('Mobile :', data['mobile']),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _infoRow(
                          'Mohalla :',
                          data['mohalla'] ?? '',
                          isWrappable: true, // ✅ Optional flag to handle wrapping
                        ),
                      ),
                    ],
                  ),
                ],
              )


            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String? title, String value,{bool isWrappable = false, bool isBold = false}) {
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
              value.isEmpty ? 'Not Available' : value,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
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
