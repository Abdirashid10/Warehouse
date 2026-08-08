import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/notifications/presentation/widgets/notifications_inbox_panel.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with StaffScopeInitMixin {
  NotificationsCubit? _cubit;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    setState(() {
      _cubit = NotificationsCubit(
        GetNotificationsUseCase(repositories.notifications),
      )..load();
    });
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return _wrap(context, const StaffScopeLoadingBody());
    }

    return BlocProvider.value(
      value: cubit,
      child: _wrap(
        context,
        NotificationsInboxPanel(cubit: cubit),
      ),
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    final colors = WmsUiColors.of(context);
    final titleStyle = WmsDesignTokens.pageTitle(context).copyWith(
      fontSize: 18,
      color: colors.textPrimary,
    );

    if (widget.embeddedInShell) {
      return Scaffold(
        backgroundColor: colors.background,
        body: child,
      );
    }
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.screenPadding,
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Operations Inbox', style: titleStyle),
      ),
      body: child,
    );
  }
}
