'use client';

import { Section } from './Section';
import { Bullet } from './Bullet';

const PROBLEMS = [
  'Content drew underneath the status bar and the navigation bar.',
  'The bottom navigation was icon-only, with no labels.',
  'Removing a paired device was hard to find.',
];

export function WhyItExists() {
  return (
    <Section
      id="why"
      eyebrow="Why it exists"
      title="A tool already existed. It just was not built for a phone."
      lead="dev-manager-desktop is excellent, and this project reads its protocol work with gratitude. It is desktop-first, though, and in the first half of 2026 a phone showed it."
    >
      <div className="grid gap-10 md:grid-cols-2">
        <ul className="space-y-4">
          {PROBLEMS.map((problem) => (
            <li key={problem} className="flex gap-3 text-muted-foreground">
              <Bullet muted />
              <span className="leading-relaxed">{problem}</span>
            </li>
          ))}
        </ul>
        <div className="space-y-4">
          <p className="leading-relaxed text-muted-foreground">
            None of that is a flaw in a desktop app. It is what happens
            when a desktop app is opened on a phone. So this is a rewrite
            that treats the phone as the target rather than an
            afterthought, and holds one bar above all others: nothing
            renders under a system bar, and nothing becomes untappable
            because of one, on any screen, in any orientation.
          </p>
          {/* Their insets bug was a regression, not neglect, and it was
              fixed before this project had a first release. Saying so
              keeps the list above honest as it ages. */}
          <p className="text-sm leading-relaxed text-muted-foreground/70">
            The first of those was a regression in their Android build,
            fixed in v1.99.19 in August 2026. The other two still stand.
          </p>
          {/* The desktop app came second, and needs its own reason: a
              rewrite of a desktop tool for the desktop is only worth it
              if the desktop tool has the same problems there. */}
          <p className="leading-relaxed text-muted-foreground">
            The Windows app followed for the same reason. On the desktop,
            the existing tool has the same habits: an unlabeled icon rail, a
            setup form full of fields most people never need, and a delete
            that is hard to find. So the Windows app carries over the
            Android app’s labels, its six-character pairing and its
            removal in plain sight.
          </p>
        </div>
      </div>
    </Section>
  );
}
