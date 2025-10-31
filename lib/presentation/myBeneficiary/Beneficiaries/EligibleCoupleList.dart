import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class EligibleCoupleList extends StatefulWidget {
  const EligibleCoupleList({super.key});

  @override
  State<EligibleCoupleList> createState() => _EligibleCoupleListState();
}

class _EligibleCoupleListState extends State<EligibleCoupleList> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',
      'name': 'Ramesh Kumar',
      'age/gender': '18 Y / Male',
      'status':  'Eligible Couple'
    },
    {
      'hhId': '51016121848',
      'name': 'Sita Devi',
      'age/gender': '18 Y / Female',
      'status': 'Eligible Couple'
    },
  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
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
        screenTitle: l10n?.eligibleCoupleListTitle ?? 'Eligible Couple List',
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
                  _infoRow('', data['name']),
                  const SizedBox(height: 8),
                  _infoRow(
                    '',
                    data['age/gender'] ?? '',
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

  Widget _infoRow(String title, String value, {bool isWrappable = false}) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment:
        isWrappable ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            '$title',
            style:  TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? l10n?.notAvailable ?? 'N/A' : value,
              style:  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
              softWrap: isWrappable,
              overflow:
              isWrappable ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
