import { useCallback, useEffect, useState } from "react";
import type { CatalogPackage } from "../../data/models";
import { fetchCatalog } from "../../ipc/commands";
import type { Remote } from "../devices/useDeviceData";

/**
 * The Homebrew catalog, fetched the first time the catalog dialog opens
 * and kept for the session; a person can ask for it again with `refresh`.
 * Never fetched in the background or at launch.
 */
export function useCatalog(open: boolean) {
  const [state, setState] = useState<Remote<CatalogPackage[]>>({ data: null, loading: false, error: null });

  const refresh = useCallback(() => {
    setState((current) => ({ ...current, loading: true, error: null }));
    fetchCatalog().then(
      (data) => setState({ data, loading: false, error: null }),
      (e: unknown) => setState((current) => ({ ...current, loading: false, error: String(e) })),
    );
  }, []);

  useEffect(() => {
    if (open && state.data === null && !state.loading && state.error === null) {
      refresh();
    }
  }, [open, state, refresh]);

  return { ...state, refresh };
}
