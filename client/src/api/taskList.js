import { api } from './client';

/**
 * Load tasks for the current user (Staff: assigned only; Admin/Supervisor: all).
 * Normalizes response so downstream code always receives an array.
 */
export async function fetchTaskList() {
  const { data } = await api.get('/tasks');
  return {
    tasks: Array.isArray(data?.tasks) ? data.tasks : [],
    scope: data?.scope ?? 'all',
  };
}
