// Parametric scifi deck box, one box per Netrunner faction.
//
// Derived from "Parametric Scifi Deck Box With Two Netrunner Emblems" by
// Thingiverse user Austin (https://www.thingiverse.com/thing:39997), which is
// licensed Creative Commons - Attribution - Share Alike. This derivative keeps
// that license.
//
// Changes from the original: the box depth is now derived from how many sleeved
// cards it has to hold rather than being hard-coded, and all seven faction
// emblems are generated from the MIT-licensed Netrunner-Icon-Font by Michael W.
// Delaney (https://github.com/MWDelaney/Netrunner-Icon-Font) via svg2dxf.py.

// ---------------------------------------------------------------------------
// PRINTING: these two are the only printer-specific numbers. Every wall and
// floor thickness below is a multiple of them, so change these and re-export
// to get clean floors and sleeve-walls on your own machine.
//
// layer_height matters more than nozzle_width here: floor_thickness is 6 layers
// and sleeve_z_gap is 4 layers, so slicing at a height these aren't a multiple
// of puts the floor and the lid's stop mid-layer. The original design used
// 0.27; 0.2 is the common default for a 0.4 nozzle and is what ships here.
// ---------------------------------------------------------------------------
nozzle_width= 0.4;
layer_height= 0.2;

// ---------------------------------------------------------------------------
// Which faction to build. Override it from the command line:
//   openscad -D 'faction="anarch"' -o deckbox_anarch.stl deckbox.scad
// or build the whole set at once with ./build_all.sh
// ---------------------------------------------------------------------------
faction= "shaper";

// ---------------------------------------------------------------------------
// Deck sizing. The box is only as deep as the deck it has to hold, so the corp
// boxes come out a little fatter than the runner boxes.
// ---------------------------------------------------------------------------

// How the cards are sleeved: "none", "single" or "double".
card_sleeving= "single";

// Thickness of one card at each sleeving level, in mm.
//   none   -- a bare Netrunner card is a hair over 0.3mm
//   single -- one standard sleeve; 0.525 is what the original design implied,
//             since it quoted its 31.5mm cavity as "roughly 60 cards"
//   double -- a perfect-fit inner sleeve plus a standard outer one
// Sleeve brands vary, so treat these as starting points: stand a known number
// of cards on edge, measure the stack, divide, and edit the row you use.
sleeving_table= [
	["none",   0.31],
	["single", 0.525],
	["double", 0.72]
];

// Bypass the table entirely with a measured value, eg -D card_thickness_override=0.6
card_thickness_override= undef;

// Breathing room (mm) on top of the deck's own thickness, so that a full deck
// still slides in and out easily instead of wedging between the sleeve walls.
deck_slack= 1.5;

// Override the card count entirely, ignoring the faction's deck size and
// extra_card_slots. Meant for the command line rather than for editing here:
//   openscad -D 'faction="jinteki"' -D card_count_override=50 ...
// or, more conveniently, `just build-one jinteki 50`.
card_count_override= undef;

// Slots beyond the faction's deck size. Netrunner deck sizes don't count the
// identity card, so the default of 1 is the ID travelling in the same box.
// Raise it to leave room for tokens and a few spares. Applies to every faction
// at once; each extra slot costs about half a millimetre of depth.
extra_card_slots= 1;

// name             side      cards  emblem dxf                  scale  xy offset
faction_table= [
	["anarch",       "runner",  40, "anarch_emblem.dxf",         0.7, [0, 0]],
	["criminal",     "runner",  40, "criminal_emblem.dxf",       0.7, [0, 0]],
	["shaper",       "runner",  40, "shaper_emblem.dxf",         0.7, [0, 0]],
	["haas_bioroid", "corp",    44, "haas_bioroid_emblem.dxf",   0.7, [0, 0]],
	["jinteki",      "corp",    44, "jinteki_emblem.dxf",        0.7, [0, 0]],
	["nbn",          "corp",    44, "nbn_emblem.dxf",            0.7, [0, 0]],
	// the W is wider relative to its height than the others, so it has to come
	// down a little to stay inside the hexagonal frame
	["weyland",      "corp",    44, "weyland_emblem.dxf",        0.63, [0, 0]],

	// No emblem at all, sized for the largest of the above.
	["generic",      "corp",    44, "",                          1.0, [0, 0]]
];

emblem_directory= "emblems/";

faction_matches= [
	for (index= [0 : (len(faction_table) - 1)])
		if (faction_table[index][0] == faction) index];

assert(
	(len(faction_matches) == 1),
	str("unknown faction \"", faction, "\" -- see faction_table"));

faction_row= faction_table[faction_matches[0]];

faction_side= faction_row[1];
faction_deck_size= faction_row[2];
faction_emblem_scale= faction_row[4];
faction_emblem_xy_offset= faction_row[5];

faction_emblem_filename= (
	(len(faction_row[3]) > 0) ?
		str(emblem_directory, faction_row[3]) :
		"");

card_count= is_undef(card_count_override)
	? (faction_deck_size + extra_card_slots)
	: card_count_override;

sleeving_matches= [
	for (index= [0 : (len(sleeving_table) - 1)])
		if (sleeving_table[index][0] == card_sleeving) index];

assert(
	(len(sleeving_matches) == 1),
	str("unknown card_sleeving \"", card_sleeving, "\" -- see sleeving_table"));

sleeved_card_thickness= is_undef(card_thickness_override)
	? sleeving_table[sleeving_matches[0]][1]
	: card_thickness_override;

// ---------------------------------------------------------------------------
// Box geometry. Width and height are set by the cards themselves (a sleeved
// card is about 66 x 91mm) and so are the same for every faction; only the
// depth follows the deck size.
// ---------------------------------------------------------------------------
deckbox_width= 78;
deckbox_total_height= 100;
deckbox_lid_height= 20;

sleeve_height= 12;
sleeve_xy_gap= 0.25; // decrease if the fit is too loose, increase if it's too tight
sleeve_z_gap= (4 * layer_height);
sleeve_wall_thickness= (4 * nozzle_width);

hex_pattern_line_width= 1.5;
hex_pattern_depth= (0.75 * nozzle_width);

inner_sleeve_wall_thickness= sleeve_wall_thickness;
outer_sleeve_wall_thickness= (sleeve_wall_thickness + hex_pattern_depth);
total_sidewall_thickness= (
	inner_sleeve_wall_thickness +
	sleeve_xy_gap +
	outer_sleeve_wall_thickness);

// The deck is what sets the depth of the box.
deck_thickness= ((card_count * sleeved_card_thickness) + deck_slack);
deckbox_depth= (deck_thickness + (2 * total_sidewall_thickness));

hex_pattern_cell_radius= (deckbox_width / 12);

// NOTE: The floor intionally doesn't factor in hex_pattern_depth to
// avoid generating any mostly-hollow layers.
floor_thickness= (6 * layer_height);

deck_cavity_size= [
	(deckbox_width - (2 * total_sidewall_thickness)),
	(deckbox_depth - (2 * total_sidewall_thickness)),
	(deckbox_total_height - (2 * floor_thickness))];

echo(str("Building the ", faction, " deckbox (", faction_side, ", ",
	card_count, " cards, ", card_sleeving, "-sleeved at ",
	sleeved_card_thickness, "mm each)."));
echo("This deckbox has a cavity-size of ", deck_cavity_size);
echo("This deckbox has an outer size of ",
	[deckbox_width, deckbox_depth, deckbox_total_height]);

emblem_frame_width= (0.85 * deckbox_width);
emblem_depth= (0.75 * nozzle_width);

// Emblems traced by hand -- or converted from someone else's artwork -- very
// often contain contours that touch or overlap themselves. Extruding one of
// those directly produces a non-manifold mesh, which CGAL then discards
// without stopping the render: exactly the failure mode that made earlier
// prints of this design come out with no emblem on them at all. Feeding the
// outline through a tiny erode/dilate pair first forces it through OpenSCAD's
// polygon clipper, which resolves the overlaps into clean contours.
//
// This is measured in emblem-file units and applied before emblem_scale, so at
// print scale it moves each edge by well under a hundredth of a millimetre.
// Raise it if a new emblem still refuses to become a closed mesh.
emblem_cleanup_epsilon= 0.01;

plating_xy_separation= 10;

bevel_size= 1; // length of the beveled edge itself is (sqrt(2) * bevel_size)

csg_overlap= 0.02;

unit_hexagon_inner_radius= (sqrt(3) / 2);

unit_hexagon_points= [
	[1, 0],
	[0.5, unit_hexagon_inner_radius],
	[-0.5, unit_hexagon_inner_radius],
	[-1, 0],
	[-0.5, -unit_hexagon_inner_radius],
	[0.5, -unit_hexagon_inner_radius]];

module hexagon_lattice_unbounded(
	lattice_size,
	hex_cell_radius,
	separation_gap)
{
	// convert the hexagonal grid into a rectangular grid of hex-cell-pairs
	rect_cell_width= (3 * hex_cell_radius);
	rect_cell_height= (2 * (unit_hexagon_inner_radius * hex_cell_radius));

	column_count= ceil((lattice_size[0] + hex_cell_radius) / rect_cell_width);
	row_count= ceil((lattice_size[1] + hex_cell_radius) / rect_cell_height);

	union()
	{
		for (row_index= [0 : (row_count - 1)])
		{
			translate([
				0,
				(row_index * rect_cell_height),
				0])
			for (column_index= [0 : (column_count - 1)])
			{
				translate([
					(column_index * rect_cell_width),
					0,
					0])
				union()
				{
					scale((hex_cell_radius - (separation_gap / 2)))
					polygon(points= unit_hexagon_points);

					translate([
						(hex_cell_radius + (hex_cell_radius / 2)),
						(rect_cell_height / 2),
						0])
					scale((hex_cell_radius - (separation_gap / 2)))
					polygon(points= unit_hexagon_points);
				}
			}
		}
	}
}

module hexagon_lattice_bounded(
	lattice_size,
	hex_cell_radius,
	separation_gap,
	is_positive= true)
{
	difference()
	{
		if (!is_positive)
		{
			translate([-csg_overlap, -csg_overlap])
			square([
				(lattice_size[0] + (2 * csg_overlap)),
				(lattice_size[1] + (2 * csg_overlap))]);
		}

		intersection()
		{
			square(lattice_size);

			hexagon_lattice_unbounded(
				lattice_size,
				hex_cell_radius,
				separation_gap);
		}
	}
}

module beveled_cube(
	size,
	center= false)
{
	promoted_size= (
		(str(size)[0] != "[") ?
			[size, size, size] :
			size);

	beveled_size= (promoted_size - (2 * [bevel_size, bevel_size, bevel_size]));

	subcube_offset= (center == true) ? 0 : bevel_size;

	hull()
	{
		translate([0, subcube_offset, subcube_offset])
		cube(
			size= [promoted_size[0], beveled_size[1], beveled_size[2]],
			center= center);

		translate([subcube_offset, 0, subcube_offset])
		cube(
			size= [beveled_size[0], promoted_size[1], beveled_size[2]],
			center= center);

		translate([subcube_offset, subcube_offset, 0])
		cube(
			size= [beveled_size[0], beveled_size[1], promoted_size[2]],
			center= center);
	}
}

module deckbox_face_pattern(
	side_size,
	is_positive)
{
	translate([0, 0, -csg_overlap])
	linear_extrude(
		height= (hex_pattern_depth + csg_overlap),
		convexity= 4)
	hexagon_lattice_bounded(
		lattice_size= side_size,
		hex_cell_radius= hex_pattern_cell_radius,
		separation_gap= (hex_pattern_line_width / 2),
		is_positive= is_positive);
}

module deckbox_front_hex_pattern(
	have_emblem)
{
	emblem_frame_outer_radius=
		(emblem_frame_width / (2 * unit_hexagon_inner_radius));

	union()
	{
		difference()
		{
			scale([1, -1, 1])
			rotate([90, 0, 0])
			deckbox_face_pattern(
				[deckbox_width, deckbox_total_height],
				is_positive= true);

			if (have_emblem)
			{
				translate([
					(deckbox_width / 2),
					(hex_pattern_depth + csg_overlap),
					(deckbox_total_height / 2)])
				rotate([90, 0, 0])
				linear_extrude(height= (hex_pattern_depth + (2 * csg_overlap)))
				scale(emblem_frame_outer_radius)
				rotate([0, 0, 90])
				polygon(unit_hexagon_points);
			}
		}

		if (have_emblem)
		{
			translate([
				(deckbox_width / 2),
				hex_pattern_depth,
				(deckbox_total_height / 2)])
			rotate([90, 0, 0])
			linear_extrude(height= (hex_pattern_depth + csg_overlap))
			scale(emblem_frame_outer_radius - hex_pattern_line_width)
			rotate([0, 0, 90])
			polygon(unit_hexagon_points);
		}
	}
}

module deckbox_front_emblem(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	color("SlateGray")
	translate([
		(deckbox_width / 2),
		(hex_pattern_depth + csg_overlap),
		(deckbox_total_height / 2)])
	rotate([90, 0, 0])
	linear_extrude(height= (emblem_depth + csg_overlap))
	translate(emblem_xy_offset)
	scale(emblem_scale)
	offset(delta= emblem_cleanup_epsilon)
	offset(delta= -emblem_cleanup_epsilon)
	import(emblem_filename);
}

module deckbox_left_hex_pattern()
{
	rotate([0, 0, 90])
	rotate([90, 0, 0])
	deckbox_face_pattern(
		[deckbox_depth, deckbox_total_height],
		is_positive= true);
}

module deckbox_bottom_hex_pattern()
{
	is_aligned_to_front_face= true;

	if (is_aligned_to_front_face)
	{
		deckbox_face_pattern(
			[deckbox_width, deckbox_depth],
			is_positive= false);
	}
	else
	{
		translate([deckbox_width, 0, 0])
		rotate([0, 0, 90])
		deckbox_face_pattern(
			[deckbox_depth, deckbox_width],
			is_positive= false);
	}
}

module deckbox_body_decoration_negative(
	have_emblem)
{
	union()
	{
		// front
		deckbox_front_hex_pattern(have_emblem);

		// back
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_front_hex_pattern(have_emblem);

		// left
		deckbox_left_hex_pattern();

		// right
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_left_hex_pattern();

		// bottom
		deckbox_bottom_hex_pattern();

		// top
		translate([0, deckbox_depth, deckbox_total_height])
		rotate([180, 0, 0])
		deckbox_bottom_hex_pattern();
	}
}

module deckbox_body_decoration_positive(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	union()
	{
		// front
		deckbox_front_emblem(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);

		// back
		translate([deckbox_width, deckbox_depth, 0])
		rotate([0, 0, 180])
		deckbox_front_emblem(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

module decorated_deckbox_body(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	have_emblem= (len(emblem_filename) > 1);

	union()
	{
		difference()
		{
			beveled_cube(size= [
				deckbox_width,
				deckbox_depth,
				deckbox_total_height]);

			deckbox_body_decoration_negative(
				have_emblem);
		}

		if (have_emblem)
		{
			deckbox_body_decoration_positive(
				emblem_filename,
				emblem_scale,
				emblem_xy_offset);
		}
	}
}

module convert_to_deckbox_bottom()
{
	difference()
	{
		union()
		{
			difference()
			{
				children(0);

				translate([
					-csg_overlap,
					-csg_overlap,
					(deckbox_total_height - deckbox_lid_height)])
				cube(size= [
					(deckbox_width + (2 * csg_overlap)),
					(deckbox_depth + (2 * csg_overlap)),
					(deckbox_lid_height + csg_overlap)]);
			}

			translate([
				(total_sidewall_thickness - inner_sleeve_wall_thickness),
				(total_sidewall_thickness - inner_sleeve_wall_thickness),
				floor_thickness])
			beveled_cube(size= [
				(deck_cavity_size[0] + (2 * inner_sleeve_wall_thickness)),
				(deck_cavity_size[1] + (2 * inner_sleeve_wall_thickness)),
				(((deckbox_total_height - deckbox_lid_height) + sleeve_height) - floor_thickness)]);
		}

		translate([
			total_sidewall_thickness,
			total_sidewall_thickness,
			floor_thickness])
		cube(size= deck_cavity_size);
	}
}

module convert_to_deckbox_lid()
{
	difference()
	{
		children(0);

		translate([
			-csg_overlap,
			-csg_overlap,
			-csg_overlap])
		cube(size= [
			(deckbox_width + (2 * csg_overlap)),
			(deckbox_depth + (2 * csg_overlap)),
			((deckbox_total_height - deckbox_lid_height) + csg_overlap)]);

		translate([
			outer_sleeve_wall_thickness,
			outer_sleeve_wall_thickness,
			((deckbox_total_height - deckbox_lid_height) - csg_overlap)])
		cube(size= [
			(deckbox_width - (2 * outer_sleeve_wall_thickness)),
			(deckbox_depth - (2 * outer_sleeve_wall_thickness)),
			(sleeve_height + sleeve_z_gap + csg_overlap)]);

		translate([
			total_sidewall_thickness,
			total_sidewall_thickness,
			floor_thickness])
		cube(size= deck_cavity_size);
	}
}

module deckbox_whole(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	union()
	{
		convert_to_deckbox_bottom()
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);

		convert_to_deckbox_lid()
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

module deckbox_plate(
	emblem_filename,
	emblem_scale,
	emblem_xy_offset)
{
	union()
	{
		convert_to_deckbox_bottom()
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);

		translate([0, ((2 * deckbox_depth) + plating_xy_separation), 0])
		rotate([180, 0, 0])
		translate([0, 0, -deckbox_total_height])
		convert_to_deckbox_lid()
		decorated_deckbox_body(
			emblem_filename,
			emblem_scale,
			emblem_xy_offset);
	}
}

deckbox_plate(
	emblem_filename= faction_emblem_filename,
	emblem_scale= faction_emblem_scale,
	emblem_xy_offset= faction_emblem_xy_offset);
