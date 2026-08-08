import 'package:logisticsmobile/core/utils/overflow_safe.dart';
import 'package:flutter/material.dart';

/// Full-screen module opened from drawer (back button + title).
class WmsPushedScaffold extends StatelessWidget {
  const WmsPushedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: floatingActionButton,
      body: OverflowSafe.clip(body),
    );
  }
}
