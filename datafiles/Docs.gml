/// @category Cupidon Ext
/// @title API Ext

/// @constructor
/// @func Cupidon(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric, _internal, _scope)
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

///@text ## Curve Ext
///@method simple_Parabola(_start_x, _start_y, _distance_h, _distance_v, _height, _isometric)
/// @desc  Create a simple parabola (mimicing parametric equations) with default values
/// @param {real} _start_x start point coordinate
/// @param {real} _start_y end point coordinate
/// @param {real} [_distance_h]=100 the horizontal distance to the end point
/// @param {real} [_distance_v]=0 the vertical distance to the end point
/// @param {real} [_height]=100 the height of the parabola
/// @param {bool} [_isometric]=false toogle the fake isometric calculation
/// @returns {struct} self 

/// @text ## Anchor Ext
/// @text The Anchor is a point whose coordinate are stored in the `x` and `y` variable.
/// They are automatically updated when calling `anchor_Motion` and you retrieve those like this:
/// @code
/// // Instance step event
/// x = myCupidon.x
/// y = myCupidon.y

/// @method anchor_Set(position)
/// @desc  Set the internal point's `x` and `y` on the parabola.
/// @param {real} _position the position on the parabola. Between 0 (start point) and 1 (end point). A negative value is before the start point and a value superior to 1 is after the end point.
/// @returns {struct}    