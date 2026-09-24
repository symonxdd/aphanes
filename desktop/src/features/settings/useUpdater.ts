import { useCallback, useRef, useState } from "react";
import type { Update } from "@tauri-apps/plugin-updater";
import { checkForUpdate } from "../../ipc/commands";

/**
 * idle -> checking -> current | available -> downloading -> downloaded
 * -> installing. "installing" has no way out on success: the Windows
 * installer closes this process to replace the running executable, and
 * reopens the app when it is done.
 */
export type UpdaterStatus = "idle" | "checking" | "current" | "available" | "downloading" | "downloaded" | "installing";

export interface Updater {
  status: UpdaterStatus;
  /** The newer version the feed names, once a check has found one. */
  version: string | null;
  /** Download progress from 0 to 1, or null while the size is unknown. */
  progress: number | null;
  error: string | null;
  check: () => void;
  download: () => void;
  install: () => void;
}

/**
 * The update flow, held by App rather than by Settings, so a download
 * keeps its place when Settings is closed and reopened. Each of the three steps
 * runs only on its own click: checking, downloading and installing. None
 * of them runs at launch or on a timer, and a finished download waits for
 * the install click rather than closing the app on its own.
 */
export function useUpdater(): Updater {
  const [status, setStatus] = useState<UpdaterStatus>("idle");
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const update = useRef<Update | null>(null);

  const check = useCallback(() => {
    setError(null);
    setStatus("checking");
    checkForUpdate()
      .then((found) => {
        update.current = found;
        setStatus(found ? "available" : "current");
      })
      .catch((e: unknown) => {
        setError(String(e));
        setStatus("idle");
      });
  }, []);

  const download = useCallback(() => {
    const pending = update.current;
    if (!pending) return;
    setError(null);
    setProgress(null);
    setStatus("downloading");
    let total: number | null = null;
    let received = 0;
    pending
      .download((event) => {
        if (event.event === "Started") {
          total = event.data.contentLength ?? null;
        } else if (event.event === "Progress") {
          received += event.data.chunkLength;
          setProgress(total ? Math.min(1, received / total) : null);
        }
      })
      .then(() => setStatus("downloaded"))
      .catch((e: unknown) => {
        setError(String(e));
        setStatus("available");
      });
  }, []);

  const install = useCallback(() => {
    const pending = update.current;
    if (!pending) return;
    setError(null);
    setStatus("installing");
    // On success the installer ends this process before the promise
    // settles, so only a failure ever gets here.
    pending.install().catch((e: unknown) => {
      setError(String(e));
      setStatus("downloaded");
    });
  }, []);

  return { status, version: update.current?.version ?? null, progress, error, check, download, install };
}
