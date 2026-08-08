import { useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { useAppearance } from '../../context/AppearanceContext';

/** Hydrates appearance settings from the authenticated user profile. */
export function SyncProfilePreferences() {
  const { user, isAuthenticated, refreshProfile } = useAuth();
  const { hydrateFromServer } = useAppearance();

  useEffect(() => {
    if (!isAuthenticated) return;
    if (user?.preferences) {
      hydrateFromServer(user.preferences);
      return;
    }
    refreshProfile().then((data) => {
      if (data?.profile?.preferences) hydrateFromServer(data.profile.preferences);
    }).catch(() => {});
  }, [isAuthenticated, user?.id]);

  return null;
}
