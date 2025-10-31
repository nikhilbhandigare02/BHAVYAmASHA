import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class DeathRegister extends StatefulWidget {
  const DeathRegister({super.key});

  @override
  State<DeathRegister> createState() => _DeathRegisterState();
}

class _DeathRegisterState extends State<DeathRegister> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',
      'name': 'Ramesh Kumar',
      'age/gender': '18 Y / Male',
      'date': '22/10/2025', // ✅ changed to lowercase
      'place': 'Home',
      'status': 'Adult',
    },
    {
      'hhId': '51016121847',
      'name': 'Ramesh Kumar',
      'age/gender': '18 Y / Male',
      'date': '22/10/2025', // ✅ changed to lowercase
      'place': 'Home',
      'status': 'Adult',
    },
  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
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
        _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
      } else {
        _filtered = _staticHouseholds.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['name'] as String).toLowerCase().contains(q) ||
              (e['mobile'] as String).toLowerCase().contains(q) ||
              (e['mohalla'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.deathRegisterTitle ?? 'Death Register',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.searchHint ?? 'Search by ID/Name/Contact',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

          // 📋 Household List
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
final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Route_Names.FamliyUpdate,
          arguments: {'isBeneficiary': true},
        );
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
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] ?? '').toString(),
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

            // 🔹 Body
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
                  Row(
                    children: [
                      Expanded(child: _infoRow('', data['name'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoRow('${l10n?.dateLabel ?? 'Date'}:', data['date'] ?? l10n?.notAvailable ?? 'N/A')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child:
                          _infoRow('', data['age/gender'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _infoRow('${l10n?.placeLabel ?? 'Place'}:', data['place'] ?? l10n?.notAvailable ?? 'N/A')),
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

  Widget _infoRow(String title, String value) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            (value.isEmpty ? l10n?.notAvailable ?? 'N/A' : value),
            style:  TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}
