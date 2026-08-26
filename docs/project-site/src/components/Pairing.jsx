'use client';

import { ArrowRight } from 'lucide-react';
import { Section } from './Section';

const STEPS = [
  {
    n: '01',
    title: 'Ask the TV for its key',
    body:
      'Developer Mode runs a small server on the TV. A plain request to it returns an encrypted key file.',
    code: 'GET /webos_rsa   ·   port 9991',
  },
  {
    n: '02',
    title: 'Unlock it on the phone',
    body:
      'The six characters on the TV screen decrypt that file, on the phone. The passphrase never crosses the network at all.',
    code: 'decrypted locally',
  },
  {
    n: '03',
    title: 'Talk to the TV directly',
    body:
      'From then on the key is enough. Installing an app is a message on webOS’s own internal bus, sent over SSH.',
    code: 'ssh prisoner@tv   ·   port 9922',
  },
];

export function Pairing() {
  return (
    <Section
      id="pairing"
      eyebrow="How pairing works"
      title="Six characters, once, and then never again."
      lead="No account, no cloud, no relay. The phone and the TV work it out between themselves on your own network."
    >
      <ol className="grid gap-8 md:grid-cols-3">
        {STEPS.map(({ n, title, body, code }) => (
          <li key={n} className="relative">
            <span
              className="text-xs font-medium tracking-[0.2em]"
              style={{ color: 'var(--rose)' }}
            >
              {n}
            </span>
            <h3 className="mt-3 font-medium">{title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              {body}
            </p>
            <code className="mt-4 block rounded-lg bg-foreground/[0.04] px-3 py-2 font-mono text-xs text-muted-foreground">
              {code}
            </code>
          </li>
        ))}
      </ol>

      <a
        href="https://symonxdd.github.io/aphanes/pairing/"
        className="mt-10 inline-flex items-center gap-1.5 text-sm text-accent hover:underline"
      >
        The full walkthrough, including what is deliberately not verified
        <ArrowRight className="h-4 w-4" />
      </a>
    </Section>
  );
}
