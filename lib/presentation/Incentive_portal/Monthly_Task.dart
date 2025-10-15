import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class MonthlyTasks extends StatefulWidget {
  const MonthlyTasks({super.key});

  @override
  State<MonthlyTasks> createState() => _MonthlyTasksState();
}

class _MonthlyTasksState extends State<MonthlyTasks> {
  // Simple local state for demo toggles
  final Map<String, bool> _checked = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColorsDark.success : AppColors.success;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: l10n?.monthlySectionStateContribution ?? 'State Contribution'),
          _TaskItem(
            index: 1,
            title: l10n?.monthlyTaskPC11 ?? 'PC1.1',
            amountText: '₹300',
            amountColor: successColor,
            value: _checked['pc1.1'] ?? false,
            onChanged: (v) => setState(() => _checked['pc1.1'] = v ?? false),
          ),
          _TaskItem(
            index: 2,
            title: l10n?.monthlyTaskPC110 ?? 'PC1.10',
            amountText: '₹10',
            amountColor: successColor,
            value: _checked['pc1.10'] ?? false,
            onChanged: (v) => setState(() => _checked['pc1.10'] = v ?? false),
          ),
          _SectionTitle(title: l10n?.monthlySectionRoutineRecurring ?? 'Routine & Recurring'),
          _TaskItem(
            index: 1,
            title: l10n?.monthlyTaskPC21 ?? 'PC2.1',
            value: _checked['pc2.1'] ?? false,
            onChanged: (v) => setState(() => _checked['pc2.1'] = v ?? false),
          ),
          _TaskItem(
            index: 2,
            title: l10n?.monthlyTaskPC23 ?? 'PC2.3',
            value: _checked['pc2.3'] ?? false,
            onChanged: (v) => setState(() => _checked['pc2.3'] = v ?? false),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final int index;
  final String title;
  final String? amountText;
  final Color? amountColor;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TaskItem({
    required this.index,
    required this.title,
    this.amountText,
    this.amountColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Text(
              '$index.',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (amountText != null) ...[
              const SizedBox(width: 8),
              Text(
                amountText!,
                style: TextStyle(
                  color: amountColor ?? cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
