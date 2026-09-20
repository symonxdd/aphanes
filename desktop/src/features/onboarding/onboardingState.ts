const KEY = "onboarding_done";

/** Whether the intro has been dismissed once on this computer. */
export function readOnboardingDone(): boolean {
  try {
    return localStorage.getItem(KEY) === "true";
  } catch {
    return false;
  }
}

export function writeOnboardingDone(): void {
  try {
    localStorage.setItem(KEY, "true");
  } catch {
    // Without storage the intro shows again next launch, which is harmless.
  }
}
