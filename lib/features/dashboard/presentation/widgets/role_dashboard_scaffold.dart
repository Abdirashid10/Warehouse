import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';

class RoleDashboardScaffold extends StatelessWidget {
  const RoleDashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.capabilities,
    this.metricsBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> capabilities;
  final WidgetBuilder? metricsBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final isLoggingOut =
            authState.isLoading && authState.loadingType == AuthLoadingType.logout;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHeader(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    accentColor: accentColor,
                    displayName: user?.fullName ?? 'User',
                    roleLabel: user?.role.label ?? '',
                    warehouse: user?.warehouse,
                    isLoggingOut: isLoggingOut,
                    onLogout: () {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (metricsBuilder != null) metricsBuilder!(context),
                      Text(
                        'Your access',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: capabilities
                              .map(
                                (cap) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: AppSpacing.iconSm,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          cap,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AppCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_done_outlined,
                              color: colors.success,
                              size: AppSpacing.iconMd,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'KPIs above are loaded live from the Logistics WMS '
                                'API (MongoDB). Staff users access tasks, inventory, '
                                'and orders from the staff workspace.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.displayName,
    required this.roleLabel,
    required this.warehouse,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String displayName;
  final String roleLabel;
  final String? warehouse;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withValues(alpha: 0.75)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: Colors.white, size: AppSpacing.iconMd),
              ),
              const Spacer(),
              if (isLoggingOut)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: LoadingIndicator(size: 22, color: Colors.white),
                )
              else
                TextButton.icon(
                  onPressed: onLogout,
                  icon: Icon(Icons.logout, color: Colors.white, size: WmsIconSizes.actionButton),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (roleLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              roleLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
            ),
          ],
          if (warehouse != null && warehouse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              warehouse!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
