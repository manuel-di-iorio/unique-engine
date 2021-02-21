gpu_set_fog(false, 0, 0, 0);

//if (surface_exists(pxSurface)) draw_surface(pxSurface, 0, 0); // @debug

scr_draw_debug_info();

if (cursorSprite != -1) draw_sprite(cursorSprite, 0, winMouseX, winMouseY);
scr_fog_enable();