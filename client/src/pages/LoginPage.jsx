import { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { api } from '../api/client';
import { Package, ShieldPlus } from 'lucide-react';

export function LoginPage() {
  const { login, bootstrapFirstAdmin, isAuthenticated } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from || '/dashboard';

  const [canBootstrap, setCanBootstrap] = useState(false);
  const [statusLoaded, setStatusLoaded] = useState(false);

  useEffect(() => {
    if (isAuthenticated) {
      navigate(from, { replace: true });
    }
  }, [isAuthenticated, from, navigate]);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data } = await api.get('/auth/bootstrap-status');
        if (!cancelled) {
          setCanBootstrap(Boolean(data?.canBootstrap));
        }
      } catch {
        if (!cancelled) setCanBootstrap(false);
      } finally {
        if (!cancelled) setStatusLoaded(true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const [bUser, setBUser] = useState('');
  const [bEmail, setBEmail] = useState('');
  const [bPass, setBPass] = useState('');
  const [bError, setBError] = useState('');
  const [bLoading, setBLoading] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email.trim(), password);
      navigate(from, { replace: true });
    } catch (err) {
      let msg =
        err.response?.data?.message ||
        err.message ||
        'Unable to sign in. Please check your credentials and try again.';
      if (
        msg === 'Invalid credentials' &&
        canBootstrap &&
        statusLoaded
      ) {
        msg =
          'Unable to sign in. If this is a new installation, complete initial setup below, then try again.';
      } else if (msg === 'Invalid credentials') {
        msg = 'Email or password is incorrect. Please try again.';
      }
      setError(msg);
    } finally {
      setLoading(false);
    }
  }

  async function handleBootstrap(e) {
    e.preventDefault();
    setBError('');
    setBLoading(true);
    try {
      await bootstrapFirstAdmin({
        username: bUser.trim(),
        email: bEmail.trim(),
        password: bPass,
      });
      setCanBootstrap(false);
      navigate(from, { replace: true });
    } catch (err) {
      setBError(
        err.response?.data?.message ||
          err.message ||
          'Setup could not be completed. Please try again or contact your system administrator.'
      );
    } finally {
      setBLoading(false);
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-background px-4 py-8 sm:py-12">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgb(var(--accent)/0.1),transparent_60%)]" />

      <div className="relative w-full max-w-[420px] space-y-6">
        {canBootstrap && statusLoaded ? (
          <div className="wms-card border-accent/25 p-6 sm:p-7">
            <div className="flex items-center gap-2.5 text-accent">
              <ShieldPlus className="h-5 w-5 shrink-0" aria-hidden />
              <h2 className="text-base font-semibold text-foreground">Initial setup</h2>
            </div>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              Create your administrator account to get started, then sign in with that email and
              password.
            </p>
            <form onSubmit={handleBootstrap} className="mt-5 space-y-4">
              <label className="block space-y-1.5 text-sm font-medium text-foreground">
                Username
                <input
                  required
                  minLength={2}
                  value={bUser}
                  onChange={(e) => setBUser(e.target.value)}
                  className="wms-input"
                  placeholder="admin"
                  autoComplete="username"
                />
              </label>
              <label className="block space-y-1.5 text-sm font-medium text-foreground">
                Email
                <input
                  type="email"
                  required
                  value={bEmail}
                  onChange={(e) => setBEmail(e.target.value)}
                  className="wms-input"
                  placeholder="admin@company.com"
                  autoComplete="email"
                />
              </label>
              <label className="block space-y-1.5 text-sm font-medium text-foreground">
                Password
                <input
                  type="password"
                  required
                  minLength={8}
                  value={bPass}
                  onChange={(e) => setBPass(e.target.value)}
                  className="wms-input"
                  placeholder="Minimum 8 characters"
                  autoComplete="new-password"
                />
              </label>
              {bError ? (
                <p
                  role="alert"
                  className="rounded-lg border border-red-900/50 bg-red-950/40 px-3 py-2.5 text-sm text-red-300"
                >
                  {bError}
                </p>
              ) : null}
              <button
                type="submit"
                disabled={bLoading}
                className="wms-btn-primary w-full py-2.5"
              >
                {bLoading ? 'Creating account…' : 'Create administrator account'}
              </button>
            </form>
          </div>
        ) : null}

        <div className="wms-card border-border/80 p-8 shadow-soft sm:p-10">
          <div className="mb-8 flex flex-col items-center text-center">
            <div
              className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-accent text-white shadow-glow"
              aria-hidden
            >
              <Package className="h-8 w-8" />
            </div>
            <h1 className="text-2xl font-semibold tracking-tight text-foreground">
              Logistics WMS
            </h1>
            <p className="mt-1.5 text-sm text-muted-foreground">Sign in to continue</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <label className="block space-y-1.5 text-sm font-medium text-foreground">
              Email
              <input
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="wms-input"
                placeholder="you@company.com"
              />
            </label>

            <label className="block space-y-1.5 text-sm font-medium text-foreground">
              Password
              <input
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="wms-input"
              />
            </label>

            {error ? (
              <p
                role="alert"
                className="rounded-lg border border-red-900/50 bg-red-950/40 px-3 py-2.5 text-sm text-red-300"
              >
                {error}
              </p>
            ) : null}

            <button
              type="submit"
              disabled={loading}
              className="wms-btn-primary w-full py-2.5"
            >
              {loading ? 'Signing in…' : 'Sign in'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
