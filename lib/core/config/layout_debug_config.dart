import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Suppresses visible debug overflow/error chrome while layouts are hardened.
abstract final class LayoutDebugConfig {
  static bool _installed = false;

  static bool get _isTestBinding {
    final type = WidgetsBinding.instance.runtimeType.toString();
    return type.contains('TestWidgets') || type.contains('AutomatedTest');
  }

  static void install() {
    if (_installed || _isTestBinding) return;
    _installed = true;

    final defaultOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (_isLayoutOverflow(details)) {
        if (kDebugMode) {
          debugPrint('Layout overflow (suppressed UI): ${details.summary}');
        }
        return;
      }
      defaultOnError?.call(details);
    };

    final defaultBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      if (_isLayoutOverflow(details)) {
        return const SizedBox.shrink();
      }
      return defaultBuilder(details);
    };
  }

  static bool _isLayoutOverflow(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    return message.contains('RenderFlex overflowed') ||
        message.contains('overflowed by') ||
        message.contains('A RenderFlex') ||
        message.contains('vertical overflow') ||
        message.contains('horizontal overflow');
  }
}
