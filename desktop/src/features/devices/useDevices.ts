import { useCallback, useEffect, useState } from "react";
import type { Device } from "../../data/models";
import { checkReachable, listDevices, removeDevice } from "../../ipc/commands";

/** Reachability per device id: unknown until checked, then a boolean. */
export type Reachability = Record<string, boolean | undefined>;

/**
 * The paired TVs on this computer, loaded once from the backend and
 * refreshed after anything changes them, plus a reachability check that
 * runs when asked for, never on a timer.
 */
export function useDevices() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reachability, setReachability] = useState<Reachability>({});

  const refresh = useCallback(async () => {
    try {
      setDevices(await listDevices());
      setError(null);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoaded(true);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const check = useCallback(async (device: Device) => {
    const reachable = await checkReachable(device.host, device.port);
    setReachability((current) => ({ ...current, [device.id]: reachable }));
  }, []);

  const remove = useCallback(
    async (id: string) => {
      await removeDevice(id);
      await refresh();
    },
    [refresh],
  );

  return { devices, loaded, error, reachability, refresh, check, remove };
}
