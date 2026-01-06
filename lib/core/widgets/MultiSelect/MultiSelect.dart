import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/utils/responsive_font.dart';
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

    final localSelectedItems = List<T>.from(_selectedItems);

    final result = await showDialog<List<T>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.5.h),
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.labelText,
                      style: TextStyle(
                        fontSize:
                        ResponsiveFont.getLabelFontSize(context) + 2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 10),
                  ],
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 40.h),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.map((item) {
                      final selected =
                      localSelectedItems.contains(item.value);

                      return CheckboxListTile(
                        title: Text(
                          item.label,
                          style: TextStyle(
                            fontSize:
                            ResponsiveFont.getLabelFontSize(context) + 3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: selected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              localSelectedItems.add(item.value);
                            } else {
                              localSelectedItems.remove(item.value);
                            }
                          });
                        },
                        controlAffinity:
                        ListTileControlAffinity.leading,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 0.1.h),
                        dense: false,
                        visualDensity:
                        const VisualDensity(vertical: -2),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                const Divider(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize:
                          ResponsiveFont.getLabelFontSize(context) + 1,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pop(context, localSelectedItems);
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize:
                          ResponsiveFont.getLabelFontSize(context) + 1,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.87),
              ),
              children: widget.isRequired
                  ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color:
                    Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
                  : [],
            ),
          ),
        ],
        InkWell(
          onTap: _showMultiSelect,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? Theme.of(context)
                  .disabledColor
                  .withOpacity(0.04)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedItems.isEmpty
                        ? widget.hintText
                        : _selectedItems
                        .map((item) => widget.items
                        .firstWhere(
                            (e) => e.value == item)
                        .label)
                        .join(', '),
                    style: TextStyle(
                      color: _selectedItems.isEmpty
                          ? AppColors.grey
                          : AppColors.onSurface,
                      fontSize:
                      ResponsiveFont.getHintFontSize(context),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down,
                    color: Colors.grey),
              ],
            ),
          ),
        ),
        if (widget.validator != null)
          Builder(
            builder: (context) {
              final errorText =
              widget.validator?.call(_selectedItems);
              if (errorText == null) return const SizedBox.shrink();
              return Padding(
                padding:
                const EdgeInsets.only(top: 4.0, left: 12.0),
                child: Text(
                  errorText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),
                ),
              );
            },
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
