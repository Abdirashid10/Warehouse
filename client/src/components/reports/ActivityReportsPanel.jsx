import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { Activity, AlertCircle, Bell, ChevronRight, Loader2 } from 'lucide-react';
import { api } from '../../api/client';
import { useAuth } from '../../context/AuthContext';
import { NotificationCard } from '../notifications/NotificationCard';

const RECENT_LIMIT = 5;

async function fetchRecentNotifications(isAdmin) {
  const endpoint = isAdmin ? '/notifications/admin' : '/notifications/recent';
  const { data } = await api.get(endpoint, { params: { limit: RECENT_LIMIT } });
  return data;
}

async function fetchRecentAudit() {
  const { data } = await api.get('/audit/recent', { params: { limit: RECENT_LIMIT } });
  return data;
}

function relDate(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function WidgetState({ loading, error, onRetry, emptyMessage, children }) {
  if (loading) {
    return (
      <div className="flex items-center gap-2 py-6 text-muted-foreground">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span className="text-xs">Loading…</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center gap-2 py-6 text-center">
        <AlertCircle className="h-4 w-4 text-red-500" />
        <p className="text-xs text-red-600 dark:text-red-400">
          {error?.response?.data?.message || 'Could not load data.'}
        </p>
        {onRetry && (
          <button
            type="button"
            onClick={onRetry}
            className="text-[11px] font-medium text-accent hover:underline"
          >
            Retry
          </button>
        )}
      </div>
    );
  }

  if (!children) {
    return <p className="py-6 text-center text-xs text-muted-foreground">{emptyMessage}</p>;
  }

  return children;
}

export function ActivityReportsPanel() {
  const { user, ready, isAuthenticated } = useAuth();
  const queryEnabled = ready && isAuthenticated;
  const isAdmin = user?.role === 'Admin';

  const {
    data: notifData,
    isLoading: notifLoading,
    isError: notifError,
    error: notifErr,
    refetch: refetchNotifications,
  } = useQuery({
    queryKey: ['notifications', 'recent', isAdmin ? 'admin' : 'user'],
    queryFn: () => fetchRecentNotifications(isAdmin),
    enabled: queryEnabled,
    staleTime: 30_000,
  });

  const {
    data: auditData,
    isLoading: auditLoading,
    isError: auditError,
    error: auditErr,
    refetch: refetchAudit,
  } = useQuery({
    queryKey: ['audit', 'recent'],
    queryFn: fetchRecentAudit,
    enabled: queryEnabled,
    staleTime: 30_000,
  });

  const notifications = (notifData?.notifications || []).slice(0, RECENT_LIMIT);
  const activities = (auditData?.activities || []).slice(0, RECENT_LIMIT);

  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <div className="dash-section">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Bell className="h-3.5 w-3.5 text-sky-500" />
            <p className="dash-section__title">Recent notifications</p>
          </div>
          <Link to="/notifications" className="flex items-center gap-0.5 text-[11px] font-medium text-accent hover:underline">
            View all <ChevronRight className="h-3 w-3" />
          </Link>
        </div>
        <WidgetState
          loading={notifLoading}
          error={notifError ? notifErr : null}
          onRetry={() => refetchNotifications()}
          emptyMessage="No notifications yet"
        >
          {notifications.length > 0 ? (
            <div className="space-y-1.5">
              {notifications.map((n) => (
                <NotificationCard key={n.id} notification={n} compact />
              ))}
            </div>
          ) : null}
        </WidgetState>
      </div>

      <div className="dash-section">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Activity className="h-3.5 w-3.5 text-violet-500" />
            <p className="dash-section__title">Recent audit activity</p>
          </div>
          <Link to="/audit-logs" className="flex items-center gap-0.5 text-[11px] font-medium text-accent hover:underline">
            View all <ChevronRight className="h-3 w-3" />
          </Link>
        </div>
        <WidgetState
          loading={auditLoading}
          error={auditError ? auditErr : null}
          onRetry={() => refetchAudit()}
          emptyMessage="No audit entries yet"
        >
          {activities.length > 0 ? (
            <div className="space-y-1">
              {activities.map((a) => (
                <div key={a.id} className="flex items-start gap-2 rounded-md border border-border/40 px-2.5 py-2 text-xs">
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-foreground">{a.action}</p>
                    <p className="text-[10px] text-muted-foreground truncate">{a.details || a.entityLabel || a.module}</p>
                    <p className="mt-0.5 text-[9px] text-muted-foreground/70">
                      {a.actor?.fullName || a.actor?.username || 'System'} · {a.actorRole || a.actor?.role || '—'}
                    </p>
                  </div>
                  <span className="shrink-0 text-[9px] text-muted-foreground whitespace-nowrap">{relDate(a.createdAt)}</span>
                </div>
              ))}
            </div>
          ) : null}
        </WidgetState>
      </div>
    </div>
  );
}
