# Sprite bootstrap scripts

These Python scripts generated the first versions of the sprite grids in `src/gfx/sprites/`
(`px.py` is a tiny integer pixel canvas; the others compose obstacles, skier poses and yeti frames).
**The TypeScript grids are the source of truth.** Hand-edit them directly. Re-running a script
overwrites its file, so only do that if you're redoing a sprite family from scratch:

    python3 tools/art/skier.py tools/art src/gfx/sprites/skier.ts
    python3 tools/art/yeti.py tools/art src/gfx/sprites/yeti.ts
    python3 tools/art/obstacles.py tools/art src/gfx/sprites/obstacles.ts

Then review with `npm run sprites` (writes `tools/out/contact-sheet.png`).
