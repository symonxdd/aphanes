import { SiGithub } from 'react-icons/si';

export function Footer() {
  return (
    <footer className="border-t border-foreground/5">
      <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-12 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2.5">
          <img src="/icon.svg" alt="" className="h-6 w-6" />
          <div>
            <p className="text-sm font-medium">webOS Dev Mode Manager</p>
            <p className="text-xs text-muted-foreground">
              A Symon Software Experience
            </p>
          </div>
        </div>

        <nav className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm text-muted-foreground">
          <a href="https://symonxdd.github.io/aphanes/" className="hover:text-foreground">
            Documentation
          </a>
          <a
            href="https://github.com/symonxdd/aphanes/releases"
            className="hover:text-foreground"
          >
            Releases
          </a>
          <a
            href="https://github.com/symonxdd/aphanes/issues"
            className="hover:text-foreground"
          >
            Issues
          </a>
          <a
            href="https://github.com/symonxdd/aphanes"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="GitHub"
            className="hover:text-foreground"
          >
            <SiGithub className="h-4 w-4" />
          </a>
        </nav>
      </div>

      <div className="mx-auto max-w-6xl px-6 pb-12">
        <p className="text-xs leading-relaxed text-muted-foreground/70">
          Unaffiliated with LG Electronics Inc. or the webOS Open Source
          Edition project.
        </p>
      </div>
    </footer>
  );
}
