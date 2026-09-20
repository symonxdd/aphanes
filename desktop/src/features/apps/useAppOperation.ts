import { useCallback, useState } from "react";
import type { OperationProgress } from "../../data/models";
import type { ProgressListener } from "../../ipc/commands";

/**
 * The state of one install or uninstall, as the mobile app's
 * AppOperationState has it: idle, running with the latest step, then
 * succeeded or failed with the message to show.
 */
export type AppOperationState =
  | { phase: "idle" }
  | { phase: "running"; title: string; progress: OperationProgress | null }
  | { phase: "succeeded"; title: string }
  | { phase: "failed"; title: string; message: string };

/**
 * Drives one operation at a time. `start` is the IPC call to make; it is
 * handed the listener that feeds progress back here. Every operation is
 * the direct result of a click that reached this hook.
 */
export function useAppOperation(onSucceeded: () => void) {
  const [state, setState] = useState<AppOperationState>({ phase: "idle" });

  const run = useCallback(
    async (title: string, start: (onProgress: ProgressListener) => Promise<void>) => {
      setState({ phase: "running", title, progress: null });
      try {
        await start((progress) => setState({ phase: "running", title, progress }));
        setState({ phase: "succeeded", title });
        onSucceeded();
      } catch (e) {
        setState({ phase: "failed", title, message: String(e) });
      }
    },
    [onSucceeded],
  );

  const reset = useCallback(() => setState({ phase: "idle" }), []);

  return {
    state,
    run: (title: string, start: (onProgress: ProgressListener) => Promise<void>) => void run(title, start),
    reset,
  };
}
