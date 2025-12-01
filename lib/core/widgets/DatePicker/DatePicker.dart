import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

// A custom date picker widget that provides a text field interface.
class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final bool isEditable;
  final Function(DateTime?)? onDateChanged;
  final String labelText;
  final String? hintText;
  final String? Function(DateTime?)? validator;
  final int? labelMaxLines;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool readOnly;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.isEditable = true,
    this.readOnly = false,
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
  DateTime? _selectedDate;
  late TextEditingController _controller;
  
  DateTime? get selectedDate => _selectedDate;
  set selectedDate(DateTime? value) {
    if (_selectedDate != value) {
      _selectedDate = value;
      _updateControllerText();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(CustomDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      _selectedDate = widget.initialDate;
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    if (_selectedDate != null) {
      _controller.text = DateFormat('dd-MM-yyyy').format(_selectedDate!);
    } else {
      _controller.clear();
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.isEditable || widget.readOnly) return;

    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(2100);

    DateTime initial = _selectedDate ?? DateTime.now();
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    } else if (initial.isAfter(lastDate)) {
      initial = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateControllerText();
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

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13.sp,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Match the TextField's input style
    final TextStyle inputStyle = TextStyle(
      fontSize: 15.sp,
      color: AppColors.onSurfaceVariant,
      height: 1.5,
    );
    
    // Style for hint text to match TextField
    final hintStyle = inputStyle.copyWith(
      color: Theme.of(context).hintColor,
    );

    return GestureDetector(
      onTap: widget.isEditable && !widget.readOnly ? () => _pickDate(context) : null,
      child: AbsorbPointer(
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.labelText.isNotEmpty) _labelWidget!,
              // const SizedBox(height: 4),
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Actual text field
                  TextFormField(
                    controller: _controller,
                    readOnly: true,
                    style: inputStyle,
                    validator: widget.validator != null
                        ? (value) => widget.validator!(selectedDate)
                        : null,
                    decoration: InputDecoration(
                      hintText: _selectedDate == null ? (widget.hintText ?? 'dd-MM-yyyy') : null,
                      hintStyle: hintStyle,
                      errorStyle: TextStyle(
                        fontSize: 13.sp,
                        height: 1,
                        color: Colors.red[700],
                      ),
                      suffixIcon: widget.isEditable && !widget.readOnly
                          ? Padding(
                              padding: EdgeInsets.only(right: 2.w),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey,
                                size: 14.sp,
                              ),
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 1.w,
                        vertical: 1.h
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ],
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