import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/presentation/pages/user_detail_screen.dart';

/// Opens the full enterprise user detail screen (web-parity).
void showUserDetailSheet(
  BuildContext context,
  WmsUser user, {
  List<AuditActivity> recentActivities = const [],
}) {
  openUserDetail(context, user, auditActivities: recentActivities);
}
