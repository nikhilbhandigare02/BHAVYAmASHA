import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final bool showBack;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final IconData? icon1;
  final VoidCallback? onIcon1Tap;
  final IconData? icon2;
  final VoidCallback? onIcon2Tap;
  final IconData? icon3;
  final VoidCallback? onIcon3Tap;

  const AppHeader({
    super.key,
    required this.screenTitle,
    this.showBack = false,
    this.onBackTap,
    this.onMenuTap,
    this.icon1,
    this.onIcon1Tap,
    this.icon2,
    this.onIcon2Tap,
    this.icon3,
    this.onIcon3Tap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.only(top: 22.0),
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

            const SizedBox(width: 4),

            // Title takes the remaining space
            Expanded(
              child: Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis, // prevent overflow
              ),
            ),

            if (icon1 != null)
              IconButton(
                icon: Icon(icon1, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: onIcon1Tap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (icon2 != null)
              IconButton(
                icon: Icon(icon2, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: onIcon2Tap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (icon3 != null)
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
