'use client';

import { useEffect, useState } from 'react';

const REPO = 'symonxdd/aphanes';
const RELEASES_PAGE = `https://github.com/${REPO}/releases/latest`;

/// The newest published release, for the download button.
///
/// Starts out pointing at the releases page, which is always correct even
/// if the API call never lands, and narrows to the direct APK link once
/// it does. The button is therefore useful immediately and never shows a
/// loading state for something this small.
export function useLatestRelease() {
  const [release, setRelease] = useState({
    version: null,
    downloadUrl: RELEASES_PAGE,
    size: null,
  });

  useEffect(() => {
    let cancelled = false;

    fetch(`https://api.github.com/repos/${REPO}/releases/latest`)
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (cancelled || !data) return;
        const apk = (data.assets ?? []).find((asset) =>
          asset.name.endsWith('.apk'),
        );
        setRelease({
          version: data.tag_name ?? null,
          downloadUrl: apk?.browser_download_url ?? RELEASES_PAGE,
          size: apk ? Math.round(apk.size / 1048576) : null,
        });
      })
      .catch(() => {
        // Rate limited, offline, or the repo went private. The initial
        // state already points somewhere that works.
      });

    return () => {
      cancelled = true;
    };
  }, []);

  return release;
}
