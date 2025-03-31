// Example usage in a Create Event
//test = new Parabole(x, y, x + 120, y - 120, 50, 10);
trajectory = new Parabola();
//trajectory.start(x,y).goal( x+100, y).height(100).duration(1).apply();
//trajectory.start(x,y).goal( x, y).height(100).duration(1).apply();
trajectory.on_Goal(function(){
	//x = trajectory.end_x
	//y = trajectory.end_y
    //run = false;
})
run = false;
key = 0
curvename = ["by Coord","by Length", "by Direction", "By Direction (y:/2" ]

#region 



#endregion
#region
wrap = function(_value, _min, _max) {
	var _mod = (_value - _min) mod (_max - _min);
	return (_mod < 0) ? _mod + _max : _mod + _min;
}
clamp_wrap = function(_value, _min, _max) {
	if (_value > _max) _value = _min; else if (_value < _min) _value = _max;
	return _value;
}
parabola_selection = function(_n){
    switch(_n){
        //by Coord
        case 0 : trajectory.start(x,y).goal(x + 100, y-100).height(50).duration(1).apply();
        //by Length
        case 1 : trajectory.start(x,y).goal_By_Distance(100, -100).height(100).duration(1).apply();
        break
        //by Direction
        case 2 : trajectory.start(x,y).goal_By_LengthDir(100, 45).height(100).duration(1).apply();
        break
        case 3 : trajectory.start(x,y).goal_By_LengthDir(100, 45, 10).height(100).duration(1).apply();
        break
    }
}
parabola_selection(key)
#endregion