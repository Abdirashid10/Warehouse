import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_activity_stream.dart';

export 'package:logisticsmobile/features/audit/presentation/widgets/audit_activity_stream.dart'
    show AuditDateFilter, filterAuditByDate, AuditLogCard, AuditStamp;

/// Audit tab of the Administration console.
///
/// A thin host over [AuditActivityStream] so the console and the standalone
/// Audit Logs screen share one implementation — the console supplies its own
/// tab chrome, so the stream's security header is suppressed here.
class AdminAuditPanel extends StatelessWidget {
  const AdminAuditPanel({
    super.key,
    required this.cubit,
    required this.searchController,
    this.padding = true,
  });

  final AuditCubit cubit;
  final TextEditingController searchController;
  final bool padding;

  @override
  Widget build(BuildContext context) {
    return AuditActivityStream(
      cubit: cubit,
      searchController: searchController,
      padding: padding,
      showHeader: false,
    );
  }
}
