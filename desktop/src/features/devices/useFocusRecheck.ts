import { useEffect, useRef } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";

/**
 * Runs `recheck` whenever the window regains focus. Coming back to the
 * app is the moment its picture of the TV is likeliest to be stale, so
 * it is refreshed then. The connection to the TV is held open and
 * reused, so this costs a probe and a couple of calls, not a fresh
 * login, and there is no floor on how often it may run; it is still tied
 * to the window coming forward, never a timer.
 */
export function useFocusRecheck(recheck: () => void) {
  const latest = useRef(recheck);
  latest.current = recheck;

  useEffect(() => {
    const unlisten = getCurrentWindow().onFocusChanged(({ payload: focused }) => {
      if (focused) {
        latest.current();
      }
    });
    return () => {
      void unlisten.then((stop) => stop());
    };
  }, []);
}
