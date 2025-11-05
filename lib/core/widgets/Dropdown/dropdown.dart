import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class ApiDropdown<T> extends StatelessWidget {
  final String? labelText;
  final List<T> items;
  final String Function(T) getLabel;
  final T? value;
  final Function(T?)? onChanged;
  final bool isExpanded;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final int? labelMaxLines;
  final bool multiSelect;
  final List<T> selectedValues;
  final Function(List<T>)? onMultiChanged;

  final double? labelFontSize;

  const ApiDropdown({
    super.key,
    this.labelText,
    required this.items,
    required this.getLabel,
    this.value,
    this.onChanged,
    this.isExpanded = true,
    this.hintText,
    this.validator,
    this.labelMaxLines,
    this.multiSelect = false,
    this.selectedValues = const [],
    this.onMultiChanged,
    this.labelFontSize,
  });

  Widget? get _labelWidget {
    if (labelText == null || labelText!.isEmpty) return null;

    final bool required = labelText!.endsWith(' *');
    final String base = required
        ? labelText!.substring(0, labelText!.length - 2).trim()
        : labelText!;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: labelFontSize ?? 15.sp,
          color: AppColors.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: base),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
      maxLines: labelMaxLines,
      overflow: TextOverflow.visible,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
      height: 1.5,
    );

    return GestureDetector(
      onTap: () => _showSelectDialog(context),
      child: AbsorbPointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 Label and value side by side
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (labelText != null && labelText!.isNotEmpty)
                      Text(
                        labelText!.replaceAll(' *', ''),
                        style: TextStyle(
                          fontSize: labelFontSize ?? 14.sp,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: labelMaxLines ?? 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      value != null
                          ? getLabel(value!)
                          : (hintText ?? 'Select option'),
                      style: inputStyle.copyWith(
                        color: value != null
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 🔹 Dropdown arrow
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _showSelectDialog(BuildContext context) async {
    if (multiSelect) {
      await _showMultiSelectDialog(context);
    } else {
      await _showSingleSelectDialog(context);
    }
  }

  Future<void> _showSingleSelectDialog(BuildContext context) async {
    T? tempValue = items.contains(value) ? value : null;

    await showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.5.h),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (labelText ?? 'Select Option').replaceAll(' *', ''),
                  style: TextStyle(
                    fontSize: labelFontSize ?? 15.sp, // ✅ applied here too
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 10),
              ],
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 40.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  return RadioListTile<T>(
                    title: Text(
                      getLabel(item),
                      style: TextStyle(fontSize: labelFontSize ?? 15.sp),
                    ),
                    value: item,
                    groupValue: tempValue,
                    onChanged: (val) => setState(() => tempValue = val),
                    contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            const Divider(height: 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (tempValue != null && onChanged != null) {
                      onChanged!(tempValue);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    List<T> tempValues = List<T>.from(selectedValues);
  final l10n = AppLocalizations.of(context);
    await showDialog<List<T>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.5.h),
          ),
          title: Column(
            children: <Widget>[
              Text(
                (labelText ?? l10n!.selectOption).replaceAll(' *', ''),
                style: TextStyle(
                  fontSize: labelFontSize ?? 16.sp, // ✅ applied here too
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Divider(height: 2),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 40.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final bool isSelected = tempValues.contains(item);
                  return CheckboxListTile(
                    title: Text(
                      getLabel(item),
                      style: TextStyle(fontSize: labelFontSize ?? 15.sp),
                    ),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          if (!tempValues.contains(item)) tempValues.add(item);
                        } else {
                          tempValues.remove(item);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onMultiChanged?.call(tempValues);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
