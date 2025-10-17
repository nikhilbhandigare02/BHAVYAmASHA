import 'package:flutter/material.dart';

class ApiDropdown<T> extends StatelessWidget {
  final String labelText;
  final List<T> items;
  final String Function(T) getLabel;
  final T? value;
  final Function(T?)? onChanged;
  final bool isExpanded;
  final String? hintText;
  final FormFieldValidator<T>? validator;

  const ApiDropdown({
    super.key,
    required this.labelText,
    required this.items,
    required this.getLabel,
    this.value,
    this.onChanged,
    this.isExpanded = true,
    this.hintText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      hint: hintText != null ? Text(hintText!) : null,
      // validator: (val) {
      //   if (validator != null) {
      //     final error = validator!(val);
      //     if (error != null && error.isNotEmpty) {
      //       // 🔹 Show validation error as SnackBar
      //       WidgetsBinding.instance.addPostFrameCallback((_) {
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           SnackBar(
      //             content: Text(error),
      //             backgroundColor: Colors.redAccent,
      //             behavior: SnackBarBehavior.floating,
      //           ),
      //         );
      //       });
      //     }
      //     return null;
      //   }
      //   return null;
      // },
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
