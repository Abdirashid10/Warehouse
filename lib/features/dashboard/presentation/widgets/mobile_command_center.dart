import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/command_center_sections.dart';

/// Enterprise mobile command center — web-parity data, tabbed on phone, full scroll on tablet.
class MobileCommandCenter extends StatelessWidget {
  const MobileCommandCenter({
    super.key,
    required this.data,
    required this.routes,
    required this.onRefresh,
    this.isRefreshing = false,
    this.warningMessage,
  });

  final ControlCenterData data;
  final CommandCenterRoutes routes;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    final sections = CommandCenterSections(
      context: context,
      data: data,
      routes: routes,
    );
    final useTabs = !MobileUi.isTablet(MediaQuery.sizeOf(context).width);

    if (useTabs) {
      return _TabbedCommandCenter(
        sections: sections,
        onRefresh: onRefresh,
        isRefreshing: isRefreshing,
        warningMessage: warningMessage,
      );
    }

    return _ScrollCommandCenter(
      sections: sections.buildAll(),
      onRefresh: onRefresh,
      warningMessage: warningMessage,
      showWorkspaceHeader: true,
    );
  }
}

class _TabbedCommandCenter extends StatelessWidget {
  const _TabbedCommandCenter({
    required this.sections,
    required this.onRefresh,
    required this.isRefreshing,
    this.warningMessage,
  });

  final CommandCenterSections sections;
  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRefreshing)
            const LinearProgressIndicator(minHeight: 2),
          if (warningMessage != null)
            _WarningStrip(message: warningMessage!),
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Warehouse Command Center',
                    style: WmsDesignTokens.sectionTitle(context),
                  ),
                  Text(
                    '13 operational workspaces · web parity',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: context.wms.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'Operations'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _CommandCenterTab(
                  onRefresh: onRefresh,
                  sections: sections.buildOverviewTab(),
                ),
                _CommandCenterTab(
                  onRefresh: onRefresh,
                  sections: sections.buildAnalyticsTab(),
                ),
                _CommandCenterTab(
                  onRefresh: onRefresh,
                  sections: sections.buildOperationsTab(),
                ),
                _CommandCenterTab(
                  onRefresh: onRefresh,
                  sections: sections.buildActivityTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollCommandCenter extends StatelessWidget {
  const _ScrollCommandCenter({
    required this.sections,
    required this.onRefresh,
    this.warningMessage,
    this.showWorkspaceHeader = false,
  });

  final List<Widget> sections;
  final Future<void> Function() onRefresh;
  final String? warningMessage;
  final bool showWorkspaceHeader;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (showWorkspaceHeader)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Warehouse Command Center',
                      style: WmsDesignTokens.sectionTitle(context),
                    ),
                    Text(
                      'Full operational intelligence',
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: context.wms.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (warningMessage != null)
            SliverToBoxAdapter(child: _WarningStrip(message: warningMessage!)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: CommandCenterSections.sectionGap);
                  }
                  return sections[index ~/ 2];
                },
                childCount: sections.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandCenterTab extends StatelessWidget {
  const _CommandCenterTab({
    required this.onRefresh,
    required this.sections,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CommandCenterSectionList(sections: sections),
    );
  }
}

class _WarningStrip extends StatelessWidget {
  const _WarningStrip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .errorContainer
          .withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Text(message, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
