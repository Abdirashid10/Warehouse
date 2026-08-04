import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Users screen typography — delegates to global [WmsDesignTokens].
abstract final class UsersTypography {
  static TextStyle userName(BuildContext context) =>
      WmsDesignTokens.userName(context);

  static TextStyle email(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDesignTokens.email(context).copyWith(color: colors.textSecondary);
  }

  static TextStyle usernameHandle(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDesignTokens.description(context).copyWith(
      color: colors.textTertiary,
    );
  }

  static TextStyle badge(BuildContext context, {required Color color}) =>
      WmsDesignTokens.badge(context).copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      );

  static TextStyle metadata(BuildContext context) =>
      WmsDesignTokens.description(context);

  static TextStyle metadataValue(BuildContext context) =>
      metadata(context).copyWith(fontWeight: FontWeight.w600);

  static TextStyle actionLink(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDesignTokens.body(context).copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle searchField(BuildContext context) =>
      WmsDesignTokens.inputText(context);

  static TextStyle searchHint(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return searchField(context).copyWith(color: colors.textTertiary);
  }

  static TextStyle filterChip(BuildContext context, {Color? color}) =>
      WmsDesignTokens.body(context).copyWith(color: color);

  static TextStyle filterSectionLabel(BuildContext context) =>
      WmsDesignTokens.formLabel(context).copyWith(fontWeight: FontWeight.w700);

  static TextStyle kpiNumber(BuildContext context, {Color? color}) =>
      WmsDesignTokens.cardNumber(context).copyWith(color: color);

  static TextStyle kpiLabel(BuildContext context, {Color? color}) {
    final colors = WmsUiColors.of(context);
    return WmsDesignTokens.kpiLabel(context).copyWith(
      color: color ?? colors.textTertiary,
    );
  }

  static TextStyle pageSubtitle(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsDesignTokens.pageSubtitle(context).copyWith(
      color: colors.textSecondary,
    );
  }

  static TextStyle pagination(BuildContext context) =>
      WmsDesignTokens.body(context);
}
