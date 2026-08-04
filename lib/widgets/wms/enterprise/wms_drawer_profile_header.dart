import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';

/// Premium drawer header — avatar, app name, workspace subtitle, role badge.
class WmsDrawerProfileHeader extends StatelessWidget {
  const WmsDrawerProfileHeader({
    super.key,
    this.subtitle = 'Warehouse Control Center',
    this.accentColor = AppColors.primary,
    this.roleOverride,
    this.warehouseOverride,
  });

  static const _topPadding = 24.0;
  static const _bottomPadding = 20.0;
  static const _horizontalPadding = 16.0;
  static const _avatarSize = 48.0;
  static const _avatarNameGap = 12.0;

  final String subtitle;
  final Color accentColor;
  final String? roleOverride;
  final String? warehouseOverride;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final user = auth.user;
        final role = roleOverride ?? user?.role.label ?? 'Staff';
        final warehouse =
            warehouseOverride ?? user?.warehouse ?? 'Main Distribution Center';
        final initials = user?.initials ?? '?';

        return Container(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            _topPadding,
            _horizontalPadding,
            _bottomPadding,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor,
                accentColor.withValues(alpha: 0.82),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: _avatarSize,
                      height: _avatarSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        initials,
                        style: WmsDesignTokens.drawerAppName(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: _avatarNameGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.drawerAppName(context).copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.drawerHeaderSubtitle(context)
                                .copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DrawerChip(
                      icon: Icons.badge_outlined,
                      label: role,
                    ),
                    if (warehouse.trim().isNotEmpty)
                      _DrawerChip(
                        icon: Icons.warehouse_outlined,
                        label: warehouse,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerChip extends StatelessWidget {
  const _DrawerChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WmsIconSizes.drawer, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.badge(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
