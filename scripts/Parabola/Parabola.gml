#macro PARABOLA_GAMESPEED_TYPE gamespeed_fps

/**
 * Function Description
 * @param {real} [_start_x]=0 Description
 * @param {real} [_start_y]=0 Description
 * @param {real} [_end_x]=0 Description
 * @param {real} [_end_y]=0 Description
 * @param {real} [_duration]=0 Description
 * @param {real} [_height]=0 Description
 * @param {real} [_distance]=0 Description
 * @param {real} [_direction]=1 Description
 * @param {bool} [_apply]=false Description
 */
function Parabola(_start_x = 0, _start_y = 0, _end_x = 0, _end_y = 0, _duration = 0,  _height = 0, _distance = 0, _direction = 1, _apply = false) constructor {
	
	__ = {}
	//with(__){
	    // setup variable
    	start_x					= _start_x;	
    	start_y					= _start_y;	
    	end_x					= _end_x;	
    	end_y					= _end_y;	
    	time		    		= _duration;	
        apex_h					= _height;	
    	length					= _distance;	
		dir       				= _direction;     
        
        x				= 0; //la position x du projectile a retourner
        y				= 0; ////la position y du projectile a retourner
        //init
        apex_x			= 0;
        apex_y			= 0;
        travel_speed    = 0;
        apex_h			= 0;
        start_pa			= 0;
        end_pc			= 0;
        apex_pb			= 0;
        travel_time		= 0;
        
        on_goal		= false;
        on_goal_callback = function(){}
		on_goal_arg = undefined;
    
        game_speed      = game_get_speed(PARABOLA_GAMESPEED_TYPE);
        
        angle		= 0;
        angle_speed	= 0;
        
        if _apply {
        	apply();
        }
        
    set = function(_start_x, _start_y, _end_x, _end_y, _duration = time, _height = apex_h, _distance = length, _direction = dir){
       
    	start_x					= _start_x;	
        start_y					= _start_y;	
		end_x					= _end_x;	
		end_y					= _end_y;	
        time		    		= _duration;	
        length					= _distance;	
        apex_h					= _height;	
        dir       				= _direction;
        
        apply();
        
    }
    start = function(_x, _y){
    	start_x = _x;
    	start_y = _y;
    	return self;
    }
    ///@desc    the time it takes to a point to run the parabola from start to end.
    ///         It calculated a travel speed value. Negative value are absoluted
    duration = function(_duration){
    	time = abs(_duration);
        travel_time = abs(_duration) * game_speed
    	return self;
    }
    height = function(_height){
    	apex_h = _height;
    	return self;
    }
    apex = function(_x, _y){
        //apex_x = _x
        //apex_y = _y
        //length = (apex_x - start_x)*2
        //var _p_dir = point_direction(start_x, start_y, apex_x, apex_y)
        //
        //manually calculated from the apex_x.
        
        //calculated to set apex\x/y when apply
        apex_h = start_y - apex_y
        var _p_dir = point_direction(start_x, start_y, _x, _y)
        //
        var _l = (_x - start_x)*2
        var _h = _l * tan(_p_dir)
        
        
        //by distance
        goal_By_Distance(_l, _h)
        end_x = start_x + _l
        end_y = start_y - _h*0.5
        length = _l
        //by lengthdir
        //goal_By_LengthDir( ,_p_dir)
        
    }
    direction = function(_direction){
    	dir = _direction;
    	return self;
    }
    goal = function(_x, _y){
    	end_x = _x;
    	end_y = _y;
    	
    	length = end_x - start_x;//max(start_x, end_x) - min(start_x, end_x);
    	return self;
    }
    goal_By_Distance = function(_distance_w, _distance_h){
    	end_x = start_x + _distance_w;
    	end_y = start_y + _distance_h;
        length = _distance_w;
    	return self;
    }
    
    ///@desc   calculate the goal point of the parabola with lengthdir.
    ///        As such, the distance passed is no more the horizontal distance but the length of the radius from the start point.  
    goal_By_LengthDir = function(_distance, _direction, _distance_y = undefined){
        _distance_y = _distance_y == undefined ? _distance : _distance_y
        
		end_x = start_x + lengthdir_x(_distance, _direction);
		end_y = start_y + lengthdir_y(_distance_y, _direction);
		length = end_x - start_x;
		return self;
    }
    
    apply = function(){
    	x               = start_x;
        y               = start_y;
    	travel_time		= time * game_speed;
     
        apex_x			= start_x + length*0.5;
        apex_y			= (min(start_y, end_y) + max(start_y, end_y))*0.5 - apex_h;//(end_y + start_y)*0.5 + apex_h // * sign(start_x - end_x);
        travel_speed    = length/travel_time;

        start_pa 		= (end_y - start_y)/((end_x - start_x)*(end_x - apex_x)) - (apex_y - start_y)/((apex_x - start_x)*(end_x - apex_x));
		apex_pb			= (apex_y - start_y)/(apex_x - start_x) - start_pa*(apex_x + start_x);
		end_pc			= start_y - start_pa*start_x*start_x - apex_pb*start_x;
		
		on_goal 		= false;
    }
    get_Y = function(_x){
        return  start_pa*_x*_x + apex_pb*_x + end_pc;
    }
    point_Is_At = function(_position){
        var _x =  lerp(start_x, start_x + length, _position ); //start_x + length * _position
        var _y = get_Y(_x);
        return x >= _x && y >= _y ;
    }
    point_Set = function(_position){
    	x = start_x + lerp(0, length, _position ) ;
    	//x = start_x + length * _position
    	y = get_Y(x);
    }
    point_Get_X = function(_position){
    	return start_x + lerp(0, length, _position );
    }
    point_Get_Y = function(_position){
    	var _x = point_Get_X(_position);
    	return get_Y(_x);
    }
    point_Distance_X = function(_distance){
    	
    }
    
    rotate = function(_speed = angle_speed, _direction = 1){
    	
        angle = angle + _speed * _direction;
        return self;
    }
    ///@desc    update the x and y coordinate of a point on the parabola with a given speed.
    ///         If no speed is given, the travel speed (from the duration) is used instead.
    ///         The function also set an onGoal boolean when the point reach, well, the goal
    follow = function(_speed = travel_speed){
    	x += _speed;
    	y = get_Y(x);
        if (abs(x - end_x) <= 0 && abs(y - end_y) <= 0) && on_goal = false{
    	//if (x >= end_x && y >= end_y) && on_goal = false{
            x = end_x;
            y = end_y;
    		on_goal = true;
    		__call_function_ext(on_goal_callback, on_goal_arg);
    	}
        return self;
    }
	on_Goal = function(_callback, _data = undefined){
	  	on_goal_callback = _callback;
	  	on_goal_arg = _data;
	  	return self;
	}
    draw = function(_seg = 16){
        var _i = 0; repeat(_seg-1){
           var _col = make_colour_hsv(255/_seg*_i, 255, 255);
           var _x = start_x + (length / _seg) * _i;
           var _y = get_Y(_x);
           draw_circle_color(_x,_y, 2, _col, _col, false);
           var _x2 = start_x + (length / _seg) * (_i+1);
           var _y2 = get_Y(_x2);
           draw_line(_x,_y, _x2, _y2);
           _i++;
        }
        //draw point
        //end
        draw_circle_color(end_x, end_y, 4, c_red, c_red, false);
        //start
        draw_circle_color(start_x, start_y, 4, c_green, c_green, false);
        //apex
        draw_circle_color(apex_x, apex_y, 4, c_orange, c_orange, false);
        //pc
        draw_circle(start_x + (apex_x - start_x)*2, start_y, 4,false);
    }
    __call_function_ext = function(_function, _args){
        if (is_undefined(_args))
		{
			return _function();
		}
        return _function(_args);
    }
}
