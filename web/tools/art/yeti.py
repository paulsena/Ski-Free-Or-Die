import sys, math; sys.path.insert(0, sys.argv[1])
from px import *
W, H = 46, 52
AX, AY = 23, 28

def fur(dx, dy):
    v = dx*0.7 + dy*0.8
    return 'W' if v < 0.15 else ('s' if v < 0.75 else 'b')

def yeti(arm_l, arm_r, leg_l, leg_r, lunge=False):
    """arm_*: vertical shoulder swing offset (neg = raised); leg_*: stride offset."""
    y = Px(W, H)
    # legs + feet
    for lx, d in ((17, leg_l), (29, leg_r)):
        y.ellipse(lx+0.5, 41+d, 4.5, 6, 'W', fur)
        y.ellipse(lx+0.5, 46+d, 5.5, 2.5, 's', lambda dx, dy: 's' if dy < 0.2 else 'b')
        for i in (-2, 0, 2): y.put(lx+i, 48+d, 'r')       # toe claws
    # body
    y.ellipse(23.5, 30, 12.5, 13, 'W', fur)
    # belly / chest fur tufts
    for (x, yy) in ((19, 26), (22, 29), (26, 25), (20, 33), (25, 34), (28, 30), (17, 30)):
        y.put(x, yy, 's'); y.put(x+1, yy+1, 's')
    # arms (drawn over the body edge), claws at the end
    if lunge:
        arms = ((7, 13, -1), (39, 13, 1))   # raised wide, reaching
    else:
        arms = ((9, 28+arm_l, -1), (37, 28+arm_r, 1))
    for (ax, ay, side) in arms:
        y.ellipse(ax+0.5, ay, 4.5, 8.5, 'W', fur)
        for t in (-5, -1, 3):                  # fur tufts on the outer edge
            y.put(ax + side*5, ay + t, 'W' if side < 0 else 's')
        cy = ay + (-9 if lunge else 8)
        for i in (-2, 0, 2):
            y.put(ax+i, cy, 'r'); y.put(ax+i, cy + (-1 if lunge else 1), 'r')
    # head
    y.ellipse(23.5, 13, 9.5, 9.5, 'W', fur)
    # face mask (shaded) so the face reads against the fur
    y.ellipse(23.5, 14, 7, 5.5, 's', lambda dx, dy: 's' if dx*0.7+dy*0.8 < 0.6 else 'b')
    # brow ridge (angry V) in blue-gray
    for i in range(4):
        y.put(17+i, 9+i//2, 'b'); y.put(29-i, 9+i//2, 'b')
    # eyes: glowing red with dark pupils
    for ex in (18, 27):
        y.rect(ex, 11, 3, 2, 'E'); y.put(ex+1, 12, 'K')
    # mouth with fangs
    mw = 5 if lunge else 4
    mh = 4 if lunge else 2
    y.rect(23-mw, 16, mw*2+1, mh+1, 'e')
    y.put(23-mw+1, 16, 'W'); y.put(23+mw-1, 16, 'W')
    y.put(23-mw+1, 17, 'W'); y.put(23+mw-1, 17, 'W')
    if lunge: y.put(23-mw+1, 16+mh, 'W'); y.put(23+mw-1, 16+mh, 'W')
    # horns of fur on top of the head
    y.put(19, 3, 'W'); y.put(28, 3, 'W'); y.put(23, 2, 'W'); y.put(24, 3, 's')
    # dither the shading bands (1px checker on the W/s and s/b borders)
    g = [r[:] for r in y.g]
    for yy in range(H):
        for xx in range(W):
            k = g[yy][xx]
            nxt = {'W': 's', 's': 'b'}.get(k)
            if nxt and (xx + yy) % 2 == 0 and nxt in (y.get(xx+1, yy), y.get(xx, yy+1)):
                y.g[yy][xx] = nxt
    y.outline('K', inside='WsbEerK')
    p = Px(W, H)
    p.ellipse(24.5, 49.5, 15, 2.5, 's')   # ground shadow
    for yy in range(H):
        for xx in range(W):
            if y.g[yy][xx] != '.': p.g[yy][xx] = y.g[yy][xx]
    return p.rows()

def trim(rows, ax, ay):
    top = next(i for i, r in enumerate(rows) if r.strip('.'))
    bot = max(i for i, r in enumerate(rows) if r.strip('.'))
    cols = [i for i in range(len(rows[0])) if any(r[i] != '.' for r in rows)]
    l, rgt = min(cols), max(cols)
    return [r[l:rgt+1] for r in rows[top:bot+1]], ax-l, ay-top

frames = [
  ('yeti_run_1', yeti(-4, 3, 1, -1), 'Run cycle: 4 frames (left arm up / mid / right arm up / mid) with alternating stride'),
  ('yeti_run_2', yeti(0, 0, 0, 0), ''),
  ('yeti_run_3', yeti(3, -4, -1, 1), ''),
  ('yeti_lunge_1', yeti(0, 0, 0, 0, lunge=True), 'Lunge: arms raised, jaws open (2 frames)'),
  ('yeti_lunge_2', yeti(0, 0, -1, -1, lunge=True), ''),
]
out = []
for name, rows, c in frames:
    rows, ox, oy = trim(rows, AX, AY)
    out.append(emit(name, ox, oy, rows, c))
# run_4 reuses run_2 (mid pose); see YETI_RUN_FRAMES in entities/yeti.ts
src = '''// src/gfx/sprites/yeti.ts
// Yeti sprites. Anchor = yeti draw position (body center).
// Generated from a pixel-canvas script (fur ellipses + face details, outlined), then hand-tuned.

import { sprite } from "../sprite_def";

const YETI_SPRITES = {
''' + ''.join(out) + '''};

export default YETI_SPRITES;
'''
open(sys.argv[2], 'w').write(src)
print('ok')
