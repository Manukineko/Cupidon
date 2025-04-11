if mouse_check_button_pressed(mb_left){
    //random
    if fullRandom{
        stopOnEnd = choose(true, false);
        internal = choose(true, false);
        trajectory.motion_Internal_Transforms(internal);
        fireOnEnd = choose(true, false);
        isometric = choose(true, false);
        rotationNumber = irandom_range(-1, 4);
        fullRotation = choose(true, false);
        aCurve = choose(Linear, BounceOut, CubicInOut, WeirdOne, undefined);
        trajectory.motion_Set_AnimCurve(aCurve);
        if is_undefined(aCurve){
            aCurveName = "none";
        } else {
            aCurveName = animcurve_get(aCurve).name;
        }
    }
    
    //defined
    trajectory.motion_Reset()
    .anchor_Motion(); // Ugly hack to reset the curve properly if the Left Mouse Buttonis pressed (Play) instead of the Righ Mouse Button (proper Reset)
    target = instance_create_depth(mouse_x, mouse_y, 0, Target);
    trajectory.end_Point(target.x , target.y);
    trajectory.apex_Height(50, 0.5, isometric);
    
    trajectory.anchor_On_End(function(){
     
        var _particle = part_system_create(motion_done);
        part_system_position(_particle, x,y);
        show_debug_message("End Callback FIRED");
        
        instance_destroy(target);
        target = undefined;
    }, , stopOnEnd);
    trajectory.anchor_Speed(3)
        .anchor_Rotation(15, rotationNumber , fullRotation)
        .motion_Play();
}
if mouse_check_button_pressed(mb_right){
    trajectory.motion_Reset();
}
if keyboard_check_pressed(vk_space){
    trajectory.motion_Toggle_Pause();
}

if keyboard_check_pressed(ord("S")){
    stopOnEnd = !stopOnEnd;
}
if keyboard_check_pressed(ord("I")){
    internal =! internal;
    trajectory.motion_Internal_Transforms(internal);
}
if keyboard_check_pressed(ord("F")){
    fireOnEnd =! fireOnEnd;
}
if keyboard_check_pressed(ord("Z")){
    isometric =! isometric;
}
if keyboard_check(ord("A")){
        
    switch(keyboard_key){
        case ord("1") : aCurve = Linear; 
            aCurveSelected = true;  
            aCurveName = animcurve_get(aCurve).name; 
        break;
        case ord("2") : aCurve = BounceOut; 
            aCurveSelected = true;  
            aCurveName = animcurve_get(aCurve).name; 
        break;
        case ord("3") : aCurve = CubicInOut; 
            aCurveSelected = true;  
            aCurveName = animcurve_get(aCurve).name; 
        break;
        case ord("4") : aCurve = WeirdOne;
            aCurveSelected = true;  
            aCurveName = animcurve_get(aCurve).name;  
        break;
        default : if !aCurveSelected{
            aCurve = undefined;
            aCurveName = "none"; 
        } 
        break;
    }
}
if keyboard_check_released(ord("A")){
    aCurveSelected = false;
    trajectory.motion_Set_AnimCurve(aCurve);
    
}
if keyboard_check_pressed(ord("D")){
    drawCurve =! drawCurve;
}
if keyboard_check_pressed(ord("R")){
    rotationNumber++;
    if rotationNumber >= 5 rotationNumber = -1;
}
if keyboard_check_pressed(ord("T")){
    fullRotation =! fullRotation;
}
if keyboard_check_pressed(vk_enter){
    fullRandom =! fullRandom
}

trajectory.anchor_Motion(fireOnEnd).anchor_Orient();

x = trajectory.x;
y = trajectory.y;    
image_angle = trajectory.angle;