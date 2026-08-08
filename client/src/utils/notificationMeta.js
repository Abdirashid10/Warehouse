import {
  AlertTriangle,
  ArrowRightLeft,
  Bell,
  Boxes,
  CheckCircle2,
  ClipboardList,
  Info,
  ShoppingCart,
  User,
  Warehouse,
  XCircle,
} from 'lucide-react';

export function getNotificationIcon(category, type) {
  if (category === 'task') return ClipboardList;
  if (category === 'order') return ShoppingCart;
  if (category === 'inventory') return Boxes;
  if (category === 'warehouse') return Warehouse;
  if (category === 'user') return User;
  if (type === 'success') return CheckCircle2;
  if (type === 'warning') return AlertTriangle;
  if (type === 'error') return XCircle;
  if (category === 'system') return Bell;
  return type === 'error' ? XCircle : type === 'warning' ? AlertTriangle : Info;
}

export function getNotificationTone(type) {
  if (type === 'success') return 'success';
  if (type === 'warning') return 'warning';
  if (type === 'error') return 'danger';
  if (type === 'info') return 'accent';
  return 'default';
}

export const NOTIFICATION_CATEGORIES = [
  { value: '', label: 'All categories' },
  { value: 'task', label: 'Tasks' },
  { value: 'order', label: 'Orders' },
  { value: 'inventory', label: 'Inventory' },
  { value: 'warehouse', label: 'Warehouses' },
  { value: 'user', label: 'Users' },
  { value: 'system', label: 'System' },
];

export function movementIcon() {
  return ArrowRightLeft;
}
