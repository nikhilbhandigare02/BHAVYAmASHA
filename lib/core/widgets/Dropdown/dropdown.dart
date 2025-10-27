import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    );

    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      style: inputStyle,
      decoration: InputDecoration(
        label: (labelText != null && labelText!.isNotEmpty)
            ? Text(
                labelText!,
                softWrap: true,
                maxLines: labelMaxLines,
                overflow: TextOverflow.visible,
              )
            : null,
        hintText: hintText,
        hintStyle: inputStyle.copyWith(color: AppColors.onSurfaceVariant),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getLabel(item), style: inputStyle),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
