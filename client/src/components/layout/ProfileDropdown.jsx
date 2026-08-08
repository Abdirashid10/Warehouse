import { useNavigate } from 'react-router-dom';
import { ChevronDown, KeyRound, LogOut, Settings, User } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { UserAvatar } from '../profile/UserAvatar';
import { DropdownMenu, DropdownMenuItem, DropdownMenuSeparator } from '../ui/dropdown-menu';

export function ProfileDropdown() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const displayName = user?.fullName || user?.username || 'Account';

  function handleSignOut() {
    logout();
    navigate('/login', { replace: true });
  }

  return (
    <div className="hidden lg:block">
      <DropdownMenu
        align="end"
        trigger={
          <button
            type="button"
            className="flex items-center gap-2 rounded-lg border border-border bg-card px-2 py-1.5 text-left transition hover:bg-muted"
            aria-label="Open profile menu"
          >
            <UserAvatar user={user} size="sm" />
            <span className="max-w-[8rem] truncate text-sm font-medium text-foreground">{displayName}</span>
            <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
          </button>
        }
      >
        {(close) => (
          <>
            <div className="border-b border-border px-3 py-2.5">
              <p className="truncate text-sm font-semibold text-foreground">{displayName}</p>
              {user?.email ? (
                <p className="truncate text-xs text-muted-foreground">{user.email}</p>
              ) : null}
            </div>
            <DropdownMenuItem
              icon={User}
              label="Profile"
              onClick={() => navigate('/profile')}
              close={close}
            />
            <DropdownMenuItem
              icon={Settings}
              label="Settings"
              onClick={() => navigate('/profile#appearance')}
              close={close}
            />
            <DropdownMenuItem
              icon={KeyRound}
              label="Change Password"
              onClick={() => navigate('/profile#security')}
              close={close}
            />
            <DropdownMenuSeparator />
            <DropdownMenuItem
              icon={LogOut}
              label="Sign Out"
              variant="danger"
              onClick={handleSignOut}
              close={close}
            />
          </>
        )}
      </DropdownMenu>
    </div>
  );
}
