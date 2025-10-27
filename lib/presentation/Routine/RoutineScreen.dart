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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.routine, showBack: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _sectionTile(l10n.routinePwList),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList0to1),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList1to2),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList2to5),
          const SizedBox(height: 12),
          _sectionTile(l10n.routinePoornTikakaran),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineSampoornTikakaran),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTile(String title) {
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
                    style:  TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Text(
                  '0',
                  style: TextStyle(
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
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
