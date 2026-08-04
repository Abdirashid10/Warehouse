class TaskAssignee {
  const TaskAssignee({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? email;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return username;
  }
}

class TaskFormWarehouse {
  const TaskFormWarehouse({
    required this.id,
    required this.name,
    this.location,
  });

  final String id;
  final String name;
  final String? location;
}

class TaskFormProduct {
  const TaskFormProduct({
    required this.id,
    required this.name,
    this.sku,
  });

  final String id;
  final String name;
  final String? sku;
}

class TaskFormMeta {
  const TaskFormMeta({
    this.warehouses = const [],
    this.products = const [],
  });

  final List<TaskFormWarehouse> warehouses;
  final List<TaskFormProduct> products;
}
