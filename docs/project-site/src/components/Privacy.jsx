'use client';

import { Section } from './Section';

const STAYS = [
  'Your paired TVs, their addresses and their names',
  'The pairing key for each one, in the phone’s keystore',
  'Everything you install, and everything you remove',
  'How you use the app, which is measured nowhere',
];

const LEAVES = [
  {
    what: 'The Homebrew catalog',
    when: 'Only when you open it',
    sends: 'Nothing about you or your TVs',
  },
  {
    what: 'An app download',
    when: 'Only when you install one',
    sends: 'Nothing about you or your TVs',
  },
  {
    what: 'The session time check',
    when: 'Only on a device’s detail page',
    sends: 'The session token read from that TV',
  },
];

export function Privacy() {
  return (
    <Section
      id="privacy"
      eyebrow="Privacy"
      title="Your TV, your network, your phone."
      lead="Managing a TV happens directly between the app and the TV. There is no account, no sync and no server in the middle."
    >
      <div className="grid gap-12 md:grid-cols-2">
        <div>
          <h3 className="text-sm font-medium uppercase tracking-widest text-muted-foreground">
            Never leaves the phone
          </h3>
          <ul className="mt-5 space-y-3">
            {STAYS.map((item) => (
              <li key={item} className="flex gap-3 text-sm leading-relaxed">
                <span
                  aria-hidden
                  className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full"
                  style={{ background: 'var(--rose)' }}
                />
                {item}
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h3 className="text-sm font-medium uppercase tracking-widest text-muted-foreground">
            Reaches the internet
          </h3>
          {/* Named in full rather than summarised. Three is a short
              enough list to simply show. */}
          <ul className="mt-5 space-y-4">
            {LEAVES.map(({ what, when, sends }) => (
              <li
                key={what}
                className="rounded-xl border border-foreground/10 p-4"
              >
                <p className="text-sm font-medium">{what}</p>
                <p className="mt-1 text-xs text-muted-foreground">{when}</p>
                <p className="mt-2 text-xs text-muted-foreground">
                  Sends: {sends}
                </p>
              </li>
            ))}
          </ul>
          <p className="mt-4 text-xs leading-relaxed text-muted-foreground/80">
            The last one is the only request that sends anything at all,
            and it exists because nothing on the TV can answer how long a
            session has left.
          </p>
        </div>
      </div>
    </Section>
  );
}
