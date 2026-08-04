import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';

/// Defers [StaffScope.of] until after the first frame of dependencies are available.
mixin StaffScopeInitMixin<T extends StatefulWidget> on State<T> {
  bool _staffScopeReady = false;

  /// True after [onStaffScopeReady] has been invoked exactly once.
  bool get isStaffScopeReady => _staffScopeReady;

  /// Called once when [StaffScope] is safe to read from [context].
  void onStaffScopeReady(StaffRepositories repositories);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_staffScopeReady) return;

    final scope = context.dependOnInheritedWidgetOfExactType<StaffScope>();
    _staffScopeReady = true;

    if (scope == null) {
      return;
    }

    onStaffScopeReady(scope.repositories);
  }
}

/// Lightweight placeholder while cubits are created in [didChangeDependencies].
class StaffScopeLoadingBody extends StatelessWidget {
  const StaffScopeLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
