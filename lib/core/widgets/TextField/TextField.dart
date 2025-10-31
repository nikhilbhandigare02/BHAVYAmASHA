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

    // Only update text if we're managing our own controller
    if (widget.controller == null) {
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
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it ourselves
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
        height: 1
    );

    return TextFormField(
      controller: _controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: null,
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
      validator: _isDirty ? widget.validator : null,
      obscureText: widget.obscureText ? _isObscure : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.primary,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        // Add padding around the label to create a gap.
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
                  overflow: TextOverflow.visible,),
              )
            : null,
        labelStyle: inputStyle,
        floatingLabelStyle: inputStyle,
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
          vertical: 0.8.h,
          horizontal: 3.w,
        ),
        counterText: "",
        counterStyle: const TextStyle(height: 0, color: Colors.transparent),
        errorStyle: TextStyle(
          fontSize: 11.sp,
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
