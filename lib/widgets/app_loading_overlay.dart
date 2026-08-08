import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';

/// Full-screen or inline blocking loader for async operations.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.absorbPointer = true,
  });

  final bool isLoading;
  final Widget child;
  final String? message;
  final bool absorbPointer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: absorbPointer,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                child: Center(
                  child: Material(
                    color: WmsUiColors.of(context).surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LoadingIndicator(),
                          if (message != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
