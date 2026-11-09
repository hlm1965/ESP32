// Units: mm. EVB orientation: Ethernet connector towards +Y.
$fn = 64;
eps = 0.1;
render_part = "top"; // "top", "bottom"
board_variant = "evb"; // "evb" (ESP32-EVB), "poe2" (ESP32-POE2)

case_width = 82;
case_length = 130;
total_height = 35;
wall_thickness = 2.5;
front_thickness = 3.55;
corner_radius = 4;
top_edge_radius = 0.8;
lip_h = 2;

// Newhaven NHD-2.8R-CSXP-BREAKOUT.
tft_glass_w = 50;
tft_glass_l = 69.20;
glass_clearance = 0.60; // Total clearance, not per side.
disp_hole_dx = 62.50;
disp_hole_dy = 78.70;

evb_pcb_w = 75.184; // 2.96 inches.
evb_pcb_l = 75.184;
evb_hole_pitch = 68;
poe_pcb_w = 60;
poe_pcb_l = 90;
esp_post_h = 4;
esp_margin_y = wall_thickness + 6;

cable_w = 22;
cable_l = 22;
m3_pilot_r = 1.25;
m3_clear_r = 1.60;
board_pilot_r = 1.1; // Existing board-standoff pilot diameter: 2.2 mm.
screw_head_r = 3;
screw_head_h = 2;
rect_post_size = 4.8;

assert(render_part == "top" || render_part == "bottom",
       "render_part must be top or bottom");
assert(board_variant == "evb" || board_variant == "poe2",
       "board_variant must be evb or poe2");

module rounded_box(w, l, h, r) {
    translate([r, r, 0])
        minkowski() {
            cube([w - 2*r, l - 2*r, h - 0.1]);
            cylinder(r=r, h=0.1);
        }
}

module top_rounded_shell(w, l, h, r_xy, r_top) {
    r_inner = max(0.1, r_xy - r_top);
    hull() {
        translate([r_xy, r_xy, r_top])
            minkowski() {
                cube([w - 2*r_xy, l - 2*r_xy, 0.01]);
                intersection() {
                    sphere(r=r_top);
                    translate([-r_top, -r_top, -r_top])
                        cube([2*r_top, 2*r_top, r_top]);
                }
                cylinder(r=r_inner, h=0.01);
            }
        translate([r_xy, r_xy, r_top])
            minkowski() {
                cube([w - 2*r_xy, l - 2*r_xy, h - r_top - 0.01]);
                cylinder(r=r_xy, h=0.01);
            }
    }
}

module corner_grid(w, l, offset) {
    for (x = [offset, w - offset], y = [offset, l - offset])
        translate([x, y, 0]) children();
}

module disp_mount_grid() {
    for (x = [-disp_hole_dx/2, disp_hole_dx/2],
         y = [-disp_hole_dy/2, disp_hole_dy/2])
        translate([case_width/2 + x, case_length/2 + y, 0])
            children();
}

function board_holes(variant) =
    variant == "evb"
    // Missing upper-left hole; 68 mm pitch in X and Y.
    ? let(x0 = (case_width - evb_hole_pitch)/2,
          y0 = esp_margin_y + (evb_pcb_l - evb_hole_pitch)/2)
        [[x0, y0],
         [x0 + evb_hole_pitch, y0],
         [x0 + evb_hole_pitch, y0 + evb_hole_pitch]]
    // POE2 coordinates from lower-left PCB corner: X 4/56, Y 29/79.
    : let(x0 = (case_width - poe_pcb_w)/2)
        [for (x = [4, 56], y = [29, 79])
            [x0 + x, esp_margin_y + y]];

module board_standoffs() {
    for (p = board_holes(board_variant))
        translate([p[0], p[1], wall_thickness - eps])
            difference() {
                cylinder(r=3, h=esp_post_h + eps);
                translate([0, 0, -eps])
                    cylinder(r=board_pilot_r, h=esp_post_h + 3*eps);
            }
}

module build_top_part() {
    top_h = total_height - wall_thickness;
    post_h = top_h - front_thickness - lip_h;
    win_w = tft_glass_w + glass_clearance;
    win_l = tft_glass_l + glass_clearance;

    difference() {
        union() {
            difference() {
                top_rounded_shell(case_width, case_length, top_h,
                                  corner_radius, top_edge_radius);
                translate([wall_thickness, wall_thickness, front_thickness])
                    rounded_box(case_width - 2*wall_thickness,
                                case_length - 2*wall_thickness,
                                top_h,
                                max(0.5, corner_radius - wall_thickness));
            }
            corner_grid(case_width, case_length,
                        wall_thickness + rect_post_size/2)
                translate([-rect_post_size/2, -rect_post_size/2,
                           front_thickness - eps])
                    cube([rect_post_size, rect_post_size, post_h + eps]);
        }
        translate([(case_width - win_w)/2, (case_length - win_l)/2, -eps])
            cube([win_w, win_l, top_h + 2*eps]);
        corner_grid(case_width, case_length,
                    wall_thickness + rect_post_size/2)
            translate([0, 0, front_thickness + 2])
                cylinder(r=m3_pilot_r, h=top_h);
        // 2.55 mm blind depth; leave 1 mm front skin.
        disp_mount_grid()
            translate([0, 0, 1])
                cylinder(r=m3_pilot_r, h=front_thickness);
    }
}

module build_bottom_part() {
    lip_w = case_width - 2*wall_thickness - 0.4;
    lip_l = case_length - 2*wall_thickness - 0.4;
    lip_r = max(0.5, corner_radius - wall_thickness - 0.2);
    // Keep the knockout at the same location for either board.
    cable_y = esp_margin_y + poe_pcb_l + 2.5;

    render(convexity=10)
        difference() {
            union() {
                rounded_box(case_width, case_length, wall_thickness,
                            corner_radius);
                translate([wall_thickness + 0.2, wall_thickness + 0.2,
                           wall_thickness - eps])
                    difference() {
                        rounded_box(lip_w, lip_l, lip_h + eps, lip_r);
                        translate([1.5, 1.5, -eps])
                            rounded_box(lip_w - 3, lip_l - 3,
                                        lip_h + 3*eps,
                                        max(0.5, lip_r - 1.5));
                    }
                board_standoffs();
                corner_grid(case_width, case_length,
                            wall_thickness + rect_post_size/2)
                    translate([-rect_post_size/2, -rect_post_size/2,
                               wall_thickness - eps])
                        cube([rect_post_size, rect_post_size, lip_h + eps]);
            }
            corner_grid(case_width, case_length,
                        wall_thickness + rect_post_size/2) {
                translate([0, 0, -eps])
                    cylinder(r=m3_clear_r,
                             h=wall_thickness + lip_h + 3*eps);
                translate([0, 0, -eps])
                    cylinder(r=screw_head_r, h=screw_head_h + eps);
            }
            translate([(case_width - cable_w)/2, cable_y, 0.5])
                cube([cable_w, cable_l, wall_thickness + eps]);
        }
}

if (render_part == "top")
    build_top_part();
else
    build_bottom_part();
