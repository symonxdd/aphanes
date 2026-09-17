import { useCallback, useEffect, useState } from "react";
import type { Device } from "../../data/models";
import { checkReachable, listDevices, removeDevice, updateDeviceHost } from "../../ipc/commands";

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

  /** Probes the TV's SSH port and records the answer; also returns it. */
  const check = useCallback(async (device: Device) => {
    const reachable = await checkReachable(device.host, device.port);
    setReachability((current) => ({ ...current, [device.id]: reachable }));
    return reachable;
  }, []);

  const remove = useCallback(
    async (id: string) => {
      await removeDevice(id);
      await refresh();
    },
    [refresh],
  );

  /**
   * Saves a new address and forgets what was known about reaching the
   * old one, so the TV is probed again at the new address. The list is
   * reloaded first, so the probe that follows sees the new address.
   */
  const updateHost = useCallback(
    async (id: string, host: string) => {
      await updateDeviceHost(id, host);
      await refresh();
      setReachability((current) => ({ ...current, [id]: undefined }));
    },
    [refresh],
  );

  return { devices, loaded, error, reachability, refresh, check, remove, updateHost };
}
