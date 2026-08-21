/// Catalog app ids shown under the "Favorites" sort mode in the catalog
/// browser, in this exact order - a List, not a Set, specifically so that
/// order is preserved and used (see catalog_page.dart's sort comparator,
/// which ranks these by their position here rather than alphabetically).
///
/// Deliberately not user-facing: no star toggle, no UI to change this -
/// edit this list directly in code. Not the catalog's own `featured`
/// flag either, which is an editorial pick by the webosbrew project
/// rather than anything this app's own list is meant to reflect.
const List<String> curatedFavoriteAppIds = <String>[
  'youtube.leanback.v4',
  'org.jellyfin.webos',
  'org.xbmc.kodi',
  'twitch.adamffdev.v1',
  'org.webosbrew.piccap',
];
