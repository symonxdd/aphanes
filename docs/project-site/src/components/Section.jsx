'use client';

import { motion } from 'framer-motion';

/// One page section: an eyebrow, a heading, optional standfirst, then
/// whatever the section is actually about.
///
/// Every section shares this shell so the vertical rhythm and the
/// entrance are defined once rather than re-tuned per section.
export function Section({ id, eyebrow, title, lead, children, className = '' }) {
  return (
    <section id={id} className={`mx-auto max-w-6xl px-6 py-24 sm:py-32 ${className}`}>
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-80px' }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        {eyebrow && (
          <p className="text-xs font-medium uppercase tracking-[0.2em] text-accent">
            {eyebrow}
          </p>
        )}
        <h2 className="mt-3 max-w-2xl text-3xl sm:text-4xl font-semibold tracking-tight">
          {title}
        </h2>
        {lead && (
          <p className="mt-4 max-w-2xl text-lg leading-relaxed text-muted-foreground">
            {lead}
          </p>
        )}
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 16 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: '-80px' }}
        transition={{ duration: 0.6, delay: 0.08, ease: [0.16, 1, 0.3, 1] }}
        className="mt-12"
      >
        {children}
      </motion.div>
    </section>
  );
}
