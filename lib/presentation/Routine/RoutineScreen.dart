import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class Routinescreen extends StatefulWidget {
  const Routinescreen({super.key});

  @override
  State<Routinescreen> createState() => _RoutinescreenState();
}

class _RoutinescreenState extends State<Routinescreen> {
  final Map<String, bool> _expanded = {};

  final List<Map<String, dynamic>> _pwList = [
    {
      'name': 'sushila',
      'age': 38,
      'gender': 'महिला',
      'nextVisit': '16-12-2025',
      'mobile': '7189356357',
      'id': '51024164916',
    }
  ];
  final List<Map<String, dynamic>> _child0to1 = [];
  final List<Map<String, dynamic>> _child1to2 = [];
  final List<Map<String, dynamic>> _child2to5 = [];
  final List<Map<String, dynamic>> _poornTikakaran = [];
  final List<Map<String, dynamic>> _sampoornTikakaran = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.routine, showBack: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.home, color: primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item['id']?.toString() ?? '-',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F7E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    item['badge']?.toString() ?? 'एएनसी',
                    style: const TextStyle(color: Color(0xFF0E7C3A), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
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
                        'अगली प्रसव पूर्व तिथि: ${item['nextVisit'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'मोबाइल सं.: ${item['mobile'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.phone, color: primary, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pregnant_woman, color: primary),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }
}
