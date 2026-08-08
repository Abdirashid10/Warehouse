import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/notifications/presentation/widgets/notifications_inbox_panel.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<({List<AppNotification> items, int unreadCount})> getNotifications() async {
    return (items: <AppNotification>[], unreadCount: 0);
  }
}

class _TestNotificationsCubit extends NotificationsCubit {
  _TestNotificationsCubit() : super(GetNotificationsUseCase(_FakeNotificationsRepository()));

  void emitEmptySuccess() {
    emit(
      ResourceState.success(
        const NotificationsListState(items: [], unreadCount: 0),
      ),
    );
  }

  void emitLoading() {
    emit(const ResourceState.loading());
  }
}

void main() {
  testWidgets('NotificationsInboxPanel shows empty state when list is empty', (tester) async {
    final cubit = _TestNotificationsCubit()..emitEmptySuccess();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsInboxPanel(cubit: cubit),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Notifications'), findsOneWidget);
    expect(find.text("You don't have any notifications yet."), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsWidgets);

    await cubit.close();
  });

  testWidgets('NotificationsInboxPanel shows loading indicator', (tester) async {
    final cubit = _TestNotificationsCubit()..emitLoading();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsInboxPanel(cubit: cubit),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await cubit.close();
  });
}
