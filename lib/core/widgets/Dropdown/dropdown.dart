import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

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
          fontSize: 15.sp,
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
        child: DropdownButtonFormField<T>(
          value: multiSelect ? null : (value != null && items.contains(value) ? value : null),
          isExpanded: isExpanded,
          style: inputStyle,
          validator: validator,
          decoration: InputDecoration(
            label: _labelWidget,
            hintText: hintText ?? (multiSelect ? 'Select options' : 'Select'),
            hintStyle: inputStyle.copyWith(color: AppColors.outline),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                multiSelect ? _getMultiSelectDisplayText() : getLabel(item),
                style: inputStyle,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _getMultiSelectDisplayText() {
    if (selectedValues.isEmpty) {
      return hintText ?? 'Select options';
    } else if (selectedValues.length == 1) {
      return getLabel(selectedValues.first);
    } else {
      return '${selectedValues.length} items selected';
    }
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
                    fontSize: 15.sp,
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
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    value: item,
                    groupValue: tempValue,
                    onChanged: (val) => setState(() => tempValue = val),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(
                      vertical: -4,
                      horizontal: 0,
                    ),
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
                      fontSize: 14.sp,
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
                      fontSize: 14.sp,
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
                (labelText ?? 'Select Options').replaceAll(' *', ''),
                style: TextStyle(
                  fontSize: 16.sp,
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
                      style: TextStyle(fontSize: 15.sp),
                    ),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          if (!tempValues.contains(item)) {
                            tempValues.add(item);
                          }
                        } else {
                          tempValues.remove(item);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(
                      vertical: -4,
                      horizontal: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
           // const Divider(height: 0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 14.sp,
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
                      fontSize: 14.sp,
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