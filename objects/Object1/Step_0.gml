if mouse_check_button_pressed(mb_left){
    //random
    // trajectory.end_Point(Target.x , Target.y);
    // trajectory.apex_Height(100, 0.5, false);
    // trajectory.set_Motion_Curve(choose(Linear, ElasticOut, WeirdOne, BounceOut, CubicOut));
    // trajectory.on_End(function(){
    //     trajectory.motion_pause();
    //     var _particle = part_system_create(motion_done);
    //     part_system_position(_particle, x,y);
    //     show_debug_message("End Callback FIRED");  
    // });
    // trajectory.anchor_Speed(random_range(1, 5))
    //     .rotation(,irandom_range(-1, 5), choose(true, false))
    //     .motion_play();
        
    //defined
    trajectory.end_Point(Target.x , Target.y);
    trajectory.apex_Height(50, 0.5, true);
    //trajectory.motion_Set_AnimCurve(Linear);
    trajectory.anchor_On_End(function(){
        trajectory.motion_pause();
        // var _particle = part_system_create(motion_done);
        // part_system_position(_particle, x,y);
        // show_debug_message("End Callback FIRED");  
    });
    trajectory.anchor_Speed(3)
        //.rotation(, 1 , true)
        .motion_play();
}
if mouse_check_button_pressed(mb_right){
    trajectory.motion_reset();
}
if keyboard_check_pressed(vk_space){
    trajectory.motion_Toggle_Pause();
}

trajectory.anchor_Motion(true)//.anchor_Rotate()//.anchor_Orient();

x = trajectory.x;
y = trajectory.y;    
image_angle = trajectory.angle;