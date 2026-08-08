import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { canAccessReports } from '../utils/roles';

export function NonStaffRoute({ children }) {
  const { user, ready, isAuthenticated } = useAuth();

  if (!ready) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-slate-400">
        Loading…
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (!canAccessReports(user?.role)) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
