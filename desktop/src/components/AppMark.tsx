/**
 * The app mark, drawn from the same geometry as the mobile app's
 * AppIconGlyph painter: a 232x164 rounded screen (radius 20) filled with
 * the #FB7185 to #EC4899 gradient, with the lower-left triangle cut away
 * from the bottom-left corner up to 48 units below the top-left one.
 */
export function AppMark({ width = 36 }: { width?: number }) {
  const height = Math.round((width * 164) / 232);
  return (
    <svg width={width} height={height} viewBox="0 0 232 164" aria-hidden="true">
      <defs>
        <linearGradient id="app-mark-gradient" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#FB7185" />
          <stop offset="1" stopColor="#EC4899" />
        </linearGradient>
        <clipPath id="app-mark-clip">
          <rect x="0" y="0" width="232" height="164" rx="20" />
        </clipPath>
      </defs>
      <polygon clipPath="url(#app-mark-clip)" points="0,0 232,0 232,164 0,48" fill="url(#app-mark-gradient)" />
    </svg>
  );
}
