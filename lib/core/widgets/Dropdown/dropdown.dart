import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/utils/responsive_font.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';

class ApiDropdown<T> extends StatefulWidget {
  final String? labelText;
  final List<T> items;
  final String Function(T) getLabel;
  final bool convertToTitleCase;
  final T? value;
  final Function(T?)? onChanged;
  final bool isExpanded;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final int? labelMaxLines;
  final bool multiSelect;
  final List<T> selectedValues;
  final Function(List<T>)? onMultiChanged;

  final double? labelFontSize;
  final String? emptyOptionText;
  final bool readOnly;
  final int? autoOpenTick;


   ApiDropdown({
    super.key,
    this.labelText,
    required this.items,
    required this.getLabel,
    T? value,
    this.onChanged,
    this.isExpanded = true,
    this.hintText,
    this.validator,
    this.labelMaxLines,
    this.multiSelect = false,
    this.selectedValues = const [],
    this.onMultiChanged,
    this.labelFontSize,
    this.emptyOptionText,
    this.readOnly = false,
    this.convertToTitleCase = true,
    this.autoOpenTick,
  }): value = _normalizeValue(value);

  static T? _normalizeValue<T>(T? value) {
    if (value is String) {
      switch (value) {
        case 'not_disclosed':
          return 'Do not want to disclose' as T;
        case 'atyanth_pichda_varg':
          return 'Atyant Pichda Varg' as T;

        case 'community_toilet':
          return 'Community toilet' as T;

        case 'friend_relative_toilet':
          return 'Friend/Relative toilet' as T;

        case 'open_toilet':
          return 'Open space' as T;


      // 🔹 Place of Service / Facility cases
        case 'vhsnd_anganwadi':
          return 'VHSND/Anganwadi' as T;
        case 'hsc_and_hwc':
          return 'Health Sub-center/Health & Wealth Centre(HSC/HWC)' as T;
        case 'phc':
          return 'Primary Health Centre(PHC)' as T;
        case 'chc':
          return 'Community Health Centre (CHC)' as T;
        case 'rh':
          return 'Referral Hospital(RH)' as T;
        case 'dh':
          return 'District Hospital(DH)' as T;
        case 'mch':
          return 'Medical College Hospital(MCH)' as T;
        case 'pmsma_site':
          return 'PMSMA Site' as T;


      // 🔹 House Type cases
        case 'none':
          return 'None' as T;
        case 'kachcha':
          return 'Kuchcha House' as T;
        case 'semi_pakka_house':
          return 'Semi Pucca House' as T;
        case 'pakka_house':
          return 'Pucca House' as T;
        case 'thrust_house':
          return 'Thrust House' as T;
        case 'other':
          return 'Other' as T;

      // 🔹 Toilet Facility cases
        case 'flush_with_water':
          return 'Flush toilet with running water' as T;
        case 'flush_without_water':
          return 'Flush toilet without water' as T;
        case 'pit_toilet_with_water':
          return 'Pit toilet with running water supply' as T;
        case 'pit_toilet_without_water':
          return 'Pit toilet without water supply' as T;

      // 🔹 Drinking Water Source cases
        case 'supply_water':
          return 'Supply water' as T;
        case 'ro':
          return 'R.O.' as T;
        case 'handpump_within_house':
          return 'Hand pump within house' as T;
        case 'handpump_outside_of_house':
          return 'Hand pump outside of house' as T;
        case 'tanker':
          return 'Tanker' as T;
        case 'river':
          return 'River' as T;
        case 'pond':
          return 'Pond' as T;
        case 'lake':
          return 'Lake' as T;
        case 'well':
          return 'Well' as T;

      // 🔹 Power / Electricity Source
        case 'electricity_supply':
          return 'Electricity supply' as T;
        case 'generator':
          return 'Generator' as T;
        case 'solar_power':
          return 'Solar power' as T;
        case 'kerosene_lamp':
          return 'Kerosene lamp' as T;


      }
    }
    return value;
  }


  @override
  State<ApiDropdown<T>> createState() => _ApiDropdownState<T>();

}



class _ApiDropdownState<T> extends State<ApiDropdown<T>> {
  int? _lastOpenedTick;
  T? _selectedItem;
  String _toTitleCase(String text) {
    return text;
  }

  bool _isEnglishKey(String value) {
    // english keys contain only lowercase letters, numbers and underscores
    return RegExp(r'^[a-z0-9_]+$').hasMatch(value);
  }


  Widget? get _labelWidget {
    if (widget.labelText == null || widget.labelText!.isEmpty) return null;

    final bool required = widget.labelText!.endsWith(' *');
    final String base = required
        ? widget.labelText!.substring(0, widget.labelText!.length - 2).trim()
        : widget.labelText!;

    return Builder(
      builder: (context) => RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: ResponsiveFont.getLabelFontSize(context),
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,

          ),
          children: [
            TextSpan(text: base),
            if (required)
              const TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        maxLines: widget.labelMaxLines,
        overflow: TextOverflow.visible,
      ),
    );
  }

  T? _resolveSelectedItem() {
    final rawValue = widget.value?.toString();
    if (rawValue == null) return null;

    final normalizedRaw = _normalize(rawValue);

    for (final item in widget.items) {
      final key = item.toString();
      final label = widget.getLabel(item);

      if (_normalize(key) == normalizedRaw ||
          _normalize(label) == normalizedRaw) {
        return item;
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

// 🔥 keep internal state in sync with API value
    /*_selectedItem ??= matchedItem;*/
    _selectedItem = _resolveSelectedItem();

    final TextStyle inputStyle = TextStyle(
      fontSize: ResponsiveFont.getInputFontSize(context),
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
      height: 1,
    );

    /*String displayText() {
      final rawValue = widget.value?.toString();
      if (rawValue == null) {
        return widget.hintText ?? l10n.selectOptionLabel;
      }

      // 1️⃣ If already localized (Hindi), return as-is
      if (!_isEnglishKey(rawValue)) {
        return rawValue;
      }

      // 2️⃣ Try to find matching item safely
      T? matchedItem;
      for (final item in widget.items) {
        if (_normalize(widget.getLabel(item)) == _normalize(rawValue)) {
          matchedItem = item;
          break;
        }
      }

      if (matchedItem != null) {
        return widget.getLabel(matchedItem);
      }

      // 3️⃣ Fallback
      return rawValue;
    }*/

    /*String displayText() {
      final rawValue = widget.value;
      if (rawValue == null) {
        return widget.hintText ?? l10n.selectOptionLabel;
      }

      for (final item in widget.items) {
        // Compare using value/key, NOT label
        if (item.toString() == rawValue.toString()) {
          // Always return localized label
          return widget.getLabel(item);
        }
      }

      // Fallback (already localized or legacy)
      return rawValue.toString();
    }*/
    bool _isHintSelected() {
      return widget.value == null ||
          widget.value.toString().trim().isEmpty ||
          _resolveSelectedItem() == null;
    }

    String displayText() {
      final rawValue = widget.value?.toString();

      if (rawValue == null || rawValue.trim().isEmpty) {
        return widget.hintText ?? l10n.selectOptionLabel;
      }

      final normalizedRaw = _normalize(rawValue);

      for (final item in widget.items) {
        final key = item.toString();
        final label = widget.getLabel(item);

        // ✅ Match by key
        if (_normalize(key) == normalizedRaw) {
          return label;
        }

        if (_normalize(label) == normalizedRaw) {
          return label;
        }
      }

      // ✅ Case 2: value not found in items → show hint
      return widget.hintText ?? l10n.selectOptionLabel;
    }





    return FormField<T>(
      initialValue: widget.value,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: widget.validator,
      builder: (field) {
        if (widget.autoOpenTick != null &&
            widget.autoOpenTick != _lastOpenedTick &&
            !widget.readOnly &&
            widget.onChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _lastOpenedTick = widget.autoOpenTick;
            _showSelectDialog(context, field);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AbsorbPointer(
              absorbing: widget.readOnly,
              child: Opacity(
                opacity: widget.readOnly ? 0.7 : 1.0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.readOnly || widget.onChanged == null
                        ? null
                        : () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _showSelectDialog(context, field);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 🔹 Label and value side by side
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_labelWidget != null)
                                  DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: ResponsiveFont.getLabelFontSize(context),
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    maxLines: widget.labelMaxLines ?? 3,
                                    overflow: TextOverflow.ellipsis,
                                    child: _labelWidget!,
                                  ),
                                const SizedBox(height: 3),



                                Text(
                                  displayText(),
                                  style: inputStyle.copyWith(
                                    color: _isHintSelected()
                                        ? AppColors.grey              // ✅ "Select option"
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                    fontSize: ResponsiveFont.getHintFontSize(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                /*Text(
                                  widget.value != null
                                      ? widget.getLabel(widget.value as T)
                                      : (widget.hintText ?? l10n.selectOptionLabel),
                                  style: inputStyle.copyWith(
                                      color: widget.value != null
                                          ? AppColors.onSurfaceVariant
                                          : AppColors.grey,
                                      fontWeight: FontWeight.w400,
                                      fontSize: ResponsiveFont.getHintFontSize(context)
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),*/
                              ],
                            ),
                          ),
                          // 🔹 Dropdown arrow
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.2,
                    color: Colors.red[700],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    if (widget.multiSelect) {
      await _showMultiSelectDialog(context, field);
    } else {
      await _showSingleSelectDialog(context, field);
    }
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _showSingleSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    // T? tempValue = widget.items.contains(widget.value) ? widget.value : null;

    /*T? tempValue;

    if (widget.value != null) {
      for (final item in widget.items) {
        if (_normalize(widget.getLabel(item)) ==
            _normalize(widget.value.toString())) {
          tempValue = item;
          break;
        }
      }
    }*/

    T? tempValue = _resolveSelectedItem();

    final l10n = AppLocalizations.of(context);


    await showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.5.h),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (widget.labelText ?? 'Select Option').replaceAll('', ''),
                  style: TextStyle(
                    fontSize: widget.labelFontSize ?? 15.sp,
                    fontWeight: FontWeight.bold,
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
                children: widget.items.isEmpty
                    ? [
                  ListTile(
                    leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                    title: Text(
                      widget.emptyOptionText ?? ('No options found'),
                      style: TextStyle(
                        fontSize: widget.labelFontSize ?? 15.sp,
                        color: Colors.grey,
                      ),
                    ),
                    enabled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                  )
                ]
                    : widget.items.map((item) {
                  return RadioListTile<T>(
                    title: Text(
                      widget.convertToTitleCase ? _toTitleCase(widget.getLabel(item)) : widget.getLabel(item),
                      style: TextStyle(fontSize: widget.labelFontSize ?? 15.sp),
                    ),
                    value: item,
                    groupValue: tempValue,
                    onChanged: (val) => setState(() => tempValue = val),
                    contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
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
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.cancel ?? 'CANCEL',
                    style: TextStyle(
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (tempValue != null && widget.onChanged != null) {
                      setState(() {
                        _selectedItem = tempValue; // 🔥 update display immediately
                      });
                      widget.onChanged!(tempValue);
                      field.didChange(tempValue);
                    }
                    /*if (tempValue != null && widget.onChanged != null) {
                      widget.onChanged!(tempValue);
                      field.didChange(tempValue);
                    }*/
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.ok ?? 'OK',
                    style: TextStyle(
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _showMultiSelectDialog(
      BuildContext context, FormFieldState<T> field) async {
    List<T> tempValues = List<T>.from(widget.selectedValues);

    final l10n = AppLocalizations.of(context);
    await showDialog<List<T>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.5.h),
          ),
          title: Column(
            children: <Widget>[
              Text(
                (widget.labelText ?? l10n!.selectOption).replaceAll(' *', ''),
                style: TextStyle(
                  fontSize: widget.labelFontSize ?? 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Divider(height: 2),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 40.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.map((item) {
                  final bool isSelected = tempValues.contains(item);
                  return CheckboxListTile(
                    title: Text(
                      widget.convertToTitleCase ? _toTitleCase(widget.getLabel(item)) : widget.getLabel(item),
                      style: TextStyle(fontSize: widget.labelFontSize ?? 15.sp),
                    ),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          if (!tempValues.contains(item)) tempValues.add(item);
                        } else {
                          tempValues.remove(item);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(vertical: 0.2.h),
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.cancel ?? 'CANCEL',
                    style: TextStyle(
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onMultiChanged?.call(tempValues);
                    FocusManager.instance.primaryFocus?.unfocus();
                    FocusScope.of(context).unfocus();
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n?.ok ?? 'OK',
                    style: TextStyle(
                      fontSize: widget.labelFontSize ?? 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    FocusScope.of(context).unfocus();
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
