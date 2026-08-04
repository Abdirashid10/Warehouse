import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/warehouse_staff_count.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class AdminWarehousesPanel extends StatelessWidget {
  const AdminWarehousesPanel({super.key, required this.bundle});

  final AdministrationBundle bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle.warehouses.isEmpty) {
      return const Center(
        child: WmsEmptyState(
          title: 'No warehouses',
          message: 'Warehouse records will appear when loaded from the backend.',
          icon: Icons.warehouse_outlined,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        Text(
          'Warehouse assignment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Staff allocation and capacity per warehouse',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final warehouse in bundle.warehouses) ...[
          _WarehouseAssignmentCard(
            warehouse: warehouse,
            assignedUsers: _usersForWarehouse(warehouse.name),
            staffUsers: _staffForWarehouse(warehouse.name),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign user to warehouse',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Assignment changes are managed through the web admin when mobile assign endpoints are unavailable.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Warehouse assignment UI is ready. Connect assign-user API to persist changes.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Open Assignment Form'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<WmsUser> _usersForWarehouse(String warehouseName) {
    return bundle.users
        .where(
          (u) =>
              !u.archived &&
              u.assignedWarehouse != null &&
              u.assignedWarehouse == warehouseName,
        )
        .toList();
  }

  List<WmsUser> _staffForWarehouse(String warehouseName) {
    return _usersForWarehouse(warehouseName)
        .where((user) => isOperationalWarehouseStaffRole(user.role))
        .toList();
  }
}

class _WarehouseAssignmentCard extends StatelessWidget {
  const _WarehouseAssignmentCard({
    required this.warehouse,
    required this.assignedUsers,
    required this.staffUsers,
  });

  final Warehouse warehouse;
  final List<WmsUser> assignedUsers;
  final List<WmsUser> staffUsers;

  @override
  Widget build(BuildContext context) {
    final supervisor = assignedUsers
        .where((u) => u.role.toLowerCase() == 'supervisor')
        .map((u) => u.displayName)
        .firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  warehouse.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${staffUsers.length} staff',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(warehouse.location, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Supervisor', value: supervisor ?? 'Not assigned'),
          _InfoRow(
            label: 'Capacity',
            value: WmsFormatters.quantity(warehouse.capacity),
          ),
          _InfoRow(label: 'Staff count', value: '${staffUsers.length}'),
          if (staffUsers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final user in staffUsers.take(6))
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        user.initials,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                    label: Text(user.displayName),
                  ),
                if (staffUsers.length > 6)
                  Chip(label: Text('+${staffUsers.length - 6} more')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
