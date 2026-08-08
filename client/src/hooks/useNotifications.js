import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';

export const NOTIFICATIONS_KEY = ['notifications'];

export function notificationsQueryKey(filters = {}) {
  return [...NOTIFICATIONS_KEY, filters];
}

export async function fetchNotifications(params = {}) {
  const { data } = await api.get('/notifications', { params });
  return data;
}

export async function fetchUnreadCount() {
  const { data } = await api.get('/notifications/unread-count');
  return data;
}

export function useUnreadCount() {
  return useQuery({
    queryKey: [...NOTIFICATIONS_KEY, 'unread-count'],
    queryFn: fetchUnreadCount,
    staleTime: 5_000,
  });
}

export function useNotifications(filters = {}, options = {}) {
  return useQuery({
    queryKey: notificationsQueryKey(filters),
    queryFn: () => fetchNotifications(filters),
    staleTime: 10_000,
    ...options,
  });
}

export function useNotificationMutations() {
  const queryClient = useQueryClient();

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_KEY });
  };

  const markRead = useMutation({
    mutationFn: (id) => api.patch(`/notifications/${id}/read`),
    onSuccess: invalidate,
  });

  const markAllRead = useMutation({
    mutationFn: () => api.patch('/notifications/read-all'),
    onSuccess: invalidate,
  });

  const remove = useMutation({
    mutationFn: (id) => api.delete(`/notifications/${id}`),
    onSuccess: invalidate,
  });

  const clearRead = useMutation({
    mutationFn: () => api.delete('/notifications/clear-read'),
    onSuccess: invalidate,
  });

  return { markRead, markAllRead, remove, clearRead, invalidate };
}
