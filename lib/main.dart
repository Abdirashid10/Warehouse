import 'package:flutter/material.dart';
import 'package:logisticsmobile/app.dart';
import 'package:logisticsmobile/core/config/layout_debug_config.dart';
import 'package:logisticsmobile/core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LayoutDebugConfig.install();
  final dependencies = await InjectionContainer.init();
  runApp(LogisticsApp(dependencies: dependencies));
}