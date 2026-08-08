import 'dart:math' as math;

/// Direction of a period-over-period change.
enum TrendDirection { up, down, flat }

/// A period-over-period comparison for one metric.
///
/// Trends are only ever computed from data the app actually holds: the current
/// reporting window versus the window of equal length immediately before it.
/// Metrics with no history in the payload — total products, stock valuation,
/// head-count — are [snapshot]s and render as such. A dashboard that invented
/// "+12% vs last month" for a figure it cannot compare would be worse than one
/// that shows no delta at all; someone reorders stock against these numbers.
class MetricTrend {
  const MetricTrend({
    required this.comparable,
    required this.direction,
    required this.changePercent,
    required this.currentCount,
    required this.previousCount,
    required this.spark,
  });

  /// A metric with no comparable prior period — shows a plain snapshot marker.
  const MetricTrend.snapshot()
      : comparable = false,
        direction = TrendDirection.flat,
        changePercent = null,
        currentCount = 0,
        previousCount = 0,
        spark = const [];

  /// Whether a prior-period comparison exists for this metric.
  final bool comparable;

  final TrendDirection direction;

  /// Percent change vs the previous window. Null when the previous window was
  /// empty (any increase from zero is undefined, not "+100%").
  final double? changePercent;

  final int currentCount;
  final int previousCount;

  /// Evenly spaced buckets across the current window, for the sparkline.
  final List<double> spark;

  /// Formatted delta, e.g. `+12%`. Null when there is nothing to compare.
  String? get changeLabel {
    final pct = changePercent;
    if (!comparable || pct == null) return null;
    final rounded = pct.abs() >= 100 ? pct.round() : pct.roundToDouble();
    final sign = pct > 0 ? '+' : (pct < 0 ? '−' : '');
    return '$sign${rounded.abs().toStringAsFixed(0)}%';
  }

  /// True when the previous window held no data, so a percentage is undefined
  /// but the metric is still genuinely new activity.
  bool get isNewActivity =>
      comparable && changePercent == null && currentCount > 0;
}

abstract final class ReportsTrends {
  /// Maximum sparkline buckets — enough to read a shape, few enough to stay
  /// legible at 40dp wide.
  static const int sparkBuckets = 12;

  /// The window of equal length immediately preceding [start].
  static ({DateTime start, DateTime end}) previousWindow(
    DateTime start,
    DateTime end,
  ) {
    final span = end.difference(start);
    final previousEnd = start.subtract(const Duration(seconds: 1));
    return (start: previousEnd.subtract(span), end: previousEnd);
  }

  /// Builds a trend for any dated collection.
  static MetricTrend forDated<T>({
    required List<T> all,
    required DateTime? Function(T item) dateOf,
    required DateTime start,
    required DateTime end,
  }) {
    final previous = previousWindow(start, end);

    var current = 0;
    var prior = 0;
    final buckets = List<double>.filled(sparkBuckets, 0);
    final span = end.difference(start).inMilliseconds;

    for (final item in all) {
      final date = dateOf(item);
      if (date == null) continue;

      if (!date.isBefore(start) && !date.isAfter(end)) {
        current++;
        if (span > 0) {
          final offset = date.difference(start).inMilliseconds / span;
          final index =
              (offset * sparkBuckets).floor().clamp(0, sparkBuckets - 1);
          buckets[index] += 1;
        } else {
          buckets[sparkBuckets - 1] += 1;
        }
      } else if (!date.isBefore(previous.start) &&
          !date.isAfter(previous.end)) {
        prior++;
      }
    }

    final double? changePercent =
        prior == 0 ? null : ((current - prior) / prior) * 100;

    final direction = current == prior
        ? TrendDirection.flat
        : (current > prior ? TrendDirection.up : TrendDirection.down);

    return MetricTrend(
      comparable: true,
      direction: direction,
      changePercent: changePercent,
      currentCount: current,
      previousCount: prior,
      spark: buckets,
    );
  }

  /// Normalises a bucket list to 0..1 for painting. Returns an empty list when
  /// there is nothing to draw.
  static List<double> normalize(List<double> values) {
    if (values.isEmpty) return const [];
    final max = values.fold<double>(0, (m, v) => math.max(m, v));
    if (max <= 0) return List<double>.filled(values.length, 0);
    return [for (final v in values) v / max];
  }
}
