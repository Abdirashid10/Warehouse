import 'package:flutter/material.dart';

/// Shared overflow-safe layout helpers for phone-first WMS screens.
abstract final class OverflowSafe {
  /// Clips painted overflow at widget bounds (no layout change).
  static Widget clip(Widget child) {
    return ClipRect(child: child);
  }

  /// Ellipsis text — default for labels in tight rows.
  static Widget text(
    String data, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int maxLines = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
    bool softWrap = true,
  }) {
    return Text(
      data,
      key: key,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }

  /// Row child that expands and ellipsizes text content.
  static Widget expandedText(
    String data, {
    TextStyle? style,
    int maxLines = 1,
  }) {
    return Expanded(
      child: text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  /// Scrollable body when module content may exceed viewport height.
  static Widget scrollBody({
    required Widget child,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  /// Host that clips subtree — use at app shell boundaries.
  static Widget host(Widget child) => clip(child);
}
