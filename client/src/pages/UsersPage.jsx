import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import {
  Archive,
  ArchiveRestore,
  ArrowBigUpDash,
  KeyRound,
  Pencil,
  Search,
  Shield,
  Trash2,
  UserPlus,
  Users,
} from 'lucide-react';

import { Button } from '../components/ui/button';
import {
  DropdownMenu,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../components/ui/dropdown-menu';
import { Field, Input, Label } from '../components/ui/input';
import { Modal, ModalFooter } from '../components/ui/modal';
import { ROLES, roleBadgeClass } from '../utils/roles';
import { userStatusBadgeClass } from '../utils/userStatus';

function formatDateTime(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString(undefined, {
      dateStyle: 'medium',
      timeStyle: 'short',
    });
  } catch {
    return '—';
  }
}

async function fetchUsers() {
  const { data } = await api.get('/users');
  return data;
}

export function UsersPage() {
  const queryClient = useQueryClient();
  const { user: currentUser } = useAuth();

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
  });

  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [editTarget, setEditTarget] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const [resetPasswordResult, setResetPasswordResult] = useState(null);

  const [cUsername, setCUsername] = useState('');
  const [cEmail, setCEmail] = useState('');
  const [cPassword, setCPassword] = useState('');
  const [cRole, setCRole] = useState('Staff');
  const [createError, setCreateError] = useState('');

  const [eUsername, setEUsername] = useState('');
  const [eEmail, setEEmail] = useState('');
  const [eRole, setERole] = useState('Staff');
  const [ePassword, setEPassword] = useState('');
  const [editError, setEditError] = useState('');

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['users'] });
    queryClient.invalidateQueries({ queryKey: ['warehouses'] });
    queryClient.invalidateQueries({ queryKey: ['warehouse-staff-candidates'] });
  };

  const registerMutation = useMutation({
    mutationFn: (body) => api.post('/auth/register', body),
    onSuccess: () => {
      invalidate();
      setCreateOpen(false);
      setCUsername('');
      setCEmail('');
      setCPassword('');
      setCRole('Staff');
      setCreateError('');
    },
    onError: (err) => {
      setCreateError(err.response?.data?.message || err.message || 'Failed to create user');
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, body }) => api.patch(`/users/${id}`, body),
    onSuccess: () => {
      invalidate();
      setEditTarget(null);
      setEditError('');
    },
    onError: (err) => {
      setEditError(err.response?.data?.message || err.message || 'Update failed');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/users/${id}`),
    onSuccess: () => {
      invalidate();
      setConfirm(null);
    },
  });

  const promoteMutation = useMutation({
    mutationFn: (id) => api.post(`/users/${id}/promote`),
    onSuccess: () => {
      invalidate();
      setConfirm(null);
    },
  });

  const archiveMutation = useMutation({
    mutationFn: ({ id, archived }) => api.patch(`/users/${id}/archive`, { archived }),
    onSuccess: () => {
      invalidate();
      setConfirm(null);
    },
  });
  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => api.patch(`/users/${id}/status`, { status }),
    onSuccess: () => {
      invalidate();
      setConfirm(null);
    },
  });
  const resetPasswordMutation = useMutation({
    mutationFn: (id) => api.post(`/users/${id}/reset-password`),
    onSuccess: (res) => {
      invalidate();
      setConfirm(null);
      setResetPasswordResult(res.data);
    },
  });

  const users = data?.users || [];

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        (u.username || '').toLowerCase().includes(q) ||
        (u.email || '').toLowerCase().includes(q) ||
        (u.role || '').toLowerCase().includes(q)
    );
  }, [users, search]);

  function openEdit(u) {
    setEditError('');
    setEditTarget(u);
    setEUsername(u.username);
    setEEmail(u.email);
    setERole(u.role);
    setEPassword('');
  }

  function submitEdit(e) {
    e.preventDefault();
    setEditError('');
    const body = {
      username: eUsername.trim(),
      email: eEmail.trim(),
      role: eRole,
    };
    if (ePassword.trim().length > 0) {
      body.password = ePassword;
    }
    updateMutation.mutate({ id: editTarget._id, body });
  }

  function submitCreate(e) {
    e.preventDefault();
    setCreateError('');
    if (cPassword.length < 8) {
      setCreateError('Password must be at least 8 characters.');
      return;
    }
    registerMutation.mutate({
      username: cUsername.trim(),
      email: cEmail.trim(),
      password: cPassword,
      role: cRole,
    });
  }

  const selfId = currentUser?.id;

  function openConfirm(type, user, title, message) {
    setConfirm({ type, user, title, message });
  }

  return (
    <div className="min-h-full space-y-6 text-foreground">
      {/* ERP-style header */}
      <div className="flex flex-col gap-1 border-b border-border pb-5">
        <div className="flex items-center gap-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          <Shield className="h-3.5 w-3.5 text-accent" />
          Administration
          <span className="text-muted-foreground/60">/</span>
          <span className="text-foreground">Users</span>
        </div>
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h1 className="flex items-center gap-3 text-2xl font-semibold tracking-tight text-foreground">
              <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent-soft text-accent ring-1 ring-accent/30">
                <Users className="h-5 w-5" />
              </span>
              Users
            </h1>
            <p className="mt-2 max-w-2xl text-sm leading-relaxed text-muted-foreground">
              Create, edit, promote, archive, or remove accounts. Only{' '}
              <strong className="text-foreground">Administrators</strong> can access this module.
              Archived users cannot sign in.
            </p>
          </div>
          <Button
            type="button"
            onClick={() => {
              setCreateError('');
              setCreateOpen(true);
            }}
          >
            <UserPlus className="h-4 w-4" />
            New user
          </Button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="relative max-w-md flex-1">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="search"
            placeholder="Filter by name, email, or role…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="wms-toolbar-input"
          />
        </div>
        <div className="wms-meta">
          {filtered.length} of {users.length} users
        </div>
      </div>

      {isLoading ? (
        <div className="wms-card wms-empty-state">Loading directory…</div>
      ) : isError ? (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error?.response?.data?.message || error?.message || 'Could not load users.'}
        </div>
      ) : (
        <div className="wms-table-shell">
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Last login</th>
                  <th>Last active</th>
                  <th>Updated at</th>
                  <th className="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((u) => {
                  const isSelf = selfId && String(u._id) === String(selfId);
                  const archived = Boolean(u.archived);
                  const status = u.status || (archived ? 'Archived' : 'Active');
                  return (
                    <tr key={u._id} className={archived ? 'opacity-75' : ''}>
                      <td>
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-foreground">{u.username}</span>
                          {isSelf ? (
                            <span className="wms-badge bg-accent-soft text-accent ring-1 ring-accent/25">
                              You
                            </span>
                          ) : null}
                        </div>
                      </td>
                      <td className="text-muted-foreground">{u.email}</td>
                      <td>
                        <span className={`wms-badge ${roleBadgeClass(u.role)}`}>{u.role}</span>
                      </td>
                      <td>
                        <span className={`wms-badge ${userStatusBadgeClass(status)}`}>{status}</span>
                      </td>
                      <td className="whitespace-nowrap font-mono wms-meta">
                        {formatDateTime(u.lastLoginAt)}
                      </td>
                      <td className="whitespace-nowrap font-mono wms-meta">
                        {formatDateTime(u.lastActiveAt)}
                      </td>
                      <td className="whitespace-nowrap font-mono wms-meta">
                        {formatDateTime(u.updatedAt)}
                      </td>
                      <td className="text-right">
                        <DropdownMenu
                          align="end"
                          trigger={<DropdownMenuTrigger />}
                        >
                          {(close) => (
                            <>
                              <DropdownMenuItem
                                close={close}
                                icon={Pencil}
                                label="Edit"
                                onClick={() => openEdit(u)}
                              />
                              <DropdownMenuItem
                                close={close}
                                icon={ArrowBigUpDash}
                                label="Promote"
                                variant="warning"
                                disabled={u.role !== 'Staff' || archived || promoteMutation.isPending}
                                onClick={() =>
                                  openConfirm(
                                    'promote',
                                    u,
                                    'Promote to Supervisor',
                                    'This will change the user role from Staff to Supervisor. Continue?'
                                  )
                                }
                              />
                              <DropdownMenuItem
                                close={close}
                                icon={archived ? ArchiveRestore : Archive}
                                label={archived ? 'Restore' : 'Archive'}
                                onClick={() =>
                                  openConfirm(
                                    archived ? 'restore' : 'archive',
                                    u,
                                    archived ? 'Restore user' : 'Archive user',
                                    archived
                                      ? 'Restore this account? They will be able to sign in again.'
                                      : 'Archive this account? They will no longer be able to sign in or use the API.'
                                  )
                                }
                                disabled={isSelf || archiveMutation.isPending}
                              />
                              <DropdownMenuItem
                                close={close}
                                label={status === 'Suspended' ? 'Activate' : 'Suspend'}
                                variant="warning"
                                onClick={() =>
                                  openConfirm(
                                    status === 'Suspended' ? 'activate' : 'suspend',
                                    u,
                                    status === 'Suspended' ? 'Activate user' : 'Suspend user',
                                    status === 'Suspended'
                                      ? 'Reactivate this account for system access.'
                                      : 'Suspend this account? User will not be able to access the system.'
                                  )
                                }
                                disabled={isSelf || statusMutation.isPending}
                              />
                              <DropdownMenuItem
                                close={close}
                                icon={KeyRound}
                                label="Reset password"
                                variant="primary"
                                onClick={() =>
                                  openConfirm(
                                    'reset-password',
                                    u,
                                    'Reset password',
                                    'Generate a temporary password and force change on next login?'
                                  )
                                }
                                disabled={isSelf || resetPasswordMutation.isPending}
                              />
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                close={close}
                                icon={Trash2}
                                label="Delete"
                                variant="danger"
                                onClick={() =>
                                  openConfirm(
                                    'delete',
                                    u,
                                    'Delete user',
                                    'Permanently delete this user? This cannot be undone. Consider archiving instead.'
                                  )
                                }
                                disabled={isSelf || deleteMutation.isPending}
                              />
                            </>
                          )}
                        </DropdownMenu>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 ? (
            <p className="wms-empty-state">No users match your filter.</p>
          ) : null}
        </div>
      )}

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="New user"
        description="Provision credentials and role."
      >
        <form onSubmit={submitCreate} className="space-y-4">
          <Field label="Username" required>
            <Input required minLength={2} value={cUsername} onChange={(e) => setCUsername(e.target.value)} />
          </Field>
          <Field label="Email" required>
            <Input type="email" required value={cEmail} onChange={(e) => setCEmail(e.target.value)} />
          </Field>
          <Field label="Password" required>
            <Input
              type="password"
              required
              minLength={8}
              value={cPassword}
              onChange={(e) => setCPassword(e.target.value)}
            />
          </Field>
          <div className="space-y-1.5">
            <Label>Role</Label>
            <select value={cRole} onChange={(e) => setCRole(e.target.value)} className="wms-input">
              {ROLES.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
          {createError ? <p className="text-sm text-red-600">{createError}</p> : null}
          <ModalFooter className="mt-0 border-0 pt-2">
            <Button type="button" variant="secondary" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={registerMutation.isPending}>
              {registerMutation.isPending ? 'Creating…' : 'Create user'}
            </Button>
          </ModalFooter>
        </form>
      </Modal>

      <Modal
        open={Boolean(editTarget)}
        onClose={() => setEditTarget(null)}
        title="Edit user"
        description="Update profile fields. Leave password blank to keep the current password."
      >
        <form onSubmit={submitEdit} className="space-y-4">
          <Field label="Username" required>
            <Input required minLength={2} value={eUsername} onChange={(e) => setEUsername(e.target.value)} />
          </Field>
          <Field label="Email" required>
            <Input type="email" required value={eEmail} onChange={(e) => setEEmail(e.target.value)} />
          </Field>
          <div className="space-y-1.5">
            <Label>Role</Label>
            <select value={eRole} onChange={(e) => setERole(e.target.value)} className="wms-input">
              {ROLES.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>
          <Field label="New password (optional)" hint="Leave blank to keep current">
            <Input
              type="password"
              minLength={8}
              value={ePassword}
              onChange={(e) => setEPassword(e.target.value)}
              placeholder="Leave blank to keep current"
            />
          </Field>
          {editError ? <p className="text-sm text-red-600">{editError}</p> : null}
          <ModalFooter className="mt-0 border-0 pt-2">
            <Button type="button" variant="secondary" onClick={() => setEditTarget(null)}>
              Cancel
            </Button>
            <Button type="submit" disabled={updateMutation.isPending}>
              {updateMutation.isPending ? 'Saving…' : 'Save changes'}
            </Button>
          </ModalFooter>
        </form>
      </Modal>

      <Modal
        open={Boolean(confirm)}
        onClose={() => setConfirm(null)}
        title={confirm?.title}
        description={confirm?.message}
      >
        {confirm ? (
          <>
            <p className="rounded-lg bg-muted px-3 py-2 font-mono text-xs text-muted-foreground">
              {confirm.user.username} · {confirm.user.email}
            </p>
            <ModalFooter className="mt-0 border-0 pt-4">
              <Button type="button" variant="secondary" onClick={() => setConfirm(null)}>
                Cancel
              </Button>
              <Button
                type="button"
                variant={confirm.type === 'delete' ? 'danger' : 'primary'}
                disabled={
                  deleteMutation.isPending ||
                  promoteMutation.isPending ||
                  archiveMutation.isPending ||
                  statusMutation.isPending ||
                  resetPasswordMutation.isPending
                }
                onClick={() => {
                  const id = confirm.user._id;
                  if (confirm.type === 'delete') deleteMutation.mutate(id);
                  else if (confirm.type === 'promote') promoteMutation.mutate(id);
                  else if (confirm.type === 'archive') archiveMutation.mutate({ id, archived: true });
                  else if (confirm.type === 'restore') archiveMutation.mutate({ id, archived: false });
                  else if (confirm.type === 'suspend') statusMutation.mutate({ id, status: 'Suspended' });
                  else if (confirm.type === 'activate') statusMutation.mutate({ id, status: 'Active' });
                  else if (confirm.type === 'reset-password') resetPasswordMutation.mutate(id);
                }}
              >
                {confirm.type === 'delete'
                  ? 'Delete permanently'
                  : confirm.type === 'promote'
                    ? 'Promote'
                    : confirm.type === 'reset-password'
                      ? 'Reset password'
                      : confirm.type === 'suspend'
                        ? 'Suspend'
                        : confirm.type === 'activate'
                          ? 'Activate'
                          : confirm.type === 'restore'
                            ? 'Restore'
                            : 'Archive'}
              </Button>
            </ModalFooter>
          </>
        ) : null}
      </Modal>

      <Modal
        open={Boolean(resetPasswordResult)}
        onClose={() => setResetPasswordResult(null)}
        title="Temporary password generated"
        description="Share this securely. User will be forced to change password on next login."
      >
        <p className="rounded-lg bg-emerald-50 px-3 py-2 font-mono text-sm text-emerald-800 ring-1 ring-emerald-200 dark:bg-emerald-500/10 dark:text-emerald-300">
          {resetPasswordResult?.temporaryPassword}
        </p>
        <ModalFooter className="mt-0 border-0 pt-4">
          <Button type="button" onClick={() => setResetPasswordResult(null)}>
            Done
          </Button>
        </ModalFooter>
      </Modal>
    </div>
  );
}
