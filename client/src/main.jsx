import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './context/AuthContext';
import { NotificationSocketProvider } from './context/NotificationSocketContext';
import { AppearanceProvider } from './context/AppearanceContext';
import App from './App.jsx';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1,
    },
  },
});

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AppearanceProvider>
        <AuthProvider>
          <NotificationSocketProvider>
            <App />
          </NotificationSocketProvider>
        </AuthProvider>
      </AppearanceProvider>
    </QueryClientProvider>
  </StrictMode>
);
