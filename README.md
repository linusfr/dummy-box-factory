# dummy-box-factory

Parametric 3D-printable deck boxes for *Android: Netrunner* — one per faction,
each only as deep as the deck it holds.

[Dummy Box](https://netrunnerdb.com/en/card/12108) stops the Corp trashing your
installed cards. This one stops your backpack doing the same.

![the Jinteki box](images/renders/deckbox_jinteki.png)

Friction-fit lid, beveled edges, hex-lattice texture, emblem raised on both
faces. Grown out of
[Austin's parametric scifi deck box](https://www.thingiverse.com/thing:39997),
which shipped one fixed size and two emblems.

## Sizes

Cards are all the same shape, so every box is 78 × 100 mm and only the depth
moves.

| Side | Factions | Deck | Box |
|---|---|---|---|
| Runner | Anarch, Criminal, Shaper | 40 + ID | 78 × **35.7** × 100 mm |
| Corp | Haas-Bioroid, Jinteki, NBN, Weyland | 44 + ID | 78 × **38.1** × 100 mm |

Depth is `cards × per-card thickness + 1.5 mm slack + walls`. Sleeves decide the
rest — there's nearly 20 mm between bare and double-sleeved:

| `card_sleeving` | mm/card | 45-card corp box | |
|---|---|---|---|
| `none` | 0.34 | 78 × 26.4 × 100 mm | **measured** |
| `single` *(default)* | 0.6 | 78 × 38.1 × 100 mm | **measured** |
| `double` | 0.72 | 78 × 43.5 × 100 mm | *estimated* |

Measured with a caliper: a bare Netrunner card is 0.34 mm, and 31 cards in
**Dragon Shield** sleeves came to 18.69 mm, so 0.603 each. Only `single` has
actually been printed and filled, though. `double` is calculated rather than
measured — double-sleeving varies a lot depending on which inner and outer you
pair.

Sleeve brands vary. Stand a known stack on edge, measure it, edit the row.

## Jack in

```bash
nix-shell                    # or: direnv allow
just build                   # all eight plates into files/
just build 50                # ...at 50 cards each
just build-one jinteki 50    # ...or just the one
just sleeving=double build   # ...for double-sleeved decks
just magnets=0 build         # ...with no magnet pockets
just sizes                   # dimensions only, nothing exported
```

Non-standard builds land in `out/` rather than `files/`; `just clean` bins them.
No nix? Put `openscad` on `$PATH`, or set `OPENSCAD=`.

Each STL is a print plate: box bottom and lid, side by side.

## Printing

**0.4 mm nozzle, 0.2 mm layers, 1 extra shell, 10% infill.**

Walls and floors are multiples of the nozzle width and layer height, so if yours
differ, edit `nozzle_width` / `layer_height` at the top of `src/deckbox.scad` and
re-export. Don't scale the STL.

Layer height is the one that bites: `floor_thickness` is 6 layers and
`sleeve_z_gap` is 4, so slicing at a height that doesn't divide them puts the
floor mid-layer.

### OrcaSlicer

Process panel on the right; both tabs show in Simple mode.

| Tab | Setting | Stock | Set to |
|---|---|---|---|
| Quality | Layer height | 0.2 mm | **0.2 mm** |
| Strength | Wall loops | 2 | **3** |
| Strength | Sparse infill density | 15% | **10%** |

Wall loops 3 *is* the "1 extra shell". Leave the shell layers alone — Orca's
stock 3 + 3 is exactly the 6 layers `floor_thickness` assumes, so floors come
out solid. *(Checked against Orca 2.4.2.)*

### Doesn't fit?

| If | Then |
|---|---|
| Lid too tight or too loose | `sleeve_xy_gap` |
| Your sleeves aren't in the table | `sleeving_table` |
| You want tokens in there too | `extra_card_slots`, ~0.5 mm each |
| You want a different capacity | card counts in `faction_table` |

Every run echoes the resulting cavity and outer size.

## Magnets

**The boxes ship with magnet pockets, sized for 3 × 2 mm discs.** Two per box —
one in the lid, one in the body — at diagonally opposite corners.

Nothing about the outside changes. 3 mm is the largest that fits inside the
existing corner without the box growing a lump: the pocket tucks between the
outer chamfer and the card cavity, the sleeve is notched 3.8 mm at those two
corners, and the lid keeps material there instead of hollowing it for the
sleeve. All of that is internal.

They hold roughly 200 g, comfortably more than a loaded box weighs. The sleeve
is still the real closure; the magnets just make it click.

Glue them in against the 0.2 mm recess, and **watch the polarity** — one flipped
magnet gives you a lid that pushes itself off. Mark the stack before you start.

### Printing without magnets

```bash
just magnets=0 build              # all of them
just magnets=0 build-one criminal # just the one
```

Those land in `out/`, so they can't overwrite the committed plates. To make it
permanent, set `magnet_diameter = 0` at the top of `src/deckbox.scad` — that
drops the pockets, the sleeve notch and the lid column together, leaving the box
exactly as it was before magnets existed.

### Bigger magnets

Anything over 3 mm needs the corners to grow into posts, which the script works
out and adds by itself:

| Ø | Corner post | Protrudes | ~Hold |
|---|---|---|---|
| 3 mm *(default)* | none | **0 mm** | ~200 g |
| 4 mm | 5.8 mm | 1.75 mm | ~250 g |
| 5 mm | 6.8 mm | 2.75 mm | ~375 g |

Thickness is nearly free — up to about 18 mm before the pocket would break
through the lid's top plate. Diameter is what costs you silhouette.

If the lid ends up too grabby with magnets *and* sleeve friction, loosen
`sleeve_xy_gap` rather than reaching for weaker magnets.

## New emblems

Add a row to `faction_table`, then drop the artwork in named for it —
`svg_sources/<faction>.svg` converts to `emblems/<faction>.dxf`, and
`just emblems` picks it up with no further wiring. Hand-trace in Inkscape
([tutorial](http://repraprip.blogspot.com/2011/05/inkscape-to-openscad-dxf-tutorial.html)),
or convert a filled SVG (paths only — `<line>` elements are ignored):

```bash
python3 src/svg2dxf.py src/emblems/svg_sources/mine.svg src/emblems/mine.dxf 76
```

The `76` normalises the longest side, so every faction shares one
`emblem_scale` of 0.7. Check it fits the hex frame — Weyland's W didn't, and
rides at 0.63.

**Then run `just check-emblems`.** Outlines that touch or overlap themselves
extrude into a non-manifold mesh, which CGAL *discards without failing the
render* — that's how two of Austin's prints came out blank. `deckbox.scad`
erode/dilates every emblem (`emblem_cleanup_epsilon`) to head it off.

## Layout

| Path | What |
|---|---|
| `src/deckbox.scad` | The generator, driven by `faction_table` |
| `src/svg2dxf.py` | Filled SVG → OpenSCAD-importable DXF |
| `src/stl_equal.py` | Compares STLs by geometry, not bytes |
| `src/emblems/` | `<faction>.dxf`, generated from `svg_sources/<faction>.svg` |
| `files/` | Exported print plates |
| `out/` | Custom builds; gitignored |
| `images/renders/` | A render per faction |

`just build` only rewrites plates whose geometry actually changed, so rebuilds
leave the tree clean.

`generic` is an eighth row in `faction_table`: the same box with no emblem, for
anyone who wants the shape without the faction.

## Development

```bash
just hooks-install
just ci
```

[Conventional commits](https://www.conventionalcommits.org/), enforced by
commitizen. Pushes to `main` cut a
[semantic release](https://github.com/go-semantic-release/semantic-release) with
every STL attached.

## Credits

- Design: Thingiverse user **Austin**, [thing:39997](https://www.thingiverse.com/thing:39997) (CC BY-SA)
- Emblems: [Netrunner-Icon-Font](https://github.com/MWDelaney/Netrunner-Icon-Font) by Michael W. Delaney (MIT)

See [LICENSE](LICENSE). *Android: Netrunner* and the faction logos belong to
their rights holders — print these for your own shelf, not for sale.
