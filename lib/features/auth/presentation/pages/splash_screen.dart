import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/responsive_layout.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final statusText = state.isLoading
            ? 'Verifying secure session...'
            : 'Initializing warehouse systems...';

        final compactPhone = MediaQuery.sizeOf(context).height < 700;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -40,
                    child: _DecorOrb(size: 200, opacity: 0.12),
                  ),
                  Positioned(
                    bottom: 120,
                    left: -60,
                    child: _DecorOrb(size: 160, opacity: 0.1),
                  ),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Center(
                        child: ResponsiveCenter(
                          maxWidth: 400,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: _BrandMark(compact: compactPhone),
                              ),
                              SizedBox(
                                height: compactPhone
                                    ? AppSpacing.lg
                                    : AppSpacing.xxl,
                              ),
                              Text(
                                AppConstants.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (compactPhone
                                        ? Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                        : Theme.of(context)
                                            .textTheme
                                            .displaySmall)
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                AppConstants.appTagline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontSize: compactPhone ? 12 : 14,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                height: compactPhone
                                    ? AppSpacing.xl
                                    : AppSpacing.xxxl,
                              ),
                              LoadingIndicator(
                                size: compactPhone ? 22 : 28,
                                color: Colors.white,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                statusText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: AppSpacing.lg,
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 80.0 : 104.0;
    final iconSize = compact ? 40.0 : 52.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.warehouse_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _DecorOrb extends StatelessWidget {
  const _DecorOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
