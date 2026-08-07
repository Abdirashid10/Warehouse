import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';

/// Visual barcode representation for SKU display (no external barcode package).
class WmsBarcodeDisplay extends StatelessWidget {
  const WmsBarcodeDisplay({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final bars = code.codeUnits.map((u) => (u % 5) + 1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final h in bars)
                Expanded(
                  child: Container(
                    height: 12.0 + h * 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          code,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
