//trajectory.draw_Debug();
if drawCurve {
    trajectory.draw(100, c_red, c_red, c_aqua, c_green).draw_Checkpoint();
}
draw_self();
draw_text(x,y, $"{trajectory.motion_ratio}");