'use client';

import { useEffect, useState } from 'react';
import { useLatestRelease } from './useLatestRelease';

const RELEASES_PAGE = 'https://github.com/symonxdd/aphanes/releases';

/// Which of the two apps fits the device reading the page: 'android',
/// 'windows', or 'other' for everything else (a Mac, an iPhone, Linux).
function detectPlatform() {
  const agent = navigator.userAgent;
  if (/Android/i.test(agent)) return 'android';
  if (/Windows/i.test(agent)) return 'windows';
  return 'other';
}

/// The one main download button, fitted to the device reading the page,
/// the way most apps that ship on several platforms do it.
///
/// On Android or Windows it is that platform's installer, downloaded
/// straight away. Everywhere else there is nothing to download yet (no
/// iOS, macOS or Linux build), so it says so and leads to the downloads
/// section instead of pretending to be a download.
///
/// Null until the page is running in a browser, since the server cannot
/// know the device; that happens before the hero's entrance finishes.
export function usePrimaryDownload() {
  const [platform, setPlatform] = useState(null);
  const { android, windows } = useLatestRelease();

  useEffect(() => setPlatform(detectPlatform()), []);

  if (platform === null) return null;
  if (platform === 'android') {
    return { href: android.downloadUrl, label: 'Download for Android', direct: true };
  }
  if (platform === 'windows') {
    // Before the first desktop release there is no installer to point
    // at, so the releases page stands in for it.
    return { href: windows?.downloadUrl ?? RELEASES_PAGE, label: 'Download for Windows', direct: true };
  }
  return { href: '#downloads', label: 'Android and Windows apps', direct: false };
}
