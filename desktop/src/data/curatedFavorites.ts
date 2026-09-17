/**
 * Catalog app ids shown under the "Favorites" filter, in this exact order:
 * the catalog dialog ranks them by their position here, not
 * alphabetically. The same list as the mobile app's
 * curatedFavoriteAppIds. Deliberately not user-facing: no star toggle,
 * edit this list in code. Not the catalog's own `featured` flag either,
 * which is the webosbrew project's editorial pick.
 */
export const curatedFavoriteAppIds: readonly string[] = [
  "youtube.leanback.v4",
  "org.jellyfin.webos",
  "org.xbmc.kodi",
  "twitch.adamffdev.v1",
  "org.webosbrew.piccap",
];
