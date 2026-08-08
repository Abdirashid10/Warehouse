import { useCallback } from 'react';
import { useMutation } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { useAppearance } from '../context/AppearanceContext';

export function usePersistAppearance() {
  const { updateUser } = useAuth();
  const { updateSetting, resetSettings } = useAppearance();

  const mutation = useMutation({
    mutationFn: (preferences) => api.patch('/profile/preferences', { preferences }).then((r) => r.data),
    onSuccess: (payload) => {
      if (payload.profile) updateUser(payload.profile);
    },
  });

  const updateAndPersist = useCallback(
    (key, value) => {
      const next = updateSetting(key, value);
      if (next) mutation.mutate(next);
    },
    [updateSetting, mutation]
  );

  const resetAndPersist = useCallback(() => {
    const next = resetSettings();
    if (next) mutation.mutate(next);
  }, [resetSettings, mutation]);

  return {
    updateAndPersist,
    resetAndPersist,
    isSaving: mutation.isPending,
  };
}
