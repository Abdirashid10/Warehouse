import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/network/connectivity_service.dart';

class ConnectivityScope extends InheritedWidget {
  const ConnectivityScope({
    super.key,
    required this.connectivity,
    required super.child,
  });

  final ConnectivityService connectivity;

  static ConnectivityService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConnectivityScope>();
    assert(scope != null, 'ConnectivityScope not found');
    return scope!.connectivity;
  }

  static bool isOnline(BuildContext context) => of(context).isOnline;

  @override
  bool updateShouldNotify(ConnectivityScope oldWidget) =>
      connectivity != oldWidget.connectivity;
}
