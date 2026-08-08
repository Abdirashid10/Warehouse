import { cn } from '../../lib/utils';
import { getInitials } from '../../utils/avatar';

const SIZE_MAP = {
  sm: 'h-8 w-8 text-xs',
  md: 'h-10 w-10 text-sm',
  lg: 'h-16 w-16 text-lg',
  xl: 'h-24 w-24 text-2xl',
};

export function UserAvatar({ user, size = 'md', className }) {
  const initials = getInitials(user?.fullName, user?.username, user?.email);
  const sizeClass = SIZE_MAP[size] || SIZE_MAP.md;

  if (user?.avatar) {
    return (
      <img
        src={user.avatar}
        alt={user.fullName || user.username || 'Profile'}
        className={cn('shrink-0 rounded-full object-cover ring-2 ring-border', sizeClass, className)}
      />
    );
  }

  return (
    <div
      className={cn(
        'flex shrink-0 items-center justify-center rounded-full bg-accent-soft font-semibold text-accent ring-2 ring-accent/20',
        sizeClass,
        className
      )}
      aria-hidden
    >
      {initials}
    </div>
  );
}
