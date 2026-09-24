'use client';

import { KeyRound, PackagePlus, Tv, Timer, WifiOff, ShieldCheck } from 'lucide-react';
import { Section } from './Section';
import { Glossary } from './Glossary';

const FEATURES = [
  {
    icon: KeyRound,
    title: 'Pair once',
    body:
      'Six characters from the TV screen buys a permanent key. After that the TV just answers, with nothing to reopen.',
  },
  {
    icon: PackagePlus,
    title: 'Install homebrew',
    body: (
      <>
        Browse the public Homebrew catalog, home to{' '}
        <a
          href="https://github.com/webosbrew/youtube-webos"
          target="_blank"
          rel="noopener noreferrer"
          className="underline decoration-foreground/20 underline-offset-4 transition-colors hover:text-foreground hover:decoration-foreground/50"
        >
          youtube-webos
        </a>
        , the YouTube app without the ads. Or pick an .ipk already on the
        phone or the PC.
      </>
    ),
  },
  {
    icon: Timer,
    title: 'Watch the clock',
    body:
      'Developer Mode expires. The remaining time counts down on screen, and renewing takes one tap from the couch, or one click from the desk.',
  },
  {
    icon: Tv,
    title: 'Keep several TVs',
    body:
      'Switch between them, rename them, correct an address that changed. Removing one asks first, in plain sight.',
  },
  {
    icon: WifiOff,
    title: 'Know when it is off',
    body: (
      <>
        A fast{' '}
        <Glossary word="probe">
          A quick knock rather than a proper visit. The app opens a bare
          connection to the TV’s SSH port, waits three seconds at most,
          then drops it without logging in. An answer means the TV is awake
          and on the network.
        </Glossary>{' '}
        says whether a TV is answering before anything slow is attempted, so
        a sleeping TV never costs a long wait.
      </>
    ),
  },
  {
    icon: ShieldCheck,
    title: 'Explain itself',
    body:
      'SoC, OTA ID, firmware. Every field says what it is and whether it matters, rather than assuming.',
  },
];

export function WhatItDoes() {
  return (
    <Section
      id="features"
      eyebrow="Features"
      title="Pair a TV, install apps on it, keep its session alive."
      lead="Built against a real LG TV, on a real phone and a real PC."
    >
      <div className="grid gap-x-10 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map(({ icon: Icon, title, body }) => (
          <div key={title}>
            <Icon className="h-5 w-5 text-accent" strokeWidth={1.75} />
            <h3 className="mt-4 font-medium">{title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              {body}
            </p>
          </div>
        ))}
      </div>
    </Section>
  );
}
