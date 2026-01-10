import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/utils/responsive_font.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class ApiDropdown<T> extends StatefulWidget {
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
  final int? autoOpenTick;

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
    this.emptyOptionText,
    this.readOnly = false,
    this.convertToTitleCase = true,
    this.autoOpenTick,
  });

  @override
  State<ApiDropdown<T>> createState() => _ApiDropdownState<T>();
}

class _ApiDropdownState<T> extends State<ApiDropdown<T>> {
  int? _lastOpenedTick;

  String _toTitleCase(String text) {
    return text;
  }

  Widget? get _labelWidget {
    if (widget.labelText == null || widget.labelText!.isEmpty) return null;

    final bool required = widget.labelText!.endsWith(' *');
    final String base = required
        ? widget.labelText!.substring(0, widget.labelText!.length - 2).trim()
        : widget.labelText!;

    return Builder(
      builder: (context) => RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: ResponsiveFont.getLabelFontSize(context),
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
        maxLines: widget.labelMaxLines,
        overflow: TextOverflow.visible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextStyle inputStyle = TextStyle(
      fontSize: ResponsiveFont.getInputFontSize(context),
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
      height: 1,
    );

    return FormField<T>(
      initialValue: widget.value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: widget.validator,
      builder: (field) {
        if (widget.autoOpenTick != null &&
            widget.autoOpenTick != _lastOpenedTick &&
            !widget.readOnly &&
            widget.onChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastOpenedTick = widget.autoOpenTick;
            _showSelectDialog(context, field);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AbsorbPointer(
              absorbing: widget.readOnly,
              child: Opacity(
                opacity: widget.readOnly ? 0.7 : 1.0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.readOnly || widget.onChanged == null
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _showSelectDialog(context, field);
                          },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      width: double.infinity,
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
                                      fontSize: ResponsiveFont.getLabelFontSize(context),
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: widget.labelMaxLines ?? 3,
                                    overflow: TextOverflow.ellipsis,
                                    child: _labelWidget!,
                                  ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.value != null
                                      ? widget.getLabel(widget.value as T)
                                      : (widget.hintText ?? l10n.selectOptionLabel),
                                  style: inputStyle.copyWith(
                                    color: widget.value != null
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.grey,
                                    fontWeight: FontWeight.w400,
                                    fontSize: ResponsiveFont.getHintFontSize(context)
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
    if (widget.multiSelect) {
      await _showMultiSelectDialog(context, field);
    } else {
      await _showSingleSelectDialog(context, field);
    }
  }

  Future<void> _showSingleSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    T? tempValue = widget.items.contains(widget.value) ? widget.value : null;
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
                  (widget.labelText ?? 'Select Option').replaceAll('', ''),
                  style: TextStyle(
                    fontSize: widget.labelFontSize ?? 15.sp,
                    fontWeight: FontWeight.bold,
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
                children: widget.items.isEmpty
                    ? [
                        ListTile(
                          leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                          title: Text(
                            widget.emptyOptionText ?? ('No options found'),
                            style: TextStyle(
                              fontSize: widget.labelFontSize ?? 15.sp,
                              color: Colors.grey,
                            ),
                          ),
                          enabled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                          dense: true,
                          visualDensity: const VisualDensity(vertical: -4),
                        )
                      ]
                    : widget.items.map((item) {
                        return RadioListTile<T>(
                          title: Text(
                            widget.convertToTitleCase ? _toTitleCase(widget.getLabel(item)) : widget.getLabel(item),
                            style: TextStyle(fontSize: widget.labelFontSize ?? 15.sp),
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
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (tempValue != null && widget.onChanged != null) {
                      widget.onChanged!(tempValue);
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
                      fontSize: widget.labelFontSize ?? 14.sp,
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
    List<T> tempValues = List<T>.from(widget.selectedValues);

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
                (widget.labelText ?? l10n!.selectOption).replaceAll(' *', ''),
                style: TextStyle(
                  fontSize: widget.labelFontSize ?? 16.sp,  
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
                children: widget.items.map((item) {
                  final bool isSelected = tempValues.contains(item);
                  return CheckboxListTile(
                    title: Text(
                      widget.convertToTitleCase ? _toTitleCase(widget.getLabel(item)) : widget.getLabel(item),
                      style: TextStyle(fontSize: widget.labelFontSize ?? 15.sp),
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
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onMultiChanged?.call(tempValues);
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.ok ?? 'OK',
                    style: TextStyle(
                      fontSize: widget.labelFontSize ?? 14.sp,
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
