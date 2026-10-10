import { defineConfig } from "vite";

export default defineConfig({
  // Relative base so the build works from any subpath (GitHub Pages, itch.io)
  base: "./",
  publicDir: "public",
});
