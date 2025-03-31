if mouse_check_button_pressed(mb_left){
	trajectory.apply();
    run = true;
    //trajectory.get_Point(1.1)
}

if keyboard_check_pressed(vk_right)
{
    key++
    key = clamp_wrap(key, 0, 3)
    parabola_selection(key)
}
if keyboard_check_pressed(vk_left)
{
    key--
    key = clamp_wrap(key, 0, 3)
    parabola_selection(key)
}


//trajectory.goal(mouse_x, mouse_y).apply()

if run{ 
    // Example usage in a Step Event
    //test.update_position();
    //x = test.px
    //y = test.py
    
     trajectory.follow().rotate(5, -1);
     x = trajectory.x;
     y = trajectory.y;
     image_angle = trajectory.angle;
    
    if trajectory.point_Is_At(1){
        //show_debug_message("REACH")
        //trajectory.point_Set(1)
        //x = trajectory.x;
    	//y = trajectory.y;
        //run = false;
    }

}