import 'package:equatable/equatable.dart';

class AuditActivity extends Equatable {
  const AuditActivity({
    required this.id,
    required this.action,
    required this.module,
    required this.details,
    required this.userName,
    this.occurredAt,
  });

  final String id;
  final String action;
  final String module;
  final String details;
  final String userName;
  final DateTime? occurredAt;

  @override
  List<Object?> get props => [id, action, module, details, userName, occurredAt];
}

class AuditPage extends Equatable {
  const AuditPage({
    required this.activities,
    required this.page,
    required this.pages,
    required this.total,
  });

  final List<AuditActivity> activities;
  final int page;
  final int pages;
  final int total;

  bool get hasMore => page < pages;

  @override
  List<Object?> get props => [activities, page, pages, total];
}
