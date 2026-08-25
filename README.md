# dummy-box-factory

Parametric 3D-printable deck boxes for *Android: Netrunner* — one per faction,
each only as deep as the deck it has to hold.

Named for [Dummy Box](https://netrunnerdb.com/en/card/12108), the Shaper
resource that stops the Corp trashing your installed cards.

Friction-fit lid, beveled edges, hexagonal lattice texture, and the faction
emblem raised on both the front and the back. Derived from
[Austin's parametric scifi deck box](https://www.thingiverse.com/thing:39997),
which shipped a single fixed size and two emblems.

![the seven boxes](images/renders/deckbox_jinteki.png)

## What You Get

Card width and length don't change, so every box is 78 × 100 mm on the outside
and only the depth follows the deck.

| Side | Factions | Cards | Outer size |
|---|---|---|---|
| Runner | Anarch, Criminal, Shaper | 40 + ID | 78 × **30.5** × 100 mm |
| Corp | Haas-Bioroid, Jinteki, NBN, Weyland | 44 + ID | 78 × **32.6** × 100 mm |

Depth is `(cards × per-card thickness) + 1.5 mm slack + walls`, and the
committed plates assume single-sleeved cards. Per-card thickness comes from
`sleeving_table`:

| `card_sleeving` | mm/card | A 45-card corp box |
|---|---|---|
| `none` | 0.31 | 78 × 23.0 × 100 mm |
| `single` (default) | 0.525 | 78 × 32.6 × 100 mm |
| `double` | 0.72 | 78 × 41.4 × 100 mm |

The 0.525 comes from the original design's own "31.5 mm cavity ≈ 60 cards".
Sleeve brands vary, so measure yours and edit the row if it matters.

Each STL in `files/` is a print plate: box bottom and lid laid out side by side.

OpenSCAD doesn't emit facets in a stable order, so two exports of an identical
model differ byte-for-byte. `just build` therefore compares geometry via
`src/stl_equal.py` and only rewrites a plate that genuinely changed — rebuilding
leaves the working tree clean.

## Quick Start

```bash
nix-shell                      # or: direnv allow
just build                     # export all seven STLs into files/
just build 50                  # ...all seven at 50 cards instead
just build-one jinteki         # just the one
just build-one jinteki 50      # ...at a custom card count
just sizes                     # every faction's cavity and outer size
just size jinteki 50           # one faction, at a card count, without exporting

just sleeving=double build     # all seven sized for double-sleeved cards
just sleeving=none size nbn    # how small would NBN be unsleeved?
```

The card count is a positional argument rather than a `--flag`, because `just`
parses `--options` as its own. Sleeving is a variable, so it goes before the
recipe name (or set `SLEEVING` in the environment).

Anything non-standard — a custom card count, or sleeving other than `single` —
is written to `out/` instead of `files/`, named for what makes it different, so
it can never overwrite the committed standard plates. `out/` is gitignored and
`just clean` removes it.

Without nix, put `openscad` on your PATH (or set `OPENSCAD=/path/to/openscad`)
and the same recipes work.

### Why nix and not hermit

Hermit covers `just`, `prek`, `ruff`, `python3` and `semantic-release`, but it
has no OpenSCAD package — and OpenSCAD is the one dependency this repo can't do
without. Nix has all of it, so the dev shell is `shell.nix`/`flake.nix`. CI
pulls `semantic-release` straight from its GitHub release instead, which keeps
the repo down to a single environment manager.

## Printing

The committed STLs are built for a **0.4 mm nozzle and 0.2 mm layers**. Slice
with **1 extra shell and 10% infill** — Austin's original recommendation, which
still holds since shells follow the nozzle, not the layer height.

Every wall and floor thickness is a multiple of those two numbers, so if yours
differ, edit `nozzle_width` and `layer_height` at the top of `src/deckbox.scad`
and re-export rather than scaling the STL.

**Layer height matters more than nozzle width here.** 0.4 mm is a safe nozzle:
the emblems are ~53 mm across, and running each through a morphological opening
at one 0.42 mm bead loses at most 0.4% of its area (Anarch, the spindliest;
every other faction is under 0.1%), so nothing meaningful disappears. Layer
height is the one that bites, because two dimensions are counted in layers:

| Derived from `layer_height` | 6 layers → floor | 4 layers → `sleeve_z_gap` |
|---|---|---|
| 0.20 mm (default here) | 1.20 mm | 0.80 mm |
| 0.27 mm (the original) | 1.62 mm | 1.08 mm |

Slice at a height the floor isn't a multiple of and the top and bottom surfaces
land mid-layer — exactly the "excellent floors" the original notes are about.
Print these at 0.27 mm and the 1.2 mm floor becomes 4.4 layers; set
`layer_height` to match your slicer and re-export instead.

### OrcaSlicer

Three settings, all in the **Process** panel on the right. Both tabs are visible
in Simple mode — no need for Advanced or Expert.

| Tab | Setting | Orca default | Set to |
|---|---|---|---|
| Quality | Layer height | 0.2 mm | **0.2 mm** (already correct) |
| Strength | Wall loops | 2 | **3** |
| Strength | Sparse infill density | 15% | **10%** |

"Wall loops = 3" is Austin's "1 extra shell": one more than the stock two. The
internal keys, if you script it or drop them in a custom profile, are
`layer_height`, `wall_loops` and `sparse_infill_density`.

Leave the shell layers alone. Orca ships `bottom_shell_layers = 3` and
`top_shell_layers = 3`, which at 0.2 mm is exactly the 6 layers that
`floor_thickness` is built from — so the box floor and the lid's top plate come
out fully solid and the 10% infill never reaches them. That is the point of
making the floor a layer multiple, and it happens to line up with Orca's stock
numbers.

Checked against OrcaSlicer 2.4.2.

| If | Then |
|---|---|
| The lid is too tight or too loose | Tune `sleeve_xy_gap` |
| You double-sleeve, or don't sleeve | `just sleeving=double build`, or edit `card_sleeving` |
| Your sleeves don't match the table | Measure a known stack on edge, edit its row in `sleeving_table` |
| You want tokens in the box too | Raise `extra_card_slots` (each slot ≈ 0.5 mm of depth) |
| You want a different capacity | Edit the card counts in `faction_table` |

The script echoes the resulting cavity and outer size on every run.

## Adding a Faction or Emblem

Add a row to `faction_table` in `src/deckbox.scad` and drop a line-segments-only
DXF into `src/emblems/`. Either hand-trace one in Inkscape
([tutorial](http://repraprip.blogspot.com/2011/05/inkscape-to-openscad-dxf-tutorial.html))
or convert a filled SVG:

```bash
python3 src/svg2dxf.py path/to/emblem.svg src/emblems/my_emblem.dxf 76
```

The trailing `76` normalises the drawing's longest side, which is why every
faction shares one `emblem_scale` of 0.7 and needs no per-emblem offset. Check
the result fits its hexagonal frame — Weyland's W didn't, and sits at 0.63.

## Emblems That Vanish

Hand-traced outlines very often contain contours that touch or overlap
themselves. Extruding one produces a non-manifold mesh that CGAL **discards
without failing the render** — which is what made two of the original author's
prints come out blank. `deckbox.scad` runs every emblem through a tiny
erode/dilate pair (`emblem_cleanup_epsilon`) first. Run `just check-emblems` to
verify each one still forms a closed mesh; CI does this too.

The two original hand-traced DXFs hit a related problem: Inkscape wrote a
`SPLINE` entity that modern OpenSCAD can't read, so the Shaper emblem lost its
diamond frame and Haas-Bioroid lost the "H". Both are regenerated from SVG here;
the originals are kept alongside as `*_handtraced_original.dxf` for comparison.

## Layout

| Path | What |
|---|---|
| `src/deckbox.scad` | The generator, driven by `faction_table` |
| `src/svg2dxf.py` | Filled SVG paths → OpenSCAD-importable DXF |
| `src/emblems/` | One DXF per faction, plus the SVG sources |
| `src/stl_equal.py` | Compares two STLs by geometry rather than by bytes |
| `files/` | Exported print plates |
| `out/` | Non-standard exports (custom counts, other sleeving); gitignored |
| `images/renders/` | A preview render per faction, plus the emblem-less `generic` |

Anything named `*_handtraced_original.*` is Austin's own work, kept verbatim for
reference and never regenerated: `src/deckbox_original.scad`, the two DXFs he
traced, and the Inkscape SVGs behind them. They came from the `deckbox_source.zip`
his Thingiverse listing shipped; the archive itself is gone, but every file it
held is checked in individually and byte-identical.

### The generic box

`files/deckbox_generic.stl` is left exactly as it came from Thingiverse — the
original 39 mm-deep 60-card box — and nothing in this repo regenerates it.

The `generic` row in `faction_table` is the emblem-less box as the script builds
it today, and it scales by card count and sleeving like any other faction:

```bash
just build-one generic 50
just sleeving=double build-one generic 100
```

Those land in `out/`, so the preserved download stays where it is. `generic` is
also the one row that a plain `just build` skips — for exactly that reason. Give
`build` a card count or a non-default sleeving and it joins in, because those
outputs go to `out/` and can't overwrite anything.

## Development

```bash
just hooks-install   # run the lint hooks on every commit
just ci              # lint + verify emblems + confirm DXFs match their SVGs
```

Commits follow [conventional commits](https://www.conventionalcommits.org/) —
the commitizen hook enforces it on `commit-msg`. Pushes to `main` run
[go-semantic-release](https://github.com/go-semantic-release/semantic-release),
which tags a version and cuts a GitHub Release with all seven STLs attached, so
people can grab a printable plate without cloning or installing OpenSCAD.

## Credits

- Original design: Thingiverse user **Austin**, [thing:39997](https://www.thingiverse.com/thing:39997) (CC BY-SA)
- Emblem artwork: [Netrunner-Icon-Font](https://github.com/MWDelaney/Netrunner-Icon-Font) by Michael W. Delaney (MIT)

See [LICENSE](LICENSE). *Android: Netrunner* and the faction logos belong to
their respective rights holders.
