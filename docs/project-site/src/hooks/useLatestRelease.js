'use client';

import { useEffect, useState } from 'react';

const REPO = 'symonxdd/aphanes';
const RELEASES_PAGE = `https://github.com/${REPO}/releases`;

/// Each platform's newest release: plain v* tags are the Android app,
/// desktop-v* tags the Windows one. Found by tag rather than through
/// /releases/latest, because the repository releases both and that badge
/// goes to whichever was released last.
const PLATFORMS = {
  android: { tag: /^v\d/, asset: '.apk' },
  windows: { tag: /^desktop-v\d/, asset: '.exe' },
};

/// The newest release per platform, for the download buttons.
///
/// Android starts out pointing at the releases page, which is always
/// correct even if the API call never lands, and narrows to the direct
/// APK link once it does, so its button is useful immediately and never
/// shows a loading state. Windows starts out null and stays null until a
/// desktop release is actually found, so its button never points at
/// nothing.
export function useLatestRelease() {
  const [releases, setReleases] = useState({
    android: { version: null, downloadUrl: RELEASES_PAGE, size: null },
    windows: null,
  });

  useEffect(() => {
    let cancelled = false;

    fetch(`https://api.github.com/repos/${REPO}/releases?per_page=30`)
      .then((response) => (response.ok ? response.json() : null))
      .then((list) => {
        if (cancelled || !Array.isArray(list)) return;
        const published = list.filter((r) => !r.draft && !r.prerelease);
        const pick = ({ tag, asset }) => {
          const release = published.find((r) => tag.test(r.tag_name ?? ''));
          const file = (release?.assets ?? []).find((a) =>
            a.name.endsWith(asset),
          );
          if (!release || !file) return null;
          return {
            version: release.tag_name.replace(/^desktop-/, ''),
            downloadUrl: file.browser_download_url,
            size: Math.round(file.size / 1048576),
          };
        };
        setReleases((previous) => ({
          android: pick(PLATFORMS.android) ?? previous.android,
          windows: pick(PLATFORMS.windows),
        }));
      })
      .catch(() => {
        // Rate limited, offline, or the repo went private. The initial
        // state already points somewhere that works.
      });

    return () => {
      cancelled = true;
    };
  }, []);

  return releases;
}
