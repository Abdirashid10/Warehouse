import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.fullName,
    required this.email,
    required this.role,
    required this.username,
    this.phone,
    this.accountStatus = 'Active',
    this.assignedWarehouses = const [],
    this.permissions = const [],
    this.lastActiveAt,
    this.memberSince,
  });

  final String fullName;
  final String email;
  final String role;
  final String username;
  final String? phone;
  final String accountStatus;
  final List<String> assignedWarehouses;
  final List<String> permissions;
  final DateTime? lastActiveAt;
  final DateTime? memberSince;

  String get assignedWarehouseLabel {
    if (assignedWarehouses.isEmpty) return 'Not assigned';
    if (assignedWarehouses.length == 1) return assignedWarehouses.first;
    return assignedWarehouses.join(', ');
  }

  @override
  List<Object?> get props => [
        fullName,
        email,
        role,
        username,
        phone,
        accountStatus,
        assignedWarehouses,
        permissions,
        lastActiveAt,
        memberSince,
      ];
}
