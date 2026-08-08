import {
  Activity,
  ArrowRightLeft,
  Boxes,
  ClipboardList,
  FileBarChart,
  LayoutDashboard,
  Package,
  ShieldAlert,
  ShoppingCart,
  UserCircle,
  Users,
  Warehouse,
} from 'lucide-react';
import { canAccessReports } from '../utils/roles';

export const MANAGEMENT_NAV = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/products', label: 'Products', icon: Boxes },
  { to: '/inventory-tracking', label: 'Inventory Tracking', icon: Package },
  { to: '/stock-movements', label: 'Stock Movements', icon: ArrowRightLeft },
  { to: '/warehouses', label: 'Warehouses', icon: Warehouse },
  { to: '/expiry-management', label: 'Expiry & Risk', icon: ShieldAlert, reportsOnly: true },
  { to: '/orders', label: 'Orders', icon: ShoppingCart },
  { to: '/tasks', label: 'Tasks', icon: ClipboardList },
  { to: '/reports', label: 'Reports', icon: FileBarChart, reportsOnly: true },
  { to: '/audit-logs', label: 'Audit & Activity Logs', icon: Activity, reportsOnly: true },
  { to: '/users', label: 'Users', icon: Users, adminOnly: true },
];

export const STAFF_NAV = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/tasks', label: 'My Tasks', icon: ClipboardList },
  { to: '/staff/inventory', label: 'Inventory', icon: Package },
  { to: '/stock-movements', label: 'Stock Operations', icon: ArrowRightLeft },
  { to: '/staff/orders', label: 'My Orders', icon: ShoppingCart },
];

export const ACCOUNT_NAV = [{ to: '/profile', label: 'Profile', icon: UserCircle }];

export function getNavItems(user) {
  if (user?.role === 'Staff') return STAFF_NAV;

  return MANAGEMENT_NAV.filter((item) => {
    if (item.adminOnly && user?.role !== 'Admin') return false;
    if (item.reportsOnly && !canAccessReports(user?.role)) return false;
    return true;
  });
}

export function filterNavForRole(items, role) {
  return items.filter((item) => {
    if (item.adminOnly && role !== 'Admin') return false;
    if (item.reportsOnly && !canAccessReports(role)) return false;
    return true;
  });
}
