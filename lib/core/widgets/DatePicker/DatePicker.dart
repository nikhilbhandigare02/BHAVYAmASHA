import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final bool isEditable;
  final Function(DateTime?)? onDateChanged;
  final String labelText;               // e.g. "Birth date *"  (asterisk optional)
  final String? hintText;
  final String? Function(DateTime?)? validator;
  final int? labelMaxLines;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.isEditable = true,
    this.onDateChanged,
    this.labelText = 'Select Date',
    this.hintText,
    this.validator,
    this.labelMaxLines,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  DateTime? selectedDate;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    _controller = TextEditingController(
      text: selectedDate != null
          ? DateFormat('dd/MM/yy').format(selectedDate!)
          : '',
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.isEditable) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yy').format(picked);
      });
      widget.onDateChanged?.call(picked);
    }
  }


  Widget? get _labelWidget {
    if (widget.labelText.isEmpty) return null;

    final bool required = widget.labelText.endsWith(' *');
    final String base = required
        ? widget.labelText.substring(0, widget.labelText.length - 2).trim()
        : widget.labelText;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15.sp,
          color: AppColors.onSurfaceVariant,
          //fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: base),
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      maxLines: widget.labelMaxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle inputStyle = TextStyle(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
      height: 1.5,
    );

    return GestureDetector(
      onTap: widget.isEditable ? () => _pickDate(context) : null,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          readOnly: true,
          style: inputStyle,
          validator: widget.validator != null
              ? (value) => widget.validator!(selectedDate)
              : null,
          decoration: InputDecoration(

            label: _labelWidget,

            hintText: widget.hintText ?? 'dd/MM/yy',
            hintStyle:
            inputStyle.copyWith(color: AppColors.onSurfaceVariant),


            suffixIcon: widget.isEditable
                ? Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey,
                size: 14.sp,
              ),
            )
                : null,
            suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),


            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 1.w,
              vertical: 1.h,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}