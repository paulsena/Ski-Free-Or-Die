# Lua → TypeScript porting conventions

The web build in `web/` is a faithful port of the LÖVE game in the repo root (`src/`, `main.lua`).
Every Lua module `src/<dir>/<name>.lua` becomes `web/src/<dir>/<name>.ts`, with the same name and the same structure.

## Already ported (use these as style references)
- `web/src/platform/love.ts`: LÖVE API shim. Import it as `import love from "../platform/love"` and call
  `love.graphics.*`, `love.keyboard.isDown`, `love.mouse.isDown`, `love.timer.getTime`,
  `love.audio.newSource`, `love.sound.newSoundData`, `love.filesystem.*`, `love.getGameMousePosition()`
  exactly like the Lua code does. Colors are arrays `[r,g,b,a]` in 0..1, the same as Lua tables.
- `web/src/colors.ts`, `web/src/core/config.ts`, `web/src/core/state_manager.ts`
- `web/src/lib/seeded_random.ts`, `web/src/lib/utils.ts`, `web/src/lib/camera.ts`
- `web/src/main.ts`

## Rules
1. **Names stay the same.** Keep snake_case for functions, methods, fields and locals, and PascalCase for modules, exactly as in the Lua. Keep the comments and section banners.
2. **Module shapes:**
   - A Lua "class" (`X.new(...)` plus `setmetatable(self, {__index = X})`) becomes `export default class X` with a constructor and a `static new(...)` that returns `new X(...)`. Instance methods `X:foo()` become class methods. Module constants/functions `X.FOO`/`X.bar()` become `static` members. Example: `web/src/lib/camera.ts`.
   - A plain table of functions or a singleton becomes `const X = { ... }; export default X;` (example: `web/src/lib/utils.ts`), or a class with static members when it has a lot of module-level state.
   - A state module (`src/states/*.lua`, table with `:enter/:update/:draw/...`) becomes a `const XState = { ... }` object with methods that use `this`, typed loosely (`[key: string]: any`), and is default-exported.
   - Module-local `local` variables become module-level `let`/`const`.
3. **Multiple return values** become tuples: `return a, b` → `return [a, b]`, and `local a, b = f()` → `const [a, b] = f()`.
4. **Arrays are 0-based.** Lua `t[1]` is `t[0]` and `#t` is `t.length`. Rewrite `for i = 1, #t` and `ipairs` carefully, and watch any arithmetic on indices.
   **The RNG must make exactly the same draws in the same order.** `rng.random_int(1, n)` still returns 1..n, so subtract 1 when you use it as an index. `rng.choose()` and `rng.shuffle()` already handle this.
   Never add, remove or reorder RNG calls.
5. **Lua semantics to watch for:**
   - `%` in Lua is floored modulo. Use `a - Math.floor(a/b)*b` when an operand can be negative.
   - `nil`/`false` are falsy, but `0` and `""` are **truthy** in Lua. Translate `x or default` as `x ?? default` when x can be 0 or "".
   - `math.random()` → `Math.random()`, `math.random(n)` → `1 + Math.floor(Math.random()*n)`, `math.random(a,b)` → `a + Math.floor(Math.random()*(b-a+1))`.
   - `string.format("%02d", x)` → `String(x).padStart(2, "0")`, `%.1f` → `x.toFixed(1)`, `string.rep` → `"".repeat`, `#s` → `s.length`, `s:sub(i,j)` → `s.substring(i-1, j)`, `s:upper()` → `toUpperCase()`.
   - `unpack(t)` → spread `...t`. `pairs` over string-keyed tables → `for (const k in obj)` (insertion order).
   - `love.graphics.polygon("fill", x1, y1, ...)` keeps the same varargs form; a table argument also works.
6. **Imports:** `require("src.foo.bar")` → `import Bar from "../foo/bar"` (relative path). Images must be listed in `IMAGES` in `web/src/main.ts`, and paths drop the `assets/` prefix (`assets/images/x.png` → `images/x.png`).
7. **Types:** use `strict` mode, but keep it practical. `any` is fine for loosely shaped tables. Don't redesign anything: this is a faithful port, not a refactor. Don't change game behaviour, tuning values or visuals.
8. **Tests:** `test/test_*.lua` becomes `web/test/<name>.test.ts` using Vitest (`import { describe, it, expect } from "vitest"`).
9. **Checks before you finish:** `cd web && npx tsc --noEmit` reports no errors in the files you wrote (errors about modules that aren't ported yet are expected), and `npx vitest run` passes.
