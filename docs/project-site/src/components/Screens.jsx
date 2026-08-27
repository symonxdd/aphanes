'use client';

import Image from 'next/image';
import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';
import { Section } from './Section';
import { useDragScroll } from '@/hooks/useDragScroll';

// Served from public/screens, which scripts/sync-screenshots.mjs copies
// out of /docs/screenshots before every dev run and build. The README and
// this site therefore always show the same files.
const SHOT_SIZE = { width: 1080, height: 2340 };

// Two screens were captured in both themes, and those follow the site's
// theme. The rest are shown as taken.
//
// Where a dark one is showing, its caption says so: the app ships light,
// dark and a true-black OLED theme, and these are the OLED one rather
// than ordinary dark. Without saying it, a reader would assume the site
// had simply tinted the screenshots.
const SHOTS = [
  { src: 'main-screen', dark: 'main-screen-oled', caption: 'Paired TVs, with live reachability' },
  { src: 'device-detail-screen', caption: 'What the TV says about itself' },
  { src: 'apps-screen', caption: 'Installed apps' },
  { src: 'homebrew-catalog-list', caption: 'The Homebrew catalog' },
  { src: 'install-an-app-sheet', caption: 'Two ways to install' },
  { src: 'pair-a-device-screen', caption: 'Pairing' },
  { src: 'ip-address-explainer-sheet', caption: 'Every field explains itself' },
  { src: 'onboarding', dark: 'onboarding-dark-oled', caption: 'First run' },
  { src: 'settings-screen', caption: 'Settings' },
  { src: 'about-screen', caption: 'About' },
  {
    src: 'cinematic-splashscreen',
    // The word itself, on the screen that hides. `alt` stays plain: a
    // screen reader announcing "aphanes" describes nothing, and `lang`
    // is what stops it being read with English pronunciation rules.
    caption: 'ἀφανής',
    lang: 'grc',
    alt: 'The full screen title card, hidden behind the app icon',
  },
];

export function Screens() {
  const { resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const { ref: strip, handlers } = useDragScroll();

  // Same reasoning as the theme toggle: the server cannot know which
  // variant to serve, so the light one renders until the theme resolves.
  useEffect(() => setMounted(true), []);
  const dark = mounted && resolvedTheme === 'dark';

  return (
    <Section
      id="screens"
      eyebrow="Screens"
      title="Nothing hides under a system bar."
      lead="Every screen respects the status bar, the navigation bar and display cutouts. That was the whole point. Switch this site between light and dark and a couple of them follow, showing the app's true-black OLED theme."
    >
      <div
        ref={strip}
        {...handlers}
        className="scroll-slim -mx-6 cursor-grab overflow-x-auto px-6 pb-4 select-none active:cursor-grabbing"
      >
        <ul className="flex gap-5">
          {SHOTS.map(({ src, dark: darkSrc, caption, lang, alt }) => (
            <li key={src} className="w-[190px] shrink-0 sm:w-[220px]">
              <div className="overflow-hidden rounded-2xl border border-foreground/10 bg-foreground/[0.02]">
                <Image
                  src={`/screens/${dark && darkSrc ? darkSrc : src}.jpg`}
                  alt={alt ?? caption}
                  {...SHOT_SIZE}
                  draggable={false}
                  sizes="220px"
                  className="h-auto w-full"
                />
              </div>
              <p className="mt-3 text-sm text-muted-foreground" lang={lang}>
                {caption}
                {dark && darkSrc && (
                  <span className="text-muted-foreground/60">
                    {' '}
                    · OLED theme
                  </span>
                )}
              </p>
            </li>
          ))}
        </ul>
      </div>
      <p className="mt-2 text-xs text-muted-foreground/70">
        Drag sideways for the rest.
      </p>
    </Section>
  );
}
