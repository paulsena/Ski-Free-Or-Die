# Tiny integer pixel canvas for authoring palette sprites.
class Px:
    def __init__(s, W, H): s.W, s.H = W, H; s.g = [['.']*W for _ in range(H)]
    def put(s, x, y, k):
        if 0 <= x < s.W and 0 <= y < s.H: s.g[y][x] = k
    def get(s, x, y): return s.g[y][x] if 0 <= x < s.W and 0 <= y < s.H else '.'
    def rect(s, x, y, w, h, k):
        for j in range(h):
            for i in range(w): s.put(x+i, y+j, k)
    def hline(s, x0, x1, y, k):
        for x in range(x0, x1+1): s.put(x, y, k)
    def vline(s, x, y0, y1, k):
        for y in range(y0, y1+1): s.put(x, y, k)
    def ellipse(s, cx, cy, rx, ry, k, shade=None):
        for y in range(s.H):
            for x in range(s.W):
                dx, dy = (x+0.5-cx)/rx, (y+0.5-cy)/ry
                if dx*dx+dy*dy <= 1:
                    s.put(x, y, shade(dx, dy) if shade else k)
    def outline(s, k, inside=None):
        # 1px outline around non-transparent pixels (4-neighbour)
        add = []
        for y in range(s.H):
            for x in range(s.W):
                if s.g[y][x] == '.' and any((s.get(x+a, y+b) in inside) if inside else (s.get(x+a, y+b) not in '.s') for a, b in ((1,0),(-1,0),(0,1),(0,-1))):
                    add.append((x, y))
        for x, y in add: s.put(x, y, k)
    def stamp(s, x, y, rows):
        for j, r in enumerate(rows):
            for i, k in enumerate(r):
                if k != '.': s.put(x+i, y+j, k)
    def rows(s): return [''.join(r) for r in s.g]
def center(W, rows):
    out = []
    for r in rows:
        assert (W-len(r)) % 2 == 0 and len(r) <= W, (r, len(r), W)
        p = (W-len(r))//2
        out.append('.'*p + r + '.'*p)
    return out
def emit(name, ox, oy, rows, comment=''):
    w = len(rows[0])
    for r in rows: assert len(r) == w, (name, r)
    s = ('  // %s\n' % comment) if comment else ''
    s += '  %s: sprite(%d, %d, [\n' % (name, ox, oy)
    for r in rows: s += '    "%s",\n' % r
    return s + '  ]),\n'
