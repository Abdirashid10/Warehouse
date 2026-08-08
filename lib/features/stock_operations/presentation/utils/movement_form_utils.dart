/// Builds backend movement reason (min 10 chars required by API).
String buildMovementReason({
  required String notes,
  String? supplier,
  String? referenceNumber,
  String? returnReason,
}) {
  final parts = <String>[];
  if (notes.trim().isNotEmpty) parts.add(notes.trim());
  if (returnReason != null && returnReason.trim().isNotEmpty) {
    parts.add(returnReason.trim());
  }
  if (supplier != null && supplier.trim().isNotEmpty) {
    parts.add('Supplier: ${supplier.trim()}');
  }
  if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
    parts.add('Ref: ${referenceNumber.trim()}');
  }
  return parts.join(' — ');
}

const movementReasonMinLength = 10;

String? validateMovementReason(String reason) {
  final trimmed = reason.trim();
  if (trimmed.isEmpty) {
    return 'Notes / reason is required.';
  }
  if (trimmed.length < movementReasonMinLength) {
    return 'Enter at least $movementReasonMinLength characters in notes.';
  }
  return null;
}
