import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/Incentive_portal/Finalize_Incentive.dart';
import 'package:medixcel_new/presentation/Incentive_portal/Monthly_Task.dart';
import 'package:sizer/sizer.dart';

import '../../core/widgets/MarqeeText/MarqeeText.dart';

class IncentivePortal extends StatefulWidget {
  const IncentivePortal({super.key});

  @override
  State<IncentivePortal> createState() => _IncentivePortalState();
}

class _IncentivePortalState extends State<IncentivePortal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _navigatingFinalize = false;

  final List<String> _years = [
    '2022-2023',
    '2023-2024',
    '2024-2025',
    '2025-2026',
  ];

  late String _selectedYear;
  late String _selectedMonth;
  bool _isFirstBuild = true;

  List<String> _getMonthNames(AppLocalizations? l10n) => [
    l10n?.monthJanuary ?? 'January',
    l10n?.monthFebruary ?? 'February',
    l10n?.monthMarch ?? 'March',
    l10n?.monthApril ?? 'April',
    l10n?.monthMay ?? 'May',
    l10n?.monthJune ?? 'June',
    l10n?.monthJuly ?? 'July',
    l10n?.monthAugust ?? 'August',
    l10n?.monthSeptember ?? 'September',
    l10n?.monthOctober ?? 'October',
    l10n?.monthNovember ?? 'November',
    l10n?.monthDecember ?? 'December',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedYear = _years[2]; // default sample like screenshot

    _tabController.addListener(() async {
      if (_navigatingFinalize) return;
      if (_tabController.index == 2 && !_tabController.indexIsChanging) {
        _navigatingFinalize = true;
        final prev = _tabController.previousIndex;
        // Revert selection back to previous tab to keep TabBarView here
        if (mounted) {
          setState(() {
            _tabController.index = prev;
          });
        }
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FinalizeIncentivePage()),
        );
        _navigatingFinalize = false;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = _getMonthNames(l10n);
    
    // Initialize _selectedMonth on first build
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _selectedMonth = monthNames[DateTime.now().month - 1];
    } else if (_selectedMonth == null) {
      // Fallback in case _selectedMonth is somehow null
      _selectedMonth = monthNames[DateTime.now().month - 1];
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        screenTitle: l10n?.drawerIncentivePortal ?? 'Incentive Portal',
        showBack: true,
      ),
      floatingActionButton: RawMaterialButton(
        onPressed: () {},
        fillColor: AppColors.primary, // background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        constraints: const BoxConstraints(
          minWidth: 50,
          minHeight: 50,
        ),
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color:Colors.lightBlue[50],
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Rohit Chavan',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoCell(title: l10n?.incentiveHeaderDistrict ?? 'जिला', value: 'Patna'),
                        _InfoCell(title: l10n?.incentiveHeaderBlock ?? 'Block', value: 'Maner'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoCell(title: l10n?.incentiveHeaderHsc ?? 'HSC', value: 'HSC Baank'),
                        _InfoCell(title: l10n?.incentiveHeaderPanchayat ?? 'Panchayat', value: 'Baank'),
                        _InfoCell(title: l10n?.incentiveHeaderAnganwadi ?? 'Anganwadi', value: 'Baank'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            MarqueeText(
              text: l10n?.incentiveNote ?? 'This is a sample incentive note scrolling continuously...',
              style: TextStyle(color: AppColors.error, fontSize: 12),
              velocity: 50, // adjust speed
            ),


            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LabeledDropdown<String>(
                    label: l10n?.incentiveFinancialYear ?? 'Financial year',
                    value: _selectedYear,
                    items: _years.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledDropdown<String>(
                    label: l10n?.incentiveFinancialMonth ?? 'Financial month',
                    value: _selectedMonth,
                    items: monthNames.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  l10n != null
                    ? l10n!.incentiveTotalAmount(0)
                    : 'Total amount (Daily + Monthly): ₹0',
                  style:  TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
                color: AppColors.surfaceVariant
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: l10n?.incentiveTabDaily ?? 'Daily tasks'),
                  Tab(text: l10n?.incentiveTabMonthly ?? 'Monthly tasks'),
                  Tab(text: l10n?.incentiveTabFinalize ?? 'Finalize'),
                ],
              ),
            ),

            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _SectionPlaceholder(title: 'Daily tasks content here'),
                  MonthlyTasks(),
                  // _SectionPlaceholder(title: 'Finalize content here'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCell({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
class _SectionPlaceholder extends StatelessWidget {
  final String title;
  const _SectionPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14.sp)),
    );
  }
}
