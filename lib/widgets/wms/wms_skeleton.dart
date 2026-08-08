import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Shimmer-style placeholder for list and card loading states.
class WmsSkeleton extends StatefulWidget {
  const WmsSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<WmsSkeleton> createState() => _WmsSkeletonState();
}

class _WmsSkeletonState extends State<WmsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final wms = context.wms;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [
                wms.surfaceVariant,
                wms.border,
                wms.surfaceVariant,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class WmsSkeletonBox extends StatelessWidget {
  const WmsSkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppSpacing.radiusSm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return WmsSkeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: wms.surfaceVariant,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class WmsListSkeleton extends StatelessWidget {
  const WmsListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const WmsSkeletonBox(
        height: 88,
        radius: AppSpacing.radiusMd,
      ),
    );
  }
}

class WmsKpiSkeleton extends StatelessWidget {
  const WmsKpiSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 600 ? 4 : 2;
    return GridView.builder(
      itemCount: columns * 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 88,
      ),
      itemBuilder: (_, __) => const WmsSkeletonBox(
        height: 88,
        radius: AppSpacing.radiusLg,
      ),
    );
  }
}

/// Full-screen enterprise loading skeleton for command-center screens.
class WmsScreenSkeleton extends StatelessWidget {
  const WmsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        WmsSkeletonBox(height: 120, radius: AppSpacing.radiusLg),
        SizedBox(height: AppSpacing.lg),
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.lg),
        WmsSkeletonBox(height: 24, width: 160),
        SizedBox(height: AppSpacing.sm),
        WmsSkeletonBox(height: 140, radius: AppSpacing.radiusLg),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 140, radius: AppSpacing.radiusLg),
      ],
    );
  }
}
