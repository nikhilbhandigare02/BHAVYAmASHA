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
      child: AbsorbPointer( // disables default dropdown behavior
        child: DropdownButtonFormField<T>(
          value: multiSelect ? null : value,
          isExpanded: isExpanded,
          style: inputStyle,
          decoration: InputDecoration(
            label: (labelText != null && labelText!.isNotEmpty)
                ? Text(
              labelText!,
              softWrap: true,
              maxLines: labelMaxLines,
              overflow: TextOverflow.visible,
              style: TextStyle(fontSize: 15.sp),
            )
                : null,
            hintText: hintText,
            hintStyle: inputStyle.copyWith(color: AppColors.onSurfaceVariant),
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
          onChanged: onChanged, // handled via dialog
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
    T? tempValue = value;

    await showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.5.h),
              ),
              title: Column(
                children: <Widget>[
                  Text(
                    labelText ?? 'Select Option',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 2,)
                ],
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
                        contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
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
                Divider(height: 0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (onChanged != null && tempValue != null) {
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
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    List<T> tempValues = List<T>.from(selectedValues);

    await showDialog<List<T>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.5.h),
              ),
              title: Column(
                children: <Widget>[
                  Text(
                    labelText ?? 'Select Options',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Divider(height: 2,)
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 40.h),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) {
                      bool isSelected = tempValues.contains(item);
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
                        contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
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
                Divider(height: 0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (onMultiChanged != null) {
                          onMultiChanged!(tempValues);
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
                )
              ],
            );
          },
        );
      },
    );
  }
}