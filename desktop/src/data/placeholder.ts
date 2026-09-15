import type { CatalogPackage, DeviceInfo, DevModeStatus, InstalledApp } from "./models";

/**
 * Stand-in data so the shell has something to lay out. Devices are real
 * already; every value here is replaced by a Tauri command as the protocol
 * crate grows. Nothing in this file is ever shown in a release build.
 */
export const placeholderInfo: DeviceInfo = {
  modelName: "65UN70006LA",
  firmwareVersion: "04.64.00",
  webosVersion: "5.6.2",
  socName: "k6lp",
  otaId: "HE_DTV_W20P_AFADABAA",
};

export const placeholderDevMode: DevModeStatus = { remaining: "999:52:55" };

export const placeholderApps: InstalledApp[] = [
  { id: "youtube.leanback.v4", title: "YouTube AdFree", version: "0.5.3", vendor: "webosbrew.org" },
  { id: "org.jellyfin.webos", title: "Jellyfin", version: "1.2.0", vendor: "webosbrew.org" },
  { id: "org.xbmc.kodi", title: "Kodi", version: "21.1", vendor: "mirrors.kodi.tv" },
  { id: "org.webosbrew.hbchannel", title: "Homebrew Channel", version: "0.6.3", vendor: "webosbrew.org" },
];

export const placeholderCatalog: CatalogPackage[] = [
  {
    id: "youtube.leanback.v4",
    title: "YouTube AdFree",
    shortDescription: "youtube.leanback.v4",
    favorite: true,
    installed: true,
  },
  {
    id: "org.jellyfin.webos",
    title: "Jellyfin",
    shortDescription: "A webOS client to connect to a Jellyfin server",
    favorite: true,
    installed: true,
  },
  {
    id: "org.xbmc.kodi",
    title: "Kodi",
    shortDescription: "Award-winning free and open source media player",
    favorite: true,
    installed: true,
  },
  {
    id: "twitch.adamffdev.v1",
    title: "Twitch AdFree",
    shortDescription: "twitch.adamffdev.v1",
    favorite: true,
    installed: false,
  },
  {
    id: "org.piccap",
    title: "PicCap",
    shortDescription: "Hyperion Sender App, Ambilight for webOS",
    favorite: true,
    installed: false,
  },
  {
    id: "com.moonlight",
    title: "Moonlight",
    shortDescription: "Open source NVIDIA GameStream client",
    favorite: false,
    installed: false,
  },
];
