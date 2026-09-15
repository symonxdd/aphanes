import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { SplashProvider } from "./features/splash/SplashProvider";
import { ThemeProvider } from "./theme/ThemeProvider";
import "./styles/base.css";

const root = document.getElementById("root");
if (!root) {
  throw new Error("index.html has no #root element");
}

ReactDOM.createRoot(root).render(
  <React.StrictMode>
    <ThemeProvider>
      <SplashProvider>
        <App />
      </SplashProvider>
    </ThemeProvider>
  </React.StrictMode>,
);
