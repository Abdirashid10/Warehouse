import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_quick_actions.dart';

/// Staff-only dashboard welcome header — greeting, live date/time, quick actions.
class StaffDashboardHeader extends StatelessWidget {
  const StaffDashboardHeader({
    super.key,
    required this.assignedWarehouseName,
    required this.stockOpsRoute,
    required this.ordersRoute,
    required this.tasksRoute,
    required this.reportsRoute,
    required this.onNavigate,
  });

  final String? assignedWarehouseName;
  final String stockOpsRoute;
  final String ordersRoute;
  final String tasksRoute;
  final String reportsRoute;
  final void Function(String route, {bool replace}) onNavigate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final colors = WmsUiColors.of(context);
        final warehouse = assignedWarehouseName?.trim().isNotEmpty == true
            ? assignedWarehouseName!
            : auth.user?.warehouse;
        final userName = WmsFormatters.greetingName(auth.user?.fullName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${WmsFormatters.greeting()}, $userName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.sectionTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _StaffLiveDateTime(),
                  if (warehouse != null && warehouse.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warehouse_outlined,
                          size: WmsIconSizes.listLeading,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: WmsIconSizes.iconLabelGap),
                        Expanded(
                          child: Text(
                            warehouse,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.pageSubtitle(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            WmsQuickActionsSection(
              title: 'Quick Actions',
              showSubtitle: false,
              compact: true,
              actions: [
                WmsQuickAction(
                  label: 'Receive',
                  icon: Icons.move_to_inbox_outlined,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successLight,
                  onTap: () => onNavigate(stockOpsRoute),
                ),
                WmsQuickAction(
                  label: 'Dispatch',
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFFC2410C),
                  iconBackground: const Color(0xFFFFEDD5),
                  onTap: () => onNavigate(stockOpsRoute),
                ),
                WmsQuickAction(
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.info,
                  iconBackground: AppColors.infoLight,
                  onTap: () => onNavigate(stockOpsRoute),
                ),
                WmsQuickAction(
                  label: 'Tasks',
                  icon: Icons.assignment_outlined,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.primaryLight,
                  onTap: () => onNavigate(tasksRoute),
                ),
                WmsQuickAction(
                  label: 'Orders',
                  icon: Icons.shopping_cart_outlined,
                  iconColor: AppColors.accent,
                  iconBackground: AppColors.accentLight,
                  onTap: () => onNavigate(ordersRoute, replace: true),
                ),
                WmsQuickAction(
                  label: 'Reports',
                  icon: Icons.assessment_outlined,
                  iconColor: AppColors.primary,
                  iconBackground: AppColors.primaryLight,
                  onTap: () => onNavigate(reportsRoute),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Updates every minute so the welcome header shows current date and time.
class _StaffLiveDateTime extends StatefulWidget {
  const _StaffLiveDateTime();

  @override
  State<_StaffLiveDateTime> createState() => _StaffLiveDateTimeState();
}

class _StaffLiveDateTimeState extends State<_StaffLiveDateTime> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Text(
      WmsFormatters.staffDashboardDateTime(_now),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: WmsDesignTokens.pageSubtitle(context).copyWith(
        color: colors.textSecondary,
      ),
    );
  }
}
