# Phase B: Pixel-Art Overhaul (web build)

> **For a fresh agent session:** this plan stands on its own. Read `CLAUDE.md`, then this file, then `web/PORTING.md`.
> Work only in `web/`. The Lua code in the repo root is a frozen reference.

## Context

The game has been ported from LÖVE/Lua to **TypeScript + Vite + Canvas 2D** in `web/` (Phase A, done 2026-10-10).
That port is faithful and playable: menu, time trial, endless mode with the yeti, name entry, high scores and sidebar HUDs.
Type check, 115 Vitest tests and the build all pass.

All in-game art is still drawn at runtime with shape primitives (polygons, ellipses, rectangles) through the LÖVE shim in
`web/src/platform/love.ts`. Canvas 2D antialiases those paths, so edges look soft and "vector-y" rather than like crisp pixel art.
**Goal:** replace this with real, palette-locked pixel art authored at the native 360×480 resolution. Keep the 80s
"Windbreaker" look (hot pink, electric blue, yellow, mint, snow white).

**Decisions already made with the user:**
- **Code first.** Sprites are authored as palette-indexed pixel grids in TypeScript. They're exact, diffable and always
  on-palette, and they can be reviewed by rendering them to PNG and looking at the result. This includes the skier.
- **AI image tools only where code grids fall short.** The likely cases are the yeti's animation frames and the large title
  screen. Use PixelLab (it has an MCP server) for animated frame sets, or Retro Diffusion or another image model for large static
  art. Everything AI-made gets snapped to the palette. Earlier PixelLab assets (`assets/sprites/skier/`, unused) are optional
  inputs only, not a constraint.
- **Hand simpler, mechanical work to Codex** through the `codex:codex-rescue` agent (`--background --write`). Give each job a
  set of files no other job touches, then verify the results yourself (`npx tsc --noEmit`, `npm test`, play in the browser).
  Do the art direction and the visual review yourself.

## Where the art lives now (web/src)

Important: `lib/sprites.ts` is **dead code**. Nothing imports it, in either the Lua or the TS version. The real drawing is in
the entity files:

| What | File → function |
|------|-----------------|
| Skier (7 steering positions, tuck, side-view stop, crash) | `entities/skier.ts` → `draw`, `draw_normal`, `draw_side_view`, `draw_crashed` |
| Small/large tree, rock, cabin, snow mound | `entities/obstacle.ts` → `draw_small_tree`, `draw_large_tree`, `draw_rock`, `draw_cabin`, `draw_snow_mound` (`draw` applies flip and scale) |
| Gates (pending/passed/missed) | `entities/gate.ts` → `draw` |
| Yeti (run, arm swing, lunge) + danger overlay | `entities/yeti.ts` → `draw`, `draw_yeti`, `draw_danger_overlay` |
| Particles (snow spray, impact, crash, gate sparkle) | `systems/particles.ts` |
| Slope background, finish line, overlays | `states/play_state.ts` → `draw_slope`, `draw_game_over`, `draw_pause`, `draw_yeti_warning` |
| Block-pixel fonts that already exist | `ui/sidebar_hud.ts` (`CHARS` table, `draw_block_char`), `states/name_entry_state.ts` (`draw_blocky_char`) |
| Title screen | `public/images/game_main_screen.png` (1792×2400 AI image, off-grid, has a Gemini watermark at the bottom right) |
| Palette | `colors.ts` |

Skier positions are **0-based** in TS: `POS_FULL_LEFT=0 … POS_CENTER=3 … POS_FULL_RIGHT=6`.

## Steps

### 1. Locked palette (`web/src/gfx/palette.ts`)
- About 16–24 colors, each with a single-character key. Include the 80s neons from `colors.ts`, snow ramps (white → pale blue
  shadow → blue-gray), a pine ramp (3 greens), wood/rock ramps (2–3 each), skin (2), black outline, yeti whites and grays, and
  red eyes. `.` means transparent.
- `colors.ts` keeps its names but points at palette entries, so UI code doesn't change.

### 2. Sprite format + baking (`web/src/gfx/sprite.ts`)
- A sprite is `{ w, h, ox, oy, rows: string[] }`, where each character of a row is a palette key and `ox, oy` is the anchor
  (the entity's x, y, usually the feet or base).
- `bake(sprite)` draws it once to an offscreen canvas with `fillRect` per pixel, and `drawSprite(name, x, y, flipX?)` blits it
  at **integer** coordinates (`Math.round` after the camera transform) so the pixels stay crisp.
- Optionally pack everything into a single atlas canvas at startup.
- Support palette swaps for variants (pink and blue cabin roofs; gate colors for pending/passed/missed) instead of duplicating
  sprites.

### 3. Review tooling (`web/tools/render-sprites.ts`, run with `npx tsx`)
- Renders every sprite to a PNG contact sheet at 1× and 4× (with `@napi-rs/canvas` or `pngjs`) at
  `web/tools/out/contact-sheet.png`, labelled by name.
- **The loop:** author → render the sheet → look at the PNG with the Read tool → fix → repeat. Then check in context with
  in-game screenshots in Chrome (dev server `npm run dev`; drive the game from JS via `await import('/src/core/state_manager.ts')`;
  fast-forward with `SM.update(1/60)` loops).
- Add a Vitest test checking that every sprite has rows of equal width, uses only palette keys, and has an anchor inside its bounds.

### 4. Static sprites as code grids (good Codex candidates once the palette, format and one example sprite exist)
- Small tree (~12×18), large tree (~20×30) and a snowy variant of each, rock (~14×10), cabin (~28×24, palette-swapped roof),
  snow mound, gate pole + flag in 3 states, finish-line banner, ski-track decal, particle pixels (1–2px), HUD icons.
- Match the current sizes and collision footprints: read each type's radius/size in `entities/obstacle.ts` (`Obstacle.TYPES`)
  and don't change collision values.
- Replace the bodies of the `draw_*` functions in `entities/obstacle.ts` and `entities/gate.ts` with `drawSprite` calls.

### 5. Characters, code first
- **Skier:** one sprite per position (7, mirrored left/right, so author 4: center, gentle, sharp, full/side-stop), plus a tuck
  variant of each and 2–3 crash frames. About 16×24. Pink jacket, blue pants and skis, yellow helmet, goggles.
- **Yeti:** 2–4 run frames and 1–2 lunge frames, about 32×40. If the code version reads badly after two review passes,
  generate a frame set with PixelLab, run it through `web/tools/quantize.ts` (nearest palette color, remove isolated stray
  pixels, crop), and convert it into the same `rows` format.
- Wire them into `entities/skier.ts` and `entities/yeti.ts`, keeping all state logic and timing as it is.

### 6. Pixel font
- Turn the existing `CHARS` block font (`ui/sidebar_hud.ts`) into a shared bitmap font (`web/src/gfx/font.ts`). Then make
  `love.graphics.print/printf` in `platform/love.ts` use it at small sizes instead of the system font, keeping width
  measurement for `printf` centering.

### 7. Title screen
- Rebuild it at 360×480: downsample the current image (box filter), quantize it to the palette, remove the watermark and clean
  it up. Or regenerate it at native size. Leave space for the menu items drawn by `states/menu_state.ts`.

### 8. Clean up
- Delete `lib/sprites.ts` (dead code). Remove shape-drawing code that has been replaced.
- Update `docs/graphics.md` to describe the palette, sprite format and review loop, and update `docs/ROADMAP.md`.

## Known rough edges from Phase A (fix here or in a polish pass)
- The "Quit" menu item does nothing useful in a browser. Hide it in the web build.
- Phones: steering (one finger) and tuck (two fingers) work, but name entry and "ENTER: Continue" need on-screen tap targets.
- No pixel-perfect map diff against the Lua yet, because LÖVE isn't installed. The seeded RNG is pinned by tests.

## Verification
- `cd web && npx tsc --noEmit && npm test && npm run build` all pass.
- The contact sheet has been reviewed for every sprite, and every sprite uses only palette colors (enforced by the test).
- Play in Chrome: menu → time trial to the finish → name entry → high scores, then endless until the yeti catches you. Take
  screenshots at 1× zoom to check that edges are crisp (no antialiasing on sprites), and that collisions feel the same as before
  (no hitbox values changed).
- Before/after screenshot pairs for the menu, gameplay, crash and yeti chase, shared with the user.
