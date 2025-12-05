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

  DateTime _getValidInitialDate() {
    final now = DateTime.now();
    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(2100);
    
    // Check if this is for a child (15 years range)
    final isChildDateRange = firstDate == DateTime.now().subtract(const Duration(days: 15 * 365));
    
    // If there's a selected date and it's within range, use it
    if (_selectedDate != null) {
      if (isChildDateRange) {
        // For child date range, check if selected date is within the last 15 years
        final minChildDate = DateTime.now().subtract(const Duration(days: 15 * 365));
        if (!_selectedDate!.isBefore(minChildDate) && !_selectedDate!.isAfter(now)) {
          return _selectedDate!;
        }
      } else if (!_selectedDate!.isBefore(firstDate) && !_selectedDate!.isAfter(lastDate)) {
        return _selectedDate!;
      }
    }
    
    // For child date range, default to 1 year ago
    if (isChildDateRange) {
      return now.subtract(const Duration(days: 365));
    }
    
    // If no date is selected or it's invalid, use today's date if it's within range
    if (!now.isBefore(firstDate) && !now.isAfter(lastDate)) {
      return now;
    }
    
    // If today is not in range, use the closest valid date
    if (now.isBefore(firstDate)) {
      return firstDate;
    } else {
      return lastDate;
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.isEditable || widget.readOnly) return;

    final firstDate = widget.firstDate ?? DateTime(1900);
    final lastDate = widget.lastDate ?? DateTime(2100);
    
    // Always get a valid initial date, regardless of current _selectedDate
    final initialDate = _getValidInitialDate();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
            fontSize: 13.5.sp,
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
          padding: const EdgeInsets.only(top: 6.0, bottom: 6),
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
                        // vertical: 0.3.h
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