import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

// Custom TextInputFormatter for Title Case
class TitleCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Convert to title case
    final titleCaseText = _toTitleCase(newValue.text);

    return TextEditingValue(
      text: titleCaseText,
      selection: newValue.selection,
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

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
  final bool enableTitleCase; // New parameter to enable/disable title case

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
    this.enableTitleCase = false, // Default is false for backward compatibility
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

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;

    // Apply title case to initial value if enabled
    final initialText = widget.enableTitleCase && widget.initialValue != null
        ? _toTitleCase(widget.initialValue!)
        : widget.initialValue ?? '';

    _controller = widget.controller ?? TextEditingController(text: initialText);
    _isDirty = widget.initialValue?.isNotEmpty ?? false;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller?.dispose();

      final initialText = widget.enableTitleCase && widget.initialValue != null
          ? _toTitleCase(widget.initialValue!)
          : widget.initialValue ?? '';

      _controller = widget.controller ?? TextEditingController(text: initialText);
    }

    if (widget.controller == null) {
      _controller ??= TextEditingController();
      final newText = widget.enableTitleCase && widget.initialValue != null
          ? _toTitleCase(widget.initialValue!)
          : widget.initialValue ?? '';

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

    // Build input formatters list
    final List<TextInputFormatter> formatters = [
      ...?widget.inputFormatters,
      if (widget.enableTitleCase) TitleCaseTextInputFormatter(),
    ];

    return TextFormField(
      controller: _controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      initialValue: null,
      textAlignVertical: TextAlignVertical.center,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
      inputFormatters: formatters,
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
              style: inputStyle.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            softWrap: true,
            maxLines: widget.labelMaxLines,
            overflow: TextOverflow.visible,
          ),
        )
            : null,
        labelStyle: inputStyle.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: inputStyle.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: widget.hintText,
        hintStyle: inputStyle.copyWith(color: AppColors.onSurfaceVariant),

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