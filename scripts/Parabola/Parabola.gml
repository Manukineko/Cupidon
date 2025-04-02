/*
TO DO :
- Changer le boolen `_once` en single frame ou on_enter pour Motion_Is_At et Add_Checkpoint
- ajouter un boolen `_once` a add_Checkpoint qui signifie que le checkpoint ne sera pas valider meme si le ratio match encore.
*/

enum MOTION_UNIT{
    TIME,
    RATIO,
    STEPS
}
/// @desc Function Description
/// @param {real} [_start_x] Description
/// @param {real} [_start_y] Description
/// @param {real} [_distance_h]=0 Description
/// @param {real} [_distance_v]=0 Description
/// @param {real} [_height]=0 Description
/// @param {bool} [_isometric]=false Description
/// @param {id.instance} [_scope]=other Description
function Parabezier(_start_x = undefined, _start_y = undefined, _distance_h = 0, _distance_v = 0, _height = 0, _isometric = false,_scope = other) constructor {

    // Points de départ, d'apex et d'arrivée
    start_x		= 0; // x coordinate of the starting point of the curve
    start_y		= 0; // y coordinate of the starting point of the curve
    control_x		= 0; // x coordinate of the control point of the curve
    control_y		= 0; // y coordinate of the curve control point
    end_x		= 0; // x coordinate of the ending point of the curve
    end_y		= 0; // y coordinate of the ending point of the curve
    
    // coordonees du point sur la courbe
    x			= start_x;
    y			= start_x;
    angle       = 0; // l'angle du point x,y (default : droite)
    
    distance         = 0; // distance between the starting point and the ending point
    distance_h		 = 0; // distance between `start_x` and `end_x`
    distance_v		 = 0; // distance between `start_y` and `end_y`
    length           = 0; // longueur reelle de la courbe
    height           = 0; // hauteur cached par les method apex_Height_* - P'tet inutile.
    height_ortho     = 0; // la hauteur du sommet de la courbe sur le plan orthogonal (relatif a atart_y ou end_y
    height_iso       = 0; // la hauteur du sommet de la courbe sur le plan isometrique (relatif au point median de la distance start <> end
    vertex_height    = 0; // hauteur du sommet de la courbe //TO DELETE
    
    // coordonnee du sommet de la courbe
    vertex_x = 0;
    vertex_y = 0;
    
    game_speed      = game_get_speed(PARABOLA_GAMESPEED_TYPE);
    motion_time		= 0; // temps en seconde pour parcourir la courbe du point de depart au point d'arrivee
    motion_steps	= 0; // temps en steps 
    motion_rate	    = 0; // vitesse calcule pour updater la position du point sur la courbe ([0 , 1])
    motion_ratio    = 0; // le ratio incrementeé pour deplacer le point x,y sur la courbe.
    curve_ratio 	= 0;
    m_next_ratio    = 0;
    m_prev_ratio    = 0;
    motion_curve	= undefined;
	motion_curve_channel = undefined;
    
    rotation_rate    = 0; // vitess de rotation sur le point x,y
    cycles_amount     = 0; // nombre de rotations max
    force_rotation  = false;
    force_cycle     = false;
    
    
    // bool
    is_playing		= false; // le point se deplace sur la courbe
    is_stopped		= true; //le point retourne au depart
    is_paused		= false; // le point est pausé
    is_completed	= false; // le mouvement sur la courbe est complet (ratio > 1)
    at_end          = false; // Passe à `true` sur la frame de completion de la courbe (ratio == 1), puis repasse a false
    finalize		= false; // booleen interne s'assurant d'executer les operation une fois la courbe complete, une seule fois.
    stability_counter = 0;
    
    on_end_callback	= undefined;
    on_end_arg		= undefined;
    checkpoints 	= [];
    
    unit_time		= MOTION_UNIT.TIME;
    unit_ratio		= MOTION_UNIT.RATIO;
    unit_steps		= MOTION_UNIT.STEPS;
    motion_unit		= unit_time;
    
    
   
    // Méthodes pour définir les valeurs
    
    /// @desc Define the starting point
    /// @arg {real} _x x position
    /// @arg {real} _y y position
    /// @return {self} return self to allow chaining.
    start_Point = function(_x, _y) {
        start_x = _x;
        start_y = _y;
        distance_h = end_x - start_x;
        return self;
    };
    /// @desc Define the ending point
    /// @arg {real} _x x position
    /// @arg {real} _y y position
    /// @return {self} return self to allow chaining.
    end_Point = function(_x, _y) {
        end_x = _x;
        end_y = _y;
        distance_h = end_x - start_x;
        return self;
    };
    /// @desc  Define an ending point based on a vhorizontal and vertical distance from the starting point
    /// @param {real} _distance_h Description
    /// @param {real} _distance_v Description
    /// @returns {struct} Description 
    end_By_Distance = function(_distance_h, _distance_v) {
        end_x = start_x + _distance_h;
        end_y = start_y + _distance_v;
        distance_h = _distance_h;
        distance_v = _distance_v;
        distance = point_distance(start_x, start_y, end_x, end_y);
        return self;
    };
    /// @desc Defini an ending point based on a distance and a direction (use `lengthdir` internally. 
    /// @param {real} _distance a distance
    /// @param {real} _direction a direction in degre
    /// @returns {struct} Description
    end_By_Direction = function(_distance, _direction) {
        // Calcul de la position du point d'arrivée
        end_x = start_x + lengthdir_x(_distance, _direction);
        end_y = start_y + lengthdir_y(_distance, _direction);
        
        distance_h = end_x - start_x;
        distance_v = end_y;
        distance = _distance;
        return self;
    };
    /// @desc Define the control point position (the middle point)
    /// **Shouldn't be use neither with another `apex_*` method as it will change the height calculated by those methods as well**
    /// @param {any*} _x x position
    /// @param {any*} _y y position
    /// @returns {struct} 
    control_Point = function(_x, _y) {
        control_x = _x;
        control_y = _y;
        
        vertex_x = point_Get_X(0.5);
        vertex_y = point_Get_Y(0.5);
        
        return self;
    };
    /// @desc Define the top height of the curve (vertex) with a distance. It is **NOT** the control point's height
    /// **Shouldn't be use neither with another `apex_*` method nor `apex_Point` as it will change the height calculated by those methods as well**
    /// @param {real} _vertex_height The height of the curve
    /// @param {real} [_x_ratio]=0.5 the x position where the vertex is positioned.
    /// @param {bool} [_isometric]=false This modify the height calculation. false: from the lowest extremity point, true: from the line between the start point and the end point
    /// @returns {struct}
    apex_Height = function(_apex_height, _x_ratio = 0.5, _isometric = false ) {
        height = _apex_height;
        //isometric
        var _dir = point_direction(start_x, start_y, end_x, end_y);
        var _mx = start_x + lengthdir_x(distance*_x_ratio, _dir);
        var _my = start_y + lengthdir_y(distance*_x_ratio, _dir);
        
        if _isometric{
            vertex_x = _mx;
            vertex_y = _my - _apex_height;
            height_iso = _apex_height;
            height_ortho = max(start_y, end_y) - vertex_y;
        }else{
            vertex_x = start_x + _x_ratio * distance_h;
            vertex_y = max(start_y, end_y) - _apex_height;
            height_ortho = _apex_height;
            height_iso    = vertex_y - _my;
        }
        
        // Calculate the control point coordinate (control_x, control_y) from the curve's vertex and its start/end points
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        
        return self;
    };
    
    /// @desc Define the top height of the curve (vertex) with a ratio.
    /// **Shouldn't be use neither with another `apex_*` method nor `apex_Point` as it will change the height calculated by those methods as well**
    /// @param {real} [_y_ratio]=0.5 vertical ratio (0,1) to stay on the curve, <0,1<: outside of the curve.
    /// @param {real} [_x_ratio]=0.5 horizontal ratio (0,1) to stay on the curve, <0,1<: outside of the curve.
    /// @returns {struct}
    apex_Height_Alt = function(_y_ratio = 0.5, _x_ratio = 0.5) {

        // Calculer la position horizontale de l'apex (vertex_x)
        vertex_x = start_x + _x_ratio * distance_h;
        // Calculer la position verticale de l'apex avec le ratio
        vertex_y = start_y + _y_ratio * distance_v;

        // Calculer le point de contrôle (control_x, control_y) en fonction du vertex et des points de départ/d'arrivée
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        return self;
    };

    /// @desc  Define the top height of the curve (vertex) with a coordinate. It is **NOT** the control point's coordinate
    /// **Shouldn't be use neither with another `apex_*` method nor `apex_Point` as it will change the height calculated by those methods as well**
    /// @param {any*} _x x position
    /// @param {any*} _y y position
    /// @returns {struct}    
    apex_Coord = function(_x, _y){
        // Calculer la position horizontale de l'apex (contrainte entre start_x et end_x)
        vertex_x = _x;
        // Calculer la position verticale de l'apex
        vertex_y = _y;

        // Calculer le point de contrôle (control_x, control_y) en fonction du vertex et des points de départ/d'arrivée
        control_x = 2 * vertex_x - 0.5 * (start_x + end_x);
        control_y = 2 * vertex_y - 0.5 * (start_y + end_y);
        //control_y = min(start_y, end_y) -_vertex_height
        return self;
    }
    
    /// @desc  Set the internal point's `x` and `y` on the curve.
    /// @param {real} _pos the ratio on the curve
    /// @returns {struct}    
    point_Set = function(_pos) {
        x = point_Get_X(_pos);
        y = point_Get_Y(_pos);

        return self;
    };
    /// @desc  Get the `x` value of a point on the curve at the given `ratio`
    /// @param {real} _pos the ratio to get the `x` from
    /// @returns {real} the point's `x` value in the room    
    point_Get_X = function(_pos) {
        return sqr(1 - _pos) * start_x + 2 * (1 - _pos) * _pos * control_x + sqr(_pos) * end_x;
    };
    /// @desc  Get the `y` value of a point on the curve at the given `ratio`
    /// @param {real} _pos the ratio to get the `y` from
    /// @returns {real} the point's `y` value in the room 
    point_Get_Y = function(_pos) {
        return sqr(1 - _pos) * start_y + 2 * (1 - _pos) * _pos * control_y + sqr(_pos) * end_y;
    };
    /// @desc    the speed of the tracking point on the curve (from the starting point to the ending point). it can be a Time, a Ratio or Steps. The method also calculate a basic rotation_rate
    /// @args {real} _speed time: in second, ratio: percentage by steps between [0, 100], steps: gamemaker's steps  
    /// @args {string} [_motion_unit]="unit_time" The type of unit of the speed value set.
    motion_Speed = function(_speed, _motion_unit = "unit_time"){
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
        rotation_rate = 360/motion_steps;

    	return self;
    }
    ///@desc Calculate the curve's length (this is a slow method).
    /// @arg {real} [_precision]=100 the precision of the calculation. a higher value means a better precision but at a cost of performance.
    /// @return length
    calculate_Length = function(_precision = 100) {
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
            length = total_length; // Stocker la longueur calculée
        }
        return length;
    };

    /// @desc Update the tracking point's coordinate on the curve. This method is to be call each frame to be fully exploited.
    /// @arg {bool} [_on_end]=false Trigger the callback when the end of the curve is reached.
	motion = function(_on_end = false) {
	    if is_stopped {
	        if is_playing {
	            x = point_Get_X(0);
	            y = point_Get_Y(0);
                angle = 0;
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
            
            if (_checkpoint.checked && _checkpoint.once) {
                continue;
            }
            
                // Check if the ratio has been reached
            if (motion_Is_At(_checkpoint.ratio, _checkpoint.once)) {
                // Exécuter le callback si défini
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
        
	    // We save the value of motion_ratio`
	    m_prev_ratio = motion_ratio;
	
	    // Then we increment it based on the motion_rate (calculated in the `motion_Speed` method)
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

	     //Managed special cases with some Animation Curves (like Elastic or Bounce) where 1 could be reached several time while the motion isn't completed yet.
	     //We scale dynamically the range based on the motion_rate.
        var _epsilon_dynamic = max(0.00001, motion_rate * 0.001);
	    if abs(curve_ratio - 1) <= _epsilon_dynamic && !is_completed && m_prev_ratio <= motion_ratio {
	        is_completed = true; // Marquer la stabilisation à 1
	        motion_ratio = 1;
	    }
	
	    // Finalyze only when the last 1 has been reached.
	    if (is_completed && motion_ratio == 1 && !finalize) {
	        finalize = true;
	        at_end = true;    // flag the frame as the end of curve one
   
	        show_debug_message("END REACHED");
	
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
	    //We can also use that variable to check if the tracker has reached the end.
	    if (motion_ratio > 1 && at_end) {
	        at_end = false;
	    }
         
	    // update the tracker point
	    point_Set(motion_ratio);
        //The rotation is managed internally, but I plane to allow to managed it manually throuhgh the `rotate` method
        __rotate();
	
	    return self;
	};
    /// @desc set the rotation of the tracker point
    /// @arg {real} [_speed]=rotation_rate the rotation speed. By default, it use the rotation speed calculated by the method `motion_Speed`
    /// @arg {real} _cycles_amount the number of complete rotations (cycle) (-1: illimited, 0: no cycle (no rotation, equal to speed = 0), 1..n: cycle)
    /// @arg {bool} _force_cycle force only cycle (complete rotation) before the tracker reached the end point.\n
    /// it will sync
    rotation = function(_speed = rotation_rate, _cycles_amount = -1, _force_cycle = false) {
        // Calculer les paramètres initiaux
        force_cycle = _force_cycle;
        cycles_amount = floor(_cycles_amount);
        
        if (force_cycle && motion_steps > 0) {
            if (cycles_amount == -1) {
                var _cycles = motion_steps * _speed / 360;
                var _whole_cycles = round(_cycles);
                rotation_rate = (360 * _whole_cycles) / motion_steps; // Ajuster la vitesse
            } else {
                rotation_rate = (360 * cycles_amount) / motion_steps; // Fixer pour `cycles_amount`
            }
        } else {
            rotation_rate = _speed; // Utiliser `_speed` directement si pas de synchronisation
        }
    
        
        return self;
    };
	/// @desc Rotate the point. Should be called in the step event.
     rotate = function() {
        if is_stopped { 
            angle = 0;
	        return self;
	    }
        
        if (is_paused) {
            if force_rotation{
                angle += rotation_rate; // we apply a final rotation in case `rotate` is called after `motion` and the tracking point has been paused on that framepaused
                force_rotation = false; 
                return self;
            }
            return self;
        }
    
        __rotate();
    
        return self;
    };

    
    /// @desc Démarre ou reprend le mouvement
    play = function() {
            if (motion_ratio >= 1) {
                motion_ratio = 0; // Réinitialise si le mouvement est terminé
                curve_ratio = 0;
                at_end = false;   // Remet l'état "non terminé"
            }
            is_playing = true;
            is_paused = false;
            is_stopped = false;
        return self;
    };
    /// @desc Met en pause le mouvement
    pause = function() {
        if (is_paused || is_stopped) return self; // Ne rien faire si déjà en pause ou arrêté
        is_paused = true;  // Marquer comme "en pause"
        return self;

    };
    /// @desc Arrête le mouvement et réinitialise le ratio
    stop = function() {
        motion_ratio = 0; // Réinitialise la progression
        curve_ratio = 0;
        //is_playing = false;
        is_paused = false;
        is_stopped = true;
        at_end = false;   // Remet l'état "non terminé"
        return self;
    };
    /// @desc Reprend le mouvement depuis l'état de pause
    resume = function() {
        //if (!is_paused) return self; // Ne fait rien si le mouvement n'est pas en pause
        //is_playing = true;
        //is_paused = false;
        //return self;
        if (!is_paused || is_stopped) return self; // Ne rien faire si pas en pause ou arrêté
        is_paused = false; // Retirer l'état "pausé"
        return self;

    };
    /// @desc Bascule entre pause et reprise du mouvement
    toggle_Pause = function() {
        if (is_stopped) return self; // Ne rien faire si le mouvement est arrêté
    
        // Basculer l'état entre pause et reprise
        is_paused = !is_paused; // Inverse l'état de pause
    
        return self; // Retourner l'objet pour chaînage
    };
    on_End = function(_callback, _args = undefined){
        on_end_callback = _callback;
        on_end_arg = _args;
        return self;
    }
    /// @desc Return true when the ratio is reached.
    /// @arg {real} _ratio the ratio on the curve to check
    /// @arg {bool} [_once] Only on the frame it turns true.
    /* If you use an Animation Curve, the method could return true multiple time, even with the _once` booleen.
    // Could happened with curves like Bounce or Elastic.*/
    motion_Is_At = function(_ratio, _once = true){
        return _once 
            ? motion_ratio >= _ratio &&  m_next_ratio >= _ratio && m_prev_ratio < _ratio
            : motion_ratio >= _ratio;
    }
    /// @desc	Add a checkpoint to the curve's checkpoints array.
    //			No duplicates support for now.
    /// @arg	{real} _ratio the ratio to reach to trigger the check point
    /// @arg	{function} [_callback]=undefined the callback to fire
    /// @arg	{struct,array} [_args]=undefined the argument for the callback
    /// @arg	{bool} [_once]=true If the checkpoint should be checked once or each time it is reached. 
    add_Checkpoints = function(_ratio, _callback = undefined, _args = undefined, _once = true){
        var _data = {
            ratio : _ratio,
            callback : _callback,
            args : _args,
            once : _once,
            checked : false
        }
        array_push(checkpoints,_data);
        return self;
    }
    /// @desc return true if a checkpoint has been reached
    /// @param {real} _index the index of the checkpoint in the checkpoints array
    /// @param {bool} _once only on the frame it turns true
    /// @return {bool} true or false
    motion_At_Checkpoint = function(_index, _once = true){
        // Vérifier si l'index est valide
        if (_index < 0 || _index >= array_length(checkpoints)) {
            show_debug_message("Index de checkpoint invalide !");
            return false;
        }
    
        var _checkpoint = checkpoints[_index];
    
        // Vérifier si le ratio est atteint
        return motion_Is_At(_checkpoint.ratio, _once);
    };

    /// @desc Définit une courbe d'animation pour le mouvement et met en cache le canal 0
	set_Motion_Curve = function(_curve_index) {
	    if (!animcurve_exists(_curve_index)) {
	        show_debug_message("Erreur : La courbe spécifiée n'existe pas !");
	        motion_curve = undefined;       // Réinitialiser si la courbe est invalide
	        motion_curve_channel = undefined;  // Réinitialiser le canal en cache
	        return self;
	    }
	
	    motion_curve = animcurve_get(_curve_index); // Stocker la structure de la courbe
	    if (array_length(motion_curve.channels) > 0) {
	        motion_curve_channel = animcurve_get_channel(motion_curve, 0); // Mettre en cache le canal 0
	    } else {
	        show_debug_message("Erreur : La courbe spécifiée n'a pas de canaux !");
	        motion_curve = undefined;       // Réinitialiser si aucun canal n'existe
	        motion_curve_channel = undefined;  // Réinitialiser le canal en cache
	    }
	
	    return self; // Retourner l'objet pour permettre le chaînage
	};


    // Méthode pour appliquer les calculs (logique complémentaire)
    __update_Metrics = function() {
        distance_h = end_x - start_x;
        distance_v = end_y - start_y;
        distance = point_distance(start_x, start_y, end_x, end_y);
      
    };
    __rotate = function() {
        if (rotation_rate > 0) {
            angle += rotation_rate; // Incrémenter l'angle
    
            if (cycles_amount > 0) {
                var max_angle = 360 * cycles_amount;
                if (angle >= max_angle) {
                    angle = max_angle;
                    rotation_rate = 0; // Arrêter la rotation une fois complétée
                }
            } else if (cycles_amount == -1) {
                if (angle >= 360) {
                    angle = angle mod 360; // Réinitialiser après un cycle complet
                }
            }
        }
    };
    // Méthode pour dessiner la courbe
    draw = function() {
        for (var _t = 0; _t <= 1; _t += 1/16) {
            var _x = point_Get_X(_t);
            var _y = point_Get_Y(_t);
            draw_point(_x, _y);
        }

        // Dessiner les points clés (start, apex, end)
        draw_circle_color(end_x, end_y, 4, c_red, c_red, true);
        draw_circle_color(end_x, end_y, 2, c_red, c_red, false);
    };
    // dessiner la courbe debug
    draw_Debug = function(_seg = 16){
        var _t1 = 1/_seg;
        var _i = 0; repeat(_seg-1){
            var _t = _i/_seg;
           var _col = make_colour_hsv(255/_seg*_i, 255, 255);
           var _x = point_Get_X(_t);
           var _y = point_Get_Y(_t);
           draw_circle_color(_x,_y, 2, _col, _col, false);
           var _x2 = point_Get_X(_t + _t1);
           var _y2 = point_Get_Y(_t + _t1);
           draw_line(_x,_y, _x2, _y2);
           _i++;
        }
        //draw point
        draw_line_color(start_x, start_y, end_x, end_y, c_teal, c_red);
        //end
        draw_circle_color(end_x, end_y, 4, c_red, c_red, false);
        //start
        draw_circle_color(start_x, start_y, 4, c_teal, c_teal, false);
        //apex
        draw_circle_color(control_x, control_y, 4, c_orange, c_orange, false);
        //vertex
        draw_circle_color(vertex_x, vertex_y, 4, c_aqua , c_aqua , false);
    }
    
    /// @desc Normalise un angle pour retourner des coordonnées entre -1 et 1
    /// @param {real} _angle : L'angle en degrés (optionnel, peut être vide)
    /// @param {bool} [_signed_int] : Boolean pour indiquer si les valeurs doivent être limitées à -1, 1 ou 0
    function __normalize_Angle(_angle, _signed_int = false) {
        // Vérification si un angle est fourni
        if (is_undefined(_angle)) {
            return { x: 0, y: 0, angle: undefined }; // Valeurs par défaut si aucun angle
        }
        
        // Calcul des coordonnées normalisées
        var x_norm = dcos(_angle); // Cosinus pour la coordonnée X
        var y_norm = -dsin(_angle); // Sinus pour la coordonnée Y (inversion pour GameMaker)
    
        // Si le mode discret est activé
        if (_signed_int) {
            x_norm = (x_norm > 0) - (x_norm < 0); // Limite X à -1, 0 ou 1
            y_norm = (y_norm > 0) - (y_norm < 0); // Limite Y à -1, 0 ou 1
        }
    
        // Retourner une struct avec les valeurs
        return {
            x: x_norm,
            y: y_norm,
            angle: _angle // Ajouter l'angle original en tant que membre
        };
    }
    ///@desc create a simple parabola (mimic prametric equations)
    simple_Parabola = function(_start_x, _start_y, _distance_h = 100, _distance_v = 0, _height = 100, _isometric = false){
        start_Point(_start_x, _start_y)
        end_By_Distance(_distance_h, _distance_v)
        apex_Height(_height, 0.5, _isometric)
        return self
     }
    
    __init_Simple_Parabola = function(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric, _scope){
        var _sx = 0
        var _sy = 0
        if (!is_undefined(_scope) && variable_instance_exists(_scope, "x") && variable_instance_exists(_scope, "y")){
            _sx = _scope.x
            _sy = _scope.y
        }
        
        _sx		= _start_x ?? _sx; // coordonee x du point de depart de la courbe
        _sy		= _start_y ?? _sy; // coordonee y du point de depart de la courbe
        simple_Parabola(_sx, _sy, _distance_h, _distance_v, _height, _isometric)
        point_Set(0)
        
    }
    
    /// Initialise une simple parabole à la creation.
    __init_Simple_Parabola(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric, _scope)
}



