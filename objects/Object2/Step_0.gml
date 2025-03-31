if mouse_check_button_pressed(mb_left){
    
	
    trajectory.end_Point(Target.x , Target.y)
    //var _dis = point_distance(xx,yy, Target.x, Target.y);
    //var _dir = point_direction(xx,yy, Target.x, Target.y);
    //trajectory.start_Point(xx, yy)
    	//.end_By_Direction(_dis, _dir)
    	trajectory.apex_Height(100, 0.5, true)
    	//trajectory.duration(1.5)
    	////.set_Motion_Curve(CubicIn)
        //trajectory.set_Motion_Curve(BounceOut)
        trajectory.add_Checkpoints(0.15, function (){
            var _particle = part_system_create(motion_done);
            part_system_position(_particle, x,y);
            show_debug_message("Reached 0.25");
        })
        trajectory.add_Checkpoints(0.50, function (){
            var _particle = part_system_create(motion_done);
            part_system_position(_particle, x,y);
            show_debug_message("Reached 0.25");
        })
        
    	trajectory.on_End(function(){
	        trajectory.pause();
	        var _particle = part_system_create(motion_done);
	        part_system_position(_particle, x,y);
	        show_debug_message("End Callback FIRED");  
	    })
    	trajectory.motion_Speed(3).rotation(,2, true).play();
    // spd = 0;
    // run = true;
    //trajectory.get_Point(1.1)
}
if mouse_check_button_pressed(mb_right){
    trajectory.stop()
}
if keyboard_check_pressed(vk_space){
    trajectory.toggle_Pause()
}


//trajectory.goal(mouse_x, mouse_y).apply()

//if run{ 
    // Example usage in a Step Event
    //test.update_position();
    //x = test.px
    //y = test.py
    //spd += 0.01
    //trajectory.get_point_by_distance(spd)
    trajectory.motion(true)//.rotate()//point_Set(spd)
    if trajectory.motion_Is_At(0){
        var _particle = part_system_create(motion_done);
        part_system_position(_particle, x,y);
        show_debug_message("Reached 0.25");  
    }
     
     x = trajectory.x;
     y = trajectory.y;    
    image_angle = trajectory.angle

//}