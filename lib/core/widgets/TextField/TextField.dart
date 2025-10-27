import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

class CustomTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? labelMaxLines;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.inputFormatters,
    this.maxLength,
    this.labelMaxLines,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 16,
      color: AppColors.onSurfaceVariant
    );

    return TextFormField(
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      obscureText: widget.obscureText ? _isObscure : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        label: (widget.labelText != null && widget.labelText!.isNotEmpty)
            ? Text(
                widget.labelText!,
                softWrap: true,
                maxLines: widget.labelMaxLines,
                overflow: TextOverflow.visible,
                style: inputStyle,
              )
            : null,
        hintText: widget.hintText,
        hintStyle: inputStyle.copyWith(color: AppColors.onSurfaceVariant),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: AppColors.onSurfaceVariant)
            : null,
        suffixIcon: widget.obscureText
            ? IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.onSurfaceVariant,
          ),
          onPressed: () => setState(() {
            _isObscure = !_isObscure;
          }),
        )
            : null,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: inputStyle,
    );
  }
}
