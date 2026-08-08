import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.warehouse,
    this.permissions = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? warehouse;
  final List<String> permissions;

  bool hasPermission(String permission) =>
      permissions.contains(permission) || role.isAdmin;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [id, fullName, email, role, warehouse, permissions];
}
