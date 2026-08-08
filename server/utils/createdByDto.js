/** Populate path for user refs on movements and catalog records. */
const CREATED_BY_SELECT = 'username email role fullName';

const DELETED_USER_LABEL = 'Deleted User';

function pickPopulatedUser(...candidates) {
  for (const user of candidates) {
    if (user && typeof user === 'object' && user.username) {
      return user;
    }
  }
  return null;
}

function extractUserIdRef(doc) {
  if (!doc || typeof doc !== 'object') return null;

  for (const field of ['createdBy', 'userId', 'performedBy', 'actorId']) {
    const value = doc[field];
    if (!value) continue;
    if (typeof value === 'object' && value._id) {
      return value._id.toString();
    }
    if (typeof value === 'string' || value.toString) {
      return value.toString();
    }
  }
  return null;
}

/**
 * Standard performer / created-by payload for API responses.
 */
function formatPerformedByUser(doc, options = {}) {
  const user = pickPopulatedUser(
    doc?.creator,
    doc?.performer,
    doc?.createdBy,
    doc?.userId
  );

  if (!user) {
    const refId = extractUserIdRef(doc);
    if (refId || options.missingMeansDeleted) {
      return {
        id: refId || null,
        username: null,
        full_name: null,
        fullName: null,
        name: DELETED_USER_LABEL,
        role: '',
        display_name: DELETED_USER_LABEL,
        display_label: DELETED_USER_LABEL,
        deleted: true,
      };
    }
    return null;
  }

  const displayName = (user.fullName || '').trim() || user.username;
  const role = user.role || '';

  return {
    id: user._id?.toString(),
    username: user.username,
    full_name: user.fullName || '',
    fullName: user.fullName || '',
    name: displayName,
    role,
    display_name: displayName,
    display_label: role ? `${displayName} (${role})` : displayName,
    deleted: false,
  };
}

function formatCreatedBy(doc) {
  return formatPerformedByUser(doc);
}

function attachCreatedByFields(formatted, doc) {
  if (!formatted || !doc) return formatted;
  const created_by = formatCreatedBy(doc);
  return {
    ...formatted,
    created_by,
    performed_by: created_by,
  };
}

module.exports = {
  CREATED_BY_SELECT,
  DELETED_USER_LABEL,
  formatPerformedByUser,
  formatCreatedBy,
  attachCreatedByFields,
  extractUserIdRef,
};
