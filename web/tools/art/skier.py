import sys, math; sys.path.insert(0, sys.argv[1])
from px import *
W, H = 25, 30
AX, AY = 12, 15          # anchor (entity x, y)
FEET = (12, 18)          # where the boots meet the skis

BODY_FRONT = [
 "...KKKKK...",
 "..KYYYYyK..",
 ".KYWYYYYyK.",
 ".KKKKKKKKK.",
 ".KCWCKCWCK.",
 ".KFFFFFFfK.",
 "..KKFFfKK..",
 ".KlPPPPPpK.",
 "KlPPYYYPPpK",
 "KlPPPPPPPpK",
 "KPKlPPPPKpK",
 "KYKlPPPpKYK",
 ".K.KcCCcK..",
 "...KcCKcK..",
 "...KcCKcK..",
 "...KKK.KK..",
]
BODY_34 = [  # three-quarter view, facing right/downhill
 "...KKKKK...",
 "..KYYYYyK..",
 ".KYWYYYYyK.",
 ".KKKKKKKKK.",
 ".KFKCWCWCK.",
 ".KFFFFFFfK.",
 "..KKFFfKK..",
 ".KlPPPPPpK.",
 "KlPPPYYYPpK",
 "KlPPPPPPPpK",
 "KPKlPPPPpKK",
 "KYKlPPPpKYK",
 ".K.KcCCcK..",
 "...KcCKcK..",
 "...KcCcKK..",
 "...KKKKK...",
]
BODY_SIDE = [  # profile, facing right
 "..KKKKK..",
 ".KYYYYyK.",
 "KYWYYYYyK",
 "KKKKKKKKK",
 ".KFFKCWCK",
 ".KFFFFFfK",
 "..KKFfKK.",
 ".KlPPPpK.",
 "KlPPYPPpK",
 "KlPPPYPPK",
 "KlPPPPKYK",
 ".KPPPpK..",
 ".KcCCcK..",
 "..KcCcK..",
 "..KcCCK..",
 "..KKKKK..",
]
TUCK_FRONT = [
 "...KKKKK...",
 "..KYYYYyK..",
 ".KYWYYYYyK.",
 ".KKKKKKKKK.",
 ".KCWCKCWCK.",
 "KlKFFFFfKpK",
 "KlPKKKKKPpK",
 "KYlPPYPPpYK",
 ".KlPPPPPpK.",
 ".KcCCCCCcK.",
 "..KKK.KKK..",
]
TUCK_34 = [
 "...KKKKK...",
 "..KYYYYyK..",
 ".KYWYYYYyK.",
 ".KKKKKKKKK.",
 ".KFKCWCWCK.",
 "KlKFFFFfKpK",
 "KlPKKKKKPpK",
 "KYlPPPYPpYK",
 ".KlPPPPPpK.",
 ".KcCCCCCcK.",
 "..KKKKKKK..",
]
TUCK_SIDE = [
 "..KKKKK..",
 ".KYYYYyK.",
 "KYWYYYYyK",
 "KKKKKKKKK",
 ".KFFKCWCK",
 "KlKFFFfKK",
 "KlPKKKKYK",
 "KlPPPYPPK",
 ".KcCCCcK.",
 "..KKKKK..",
]

def thick_line(p, x0, y0, x1, y1, k):
    n = int(max(abs(x1-x0), abs(y1-y0))) + 1
    pts = []
    for i in range(n+1):
        t = i/n
        x, y = round(x0+(x1-x0)*t), round(y0+(y1-y0)*t)
        if (x, y) not in pts: pts.append((x, y))
    for x, y in pts: p.put(x, y, k)
    return pts

def ski_layer(angle_deg, spread):
    """Skis as a separate layer so the K outline only wraps the skis."""
    p = Px(W, H)
    a = math.radians(angle_deg)
    dx, dy = math.sin(a), math.cos(a)        # travel direction (down = +y)
    px_, py_ = dy, -dx                        # perpendicular
    fx, fy = FEET
    for side in (-1, 1):
        ox, oy = fx + px_*spread*side, fy + py_*spread*side
        # tail 4px behind the boots, tip 8px ahead
        thick_line(p, ox-dx*4, oy-dy*4, ox+dx*8, oy+dy*8, 'C')
        # dark tip
        p.put(round(ox+dx*8), round(oy+dy*8), 'c')
    p.outline('K', inside='Cc')
    return p

def merge(dst, src):
    for y in range(H):
        for x in range(W):
            if src.g[y][x] != '.': dst.g[y][x] = src.g[y][x]

def shadow(p, angle):
    # soft shadow under the skier, offset down-right
    if abs(angle) >= 80: p.ellipse(13.5, 21.5, 11, 2.5, 's')
    else: p.ellipse(13.5, 22, 6 + abs(angle)/15, 3.5, 's')

def poles(p, pts):
    for (x0, y0, x1, y1) in pts:
        thick_line(p, x0, y0, x1, y1, 'R')
        p.put(round(x1), round(y1), 'L')

def skier(angle, body, tuck=False, flipbody=False):
    p = Px(W, H)
    shadow(p, angle)
    spread = 1.0 if (tuck or abs(angle) >= 80) else 2.0
    merge(p, ski_layer(angle, spread))
    bw = len(body[0]); bh = len(body)
    bx = FEET[0] - bw//2 + (1 if body in (BODY_SIDE, TUCK_SIDE) else 0)
    by = FEET[1] - bh + (1 if not tuck else 1)
    # poles: drawn behind the body
    gx_l, gx_r = bx + 1, bx + bw - 2
    gy = by + (11 if not tuck else 7)
    a = math.radians(angle)
    if tuck:
        poles(p, [(gx_l, gy, gx_l-5, gy-5), (gx_r, gy, gx_r+5, gy-5)])
    elif abs(angle) >= 80:
        poles(p, [(gx_r, gy-1, gx_r+5, gy+6)])
    else:
        poles(p, [(gx_l, gy, gx_l-2+math.sin(a)*3, gy+9), (gx_r, gy, gx_r+2+math.sin(a)*3, gy+9)])
    p.stamp(bx, by, body)
    return p.rows()

def crash_frame(star_phase):
    p = Px(W, H)
    p.ellipse(12.5, 19.5, 11, 3, 's')
    # skis scattered
    sk = Px(W, H)
    thick_line(sk, 3, 12, 9, 22, 'C'); thick_line(sk, 15, 23, 22, 15, 'C')
    sk.outline('K', inside='C'); merge(p, sk)
    # sprawled body lying left-to-right, head on the left
    p.stamp(3, 14, [
        ".KKKK...........",
        "KYYYyK.KKKKKKK..",
        "KYWYyKKlPPPPPpKK",
        "KCWCKKlPPYYPPPcCK",
        "KFFFKKPPPPPPPpcCK",
        ".KKKK.KKKKKKKKKK.",
    ])
    # dizzy stars circling the head
    stars = [(2, 10), (6, 8), (10, 10)] if star_phase == 0 else [(3, 8), (8, 9), (1, 11)]
    for (x, y) in stars:
        p.put(x, y, 'Y'); p.put(x-1, y, 'y'); p.put(x+1, y, 'y'); p.put(x, y-1, 'y'); p.put(x, y+1, 'y')
    return p.rows()

def trim(rows, ax, ay):
    # crop transparent borders, keep anchor
    top = next(i for i, r in enumerate(rows) if r.strip('.'))
    bot = max(i for i, r in enumerate(rows) if r.strip('.'))
    cols = [i for i in range(len(rows[0])) if any(r[i] != '.' for r in rows)]
    l, rgt = min(cols), max(cols)
    return [r[l:rgt+1] for r in rows[top:bot+1]], ax-l, ay-top

out = []
def add(name, rows, comment=''):
    rows, ox, oy = trim(rows, AX, AY)
    out.append(emit(name, ox, oy, rows, comment))

add('skier_center', skier(0, BODY_FRONT), 'Straight down (POS_CENTER). Right-facing poses are mirrored for left.')
add('skier_gentle', skier(30, BODY_34), 'Gentle turn right (POS_RIGHT)')
add('skier_sharp', skier(60, BODY_34), 'Sharp turn right (POS_FAR_RIGHT)')
add('skier_side', skier(90, BODY_SIDE), 'Full stop facing right (POS_FULL_RIGHT): side view, skis across the slope')
add('skier_center_tuck', skier(0, TUCK_FRONT, True), 'Tuck variants: crouched, skis together, poles tucked up')
add('skier_gentle_tuck', skier(30, TUCK_34, True))
add('skier_sharp_tuck', skier(60, TUCK_34, True))
add('skier_side_tuck', skier(90, TUCK_SIDE, True))
add('skier_crash_1', crash_frame(0), 'Crash: sprawled with circling stars (2 frames)')
add('skier_crash_2', crash_frame(1))

src = '''// src/gfx/sprites/skier.ts
// Skier sprites. Anchor = skier (x, y); the boots sit 3px below it.
// Generated from a pixel-canvas script (body stamps + skis drawn at each angle), then hand-tuned.

import { sprite } from "../sprite_def";

const SKIER_SPRITES = {
''' + ''.join(out) + '''};

export default SKIER_SPRITES;
'''
open(sys.argv[2], 'w').write(src)
print('ok')
