import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { StaffMultiSelect } from '../components/warehouses/StaffMultiSelect';
import { WarehouseAssignedStaff } from '../components/warehouses/WarehouseAssignedStaff';
import { Button } from '../components/ui/button';
import { Field, Input } from '../components/ui/input';
import {
  AlertTriangle,
  Box,
  Loader2,
  MapPin,
  Package,
  Pencil,
  Plus,
  Search,
  Users,
  Warehouse,
  X,
} from 'lucide-react';

/* ─── API ─── */

async function fetchWarehouses() {
  const { data } = await api.get('/inventory/warehouses');
  return data;
}

async function fetchStaffCandidates() {
  const { data } = await api.get('/inventory/warehouses/staff-candidates');
  return data;
}

/* ─── Helpers ─── */

function fmt(n) {
  if (n == null || Number.isNaN(n)) return '0';
  return Number(n).toLocaleString();
}

function utilPct(used, capacity) {
  if (!capacity || capacity <= 0) return 0;
  return Math.min(100, Math.round((used / capacity) * 100));
}

function utilColor(pct) {
  if (pct >= 90) return { bar: 'bg-red-500', text: 'text-red-600 dark:text-red-400', label: 'Critical' };
  if (pct >= 70) return { bar: 'bg-amber-500', text: 'text-amber-600 dark:text-amber-400', label: 'High' };
  if (pct >= 40) return { bar: 'bg-sky-500', text: 'text-sky-600 dark:text-sky-400', label: 'Normal' };
  return { bar: 'bg-emerald-500', text: 'text-emerald-600 dark:text-emerald-400', label: 'Low' };
}

const emptyForm = { name: '', location: '', capacity: '' };

/* ═══════════════════════════════════════════════════════════════
   MAIN EXPORT
   ═══════════════════════════════════════════════════════════════ */

export function WarehousesPage() {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const canManage = user?.role === 'Admin' || user?.role === 'Supervisor';

  const { data, isLoading, isError } = useQuery({
    queryKey: ['warehouses'],
    queryFn: fetchWarehouses,
    refetchOnWindowFocus: true,
  });
  const { data: staffData, isLoading: staffLoading } = useQuery({ queryKey: ['warehouse-staff-candidates'], queryFn: fetchStaffCandidates, enabled: canManage });

  const [searchQ, setSearchQ] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [createForm, setCreateForm] = useState(emptyForm);
  const [createStaffIds, setCreateStaffIds] = useState([]);
  const [createError, setCreateError] = useState('');

  const [editTarget, setEditTarget] = useState(null);
  const [editForm, setEditForm] = useState(emptyForm);
  const [editStaffIds, setEditStaffIds] = useState([]);
  const [editError, setEditError] = useState('');

  const staffCandidates = staffData?.staff || [];
  const allRows = data?.warehouses || [];

  const rows = useMemo(() => {
    if (!searchQ) return allRows;
    const q = searchQ.toLowerCase();
    return allRows.filter((w) =>
      (w.name || '').toLowerCase().includes(q) ||
      (w.location || '').toLowerCase().includes(q)
    );
  }, [allRows, searchQ]);

  const stats = useMemo(() => {
    const totalCap = allRows.reduce((s, w) => s + (w.capacity || 0), 0);
    const totalStaff = allRows.reduce((s, w) => s + (w.staff_count ?? 0), 0);
    const totalUnits = allRows.reduce(
      (s, w) => s + (w.totalUnits ?? w.total_units ?? 0),
      0
    );
    const avgUtilization = utilPct(totalUnits, totalCap);
    return { count: allRows.length, totalCap, totalStaff, totalUnits, avgUtilization };
  }, [allRows]);

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['warehouses'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
  };

  const createMutation = useMutation({
    mutationFn: (body) => api.post('/inventory/warehouses', body),
    onSuccess: () => { invalidate(); setCreateForm(emptyForm); setCreateStaffIds([]); setCreateError(''); setShowCreate(false); },
    onError: (err) => setCreateError(err.response?.data?.message || 'Could not create warehouse'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, body }) => api.patch(`/inventory/warehouses/${id}`, body),
    onSuccess: () => { invalidate(); setEditTarget(null); setEditError(''); },
    onError: (err) => setEditError(err.response?.data?.message || 'Could not update warehouse'),
  });

  function openEdit(warehouse) {
    setEditError('');
    setEditForm({ name: warehouse.name, location: warehouse.location, capacity: String(warehouse.capacity ?? '') });
    setEditStaffIds((warehouse.assigned_staff || []).map((s) => s.id));
    setEditTarget(warehouse);
  }

  function buildPayload(form, staffIds, setError) {
    const cap = Number(form.capacity);
    if (!form.name.trim() || !form.location.trim()) { setError('Name and location are required.'); return null; }
    if (!Number.isFinite(cap) || cap < 0) { setError('Capacity must be a valid non-negative number.'); return null; }
    return { name: form.name.trim(), location: form.location.trim(), capacity: cap, staff_ids: staffIds };
  }

  function handleCreate(e) {
    e.preventDefault();
    const body = buildPayload(createForm, createStaffIds, setCreateError);
    if (body) createMutation.mutate(body);
  }

  function handleUpdate(e) {
    e.preventDefault();
    if (!editTarget) return;
    const body = buildPayload(editForm, editStaffIds, setEditError);
    if (body) updateMutation.mutate({ id: editTarget.id || editTarget._id, body });
  }

  const isSaving = createMutation.isPending || updateMutation.isPending;

  /* ═══ Render ═══ */
  return (
    <div className="space-y-4 px-1">

      {/* ── Header ── */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-lg font-bold text-foreground">Warehouses</h1>
          <p className="text-xs text-muted-foreground">Infrastructure & capacity control · {stats.count} warehouse{stats.count !== 1 ? 's' : ''} active</p>
        </div>
        {canManage && (
          <button type="button" onClick={() => setShowCreate(!showCreate)} className="inline-flex items-center gap-1.5 rounded-lg border border-accent bg-accent px-3 py-1.5 text-xs font-semibold text-white shadow-sm transition hover:bg-accent/90 active:scale-[0.97] shrink-0">
            <Plus className="h-3.5 w-3.5" /> Add Warehouse
          </button>
        )}
      </div>

      {/* ── KPI Cards ── */}
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        <KpiMini label="Warehouses" value={stats.count} icon={Warehouse} color="text-sky-600 dark:text-sky-400" bg="bg-sky-50 dark:bg-sky-500/10" />
        <KpiMini label="Units Stored" value={`${fmt(stats.totalUnits)} Units`} icon={Package} color="text-emerald-600 dark:text-emerald-400" bg="bg-emerald-50 dark:bg-emerald-500/10" />
        <KpiMini label="Total Staff" value={`${stats.totalStaff} Staff`} icon={Users} color="text-violet-600 dark:text-violet-400" bg="bg-violet-50 dark:bg-violet-500/10" />
        <KpiMini label="Avg Capacity Used" value={`${stats.avgUtilization}% Capacity Used`} icon={Box} color="text-blue-600 dark:text-blue-400" bg="bg-blue-50 dark:bg-blue-500/10" />
      </div>

      {/* ── Create Form (collapsible) ── */}
      {showCreate && canManage && (
        <div className="rounded-lg border border-border bg-card">
          <div className="flex items-center justify-between border-b border-border/60 px-4 py-2.5">
            <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">New Warehouse</p>
            <button type="button" onClick={() => setShowCreate(false)} className="rounded-md p-1 text-muted-foreground transition hover:bg-muted hover:text-foreground">
              <X className="h-3.5 w-3.5" />
            </button>
          </div>
          <form onSubmit={handleCreate} className="space-y-3 px-4 py-3">
            <div className="grid gap-3 sm:grid-cols-3">
              <Field label="Name" required>
                <Input value={createForm.name} onChange={(e) => setCreateForm((f) => ({ ...f, name: e.target.value }))} placeholder="Main DC" className="h-8 text-xs" />
              </Field>
              <Field label="Location" required>
                <Input value={createForm.location} onChange={(e) => setCreateForm((f) => ({ ...f, location: e.target.value }))} placeholder="City, region" className="h-8 text-xs" />
              </Field>
              <Field label="Capacity (units)" required>
                <Input type="number" min={0} step={1} value={createForm.capacity} onChange={(e) => setCreateForm((f) => ({ ...f, capacity: e.target.value }))} placeholder="10000" className="h-8 text-xs" />
              </Field>
            </div>
            <div className="border-t border-border/60 pt-3">
              <StaffMultiSelect candidates={staffCandidates} value={createStaffIds} onChange={setCreateStaffIds} disabled={isSaving} loading={staffLoading} />
            </div>
            {createError && <ErrorBanner message={createError} />}
            <div className="flex justify-end">
              <Button type="submit" disabled={isSaving} size="sm">
                {createMutation.isPending ? 'Creating…' : 'Create Warehouse'}
              </Button>
            </div>
          </form>
        </div>
      )}

      {/* ── Search ── */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground" />
          <input type="text" value={searchQ} onChange={(e) => setSearchQ(e.target.value)} placeholder="Search warehouses, locations…" className="wms-input h-8 w-full pl-8 text-xs" />
        </div>
      </div>

      {/* ── Warehouses Grid ── */}
      {isLoading ? (
        <LoadingSkeleton />
      ) : isError ? (
        <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-3 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
          Failed to load warehouses.
        </div>
      ) : rows.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-dashed border-border bg-muted/10 py-14 text-center">
          <Warehouse className="h-10 w-10 text-muted-foreground/20" />
          <div>
            <p className="text-sm font-medium text-muted-foreground">{searchQ ? 'No warehouses match your search' : 'No warehouses yet'}</p>
            <p className="mt-0.5 text-[11px] text-muted-foreground/70">
              {searchQ ? 'Try a different search term.' : canManage ? 'Add your first warehouse to begin operations.' : 'Ask an Admin or Supervisor to create a warehouse.'}
            </p>
          </div>
          {canManage && !searchQ && (
            <button type="button" onClick={() => setShowCreate(true)} className="mt-1 inline-flex items-center gap-1 rounded-md border border-accent bg-accent/5 px-3 py-1.5 text-xs font-semibold text-accent transition hover:bg-accent/10">
              <Plus className="h-3 w-3" /> Add First Warehouse
            </button>
          )}
        </div>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {rows.map((w) => {
            const used = w.totalUnits ?? w.total_units ?? 0;
            const cap = w.capacity || 0;
            const pct = w.utilization ?? utilPct(used, cap);
            const uc = utilColor(pct);
            const staffCount = w.staff_count ?? 0;

            return (
              <div key={w.id || w._id} className="group rounded-lg border border-border bg-card transition hover:shadow-sm hover:border-border">
                {/* Card header */}
                <div className="flex items-start justify-between px-3.5 pt-3.5 pb-2">
                  <div className="flex items-center gap-2.5 min-w-0">
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-sky-50 dark:bg-sky-500/10">
                      <Warehouse className="h-4 w-4 text-sky-600 dark:text-sky-400" />
                    </div>
                    <div className="min-w-0">
                      <h3 className="text-sm font-bold text-foreground truncate">{w.name}</h3>
                      <p className="flex items-center gap-1 text-[10px] text-muted-foreground truncate">
                        <MapPin className="h-2.5 w-2.5 shrink-0" /> {w.location}
                      </p>
                    </div>
                  </div>
                  {canManage && (
                    <button type="button" onClick={() => openEdit(w)} className="rounded-md border border-border p-1.5 text-muted-foreground opacity-0 transition group-hover:opacity-100 hover:bg-muted hover:text-foreground focus:opacity-100" title="Edit warehouse">
                      <Pencil className="h-3 w-3" />
                    </button>
                  )}
                </div>

                {/* Capacity bar */}
                <div className="px-3.5 pb-2">
                  <div className="flex items-center justify-between text-[10px]">
                    <span className="text-muted-foreground">Capacity Used</span>
                    <span className={`font-bold tabular-nums ${uc.text}`}>{pct}% Capacity Used</span>
                  </div>
                  <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-muted">
                    <div className={`h-full rounded-full transition-all ${uc.bar}`} style={{ width: `${pct}%` }} />
                  </div>
                  <div className="mt-1 flex items-center justify-between text-[9px] text-muted-foreground tabular-nums">
                    <span>{fmt(used)} Units / {fmt(cap)} capacity</span>
                    <span>{fmt(Math.max(0, cap - used))} available</span>
                  </div>
                </div>

                {/* Stats row */}
                <div className="flex items-center gap-px border-t border-border/60">
                  <StatCell icon={Package} label="Stored" value={`${fmt(used)} Units`} />
                  <div className="w-px self-stretch bg-border/60" />
                  <StatCell icon={Users} label="Staff" value={`${staffCount} Staff`} />
                  <div className="w-px self-stretch bg-border/60" />
                  <div className="flex-1 px-2.5 py-2">
                    <WarehouseAssignedStaff staff={w.assigned_staff} compact maxVisible={3} />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* ── Footer ── */}
      {rows.length > 0 && (
        <p className="text-[11px] text-muted-foreground">
          {rows.length === allRows.length
            ? `${rows.length} warehouse${rows.length !== 1 ? 's' : ''}`
            : `${rows.length} of ${allRows.length} warehouses (filtered)`}
          {' '} · {fmt(stats.totalUnits)} units stored · {stats.totalStaff} staff assigned · {fmt(stats.totalCap)} total capacity
        </p>
      )}

      {/* ═══════════════════════════════════════════════════════════════
         EDIT MODAL
         ═══════════════════════════════════════════════════════════════ */}
      {editTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20 p-4 backdrop-blur-[2px]">
          <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-border bg-card shadow-2xl">
            {/* Modal header */}
            <div className="flex items-center justify-between border-b border-border px-5 py-3">
              <div>
                <h2 className="text-sm font-bold text-foreground">Edit Warehouse</h2>
                <p className="mt-0.5 text-[11px] text-muted-foreground">{editTarget.name}</p>
              </div>
              <button type="button" onClick={() => setEditTarget(null)} className="rounded-md p-1 text-muted-foreground transition hover:bg-muted hover:text-foreground">
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Current staff preview */}
            <div className="border-b border-border/60 px-5 py-3">
              <p className="mb-2 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Current Staff</p>
              <WarehouseAssignedStaff staff={editTarget.assigned_staff} />
            </div>

            <form onSubmit={handleUpdate} className="space-y-3 px-5 py-4">
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Name" required>
                  <Input value={editForm.name} onChange={(e) => setEditForm((f) => ({ ...f, name: e.target.value }))} className="h-8 text-xs" />
                </Field>
                <Field label="Location" required>
                  <Input value={editForm.location} onChange={(e) => setEditForm((f) => ({ ...f, location: e.target.value }))} className="h-8 text-xs" />
                </Field>
              </div>
              <Field label="Capacity (units)" required>
                <Input type="number" min={0} step={1} value={editForm.capacity} onChange={(e) => setEditForm((f) => ({ ...f, capacity: e.target.value }))} className="h-8 text-xs" />
              </Field>

              <div className="border-t border-border/60 pt-3">
                <StaffMultiSelect candidates={staffCandidates} value={editStaffIds} onChange={setEditStaffIds} disabled={isSaving} loading={staffLoading} />
              </div>

              {editError && <ErrorBanner message={editError} />}

              <div className="flex justify-end gap-2 pt-1">
                <button type="button" onClick={() => setEditTarget(null)} className="rounded-md border border-border px-3 py-1.5 text-[11px] font-medium text-muted-foreground transition hover:bg-muted hover:text-foreground">Cancel</button>
                <Button type="submit" disabled={isSaving} size="sm">
                  {updateMutation.isPending ? 'Saving…' : 'Save Changes'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════
   Sub-components
   ═══════════════════════════════════════════════════════════════ */

function KpiMini({ label, value, icon: Icon, color, bg }) {
  return (
    <div className="rounded-lg border border-border bg-card px-2.5 py-2">
      <div className="flex items-center gap-1.5">
        <div className={`flex h-5 w-5 items-center justify-center rounded ${bg}`}>
          <Icon className={`h-3 w-3 ${color}`} strokeWidth={2.2} />
        </div>
        <span className="text-[9px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</span>
      </div>
      <p className={`mt-0.5 text-lg font-bold tabular-nums leading-tight ${color}`}>{value}</p>
    </div>
  );
}

function StatCell({ icon: Icon, label, value }) {
  return (
    <div className="flex flex-1 items-center gap-1.5 px-2.5 py-2">
      <Icon className="h-3 w-3 text-muted-foreground" />
      <div>
        <p className="text-xs font-bold tabular-nums text-foreground">{value}</p>
        <p className="text-[8px] text-muted-foreground">{label}</p>
      </div>
    </div>
  );
}

function ErrorBanner({ message }) {
  return (
    <div className="flex items-start gap-2 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-[11px] font-medium text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
      <AlertTriangle className="mt-0.5 h-3 w-3 shrink-0" /> {message}
    </div>
  );
}

function LoadingSkeleton() {
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-40 animate-pulse rounded-lg bg-muted/30" />
      ))}
    </div>
  );
}
