# c∪pido∩
a small library to create trajectories with Quadratic Bezier Curves that you will love (may be).

I was quite frustrated when I add to create a trajectory for annitem to follow in order to simulate a simple throw at from a character, without relying on physics and friction.
I just wanted a nice parabola.

This library allows you to create a parabola (a simple quadratic Bezier curve) as a constructor and it will calculate automatically a coordinate on the curve for you to use with any stuff, just doing :
```gml
// attached object step event or where you want
x = myParabola.x
y = myParabola.y
```

to create a parabola, you need a starting point, an ending point (several method are available for different way of set that point up) and a height.

then Librarie support
- motion - to update the point position each frame
- 
- rotation - to sync (or not) the rotation to the duration
