import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';

abstract class MovementsRepository {
  Future<({List<StockMovement> movements, MovementStats stats})> getMovements({
    String? type,
  });

  Future<StockMovement> createMovement(CreateMovementInput input);
}
