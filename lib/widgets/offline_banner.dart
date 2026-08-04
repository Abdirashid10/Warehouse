import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/network/connectivity_service.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Slim banner when the device has no network connection.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.connectivity, required this.child});

  final ConnectivityService connectivity;
  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late bool _online;

  @override
  void initState() {
    super.initState();
    _online = widget.connectivity.isOnline;
    widget.connectivity.onlineStream.listen((online) {
      if (mounted) setState(() => _online = online);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Column(
      children: [
        if (!_online)
          Material(
            color: wms.warning,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: WmsIconSizes.status, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'You\'re offline — showing last synced data where available',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
