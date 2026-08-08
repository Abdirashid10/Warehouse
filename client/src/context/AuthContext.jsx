import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { api } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const storedToken = localStorage.getItem('token');
    const storedUser = localStorage.getItem('user');
    if (storedToken && storedUser) {
      setToken(storedToken);
      try {
        setUser(JSON.parse(storedUser));
      } catch {
        localStorage.removeItem('user');
        localStorage.removeItem('token');
      }
    }
    setReady(true);
  }, []);

  const applySession = useCallback((data) => {
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    setToken(data.token);
    setUser(data.user);
  }, []);

  const updateUser = useCallback((nextUser) => {
    setUser((prev) => {
      const merged = { ...prev, ...nextUser };
      localStorage.setItem('user', JSON.stringify(merged));
      return merged;
    });
  }, []);

  const refreshProfile = useCallback(async () => {
    const { data } = await api.get('/profile/me');
    if (data?.profile) updateUser(data.profile);
    return data;
  }, [updateUser]);

  const login = useCallback(
    async (email, password) => {
      const { data } = await api.post('/auth/login', { email, password });
      applySession(data);
      return data;
    },
    [applySession]
  );

  const bootstrapFirstAdmin = useCallback(
    async (payload) => {
      const { data } = await api.post('/auth/bootstrap', payload);
      applySession(data);
      return data;
    },
    [applySession]
  );

  const logout = useCallback(() => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({
      user,
      token,
      ready,
      isAuthenticated: Boolean(token),
      login,
      bootstrapFirstAdmin,
      logout,
      updateUser,
      refreshProfile,
    }),
    [user, token, ready, login, bootstrapFirstAdmin, logout, updateUser, refreshProfile]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return ctx;
}
