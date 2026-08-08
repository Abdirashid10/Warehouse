import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Shared web-parity catalog page chrome (Products, Warehouses, etc.).
class WmsCatalogPageHeader extends StatelessWidget {
  const WmsCatalogPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: WmsDesignTokens.pageTitle(context).copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: onSurface,
                letterSpacing: -0.5,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: WmsDesignTokens.supporting(context).copyWith(
                color: wms.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class WmsCatalogSearchField extends StatelessWidget {
  const WmsCatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: WmsDesignTokens.body(context).copyWith(
            color: onSurface,
            fontSize: 15,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WmsDesignTokens.supporting(context).copyWith(
              color: wms.textTertiary,
              fontSize: 15,
            ),
        prefixIcon: Icon(
          Icons.search,
          size: WmsIconSizes.search,
          color: wms.textTertiary,
        ),
        filled: true,
        fillColor: wms.cardBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: wms.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: wms.border),
        ),
      ),
    );
  }
}

/// Catalog list scaffold — respects app light/dark theme.
class WmsCatalogListScaffold extends StatelessWidget {
  const WmsCatalogListScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        toolbarHeight: 44,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class WmsCatalogListCard extends StatelessWidget {
  const WmsCatalogListCard({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Material(
      color: wms.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: wms.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: child),
              Icon(
                Icons.chevron_right,
                size: WmsIconSizes.listLeading,
                color: wms.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
