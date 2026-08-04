import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/command_center_sections.dart';

/// Tablet / wide-screen enterprise dashboard — full scroll of all command center sections.
class AdminEnterpriseDashboardBody extends StatelessWidget {
  const AdminEnterpriseDashboardBody({
    super.key,
    required this.data,
    required this.routes,
  });

  final ControlCenterData data;
  final CommandCenterRoutes routes;

  @override
  Widget build(BuildContext context) {
    final sections = CommandCenterSections(
      context: context,
      data: data,
      routes: routes,
    ).buildAll();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: CommandCenterSections.sectionGap),
          sections[i],
        ],
      ],
    );
  }
}
