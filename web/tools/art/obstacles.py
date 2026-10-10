import sys; sys.path.insert(0, sys.argv[1])
from px import *
out = []

# ---------------- Trees (hand-authored, centered) ----------------
small = center(15, [
 "g",
 "gjg",
 "gjGgg",
 "gjjGg",
 "gjjGGgg",
 "gjjGGGGgg",
 "ggGgGgg",
 "gjjgGGGgg",
 "gjjGGGGGGgg",
 "gjjjGGGGGGggg",
 "gjgjgGgGgGggg",
 "ggGGgGGgg",
 "gjjgGGGGGgg",
 "gjjjGGGGGGggg",
 "gjjjGGGGGGGGggg",
 "gjgjgGgGgGgGggg",
]) + [
 "......nNw......",
 "......nNws.....",
 "....ssnNwsss...",
 ".....ssssss....",
]
small_snowy = center(15, [
 "b",
 "bWb",
 "bWWsb",
 "gWWsg",
 "gjWWsgg",
 "gjjGGGGgg",
 "bWWsWsb",
 "bWWWsGsgg",
 "gjjjsGGGGgg",
 "gjjjGGGGGGggg",
 "gjgjgGgGgGggg",
 "bWWWsWsgb",
 "bWWWWsGsGgg",
 "gjjjjGGGGGggg",
 "gjjjGGGGGGGGggg",
 "gjgjgGgGgGgGggg",
]) + small[-4:]
out.append(emit('small_tree', 7, 12, small, 'Small pine (hitbox 18x24)'))
out.append(emit('small_tree_snowy', 7, 12, small_snowy))

large_rows = [
 "g","gjg","gjGgg","gjjGg","gjjGGgg","gjjGGGGgg",
 "ggGgGgg","gjjgGGGgg","gjjGGGGGGgg","gjjjGGGGGGggg","gjjjGGGGgGGgggg"[:13] if False else "gjjjGGGgGGggg","gjgjgGgGgGgGggg",
 "ggGGgGgGGgg","gjjgGGGGGGGgg","gjjjGGGGGGGGggg","gjjjGGGGgGGGGGggg","gjjjjGGGGGGgGGGGggg","gjgjgGgGgGgGgGgGggg",
 "ggGGgGGgGGgGGgg","gjjgGGGGGGGGGGGgg","gjjjGGGGGGGGGGGGggg","gjjjjGGGGGgGGGGGGGggg","gjjjjGGGGGGGGGGGGGGGggg","gjjjjGGGGgGGGGGGGGGgGGggg","gjgjgjgGgGgGgGgGgGgGggggg",
]
snow_rows = list(large_rows)
snow_rows[0:6] = ["b","bWb","bWWsb","gWWsg","gjWWsgg","gjjGGGGgg"]
snow_rows[6:8] = ["bWWsWsb","bWWWsGsgg"]
snow_rows[12:14] = ["bWWWsWsWsgb","bWWWWsGsGGsgg"]
snow_rows[18:20] = ["bWWWWsWWsWsWsgb","bWWWWWsGGsGGsGsgg"]
trunk = [
 "..........nNNw...........",
 "..........nNNw...........",
 "..........nNNws..........",
 "..........nNNwss.........",
 "......ssssnNNwsssss......",
 ".....sssssssssssssss.....",
 ".......sssssssssss.......",
]
large = center(25, large_rows) + trunk
large_snowy = center(25, snow_rows) + trunk
out.append(emit('large_tree', 12, 19, large, 'Large pine (hitbox 28x40)'))
out.append(emit('large_tree_snowy', 12, 19, large_snowy))

# ---------------- Rock (hitbox 24x18) ----------------
def rpad(W, rows): return [r + '.'*(W-len(r)) for r in rows]
rock = rpad(22, [
 "......bbbbbb",
 "....bbWWWWWWbb",
 "...bWWWWWWWWsWb",
 "..rLWWWWWWsWsrrr",
 ".rLLLWWWsLLrRRRrr",
 ".rLLLLLLLLrRRRRRrr",
 "rLLLLLLLLLrRRRRRRRr",
 "rLLLLLLLLrRRRRRRRRrr",
 "rLLLLLLLrRRRRRRRRrrrr",
 "rRLLLLLrRRRRRRRRrrrrr",
 ".rRRRRrRRRRRRRRrrrrr",
 "..rrrrrrrrrrrrrrrrrss",
 "...sssssssssssssssss",
 "......ssssssssssss",
])
out.append(emit('rock', 10, 7, rock, 'Rock with snow cap (hitbox 24x18)'))

# ---------------- Snow mound (hitbox 30x12) ----------------
mound = rpad(28, [
 "..........ssssssss",
 ".......sssWWWWWWWWsss",
 ".....ssWWWWWWWWWWWWWSss",
 "...ssWWWWWWWWWWWWWSSSSss",
 "..sWWWWWWWWWWWWSSSSSSSSss",
 ".sWWWWWWWWWSSSSSSSSSSSssss",
 ".sSSSSSSSSSSSSSSSSSSssssbb",
 "bsSSSSSSSSSSSSSSsssssssbbb",
 ".bbsssssssssssssssssbbbbbs",
 "..bbbbbbbbbbbbbbbbbbbbbsss",
 "....sssssssssssssssssssss",
])
out.append(emit('snow_mound', 13, 6, mound, 'Snow mound (hitbox 30x12)'))

# ---------------- Cabin (hitbox 42x36) ----------------
W, H = 37, 34
p = Px(W, H)
cx = 18
p.ellipse(20.5, 30.5, 17, 3.5, 's')                   # shadow
# body (logs)
bx0, bx1, by0, by1 = 6, 30, 15, 30
for y in range(by0, by1+1):
    for x in range(bx0, bx1+1):
        k = 'N'
        if (y - by0) % 3 == 2: k = 'n'
        if (y - by0) % 3 == 0: k = 'w'
        p.put(x, y, k)
p.vline(bx0, by0, by1, 'n'); p.vline(bx1, by0, by1, 'n')
p.hline(bx0, bx1, by1, 'n')
# log ends sticking out
for y in range(by0+1, by1, 3):
    p.put(bx0-1, y, 'w'); p.put(bx1+1, y, 'w')
# door
p.rect(15, 21, 7, 10, 'y'); p.rect(16, 22, 5, 9, 'Y'); p.put(19, 26, 'y'); p.put(16, 22, 'W')
# windows
for wx in (8, 24):
    p.rect(wx, 19, 5, 5, 'n'); p.rect(wx+1, 20, 3, 3, 'C'); p.put(wx+1, 20, 'W'); p.put(wx+3, 22, 'c')
# chimney
p.rect(24, 3, 4, 8, 'R'); p.vline(27, 3, 10, 'r'); p.vline(24, 3, 10, 'L')
# roof: apex row 2, eaves row 15
for y in range(2, 16):
    hw = round((y-2) * 17/13) + 1
    for x in range(cx-hw, cx+hw+1):
        d = min(x-(cx-hw), (cx+hw)-x)
        k = 'W' if d >= 2 else ('P' if d == 1 else 'p')
        if k == 'W' and x > cx + hw//3: k = 's' if (x+y) % 7 == 0 else 'W'
        p.put(x, y, k)
p.hline(cx-17, cx+17, 15, 'p')
p.hline(cx-16, cx+16, 14, 'P')
p.put(cx, 1, 'p')
# chimney pokes through the roof, snow cap
p.rect(24, 3, 4, 5, 'R'); p.vline(27, 3, 7, 'r'); p.vline(24, 3, 7, 'L')
p.hline(23, 28, 2, 'W'); p.hline(24, 27, 1, 'W')
# snow drips from the eaves
for x, l in ((3, 1), (4, 2), (9, 1), (27, 2), (28, 1), (33, 1)):
    for j in range(l): p.put(x, 16+j, 'W')
# roof snow ridge shading
for y in range(4, 14):
    p.put(cx + (y-2)//2 + 2, y, 's') if (y % 3 == 0) else None
out.append(emit('cabin', 18, 18, p.rows(), 'Log cabin, roof color P/p/l is palette-swapped per variant (hitbox 42x36)'))

src = '''// src/gfx/sprites/obstacles.ts
// Obstacle sprites. Authored at native resolution; anchor = obstacle (x, y), the hitbox center.
// Generated from a pixel-canvas script, then hand-tuned. Keys: see gfx/palette.ts.

import { sprite } from "../sprite_def";

const OBSTACLE_SPRITES = {
''' + ''.join(out) + '''};

export default OBSTACLE_SPRITES;
'''
open(sys.argv[2], 'w').write(src)
print('ok')
