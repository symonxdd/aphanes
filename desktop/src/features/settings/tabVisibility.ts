import { useCallback, useState } from "react";

/**
 * Which of the optional tabs show on a TV's pane, mirroring the mobile
 * app's tab visibility controllers. Both off by default: neither tab has
 * anything behind it yet, and most people will never want them, so
 * hiding them keeps the pane to what works. Preferences, not
 * credentials, so localStorage is the right store.
 */
export interface TabVisibility {
  files: boolean;
  terminal: boolean;
  setFiles: (visible: boolean) => void;
  setTerminal: (visible: boolean) => void;
}

const FILES_KEY = "files_tab_visible";
const TERMINAL_KEY = "terminal_tab_visible";

function read(key: string): boolean {
  try {
    return localStorage.getItem(key) === "true";
  } catch {
    return false;
  }
}

function write(key: string, visible: boolean): void {
  try {
    localStorage.setItem(key, String(visible));
  } catch {
    // A blocked store only loses persistence, not the current session.
  }
}

export function useTabVisibility(): TabVisibility {
  const [files, setFilesState] = useState(() => read(FILES_KEY));
  const [terminal, setTerminalState] = useState(() => read(TERMINAL_KEY));

  const setFiles = useCallback((visible: boolean) => {
    setFilesState(visible);
    write(FILES_KEY, visible);
  }, []);

  const setTerminal = useCallback((visible: boolean) => {
    setTerminalState(visible);
    write(TERMINAL_KEY, visible);
  }, []);

  return { files, terminal, setFiles, setTerminal };
}
