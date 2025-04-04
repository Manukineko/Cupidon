if mouse_check_button_pressed(mb_left){
    
    trajectory.end_Point(Target.x , Target.y);
    trajectory.apex_Height(100, 0.5, false);
    trajectory.set_Motion_Curve(choose(Linear, ElasticOut, WeirdOne, BounceOut, CubicOut));
    trajectory.on_End(function(){
        trajectory.motion_pause();
        var _particle = part_system_create(motion_done);
        part_system_position(_particle, x,y);
        show_debug_message("End Callback FIRED");  
    });
    trajectory.motion_Speed(random_range(1, 5))
        .rotation(,irandom_range(-1, 5), choose(true, false))
        .motion_play();
}
if mouse_check_button_pressed(mb_right){
    trajectory.motion_stop();
}
if keyboard_check_pressed(vk_space){
    trajectory.motion_toggle_Pause();
}

trajectory.motion(true).rotate();

x = trajectory.x;
y = trajectory.y;    
image_angle = trajectory.angle;