import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.createdAt,
    this.category,
    this.performedBy,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime? createdAt;
  final String? category;
  final String? performedBy;

  String get categoryLabel =>
      (category ?? type).replaceAll('_', ' ').trim().toUpperCase();

  @override
  List<Object?> get props =>
      [id, title, message, type, read, createdAt, category, performedBy];
}
