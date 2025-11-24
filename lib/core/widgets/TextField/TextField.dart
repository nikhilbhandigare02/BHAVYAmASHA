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
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;

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
    this.controller,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;
  TextEditingController? _controller;
  bool _isDirty = false;

  List<TextSpan> _buildLabelTextSpans(String text) {
    if (!text.endsWith(' *')) {
      return [TextSpan(text: text)];
    }

    final parts = text.split(' *');
    return [
      TextSpan(text: parts[0]),
      const TextSpan(
        text: ' *',
        style: TextStyle(color: Colors.red),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue ?? '');
    _isDirty = widget.initialValue?.isNotEmpty ?? false;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller?.dispose();
      _controller = widget.controller ?? TextEditingController(text: widget.initialValue ?? '');
    }

    if (widget.controller == null) {
      _controller ??= TextEditingController();
      final newText = widget.initialValue ?? '';
      final oldInit = oldWidget.initialValue ?? '';
      final currText = _controller!.text;
      final shouldUpdate =
          currText.isEmpty ||
              currText == oldInit ||
              (newText.length >= currText.length && newText.startsWith(currText));
      if (shouldUpdate && currText != newText) {
        _controller!.text = newText;
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 15.sp,
      color: AppColors.onSurfaceVariant,
      height: 1.5,
    );

    return TextFormField(
      controller: _controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: null,
      textAlignVertical: TextAlignVertical.center, // ✅ Keeps text & icon centered
      onChanged: (value) {
        if (!_isDirty && value.isNotEmpty) {
          setState(() {
            _isDirty = true;
          });
        }
        widget.onChanged?.call(value);
      },
      onTap: () {
        if (!_isDirty) {
          setState(() {
            _isDirty = true;
          });
        }
      },
      validator: widget.validator,
      obscureText: widget.obscureText ? _isObscure : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.primary,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        isDense: true,
        label: (widget.labelText != null && widget.labelText!.isNotEmpty)
            ? Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RichText(
            text: TextSpan(
              children: _buildLabelTextSpans(widget.labelText!),
              style: inputStyle,
            ),
            softWrap: true,
            maxLines: widget.labelMaxLines,
            overflow: TextOverflow.visible,
          ),
        )
            : null,
        labelStyle: inputStyle,
        floatingLabelStyle: inputStyle,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: widget.hintText,
        hintStyle: inputStyle.copyWith(color: AppColors.onSurfaceVariant),

        // ✅ Properly aligned prefix icon
        prefixIcon: widget.prefixIcon != null
            ? Padding(
          padding: EdgeInsets.only(left: 3.w, right: 2.w),
          child: Icon(
            widget.prefixIcon,
            size: 18.sp,
            color: AppColors.onSurfaceVariant,
          ),
        )
            : null,
        prefixIconConstraints: BoxConstraints(
          minWidth: 8.w,
          minHeight: 4.h,
        ),

        // ✅ Suffix for password toggle
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
          vertical: 1.h,
          horizontal: 1.w,
        ),
        counterText: "",
        errorStyle: TextStyle(
          fontSize: 13.sp,
          height: 1.2,
          color: Colors.red[700],
        ),
        errorMaxLines: 2,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: inputStyle,
    );
  }
}
