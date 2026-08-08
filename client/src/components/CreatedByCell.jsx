import { roleBadgeClass } from '../utils/roles';
import { formatPerformerDisplay } from '../utils/performerDisplay';

/**
 * Displays created_by / performed_by from API responses.
 */
export function CreatedByCell({ createdBy, compact = false }) {
  const performer = formatPerformerDisplay(createdBy);

  return (
    <div className={compact ? 'flex min-w-[6rem] flex-col gap-1' : 'min-w-[6rem]'}>
      <div
        className={
          compact
            ? `text-sm font-medium leading-tight ${performer.deleted ? 'text-muted-foreground italic' : 'text-foreground'}`
            : `text-sm font-medium ${performer.deleted ? 'text-muted-foreground italic' : 'text-foreground'}`
        }
      >
        {performer.primary}
      </div>
      {createdBy?.role && !performer.deleted ? (
        <span
          className={`inline-flex w-fit wms-badge ${roleBadgeClass(createdBy.role)} ${compact ? 'mt-0' : 'mt-0.5'}`}
        >
          {createdBy.role}
        </span>
      ) : null}
    </div>
  );
}
