import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_executive_header.dart';

/// Web-parity greeting header for warehouse control center dashboards.
class ControlCenterHeader extends StatelessWidget {
  const ControlCenterHeader({
    super.key,
    required this.data,
    required this.forAdmin,
    required this.lastSyncedAt,
    required this.isLoading,
    this.embeddedInShell = false,
  });

  final ControlCenterData? data;
  final bool forAdmin;
  final DateTime? lastSyncedAt;
  final bool isLoading;
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final profile = data?.supervisor.profile;
        final name = profile?.fullName.isNotEmpty == true
            ? profile!.fullName
            : (authState.user?.fullName ?? 'Operator');
        final role = profile?.role.isNotEmpty == true
            ? profile!.role
            : (authState.user?.role.label ??
                (forAdmin ? 'Administrator' : 'Supervisor'));
        final warehouses = profile?.assignedWarehousesLabel ??
            authState.user?.warehouse ??
            'All warehouses';

        return WmsExecutiveHeader(
          compact: embeddedInShell,
          embeddedInShell: embeddedInShell,
          welcomeBackStyle: true,
          subtitle: 'Warehouse operations overview',
          displayName: name,
          roleLabel: role,
          warehouseName: warehouses,
          lastSyncedAt: lastSyncedAt,
          showLoadingBar: isLoading,
        );
      },
    );
  }
}
