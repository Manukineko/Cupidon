draw_text(16, 16 * 1,  $"[Z] - isometric: {isometric}");
draw_text(16, 16 * 2,  $"[S] - Stop on End: {stopOnEnd}");
draw_text(16, 16 * 3,  $"[F] - Fire on End: {fireOnEnd}");
draw_text(16, 16 * 4,  $"[I] - Orient: {!internal}");
draw_text(16, 16 * 5,  $"[R] - Rotation number: {rotationNumber}");
draw_text(16, 16 * 6,  $"[T] - Force full Rotation: {fullRotation}");
draw_text(16, 16 * 7,  $"[A] - Remove Curve");
draw_text(16, 16 * 8,  $"[Hold A +] - Curve : {aCurveName}");
draw_text(32, 16 * 9,  $"[1] - Linear");
draw_text(32, 16 * 10, $"[2] - Bounce Out");
draw_text(32, 16 * 11, $"[3] - Cubic In Out");
draw_text(32, 16 * 12, $"[4] - Weird One");
draw_text(16, 16 * 13,  $"[Enter] - Randomize {fullRandom}");

draw_set_halign(fa_center);
draw_text(viewWidthSlice, viewHeight, "[LMB] - Play");
draw_text(viewWidthSlice * 2, viewHeight, "[Space] - Pause/Resume");
draw_text(viewWidthSlice * 3, viewHeight, "[RMB] - Reset");
draw_set_halign(fa_left);
