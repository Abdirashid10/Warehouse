import { useEffect, useMemo, useRef, useState } from 'react';
import { Check, ChevronsUpDown, Loader2, Search, X } from 'lucide-react';
import { UserAvatar } from '../profile/UserAvatar';

/**
 * Searchable staff picker (combobox) for task assignment.
 *
 * Built in-house rather than pulling in react-select: it needs the project's `wms-input`
 * styling, dark-mode tokens and avatar rows, and it keeps the dependency list unchanged.
 *
 * Behaviour:
 *  - closed, it reads as a normal dropdown control showing the current assignee;
 *  - open, it filters on name / username / email as you type;
 *  - ↑/↓ move the active option, Enter selects it, Escape closes, blur/outside-click closes;
 *  - selecting fires `onSelect(staff)` so the parent can store the id AND clear its
 *    "Assign a staff member" validation error in the same update.
 */

function matches(staff, query) {
  return `${staff.full_name || ''} ${staff.username || ''} ${staff.email || ''}`
    .toLowerCase()
    .includes(query);
}

export function StaffCombobox({
  staff = [],
  selectedId = '',
  onSelect,
  disabled = false,
  loading = false,
  fallback = false,
  placeholder = 'Search staff by name…',
  emptyLabel = 'No active staff members found',
  disabledLabel = 'Select a warehouse first',
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [activeIndex, setActiveIndex] = useState(0);
  const rootRef = useRef(null);
  const inputRef = useRef(null);

  const selected = useMemo(
    () => staff.find((s) => s.id === selectedId) || null,
    [staff, selectedId]
  );

  const options = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return staff;
    const hits = staff.filter((s) => matches(s, q));
    // Never dead-end on a typo — an unmatched query still offers the full roster.
    return hits.length ? hits : staff;
  }, [staff, query]);

  const noHits = query.trim().length > 0 && staff.length > 0
    && !staff.some((s) => matches(s, query.trim().toLowerCase()));

  useEffect(() => {
    setActiveIndex(0);
  }, [query, open]);

  useEffect(() => {
    if (!open) return undefined;
    function onPointerDown(e) {
      if (rootRef.current && !rootRef.current.contains(e.target)) {
        setOpen(false);
        setQuery('');
      }
    }
    document.addEventListener('mousedown', onPointerDown);
    return () => document.removeEventListener('mousedown', onPointerDown);
  }, [open]);

  function openMenu() {
    if (disabled || loading) return;
    setOpen(true);
    requestAnimationFrame(() => inputRef.current?.focus());
  }

  function choose(member) {
    if (!member) return;
    onSelect?.(member);
    setOpen(false);
    setQuery('');
  }

  function onKeyDown(e) {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      e.preventDefault();
      if (!open) { openMenu(); return; }
      const delta = e.key === 'ArrowDown' ? 1 : -1;
      setActiveIndex((i) => (options.length ? (i + delta + options.length) % options.length : 0));
    } else if (e.key === 'Enter') {
      if (open) {
        e.preventDefault();
        choose(options[activeIndex]);
      }
    } else if (e.key === 'Escape') {
      setOpen(false);
      setQuery('');
    }
  }

  const triggerLabel = selected
    ? (selected.full_name || selected.username)
    : disabled
      ? disabledLabel
      : staff.length === 0 && !loading
        ? emptyLabel
        : 'Select staff member…';

  return (
    <div ref={rootRef} className="relative mt-1" onKeyDown={onKeyDown}>
      {/* Trigger — matches the height/border of the sibling `wms-input` selects */}
      <button
        type="button"
        disabled={disabled || loading}
        onClick={() => (open ? setOpen(false) : openMenu())}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label="Assign staff member"
        className="wms-input flex w-full items-center gap-2 text-left disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading ? (
          <Loader2 className="h-3.5 w-3.5 shrink-0 animate-spin text-muted-foreground" />
        ) : selected ? (
          <UserAvatar
            user={{ fullName: selected.full_name, username: selected.username, email: selected.email, avatar: selected.avatar }}
            size="sm"
          />
        ) : (
          <Search className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
        )}
        <span className={`flex-1 truncate ${selected ? 'font-medium text-foreground' : 'text-muted-foreground'}`}>
          {loading ? 'Loading staff…' : triggerLabel}
        </span>
        {selected && !disabled && (
          <span
            role="button"
            tabIndex={-1}
            aria-label="Clear assignee"
            onClick={(e) => { e.stopPropagation(); onSelect?.(null); }}
            className="rounded p-0.5 text-muted-foreground transition hover:bg-muted hover:text-foreground"
          >
            <X className="h-3.5 w-3.5" />
          </span>
        )}
        <ChevronsUpDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
      </button>

      {open && (
        <div className="absolute z-50 mt-1 w-full overflow-hidden rounded-lg border border-border bg-card shadow-lg">
          <div className="flex items-center gap-2 border-b border-border px-2.5 py-2">
            <Search className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
            <input
              ref={inputRef}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={placeholder}
              autoComplete="off"
              className="w-full bg-transparent text-xs text-foreground outline-none placeholder:text-muted-foreground"
            />
          </div>

          {fallback && (
            <p className="border-b border-border/60 bg-amber-50/60 px-2.5 py-1.5 text-[10px] text-amber-700 dark:bg-amber-500/10 dark:text-amber-300">
              No staff mapped to this warehouse — showing all {staff.length} active staff.
            </p>
          )}
          {noHits && (
            <p className="border-b border-border/60 px-2.5 py-1.5 text-[10px] text-muted-foreground">
              No match for “{query.trim()}” — showing all {staff.length} staff.
            </p>
          )}

          <ul role="listbox" className="max-h-52 overflow-y-auto py-1">
            {options.length === 0 ? (
              <li className="px-2.5 py-3 text-center text-xs text-muted-foreground">{emptyLabel}</li>
            ) : (
              options.map((s, i) => {
                const isSelected = s.id === selectedId;
                const isActive = i === activeIndex;
                return (
                  <li key={s.id} role="option" aria-selected={isSelected}>
                    <button
                      type="button"
                      onMouseEnter={() => setActiveIndex(i)}
                      onClick={() => choose(s)}
                      className={`flex w-full items-center gap-2.5 px-2.5 py-1.5 text-left text-sm transition ${isActive ? 'bg-muted' : ''}`}
                    >
                      <UserAvatar
                        user={{ fullName: s.full_name, username: s.username, email: s.email, avatar: s.avatar }}
                        size="sm"
                      />
                      <span className="min-w-0 flex-1">
                        <span className="block truncate font-medium text-foreground">{s.full_name || s.username}</span>
                        <span className="block truncate text-[10px] text-muted-foreground">
                          {s.warehouse_names?.length ? s.warehouse_names.join(' · ') : s.username}
                        </span>
                      </span>
                      {isSelected && <Check className="h-3.5 w-3.5 shrink-0 text-accent" />}
                    </button>
                  </li>
                );
              })
            )}
          </ul>
        </div>
      )}
    </div>
  );
}
