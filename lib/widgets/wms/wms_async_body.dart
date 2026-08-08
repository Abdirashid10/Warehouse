import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Standard loading / error / empty / success handling for staff screens.
class WmsAsyncBody<T> extends StatelessWidget {
  const WmsAsyncBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = 'No records found',
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.loadingMessage = 'Loading…',
    this.skeleton,
    this.onRefresh,
    this.errorKind,
  });

  final ResourceState<T> state;
  final Future<void> Function() onRetry;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final String loadingMessage;
  final Widget? skeleton;
  final Future<void> Function()? onRefresh;
  final WmsErrorKind? errorKind;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.data == null) {
      return skeleton ?? const WmsScreenSkeleton();
    }

    if (state.isFailure && state.data == null) {
      return WmsErrorState(
        message: state.message ?? 'Something went wrong',
        onRetry: onRetry,
        kind: errorKind ?? wmsErrorKindFromMessage(state.message),
      );
    }

    final data = state.data;
    if (data == null) return const SizedBox.shrink();

    if (isEmpty != null && isEmpty!(data)) {
      return WmsEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon,
      );
    }

    final content = builder(context, data);

    if (onRefresh == null) return content;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: content is ScrollView || content is ListView
          ? content
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: content,
            ),
    );
  }
}
