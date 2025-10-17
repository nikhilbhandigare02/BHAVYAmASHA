import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final bool isEditable;
  final Function(DateTime?)? onDateChanged;
  final String labelText;
  final String? hintText;
  final String? Function(DateTime?)? validator; // 🔹 External validator

  const CustomDatePicker({
    super.key,
    this.initialDate,
    this.isEditable = true,
    this.onDateChanged,
    this.labelText = 'Select Date',
    this.hintText,
    this.validator,
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E73B8),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yy').format(picked);
      });
      widget.onDateChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEditable ? () => _pickDate(context) : null,
      child: AbsorbPointer(
        absorbing: true,
        child: TextFormField(
          controller: _controller,
          readOnly: true,
          // validator: (_) {
          //   if (widget.validator != null) {
          //     final error = widget.validator!(selectedDate);
          //     if (error != null && error.isNotEmpty) {
          //       // 🔹 Show validation message as a Snackbar
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
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'dd/MM/yy',
            suffixIcon: widget.isEditable
                ? const Icon(Icons.calendar_today_outlined, color: Colors.grey)
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
