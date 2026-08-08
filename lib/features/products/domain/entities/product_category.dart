import 'package:equatable/equatable.dart';

class ProductCategory extends Equatable {
  const ProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
