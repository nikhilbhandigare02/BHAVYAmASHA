import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final bool isEditable;
  final Function(DateTime?)? onDateChanged;
  final String labelText;
  final String? hintText;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.isEditable = true,
    this.onDateChanged,
    this.labelText = 'Select Date',
    this.hintText,
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
      text: selectedDate != null ? DateFormat('dd/MM/yy').format(selectedDate!) : '',
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!widget.isEditable) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yy').format(picked);
      });
      if (widget.onDateChanged != null) widget.onDateChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = selectedDate != null ? DateFormat('dd/MM/yy').format(selectedDate!) : '';
    return AbsorbPointer(
      absorbing: !widget.isEditable,
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'dd/MM/yy',
          suffixIcon: widget.isEditable
              ? const Icon(Icons.calendar_today_outlined)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        controller: TextEditingController(text: formattedDate),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
