#!/usr/bin/env just --justfile

openscad := env_var_or_default("OPENSCAD", "openscad")
# "none", "single" or "double"; override per invocation with
#   just sleeving=double build
sleeving := env_var_or_default("SLEEVING", "single")
# magnet diameter in mm; 0 prints the box with no pockets at all
magnets := env_var_or_default("MAGNETS", "3")
factions := "anarch criminal shaper haas_bioroid jinteki nbn weyland generic"

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
		just sleeving='{{ sleeving }}' magnets='{{ magnets }}' build-one "$faction" '{{ cards }}'
	done

# Export one faction, optionally at a custom count, eg `just build-one jinteki 50`
build-one faction cards="":
	#!/usr/bin/env bash
	set -euo pipefail
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	override=(-D 'card_sleeving="{{ sleeving }}"' -D 'magnet_diameter={{ magnets }}')
	suffix=""
	if [ '{{ magnets }}' != 3 ]; then
		suffix="_magnets{{ magnets }}"
	fi
	if [ -n '{{ cards }}' ]; then
		override+=(-D 'card_count_override={{ cards }}')
		suffix="_{{ cards }}cards${suffix}"
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
	override=(-D 'card_sleeving="{{ sleeving }}"' -D 'magnet_diameter={{ magnets }}')
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
		just sleeving='{{ sleeving }}' magnets='{{ magnets }}' size "$faction"
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
	for faction in {{ factions }}; do
		svg="src/emblems/svg_sources/${faction}.svg"
		# generic is deliberately emblem-less
		[ -f "$svg" ] || continue
		python3 src/svg2dxf.py "$svg" "src/emblems/${faction}.dxf" 76
	done

# Refresh the preview render for every faction into images/renders/
previews:
	#!/usr/bin/env bash
	set -euo pipefail
	mkdir -p images/renders
	for faction in {{ factions }}; do
		printf 'rendering %s\n' "$faction"
		# --render forces the CGAL pipeline. The default OpenCSG preview shades
		# the recessed hexagons identically to the ribs between them, so the
		# texture disappears and the walls come out flat.
		# render_mode=whole assembles the box; the plate layout the STLs use puts
		# the lid off to one side and reads badly as a picture.
		{{ openscad }} --render -D "faction=\"$faction\"" -D 'render_mode="whole"' \
			-o "images/renders/deckbox_${faction}.png" \
			--imgsize=900,1000 --projection=o --camera=39,16,50,62,0,28,330 \
			--colorscheme=DeepOcean src/deckbox.scad 2>/dev/null
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
	for dxf in src/emblems/*.dxf; do
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
