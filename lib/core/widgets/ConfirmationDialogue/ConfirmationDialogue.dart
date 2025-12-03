import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../config/themes/CustomColors.dart';

Future<List<String>?> showMultiSelectDialog({
  required BuildContext context,
  required String title,
  required List<String> items,
  required List<String> selectedItems,
  bool isSearchable = false,
  Color? dialogBackgroundColor,
  Color? titleTextColor,
  Color? selectedItemColor,
}) async {
  final localSelectedItems = Set<String>.from(selectedItems);
    return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: titleTextColor ?? AppColors.onSurfaceVariant,
                ),
              ),
              const Divider(height: 10),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 40.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) {
                  final selected = localSelectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(
                      item,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    value: selected,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          localSelectedItems.add(item);
                        } else {
                          localSelectedItems.remove(item);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    dense: true,
                    activeColor: selectedItemColor ?? Theme.of(context).primaryColor,
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
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, localSelectedItems.toList()),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 13.sp,
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
    ),
  );
}

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  String?  title,
   String? message,
  required String yesText,
  String? noText,
  VoidCallback? onYes,
  VoidCallback? onNo,

  // ✅ Optional color customizations
  Color? titleBackgroundColor,
  Color? titleTextColor,
  Color? messageTextColor,
  Color? yesButtonColor,
  Color? noButtonColor,
  Color? dialogBackgroundColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final hasTwoButtons = noText != null && noText.isNotEmpty;

      return AlertDialog(
        backgroundColor: dialogBackgroundColor ?? AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

        // 🟡 Message Section
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            message ?? '',
            style: TextStyle(
              color: messageTextColor ?? AppColors.onSurface,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 🟡 Buttons (Dynamic Layout)
        actionsAlignment:
        hasTwoButtons ? MainAxisAlignment.end : MainAxisAlignment.end,
        actions: [
          if (hasTwoButtons)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onNo != null) onNo();
              },
              child: Text(
                noText!,
                style: TextStyle(
                  color: AppColors.onSurface ?? AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              if (onYes != null) onYes();
            },
            child: Text(
              yesText,
              style: TextStyle(
                color: AppColors.onSurface ?? AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    },
  );
}
