enum UserRole {
  admin,
  supervisor,
  staff,
  unknown;

  /// Parses backend roles: `Admin`, `Supervisor`, `Staff` (any casing).
  static UserRole fromString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return UserRole.unknown;

    switch (normalized.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'supervisor':
      case 'manager':
        return UserRole.supervisor;
      case 'staff':
      case 'warehouse staff':
      case 'warehouse associate':
      case 'associate':
      case 'operator':
        return UserRole.staff;
      default:
        return UserRole.unknown;
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.staff:
        return 'Warehouse Staff';
      case UserRole.unknown:
        return 'Staff';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isSupervisor => this == UserRole.supervisor;
  bool get isStaff => this == UserRole.staff;
}
