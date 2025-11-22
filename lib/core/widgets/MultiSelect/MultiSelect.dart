import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MultiSelect<T> extends StatefulWidget {
  final List<MultiSelectItem<T>> items;
  final List<T> selectedValues;
  final String labelText;
  final String hintText;
  final Function(List<T>) onSelectionChanged;
  final bool isRequired;
  final bool isDisabled;
  final String? Function(List<T>?)? validator;

  const MultiSelect({
    Key? key,
    required this.items,
    required this.selectedValues,
    required this.labelText,
    required this.hintText,
    required this.onSelectionChanged,
    this.isRequired = false,
    this.isDisabled = false,
    this.validator,
  }) : super(key: key);

  @override
  _MultiSelectState<T> createState() => _MultiSelectState<T>();
}

class _MultiSelectState<T> extends State<MultiSelect<T>> {
  List<T> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems = List<T>.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(MultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      setState(() {
        _selectedItems = List<T>.from(widget.selectedValues);
      });
    }
  }

  Future<void> _showMultiSelect() async {
    if (widget.isDisabled) return;

    final result = await showDialog<List<T>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog<T>(
          title: widget.labelText,
          items: widget.items,
          selectedValues: _selectedItems,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedItems = result;
      });
      widget.onSelectionChanged(_selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              text: widget.labelText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(

              fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
                  ),
              children: widget.isRequired
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
          SizedBox(height: 0.2.h),
        ],
        InkWell(
          onTap: _showMultiSelect,
          child: InputDecorator(
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,


              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 14.0,
              ),
              suffixIcon: Icon(Icons.arrow_drop_down),
              filled: widget.isDisabled,
              fillColor: widget.isDisabled
                  ? Theme.of(context).disabledColor.withOpacity(0.04)
                  : null,
            ),
            child: Text(
              _selectedItems.isEmpty
                  ? widget.hintText
                  : _selectedItems
                      .map((item) => widget.items
                          .firstWhere((element) => element.value == item)
                          .label)
                      .join(', '),
              style: TextStyle(
                color: _selectedItems.isEmpty
                    ? Theme.of(context).hintColor
                    : null,
              ),
            ),
          ),
        ),
        if (widget.validator != null)
          Builder(
            builder: (context) {
              final errorText = widget.validator?.call(_selectedItems);
              if (errorText == null) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                child: Text(
                  errorText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class MultiSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<MultiSelectItem<T>> items;
  final List<T> selectedValues;

  const MultiSelectDialog({
    Key? key,
    required this.title,
    required this.items,
    required this.selectedValues,
  }) : super(key: key);

  @override
  _MultiSelectDialogState<T> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List<T>.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: widget.items.map((item) {
            return CheckboxListTile(
              title: Text(item.label,
                  ),
              value: _selectedItems.contains(item.value),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedItems.add(item.value);
                  } else {
                    _selectedItems.remove(item.value);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedItems),
          child: Text('OK'),
        ),
      ],
    );
  }
}

class MultiSelectItem<T> {
  final String label;
  final T value;

  MultiSelectItem({
    required this.label,
    required this.value,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiSelectItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}
