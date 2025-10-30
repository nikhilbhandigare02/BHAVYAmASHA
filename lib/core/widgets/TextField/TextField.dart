import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

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
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller ??= TextEditingController();
    final newText = widget.initialValue ?? '';
    final oldInit = oldWidget.initialValue ?? '';
    final currText = _controller!.text;
    final shouldUpdate =
        // update if text is currently empty
        currText.isEmpty ||
        // or if it still matches the old initialValue (user hasn't edited)
        currText == oldInit ||
        // or if upstream is progressively providing a longer value (prefill flow)
        (newText.length >= currText.length && newText.startsWith(currText));
    if (shouldUpdate && currText != newText) {
      _controller!.text = newText;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 14.sp,
      color: AppColors.onSurfaceVariant,
      height: 1.5
    );

    return TextFormField(
      controller: _controller,
      // initialValue must be null when controller is provided
      initialValue: null,
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
        contentPadding: EdgeInsets.symmetric(
          vertical: 1.5.h,
          horizontal: 3.w,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: inputStyle,
    );
  }
}
