function scr_history_set_state(action) {
	var obj = action.object;
	var state = action.state;
	obj.x = state.x;
	obj.y = state.y;
	obj.z = state.z;
	obj.xrot = state.xrot;
	obj.yrot = state.yrot;
	obj.zrot = state.zrot;
	obj.xscale = state.xscale;
	obj.yscale = state.yscale;
	obj.zscale = state.zscale;
	
	scr_update_pxsurface();
}