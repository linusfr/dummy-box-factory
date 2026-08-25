#!/usr/bin/env just --justfile

openscad := env_var_or_default("OPENSCAD", "openscad")
# "none", "single" or "double"; override per invocation with
#   just sleeving=double build
sleeving := env_var_or_default("SLEEVING", "single")
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
	targets='{{ factions }}'
	if [ -n '{{ cards }}' ] || [ '{{ sleeving }}' != single ]; then
		# non-standard builds land in out/, so generic can join in without
		# endangering the preserved files/deckbox_generic.stl download
		targets='{{ preview_factions }}'
	fi
	for faction in $targets; do
		just sleeving='{{ sleeving }}' build-one "$faction" '{{ cards }}'
	done

# Export one faction, optionally at a custom count, eg `just build-one jinteki 50`
build-one faction cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	override=(-D 'card_sleeving="{{ sleeving }}"')
	suffix=""
	if [ -n '{{ cards }}' ]; then
		override+=(-D 'card_count_override={{ cards }}')
		suffix="_{{ cards }}cards"
	fi
	if [ '{{ sleeving }}' != single ]; then
		suffix="${suffix}_{{ sleeving }}"
	fi
	if [ -n "$suffix" ]; then
		# anything non-standard is a throwaway; keep it out of the committed set
		mkdir -p out
		out="out/deckbox_{{ faction }}${suffix}.stl"
	else
		out="files/deckbox_{{ faction }}.stl"
	fi
	if ! {{ openscad }} -D 'faction="{{ faction }}"' "${override[@]}" \
			-o "$tmp/out.stl" src/deckbox.scad > "$tmp/log" 2>&1; then
		cat "$tmp/log"; exit 1
	fi
	grep -E 'WARNING|ERROR' "$tmp/log" || true
	# OpenSCAD reorders facets between runs, so compare shape, not bytes --
	# otherwise every rebuild would dirty all seven committed plates
	if [ -f "$out" ] && python3 src/stl_equal.py "$out" "$tmp/out.stl" >/dev/null; then
		printf '%-40s unchanged\n' "$out"
	else
		mv "$tmp/out.stl" "$out"
		printf '%-40s updated\n' "$out"
	fi

# Print one faction's size, eg `just size jinteki 50` or `just sleeving=double size nbn`
size faction cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	override=(-D 'card_sleeving="{{ sleeving }}"')
	if [ -n '{{ cards }}' ]; then
		override+=(-D 'card_count_override={{ cards }}')
	fi
	{{ openscad }} -D 'faction="{{ faction }}"' "${override[@]}" \
		-o "$tmp/size.echo" src/deckbox.scad 2>/dev/null
	# .echo export writes errors into the file and still exits 0, so check here
	if grep -q '^ERROR' "$tmp/size.echo"; then
		grep -E '^(ERROR|WARNING)' "$tmp/size.echo" >&2; exit 1
	fi
	sed 's/^ECHO: //' "$tmp/size.echo"

# Print every faction's cavity and outer size without exporting anything
sizes:
	#!/usr/bin/env bash
	set -euo pipefail
	for faction in {{ factions }}; do
		just sleeving='{{ sleeving }}' size "$faction"
	done

# Delete the exported STLs, including any custom builds under out/
clean:
	#!/usr/bin/env bash
	set -euo pipefail
	for faction in {{ factions }}; do
		rm -f "files/deckbox_${faction}.stl"
	done
	rm -rf out

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
