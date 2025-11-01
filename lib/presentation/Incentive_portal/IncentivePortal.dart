import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/Incentive_portal/Finalize_Incentive.dart';
import 'package:medixcel_new/presentation/Incentive_portal/Monthly_Task.dart';
import 'package:sizer/sizer.dart';

import '../../core/config/routes/Route_Name.dart';
import '../../core/widgets/MarqeeText/MarqeeText.dart';
import '../HomeScreen/HomeScreen.dart';

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
    
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _selectedMonth = monthNames[DateTime.now().month - 1];
    } else if (_selectedMonth == null) {

    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        screenTitle: 'प्रोत्साहन पोर्टल',
        showBack: false,
        icon1Image: 'assets/images/google-docs.png',
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.NationalProgramsScreen ),
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: CustomDrawer(),
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
              color: AppColors.primaryContainer,
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
                        _InfoCell(title: 'जिला', value: 'Patna'),
                        _InfoCell(title: 'प्रखंड', value: 'Maner'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _InfoCell(title:  'स्वास्थ्य उप केंद्र', value: 'HSC Baank'),
                        _InfoCell(title:  'पंचायत', value: 'Baank'),
                        _InfoCell(title:  'आंगनवाड़ी', value: 'Baank'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            MarqueeText(
              text:  'प्रत्येक महीने की दावा राशि के भुगतान फाइल अगले महीने की 28 से 30 तारीख के बीच जमा करें।',
              style: TextStyle(color: AppColors.error, fontSize: 12),
              velocity: 50, // adjust speed
            ),


            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LabeledDropdown<String>(
                    label: 'वित्तीय वर्ष',
                    value: _selectedYear,
                    items: _years.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledDropdown<String>(
                    label:  'वित्तीय महीना',
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
                  'कुल राशि(दैनिक+मासिक) : ₹0',
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
                  Tab(text:  'दैनिक कार्य'),
                  Tab(text:  'मासिक कार्य'),
                  Tab(text: 'अंतिम रूप से'),
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
        Text(label, style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
