/// One list bullet, sitting on the optical center of the first line of
/// its own text.
///
/// The dot lives inside a box exactly one line tall and is centred in
/// it, rather than being nudged into place with a top margin. A margin
/// is guesswork that has to be re-tuned for every font size it meets,
/// and it tends to land the dot on a fractional device pixel, which is
/// what makes a 6px circle render as a slightly flattened one.
export function Bullet({ muted = false }) {
  return (
    <span aria-hidden className="flex h-[1lh] flex-none items-center">
      <span
        className={`block h-1.5 w-1.5 rounded-full ${muted ? 'bg-foreground/30' : ''}`}
        style={muted ? undefined : { background: 'var(--rose)' }}
      />
    </span>
  );
}
