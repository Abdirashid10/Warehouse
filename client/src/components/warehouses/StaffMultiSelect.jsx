import { useMemo, useState } from 'react';
import { Check, ChevronDown, Search, X } from 'lucide-react';
import { UserAvatar } from '../profile/UserAvatar';
import { cn } from '../../lib/utils';

function staffLabel(member) {
  return member.full_name || member.username || member.email;
}

export function StaffMultiSelect({
  candidates = [],
  value = [],
  onChange,
  disabled,
  loading,
}) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');

  const selectedSet = useMemo(() => new Set(value.map(String)), [value]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return candidates;
    return candidates.filter((c) => {
      const hay = `${c.full_name || ''} ${c.username || ''} ${c.email || ''}`.toLowerCase();
      return hay.includes(q);
    });
  }, [candidates, search]);

  const selectedMembers = useMemo(
    () => candidates.filter((c) => selectedSet.has(String(c.id))),
    [candidates, selectedSet]
  );

  function toggle(id) {
    const key = String(id);
    if (selectedSet.has(key)) {
      onChange(value.filter((v) => String(v) !== key));
    } else {
      onChange([...value, key]);
    }
  }

  function remove(id) {
    onChange(value.filter((v) => String(v) !== String(id)));
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm font-medium text-foreground">Assign staff</p>
        <span className="text-xs text-muted-foreground">
          {value.length} selected · Staff role only
        </span>
      </div>

      {selectedMembers.length > 0 ? (
        <div className="flex flex-wrap gap-2">
          {selectedMembers.map((member) => (
            <span
              key={member.id}
              className="inline-flex items-center gap-1.5 rounded-full border border-border bg-muted/50 py-1 pl-1 pr-2 text-xs font-medium text-foreground"
            >
              <UserAvatar
                user={{
                  fullName: member.full_name,
                  username: member.username,
                  email: member.email,
                  avatar: member.avatar,
                }}
                size="sm"
                className="h-6 w-6 text-[10px]"
              />
              {staffLabel(member)}
              {!disabled ? (
                <button
                  type="button"
                  onClick={() => remove(member.id)}
                  className="rounded-full p-0.5 text-muted-foreground hover:bg-muted hover:text-foreground"
                  aria-label={`Remove ${staffLabel(member)}`}
                >
                  <X className="h-3 w-3" />
                </button>
              ) : null}
            </span>
          ))}
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">No staff selected yet.</p>
      )}

      <div className="relative">
        <button
          type="button"
          disabled={disabled}
          onClick={() => setOpen((v) => !v)}
          className={cn(
            'flex w-full items-center justify-between rounded-lg border border-border bg-background px-3 py-2.5 text-sm transition',
            'hover:border-accent/40 hover:bg-muted/30',
            open && 'border-accent ring-2 ring-accent/20',
            disabled && 'cursor-not-allowed opacity-60'
          )}
        >
          <span className="text-muted-foreground">
            {loading ? 'Loading staff…' : 'Search and select staff members'}
          </span>
          <ChevronDown className={cn('h-4 w-4 text-muted-foreground transition', open && 'rotate-180')} />
        </button>

        {open && !disabled ? (
          <div className="absolute z-20 mt-2 w-full overflow-hidden rounded-xl border border-border bg-card shadow-2xl">
            <div className="border-b border-border p-2">
              <div className="relative">
                <Search className="pointer-events-none absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <input
                  type="search"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search by name or email…"
                  className="wms-input w-full py-2 pl-9 pr-3 text-sm"
                  autoFocus
                />
              </div>
            </div>
            <ul className="max-h-56 overflow-y-auto p-1">
              {filtered.length === 0 ? (
                <li className="px-3 py-6 text-center text-sm text-muted-foreground">
                  {loading ? 'Loading…' : 'No Staff users match your search.'}
                </li>
              ) : (
                filtered.map((member) => {
                  const checked = selectedSet.has(String(member.id));
                  return (
                    <li key={member.id}>
                      <button
                        type="button"
                        onClick={() => toggle(member.id)}
                        className={cn(
                          'flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-left transition',
                          checked ? 'bg-accent/10' : 'hover:bg-muted'
                        )}
                      >
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
                          <p className="truncate text-sm font-medium text-foreground">
                            {staffLabel(member)}
                          </p>
                          <p className="truncate text-xs text-muted-foreground">{member.email}</p>
                        </div>
                        <span
                          className={cn(
                            'flex h-5 w-5 shrink-0 items-center justify-center rounded border',
                            checked
                              ? 'border-accent bg-accent text-white'
                              : 'border-border bg-background'
                          )}
                        >
                          {checked ? <Check className="h-3 w-3" /> : null}
                        </span>
                      </button>
                    </li>
                  );
                })
              )}
            </ul>
          </div>
        ) : null}
      </div>
    </div>
  );
}
