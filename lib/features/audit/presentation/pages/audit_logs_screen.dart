import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_activity_stream.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_theme.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';

/// Audit Logs — the platform's high-security activity stream.
class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen>
    with StaffScopeInitMixin {
  AuditCubit? _cubit;
  final _searchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = AuditCubit(repositories.audit)..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const WmsPushedScaffold(
        title: 'Audit Logs',
        body: StaffScopeLoadingBody(),
      );
    }

    final palette = AuditPalette.of(context);

    return WmsPushedScaffold(
      title: 'Audit Logs',
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: BlocProvider.value(
          value: cubit,
          child: RefreshIndicator(
            color: palette.brand,
            backgroundColor: palette.colors.surface,
            onRefresh: cubit.refresh,
            child: AuditActivityStream(
              cubit: cubit,
              searchController: _searchController,
            ),
          ),
        ),
      ),
    );
  }
}
