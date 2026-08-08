import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double screenPadding = xl;
  static const double cardPadding = lg;
  static const double sectionGap = xl;
  static const double cardGap = md;
  static const double itemGap = md;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusButton = 14;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;

  static const double iconSm = WmsIconSizes.actionButton;
  static const double iconMd = WmsIconSizes.listLeading;
  static const double iconLg = WmsIconSizes.kpi;

  static const double buttonHeight = 48;
  static const double inputHeight = 48;
  static const double bottomNavHeight = 70;
  static const double minTouchTarget = buttonHeight;
  static const double listTileMinHeight = 52;
}
