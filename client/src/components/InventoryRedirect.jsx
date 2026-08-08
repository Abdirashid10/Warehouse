import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export function InventoryRedirect() {
  const { user } = useAuth();
  return (
    <Navigate
      to={user?.role === 'Staff' ? '/staff/inventory' : '/inventory-tracking'}
      replace
    />
  );
}
