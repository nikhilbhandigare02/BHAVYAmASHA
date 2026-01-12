import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

class CenterBoxLoaderLogin extends StatelessWidget {
  const CenterBoxLoaderLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed background
        // Container(color: AppColors.background),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.26),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: _LoaderSpinner(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoaderSpinner extends StatelessWidget {
  const _LoaderSpinner();

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: 3.5,
      color: AppColors.primary,
    );
  }
}
