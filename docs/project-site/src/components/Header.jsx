'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { SiGithub } from 'react-icons/si';
import { Download } from 'lucide-react';
import { ThemeToggle } from './ThemeToggle';
import { useLatestRelease } from '@/hooks/useLatestRelease';

const NAV = [
  { label: 'What it does', href: '#what' },
  { label: 'Screens', href: '#screens' },
  { label: 'Pairing', href: '#pairing' },
  { label: 'Privacy', href: '#privacy' },
];

const Path = (props) => (
  <motion.path
    fill="transparent"
    strokeWidth="2"
    stroke="currentColor"
    strokeLinecap="round"
    {...props}
  />
);

const burger = {
  top: { closed: { d: 'M 2 5 L 16 5' }, open: { d: 'M 3 15 L 15 3' } },
  middle: {
    closed: { opacity: 1, d: 'M 2 9 L 16 9' },
    open: { opacity: 0, d: 'M 2 9 L 16 9' },
  },
  bottom: { closed: { d: 'M 2 13 L 16 13' }, open: { d: 'M 3 3 L 15 15' } },
};

const menu = {
  hidden: { opacity: 0, height: 0 },
  visible: {
    opacity: 1,
    height: 'auto',
    transition: {
      height: { duration: 0.3, ease: [0.16, 1, 0.3, 1] },
      opacity: { duration: 0.2 },
      staggerChildren: 0.05,
      delayChildren: 0.05,
    },
  },
  exit: {
    opacity: 0,
    height: 0,
    transition: {
      height: { duration: 0.25, ease: [0.16, 1, 0.3, 1] },
      opacity: { duration: 0.15 },
      staggerChildren: 0.03,
      staggerDirection: -1,
    },
  },
};

const menuItem = {
  hidden: { opacity: 0, y: -10 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { type: 'spring', stiffness: 300, damping: 30 },
  },
  exit: { opacity: 0, y: -10, transition: { duration: 0.15 } },
};

export function Header() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState('');
  const [overHero, setOverHero] = useState(true);
  const { downloadUrl } = useLatestRelease();

  useEffect(() => {
    const onScroll = () => {
      setScrolled(window.scrollY > 20);

      // The hero is permanently dark in both themes, so while the header
      // floats over it the header's own text has to be light regardless
      // of the theme, and switch back once it clears it.
      const hero = document.getElementById('hero');
      setOverHero(hero ? hero.getBoundingClientRect().bottom > 72 : false);

      const current = NAV.map((item) => item.href.slice(1)).find((id) => {
        const el = document.getElementById(id);
        if (!el) return false;
        const { top, bottom } = el.getBoundingClientRect();
        return top <= 120 && bottom >= 120;
      });
      setActive(current ?? '');
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    const onResize = () => window.innerWidth >= 768 && setOpen(false);
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  const goTo = (href) => {
    document.querySelector(href)?.scrollIntoView({ behavior: 'smooth' });
  };

  // Over the dark hero the header borrows light colours; past it, the
  // theme's own.
  const tone = overHero && !scrolled ? 'text-white/70' : 'text-muted-foreground';
  const toneStrong = overHero && !scrolled ? 'text-white' : 'text-foreground';

  return (
    <>
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
        className={`fixed top-0 inset-x-0 z-50 py-3 border-b transition-colors duration-300 ${
          scrolled || open
            ? 'bg-background/80 backdrop-blur-lg border-foreground/5'
            : 'bg-transparent border-transparent'
        }`}
      >
        <div className="mx-auto max-w-6xl px-6 flex items-center justify-between gap-4">
          <button
            onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
            className="flex items-center gap-2.5 shrink-0"
          >
            <img src="/icon.svg" alt="" className="w-7 h-7" />
            <span className={`font-semibold tracking-tight ${toneStrong}`}>
              webOS Dev Mode Manager
            </span>
          </button>

          <nav className="hidden md:flex items-center gap-1">
            {NAV.map((item) => (
              <button
                key={item.href}
                onClick={() => goTo(item.href)}
                className={`px-3 py-2 text-sm rounded-lg transition-colors hover:bg-foreground/5 ${
                  active === item.href.slice(1) ? toneStrong : tone
                }`}
              >
                {item.label}
              </button>
            ))}
          </nav>

          <div className="flex items-center gap-1.5 shrink-0">
            <a
              href="https://github.com/symonxdd/aphanes"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="GitHub repository"
              className={`hidden sm:flex w-9 h-9 items-center justify-center rounded-lg hover:bg-foreground/5 transition-colors ${tone} hover:${toneStrong}`}
            >
              <SiGithub className="w-4.5 h-4.5" />
            </a>
            <ThemeToggle />
            <a
              href={downloadUrl}
              className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-foreground text-background text-sm font-medium hover:opacity-90 transition-opacity"
            >
              <Download className="w-4 h-4" />
              Download
            </a>
            <button
              onClick={() => setOpen(!open)}
              className={`md:hidden w-9 h-9 flex items-center justify-center rounded-lg hover:bg-foreground/5 ${tone}`}
              aria-label="Toggle menu"
              aria-expanded={open}
            >
              <svg width="18" height="18" viewBox="0 0 18 18">
                {['top', 'middle', 'bottom'].map((key) => (
                  <Path
                    key={key}
                    variants={burger[key]}
                    initial="closed"
                    animate={open ? 'open' : 'closed'}
                    transition={{ duration: 0.2 }}
                  />
                ))}
              </svg>
            </button>
          </div>
        </div>
      </motion.header>

      <AnimatePresence>
        {open && (
          <motion.div
            variants={menu}
            initial="hidden"
            animate="visible"
            exit="exit"
            className="fixed top-[60px] inset-x-0 z-40 md:hidden overflow-hidden border-b border-foreground/5 bg-background/95 backdrop-blur-lg"
          >
            <div className="flex flex-col gap-1 p-4">
              {NAV.map((item) => (
                <motion.button
                  key={item.href}
                  variants={menuItem}
                  onClick={() => {
                    setOpen(false);
                    setTimeout(() => goTo(item.href), 180);
                  }}
                  className="w-full text-left py-3 px-4 rounded-xl text-base text-muted-foreground hover:text-foreground hover:bg-foreground/5 transition-colors"
                >
                  {item.label}
                </motion.button>
              ))}
              <motion.a
                variants={menuItem}
                href={downloadUrl}
                className="mt-1 flex items-center gap-2 py-3 px-4 rounded-xl bg-foreground text-background font-medium"
              >
                <Download className="w-4 h-4" />
                Download the APK
              </motion.a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
