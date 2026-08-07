import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';

/// One entry in a [WmsPillTabBar].
class WmsPillTabSpec {
  const WmsPillTabSpec({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Colours for a [WmsPillTabBar], supplied by the hosting module's palette so
/// the shared widget stays theme-agnostic.
class WmsPillTabStyle {
  const WmsPillTabStyle({
    required this.activeGradient,
    required this.trackColor,
    required this.activeLabel,
    required this.inactiveLabel,
    this.activeGlow = const [],
    this.trackBorder,
  });

  final Gradient activeGradient;
  final Color trackColor;
  final Color activeLabel;
  final Color inactiveLabel;
  final List<BoxShadow> activeGlow;
  final BoxBorder? trackBorder;
}

/// Pill-shaped tab selector whose indicator slides continuously with the page.
///
/// Driven by the [TabController]'s animation rather than by discrete index
/// changes, so a half-completed swipe leaves the indicator half-way across.
/// Item widths are measured with a [TextPainter] up front, so the geometry is
/// correct on the very first frame instead of jumping after a post-layout pass.
class WmsPillTabBar extends StatefulWidget {
  const WmsPillTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.style,
  });

  final TabController controller;
  final List<WmsPillTabSpec> tabs;
  final WmsPillTabStyle style;

  static const double height = 46;

  @override
  State<WmsPillTabBar> createState() => _WmsPillTabBarState();
}

class _WmsPillTabBarState extends State<WmsPillTabBar> {
  final _scrollController = ScrollController();

  static const double _iconSize = 15;
  static const double _iconGap = 6;
  static const double _horizontalPadding = 14;
  static const double _itemGap = 6;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant WmsPillTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.controller.indexIsChanging) _scrollToIndex();
  }

  TextStyle _labelStyle(BuildContext context) =>
      WmsDesignTokens.supportingDense(context).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );

  List<double> _measure(BuildContext context) {
    final style = _labelStyle(context);
    final scaler = MediaQuery.textScalerOf(context);
    return [
      for (final tab in widget.tabs)
        () {
          final painter = TextPainter(
            text: TextSpan(text: tab.label, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          return painter.width + _iconSize + _iconGap + _horizontalPadding * 2;
        }(),
    ];
  }

  void _scrollToIndex() {
    if (!_scrollController.hasClients || !mounted) return;
    final widths = _measure(context);
    final index = widget.controller.index.clamp(0, widths.length - 1);

    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += widths[i] + _itemGap;
    }
    final viewport = _scrollController.position.viewportDimension;
    final target = (offset - (viewport - widths[index]) / 2)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final widths = _measure(context);

    final offsets = <double>[];
    var running = 0.0;
    for (final width in widths) {
      offsets.add(running);
      running += width + _itemGap;
    }
    final totalWidth = running - _itemGap;

    return Container(
      height: WmsPillTabBar.height,
      decoration: BoxDecoration(
        color: style.trackColor,
        borderRadius: BorderRadius.circular(999),
        border: style.trackBorder,
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: math.max(totalWidth, 0),
          child: AnimatedBuilder(
            animation: widget.controller.animation ?? widget.controller,
            builder: (context, _) {
              final value = widget.controller.animation?.value.toDouble() ??
                  widget.controller.index.toDouble();
              final lower = value.floor().clamp(0, widths.length - 1);
              final upper = value.ceil().clamp(0, widths.length - 1);
              final t = value - lower;

              return Stack(
                children: [
                  Positioned(
                    left: _lerp(offsets[lower], offsets[upper], t),
                    top: 0,
                    bottom: 0,
                    width: _lerp(widths[lower], widths[upper], t),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: style.activeGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: style.activeGlow,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < widget.tabs.length; i++) ...[
                        if (i > 0) const SizedBox(width: _itemGap),
                        SizedBox(
                          width: widths[i],
                          child: _PillTabItem(
                            spec: widget.tabs[i],
                            style: _labelStyle(context),
                            // Cross-fade with the indicator so a label is never
                            // stranded mid-way between the two contrasts.
                            selection: (1 - (value - i).abs()).clamp(0.0, 1.0),
                            activeColor: style.activeLabel,
                            inactiveColor: style.inactiveLabel,
                            onTap: () => widget.controller.animateTo(i),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PillTabItem extends StatelessWidget {
  const _PillTabItem({
    required this.spec,
    required this.style,
    required this.selection,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final WmsPillTabSpec spec;
  final TextStyle style;
  final double selection;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(inactiveColor, activeColor, selection)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(spec.icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
