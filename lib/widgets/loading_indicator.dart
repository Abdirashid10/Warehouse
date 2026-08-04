import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.color,
    this.strokeWidth = 2.5,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? AppColors.primary,
      ),
    );
  }
}
