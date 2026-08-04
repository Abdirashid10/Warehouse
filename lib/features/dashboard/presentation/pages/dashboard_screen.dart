import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/widgets/wms/wms_shell_navigation_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDarkMode || theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surface = isDark ? const Color(0xFF111827) : AppColors.surface;
    final mutedSurface = isDark ? const Color(0xFF1F2937) : AppColors.surfaceVariant;
    final border = isDark ? Colors.white24 : AppColors.border;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      drawer: _buildDrawer(context, isDark),
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.menu_rounded, color: primaryText),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good afternoon, there',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Warehouse Operations Center',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            icon: Icon(
              _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: primaryText,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_rounded, color: primaryText),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline_rounded, color: primaryText),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            _buildWelcomeCard(
              context: context,
              surface: surface,
              mutedSurface: mutedSurface,
              border: border,
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildSectionHeader(
              title: 'Operational Alerts',
              context: context,
              primaryText: primaryText,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.12,
              children: [
                _buildAlertCard(
                  context: context,
                  label: 'Out Of Stock',
                  count: '2',
                  accent: AppColors.error,
                  icon: Icons.remove_shopping_cart_outlined,
                  background: AppColors.errorLight,
                  primaryText: primaryText,
                ),
                _buildAlertCard(
                  context: context,
                  label: 'Low Stock',
                  count: '9',
                  accent: AppColors.warning,
                  icon: Icons.trending_down_rounded,
                  background: AppColors.warningLight,
                  primaryText: primaryText,
                ),
                _buildAlertCard(
                  context: context,
                  label: 'Expired',
                  count: '2',
                  accent: AppColors.expired,
                  icon: Icons.event_busy_outlined,
                  background: AppColors.expiredLight,
                  primaryText: primaryText,
                ),
                _buildAlertCard(
                  context: context,
                  label: 'Expiring Soon',
                  count: '0',
                  accent: AppColors.info,
                  icon: Icons.schedule_rounded,
                  background: AppColors.infoLight,
                  primaryText: primaryText,
                ),
                _buildAlertCard(
                  context: context,
                  label: 'Pending Orders',
                  count: '1',
                  accent: AppColors.primary,
                  icon: Icons.shopping_cart_outlined,
                  background: AppColors.primaryLight,
                  primaryText: primaryText,
                ),
                _buildAlertCard(
                  context: context,
                  label: 'Urgent Tasks',
                  count: '6',
                  accent: AppColors.error,
                  icon: Icons.access_time_filled,
                  background: AppColors.errorLight,
                  primaryText: primaryText,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildExpirySection(
              context: context,
              surface: surface,
              border: border,
              primaryText: primaryText,
              secondaryText: secondaryText,
            ),
          ],
        ),
      ),
      bottomNavigationBar: WmsShellNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          WmsNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          WmsNavDestination(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
            label: 'Inventory',
          ),
          WmsNavDestination(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            label: 'Orders',
          ),
          WmsNavDestination(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment_rounded,
            label: 'Tasks',
          ),
          WmsNavDestination(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark) {
    final surface = isDark ? const Color(0xFF111827) : AppColors.surface;
    final border = isDark ? Colors.white24 : AppColors.border;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    return Drawer(
      backgroundColor: surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Supervisor Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Warehouse operations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Inventory'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Tasks'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard({
    required BuildContext context,
    required Color surface,
    required Color mutedSurface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Supervisor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Assigned Warehouses: All warehouses',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mutedSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(Icons.refresh_rounded, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Synced 2m ago',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required BuildContext context,
    required Color primaryText,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required String label,
    required String count,
    required Color accent,
    required IconData icon,
    required Color background,
    required Color primaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirySection({
    required BuildContext context,
    required Color surface,
    required Color border,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Expiry Tracking',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildExpiryStat(
                    label: 'Expired',
                    count: '2',
                    color: AppColors.error,
                    context: context,
                  ),
                  const Spacer(),
                  _buildExpiryStat(
                    label: 'Expiring Soon',
                    count: '3',
                    color: AppColors.warning,
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _buildExpiryStat(
                    label: 'Expiring (30D)',
                    count: '5',
                    color: AppColors.info,
                    context: context,
                  ),
                  const Spacer(),
                  _buildExpiryStat(
                    label: 'Safe',
                    count: '48',
                    color: AppColors.success,
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Container(height: 8, color: AppColors.error)),
                    Expanded(flex: 3, child: Container(height: 8, color: AppColors.warning)),
                    Expanded(flex: 5, child: Container(height: 8, color: AppColors.info)),
                    Expanded(flex: 48, child: Container(height: 8, color: AppColors.success)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Inventory shelf-life is trending within expected thresholds.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryStat({
    required String label,
    required String count,
    required Color color,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
