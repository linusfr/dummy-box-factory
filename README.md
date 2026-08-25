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
| Runner | Anarch, Criminal, Shaper | 40 + ID | 78 × **30.5** × 100 mm |
| Corp | Haas-Bioroid, Jinteki, NBN, Weyland | 44 + ID | 78 × **32.6** × 100 mm |

Depth is `cards × per-card thickness + 1.5 mm slack + walls`. Sleeves decide the
rest — there's nearly 20 mm between bare and double-sleeved:

| `card_sleeving` | mm/card | 45-card corp box |
|---|---|---|
| `none` | 0.31 | 78 × 23.0 × 100 mm |
| `single` *(default)* | 0.525 | 78 × 32.6 × 100 mm |
| `double` | 0.72 | 78 × 41.4 × 100 mm |

Sleeve brands vary. Stand a known stack on edge, measure it, edit the row.

## Jack in

```bash
nix-shell                    # or: direnv allow
just build                   # all seven plates into files/
just build 50                # ...at 50 cards each
just build-one jinteki 50    # ...or just the one
just sleeving=double build   # ...for double-sleeved decks
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

## New emblems

Add a row to `faction_table` and drop a line-segments-only DXF into
`src/emblems/`. Hand-trace it in Inkscape
([tutorial](http://repraprip.blogspot.com/2011/05/inkscape-to-openscad-dxf-tutorial.html)),
or convert a filled SVG:

```bash
python3 src/svg2dxf.py emblem.svg src/emblems/my_emblem.dxf 76
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
| `src/emblems/` | A DXF per faction, plus the SVG sources |
| `files/` | Exported print plates |
| `out/` | Custom builds; gitignored |
| `images/renders/` | A render per faction |

`just build` only rewrites plates whose geometry actually changed, so rebuilds
leave the tree clean.

`*_handtraced_original.*` and `files/deckbox_generic.stl` are Austin's own work,
kept verbatim and never regenerated. The `generic` row in `faction_table` builds
an emblem-less box at today's settings, and scales like any faction — a plain
`just build` skips it so his original survives.

## Development

```bash
just hooks-install
just ci
```

[Conventional commits](https://www.conventionalcommits.org/), enforced by
commitizen. Pushes to `main` cut a
[semantic release](https://github.com/go-semantic-release/semantic-release) with
all seven STLs attached.

## Credits

- Design: Thingiverse user **Austin**, [thing:39997](https://www.thingiverse.com/thing:39997) (CC BY-SA)
- Emblems: [Netrunner-Icon-Font](https://github.com/MWDelaney/Netrunner-Icon-Font) by Michael W. Delaney (MIT)

See [LICENSE](LICENSE). *Android: Netrunner* and the faction logos belong to
their rights holders — print these for your own shelf, not for sale.
