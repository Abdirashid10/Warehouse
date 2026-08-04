import 'dart:async';

/// Broadcasts inventory-changing operations so open screens can refresh live data.
class WmsInventoryRefreshBus {
  WmsInventoryRefreshBus._();

  static final WmsInventoryRefreshBus instance = WmsInventoryRefreshBus._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onRefresh => _controller.stream;

  void notifyInventoryChanged() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
