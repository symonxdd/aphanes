'use client';

import { Monitor, Smartphone } from 'lucide-react';
import { Section } from './Section';
import { useLatestRelease } from '@/hooks/useLatestRelease';

const RELEASES_PAGE = 'https://github.com/symonxdd/aphanes/releases';

/// The two apps side by side, each with its own download. The Windows
/// card links to the releases page until a desktop release exists, so it
/// is never a dead button.
export function Platforms() {
  const { android, windows } = useLatestRelease();

  const apps = [
    {
      icon: Smartphone,
      name: 'Android',
      body:
        'The one that started it, built for a phone first: nothing sits under a system bar, on any screen, in any orientation.',
      version: android.version,
      size: android.size,
      href: android.downloadUrl,
      label: 'Download for Android',
    },
    {
      icon: Monitor,
      name: 'Windows',
      body:
        'The same app at a desk: paired TVs in a sidebar, and each installed package’s full description. Updates are one click away in Settings: it never checks on its own, and nothing installs without a click.',
      version: windows?.version ?? null,
      size: windows?.size ?? null,
      href: windows?.downloadUrl ?? RELEASES_PAGE,
      label: 'Download for Windows',
    },
  ];

  return (
    <Section
      id="downloads"
      eyebrow="Two apps"
      title="On the phone, or at the desk."
      lead="Same TVs, same pairing, same catalog. Pick whichever is closer to hand, or both: each keeps its own paired TVs, and neither needs the other."
    >
      <div className="grid gap-6 md:grid-cols-2">
        {apps.map(({ icon: Icon, name, body, version, size, href, label }) => (
          <div
            key={name}
            className="flex flex-col rounded-2xl border border-foreground/10 p-6"
          >
            <div className="flex items-center gap-3">
              <Icon className="h-5 w-5 text-accent" strokeWidth={1.75} />
              <h3 className="font-medium">{name}</h3>
              {version && (
                <span className="ml-auto text-xs tabular-nums text-muted-foreground">
                  {version}
                  {size ? ` · ${size} MB` : ''}
                </span>
              )}
            </div>
            <p className="mt-4 flex-1 text-sm leading-relaxed text-muted-foreground">
              {body}
            </p>
            <a
              href={href}
              className="mt-6 inline-flex items-center self-start rounded-xl bg-foreground px-4 py-2.5 text-sm font-medium text-background transition-opacity hover:opacity-90"
            >
              {label}
            </a>
          </div>
        ))}
      </div>

      {/* Said plainly for the visitor on an iPhone, a Mac or Linux, who
          would otherwise be left guessing whether a version is on the
          way. */}
      <p className="mt-8 max-w-2xl text-sm leading-relaxed text-muted-foreground">
        No iOS, macOS or Linux version yet. All three are possible; what
        they need is someone with an iPhone, a Mac or a Linux machine to
        test each release properly on real hardware. Anyone happy to help
        with that is welcome to{' '}
        <a
          href="https://github.com/symonxdd/aphanes/issues"
          className="text-accent underline decoration-accent/30 underline-offset-4 hover:decoration-accent"
        >
          get in touch through the project’s issues
        </a>
        .
      </p>
    </Section>
  );
}
