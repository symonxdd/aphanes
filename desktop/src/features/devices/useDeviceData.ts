import { useCallback, useEffect, useRef, useState } from "react";
import type { Device, DeviceDetail, InstalledApp } from "../../data/models";
import { fetchDeviceDetail, listInstalledApps } from "../../ipc/commands";

/**
 * Something fetched from a TV. `data` outlives a failed or running
 * refetch, so what was last known stays on screen while the row that
 * reports the fetch itself says what is happening.
 */
export interface Remote<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

const idle: Remote<never> = { data: null, loading: false, error: null };

interface Entry {
  detail: Remote<DeviceDetail>;
  apps: Remote<InstalledApp[]>;
}

/**
 * What the selected TV reports, fetched once it is known to be reachable
 * and kept per device for the rest of the session, so switching back to
 * a TV shows what it said before. The details and the app list travel
 * over two connections in parallel, as the mobile app's two pages open
 * their own. Fetches run when a TV is first shown and when a person asks
 * for a refresh; never on a timer.
 */
export function useDeviceData(device: Device | null, reachable: boolean | undefined) {
  const [entries, setEntries] = useState<Record<string, Entry>>({});
  const inFlight = useRef(new Set<string>());

  const fetchAll = useCallback((id: string) => {
    if (inFlight.current.has(id)) {
      return;
    }
    inFlight.current.add(id);
    setEntries((current) => ({
      ...current,
      [id]: {
        detail: { ...(current[id]?.detail ?? idle), loading: true, error: null },
        apps: { ...(current[id]?.apps ?? idle), loading: true, error: null },
      },
    }));

    const settle = <K extends keyof Entry>(key: K, result: Remote<NonNullable<Entry[K]["data"]>>) =>
      setEntries((current) => {
        const entry = current[id];
        if (!entry) {
          return current;
        }
        const previous = entry[key];
        return { ...current, [id]: { ...entry, [key]: { ...result, data: result.data ?? previous.data } } };
      });

    const detail = fetchDeviceDetail(id).then(
      (data) => settle("detail", { data, loading: false, error: null }),
      (e: unknown) => settle("detail", { data: null, loading: false, error: String(e) }),
    );
    const apps = listInstalledApps(id).then(
      (data) => settle("apps", { data, loading: false, error: null }),
      (e: unknown) => settle("apps", { data: null, loading: false, error: String(e) }),
    );
    void Promise.allSettled([detail, apps]).then(() => inFlight.current.delete(id));
  }, []);

  useEffect(() => {
    if (device && reachable === true && !entries[device.id]) {
      fetchAll(device.id);
    }
  }, [device, reachable, entries, fetchAll]);

  const refresh = useCallback(() => {
    if (device) {
      fetchAll(device.id);
    }
  }, [device, fetchAll]);

  /**
   * Only the app list, after an install or uninstall changed it. The
   * details are untouched by either, and refetching them would repeat
   * the session check for nothing.
   */
  const refreshApps = useCallback(() => {
    if (!device) {
      return;
    }
    const id = device.id;
    setEntries((current) => {
      const entry = current[id];
      return entry ? { ...current, [id]: { ...entry, apps: { ...entry.apps, loading: true, error: null } } } : current;
    });
    listInstalledApps(id).then(
      (data) =>
        setEntries((current) => {
          const entry = current[id];
          return entry ? { ...current, [id]: { ...entry, apps: { data, loading: false, error: null } } } : current;
        }),
      (e: unknown) =>
        setEntries((current) => {
          const entry = current[id];
          return entry
            ? { ...current, [id]: { ...entry, apps: { ...entry.apps, loading: false, error: String(e) } } }
            : current;
        }),
    );
  }, [device]);

  /**
   * Re-marks the app list from a running list the TV just reported, as
   * a launch or a page's own check does, without fetching the list again.
   */
  const setRunning = useCallback(
    (running: readonly string[]) => {
      if (!device) {
        return;
      }
      const id = device.id;
      setEntries((current) => {
        const entry = current[id];
        if (!entry?.apps.data) {
          return current;
        }
        const data = entry.apps.data.map((app) => ({ ...app, running: running.includes(app.id) }));
        return { ...current, [id]: { ...entry, apps: { ...entry.apps, data } } };
      });
    },
    [device],
  );

  /**
   * Drops everything held for a TV, so it is fetched afresh the next
   * time it is known to answer. For an address change: what the old
   * address said may not be this TV at all.
   */
  const forget = useCallback((id: string) => {
    setEntries((current) => {
      if (!(id in current)) {
        return current;
      }
      const { [id]: _dropped, ...rest } = current;
      return rest;
    });
  }, []);

  const entry = device ? entries[device.id] : undefined;
  return {
    detail: entry?.detail ?? (idle as Remote<DeviceDetail>),
    apps: entry?.apps ?? (idle as Remote<InstalledApp[]>),
    refresh,
    refreshApps,
    setRunning,
    forget,
  };
}
