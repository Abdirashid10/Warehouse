import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_audit_panel.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> with StaffScopeInitMixin {
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

    return WmsPushedScaffold(
      title: 'Audit Logs',
      body: BlocProvider.value(
        value: cubit,
        child: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: AdminAuditPanel(
            cubit: cubit,
            searchController: _searchController,
          ),
        ),
      ),
    );
  }
}
