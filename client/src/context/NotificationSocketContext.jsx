import { createContext, useCallback, useContext, useEffect, useRef } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { io } from 'socket.io-client';
import { useAuth } from './AuthContext';
import { NOTIFICATIONS_KEY } from '../hooks/useNotifications';

const NotificationSocketContext = createContext(null);

function socketBaseUrl() {
  const apiBase = import.meta.env.VITE_API_BASE_URL;
  if (apiBase && apiBase !== '/api') {
    return apiBase.replace(/\/api\/?$/, '');
  }
  return window.location.origin;
}

export function NotificationSocketProvider({ children }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const socketRef = useRef(null);

  const patchUnread = useCallback(
    (unreadCount) => {
      queryClient.setQueryData([...NOTIFICATIONS_KEY, 'unread-count'], { unreadCount });
    },
    [queryClient]
  );

  const invalidateNotifications = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: NOTIFICATIONS_KEY });
  }, [queryClient]);

  const invalidateInventory = useCallback(() => {
    queryClient.invalidateQueries({ queryKey: ['inventory'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
    queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
    queryClient.invalidateQueries({ queryKey: ['reports'] });
  }, [queryClient]);

  useEffect(() => {
    if (!token) {
      if (socketRef.current) {
        socketRef.current.disconnect();
        socketRef.current = null;
      }
      return undefined;
    }

    const socket = io(socketBaseUrl(), {
      path: '/socket.io',
      auth: { token },
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 10,
    });

    socketRef.current = socket;

    socket.on('notifications:unread', ({ unreadCount }) => {
      patchUnread(unreadCount);
    });

    socket.on('notification:new', () => {
      invalidateNotifications();
    });

    socket.on('notification:read', ({ unreadCount }) => {
      if (typeof unreadCount === 'number') patchUnread(unreadCount);
      invalidateNotifications();
    });

    socket.on('notifications:all-read', ({ unreadCount }) => {
      patchUnread(unreadCount ?? 0);
      invalidateNotifications();
    });

    socket.on('notification:deleted', ({ unreadCount }) => {
      if (typeof unreadCount === 'number') patchUnread(unreadCount);
      invalidateNotifications();
    });

    const invalidateAudit = () => {
      queryClient.invalidateQueries({ queryKey: ['audit', 'recent'] });
    };

    socket.on('inventory:changed', () => {
      invalidateInventory();
      invalidateAudit();
    });

    socket.on('task:changed', () => {
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
      queryClient.invalidateQueries({ queryKey: ['tasks'] });
      invalidateAudit();
    });

    socket.on('order:changed', () => {
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'stats'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard', 'widgets'] });
      queryClient.invalidateQueries({ queryKey: ['orders'] });
      invalidateAudit();
    });

    return () => {
      socket.disconnect();
      socketRef.current = null;
    };
  }, [token, patchUnread, invalidateNotifications, invalidateInventory]);

  return (
    <NotificationSocketContext.Provider value={{ connected: Boolean(socketRef.current) }}>
      {children}
    </NotificationSocketContext.Provider>
  );
}

export function useNotificationSocket() {
  return useContext(NotificationSocketContext);
}
