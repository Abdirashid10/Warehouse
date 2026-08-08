const DELETED_USER_LABEL = 'Deleted User';

/**
 * Resolve display text for movement / audit performer fields from API.
 */
export function formatPerformerDisplay(performedBy) {
  if (!performedBy) {
    return {
      primary: DELETED_USER_LABEL,
      withRole: DELETED_USER_LABEL,
      deleted: true,
    };
  }

  if (performedBy.deleted) {
    return {
      primary: DELETED_USER_LABEL,
      withRole: DELETED_USER_LABEL,
      deleted: true,
    };
  }

  const primary =
    performedBy.display_name ||
    performedBy.full_name ||
    performedBy.fullName ||
    performedBy.name ||
    performedBy.username ||
    DELETED_USER_LABEL;

  const withRole =
    performedBy.display_label ||
    (performedBy.role ? `${primary} (${performedBy.role})` : primary);

  return {
    primary,
    withRole,
    deleted: primary === DELETED_USER_LABEL,
  };
}

export function performerSearchText(performedBy) {
  const { primary, withRole } = formatPerformerDisplay(performedBy);
  return [primary, withRole, performedBy?.username, performedBy?.role].filter(Boolean).join(' ');
}
