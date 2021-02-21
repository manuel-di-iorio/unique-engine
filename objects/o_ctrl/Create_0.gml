alarm[0] = 1; // AA
device_mouse_dbclick_enable(false);
show_debug_overlay(true);

enum Colors3D {
	// Transform 
	red = $3a1be0,  
	green = $18d415,
	blue = $e05402,
  
	// Selection
	selection = $0dc7d1,
	selectionR = 209,
	selectionG = 199,
	selectionB = 13,
	
	// Hover
	hover = $6be5ff,
	hoverR = 0,
	hoverG = 0,
	hoverB = 0
}

enum ObjectType {
	model,
	selector
}

enum Tools {
	hand,
	translate,
	rotate,
	scale
}

// Maximize the window (twice to fix gm draw resize)
window_command_run(window_command_maximize);
window_command_run(window_command_minimize);
window_command_run(window_command_maximize);

// Variables
x = 200;
y = 150;
z = 60;
direction = 130;
zdir = 20;
camFov = 60;
stats = {
	models: 0, // Models
	meshes: 0, // Meshes
    triangles: 0, // Triangles
	lights: 1, // Lights,
	audioSources: 0, // Audio sources
	selectors: 0
};
winMouseX = 0;
winMouseY = 0;
winOldMouseX = 0;
winOldMouseY = 0;
winOldW = 0;
winOldH = 0;
aa_enabled = false//true;
lightEnabled = true;
models = []; // List of models
pxSurface = -1;
selectedPxCol = 0;
selectionId = 1; // Object ID for the selection surface
selectors = []; // List of selectors
selectedObj = -1; // Selected object (model/selector)
selectedGizmo = -1; // Selected gizmo component
selectedTool = Tools.translate; // Selected tool
cursorSprite = -1;

// Default light
tex_light = sprite_get_texture(s_light, 0);
scr_model_add_selector(0, 0, 0, 0, tex_light);

// Audio texture
tex_audio_source = sprite_get_texture(s_audio, 0);

// Resize the editor
scr_on_window_resize();

scr_setup_3d();

// Create the grid
scr_model_build_grid();

// Create the gizmo model
scr_model_build_gizmo();

// Create a default cube
tex_cube = sprite_get_texture(s_cube, 0);
//tex_cube_texel_w = texture_get_texel_width(tex_cube);
//tex_cube_texel_h = texture_get_texel_height(tex_cube);
scr_model_add_default_cube();

// Shaders variables
shdrReplaceCol_uCol = shader_get_uniform(shdr_replace_color,  "u_col");
shdrBlendCol_uCol = shader_get_uniform(shdr_blend_color,  "u_col");