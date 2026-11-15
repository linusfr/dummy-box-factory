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

// "plate" lays the bottom and lid side by side for printing. "whole" assembles
// them into the finished box, which is only useful for renders.
render_mode= "plate";

// ---------------------------------------------------------------------------
// Deck sizing. The box is only as deep as the deck it has to hold, so the corp
// boxes come out a little fatter than the runner boxes.
// ---------------------------------------------------------------------------

// How the cards are sleeved: "none", "single" or "double".
card_sleeving= "single";

// Thickness of one card at each sleeving level, in mm.
//   none   -- MEASURED: a bare Netrunner card is 0.34mm with the caliper just
//             kissing it. Not printed, but the number is real.
//   single -- one standard sleeve. MEASURED: 31 sleeved cards came to 18.69mm
//             on a caliper, so 0.603 each, rounded to 0.6. That was with
//             Dragon Shield sleeves. The original design implied 0.525, which
//             turned out to be optimistic by 15%.
//   double -- a perfect-fit inner sleeve plus a standard outer one. ESTIMATED,
//             untested; double-sleeving varies a lot by brand pairing.
// Sleeve brands vary, so treat these as starting points: stand a known number
// of cards on edge, measure the stack, divide, and edit the row you use.
sleeving_table= [
	["none",   0.34],
	["single", 0.6],
	["double", 0.72]
];

// Bypass the table entirely with a measured value, eg -D card_thickness_override=0.6
card_thickness_override= undef;

// Breathing room (mm) on top of the deck's own thickness, so a full deck still
// slides in and out easily instead of wedging between the sleeve walls. 1.5 was
// too mean in practice -- you want a finger's worth of play to lift cards out.
deck_slack= 3;

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
	["anarch",       "runner",  40, "anarch.dxf",         0.7, [0, 0]],
	["criminal",     "runner",  40, "criminal.dxf",       0.7, [0, 0]],
	["shaper",       "runner",  40, "shaper.dxf",         0.7, [0, 0]],
	["haas_bioroid", "corp",    44, "haas_bioroid.dxf",   0.7, [0, 0]],
	["jinteki",      "corp",    44, "jinteki.dxf",        0.7, [0, 0]],
	["nbn",          "corp",    44, "nbn.dxf",            0.7, [0, 0]],
	// the W is wider relative to its height than the others, so it has to come
	// down a little to stay inside the hexagonal frame
	["weyland",      "corp",    44, "weyland.dxf",        0.63, [0, 0]],

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
// Box geometry. Width and height are set by the cards themselves (a card in a
// Dragon Shield sleeve measures 66.24 x 92.29mm) and so are the same for every
// faction; only the depth follows the deck size.
// ---------------------------------------------------------------------------
deckbox_width= 78;
deckbox_total_height= 100;
deckbox_lid_height= 20;

// Tall enough that a sleeved card sits fully inside the bottom half. At 12 the
// bottom's interior was 90.8mm and cards stood proud of the open box; 15 gives
// 93.8mm, 1.5mm over a 92.29mm Dragon Shield-sleeved card. Raise it if your
// sleeves are taller than that.
sleeve_height= 15;
sleeve_xy_gap= 0.25; // decrease if the fit is too loose, increase if it's too tight
sleeve_z_gap= (4 * layer_height);
sleeve_wall_thickness= (4 * nozzle_width);

hex_pattern_line_width= 1.5;
// Relief depth of the hex texture. At 0.75 nozzles the grooves were under one
// extrusion wide and the texture all but vanished once printed; 1.5 gives the
// slicer a full bead to work with. outer_sleeve_wall_thickness absorbs this, so
// deepening the pattern thickens the wall behind it rather than thinning it.
hex_pattern_depth= (1.5 * nozzle_width);

// The top and bottom faces carry raised hexagons rather than recessed ones, so
// their relief is the first thing the printer lays down -- a field of separate
// islands until the grout lines close over. One layer keeps that to a single
// island layer; at the full pattern depth it would be three, which is a lot of
// disconnected first-layer area to ask the bed to hold.
hex_pattern_floor_depth= layer_height;


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
// The emblem is raised off the floor of its recessed frame, so matching the
// pattern depth is what leaves it flush with the surrounding face.
emblem_depth= hex_pattern_depth;

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

// ---------------------------------------------------------------------------
// Optional magnet closure. The sleeve is what actually holds the lid on; these
// only add a snap. Leave magnet_diameter at 0 and the box is untouched: no
// posts, no pockets, nothing to glue.
//
// The four corners thicken into posts so the silhouette stays symmetric, but
// only the corners listed in magnet_corners are drilled. One pair is plenty --
// the sleeve constrains the lid in X and Y, so the magnets only ever work in
// straight tension, never in shear.
// ---------------------------------------------------------------------------
magnet_diameter= 3;                    // 0 disables the whole feature
magnet_thickness= 2;
magnet_fit_gap= 0.2;                   // pocket oversize, for glue and for print squish
magnet_wall= (2 * nozzle_width);       // material left around the pocket
magnet_recess= 0.2;                    // how far below the seam each magnet sits,
                                       // so the pair never quite touches
magnet_corners= [0, 2];                // 0..3 anticlockwise from the origin corner

magnet_post_size= (magnet_diameter + magnet_fit_gap + (2 * magnet_wall));

// Radius that has to stay in solid material: the pocket plus its wall.
magnet_clearance_radius= (((magnet_diameter + magnet_fit_gap) / 2) + magnet_wall);

// How far along the corner diagonal the pocket can sit. It has to clear the
// chamfer on the outside and the deck cavity on the inside; if those two leave
// no room, the corner is too small and needs a post bolted on.
magnet_offset_min= (((magnet_clearance_radius * sqrt(2)) + bevel_size) / 2);
magnet_offset_max= (total_sidewall_thickness - (magnet_clearance_radius / sqrt(2)));

magnet_needs_post= (magnet_offset_min > magnet_offset_max);

magnet_offset= magnet_needs_post
	? (total_sidewall_thickness - (magnet_post_size / 2))
	: ((magnet_offset_min + magnet_offset_max) / 2);

// how far the posts stand proud, so the lid/bottom split can cut through them
deckbox_outer_margin= ((magnet_diameter > 0) && magnet_needs_post)
	? max(0, magnet_post_size - total_sidewall_thickness)
	: 0;

// How tall the column the lid keeps has to be: the pocket, plus a wall over
// its roof so the magnet doesn't show through the outside of the lid.
magnet_column_height= (magnet_recess + magnet_thickness + (2 * magnet_wall));

// How tall the notch in the sleeve has to be, which is a different number: the
// lid's column stands at the mouth of its sleeve pocket, so the whole sleeve
// travels past it on the way in. Notch only as far as the magnet reaches and
// the lid jams a millimetre after it touches down -- the halves clear each
// other seated and nowhere else. So the notch runs the sleeve's full height,
// and the grip it costs is the price of the closure.
magnet_notch_height= (sleeve_height + sleeve_z_gap);

// ---------------------------------------------------------------------------
// Corner test coupon. render_mode="corner" crops both halves down to one
// magnet corner and plates them, so the fit that actually matters -- the lid
// travelling down past the sleeve notch onto the magnet -- can be printed in
// minutes rather than hours. Everything it carries is real geometry, straight
// out of the same modules the full plate uses.
// ---------------------------------------------------------------------------

// How far along each wall the coupon reaches from the corner. Long enough to
// hold by hand and to feel the sleeve friction; short enough to be a scrap.
corner_test_size= 25;

// Clamped so a very shallow box can't ask for a coupon deeper than it is.
corner_test_span= min(corner_test_size, deckbox_width, deckbox_depth);

// How far below the seam the coupon starts. It has to swallow the body's
// magnet pocket and still leave a flat face for the bed.
corner_test_skirt= 10;

// Which corner to cut it from. The first drilled one, unless told otherwise.
corner_test_index= (len(magnet_corners) > 0) ? magnet_corners[0] : 0;

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
	is_positive,
	depth= hex_pattern_depth)
{
	translate([0, 0, -csg_overlap])
	linear_extrude(
		height= (depth + csg_overlap),
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
			is_positive= false,
			depth= hex_pattern_floor_depth);
	}
	else
	{
		translate([deckbox_width, 0, 0])
		rotate([0, 0, 90])
		deckbox_face_pattern(
			[deckbox_depth, deckbox_width],
			is_positive= false,
			depth= hex_pattern_floor_depth);
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

	difference()
	{
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

			// posts go on after the texture so they stay smooth, and only when
			// the magnet is too fat for the corner to swallow
			if ((magnet_diameter > 0) && magnet_needs_post)
			{
				for (index= [0 : 3]) deckbox_corner_post(index);
			}
		}

		// cut both halves' pockets here; the lid/bottom split separates them
		if (magnet_diameter > 0)
		{
			for (index= magnet_corners)
			{
				deckbox_magnet_pocket(index, is_lid= false);
				deckbox_magnet_pocket(index, is_lid= true);
			}
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
					-(csg_overlap + deckbox_outer_margin),
					-(csg_overlap + deckbox_outer_margin),
					(deckbox_total_height - deckbox_lid_height)])
				cube(size= [
					(deckbox_width + (2 * (csg_overlap + deckbox_outer_margin))),
					(deckbox_depth + (2 * (csg_overlap + deckbox_outer_margin))),
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

		// clear the sleeve away from the magnet corners; the lid fills the gap
		if (magnet_diameter > 0)
		{
			for (index= magnet_corners)
				deckbox_magnet_column(
					index,
					extra_radius= sleeve_xy_gap,
					height= magnet_notch_height);
		}
	}
}

module convert_to_deckbox_lid()
{
	difference()
	{
		children(0);

		translate([
			-(csg_overlap + deckbox_outer_margin),
			-(csg_overlap + deckbox_outer_margin),
			-csg_overlap])
		cube(size= [
			(deckbox_width + (2 * (csg_overlap + deckbox_outer_margin))),
			(deckbox_depth + (2 * (csg_overlap + deckbox_outer_margin))),
			((deckbox_total_height - deckbox_lid_height) + csg_overlap)]);

		// the sleeve pocket, but leaving the magnet corners solid
		difference()
		{
			translate([
				outer_sleeve_wall_thickness,
				outer_sleeve_wall_thickness,
				((deckbox_total_height - deckbox_lid_height) - csg_overlap)])
			cube(size= [
				(deckbox_width - (2 * outer_sleeve_wall_thickness)),
				(deckbox_depth - (2 * outer_sleeve_wall_thickness)),
				(sleeve_height + sleeve_z_gap + csg_overlap)]);

			if (magnet_diameter > 0)
			{
				for (index= magnet_corners) deckbox_magnet_column(index);
			}
		}

		translate([
			total_sidewall_thickness,
			total_sidewall_thickness,
			floor_thickness])
		cube(size= deck_cavity_size);
	}
}

function magnet_corner_origin(index) =
	[((index == 0) || (index == 3)) ? 0 : deckbox_width,
	 ((index == 0) || (index == 1)) ? 0 : deckbox_depth];

function magnet_corner_sign(index) =
	[((index == 0) || (index == 3)) ? 1 : -1,
	 ((index == 0) || (index == 1)) ? 1 : -1];

module deckbox_corner_post(index)
{
	origin= magnet_corner_origin(index);
	sign= magnet_corner_sign(index);

	translate([origin[0], origin[1], 0])
	scale([sign[0], sign[1], 1])
	translate([
		(total_sidewall_thickness - magnet_post_size),
		(total_sidewall_thickness - magnet_post_size),
		0])
	beveled_cube(size= [magnet_post_size, magnet_post_size, deckbox_total_height]);
}

// The sleeve stands on the inner part of the corner and the lid's wall there is
// only outer_sleeve_wall thick, so neither half has room for a pocket as built.
// This column is notched out of the sleeve and kept in the lid, giving both
// halves a solid corner to drill. All of it is inside the box: the silhouette
// does not change.
module deckbox_magnet_column(
	index,
	extra_radius= 0,
	height= magnet_column_height)
{
	origin= magnet_corner_origin(index);
	sign= magnet_corner_sign(index);
	seam= (deckbox_total_height - deckbox_lid_height);

	translate([
		(origin[0] + (sign[0] * magnet_offset)),
		(origin[1] + (sign[1] * magnet_offset)),
		(seam - csg_overlap)])
	cylinder(
		h= (height + (2 * csg_overlap)),
		r= (magnet_clearance_radius + extra_radius),
		$fn= 48);
}

module deckbox_magnet_pocket(
	index,
	is_lid)
{
	origin= magnet_corner_origin(index);
	sign= magnet_corner_sign(index);
	inset= magnet_offset;
	seam= (deckbox_total_height - deckbox_lid_height);

	// both pockets open onto the seam, which faces up in each half's print
	// orientation -- the lid is flipped on the plate -- so neither one bridges
	translate([
		(origin[0] + (sign[0] * inset)),
		(origin[1] + (sign[1] * inset)),
		is_lid ? seam : (seam - magnet_recess - magnet_thickness)])
	cylinder(
		h= (magnet_recess + magnet_thickness),
		d= (magnet_diameter + magnet_fit_gap),
		$fn= 48);
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

// Lower-left corner of the coupon's footprint, whichever corner of the box it
// was cut from, so it can be dragged back to the origin afterwards.
function corner_test_footprint(index) =
	let (origin= magnet_corner_origin(index),
		sign= magnet_corner_sign(index))
	[min(origin[0], (origin[0] + (sign[0] * corner_test_span))),
	 min(origin[1], (origin[1] + (sign[1] * corner_test_span)))];

module corner_test_crop(
	index,
	z_min,
	z_max)
{
	footprint= corner_test_footprint(index);

	translate([
		(footprint[0] - csg_overlap),
		(footprint[1] - csg_overlap),
		z_min])
	cube(size= [
		(corner_test_span + (2 * csg_overlap)),
		(corner_test_span + (2 * csg_overlap)),
		(z_max - z_min)]);
}

// No emblem on either coupon: it lives in the middle of a face, nowhere near a
// corner, and importing the DXF only to crop it away wastes a render.
module deckbox_corner_test_bottom(index)
{
	footprint= corner_test_footprint(index);
	base= ((deckbox_total_height - deckbox_lid_height) - corner_test_skirt);

	translate([-footprint[0], -footprint[1], -base])
	intersection()
	{
		convert_to_deckbox_bottom()
		decorated_deckbox_body("", 1.0, [0, 0]);

		corner_test_crop(index, base, deckbox_total_height);
	}
}

module deckbox_corner_test_lid(index)
{
	footprint= corner_test_footprint(index);
	seam= (deckbox_total_height - deckbox_lid_height);

	// flipped seam-up, the way the lid sits on the real plate
	translate([0, corner_test_span, 0])
	rotate([180, 0, 0])
	translate([-footprint[0], -footprint[1], -deckbox_total_height])
	intersection()
	{
		convert_to_deckbox_lid()
		decorated_deckbox_body("", 1.0, [0, 0]);

		corner_test_crop(index, (seam - csg_overlap), deckbox_total_height);
	}
}

module deckbox_corner_test_plate(index)
{
	union()
	{
		deckbox_corner_test_bottom(index);

		translate([0, (corner_test_span + plating_xy_separation), 0])
		deckbox_corner_test_lid(index);
	}
}

assert(
	((render_mode == "plate") || (render_mode == "whole") ||
		(render_mode == "corner")),
	str("unknown render_mode \"", render_mode,
		"\" -- use \"plate\", \"whole\" or \"corner\""));

if (render_mode == "whole")
{
	deckbox_whole(
		emblem_filename= faction_emblem_filename,
		emblem_scale= faction_emblem_scale,
		emblem_xy_offset= faction_emblem_xy_offset);
}
else if (render_mode == "corner")
{
	if (magnet_diameter <= 0)
	{
		echo(str("WARNING: magnet_diameter is 0, so this coupon has no pocket, ",
			"no notch and nothing to test."));
	}

	echo(str("Corner coupon: corner ", corner_test_index, ", ",
		corner_test_span, "mm along each wall."));

	deckbox_corner_test_plate(corner_test_index);
}
else
{
	deckbox_plate(
		emblem_filename= faction_emblem_filename,
		emblem_scale= faction_emblem_scale,
		emblem_xy_offset= faction_emblem_xy_offset);
}
