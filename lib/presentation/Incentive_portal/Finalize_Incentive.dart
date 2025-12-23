import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class FinalizeIncentivePage extends StatefulWidget {
  const FinalizeIncentivePage({super.key});

  @override
  State<FinalizeIncentivePage> createState() => _FinalizeIncentivePageState();
}

String _safeText(dynamic v) => v?.toString().trim().isNotEmpty == true ? v.toString() : '-';

class _FinalizeIncentivePageState extends State<FinalizeIncentivePage> {
  Map<String, dynamic>? _userRow;
  bool _isUserLoading = true;
  late String _financialYear;
  late String _financialMonth;

  @override
  void initState() {
    super.initState();
    _computeFinancialPeriod();
    _loadUser();
  }

  void _computeFinancialPeriod() {
    final now = DateTime.now();
    final int year = now.year;
    final int month = now.month;
    if (month >= 4) {
      _financialYear = '${year}-${year + 1}';
    } else {
      _financialYear = '${year - 1}-${year}';
    }
    _financialMonth = _monthName(month);
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '-';
    }
  }

  Future<void> _loadUser() async {
    try {
      final row = await LocalStorageDao.instance.getCurrentUserFromDb();
      if (!mounted) return;
      setState(() {
        _userRow = row;
        _isUserLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUserLoading = false;
      });
    }
  }

  Map<String, dynamic> _detailsJson() {
    if (_userRow == null || !_userRow!.containsKey('details')) return const {};
    final raw = _userRow!['details'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  String _getWorkingField(String key) {
    try {
      final details = _detailsJson();
      final working = details['data']?['working_location'] ?? details['working_location'] ?? {};
      return _safeText(working[key]);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.success
        : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeader(
        screenTitle: (l10n?.finalizeTitle ?? 'Final Incentive Portal'),
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RowTwo(
                        leftTitle:  (l10n?.incentiveFinancialYear ?? 'Financial year'),
                        leftValue: _financialYear,
                        rightTitle:  (l10n?.incentiveFinancialMonth ?? 'Financial month'),
                        rightValue: _financialMonth,
                      ),
                      const SizedBox(height: 4),
                      Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 4),
                      _RowThree(
                        t1: (l10n?.incentiveHeaderDistrict ?? 'District'), v1: _getWorkingField('district'),
                        t2:  (l10n?.incentiveHeaderBlock ?? 'Block'), v2: _getWorkingField('block'),
                        t3: (l10n?.incentiveHeaderHscLabel ?? 'HSC'), v3: _getWorkingField('hsc_name'),
                        t4:  (l10n?.incentiveHeaderPanchayat ?? 'Panchayat'), v4: _getWorkingField('panchayat'),
                        t5:  (l10n?.incentiveHeaderAnganwadi ?? 'Anganwadi'), v5: _getWorkingField('anganwadi'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AmountColumn(title: (l10n?.finalizeClaimedAmount ?? 'Claimed Amount'), amount: '₹ 0'),
                    _AmountColumn(title: (l10n?.finalizeStateAmount ?? 'State Amount'), amount: '₹ 0'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: AppColors.onSurface, fontSize: 15.sp),
                      children: [
                        TextSpan(text: (l10n?.finalizeTotalAmountLabel ?? 'Total Amount:') + ' '),
                        TextSpan(text: '₹ 0', style: TextStyle(color: successColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 100, // fixed width for the button
                  height: 30, // optional
                  child: RoundButton(
                    title: (l10n?.finalizeSave ?? 'Save'),
                    color: AppColors.primary,
                    onPress: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String title;
  final String amount;
  const _AmountColumn({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14.sp, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(amount, style: TextStyle(color: AppColors.onSurface, fontSize: 15.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _RowTwo extends StatelessWidget {
  final String leftTitle;
  final String leftValue;
  final String rightTitle;
  final String rightValue;
  const _RowTwo({required this.leftTitle, required this.leftValue, required this.rightTitle, required this.rightValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _LabelValue(title: leftTitle, value: leftValue)),
        Expanded(child: _LabelValue(title: rightTitle, value: rightValue, alignEnd: true)),
      ],
    );
  }
}

class _RowThree extends StatelessWidget {
  final String t1, v1, t2, v2, t3, v3, t4, v4, t5, v5;
  const _RowThree({
    required this.t1, required this.v1,
    required this.t2, required this.v2,
    required this.t3, required this.v3,
    required this.t4, required this.v4,
    required this.t5, required this.v5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _LabelValue(title: t1, value: v1)),
            Expanded(child: _LabelValue(title: t2, value: v2, alignEnd: true)),
          ],
        ),
        const SizedBox(height: 6),
        Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _LabelValue(title: t3, value: v3)),
            Expanded(child: _LabelValue(title: t4, value: v4)),
            Expanded(child: _LabelValue(title: t5, value: v5, alignEnd: true)),
          ],
        ),
      ],
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String title;
  final String value;
  final bool alignEnd;
  const _LabelValue({required this.title, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14.sp)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700, fontSize: 14.sp)),
      ],
    );
  }
}
