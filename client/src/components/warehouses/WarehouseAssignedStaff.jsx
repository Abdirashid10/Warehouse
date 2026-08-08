import { UserAvatar } from '../profile/UserAvatar';
import { roleBadgeClass } from '../../utils/roles';

function staffDisplayName(member) {
  return member.full_name || member.username || member.email || 'Staff';
}

export function WarehouseAssignedStaff({ staff = [], compact = false, maxVisible = 3 }) {
  if (!staff.length) {
    return <span className="text-xs text-muted-foreground">No staff assigned</span>;
  }

  const visible = staff.slice(0, maxVisible);
  const overflow = staff.length - visible.length;

  if (compact) {
    return (
      <div className="flex items-center -space-x-2">
        {visible.map((member) => (
          <UserAvatar
            key={member.id}
            user={{
              fullName: member.full_name,
              username: member.username,
              email: member.email,
              avatar: member.avatar,
            }}
            size="sm"
            className="ring-2 ring-card"
            title={staffDisplayName(member)}
          />
        ))}
        {overflow > 0 ? (
          <span className="ml-3 text-xs font-medium text-muted-foreground">+{overflow}</span>
        ) : null}
      </div>
    );
  }

  return (
    <ul className="space-y-2">
      {staff.map((member) => (
        <li key={member.id} className="flex items-center gap-2.5">
          <UserAvatar
            user={{
              fullName: member.full_name,
              username: member.username,
              email: member.email,
              avatar: member.avatar,
            }}
            size="sm"
          />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium text-foreground">{staffDisplayName(member)}</p>
            <p className="truncate text-xs text-muted-foreground">@{member.username}</p>
          </div>
          <span className={`shrink-0 wms-badge text-[10px] ${roleBadgeClass(member.role)}`}>Staff</span>
        </li>
      ))}
    </ul>
  );
}
