#!/usr/bin/env python3
"""Convert filled SVG paths into a line-segments-only DXF that OpenSCAD can import().

Mirrors what the Inkscape "Desktop Cutting Plotter" DXF export produces for the
original hand-traced emblems: every contour becomes a closed chain of LINE
entities on layer 0, y-axis flipped out of SVG's y-down space, and the whole
drawing normalised into a bbox centred on the origin.
"""

import math
import re
import sys

NUM = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
CMD = re.compile(r"([MmLlHhVvCcSsQqTtAaZz])")


def tokenize(d):
    """Split a path 'd' attribute into (command, [numbers]) pairs."""
    out = []
    for chunk in (c for c in CMD.split(d) if c.strip()):
        if CMD.fullmatch(chunk):
            out.append([chunk, []])
        elif out:
            out[-1][1].extend(float(n) for n in NUM.findall(chunk))
    return out


def flatten_cubic(p0, p1, p2, p3, tol, depth=0):
    """Recursively subdivide a cubic bezier until it is flat within tol."""
    if depth >= 16:
        return [p3]
    # distance of the two control points from the chord p0->p3
    dx, dy = p3[0] - p0[0], p3[1] - p0[1]
    chord = math.hypot(dx, dy)
    if chord < 1e-12:
        d1 = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        d2 = math.hypot(p2[0] - p0[0], p2[1] - p0[1])
        flat = max(d1, d2)
    else:
        d1 = abs((p1[0] - p0[0]) * dy - (p1[1] - p0[1]) * dx) / chord
        d2 = abs((p2[0] - p0[0]) * dy - (p2[1] - p0[1]) * dx) / chord
        flat = max(d1, d2)
    if flat <= tol:
        return [p3]

    def mid(a, b):
        return ((a[0] + b[0]) / 2.0, (a[1] + b[1]) / 2.0)

    p01, p12, p23 = mid(p0, p1), mid(p1, p2), mid(p2, p3)
    p012, p123 = mid(p01, p12), mid(p12, p23)
    p0123 = mid(p012, p123)
    return flatten_cubic(p0, p01, p012, p0123, tol, depth + 1) + flatten_cubic(
        p0123, p123, p23, p3, tol, depth + 1
    )


def path_to_contours(d, tol):
    """Flatten one 'd' attribute into a list of point-lists (one per subpath)."""
    contours, pts = [], []
    cur = start = (0.0, 0.0)
    prev_cubic_ctrl = prev_quad_ctrl = None
    prev_cmd = ""

    def emit():
        if len(pts) > 2:
            contours.append(list(pts))

    for cmd, a in tokenize(d):
        rel = cmd.islower()
        up = cmd.upper()

        if up == "Z":
            if pts:
                pts.append(start)
                emit()
            pts.clear()
            cur = start
            prev_cubic_ctrl = prev_quad_ctrl = None
            prev_cmd = up
            continue

        # argument counts per command repetition
        step = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7}[
            up
        ]
        for i in range(0, len(a) - step + 1, step):
            seg = a[i : i + step]
            if up == "M":
                if i == 0:
                    emit()
                    pts.clear()
                    cur = (
                        (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    )
                    start = cur
                    pts.append(cur)
                else:  # implicit lineto after the first moveto pair
                    cur = (
                        (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    )
                    pts.append(cur)
            elif up == "L":
                cur = (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                pts.append(cur)
            elif up == "H":
                cur = (cur[0] + seg[0], cur[1]) if rel else (seg[0], cur[1])
                pts.append(cur)
            elif up == "V":
                cur = (cur[0], cur[1] + seg[0]) if rel else (cur[0], seg[0])
                pts.append(cur)
            elif up in ("C", "S"):
                if up == "C":
                    c1 = (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    c2 = (cur[0] + seg[2], cur[1] + seg[3]) if rel else (seg[2], seg[3])
                    end = (
                        (cur[0] + seg[4], cur[1] + seg[5]) if rel else (seg[4], seg[5])
                    )
                else:
                    # reflect the previous cubic's second control point
                    if prev_cmd in ("C", "S") and prev_cubic_ctrl:
                        c1 = (
                            2 * cur[0] - prev_cubic_ctrl[0],
                            2 * cur[1] - prev_cubic_ctrl[1],
                        )
                    else:
                        c1 = cur
                    c2 = (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    end = (
                        (cur[0] + seg[2], cur[1] + seg[3]) if rel else (seg[2], seg[3])
                    )
                pts.extend(flatten_cubic(cur, c1, c2, end, tol))
                prev_cubic_ctrl, prev_quad_ctrl = c2, None
                cur = end
                prev_cmd = up
                continue
            elif up in ("Q", "T"):
                if up == "Q":
                    q = (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    end = (
                        (cur[0] + seg[2], cur[1] + seg[3]) if rel else (seg[2], seg[3])
                    )
                else:
                    if prev_cmd in ("Q", "T") and prev_quad_ctrl:
                        q = (
                            2 * cur[0] - prev_quad_ctrl[0],
                            2 * cur[1] - prev_quad_ctrl[1],
                        )
                    else:
                        q = cur
                    end = (
                        (cur[0] + seg[0], cur[1] + seg[1]) if rel else (seg[0], seg[1])
                    )
                # promote the quadratic to an equivalent cubic
                c1 = (
                    cur[0] + 2.0 / 3 * (q[0] - cur[0]),
                    cur[1] + 2.0 / 3 * (q[1] - cur[1]),
                )
                c2 = (
                    end[0] + 2.0 / 3 * (q[0] - end[0]),
                    end[1] + 2.0 / 3 * (q[1] - end[1]),
                )
                pts.extend(flatten_cubic(cur, c1, c2, end, tol))
                prev_quad_ctrl, prev_cubic_ctrl = q, None
                cur = end
                prev_cmd = up
                continue
            else:
                raise SystemExit("elliptical arcs are not supported")
            prev_cubic_ctrl = prev_quad_ctrl = None
            prev_cmd = up
    emit()
    return contours


def dedupe(pts, eps):
    """Drop consecutive duplicate points that would become zero-length lines."""
    out = [pts[0]]
    for p in pts[1:]:
        if math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > eps:
            out.append(p)
    return out


def write_dxf(contours, path):
    body = ["0", "SECTION", "2", "ENTITIES"]
    for c in contours:
        for (x1, y1), (x2, y2) in zip(c, c[1:]):
            body += [
                "0",
                "LINE",
                "8",
                "0",
                "10",
                f"{x1:.6f}",
                "20",
                f"{y1:.6f}",
                "30",
                "0.0",
                "11",
                f"{x2:.6f}",
                "21",
                f"{y2:.6f}",
                "31",
                "0.0",
            ]
    body += ["0", "ENDSEC", "0", "EOF", ""]
    open(path, "w").write("\n".join(body))


def convert(svg_path, dxf_path, target_size=76.0, skip_paths=()):
    svg = open(svg_path).read()
    ds = re.findall(r'<path[^>]*?\sd="([^"]*)"', svg, re.S)
    ds = [d for i, d in enumerate(ds) if i not in skip_paths]
    if not ds:
        raise SystemExit(f"no <path> found in {svg_path}")
    if re.search(r"transform\s*=", svg):
        raise SystemExit(f"{svg_path} uses transforms, which are not handled")

    # Flatten in source units with a tolerance fine enough that, once scaled up
    # to target_size, the facets stay well under one extrusion width.
    contours = []
    for d in ds:
        contours += path_to_contours(d, tol=0.004)
    if not contours:
        raise SystemExit(f"no closed contours in {svg_path}")

    xs = [p[0] for c in contours for p in c]
    ys = [p[1] for c in contours for p in c]
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    scale = target_size / max(w, h)
    cx, cy = (max(xs) + min(xs)) / 2.0, (max(ys) + min(ys)) / 2.0

    # scale about the centre and flip y (SVG is y-down, DXF/OpenSCAD is y-up)
    out = []
    for c in contours:
        c = [((p[0] - cx) * scale, -(p[1] - cy) * scale) for p in c]
        c = dedupe(c, eps=1e-4)
        if len(c) < 3:
            continue
        if math.hypot(c[0][0] - c[-1][0], c[0][1] - c[-1][1]) > 1e-9:
            c.append(c[0])  # force an exactly-closed loop for OpenSCAD
        out.append(c)

    write_dxf(out, dxf_path)
    segs = sum(len(c) - 1 for c in out)
    print(
        f"{dxf_path}: {len(out)} contours, {segs} lines, "
        f"{w * scale:.2f} x {h * scale:.2f} units"
    )


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    size = float(sys.argv[3]) if len(sys.argv) > 3 else 76.0
    skip = tuple(int(i) for i in sys.argv[4].split(",")) if len(sys.argv) > 4 else ()
    convert(src, dst, size, skip)
