/// @category Cupidon
/// @title API

/// @constructor
/// @func Cupidon([_start_x], [_start_y], [_distance_h], [_distance_v], [_height], [_isometric], [_internal], [_scope])
/// @desc Create a Parabola as a Quadratic Bézier Curve. The parabola has an anchor point with an x and y coordinate as well as an angle to use in order to attach an object or any thing else that can use them.
///			It also has methods to update the anchor position and rotation along the Parabola.
/// @param {real} [_start_x] The start point x coordinate
/// @param {real} [_start_y] The start point y coordinate
/// @param {real} [_distance_h]=0 The horizontal distance to the end point
/// @param {real} [_distance_v]=0 The vertical distance to the end point
/// @param {real} [_height]=0 the height of the parabola
/// @param {bool} [_isometric]=false calculate the height as kind of fake isometric view. Default is orthogonal
/// @param {bool} [_internal]=true Manage all anchor's transforms calculation internally with the `anchor_Motion` method
/// @param {id.instance} [_scope]=other the scope. used internally to set the start point to the calling instance by default.
function Cupidon(_start_x = undefined, _start_y = undefined, _distance_h = 0, _distance_v = 0, _height = 0, _isometric = false, _internal = true, _scope = other) constructor {
	// set the internal transform globally
	internal_transforms = _internal;
    
    // Points de départ, d'apex et d'arrivée
    start_x		= 0; // x coordinate of the starting point of the parabola
    start_y		= 0; // y coordinate of the starting point of the parabola
    control_x	= 0; // x coordinate of the control point of the parabola
    control_y	= 0; // y coordinate of the parabola control point
    end_x		= 0; // x coordinate of the ending point of the parabola
    end_y		= 0; // y coordinate of the ending point of the parabola
    
    // The anchor point
    x			= start_x; // x coordinate of the anchor
    y			= start_x; // y coordinate of the anchor
    angle       = 0; // the angle of the anchor (default: right)
    
    distance         = 0; // distance between the starting point and the ending point
    distance_h		 = 0; // distance between `start_x` and `end_x`
    distance_v		 = 0; // distance between `start_y` and `end_y`
    length           = 0; // the real length of the parabola
    height           = 0; // cached height from the `apex_Height_*` method` - Probably useless
    height_ortho     = 0; // parabola vertex height (orthogonal - relative to start_y or end_y)
    height_iso       = 0; // parabola vertex height (isometric - relative to the middle point of the distance between the start point and the end point)
    
    // parabola's vertex coordinate
    vertex_x = 0;
    vertex_y = 0;
    
    game_speed      = game_get_speed(CUPIDON_GAMESPEED_TYPE);
    motion_time		= 0; // time in second that take to go through the curve between the start and the end point.
    motion_steps	= 0; // time in steps that take to go through the curve between the start and the end point.
    motion_rate	    = 0; // calculated speed to update the position (motion_ratio) of the anchor each frame on the parabola
    motion_ratio    = 0; // the incremented position to move the anchor on the parabola.
    curve_ratio 	= 0; // the interpolation used for the motion Animation Curve
    m_next_ratio    = 0; // track the next position
    m_prev_ratio    = 0; // track the previous position
    motion_curve	= undefined; // the animation curve set for the Parabola
	motion_curve_channel = undefined; // cache the channel to use in the animation curve
    
    rotation_rate   		= 0; // the rotation rate of the anchor
    rotation_rate_default	= 360/game_speed
    rotation_initialized	= false; // manage the rotation initialization when switching between internal or mnethod management
    //orientation_initialized = false; // manage the Orientation initialization when switching between internal or mnethod management
    //scale_rate
    //scale_initialized
    
    cycles_amount   		= 0; // number of full rotation
    force_cycle				= false; // force only full rotations.
    force_last_calculations = false; // If rotations are handled externally (`rotate` method) force a last calculation when the motion is paused.
    
    // bool
    is_playing		= false; // the anchor moves on the parabola
    is_stopped		= true;  // the anchor's motion is reseted to the start
    is_paused		= false; // the anchor's motion is paused
    is_completed	= false; // the anchor's motion is completed (position is > 1)
    at_end          = false; // turn `true` on the parabola completion fram (position == 1), then turn back to false
    auto_pause_on_end = false; // booleen to auto pause the Anchor once it reaches the end of the parabola.
    finalize		= false; // internal boolean to check the unique execution of further operations when the parabola is completed.
    
    on_end_callback	= undefined; // store the callback to be fired when the anchor reaches the end point
    on_end_arg		= undefined; // store the argument for the `on_end_callback`
    checkpoints 	= []; // array that stores the parabola's checkpoints
    
    motion_unit		= CUPIDON_DEFAULT_MOTION_UNIT; // the motion unit to use for calcute the anchor speed
    
#region Parabola
    /// @slug parabola-intro
    
    ///@method simple_Parabola(_start_x, _start_y, [_distance_h], [_distance_v], [_height], [_isometric])
    /// @desc  Create a simple parabola (mimicing parametric equations) with default values
    /// @param {real} _start_x start point coordinate
    /// @param {real} _start_y end point coordinate
    /// @param {real} [_distance_h]=100 the horizontal distance to the end point
    /// @param {real} [_distance_v]=0 the vertical distance to the end point
    /// @param {real} [_height]=100 the height of the parabola
    /// @param {bool} [_isometric]=false toogle the fake isometric calculation
    /// @returns {struct} self 
    simple_Parabola = function(_start_x, _start_y, _distance_h = 100, _distance_v = 0, _height = 100, _isometric = false){
        start_Point(_start_x, _start_y);
        end_By_Distance(_distance_h, _distance_v);
        apex_Height(_height, 0.5, _isometric);
        return self;
     }
    /// @method start_Point(x,y)
    /// @desc Define the starting point
    /// @arg {real} _x x position
    /// @arg {real} _y y position
    /// @return {struct} self
    start_Point = function(_x, _y) {
        start_x = _x;
        start_y = _y;
        // = end_x - start_x;
        __update_Metrics();
        return self;
    };
    /// @method control_Point(x,y)
    /// @desc Define the control point position (the middle point)
    /// 
    /// !> **This method can't be use with the `apex_*` methods as those will fight to set the vertex coordinate**
    /// @param {real} _x x position
    /// @param {real} _y y position
    /// @returns {struct} 
    control_Point = function(_x, _y) {
        control_x = _x;
        control_y = _y;
        
        vertex_x = point_Get_X(0.5);
        vertex_y = point_Get_Y(0.5);
        
        return self;
    };
    /// @method end_Point(x,y)
    /// @desc Define the ending point.
    ///
    /// !> **This method can't be use with the `end_By_*` methods as they will fight to set the end point coordinate**
    /// @arg {real} _x x position
    /// @arg {real} _y y position
    /// @return {struct} return self to allow chaining.
    end_Point = function(_x, _y) {
        end_x = _x;
        end_y = _y;
        __update_Metrics();
        return self;
    };
    /// @method end_By_Distance(horizontal, vertical)
    /// @desc  Define an ending point based on a vhorizontal and vertical distance from the starting point
    ///
    /// !> **This method can't be use with the others `end_By_*` or the `end_point` method as they will fight to set the end point coordinate**
    /// @param {real} _distance_h Description
    /// @param {real} _distance_v Description
    /// @returns {struct} 
    end_By_Distance = function(_distance_h, _distance_v) {
        end_x = start_x + _distance_h;
        end_y = start_y + _distance_v;
        distance_h = _distance_h;
        distance_v = _distance_v;
        distance = point_distance(start_x, start_y, end_x, end_y);
        return self;
    };
    /// @method end_By_Direction(distance, direction)
    /// @desc Defini an ending point based on a distance and a direction (use `lengthdir` internally. 
    ///
    /// !> **This method can't be use with the others `end_By_*` or the `end_point` method as they will fight to set the end point coordinate**
    /// @param {real} _distance a distance
    /// @param {real} _direction a direction in degre
    /// @returns {struct} self
    end_By_Direction = function(_distance, _direction) {
        // Calcul de la position du point d'arrivée
        end_x = start_x + lengthdir_x(_distance, _direction);
        end_y = start_y + lengthdir_y(_distance, _direction);
        
        distance_h = end_x - start_x;
        distance_v = end_y;
        distance = _distance;
        return self;
    };
    /// @method apex_Height(height, [x pos], [isometric])
    /// @desc Define the top height of the parabola (vertex) with a distance. It is **NOT** the control point's height.
    /// 
    /// !> **This method can't be use with others `apex_*` or the `control_point` method as they will fight to set the vertex coordinate**
    /// @param {real} _apex_height The height of the parabola
    /// @param {real} [_x_ratio]=0.5 the x position where the vertex is positioned.
    /// @param {bool} [_isometric]=false This modify the height calculation between a kind of ortho view & Isometric view. 
    ///				false : ortho. the height is calculated from the highest curve's extremity point in the room (the lowest `y` value of either the start or the end point)
    ///				true : isometric. the height is calculated from the line from the start poitn and the end point.
    /// @returns {struct}
    apex_Height = function(_apex_height, _x_ratio = 0.5, _isometric = false ) {
        height = _apex_height;
        //isometric
        var _dir = point_direction(start_x, start_y, end_x, end_y);
        var _mx = start_x + lengthdir_x(distance*_x_ratio, _dir);
        var _my = start_y + lengthdir_y(distance*_x_ratio, _dir);
        
        if _isometric{
            vertex_x = _mx + lengthdir_x(_apex_height, 90);
            vertex_y = _my + lengthdir_y(_apex_height, 90);
            height_iso = _apex_height;
            height_ortho = max(start_y, end_y) - vertex_y;
        }else{

            vertex_x = start_x + _x_ratio * distance_h;
            vertex_y = min(start_y, end_y) - _apex_height;
            height_ortho = _apex_height;
            height_iso    = vertex_y - _my;

        }
        
        // Calculate the control point coordinate (control_x, control_y) from the parabola's vertex and its start/end points
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        
        return self;
    };
    
    /// @text ---
    
    /// @method apex_Height_Alt([x pos], [y pos])
    /// @desc Define the top height of the parabola (vertex) with a ratio. Isometric mode isn't supported yet.
    ///
    /// !> **This method can't be use with others `apex_*` or the `control_point` method as they will fight to set the vertex coordinate**
    /// @param {real} [_y_ratio]=0.5 vertical ratio (0,1) to stay on the parabola, <0,1<: outside of the parabola.
    /// @param {real} [_x_ratio]=0.5 horizontal ratio (0,1) to stay on the parabola, <0,1<: outside of the parabola.
    /// @returns {struct}
    apex_Height_Alt = function(_y_ratio = 0.5, _x_ratio = 0.5) {
        
        // Calculate the horizontale position of the vertex
        vertex_x = start_x + _x_ratio * distance_h;
        // Calculate the verticale position of the vertex
        vertex_y = min(start_y, end_y) - _y_ratio * distance_v;

        // Calculate the controle point coordinate (control_x, control_y) from the vertex and the start & end points
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        return self;
    };
    /// @method apex_Coord(x, y)
    /// @desc  Define the top height of the parabola (vertex) with a coordinate. It is **NOT** the control point's coordinate
    /// 
    /// !> **This method can't be use with others `apex_*` or the `control_point` method as they will fight to set the vertex coordinate**
    /// @param {any*} _x x position
    /// @param {any*} _y y position
    /// @returns {struct} self
    apex_Coord = function(_x, _y){
        // set the horizontale position of the vertex (between start_x and end_x)
        vertex_x = _x;
        // set the verticale position of the vertex
        vertex_y = _y;

        // Calculate the controle point coordinate (control_x, control_y) from the vertex and the start & end points
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        return self;
    }
    /// @method curve_Length([precision])
    /// @desc Calculate the parabola's length (this is a slow method).
    ///	@text ?> I discourage using it each steps
    /// @arg {real} [_precision]=100 the precision of the calculation. a higher value means a better precision but at a cost of performance. 
    /// @return length
    curve_Length = function(_precision = 100) {
        if (length < 0) { // Seulement si non déjà calculée
            var total_length = 0;
            var prev_x = start_x;
            var prev_y = start_y;
            var t, curr_x, curr_y;

            for (t = 0; t <= 1; t += 1 / _precision) {
                curr_x = point_Get_X(t);
                curr_y = point_Get_Y(t);
                total_length += point_distance(prev_x, prev_y, curr_x, curr_y);
                prev_x = curr_x;
                prev_y = curr_y;
            }
            length = total_length; // this is the real length of the parabola
        }
        return length;
    };
    /// @method curve_Length_Ext([method], [precision])
    /// @desc Calculate the parabola's length using different approaches.
    /// - 0: Approximation by summing segments.
	/// - 1: Numerical integration (Simpson's Rule).
	/// - 2: Analytical formula (if applicable).
	/// @arg {real} [_method]=0 Select the calculation method.
	/// @arg {real} [_precision]=100 The precision level for calculation. Only if the method is set at 0
	/// @return {real} The length of the parabola.
	curve_Length_Ext = function(_method = 0, _precision = 100) {
	    if is_undefined(length) || length < 0 {
	        switch (_method) {
	            case 0: // Approximation by summing segments
	                length = __length_approx(_precision);
	                break;
	                
	            case 1: // Numerical integration (Simpson's Rule)
	                length = __length_integrate(_precision);
	                break;
	                
	            case 2: // Analytical formula (if applicable)
	                length = __length_analytical();
	                break;
	
	            default:
	                show_error("Invalid method type in calculate_Length_Ext", true);
	                return -1;
	        }
	    }
	    return length;
	};
    
#endregion
#region Point
	
    /// @slug point-intro
	/// @method point_Get_X(_position)
    /// @desc  Get the x coordinate of a point on the prabola, at the given position.
    /// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
    /// @returns {real} the point's `x` value in the room    
    point_Get_X = function(_position) {
        return sqr(1 - _position) * start_x + 2 * (1 - _position) * _position * control_x + sqr(_position) * end_x;
    };
    /// @method point_Get_Y(_position)
    /// @desc  Get the `y` value of a point on the parabola at the given `position`
    /// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
    /// @returns {real} the point's `y` value in the room 
    point_Get_Y = function(_position) {
        return sqr(1 - _position) * start_y + 2 * (1 - _position) * _position * control_y + sqr(_position) * end_y;
    };
    /// @method point_Get_Orientation(_position)
    /// @desc return the angle of a point to the tangent of the parabola at its current position.
	/// This method return the angle based on a position, ensuring the point maintains a natural orientation along the parabola.
    /// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
    point_Get_Orientation = function(_position){
    	return __get_Tangent(_position);
    }
    /// @method point_Is_At(_position, [_single_frame])
    /// @desc Return true when the position is reached.
    /// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
    /// @arg {bool} [_single_frame]=true return `true` __only__ when on the single frame (true) when the position is reached (then turn back to `false`)
    /* If you use an Animation Curve, the method could return true multiple time, even with the _single_frame` booleen.
    // Could happened with curves like Bounce or Elastic.*/
    point_Is_At = function(_position, _single_frame = true){
        return _single_frame 
            ? motion_ratio >= _position &&  m_next_ratio >= _position && m_prev_ratio < _position
            : motion_ratio >= _position;
    }
    /// @method point_Is_At_Checkpoint(_index, [_single_frame])
    /// @desc Like `motion_Is_At` but check the position of a Checkpoint instead
    /// @param {real} _index the index of the checkpoint in the checkpoints array to check
    /// @param {bool} _single_frame only on the frame it turns true
    /// @return {bool} true or false
    point_Is_At_Checkpoint = function(_index, _single_frame = true){
        if (_index < 0 || _index >= array_length(checkpoints)) {
            show_debug_message($"Checkpoint index {_index} not valid !");
            return false;
        }
    
        var _checkpoint = checkpoints[_index];
    
        // Check the position and return
        return point_Is_At(_checkpoint.position, _single_frame);
    };
#endregion
#region Anchor
    /// @slug anchor-intro
    
    /// @insert anchor-setters-intro
    /// @method anchor_Set(_position)
    /// @desc  Set the anchor's coordinate `x` and `y` at the given poisiton on the parabola.
    /// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
    /// @returns {struct}    
    anchor_Set = function(_position) {
        x = point_Get_X(_position);
        y = point_Get_Y(_position);

        return self;
    };
    /// @insert separator
    /// @method anchor_Speed(_speed, [_motion_unit])
    /// @desc    the speed of the tracking point on the parabola (from the starting point to the ending point). it can be a Time, a Ratio or Steps.
    /// @arg {real} _speed time: in second, ratio: percentage by steps between [0, 100], steps: gamemaker's steps  
    /// @arg {string} [_motion_unit]="unit_time" The type of unit of the speed value set.
    anchor_Speed = function(_speed, _motion_unit = motion_unit){
        if variable_struct_exists(self, _motion_unit){
            motion_unit = variable_struct_get(self, _motion_unit);
        }
        switch(motion_unit){
            //motion_time (second)
            case 0 :    motion_time = abs(_speed);
                        motion_steps = abs(_speed) * game_speed;
                        motion_rate = 1/motion_steps;
            break;
            //ratio (percentage per steps)
            case 1 :    motion_rate = min(abs(_speed) / 100, 1);
                        motion_time = 1/ (motion_rate * game_speed);
                        motion_steps = abs(motion_time) * game_speed;
            break;
            //steps
            case 2 :    motion_steps = abs(_speed);
                        motion_time = motion_steps / game_speed;
                        motion_rate = 1/motion_steps;
            break;
        }

    	return self;
    }
    /// @insert separator
    /// @method anchor_Rotation([_speed], [_cycle_amount], [_force_cycle])
    /// @desc Calculate and set a rotation rate, and a behaviour for the rotation of the anchor point. Need to be called somewhere if rotation are handle internally.
    /// @arg {real} [_speed]=rotation_rate_default the rotation speed as an angle. By default, it use a rotation rate calculated for one full rotation per second
    /// @arg {real} _cycles_amount the number of complete rotations (cycle) (-1: illimited, 0: no rotation (equal to speed = 0), 1..n: complet rotations)
    /// @arg {bool} _force_cycle force the anchor to sync the amount of cycle (complete rotation) to the arrival on the end point. It will completely bypass the `_speed` if `cycle_amount` is above `0`.
    /// @return {struct} self
    anchor_Rotation = function(_speed = rotation_rate_default, _cycles_amount = -1, _force_cycle = false) {
        // cache the value
        force_cycle = _force_cycle;
        cycles_amount = floor(_cycles_amount);
        
        rotation_initialized = true; //flag the rotation as initialized.
        
        if (force_cycle && motion_steps > 0) {
            if (cycles_amount == -1) {
                var _cycles = motion_steps * _speed / 360;
                var _whole_cycles = round(_cycles);
                rotation_rate = (360 * _whole_cycles) / motion_steps; // adjust the rate to the closest based on the given `_speed`
            } else {
                rotation_rate = (360 * cycles_amount) / motion_steps; // adjust the rate to the fixed amount of cycle
            }
        } else {
        	if cycles_amount == 0{
        		rotation_rate = 0
        	} else {
            	rotation_rate = _speed; // Use `_speed` the raw `_speed`. no sync.
        	}
        }
    
        return self;
    };
    /// @insert separator
    /// @method anchor_On_End(_callback, [_args])
    /// @desc Set a callback when the anchor reaches the end point.
    /// @arg _callback the callback to fire
    /// @arg [_args] arguments for the callback.
    /// @arg [_auto_pause]=false auto pause the Anchor when it reach the end point.
    /// @return {struct} self
    anchor_On_End = function(_callback, _args = undefined, _auto_pause = false){
        on_end_callback = _callback;
        on_end_arg = _args;
        auto_pause_on_end = _auto_pause;
        return self;
    };
    /// @slug anchor-updaters-intro
    /// @method anchor_Motion([_on_end])
    /// @desc The main method. it update the anchor's coordinate on the parabola, but also ist roation or orientation, and its scale when `motion_Internal_Transform` is set to `true`
    /// @arg {bool} [_on_end]=false Trigger the callback when the end of the parabola is reached.
	anchor_Motion = function(_on_end = false){
	    if is_stopped {
	        if is_playing {
	            x = point_Get_X(0);
	            y = point_Get_Y(0);
                angle = 0;
                //could put a parameter to choose if check point should be reset on stop.
                __reset_Checkpoints();
	            is_playing = false;
	        }
            finalize = false;
            is_completed = false;
	        return self;
	    }
	
	    if is_paused return self;
            
        // Checkpoints
        for (var _i = 0; _i < array_length(checkpoints); _i++) {
            var _checkpoint = checkpoints[_i];
            
            if (_checkpoint.checked) {
                continue;
            }
            
                // Check if the position has been reached
            if (point_Is_At(_checkpoint.position, _checkpoint.single_frame)) {
                if (!is_undefined(_checkpoint.callback)) {
                    if (is_undefined(_checkpoint.args)) {
                        _checkpoint.callback();
                    } else {
                        _checkpoint.callback(_checkpoint.args);
                    }
                }
        
                // Prevent the checkpoint to be checked again if `once` is true.
                if (_checkpoint.once) {
                    _checkpoint.checked = true;
                }
            }
        }
        
	    // Save the value of `motion_ratio`
	    m_prev_ratio = motion_ratio;
	
	    // Then increment it based on the motion_rate (calculated in the `anchor_Speed` method)
	    curve_ratio += motion_rate;
	
	    // If an Animation Curve is set, use it instead.
	    if (!is_undefined(motion_curve_channel)) {
            m_prev_ratio = animcurve_channel_evaluate(motion_curve_channel, curve_ratio - motion_rate);
	        motion_ratio = animcurve_channel_evaluate(motion_curve_channel, curve_ratio);
            curve_ratio = min(curve_ratio,1);
            m_next_ratio = animcurve_channel_evaluate(motion_curve_channel, curve_ratio + motion_rate);
	    } else {
	        motion_ratio = curve_ratio; // linear progression by default
            m_next_ratio = motion_ratio + motion_rate;
	    }

	     //Managed special cases with some Animation Curves (like Elastic or Bounce) where `1` could be reached several times while the motion isn't completed yet.
	     //We scale dynamically the range based on the motion_rate.
        var _epsilon_dynamic = max(0.00001, motion_rate * 0.001);
	    if abs(curve_ratio - 1) <= _epsilon_dynamic && !is_completed && m_prev_ratio <= motion_ratio {
	        is_completed = true; // Marquer la stabilisation à 1
	        motion_ratio = 1;
	    }
	
	    // Finalyze only when the last `1` has been reached.
	    if (is_completed && motion_ratio == 1 && !finalize) {
	        finalize = true;
	        at_end = true;    // flag the frame as the end of the parabola
	        // if rotation is handle internally, we need to force its calculation a last time to be in sync.
			if !internal_transforms force_last_calculations = true;
	        show_debug_message("END REACHED");
			
			if auto_pause_on_end{
				motion_Pause();
			}
			
	        // Trigger the callback if `_on_end` is true
	        if _on_end && !is_undefined(on_end_callback) {
	            if is_undefined(on_end_arg) {
	                on_end_callback();
	            } else {
	                on_end_callback(on_end_arg);
	            }
	        }
	    }
	
	    //If the motion ratio goes on, we unflag the frame.
	    //We can also use that variable to check if the anchor has reached the end.
	    if (motion_ratio > 1 && at_end) {
	        at_end = false;
	    }
         
	    // update the anchor point
	    anchor_Set(motion_ratio);
        if internal_transforms {
        	if rotation_initialized{
	        	__rotate();
	        }
	        // if orientation_initialized{
	        //	To Support
	        // }
	        //if scale_initialized{
	        //	To DO
	        //}
        }
	        
	
	    return self;
	};
	/// @insert separator
	/// @method anchor_Rotate()
    /// @desc Rotate the Anchor. Need to be called each steps if rotation are handle externally and is bypassed if handle internally.
    /// If `anchor_Rotation` isn't called upstream, the method assumes that the Anchor point want to be rotated and thus, will force a default rotation rate of one cycle per second. 
    ///
    /// 	!> **This method can't be use with `anchor_Orient` as both will fight to update the `angle` variable.**
     anchor_Rotate = function() {
     	if internal_transforms return self;
     	if (!rotation_initialized) {
	        // calculate a default rotation base on 
	        rotation_rate = 360 / motion_steps; // default rotation rate
	        rotation_initialized = true; // flag the initialization as done
	    }

        if is_stopped { 
            angle = 0;
	        return self;
	    }
        
        if (is_paused) {
            if force_last_calculations{
                angle += rotation_rate; // we apply a final rotation in case `rotate` is called after `motion` and the tracking point has been paused on that framepaused
                force_last_calculations = false; 
            }
            return self;
        }
    
        __rotate();
    
        return self;
    };
    
  
	/// @insert separator  
    /// @method anchor_Orient()
    /// @desc set the angle of the anchor point to the tangent of the parabola at its current position.
	/// This method updates the angle based on the motion ratio (position), ensuring the Anchor maintains a natural orientation along the parabola.
	/// Need to be called each steps if `motion_Internal_Transform` is `false`.
	///
	/// !>	**This method can't be use with `anchor_Rotate` as both will fight to update the `angle` variable.**
    anchor_Orient = function(){
    	if internal_transforms return self;
    	// if (!orientation_initialized) {
	       
	    //     orientation_initialized = true; // flag the initialization as done
	    // }
	    if is_stopped { 
            angle = __get_Tangent(0);
	        return self;
	    }
	    if (is_paused) {
            return self;
	    }
    	angle = __get_Tangent(motion_ratio);
    }
    
    /// @insert separator
#endregion
#region Motion
	
	/// @slug anchor-motion-intro
	/// @method motion_Play()
    /// @desc start the anchor. Can be use to resume as well.
    motion_Play = function() {
            if (motion_ratio >= 1) {
                motion_ratio = 0;
                curve_ratio = 0;
                at_end = false;
            }
            is_playing = true;
            is_paused = false;
            is_stopped = false;
        return self;
    };
    /// @insert separator
    /// @method motion_Pause()
    /// @desc Pause the tracking point.
    motion_Pause = function() {
        if (is_paused || is_stopped) return self; // Ne rien faire si déjà en pause ou arrêté
        is_paused = true;  // Marquer comme "en pause"
        return self;

    };
    /// @insert separator
    /// @method motion_Reset()
    /// @desc Stop the tracking point. it will goes back to the start of the parabola.
    motion_Reset = function() {
        motion_ratio = 0; // Re-initialize the progress
        curve_ratio = 0;
        //is_playing = false;
        is_paused = false;
        is_stopped = true;
        at_end = false;   // reset the finalize state
        return self;
    };
    /// @insert separator
    /// @method motion_Resume()
    /// @desc Resume the Anchor motion (from the pause state).
    motion_resume = function() {
        if (!is_paused || is_stopped) return self;
        is_paused = false;
        return self;

    };
    /// @insert separator
    /// @method motion_Toggle_Pause()
    /// @desc Toggle between pause and resume.
    motion_Toggle_Pause = function() {
        if (is_stopped) return self;
    
        is_paused = !is_paused;
        return self;
    };
    /// @insert separator
    /// @method motion_Set_AnimCurve(_animcurve)
    /// @desc Set an Animation Curves to be use as the position on the parabola
    /// @arg {Asset.GMAnimCurve, Constant.Undefined} _animcurve theAnimation Curve to use
	motion_Set_AnimCurve = function(_animcurve) {
	    if (!animcurve_exists(_animcurve)) || _animcurve == undefined {
	        if _animcurve = undefined then show_debug_message("Removed the Animation Curve"); 
	        else show_debug_message("Warning: The animation Curve doesn't exists. Resetting to `undefined`");
	        // remove the curve and the cached channel if not valid
	        motion_curve = undefined;       
	        motion_curve_channel = undefined;
	        return self;
	    }
	
	    motion_curve = animcurve_get(_animcurve);
	    if (array_length(motion_curve.channels) > 0) {
	        motion_curve_channel = animcurve_get_channel(motion_curve, 0); // cache the canal 0.
	    } else {
	        show_debug_message($"Error: The Animation Curve {motion_curve} has no channels");
	        motion_curve = undefined;       // re-initialize the variables
	        motion_curve_channel = undefined;
	    }
	
	    return self;
	};
	/// @insert separator
	/// @method motion_Internal_Transforms(_internal)
	/// @desc	Set the global behaviour for handling the anchor transformation rotate and scale. 
	///			It manages if those transformations should be handle internally by the `anchor_Motion` method or with their dedicated methods (eg: `anchor_Rotate`). 
	///
	///			?> `anchor_Scale` is a **planned feature**.
	/// @arg {bool} _internal true for internal, false for external
	motion_Internal_Transforms = function(_internal){
		internal_transforms = _internal;
	}
	
#endregion	
#region Checkpoints
	/// @slug checkpoints-intro
	
	/// @method add_Checkpoint(_position, [_callback], [_args], [_single_frame], [_once], [_sort])
    /// @desc	Add a checkpoint to the parabola's checkpoints array.
    //			No duplicates support for now.
    /// @arg	{real} _position the position to reach to trigger the check point
    /// @arg	{function} [_callback]=undefined the callback to fire
    /// @arg	{struct,array} [_args]=undefined the argument for the callback
    /// @arg     {bool} _single_frame if the checkpoint return true only on the frame when the position is reached,
    /// @arg	{bool} [_once]=true If the checkpoint should be checked once or each time it is reached. 
    /// @arg	{bool} [_sort]=false Sort the checkpoints array based on the position in ascending order. If you need more control on the sorting behaviour, use the `sort_Checkpoints` method.
    add_Checkpoint = function(_position, _callback = undefined, _args = undefined, _single_frame = true, _once = true, _sort = false){
        var _data = {
            position : _position,
            callback : _callback,
            args : _args,
            once : _once,
            single_frame : _single_frame,
            checked : false
        }
        array_push(checkpoints,_data);
        
        if _sort{
	        array_sort(checkpoints, function(a, b) {
	            return a.position - b.position;
	        });
        }
        
        return self;
    }
    /// @insert separator
    /// @desc Remove a checkpoint at the given index in the checkpoints array
    /// @arg {real} _index the index of the checkpoint
    /// @arg {bool} [_sort]=false Sort the array by ascending position.
    /// @return self
    remove_Checkpoints = function(_index, _sort = false){
    	if (_index < 0 || _index >= array_length(checkpoints)) {
	        show_error($"Invalid index {_index}. Cannot remove checkpoint.", true);
	        return self;
    	}
        
        array_delete(checkpoints, _index, 1);
        
        if _sort{
	        array_sort(checkpoints, function(a, b) {
	            return a.position - b.position;
	        });
        }
        
        return self;
    }
    /// @insert separator
    /// @method remove_Checkpoints_All()
    /// @desc Remove all the checkpoints from the checkpoints array.
    remove_Checkpoints_All = function(){
    	checkpoints = undefined;
    }
    /// @insert separator
    /// @desc Remove the callback and its arguments of the checkpoint at the given index from the checkpoints array
    /// @arg {real} _index the index of the checkpoint to remove the callback from.
    /// @return self
    remove_Checkpoint_Callback = function(_index){
    	if (_index < 0 || _index >= array_length(checkpoints)) {
	        show_error($"Invalid index {_index}. Cannot remove checkpoint.", true);
	        return self;
    	}
    	
    	var _checkpoint = checkpoints[_index];
    	
    	_checkpoint.callback = undefined;
    	_checkpoint.args = undefined;
    	
    	return self;
    }
    /// @insert separator
    /// @method edit_Checkpoint(index or ref, variable or struct)
    /// @desc ?> Planned Feature - see Roadmap
    /// @insert separator
    /// @method sort_Checkpoints(sorting)
    /// @desc ?> Planned Feature - see Roadmap
    
    /// @insert separator
#endregion
#region Draw
	/// @slug draw-intro

	/// @method draw([_point_number], [_start_color], [_end_color], [_color1], [_color2])
	/// @desc draw the parabola as a line of points.
	/// @arg {real} [_point_number]=16 the number of point that formed the parabola
	/// @arg {Constant.Color} [_start_color]=c_red The start point color
	/// @arg {Constant.Color} [_end_color]=c_red The end point color
	/// @arg {Constant.Color} [_color1]=c_white The first gradient color for the parabola's points
	/// @arg {Constant.Color} [_color2]=c_white The second gradient color for the parabola's points
    /// @return self
    draw = function(_point_number = 16, _start_color = c_red, _end_color = c_red, _color1 = c_white, _color2 = c_white) {
        
        //line of point
        for (var _t = 0; _t <= 1; _t += 1/_point_number) {
            var _x = point_Get_X(_t);
            var _y = point_Get_Y(_t);
            
            var _color = merge_colour(_color1, _color2, _t);
            draw_circle_color(_x, _y, 2, _color, _color, false);
        }
        //start and end point
        draw_circle_color(start_x, start_y, 4, c_red, c_red, true);
        draw_circle_color(end_x, end_y, 2, c_red, c_red, false);
        
        return self;
    };
    /// @insert separator
    /// @method draw_Checkpoint([_index], [_color], [_size], [_outline])
    /// @desc Draw one or all checkpoint on the parabola as a diamond shape
    /// @param {real,Constant.All} [_index]=all the checkpoint to draw
    /// @param {Constant.Color} [_color]=c_green the chckpoint color
    /// @arg {real} [_size]=6 the size of the shape the size of the diamond shape
    /// @arg {bool} [_outline]=false outline (true) or fill (false)
    /// @returns {struct} self
    draw_Checkpoint = function(_index = all, _color = c_green, _size = 6, _outline = false){
        if (checkpoints = undefined || array_length(checkpoints) < 0) return self;
    	draw_set_circle_precision(4);
    	var _x, _y, _checkpoint;
    	if _index = all{
	    	for (var _i = 0; _i < array_length(checkpoints); _i++) {
	            _checkpoint = checkpoints[_i];
	            _x = point_Get_X(_checkpoint.position);
	            _y = point_Get_Y(_checkpoint.position);
                draw_circle_color(_x, _y, _size, _color, _color, _outline);
	    	}
    	}
    	else {
        	
            if _index > -1 && _index < array_length(checkpoints) {
        		_checkpoint = checkpoints[abs(_index)];
                _x = point_Get_X(_checkpoint.position);
                _y = point_Get_Y(_checkpoint.position);
                draw_circle_color(_x, _y, _size, _color, _color, _outline);
        	}
        }

    	draw_set_circle_precision(24);
    	
    	return self;
    	
    }
    /// @insert separator
    /// @method draw_Debug([_seg], [_curve_color])
    /// @desc Draw a debug representation of the parabola.
    ///			it will draw the parabola as points linked by a line, the line between the start and end point, the start point, the end point, the controle point and the vertex point.
    /// @arg {real} _seg number of segment of the line representing the parabola. Higher value is more precise but also mor expensive.
    draw_Debug = function(_seg = 16, _curve_color = c_red){
        var _t1 = 1/_seg;
        var _i = 0; repeat(_seg-1){
            var _t = _i/_seg;
           var _col = make_colour_hsv(255/_seg*_i, 255, 255);
           var _x = point_Get_X(_t);
           var _y = point_Get_Y(_t);
           draw_circle_color(_x,_y, 2, _col, _col, false);
           var _x2 = point_Get_X(_t + _t1);
           var _y2 = point_Get_Y(_t + _t1);
           draw_line_colour(_x,_y, _x2, _y2,_curve_color,_curve_color);
           _i++;
        }
        //draw point
        draw_line_color(start_x, start_y, end_x, end_y, c_teal, c_red);
        //end
        draw_circle_color(end_x, end_y, 4, c_red, c_red, false);
        //start
        draw_circle_color(start_x, start_y, 4, c_teal, c_teal, false);
        //control
        draw_circle_color(control_x, control_y, 4, c_orange, c_orange, false);
        //vertex
        draw_circle_color(vertex_x, vertex_y, 4, c_aqua , c_aqua , false);
    }
    
#endregion
#region Private Methods

	/// @desc Calculate the tangent of a point on the parabola at `t`.
	/// @arg {real} _t the point position on the parabola
	/// @return angle
	/// @ignore
	__get_Tangent = function(_t) {
	    // Control points of the Bézier curve
	    var p0x = start_x, p0y = start_y;
	    var p1x = control_x, p1y = control_y;
	    var p2x = end_x, p2y = end_y;
	
	    // Derivative (dx/dt, dy/dt) at t
	    var dx = 2 * (1 - _t) * (p1x - p0x) + 2 * _t * (p2x - p1x);
	    var dy = 2 * (1 - _t) * (p1y - p0y) + 2 * _t * (p2y - p1y);
	
	    // Calculate angle using point_direction
	    return point_direction(0, 0, dx, dy);
	};
	/// @desc Approximate the parabola's length by summing the distances between small segments.
	/// @arg {real} [_precision] The number of divisions used to calculate the length. Higher values improve accuracy but reduce performance.
	/// @return {real} The approximate length of the quadratic Bézier curve.
	/// @ignore
	__get_Length_Approx = function(_precision) {
	    var total_length = 0, prev_x = start_x, prev_y = start_y, curr_x, curr_y;
	
	    for (var t = 1 / _precision; t <= 1; t += 1 / _precision) {
	        curr_x = point_Get_X(t);
	        curr_y = point_Get_Y(t);
	        total_length += point_distance(prev_x, prev_y, curr_x, curr_y);
	        prev_x = curr_x;
	        prev_y = curr_y;
	    }
	    return total_length;
	};
	/// @desc Calculate the parabola's length using numerical integration (Simpson's Rule).
	/// This method offers better precision compared to approximation but may impact performance.
	/// @arg {real} [_precision] The number of subdivisions for numerical integration. Higher values improve accuracy.
	/// @return {real} The numerically integrated length of the quadratic Bézier curve.
	/// @ignore
	__get_Length_Integrate = function(_precision) {
	    var total_length = 0, dt = 1 / _precision;
	    
	    for (var i = 0; i < _precision; i += 2) {
	        var t0 = i * dt, t1 = (i + 1) * dt, t2 = (i + 2) * dt;
	        var x0 = point_Get_X(t0), y0 = point_Get_Y(t0);
	        var x1 = point_Get_X(t1), y1 = point_Get_Y(t1);
	        var x2 = point_Get_X(t2), y2 = point_Get_Y(t2);
	
	        total_length += (point_distance(x0, y0, x1, y1) + 4 * point_distance(x1, y1, x2, y2) + point_distance(x2, y2, x0, y0)) / 6;
	    }
	    return total_length;
	};
	/// @desc Calculate the exact length of a quadratic Bézier curve using Gauss-Legendre Quadrature.
	/// This method offers the highest precision and uses precomputed weights and points.
	/// @return {real} The exact length of the quadratic Bézier curve.
	/// @ignore
	__get_Length_Analytical = function() {
	    var p0x = start_x, p0y = start_y;
	    var p1x = control_x, p1y = control_y;
	    var p2x = end_x, p2y = end_y;
	
	    // Gauss-Legendre weights and sample points (5-point quadrature)
	    var weights = [0.23693, 0.47863, 0.56889, 0.47863, 0.23693];
	    var points  = [0.04691, 0.23075, 0.5, 0.76925, 0.95309];
	
	    var total_length = 0;
	    
	    // Numerical integration using weighted summation
	    for (var i = 0; i < array_length(weights); i++) {
	        var t = points[i];
	        
	        var dx = 2 * (1 - t) * (p1x - p0x) + 2 * t * (p2x - p1x);
	        var dy = 2 * (1 - t) * (p1y - p0y) + 2 * t * (p2y - p1y);
	        
	        total_length += weights[i] * sqrt(dx * dx + dy * dy);
	    }
	    
	    return total_length;
	};
	

    /// @desc Normalize an angle and return a values between -1 et 1
    /// @param {real} [_angle]=undefined angle in degree
    /// @param {bool} [_signed_int]=false limit the return value to -1, 1 or 0.
    /// @ignore
    function __normalize_Angle(_angle = undefined, _signed_int = false) {
        if (is_undefined(_angle)) {
            return { x: 0, y: 0, angle: undefined }; // default value
        }
        
        // Normalization
        var x_norm = dcos(_angle); // cosinus for the x coordinate
        var y_norm = -dsin(_angle); // sinus for the y coordinate (inversed because Gamemaker stuff)
    
        // signed integrer feature
        if (_signed_int) {
            x_norm = (x_norm > 0) - (x_norm < 0); // Limite X à -1, 0 ou 1
            y_norm = (y_norm > 0) - (y_norm < 0); // Limite Y à -1, 0 ou 1
        }
    
        // return a struct with the calculated value. the input angle is also stored.
        return {
            x: x_norm,
            y: y_norm,
            angle: _angle // add the input angle
        };
    }
    
    /// @desc Update internal calculations (distance, etc)
    /// @ignore
    __update_Metrics = function() {
        distance_h = end_x - start_x;
        distance_v = end_y - start_y;
        distance = point_distance(start_x, start_y, end_x, end_y);
      
    };
    /// @desc reset the checkpoints. Use in the `motion_reset` method
    /// @ignore
    __reset_Checkpoints = function(){
    	if (checkpoints = undefined || array_length(checkpoints) < 0) return self;
    	for (var _i = 0; _i < array_length(checkpoints); _i++) {
            var _checkpoint = checkpoints[_i];
            _checkpoint.checked = false;
    	}
    }
    /// @desc rotate the tracking point internally when used in the `anchor_Motion` method
    /// @ignore
    __rotate = function() {
        if (rotation_rate > 0) {
            angle += rotation_rate; // Incrémenter l'angle
    
            if (cycles_amount > 0) {
                var max_angle = 360 * cycles_amount;
                if (angle >= max_angle) {
                    angle = max_angle;
                    rotation_rate = 0; // stop the rotation once completed
                }
            } else if (cycles_amount == -1) {
                if (angle >= 360) {
                    angle = angle mod 360; // normalise the angle each cycle.
                }
            }
        }
    };
    /// @desc internal method to set a simple parabola when the constructor is called.
    /// @ignore
    __init_Simple_Parabola = function(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric, _scope){
        var _sx = 0;
        var _sy = 0;
        if (!is_undefined(_scope) && variable_instance_exists(_scope, "x") && variable_instance_exists(_scope, "y")){
            _sx = _scope.x;
            _sy = _scope.y;
        }
        
        _sx		= _start_x ?? _sx; // coordonee x du point de depart de la courbe
        _sy		= _start_y ?? _sy; // coordonee y du point de depart de la courbe
        simple_Parabola(_sx, _sy, _distance_h, _distance_v, _height, _isometric);
        anchor_Set(0);
        
    }
    
    /// Initialize a simple parabola at creation.
    __init_Simple_Parabola(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric, _scope);
}
#endregion









