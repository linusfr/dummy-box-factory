// Parametric card-pool organizer: an outer sleeve, a drawer that slides into
// it, and one divider tray per faction standing in the drawer.
//
// Remixed from "Netrunner NSG Organizer" on MakerWorld
// (https://makerworld.com/models/2956774), licensed Creative Commons
// Attribution-NonCommercial-ShareAlike. This file and the STLs it exports keep
// that license, which is stricter than the deck box's: no commercial use.
//
// The original ships fixed STLs per sleeving. Its sleeved ceiling sits 93.2mm
// above the tray floor, which leaves a 92.3mm sleeved card under a millimetre:
// any sag or squish and the cards jam on the way in. Here every height is
// derived from the card itself:
// measure one sleeved card, set the row in sleeving_table, and the trays, the
// drawer and the sleeve all grow to suit. Geometry was re-measured from the
// original's sections rather than imported, so no mesh of theirs is reused.

// ---------------------------------------------------------------------------
// PRINTING. Same contract as deckbox.scad: walls are nozzle multiples, floors
// are layer multiples.
// ---------------------------------------------------------------------------
nozzle_width= 0.4;
layer_height= 0.2;

// "outer", "drawer", "tray", "rail", "gauge", "drawer_slice" or "assembly"
// (renders only).
part= "assembly";

// Which tray to build when part="tray"; see tray_table.
faction= "anarch";

// ---------------------------------------------------------------------------
// Cards. Thickness is per card in a stack; width and height are one card,
// standing on its short edge, sleeve and all.
// ---------------------------------------------------------------------------
card_sleeving= "single";

//   thickness -- same measurements as deckbox.scad's sleeving_table.
//   width, height --
//     none   -- the 63 x 88mm card spec plus half a millimetre. Not measured.
//     single -- MEASURED with a caliper: a Dragon Shield-sleeved card is
//               66.24 x 92.29mm.
//     double -- ESTIMATED, untested.
// Height is the number that matters: lay ten sleeved cards flat, measure the
// longest side with a caliper at the open end of the sleeve, take the largest.
//
// name      thickness  width  height
sleeving_table= [
	["none",   0.34,      63.5,  88.5],
	["single", 0.6,       66.24, 92.29],
	["double", 0.72,      67.5,  94.5]
];

// Bypass the table with measured values, eg -D card_height_override=92.6
card_thickness_override= undef;
card_width_override= undef;
card_height_override= undef;

// "standard" or "system_gateway" -- the original's two tray sets. Counts are
// back-calculated from its tray widths and hold for both of its sleevings.
tray_set= "standard";

// One count for every tray, ignoring tray_table, eg -D card_count_override=40
card_count_override= undef;

// name             emblem dxf           emblem scale  standard  system_gateway
tray_table= [
	["anarch",       "anarch.dxf",        1.0,          30,       25],
	["criminal",     "criminal.dxf",      1.0,          30,       25],
	["shaper",       "shaper.dxf",        1.0,          30,       25],
	["haas_bioroid", "haas_bioroid.dxf",  1.0,          30,       25],
	["jinteki",      "jinteki.dxf",       1.0,          30,       25],
	["nbn",          "nbn.dxf",           1.0,          30,       25],
	// the W runs wide, as on the deck box
	["weyland",      "weyland.dxf",       0.9,          30,       25],
	["neutral",      "",                  1.0,          30,       62]
];

emblem_directory= "emblems/";
emblem_cleanup_epsilon= 0.01;

// ---------------------------------------------------------------------------
// Tray. Cards stand on their short edge, faces towards the drawer's ends; the
// tray's x is the stack, y the card width, z the card height.
// ---------------------------------------------------------------------------
tray_wall= (4 * nozzle_width);
tray_floor= (8 * layer_height);
tray_card_gap= 1.0;       // total across the card's width
tray_stack_slack= 2.0;    // on top of the stack's own thickness
// Side walls stand this far above the card tops, so no sleeve shows; level
// with drawer_rim_over keeps them flush with the drawer rim. Grip comes from the scooped ends.
// Negative leaves the cards standing proud.
tray_wall_over_card= 1.0;
tray_tab_height= 10;      // label tab above the side wall, slides in tab_slot
tray_tab_radius= 3;
tray_emblem_size= 8;      // longest side of the emblem on the tab
tray_emblem_depth= (2 * layer_height);

// The end walls are scooped down to this height so a stack can be pinched out.
tray_scoop_floor= 5;
tray_scoop_half_width= 20;
tray_scoop_fillet= 6;

// ---------------------------------------------------------------------------
// Drawer.
// ---------------------------------------------------------------------------
drawer_wall= (4 * nozzle_width);
drawer_floor= (20 * layer_height);
drawer_tray_gap= 0.2;      // per side, across the trays
drawer_length_slack= 1.6;  // total, along the row of trays
drawer_rim_over= 1.0;      // drawer rim above the card tops
drawer_corner_radius= 3;

// A slot just behind the front face holds one sleeved card, shown through a
// window. Set false for a plain front.
drawer_display= true;
drawer_display_gap= 0.4;   // slot thickness over one card
drawer_window_inset= 4;

// Lengthwise slot through the floor, to push trays up from underneath. 0 drops it.
drawer_floor_slot_width= 18;
drawer_floor_slot_margin= 4;  // solid floor left at each end

// ---------------------------------------------------------------------------
// Outer sleeve. Printed standing on its closed end, so every face is a wall
// and nothing bridges -- hence walls in nozzle multiples here too.
// ---------------------------------------------------------------------------
outer_wall= (5 * nozzle_width);
outer_floor= (10 * nozzle_width);
outer_gap= 0.4;            // per side around the drawer, and behind it
outer_top_gap= 1.0;        // drawer rim to ceiling
outer_corner_radius= 1.5;

// The tabs ride in a slot cut up into the ceiling, open at the front.
tab_slot_gap= 0.4;         // per side, on top of the trays' and drawer's float
tab_slot_headroom= 1.5;
tab_slot_roof= (4 * nozzle_width);

outer_scoop_depth= 18;     // thumb notch in the ceiling at the opening
outer_scoop_half_width= 12;
outer_push_hole= 20;       // through the back wall, to push the drawer out

// Dovetail grooves, two in each face, so sleeves join side by side and stacked:
// slide a rail (part="rail") into a groove on each, from the open end. Profile
// and positions match the original's, so its sleeves join these too. Side
// grooves are measured up from the bottom, so sleeves of different heights
// standing side by side still line up. false drops them.
outer_rails= true;
rail_depth= 1.2;           // into the face; leaves 0.8mm of a 2mm side wall
rail_mouth= 4;             // groove width at the face
rail_base= 6.4;            // groove width at the bottom, the undercut
rail_side_heights= [28.55, 85.65]; // side grooves, centre up from the bottom
rail_top_offset= 19.65;    // top and bottom grooves, centre out from the middle
rail_stop= 4.25;           // solid left at the back, so a rail stops there
// Per face, rail to groove. 0.15 jammed: a rail printed flat comes out a
// little wide at its first layers.
rail_gap= 0.25;

// Height test: a thin slice of the sleeve's cross-section with the floor
// raised to where a card stands in a tray. Print it flat, stand a card in it.
// It carries the rail grooves too, so a rail can be test-fitted.
gauge_length= 8;

drawer_slice_spacing= 10;  // between the drawer and the ring on its plate

csg_overlap= 0.02;
$fn= 64;

// ---------------------------------------------------------------------------
// Derived sizes. Everything below follows from the card.
// ---------------------------------------------------------------------------
sleeving_matches= [
	for (index= [0 : (len(sleeving_table) - 1)])
		if (sleeving_table[index][0] == card_sleeving) index];

assert(
	(len(sleeving_matches) == 1),
	str("unknown card_sleeving \"", card_sleeving, "\" -- see sleeving_table"));

sleeving_row= sleeving_table[sleeving_matches[0]];

card_thickness= is_undef(card_thickness_override) ? sleeving_row[1] : card_thickness_override;
card_width= is_undef(card_width_override) ? sleeving_row[2] : card_width_override;
card_height= is_undef(card_height_override) ? sleeving_row[3] : card_height_override;

assert(
	((tray_set == "standard") || (tray_set == "system_gateway")),
	str("unknown tray_set \"", tray_set, "\" -- use \"standard\" or \"system_gateway\""));

tray_count_column= (tray_set == "standard") ? 3 : 4;

function tray_cards(row) =
	is_undef(card_count_override) ? row[tray_count_column] : card_count_override;

function tray_length(row) =
	((tray_cards(row) * card_thickness) + tray_stack_slack + (2 * tray_wall));

tray_width= (card_width + tray_card_gap + (2 * tray_wall));
tray_wall_top= ((tray_floor + card_height) + tray_wall_over_card);
tray_tab_top= (tray_wall_top + tray_tab_height);

function sum(values, index= 0) =
	(index >= len(values)) ? 0 : (values[index] + sum(values, (index + 1)));

tray_lengths= [for (row= tray_table) tray_length(row)];

drawer_display_slot= (card_thickness + drawer_display_gap);
drawer_front_depth= drawer_display
	? ((2 * drawer_wall) + drawer_display_slot)
	: drawer_wall;

drawer_inner= [
	(sum(tray_lengths) + drawer_length_slack),
	(tray_width + (2 * drawer_tray_gap))];

drawer_size= [
	(drawer_front_depth + drawer_inner[0] + drawer_wall),
	(drawer_inner[1] + (2 * drawer_wall)),
	(drawer_floor + tray_floor + card_height + drawer_rim_over)];

outer_cavity= [
	(drawer_size[0] + outer_gap),
	(drawer_size[1] + (2 * outer_gap)),
	(drawer_size[2] + outer_top_gap)];

outer_ceiling= (outer_floor + outer_cavity[2]);

// Where a tab can be, across the sleeve: against the drawer's far wall, give
// or take how far the tray and the drawer can each shift sideways.
tab_far_face= (outer_wall + outer_gap + drawer_wall + drawer_tray_gap + tray_width);
tab_float= (drawer_tray_gap + outer_gap);
tab_slot_y= [
	((tab_far_face - tray_wall) - tab_float - tab_slot_gap),
	(tab_far_face + tab_float + tab_slot_gap)];
tab_slot_top= (outer_floor + drawer_floor + tray_tab_top + tab_slot_headroom);
has_tab_slot= (tab_slot_top > outer_ceiling);

outer_size= [
	(outer_cavity[0] + outer_wall),
	(outer_cavity[1] + (2 * outer_wall)),
	has_tab_slot
		? (tab_slot_top + tab_slot_roof)
		: (outer_ceiling + outer_wall)];

assert(
	(!outer_rails || (max(rail_side_heights) + (rail_base / 2) < (outer_size[2] - outer_corner_radius))),
	"a side rail groove runs off the top of the sleeve; lower rail_side_heights");

assert(
	(!outer_rails || (rail_depth < outer_wall)),
	"rail_depth has to stay inside outer_wall, or the grooves break into the sleeve");

rail_length= ((outer_size[0] - rail_stop) - 1);

card_headroom= (outer_ceiling - (outer_floor + drawer_floor + tray_floor + card_height));

echo(str("Organizer: ", card_sleeving, "-sleeved cards, ", card_width, " x ",
	card_height, "mm at ", card_thickness, "mm each, ", tray_set, " trays."));
echo(str("Tray: ", tray_width, " wide, side walls ", (tray_wall_top), " tall, tab to ",
	tray_tab_top, "; lengths ", tray_lengths));
echo(str("Drawer: ", drawer_size));
echo(str("Outer: ", outer_size, "; ", card_headroom,
	"mm between a card top and the ceiling."));

// ---------------------------------------------------------------------------
// Shapes
// ---------------------------------------------------------------------------
module rounded_square(size, radius)
{
	offset(r= radius) offset(delta= -radius) square(size);
}

// Maps a 2D shape drawn in (y, z) onto the YZ plane, extruded along +x.
module extrude_along_x(length)
{
	rotate([90, 0, 90]) linear_extrude(height= length) children();
}

// Maps a 2D shape drawn in (x, z) onto the XZ plane, extruded along +y.
module extrude_along_y(length)
{
	translate([0, length, 0]) rotate([90, 0, 0]) linear_extrude(height= length) children();
}

// ---------------------------------------------------------------------------
// Tray
// ---------------------------------------------------------------------------
module tray_scoop_2d()
{
	// U-shaped cut down the middle of the end walls; the closing offset rounds
	// the corners where it meets the wall top
	offset(r= -tray_scoop_fillet) offset(delta= tray_scoop_fillet)
	union()
	{
		translate([(tray_width / 2), tray_wall_top])
		scale([tray_scoop_half_width, (tray_wall_top - tray_scoop_floor)])
		circle(r= 1);

		translate([((tray_width / 2) - tray_scoop_half_width), tray_wall_top])
		square([(2 * tray_scoop_half_width), (2 * tray_scoop_fillet)]);
	}
}

module tray_tab_2d(length)
{
	translate([0, (tray_wall_top - csg_overlap)])
	union()
	{
		rounded_square([length, (tray_tab_height + csg_overlap)], tray_tab_radius);
		square([length, tray_tab_radius]);
	}
}

module tray_emblem_2d(row, length)
{
	translate([(length / 2), (tray_wall_top + (tray_tab_height / 2))])
	scale((min(tray_emblem_size, (length - (2 * tray_tab_radius))) / 76) * row[2])
	// self-touching outlines extrude non-manifold; see deckbox.scad
	offset(delta= emblem_cleanup_epsilon)
	offset(delta= -emblem_cleanup_epsilon)
	import(str(emblem_directory, row[1]));
}

module tray(row)
{
	length= tray_length(row);

	difference()
	{
		union()
		{
			linear_extrude(height= tray_wall_top)
			rounded_square([length, tray_width], 1);

			// the tab sits on the far side wall, the one under tab_slot
			translate([0, (tray_width - tray_wall), 0])
			extrude_along_y(tray_wall)
			tray_tab_2d(length);
		}

		translate([tray_wall, tray_wall, tray_floor])
		cube([(length - (2 * tray_wall)), (tray_width - (2 * tray_wall)), tray_tab_top]);

		translate([-csg_overlap, 0, 0])
		extrude_along_x(length + (2 * csg_overlap))
		tray_scoop_2d();

		// recessed into the inward face, which is the one you see over the cards
		if (len(row[1]) > 0)
		{
			translate([0, (tray_width - tray_wall - csg_overlap), 0])
			extrude_along_y(tray_emblem_depth + csg_overlap)
			tray_emblem_2d(row, length);
		}
	}
}

// ---------------------------------------------------------------------------
// Drawer. Front at x=0, the end that faces out of the sleeve.
// ---------------------------------------------------------------------------
module drawer(
	inner_length= drawer_inner[0],
	display= drawer_display)
{
	slot_width= (card_width + (2 * drawer_tray_gap) + tray_card_gap);
	front_depth= display ? drawer_front_depth : drawer_wall;
	length= (front_depth + inner_length + drawer_wall);

	difference()
	{
		linear_extrude(height= drawer_size[2])
		rounded_square([length, drawer_size[1]], drawer_corner_radius);

		translate([front_depth, drawer_wall, drawer_floor])
		cube([inner_length, drawer_inner[1], drawer_size[2]]);

		if (drawer_floor_slot_width > 0)
		{
			translate([
				(front_depth + drawer_floor_slot_margin),
				((drawer_size[1] - drawer_floor_slot_width) / 2),
				-csg_overlap])
			cube([
				(inner_length - (2 * drawer_floor_slot_margin)),
				drawer_floor_slot_width,
				(drawer_floor + (2 * csg_overlap))]);
		}

		if (display)
		{
			// open at the top, so the card drops in from above
			translate([drawer_wall, ((drawer_size[1] - slot_width) / 2), drawer_floor])
			cube([drawer_display_slot, slot_width, drawer_size[2]]);

			translate([
				-csg_overlap,
				(((drawer_size[1] - slot_width) / 2) + drawer_window_inset),
				(drawer_floor + drawer_window_inset)])
			cube([
				(drawer_wall + (2 * csg_overlap)),
				(slot_width - (2 * drawer_window_inset)),
				(drawer_size[2] - drawer_floor - (2 * drawer_window_inset))]);
		}
	}
}

// ---------------------------------------------------------------------------
// Outer sleeve. Open at x=0, closed at the back.
// ---------------------------------------------------------------------------
module outer_profile_2d()
{
	rounded_square([outer_size[1], outer_size[2]], outer_corner_radius);
}

module outer_cavity_2d(floor_height= outer_floor)
{
	translate([outer_wall, floor_height])
	square([outer_cavity[1], (outer_ceiling - floor_height)]);

	if (has_tab_slot)
	{
		translate([tab_slot_y[0], (outer_ceiling - csg_overlap)])
		square([(tab_slot_y[1] - tab_slot_y[0]), ((tab_slot_top - outer_ceiling) + csg_overlap)]);
	}
}

// One groove: mouth on the face at y=0, undercut going in towards +y.
module rail_groove_2d()
{
	polygon([
		[-(rail_mouth / 2), -csg_overlap],
		[(rail_mouth / 2), -csg_overlap],
		[(rail_mouth / 2), 0],
		[(rail_base / 2), rail_depth],
		[-(rail_base / 2), rail_depth],
		[-(rail_mouth / 2), 0]]);
}

// All eight, in the sleeve's (y, z) cross-section.
module outer_rails_2d()
{
	for (z= rail_side_heights)
	{
		translate([0, z]) rotate(-90) rail_groove_2d();
		translate([outer_size[1], z]) rotate(90) rail_groove_2d();
	}

	for (y= [((outer_size[1] / 2) - rail_top_offset), ((outer_size[1] / 2) + rail_top_offset)])
	{
		translate([y, 0]) rail_groove_2d();
		translate([y, outer_size[2]]) rotate(180) rail_groove_2d();
	}
}

// Double dovetail filling two facing grooves, printed flat on one wide face.
module rail()
{
	half= (rail_depth - rail_gap);
	mouth= (rail_mouth - (2 * rail_gap));
	base= (rail_base - (2 * rail_gap));

	rotate([90, 0, 90])
	linear_extrude(height= rail_length)
	translate([(base / 2), 0])
	polygon([
		[-(base / 2), 0],
		[(base / 2), 0],
		[(mouth / 2), half],
		[(base / 2), (2 * half)],
		[-(base / 2), (2 * half)],
		[-(mouth / 2), half]]);
}

module outer()
{
	difference()
	{
		extrude_along_x(outer_size[0])
		outer_profile_2d();

		if (outer_rails)
		{
			translate([-csg_overlap, 0, 0])
			extrude_along_x((outer_size[0] - rail_stop) + csg_overlap)
			outer_rails_2d();
		}

		translate([-csg_overlap, 0, 0])
		extrude_along_x(outer_cavity[0] + csg_overlap)
		outer_cavity_2d();

		// thumb notch through the ceiling, to reach the drawer's front edge
		translate([0, (outer_size[1] / 2), (outer_ceiling - csg_overlap)])
		scale([outer_scoop_depth, outer_scoop_half_width, 1])
		cylinder(h= (outer_size[2] - outer_ceiling + (2 * csg_overlap)), r= 1);

		translate([
			(outer_cavity[0] - csg_overlap),
			(outer_size[1] / 2),
			(outer_floor + (drawer_size[2] / 2))])
		rotate([0, 90, 0])
		cylinder(h= (outer_wall + (2 * csg_overlap)), d= outer_push_hole);
	}
}

module gauge(floor_height= (outer_floor + drawer_floor + tray_floor))
{
	linear_extrude(height= gauge_length)
	difference()
	{
		outer_profile_2d();
		outer_cavity_2d(floor_height= floor_height);
		if (outer_rails) outer_rails_2d();
	}
}

// A drawer one tray long, plated with a slice of the sleeve at its real floor
// height. Load the tray with cards, stand it in the drawer and push the drawer
// through the ring: tray in drawer, drawer in sleeve, tab in its slot.
module drawer_slice()
{
	drawer(inner_length= (max(tray_lengths) + drawer_length_slack), display= false);

	translate([0, (drawer_size[1] + drawer_slice_spacing), 0])
	gauge(floor_height= outer_floor);
}

// ---------------------------------------------------------------------------
// Assembly, for renders and for eyeballing clearances
// ---------------------------------------------------------------------------

// How far the drawer stands out of the sleeve; renders pull it half out so the
// trays show.
assembly_pull= 0;

// Colours only reach the OpenCSG preview, which is what the renders use.
assembly_tray_colors= [
	["anarch", "DarkOrange"], ["criminal", "RoyalBlue"], ["shaper", "LimeGreen"],
	["haas_bioroid", "MediumPurple"], ["jinteki", "Crimson"], ["nbn", "Gold"],
	["weyland", "DarkOliveGreen"], ["neutral", "Silver"]];

function assembly_tray_color(name) =
	let (matches= [for (row= assembly_tray_colors) if (row[0] == name) row[1]])
	(len(matches) > 0) ? matches[0] : "Silver";

module assembly()
{
	color("DimGray") outer();

	translate([-assembly_pull, (outer_wall + outer_gap), outer_floor])
	{
		color("SlateGray") drawer();

		for (index= [0 : (len(tray_table) - 1)])
		{
			translate([
				(drawer_front_depth + (drawer_length_slack / 2) +
					sum([for (before= [0 : 1 : (index - 1)]) tray_lengths[before]])),
				(drawer_wall + drawer_tray_gap),
				drawer_floor])
			color(assembly_tray_color(tray_table[index][0]))
			tray(tray_table[index]);
		}
	}
}

tray_matches= [
	for (index= [0 : (len(tray_table) - 1)])
		if (tray_table[index][0] == faction) index];

if (part == "outer")
{
	// standing on its closed end: the back wall is the first layer
	translate([0, 0, outer_size[0]]) rotate([0, 90, 0]) outer();
}
else if (part == "drawer")
{
	drawer();
}
else if (part == "tray")
{
	assert(
		(len(tray_matches) == 1),
		str("unknown faction \"", faction, "\" -- see tray_table"));

	tray(tray_table[tray_matches[0]]);
}
else if (part == "rail")
{
	rail();
}
else if (part == "gauge")
{
	gauge();
}
else if (part == "drawer_slice")
{
	drawer_slice();
}
else
{
	assert(
		(part == "assembly"),
		str("unknown part \"", part,
			"\" -- use \"outer\", \"drawer\", \"tray\", \"rail\", \"gauge\", \"drawer_slice\" or \"assembly\""));

	assembly();
}
