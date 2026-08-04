import 'package:equatable/equatable.dart';

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.type,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.performedBy,
    required this.timestamp,
    this.fromLocation,
    this.toLocation,
    this.notes,
    this.relatedTaskId,
  });

  final String id;
  final String type;
  final String productName;
  final String sku;
  final num quantity;
  final String performedBy;
  final DateTime? timestamp;
  final String? fromLocation;
  final String? toLocation;
  final String? notes;
  final String? relatedTaskId;

  @override
  List<Object?> get props => [
        id,
        type,
        productName,
        sku,
        quantity,
        performedBy,
        timestamp,
        fromLocation,
        toLocation,
        notes,
        relatedTaskId,
      ];
}

class MovementStats extends Equatable {
  const MovementStats({
    required this.total,
    required this.inbound,
    required this.outbound,
    required this.transfers,
    required this.adjustments,
    this.returns = 0,
  });

  final int total;
  final int inbound;
  final int outbound;
  final int transfers;
  final int adjustments;
  final int returns;

  @override
  List<Object?> get props =>
      [total, inbound, outbound, transfers, adjustments, returns];
}
