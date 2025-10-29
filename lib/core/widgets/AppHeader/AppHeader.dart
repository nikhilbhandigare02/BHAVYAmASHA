import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final bool showBack;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;

  final IconData? icon1;
  final VoidCallback? onIcon1Tap;
  final Widget? icon1Widget;

  final IconData? icon2;
  final VoidCallback? onIcon2Tap;
  final Widget? icon2Widget;

  final IconData? icon3;
  final VoidCallback? onIcon3Tap;
  final Widget? icon3Widget;

  const AppHeader({
    super.key,
    required this.screenTitle,
    this.showBack = false,
    this.onBackTap,
    this.onMenuTap,
    this.icon1,
    this.onIcon1Tap,
    this.icon1Widget,
    this.icon2,
    this.onIcon2Tap,
    this.icon2Widget,
    this.icon3,
    this.onIcon3Tap,
    this.icon3Widget,
  });

  @override
  @override
  Size get preferredSize => Size.fromHeight(10.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: EdgeInsets.only(top: 2.5.h),
        child: Row(
          children: [
            showBack
                ? IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: onBackTap ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
                : IconButton(
              icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: 1.w),
            // Title takes remaining space
            Expanded(
              child: Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Icon1
            if (icon1Widget != null)
              GestureDetector(
                onTap: onIcon1Tap,
                child: icon1Widget,
              )
            else if (icon1 != null)
              IconButton(
                icon: Icon(icon1, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: onIcon1Tap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            // Icon2
            if (icon2Widget != null)
              GestureDetector(
                onTap: onIcon2Tap,
                child: icon2Widget,
              )
            else if (icon2 != null)
              IconButton(
                icon: Icon(icon2, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: onIcon2Tap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            // Icon3
            if (icon3Widget != null)
              GestureDetector(
                onTap: onIcon3Tap,
                child: icon3Widget,
              )
            else if (icon3 != null)
              IconButton(
                icon: Icon(icon3, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: onIcon3Tap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
