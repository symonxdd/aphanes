'use client';

import { motion } from 'framer-motion';
import { Download, BookOpen } from 'lucide-react';
import { SiGithub } from 'react-icons/si';
import { useLatestRelease } from '@/hooks/useLatestRelease';

// Each element arrives a beat after the one before, the same staggered
// settle the app's own title card uses when the icon is tapped.
const rise = (delay) => ({
  initial: { opacity: 0, y: 16 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.7, delay, ease: [0.16, 1, 0.3, 1] },
});

export function Hero() {
  const { version, downloadUrl, size } = useLatestRelease();

  return (
    <section
      id="hero"
      className="relative isolate overflow-hidden bg-void text-white"
    >
      {/* The one spot of colour in the dark, bled out of the icon itself
          rather than laid on top of it as a separate decoration. */}
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/2 top-[22%] -z-10 h-[420px] w-[420px] -translate-x-1/2 rounded-full opacity-25 blur-[120px]"
        style={{
          background:
            'radial-gradient(circle, var(--rose) 0%, var(--pink) 45%, transparent 70%)',
        }}
      />

      <div className="mx-auto flex min-h-[100svh] max-w-3xl flex-col items-center justify-center px-6 py-32 text-center">
        <motion.img
          {...rise(0.05)}
          src="/icon.svg"
          alt=""
          className="w-28 h-28 sm:w-36 sm:h-36"
        />

        <motion.h1
          {...rise(0.18)}
          className="mt-10 text-5xl sm:text-6xl font-light tracking-[0.18em]"
        >
          Aphanes
        </motion.h1>

        <motion.p
          {...rise(0.28)}
          className="mt-3 text-sm tracking-[0.2em] text-white/60 uppercase"
        >
          a webOS Dev Mode Manager
        </motion.p>

        <motion.div
          {...rise(0.4)}
          className="mt-9 h-px w-16 bg-white/20"
          aria-hidden
        />

        <motion.p
          {...rise(0.5)}
          className="mt-8 text-xl"
          style={{ color: 'var(--rose)' }}
          lang="grc"
        >
          ἀφανής
        </motion.p>
        <motion.p
          {...rise(0.58)}
          className="mt-2 text-sm tracking-widest text-white/45"
        >
          unseen · not manifest
        </motion.p>

        <motion.p
          {...rise(0.7)}
          className="mt-12 max-w-md text-base leading-relaxed text-white/70"
        >
          An LG webOS TV, managed from the phone already in your hand.
          Pair once, install what you like, and watch the Developer Mode
          clock without getting up.
        </motion.p>

        <motion.div
          {...rise(0.82)}
          className="mt-10 flex flex-wrap items-center justify-center gap-3"
        >
          <a
            href={downloadUrl}
            className="inline-flex items-center gap-2 rounded-xl bg-white px-5 py-3 text-sm font-medium text-black transition-transform hover:scale-[1.02]"
          >
            <Download className="h-4 w-4" />
            Download for Android
          </a>
          <a
            href="https://symonxdd.github.io/aphanes/"
            className="inline-flex items-center gap-2 rounded-xl border border-white/15 px-5 py-3 text-sm text-white/80 transition-colors hover:bg-white/5 hover:text-white"
          >
            <BookOpen className="h-4 w-4" />
            Read the docs
          </a>
          <a
            href="https://github.com/symonxdd/aphanes"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 rounded-xl border border-white/15 px-5 py-3 text-sm text-white/80 transition-colors hover:bg-white/5 hover:text-white"
          >
            <SiGithub className="h-4 w-4" />
            Source
          </a>
        </motion.div>

        <motion.p {...rise(0.92)} className="mt-5 text-xs text-white/35">
          {version ? `${version} · ` : ''}
          {size ? `${size} MB · ` : ''}
          Android 5.0 and up · free and open source
        </motion.p>
      </div>

      {/* Fades the dark band into whatever the page's theme is below it,
          so the join reads as one surface rather than two stacked ones. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 bottom-0 h-24 bg-gradient-to-b from-transparent to-background"
      />
    </section>
  );
}
