import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final bool? showBack; // ✅ Made nullable
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;

  // Icon 1
  final IconData? icon1;
  final String? icon1Image;
  final VoidCallback? onIcon1Tap;
  final Widget? icon1Widget;

  // Icon 2
  final IconData? icon2;
  final String? icon2Image;
  final VoidCallback? onIcon2Tap;
  final Widget? icon2Widget;

  // Icon 3
  final IconData? icon3;
  final String? icon3Image;
  final VoidCallback? onIcon3Tap;
  final Widget? icon3Widget;

  const AppHeader({
    super.key,
    required this.screenTitle,
    this.showBack, // ✅ Nullable now
    this.onBackTap,
    this.onMenuTap,
    this.icon1,
    this.icon1Image,
    this.onIcon1Tap,
    this.icon1Widget,
    this.icon2,
    this.icon2Image,
    this.onIcon2Tap,
    this.icon2Widget,
    this.icon3,
    this.icon3Image,
    this.onIcon3Tap,
    this.icon3Widget,
  });

  @override
  Size get preferredSize => Size.fromHeight(10.h);

  Widget _buildIcon({
    IconData? icon,
    String? imagePath,
    Widget? widget,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    if (widget != null) {
      return GestureDetector(onTap: onTap, child: widget);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Image.asset(
            imagePath,
            height: 2.8.h,
            width: 2.8.h,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    } else if (icon != null) {
      return IconButton(
        icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 17.sp),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: EdgeInsets.only(top: 3.5.h),
        child: Row(
          children: [
            // ✅ If showBack == true, show back button; if false or null, show menu
            (showBack ?? false)
                ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: onBackTap ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
                : IconButton(
              icon: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            SizedBox(width: 1.w),

            Expanded(
              child: Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ✅ Icon 1, 2, 3 (now with image & widget support)
            _buildIcon(
              icon: icon1,
              imagePath: icon1Image,
              widget: icon1Widget,
              onTap: onIcon1Tap,
              context: context,
            ),
            _buildIcon(
              icon: icon2,
              imagePath: icon2Image,
              widget: icon2Widget,
              onTap: onIcon2Tap,
              context: context,
            ),
            _buildIcon(
              icon: icon3,
              imagePath: icon3Image,
              widget: icon3Widget,
              onTap: onIcon3Tap,
              context: context,
            ),
          ],
        ),
      ),
    );
  }
}
