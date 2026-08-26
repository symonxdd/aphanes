'use client';

import { useEffect, useState } from 'react';
import { Moon, Sun } from 'lucide-react';
import { useTheme } from 'next-themes';

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // The server has no idea which theme the browser will resolve to, so
  // rendering an icon before mount would guarantee a hydration mismatch.
  // A same-sized blank holds the layout until then.
  useEffect(() => setMounted(true), []);

  if (!mounted) {
    return <div className="w-9 h-9" aria-hidden />;
  }

  const isDark = resolvedTheme === 'dark';

  return (
    <button
      onClick={() => setTheme(isDark ? 'light' : 'dark')}
      className="w-9 h-9 flex items-center justify-center rounded-lg text-muted-foreground hover:text-foreground hover:bg-foreground/5 transition-colors"
      aria-label={isDark ? 'Switch to light theme' : 'Switch to dark theme'}
    >
      {isDark ? <Moon size={18} /> : <Sun size={18} />}
    </button>
  );
}
