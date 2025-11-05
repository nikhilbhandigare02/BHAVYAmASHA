import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';

class TodayProgramSection extends StatefulWidget {
  final int? selectedGridIndex;
  final Function(int) onGridTap;
  final Map<String, List<String>> apiData;

  const TodayProgramSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    required this.apiData,
  });

  @override
  State<TodayProgramSection> createState() => _TodayProgramSectionState();
}

class _TodayProgramSectionState extends State<TodayProgramSection> {
  String? _expandedKey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGridTap(0);
    });
  }

  bool _isExpanded(String key) {
    return _expandedKey == key;
  }

  List<Widget> _getAncListItems() {
    // Sample ANC data - replace with your actual data
    final List<Map<String, dynamic>> ancItems = [
      {
        'id': 'ANC-001',
        'name': 'Priya Sharma',
        'age': '25y',
        'gender': 'Female',
        'Current ANC last due date' :'18 Nov 2023',
        'last Visit date': 'no visit yet',
        'mobile': '9876543210',
        'badge': 'ANC',
      },
      {
        'id': 'ANC-002',
        'name': 'Meera Patel',
        'age': '28y',
        'gender': 'Female',
        'last Visit date': '18 Nov 2023',
        'Current ANC last due date' :'18 Nov 2023',
        'mobile': '9876543211',
        'badge': 'ANC',
      },
    ];

    return ancItems.map((item) => _routineCard(item)).toList();
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                    item['badge']?.toString() ?? 'ANC',
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
                        '${item['age'] ?? '-'} | ${item['gender'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'last Visit date: ${item['last Visit date'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Current ANC last due date: ${item['Current ANC last due date'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mobile: ${item['mobile'] ?? '-'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.phone, color: primary, size: 24),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid Boxes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(0),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 0 ? AppColors.primary : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/schedule.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                "0",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 0 ? AppColors.onPrimary : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.toDoVisits,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              color: widget.selectedGridIndex == 0 ? AppColors.onPrimary : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Grid Box 2
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(1),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 1 ? AppColors.primary : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/comment.png',
                                    width: 6.w,
                                    height: 6.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              Text(
                                "0",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 1 ? AppColors.onPrimary : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.completedVisits,
                            style: TextStyle(

                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp  ,
                              color: widget.selectedGridIndex == 1 ? AppColors.onPrimary : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ExpansionTile list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              // Control ExpansionTile animation speed globally
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Column(
              children: [
                for (var entry in widget.apiData.entries) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: ExpansionTile(
                      key: ValueKey('${entry.key}_$_expandedKey'),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedKey = expanded ? entry.key : null;
                        });
                      },
                      initiallyExpanded: _expandedKey == entry.key,
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: _expandedKey == entry.key ? Colors.blueAccent : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${entry.value.length}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _expandedKey == entry.key ? 0.5 : 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.keyboard_arrow_down_outlined,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      children: entry.key == 'ANC List'
                          ? _getAncListItems()
                          : entry.value
                              .map((item) => ListTile(title: Text(item)))
                              .toList(),
                    ),
                  ),
                  Divider(
                    color: AppColors.divider,
                    thickness: 1,
                    height: 1,
                  ),
                ],
              ],
            ),
          ),
        )
      ],
    );
  }
}
