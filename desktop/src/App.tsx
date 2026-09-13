import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

/**
 * Root of the desktop UI. Nothing is designed yet: this only proves the
 * frontend can reach the Rust side through a command.
 */
export default function App() {
  const [version, setVersion] = useState<string | null>(null);

  useEffect(() => {
    invoke<string>("app_version").then(setVersion).catch(() => setVersion(null));
  }, []);

  return (
    <main>
      <h1>webOS Dev Mode Manager</h1>
      <p>Desktop scaffold{version ? ` v${version}` : ""}. No features yet.</p>
    </main>
  );
}
