// Update the selection outline surface
scr_selection_outline_surf_update();

// Draw the grid
if (!drawGameOnly && settings.grid.show) vertex_submit(gridVbuff, pr_linelist, -1);

// Draw the scene
scr_draw_scene(false);