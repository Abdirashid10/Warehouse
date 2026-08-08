import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:intl/intl.dart';

/// Staff-only dashboard header — operational greeting with live date/time.
class StaffOperationsHeader extends StatefulWidget {
  const StaffOperationsHeader({
    super.key,
    required this.displayName,
    this.showLoadingBar = false,
  });

  final String? displayName;
  final bool showLoadingBar;

  @override
  State<StaffOperationsHeader> createState() => _StaffOperationsHeaderState();
}

class _StaffOperationsHeaderState extends State<StaffOperationsHeader> {
  Timer? _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _firstName {
    final name = widget.displayName?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final date = DateFormat('EEE, MMM d, yyyy').format(_now);
    final time = DateFormat('h:mm a').format(_now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLoadingBar)
          const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${WmsFormatters.greeting()}, $_firstName',
                style: WmsDesignTokens.pageTitle(context).copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$date · $time',
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Warehouse Operations',
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
