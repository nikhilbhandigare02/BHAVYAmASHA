import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class FinalizeIncentivePage extends StatelessWidget {
  const FinalizeIncentivePage({super.key});

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
                color: AppColors.surface,
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
                        leftTitle: l10n?.incentiveFinancialYear ?? 'वित्तीय वर्ष',
                        leftValue: '2024-2025',
                        rightTitle: l10n?.incentiveFinancialMonth ?? 'वित्तीय महीना',
                        rightValue: 'June',
                      ),
                      const SizedBox(height: 4),
                      Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 4),
                      _RowThree(
                        t1: l10n?.incentiveHeaderDistrict ?? 'जिला', v1: 'Patna',
                        t2: l10n?.incentiveHeaderBlock ?? 'प्रखंड', v2: 'Maner',
                        t3: l10n?.incentiveHeaderHsc ?? 'स्वास्थ्य उप केंद्र', v3: 'HSC Baank',
                        t4: l10n?.incentiveHeaderPanchayat ?? 'पंचायत', v4: 'Baank',
                        t5: l10n?.incentiveHeaderAnganwadi ?? 'आंगनवाड़ी', v5: 'Baank',
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
                      style: TextStyle(color: AppColors.onSurface, fontSize: 16),
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
        Text(title, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(amount, style: TextStyle(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
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
        Text(title, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
