'use client';

import { Section } from './Section';

const PROBLEMS = [
  'Content drew underneath the status bar and the navigation bar.',
  'The bottom navigation was icon-only, with no labels.',
  'Removing a paired device was hard to find.',
];

export function WhyItExists() {
  return (
    <Section
      eyebrow="Why it exists"
      title="A tool already existed. It just was not built for a phone."
      lead="dev-manager-desktop is excellent, and this project reads its protocol work with gratitude. It is desktop-first, though, and on a phone it shows."
    >
      <div className="grid gap-10 md:grid-cols-2">
        <ul className="space-y-4">
          {PROBLEMS.map((problem) => (
            <li key={problem} className="flex gap-3 text-muted-foreground">
              <span
                aria-hidden
                className="mt-2 h-1 w-1 shrink-0 rounded-full bg-foreground/30"
              />
              <span className="leading-relaxed">{problem}</span>
            </li>
          ))}
        </ul>
        <p className="leading-relaxed text-muted-foreground">
          None of that is a flaw in a desktop app. It is what happens when
          a desktop app is opened on a phone. So this is a rewrite that
          treats the phone as the target rather than an afterthought, and
          holds one bar above all others: nothing renders under a system
          bar, and nothing becomes untappable because of one, on any
          screen, in any orientation.
        </p>
      </div>
    </Section>
  );
}
