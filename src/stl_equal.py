#!/usr/bin/env python3
"""Compare two ASCII STL files by geometry rather than by bytes.

OpenSCAD does not emit facets in a stable order between runs, so two exports of
an identical model routinely differ byte-for-byte. Committing the exports would
therefore show every plate as modified after any rebuild, and a byte-level "are
the STLs up to date" check in CI would fail on noise. This compares the facets
as an order-independent multiset instead.

Exits 0 when the two meshes are the same shape, 1 when they are not.
"""

import sys


def facets(path):
    """Read an ASCII STL into a canonical, order-independent list of facets."""
    out, current = [], []
    with open(path) as handle:
        for line in handle:
            stripped = line.strip()
            if stripped.startswith("facet normal"):
                current = [stripped]
            elif stripped.startswith("vertex"):
                current.append(stripped)
            elif stripped == "endfacet":
                # sorting the vertices makes the comparison blind to which
                # corner of the triangle the exporter happened to start at
                out.append(current[0] + "|" + "|".join(sorted(current[1:])))
    return sorted(out)


def main():
    if len(sys.argv) != 3:
        sys.exit("usage: stl_equal.py A.stl B.stl")

    left, right = sys.argv[1], sys.argv[2]
    a, b = facets(left), facets(right)

    if a == b:
        print(f"identical geometry ({len(a)} facets)")
        return 0

    print(f"geometry differs: {len(a)} facets in {left}, {len(b)} in {right}")
    only_a = len(set(a) - set(b))
    only_b = len(set(b) - set(a))
    print(f"  {only_a} facets only in {left}, {only_b} only in {right}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
