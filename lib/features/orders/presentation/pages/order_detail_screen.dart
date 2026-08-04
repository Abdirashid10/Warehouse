import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/presentation/cubit/order_detail_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';
import 'package:logisticsmobile/widgets/wms/wms_order_timeline.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with StaffScopeInitMixin {
  OrderDetailCubit? _cubit;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = OrderDetailCubit(repositories.orders)..load(widget.orderId);
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  String? _nextStaffStatus(String current) {
    switch (current) {
      case WmsOrderStatuses.pending:
        return WmsOrderStatuses.processing;
      case WmsOrderStatuses.processing:
        return WmsOrderStatuses.packed;
      case WmsOrderStatuses.packed:
        return WmsOrderStatuses.shipped;
      case WmsOrderStatuses.shipped:
        return WmsOrderStatuses.delivered;
      default:
        return null;
    }
  }

  String _actionLabel(String nextStatus) {
    switch (nextStatus) {
      case WmsOrderStatuses.packed:
        return 'Pack';
      case WmsOrderStatuses.processing:
        return 'Start Processing';
      case WmsOrderStatuses.shipped:
        return 'Ship';
      case WmsOrderStatuses.delivered:
        return 'Deliver';
      default:
        return nextStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: BlocBuilder<OrderDetailCubit, ResourceState<WarehouseOrder>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: WmsListSkeleton(itemCount: 4),
              );
            }
            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load order',
                onRetry: () => cubit.load(widget.orderId),
              );
            }
            final order = state.data;
            if (order == null) return const SizedBox.shrink();

            final next = _nextStaffStatus(order.status);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      WmsOrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                WmsOrderStatusTimeline(currentStatus: order.status),
                const SizedBox(height: AppSpacing.md),
                _Row(label: 'Customer', value: order.customerName),
                if (order.deliveryAddress != null)
                  _Row(label: 'Warehouse', value: order.deliveryAddress!),
                if (order.phoneNumber != null)
                  _Row(label: 'Phone', value: order.phoneNumber!),
                if (order.deliveryAddress != null)
                  _Row(label: 'Delivery', value: order.deliveryAddress!),
                _Row(label: 'Items', value: '${order.itemCount}'),
                _Row(label: 'Total', value: WmsFormatters.currency(order.grandTotal)),
                if (order.priority != null) _Row(label: 'Priority', value: order.priority!),
                _Row(label: 'Notes', value: 'No additional notes provided'),
                const SizedBox(height: AppSpacing.md),
                if (order.items.isNotEmpty) ...[
                  Text('Line items', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName),
                                  Text('SKU ${item.sku}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Text(WmsFormatters.quantity(item.quantity)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (next != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppButton(
                    label: _actionLabel(next),
                    isLoading: state.isLoading,
                    onPressed: state.isLoading
                        ? null
                        : () => cubit.advanceStatus(next),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      ),
    );
  }
}
