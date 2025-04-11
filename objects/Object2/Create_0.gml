draw_set_color(c_black);
trajectory = new Cupidon();
trajectory.add_Checkpoint(0.10, function (){
    var _particle = part_system_create(motion_done);
    part_system_position(_particle, x,y);
    show_debug_message("Reached 0.25");
});
 trajectory.add_Checkpoint(0.50, function (){
    var _particle = part_system_create(motion_done);
    part_system_position(_particle, x,y);
    show_debug_message("Reached 0.25");
})
//trajectory.point_Set(0)