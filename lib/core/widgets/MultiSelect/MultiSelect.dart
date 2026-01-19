import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/utils/responsive_font.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

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
    //_selectedItems = List<T>.from(widget.selectedValues);
    _selectedItems = _resolveSelectedValues(
      widget.selectedValues.map(_normalizeValue).toList(),
    );
  }

  @override
  void didUpdateWidget(MultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedValues != widget.selectedValues) {
      setState(() {
        _selectedItems = _resolveSelectedValues(
          widget.selectedValues.map(_normalizeValue).toList(),
        );
      });
    }
  }

  T _normalizeValue<T>(T value) {
    if (value is String) {
      final v = value
          .replaceAll('[', '')
          .replaceAll(']', '')
          .trim();

      switch (v) {
        case 'tb':
          return 'Tuberculosis (TB)' as T;
        case 'hep_b':
          return 'Hepetitis - B' as T;
        case 'sti_rti':
          return 'STI/RTI' as T;
        case 'hep_b':
          return 'Hepetitis - B' as T;


      // 🔹 High-risk pregnancy conditions
        case 'severe_anemia':
          return 'Severe Anemia' as T;

        case 'pih_pe_eclampsia':
          return 'Pregnancy Induced Hypertension, Pre-eclampsia, Eclampsia' as T;

        case 'symphilis_hiv_hep_b_hep_c':
          return 'Syphilis, HIV Positive, Hepatitis-B, Hepatitis-C' as T;

        case 'gestational_diabetes':
          return 'Gestational Diabetes' as T;

        case 'hypothyroidism':
          return 'Hypothyroidism' as T;

        case 'teenage_pregnancy':
          return 'Teenage Pregnancy (< 20 years) / Pregnancy After 35 Years' as T;

        case 'twins_or_more':
          return 'Pregnant With Twins Or More' as T;

        case 'mal_presentation_of_baby':
          return 'Mal Presentation of Baby (Breech / Transverse / Oblique)' as T;

        case 'previous_c_section':
          return 'Previous Cesarean Delivery' as T;

        case 'plecenta_previa':
          return 'Placenta Previa' as T;

        case 'complex_history':
          return 'Previous History of Neo-Natal Death, Still Birth, Premature Births, Repeated Abortions, PIH, PPH, APH, Obstructed Labour' as T;

        case 'rh_negative':
          return 'RH Negative' as T;

        case 'lpg':
          return 'LPG' as T;
        case 'firewood':
          return 'Firewood' as T;
        case 'coal':
          return 'Coal' as T;
        case 'kerosene':
          return 'Kerosene' as T;
        case 'crop_residue':
          return 'Crop Residue' as T;
        case 'dunk_cake':
          return 'Dung Cake' as T;
        case 'other':
          return 'Other' as T;

      }
    }
    return value;
  }




  /*@override
  void didUpdateWidget(MultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      print('🔍 MultiSelect didUpdateWidget: selectedValues changed from ${oldWidget.selectedValues} to ${widget.selectedValues}');
      setState(() {
       // _selectedItems = List<T>.from(widget.selectedValues);
        _selectedItems = _resolveSelectedValues(widget.selectedValues);
      });
    }
  }*/

  String _sanitizeRaw(dynamic raw) {
    return raw
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .trim();
  }


  List<T> _resolveSelectedValues(List<dynamic> rawValues) {
    final List<T> resolved = [];

    for (final raw in rawValues) {
      final cleanedRaw = _sanitizeRaw(raw);

      for (final item in widget.items) {
        if (_matchesValue(item, cleanedRaw)) {
          resolved.add(item.value);
          break;
        }
      }
    }
    return resolved;
  }



  /*List<T> _resolveSelectedValues(List<T> rawValues) {
    final List<T> resolved = [];

    for (final raw in rawValues) {
      for (final item in widget.items) {
        if (_matchesValue(item, raw)) {
          resolved.add(item.value);
          break;
        }
      }
    }
    return resolved;
  }*/

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matchesValue(MultiSelectItem<T> item, dynamic rawValue) {
    if (rawValue == null) return false;

    final normalizedRaw = _normalize(rawValue.toString());
    final normalizedValue = _normalize(item.value.toString());
    final normalizedLabel = _normalize(item.label);

    return normalizedRaw == normalizedValue ||
        normalizedRaw == normalizedLabel;
  }

  Future<void> _showMultiSelect() async {
    if (widget.isDisabled) return;
    final l10n = AppLocalizations.of(context);
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
                      final selected = localSelectedItems.any(
                            (e) => _matchesValue(item, _sanitizeRaw(e)),
                      );

                      /* final selected =
                      localSelectedItems.contains(item.value);
*/
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
                              if (!localSelectedItems.any((e) => _matchesValue(item, e))) {
                                localSelectedItems.add(item.value);
                              }
                            } else {
                              localSelectedItems.removeWhere(
                                    (e) => _matchesValue(item, _sanitizeRaw(e)),
                              );
                            }
                            /*if (value == true) {
                              localSelectedItems.add(item.value);
                            } else {
                              localSelectedItems.remove(item.value);
                            }*/
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
                        l10n!.cancel,
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
                        l10n!.ok,
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
                  child: Builder(
                    builder: (context) {
                      final displayText = _selectedItems.isEmpty
                          ? widget.hintText
                          : _selectedItems
                          .map((item) {
                        final foundItem = widget.items.firstWhere(
                              (e) => _matchesValue(e, _sanitizeRaw(item)),
                          orElse: () => MultiSelectItem(
                            label: item.toString(),
                            value: item,
                          ),
                        );
                        return foundItem.label;
                      })
                          .join(', ');

                      /*final displayText = _selectedItems.isEmpty
                          ? widget.hintText
                          : _selectedItems
                          .map((item) {
                            *//*final foundItem = widget.items
                                .where((e) => e.value == item)
                                .firstOrNull;*//*
                        final foundItem = widget.items
                            .firstWhere(
                              (e) => _matchesValue(e, item),
                          orElse: () => MultiSelectItem(
                            label: item.toString(),
                            value: item,
                          ),
                        );

                        return foundItem?.label ?? item.toString();
                          })
                          .join(', ');*/
                      
                      print('🔍 MultiSelect build: _selectedItems=$_selectedItems, displayText="$displayText"');
                      
                      return Text(
                        displayText,
                        style: TextStyle(
                          color: _selectedItems.isEmpty
                              ? AppColors.grey
                              : AppColors.onSurface,
                          fontSize:
                          ResponsiveFont.getHintFontSize(context),
                        ),
                      );
                    }
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
