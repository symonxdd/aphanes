/**
 * The Developer Mode session's remaining time as LG reports it, read as
 * a number of seconds, or null when it is not in a shape this recognizes.
 * Ported from the mobile app's DevModeStatus.remainingDuration.
 *
 * LG does not document the format, and dev-manager-desktop passes the
 * string straight through without parsing it. A real TV was observed
 * returning "999:52:55", so hours run well past 24 and are not padded to
 * a fixed width; that shape is handled first. The written-out forms after
 * it are defensive, for firmware that words it differently. Anything
 * unrecognized gives up cleanly and the caller shows the string verbatim.
 */
export function remainingSeconds(remaining: string | null): number | null {
  const raw = remaining?.trim();
  if (!raw) {
    return null;
  }

  // "999:59:59", where hours are free to exceed 24.
  const clock = /^(\d+):([0-5]?\d):([0-5]?\d)$/.exec(raw);
  if (clock) {
    return Number(clock[1]) * 3600 + Number(clock[2]) * 60 + Number(clock[3]);
  }

  // "3 days 4 hours", "45 minutes", "12h 30m", and similar. Summed rather
  // than matched as a whole, so order and separators do not matter.
  const parts = /(\d+)\s*(days?|d|hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b/gi;
  let total = 0;
  let matched = false;
  for (const part of raw.matchAll(parts)) {
    const value = Number(part[1]);
    const unit = part[2].toLowerCase();
    matched = true;
    if (unit.startsWith("d")) {
      total += value * 86400;
    } else if (unit.startsWith("h")) {
      total += value * 3600;
    } else if (unit.startsWith("m")) {
      total += value * 60;
    } else {
      total += value;
    }
  }
  return matched && total > 0 ? total : null;
}

/**
 * Seconds as a clock, with hours free to run past 24. A session can be
 * most of a thousand hours long, so days would be the friendlier unit,
 * but LG reports hours and matching that keeps the value comparable with
 * what the TV itself shows.
 */
export function formatCountdown(seconds: number): string {
  const clamped = Math.max(0, Math.floor(seconds));
  const hours = Math.floor(clamped / 3600);
  const minutes = String(Math.floor((clamped % 3600) / 60)).padStart(2, "0");
  const secs = String(clamped % 60).padStart(2, "0");
  return `${hours}:${minutes}:${secs}`;
}
