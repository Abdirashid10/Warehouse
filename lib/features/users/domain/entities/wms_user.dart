import 'package:equatable/equatable.dart';

class WmsUser extends Equatable {
  const WmsUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.assignedWarehouse,
    this.archived = false,
    this.lastLoginAt,
    this.createdAt,
    this.loginCount,
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final String status;
  final String? fullName;
  final String? assignedWarehouse;
  final bool archived;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final int? loginCount;

  String get displayName =>
      fullName != null && fullName!.trim().isNotEmpty ? fullName!.trim() : username;

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }

  bool get isActive => status == 'Active' && !archived;

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        role,
        status,
        fullName,
        assignedWarehouse,
        archived,
        lastLoginAt,
        createdAt,
        loginCount,
      ];
}
