#!/usr/bin/env just --justfile

openscad := env_var_or_default("OPENSCAD", "openscad")
factions := "anarch criminal shaper haas_bioroid jinteki nbn weyland"
# generic gets a preview but no committed STL: files/deckbox_generic.stl is
# the preserved original Thingiverse download, not something we regenerate
preview_factions := factions + " generic"

# ==========================================
# DEFAULT
# ==========================================

# Show all available commands
@default:
	just --list

# ==========================================
# BUILD
# ==========================================

# Export every faction, optionally at one shared card count, eg `just build 50`
build cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	for faction in {{ factions }}; do
		just build-one "$faction" '{{ cards }}'
	done

# Export one faction, optionally at a custom count, eg `just build-one jinteki 50`
build-one faction cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	if [ -n '{{ cards }}' ]; then
		# keep custom sizes clear of the committed standard plates
		out="files/deckbox_{{ faction }}_{{ cards }}cards.stl"
		override=(-D 'card_count_override={{ cards }}')
	else
		out="files/deckbox_{{ faction }}.stl"
		override=()
	fi
	if ! {{ openscad }} -D 'faction="{{ faction }}"' "${override[@]}" \
			-o "$tmp/out.stl" src/deckbox.scad > "$tmp/log" 2>&1; then
		cat "$tmp/log"; exit 1
	fi
	grep -E 'WARNING|ERROR' "$tmp/log" || true
	# OpenSCAD reorders facets between runs, so compare shape, not bytes --
	# otherwise every rebuild would dirty all seven committed plates
	if [ -f "$out" ] && python3 src/stl_equal.py "$out" "$tmp/out.stl" >/dev/null; then
		printf '%-34s unchanged\n' "$(basename "$out")"
	else
		mv "$tmp/out.stl" "$out"
		printf '%-34s updated\n' "$(basename "$out")"
	fi

# Print one faction's size at a given card count, eg `just size jinteki 50`
size faction cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	if [ -n '{{ cards }}' ]; then
		override=(-D 'card_count_override={{ cards }}')
	else
		override=()
	fi
	{{ openscad }} -D 'faction="{{ faction }}"' "${override[@]}" \
		-o "$tmp/size.echo" src/deckbox.scad 2>/dev/null
	sed 's/^ECHO: //' "$tmp/size.echo"

# Print each faction's cavity and outer size without exporting anything
sizes:
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	for faction in {{ factions }}; do
		# .echo evaluates the script and dumps echo() output without a CGAL render
		{{ openscad }} -D "faction=\"$faction\"" -o "$tmp/sizes.echo" src/deckbox.scad 2>/dev/null
		sed 's/^ECHO: //' "$tmp/sizes.echo"
	done

# Delete the exported STLs, including any custom card-count builds
clean:
	#!/usr/bin/env bash
	set -euo pipefail
	for faction in {{ factions }}; do
		rm -f "files/deckbox_${faction}.stl"
	done
	rm -f files/deckbox_*cards.stl

# ==========================================
# ARTWORK
# ==========================================

# Regenerate the emblem DXFs from their SVG sources
emblems:
	#!/usr/bin/env bash
	set -euo pipefail
	cd src
	python3 svg2dxf.py emblems/svg_sources/Anarch.svg             emblems/anarch_emblem.dxf       76
	python3 svg2dxf.py emblems/svg_sources/Criminal.svg           emblems/criminal_emblem.dxf     76
	python3 svg2dxf.py emblems/svg_sources/Shaper-smooth.svg      emblems/shaper_emblem.dxf       76
	python3 svg2dxf.py emblems/svg_sources/haas-bioroid.svg       emblems/haas_bioroid_emblem.dxf 76
	python3 svg2dxf.py emblems/svg_sources/Jinteki_Simple.svg     emblems/jinteki_emblem.dxf      76
	python3 svg2dxf.py emblems/svg_sources/NBN.svg                emblems/nbn_emblem.dxf          76
	python3 svg2dxf.py emblems/svg_sources/Weyland-Consortium.svg emblems/weyland_emblem.dxf      76

# Refresh the preview render for every faction into images/renders/
previews:
	#!/usr/bin/env bash
	set -euo pipefail
	mkdir -p images/renders
	for faction in {{ preview_factions }}; do
		printf 'rendering %s\n' "$faction"
		{{ openscad }} -D "faction=\"$faction\"" -o "images/renders/deckbox_${faction}.png" \
			--imgsize=800,800 --projection=o --camera=39,35,46,68,0,22,320 \
			--colorscheme=Tomorrow src/deckbox.scad 2>/dev/null
	done

# ==========================================
# CHECKS
# ==========================================

# Verify every emblem extrudes to a closed mesh (guards the vanishing-emblem bug)
check-emblems:
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	printf 'difference() {\n  linear_extrude(height = 0.32) scale(0.7) import(EMBLEM);\n  translate([100, 100, 100]) cube(1);\n}\n' > "$tmp/probe.scad"
	rc=0
	for dxf in src/emblems/*_emblem.dxf; do
		case "$dxf" in *handtraced*) continue ;; esac
		if {{ openscad }} -o "$tmp/out.stl" -D "EMBLEM=\"$PWD/$dxf\"" "$tmp/probe.scad" 2>&1 \
				| grep -q 'not closed'; then
			printf '%-32s NOT A CLOSED MESH\n' "$(basename "$dxf")"; rc=1
		else
			printf '%-32s ok\n' "$(basename "$dxf")"
		fi
	done
	exit $rc

# Confirm the committed emblem DXFs still match their SVG sources
check-emblems-current: emblems
	git diff --exit-code -- src/emblems

# Run all pre-commit hooks
pre-commit:
	prek run --all-files

# Install pre-commit git hooks
hooks-install:
	prek install

# Confirm the committed STLs still match what the script produces
check-stls-current: build
	git diff --exit-code -- files/

# Run the full CI pipeline
ci: pre-commit check-emblems check-emblems-current check-stls-current
