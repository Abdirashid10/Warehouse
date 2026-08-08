import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Activity,
  Camera,
  Eye,
  EyeOff,
  KeyRound,
  LayoutGrid,
  LogOut,
  Palette,
  Shield,
  Trash2,
  User,
} from 'lucide-react';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useAppearance } from '../context/AppearanceContext';
import { PageShell } from '../components/layout/PageShell';
import { UserAvatar } from '../components/profile/UserAvatar';
import { PasswordStrength } from '../components/profile/PasswordStrength';
import { AppearanceSettingsSection } from '../components/profile/AppearanceSettingsSection';
import { Button } from '../components/ui/button';
import { Field, Input } from '../components/ui/input';
import { roleBadgeClass } from '../utils/roles';
import {
  getAccountStatusClass,
  getAccountStatusLabel,
} from '../utils/rolePermissions';
import { validateAvatarFile } from '../utils/avatar';

async function fetchProfile() {
  const { data } = await api.get('/profile/me');
  return data;
}

function formatWhen(iso) {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
  } catch {
    return '—';
  }
}

export function ProfilePage() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { user, updateUser, logout } = useAuth();
  const { hydrateFromServer } = useAppearance();
  const fileRef = useRef(null);

  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [profileError, setProfileError] = useState('');
  const [profileSaved, setProfileSaved] = useState('');
  const [avatarPreview, setAvatarPreview] = useState(null);
  const [avatarError, setAvatarError] = useState('');

  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [passwordError, setPasswordError] = useState('');
  const [passwordSaved, setPasswordSaved] = useState('');

  const { data, isLoading, isError } = useQuery({
    queryKey: ['profile', 'me'],
    queryFn: fetchProfile,
  });

  useEffect(() => {
    if (!data?.profile) return;
    const p = data.profile;
    setFullName(p.fullName || '');
    setUsername(p.username || '');
    setEmail(p.email || '');
    setPhone(p.phone || '');
    if (p.preferences) hydrateFromServer(p.preferences);
  }, [data, hydrateFromServer]);

  const profile = data?.profile || user;

  const updateProfileMutation = useMutation({
    mutationFn: (body) => api.patch('/profile/me', body).then((r) => r.data),
    onSuccess: (payload) => {
      updateUser(payload.profile);
      setProfileSaved('Profile updated successfully.');
      setProfileError('');
      queryClient.invalidateQueries({ queryKey: ['profile', 'me'] });
    },
    onError: (err) => {
      setProfileError(err?.response?.data?.message || 'Failed to update profile');
      setProfileSaved('');
    },
  });

  const avatarMutation = useMutation({
    mutationFn: (avatar) => api.patch('/profile/avatar', { avatar }).then((r) => r.data),
    onSuccess: (payload) => {
      updateUser(payload.profile);
      setAvatarPreview(null);
      setAvatarError('');
      queryClient.invalidateQueries({ queryKey: ['profile', 'me'] });
    },
    onError: (err) => setAvatarError(err?.response?.data?.message || 'Failed to update avatar'),
  });

  const passwordMutation = useMutation({
    mutationFn: (body) => api.patch('/profile/password', body).then((r) => r.data),
    onSuccess: () => {
      setPasswordSaved('Password updated successfully.');
      setPasswordError('');
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      updateUser({ forcePasswordChange: false });
      queryClient.invalidateQueries({ queryKey: ['profile', 'me'] });
    },
    onError: (err) => {
      setPasswordError(err?.response?.data?.message || 'Failed to change password');
      setPasswordSaved('');
    },
  });

  useEffect(() => {
    if (profile?.forcePasswordChange) {
      document.getElementById('security')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, [profile?.forcePasswordChange]);

  async function handleAvatarPick(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const dataUrl = await validateAvatarFile(file);
      setAvatarPreview(dataUrl);
      setAvatarError('');
    } catch (err) {
      setAvatarError(err.message);
    }
    e.target.value = '';
  }

  function handleSaveProfile(e) {
    e.preventDefault();
    setProfileSaved('');
    updateProfileMutation.mutate({ fullName, username, email, phone });
  }

  function handleSaveAvatar() {
    if (avatarPreview) avatarMutation.mutate(avatarPreview);
  }

  function handleRemoveAvatar() {
    avatarMutation.mutate('');
    setAvatarPreview(null);
  }

  function handleChangePassword(e) {
    e.preventDefault();
    setPasswordSaved('');
    if (newPassword !== confirmPassword) {
      setPasswordError('New passwords do not match');
      return;
    }
    passwordMutation.mutate({ currentPassword, newPassword });
  }

  const activityItems = [
    ...(data?.loginActivity || []).map((item) => ({
      id: `login-${item.at}`,
      action: item.label || 'Signed in',
      module: 'Authentication',
      details: '',
      createdAt: item.at,
    })),
    ...(data?.activity || []),
    ...(data?.recentMovements || []).map((m) => ({
      id: m.id,
      action: `${m.type} movement`,
      module: 'Inventory',
      details: `${m.product?.sku || 'Product'} · ${m.warehouse?.name || 'Warehouse'} · qty ${m.quantity}`,
      createdAt: m.createdAt,
    })),
  ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

  const sectionLinks = [
    { id: 'overview', label: 'Overview', icon: LayoutGrid },
    { id: 'personal', label: 'Personal', icon: User },
    { id: 'security', label: 'Security', icon: KeyRound },
    { id: 'appearance', label: 'Appearance', icon: Palette },
    { id: 'activity', label: 'Activity', icon: Activity },
  ];

  if (isLoading && !profile) {
    return (
      <PageShell title="My Profile" subtitle="Manage your account, security, and workspace preferences.">
        <div className="text-muted-foreground">Loading profile…</div>
      </PageShell>
    );
  }

  if (isError && !profile) {
    return (
      <PageShell title="My Profile">
        <div className="text-red-600">Failed to load profile.</div>
      </PageShell>
    );
  }

  const displayUser = { ...profile, avatar: avatarPreview || profile.avatar };
  const statusLabel = getAccountStatusLabel(profile.status, profile.archived);
  const permissions = data?.permissions || [];

  return (
    <PageShell title="My Profile" subtitle="Manage your account, security, and workspace preferences.">
      {profile.forcePasswordChange ? (
        <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900 dark:border-amber-500/30 dark:bg-amber-500/10 dark:text-amber-200">
          Your administrator requires a password change before continuing. Update your password in the Security section below.
        </div>
      ) : null}

      <nav className="mb-4 flex flex-wrap gap-2">
        {sectionLinks.map(({ id, label, icon: Icon }) => (
          <a
            key={id}
            href={`#${id}`}
            className="inline-flex items-center gap-1.5 rounded-lg border border-border bg-card px-3 py-1.5 text-xs font-medium text-muted-foreground transition hover:border-accent/40 hover:text-foreground"
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </a>
        ))}
      </nav>

      <section id="overview" className="wms-stat-card overflow-hidden p-0 scroll-mt-24">
        <div className="border-b border-border px-6 py-4">
          <div className="flex items-center gap-2">
            <LayoutGrid className="h-4 w-4 text-accent" />
            <h3 className="text-sm font-semibold text-foreground">Profile overview</h3>
          </div>
        </div>
        <div className="border-b border-border bg-gradient-to-br from-accent/5 via-transparent to-transparent px-6 py-8 dark:from-accent/10">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-center">
            <div className="relative">
              <UserAvatar user={displayUser} size="xl" />
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                className="absolute bottom-0 right-0 flex h-8 w-8 items-center justify-center rounded-full border border-border bg-card text-foreground shadow-sm transition hover:bg-muted"
                aria-label="Upload profile photo"
              >
                <Camera className="h-4 w-4" />
              </button>
              <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={handleAvatarPick} />
            </div>
            <div className="min-w-0 flex-1">
              <h2 className="text-2xl font-semibold tracking-tight text-foreground">
                {profile.fullName || profile.username}
              </h2>
              <p className="text-sm text-muted-foreground">@{profile.username}</p>
              <div className="mt-3 flex flex-wrap items-center gap-2">
                {profile.role ? (
                  <span className={`wms-badge ${roleBadgeClass(profile.role)}`}>{profile.role}</span>
                ) : null}
                <span className={`wms-badge ${getAccountStatusClass(profile.status, profile.archived)}`}>
                  {statusLabel}
                </span>
              </div>
              <p className="mt-2 text-sm text-muted-foreground">{profile.email}</p>
              <div className="mt-3 flex flex-wrap gap-4 text-xs text-muted-foreground">
                <span>Last login: {formatWhen(profile.lastLoginAt)}</span>
                <span>Member since: {formatWhen(profile.createdAt)}</span>
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              {avatarPreview ? (
                <>
                  <Button size="sm" onClick={handleSaveAvatar} disabled={avatarMutation.isPending}>
                    Save photo
                  </Button>
                  <Button size="sm" variant="secondary" onClick={() => setAvatarPreview(null)}>
                    Cancel
                  </Button>
                </>
              ) : profile.avatar ? (
                <Button size="sm" variant="secondary" onClick={handleRemoveAvatar} disabled={avatarMutation.isPending}>
                  <Trash2 className="h-4 w-4" />
                  Remove photo
                </Button>
              ) : null}
            </div>
          </div>
          {avatarError ? <p className="mt-3 text-sm text-red-600">{avatarError}</p> : null}
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <section id="personal" className="wms-card p-6 scroll-mt-24">
            <div className="mb-5 flex items-center gap-2">
              <User className="h-4 w-4 text-accent" />
              <h3 className="text-sm font-semibold text-foreground">Personal information</h3>
            </div>
            <form onSubmit={handleSaveProfile} className="grid gap-4 sm:grid-cols-2">
              <Field label="Full name">
                <Input value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Your display name" />
              </Field>
              <Field label="Username">
                <Input value={username} onChange={(e) => setUsername(e.target.value)} required />
              </Field>
              <Field label="Email">
                <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
              </Field>
              <Field label="Phone">
                <Input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+1 555 0100" />
              </Field>
              <div className="sm:col-span-2 flex flex-wrap items-center gap-3">
                <Button type="submit" disabled={updateProfileMutation.isPending}>
                  Save changes
                </Button>
                {profileSaved ? <span className="text-sm text-emerald-600 dark:text-emerald-400">{profileSaved}</span> : null}
                {profileError ? <span className="text-sm text-red-600">{profileError}</span> : null}
              </div>
            </form>
          </section>

          <section id="security" className="wms-card p-6 scroll-mt-24">
            <div className="mb-5 flex items-center gap-2">
              <KeyRound className="h-4 w-4 text-accent" />
              <h3 className="text-sm font-semibold text-foreground">Account security</h3>
            </div>
            <form onSubmit={handleChangePassword} className="max-w-md space-y-4">
              <Field label="Current password">
                <div className="relative">
                  <Input
                    type={showCurrent ? 'text' : 'password'}
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    required
                  />
                  <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" onClick={() => setShowCurrent((v) => !v)}>
                    {showCurrent ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </Field>
              <Field label="New password">
                <div className="relative">
                  <Input
                    type={showNew ? 'text' : 'password'}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    required
                    minLength={8}
                  />
                  <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" onClick={() => setShowNew((v) => !v)}>
                    {showNew ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
                <PasswordStrength password={newPassword} />
              </Field>
              <Field label="Confirm new password">
                <Input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  minLength={8}
                />
              </Field>
              <div className="rounded-lg border border-dashed border-border bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
                Future-ready: two-factor authentication and active session management will appear here.
              </div>
              <div className="flex flex-wrap items-center gap-3">
                <Button type="submit" disabled={passwordMutation.isPending}>
                  Update password
                </Button>
                {passwordSaved ? <span className="text-sm text-emerald-600 dark:text-emerald-400">{passwordSaved}</span> : null}
                {passwordError ? <span className="text-sm text-red-600">{passwordError}</span> : null}
              </div>
            </form>
          </section>

          <section id="appearance" className="wms-card p-6 scroll-mt-24">
            <div className="mb-2 flex items-center gap-2">
              <Palette className="h-4 w-4 text-accent" />
              <h3 className="text-sm font-semibold text-foreground">Appearance preferences</h3>
            </div>
            <p className="mb-5 text-xs text-muted-foreground">
              Connected to your workspace appearance settings. Changes here apply globally and are saved to your account.
            </p>
            <AppearanceSettingsSection />
          </section>
        </div>

        <div className="space-y-6">
          <section className="wms-card p-6">
            <div className="mb-4 flex items-center gap-2">
              <Shield className="h-4 w-4 text-accent" />
              <h3 className="text-sm font-semibold text-foreground">Account information</h3>
            </div>
            <dl className="space-y-3 text-sm">
              <div>
                <dt className="text-muted-foreground">Role</dt>
                <dd className="mt-0.5 font-medium text-foreground">{profile.role}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Last active</dt>
                <dd className="mt-0.5 font-medium text-foreground">{formatWhen(profile.lastActiveAt)}</dd>
              </div>
              <div>
                <dt className="text-muted-foreground">Assigned warehouse</dt>
                <dd className="mt-0.5 font-medium text-foreground">
                  {data?.assigned_warehouses?.scope === 'all'
                    ? 'All warehouses'
                    : data?.assigned_warehouses?.warehouses?.length
                      ? data.assigned_warehouses.warehouses.map((w) => w.name).join(', ')
                      : profile.role === 'Staff'
                        ? 'Not assigned'
                        : 'All sites'}
                </dd>
              </div>
            </dl>
            <ul className="mt-4 space-y-1.5 border-t border-border pt-4">
              {permissions.map((item) => (
                <li key={item} className="text-xs text-muted-foreground">
                  • {item}
                </li>
              ))}
            </ul>
          </section>

          <section id="activity" className="wms-card p-6 scroll-mt-24">
            <div className="mb-4 flex items-center gap-2">
              <Activity className="h-4 w-4 text-accent" />
              <h3 className="text-sm font-semibold text-foreground">Recent activity</h3>
            </div>
            <div className="max-h-72 space-y-3 overflow-y-auto">
              {activityItems.length === 0 ? (
                <p className="text-sm text-muted-foreground">No recent activity recorded yet.</p>
              ) : (
                activityItems.slice(0, 12).map((item) => (
                  <div key={item.id} className="rounded-lg border border-border/70 bg-background/50 px-3 py-2">
                    <p className="text-sm font-medium text-foreground">{item.action}</p>
                    <p className="text-xs text-muted-foreground">
                      {item.module}{item.details ? ` · ${item.details}` : ''}
                    </p>
                    <p className="mt-1 text-[10px] text-muted-foreground">{formatWhen(item.createdAt)}</p>
                  </div>
                ))
              )}
            </div>
            <Link to="/stock-movements" className="mt-4 inline-block text-xs font-medium text-accent hover:underline">
              View stock movements
            </Link>
          </section>

          <section className="wms-card p-6">
            <Button
              variant="secondary"
              className="w-full"
              onClick={() => {
                logout();
                navigate('/login', { replace: true });
              }}
            >
              <LogOut className="h-4 w-4" />
              Sign out
            </Button>
          </section>
        </div>
      </div>
    </PageShell>
  );
}
