import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';

/// Shared layout constants for enterprise drawer navigation.
abstract final class WmsDrawerLayout {
  static const double widthFactor = 0.85;
  static const double menuItemHeight = 48.0;
  static const double menuItemRadius = 12.0;
  static const double menuItemGap = 12.0;
  static const double sectionGap = 20.0;
  static const double menuPaddingH = 16.0;
  static const double menuPaddingV = 10.0;
  static const double iconSize = WmsIconSizes.drawer;
  static const double iconLabelGap = WmsIconSizes.iconLabelGap;
  static const double activeIndicatorWidth = 4.0;
  static const double signOutPadding = 16.0;

  static double drawerWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width * widthFactor;
}

/// Single drawer navigation row — consistent height, icon alignment, active state.
class WmsDrawerMenuTile extends StatelessWidget {
  const WmsDrawerMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final accent = accentColor ?? colors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: WmsDrawerLayout.menuItemGap),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(WmsDrawerLayout.menuItemRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WmsDrawerLayout.menuItemRadius),
          child: SizedBox(
            height: WmsDrawerLayout.menuItemHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: WmsDrawerLayout.activeIndicatorWidth,
                  decoration: selected
                      ? BoxDecoration(
                          color: accent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(WmsDrawerLayout.menuItemRadius),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WmsDrawerLayout.menuPaddingH,
                      vertical: WmsDrawerLayout.menuPaddingV,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: WmsDrawerLayout.iconSize,
                          color: selected ? accent : colors.textSecondary,
                        ),
                        const SizedBox(width: WmsDrawerLayout.iconLabelGap),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              color: selected ? accent : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed sign-out action pinned to drawer bottom.
class WmsDrawerSignOut extends StatelessWidget {
  const WmsDrawerSignOut({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colors.divider),
        // A Drawer does not inset its own content, so on a device with a
        // gesture bar the sign-out row sat underneath it and was clipped. The
        // SafeArea wraps only the padded tile, so the divider still spans the
        // full width while the touch target clears the system bar.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(WmsDrawerLayout.signOutPadding),
            child: WmsDrawerMenuTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              selected: false,
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ),
        ),
      ],
    );
  }
}
