import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class ApiDropdown<T> extends StatelessWidget {
  final String? labelText;
  final List<T> items;
  final String Function(T) getLabel;
  final bool convertToTitleCase;
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
  final String? emptyOptionText;
  final bool readOnly;


  String _toTitleCase(String text) {
    return text;
    /*if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';

    }).join(' ');*/
  }

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
    this.convertToTitleCase = true,
    this.emptyOptionText,
    this.readOnly = false
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
          fontSize: 13.5.sp,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
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
    final l10n = AppLocalizations.of(context)!;
    final TextStyle inputStyle = TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
      height: 1,
    );

    return FormField<T>(
      initialValue: value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: readOnly
                  ? null // Disable tap when readOnly
                  : () {
                FocusManager.instance.primaryFocus?.unfocus();
                FocusScope.of(context).unfocus();
                FocusScope.of(context).requestFocus(FocusNode());
                _showSelectDialog(context, field);
              },
              child: AbsorbPointer(
                absorbing: readOnly,
                child: Opacity(
                  opacity: readOnly ? 0.7 : 1.0,
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
                              if (_labelWidget != null)
                                DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: labelFontSize ?? 14.sp,
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                  maxLines: labelMaxLines ?? 3,
                                  overflow: TextOverflow.ellipsis,
                                  child: _labelWidget!,
                                ),
                              const SizedBox(height: 3),
                              Text(
                                value != null
                                    ? getLabel(value!)
                                     : (hintText ?? l10n.selectOptionLabel),

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
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.2,
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Future<void> _showSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    if (multiSelect) {
      await _showMultiSelectDialog(context, field);
    } else {
      await _showSingleSelectDialog(context, field);
    }
  }

  Future<void> _showSingleSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    T? tempValue = items.contains(value) ? value : null;
    final l10n = AppLocalizations.of(context);


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
                  (labelText ?? 'Select Option').replaceAll('', ''),
                  style: TextStyle(
                    fontSize: labelFontSize ?? 15.sp,
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
                children: items.isEmpty
                    ? [
                        ListTile(
                          leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                          title: Text(
                            emptyOptionText ?? (  'No options found'),
                            style: TextStyle(
                              fontSize: labelFontSize ?? 15.sp,
                              color: Colors.grey,
                            ),
                          ),
                          enabled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -4),
                        )
                      ]
                    : items.map((item) {
                        return RadioListTile<T>(
                          title: Text(
                            convertToTitleCase ? _toTitleCase(getLabel(item)) : getLabel(item),
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
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                      l10n?.cancel ?? 'CANCEL',
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
                      field.didChange(tempValue);
                    }
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.ok ?? 'OK',
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
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _showMultiSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
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
                  fontSize: labelFontSize ?? 16.sp,  
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
                      convertToTitleCase ? _toTitleCase(getLabel(item)) : getLabel(item),
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
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.cancel ?? 'CANCEL',
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
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.ok ?? 'OK',
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
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
