import 'package:equatable/equatable.dart';

enum WarehouseCapacityFilter {
  active,
  lowCapacity,
  highCapacity,
  full,
}

enum WarehouseStatusLabel {
  active,
  warning,
  full,
}

class WarehouseStaffMember extends Equatable {
  const WarehouseStaffMember({
    required this.id,
    required this.displayName,
    this.username,
    this.avatar,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? avatar;

  @override
  List<Object?> get props => [id, displayName, username, avatar];
}

class Warehouse extends Equatable {
  const Warehouse({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.staffCount,
    this.totalUnits = 0,
    this.utilization = 0,
    this.lineCount = 0,
    this.assignedStaff = const [],
  });

  final String id;
  final String name;
  final String location;
  final num capacity;
  final int staffCount;
  final num totalUnits;
  final int utilization;
  final int lineCount;
  final List<WarehouseStaffMember> assignedStaff;

  num get availableCapacity {
    final available = capacity - totalUnits;
    return available < 0 ? 0 : available;
  }

  int get utilizationPercent {
    if (utilization > 0) return utilization;
    if (capacity <= 0) return 0;
    return ((totalUnits / capacity) * 100).round().clamp(0, 100);
  }

  WarehouseStatusLabel get statusLabel {
    final pct = utilizationPercent;
    if (pct >= 90) return WarehouseStatusLabel.full;
    if (pct >= 70) return WarehouseStatusLabel.warning;
    return WarehouseStatusLabel.active;
  }

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  bool matchesCapacityFilter(WarehouseCapacityFilter filter) {
    final pct = utilizationPercent;
    switch (filter) {
      case WarehouseCapacityFilter.active:
        return pct < 70;
      case WarehouseCapacityFilter.lowCapacity:
        return pct < 40;
      case WarehouseCapacityFilter.highCapacity:
        return pct >= 70 && pct < 90;
      case WarehouseCapacityFilter.full:
        return pct >= 90;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        capacity,
        staffCount,
        totalUnits,
        utilization,
        lineCount,
        assignedStaff,
      ];
}

class WarehousesSummary {
  const WarehousesSummary({
    required this.totalWarehouses,
    required this.totalUnitsStored,
    required this.totalStaff,
    required this.averageCapacityUsed,
  });

  final int totalWarehouses;
  final num totalUnitsStored;
  final int totalStaff;
  final int averageCapacityUsed;

  factory WarehousesSummary.fromWarehouses(List<Warehouse> warehouses) {
    if (warehouses.isEmpty) {
      return const WarehousesSummary(
        totalWarehouses: 0,
        totalUnitsStored: 0,
        totalStaff: 0,
        averageCapacityUsed: 0,
      );
    }

    final totalUnits =
        warehouses.fold<num>(0, (sum, w) => sum + (w.totalUnits));
    final totalCap =
        warehouses.fold<num>(0, (sum, w) => sum + (w.capacity));
    final totalStaff =
        warehouses.fold<int>(0, (sum, w) => sum + w.staffCount);
    final avgUsed = totalCap <= 0
        ? 0
        : ((totalUnits / totalCap) * 100).round().clamp(0, 100);

    return WarehousesSummary(
      totalWarehouses: warehouses.length,
      totalUnitsStored: totalUnits,
      totalStaff: totalStaff,
      averageCapacityUsed: avgUsed,
    );
  }
}

class WarehousePerformanceRankings {
  const WarehousePerformanceRankings({
    this.topUtilized,
    this.lowestUtilized,
    this.largest,
    this.mostActive,
  });

  final Warehouse? topUtilized;
  final Warehouse? lowestUtilized;
  final Warehouse? largest;
  final Warehouse? mostActive;

  factory WarehousePerformanceRankings.fromWarehouses(List<Warehouse> list) {
    if (list.isEmpty) {
      return const WarehousePerformanceRankings();
    }

    Warehouse? top;
    Warehouse? lowest;
    Warehouse? largest;
    Warehouse? mostActive;

    for (final w in list) {
      if (top == null || w.utilizationPercent > top.utilizationPercent) {
        top = w;
      }
      if (lowest == null || w.utilizationPercent < lowest.utilizationPercent) {
        lowest = w;
      }
      if (largest == null || w.capacity > largest.capacity) {
        largest = w;
      }
      if (mostActive == null || w.totalUnits > mostActive.totalUnits) {
        mostActive = w;
      }
    }

    return WarehousePerformanceRankings(
      topUtilized: top,
      lowestUtilized: lowest,
      largest: largest,
      mostActive: mostActive,
    );
  }
}
