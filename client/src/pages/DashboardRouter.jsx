import { useAuth } from '../context/AuthContext';
import { Dashboard } from './Dashboard';
import { StaffDashboard } from './StaffDashboard';

export function DashboardRouter() {
  const { user } = useAuth();

  if (user?.role === 'Staff') {
    return <StaffDashboard />;
  }

  return <Dashboard />;
}
