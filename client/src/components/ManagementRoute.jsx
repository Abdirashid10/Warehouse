import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

/** Blocks Staff from management-only pages (Admin/Supervisor only). */
export function ManagementRoute({ children }) {
  const { user, ready, isAuthenticated } = useAuth();

  if (!ready) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-muted-foreground">
        Loading…
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (user?.role === 'Staff') {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
