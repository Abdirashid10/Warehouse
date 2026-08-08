export function PasswordStrength({ password = '' }) {
  const value = String(password);
  let score = 0;
  if (value.length >= 8) score += 1;
  if (value.length >= 12) score += 1;
  if (/[A-Z]/.test(value) && /[a-z]/.test(value)) score += 1;
  if (/\d/.test(value)) score += 1;
  if (/[^A-Za-z0-9]/.test(value)) score += 1;

  const level = value.length === 0 ? 0 : Math.min(4, Math.max(1, score));
  const labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
  const colors = ['bg-muted', 'bg-red-500', 'bg-amber-500', 'bg-sky-500', 'bg-emerald-500'];

  return (
    <div className="space-y-1.5">
      <div className="flex gap-1">
        {[1, 2, 3, 4].map((step) => (
          <div
            key={step}
            className={`h-1 flex-1 rounded-full transition-colors ${
              level >= step ? colors[level] : 'bg-muted'
            }`}
          />
        ))}
      </div>
      <p className="text-xs text-muted-foreground">
        {value.length === 0 ? 'Use at least 8 characters' : `Strength: ${labels[level]}`}
      </p>
    </div>
  );
}
