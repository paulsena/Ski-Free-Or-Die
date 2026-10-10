# Graphics System

The web build (`web/`) draws everything as **palette-locked pixel art at the native 360×480 resolution**.
Sprites are palette-indexed grids written in TypeScript, so they're exact, diffable and always on-palette.
They're baked once to offscreen canvases and blitted at whole-pixel positions, so nothing is antialiased.
The game canvas is then scaled up with nearest-neighbour filtering.

(The original LÖVE build in `src/` still uses shape primitives. It's a frozen reference.)

## Palette

**File:** `web/src/gfx/palette.ts`. It has 32 colors, each with a single-character key. `.` is transparent.

| Group | Keys |
|-------|------|
| Ink | `K` black |
| 80s neons | `P` hot pink, `p` pink shadow, `l` pink highlight, `C` electric blue, `c` blue shadow, `B` royal blue, `Y` yellow, `y` yellow shadow, `M` mint, `O` sunset orange, `V` deep purple |
| Snow | `W` snow white, `S` snow (ground), `s` snow shadow, `b` blue-gray, `A` sky blue |
| Night | `D` night navy, `d` dusk indigo (UI backgrounds, title) |
| Pine | `g` dark, `G` pine, `j` light |
| Wood | `n` dark brown, `N` cabin brown, `w` light wood |
| Rock | `r` dark, `R` gray, `L` light |
| Skin | `F`, `f` |
| Yeti | `E` glowing red, `e` dark red |

`web/src/colors.ts` keeps its named colors (`Colors.HOT_PINK`, …), but each one now points at a palette entry via `pal(key, alpha?)`, so UI code is on-palette too.
`nearest_key(r, g, b)` maps any color to the palette.

## Sprite format

**Files:** `web/src/gfx/sprite_def.ts` (pure data helpers, no DOM) and `web/src/gfx/sprite.ts` (baking and drawing).

```ts
{ w, h, ox, oy, rows: string[] }   // rows[y][x] is a palette key; (ox, oy) is the anchor
sprite(ox, oy, rows)               // builds one (w/h come from the grid)
```

- The **anchor** is the pixel that lands on the entity's `(x, y)`. For obstacles that's the hitbox center, for the skier it's the body (boots are 3px below), and for the yeti it's the body center.
- `draw_sprite(name, x, y, flip_x?, swap?, alpha?)` draws a registered sprite in the current coordinate space. Only the translation is used: the position is snapped with `Math.round`, and scale and rotation are ignored, so pixels never get resampled.
- `fill_px(key, x, y, w, h, alpha?)` fills a snapped rectangle in one palette color. Use it for anything with a variable size (gate banners, slope, finish line, particles, UI bars).
- **Palette swaps** (`Swap = { P: "M", … }`) recolor a sprite instead of duplicating it. Each (sprite, flip, swap) combination is baked once and cached.
- The camera rounds its translation (`lib/camera.ts`), so world-space geometry also lands on whole pixels.

**Registry:** `web/src/gfx/sprites/index.ts` merges these files:

| File | Sprites |
|------|---------|
| `obstacles.ts` | `small_tree`, `small_tree_snowy`, `large_tree`, `large_tree_snowy`, `rock`, `snow_mound`, `cabin` |
| `gate.ts` | `gate_pole`, `gate_arrow`, plus `GATE_SWAPS` (pending pink / passed mint / missed gray / flash white) |
| `skier.ts` | `skier_center`, `skier_gentle`, `skier_sharp`, `skier_side`, a `*_tuck` variant of each, `skier_crash_1/2` |
| `yeti.ts` | `yeti_run_1..3`, `yeti_lunge_1/2` |
| `ui.ts` | `ui_arrow_up/down`, `ui_medal` (+ `MEDAL_SWAPS` silver/bronze), `ui_trophy` |
| `variants.ts` | Palette-swap variants, listed so the contact sheet shows them (`CABIN_ROOF_BLUE`, gate states, medals) |

### How entities pick sprites
- **Skier** (`entities/skier.ts`): positions 1–5 map to center/gentle/sharp poses, and the left positions are mirrored right poses. Positions 0/6 use the side view. Tucking appends `_tuck`. A crash alternates the two crash frames (the dizzy stars move).
- **Obstacles** (`entities/obstacle.ts`): the seeded `scale` (0.9–1.1) is no longer applied, because pixel art isn't scaled. It now picks a variant instead: trees use the snowy sprite and cabins the blue roof when `scale >= 1.0`. The `flip` field still mirrors the sprite. RNG draws and hitboxes are unchanged.
- **Gates** (`entities/gate.ts`): the banner is drawn with `fill_px` stripes between the two pole sprites, all recolored by the state swap. The arrow above a pending gate bobs by 2px.
- **Yeti** (`entities/yeti.ts`): the run cycle `1,2,3,2` follows the arm-swing phase. A lunge shows the lunge frames plus a 6px hop toward the player, replacing the old 1.3× scale. The eyes flicker red/orange through a swap.
- **Particles** (`systems/particles.ts`): square pixels in a palette key per type. They shrink as they die instead of fading with alpha.

## Font

**File:** `web/src/gfx/font.ts`. A 5×7 bitmap font covering printable ASCII (6px advance).
`love.graphics.print/printf` in `platform/love.ts` render with it: sizes ≤13 draw at 1×, larger sizes at 2× (the menu uses 16 → 2×).
`Font.getWidth` measures the bitmap, so `printf` centering and wrapping still work.
The sidebar HUD and the name-entry screen draw the same glyphs as big blocks.

## Title screen

`web/public/images/title_screen.png` is 360×480 and palette-locked (a test enforces this). It's built from the original AI art (`assets/images/game_main_screen.png`, 1792×2400):

```bash
cd web && npm run title
```

That runs `tools/quantize.ts`, which does an area-average downsample, nearest palette color in CIELAB, a light 4×4 Bayer dither and stray-pixel cleanup. Then `tools/fix-title.ts` removes the generator watermark.
`quantize.ts` is generic (`--crop`, `--size`, `--palette`, `--dither`, `--clean`, `--erase`, and `--rows` to emit a code sprite), so it can turn any AI-made frames into sprites.

## Review loop

1. Edit the grids in `web/src/gfx/sprites/*.ts`. The Python scripts in `web/tools/art/` only bootstrapped them (see its README).
2. `npm run sprites [filter]` renders `web/tools/out/contact-sheet.png` (or `contact-sheet-<filter>.png`). Each sprite appears at 1× and at 4× (`ZOOM=n` to change), with the anchor pixel marked in magenta and the palette-swap variants included. Open the PNG and look at it.
3. `npm test` runs `test/sprites.test.ts`, which checks that rows are rectangular, that only palette keys are used, that anchors are in bounds and that swap targets are valid. `test/title.test.ts` checks the title palette.
4. Check in context: `npm run dev`. In dev builds `window.__game = { StateManager, love }` is exposed. Drive the game from the console (`__game.StateManager.switch("play", {mode: "endless"})`, then loops of `StateManager.update(1/60)`), and override `love.getGameMousePosition` to steer. To render a frame at native size, call `love.graphics.setCanvas(c)` + `StateManager.draw()` on a 360×480 `love.graphics.newCanvas`. Reading it back with `getImageData` and comparing against the palette is a quick antialiasing check: gameplay frames have zero off-palette pixels, and only the translucent UI overlays blend.

## Common tasks

**Add a sprite:** add `name: sprite(ox, oy, [...rows])` to the right file in `gfx/sprites/` (or a new file merged in `index.ts`). Render the contact sheet, then call `draw_sprite("name", x, y)`.

**Recolor a variant:** define a `Swap` and pass it to `draw_sprite`. Add it to `SPRITE_VARIANTS` so it shows up on the contact sheet.

**Add a palette color:** add a single-character key to `PALETTE`, re-run `npm run title` (the title is quantized against the whole palette), and update the table above.

**Add a particle type:** add a `TYPES` entry in `systems/particles.ts` that includes a palette `key`.
