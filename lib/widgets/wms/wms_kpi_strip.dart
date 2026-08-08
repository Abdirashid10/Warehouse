import 'package:flutter/material.dart';

import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';

import 'package:logisticsmobile/widgets/kpi_stat_card.dart';



class WmsKpiStrip extends StatelessWidget {

  const WmsKpiStrip({super.key, required this.items, this.premium = false});



  final List<WmsKpiItem> items;
  final bool premium;



  static int crossAxisCountForWidth(double width) => width > 500 ? 3 : 2;



  static double cellWidthFor({

    required double maxWidth,

    required int crossAxisCount,

    double spacing = AppSpacing.md,

  }) {

    return (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

  }



  /// Minimum row height so icon, value, and two-line labels fit on small phones.

  static double mainAxisExtentForWidth(double maxWidth) {
    return MobileUi.kpiGridMainAxisExtentFor(maxWidth);
  }



  @override

  Widget build(BuildContext context) {

    return LayoutBuilder(

      builder: (context, constraints) {

        final crossCount = crossAxisCountForWidth(constraints.maxWidth);

        final mainAxisExtent =

            mainAxisExtentForWidth(constraints.maxWidth);



        return GridView.builder(

          itemCount: items.length,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(

            crossAxisCount: crossCount,

            mainAxisSpacing: AppSpacing.md,

            crossAxisSpacing: AppSpacing.md,

            mainAxisExtent: mainAxisExtent,

          ),

          itemBuilder: (context, index) {

            final item = items[index];

            return KPIStatCard(

              label: item.label,

              value: item.value,

              icon: item.icon,

              iconColor: item.color,

              iconBackgroundColor: item.background,

              onTap: item.onTap,

              premium: premium,

              accentColor: item.color,

            );

          },

        );

      },

    );

  }

}



class WmsKpiItem {

  const WmsKpiItem({

    required this.label,

    required this.value,

    required this.icon,

    required this.color,

    required this.background,

    this.onTap,

  });



  final String label;

  final String value;

  final IconData icon;

  final Color color;

  final Color background;

  final VoidCallback? onTap;

}


