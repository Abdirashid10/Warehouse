import 'package:logisticsmobile/features/stock_operations/data/datasources/movements_remote_data_source.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/domain/repositories/movements_repository.dart';

class MovementsRepositoryImpl implements MovementsRepository {
  MovementsRepositoryImpl(this._remote);

  final MovementsRemoteDataSource _remote;

  @override
  Future<({List<StockMovement> movements, MovementStats stats})> getMovements({
    String? type,
  }) async {
    final models = await _remote.fetchMovements(type: type);
    return (
      movements: models.map((m) => m.toEntity()).toList(),
      stats: _remote.computeStats(models),
    );
  }

  @override
  Future<StockMovement> createMovement(CreateMovementInput input) =>
      _remote.createMovement(input);
}
