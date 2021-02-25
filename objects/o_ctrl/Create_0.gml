// Load the settings
scr_load_settings();

// Set display AA/VSync
alarm[0] = 1; 

// Show debug overlay
if (settings.debug.overlay) show_debug_overlay(true);

// Disable the double click support (to reduce click delay)
device_mouse_dbclick_enable(false);

enum Colors3D {
	// Transform 
	x = $3a1be0,  
	y = $00b300,
	z = $e05402,
	hover = $0dc7d1,
	selection = $6be5ff,
}

#macro ColorHoverR 209 * .0039
#macro ColorHoverG 199 * .0039
#macro ColorHoverB 13 * .0039

#macro ColorSelectionR 255 * .0039
#macro ColorSelectionG 229 * .0039
#macro ColorSelectionB 107 * .0039

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

// Set the room background color
layer_background_blend(layer_background_get_id("Background"), settings.camera.bgcol)

// Maximize the window
window_command_run(window_command_maximize);
window_command_run(window_command_minimize);
window_command_run(window_command_maximize);

// Variables
x = 130;
y = -50;
z = 50;
cameraXT = 0;
cameraYT = 0;
cameraZT = 0;
cameraF = 0;
direction = 110;
zdir = 20;
cameraFov = 60;
cameraAspectRatio = view_get_wport(0)/view_get_hport(0);
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
winMouse3DX = 0;
winMouse3DY = 0;
winOldMouse3DX = 0;
winOldMouse3DY = 0;
winMouse3DZ = 0;
winOldMouse3DZ = 0;
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

// Setup the 3D environment and projection
scr_setup_3d();

// Create the grid
gridVbuff = -1;
scr_model_build_grid();

// Create the gizmo model
scr_model_build_gizmo();

// Create a default cube
tex_cube = sprite_get_texture(s_cube, 0);
scr_model_add_default_cube();

// Shaders variables
shdrReplaceCol_uCol = shader_get_uniform(shdr_replace_color,  "u_col");
shdrBlendCol_uCol = shader_get_uniform(shdr_blend_color,  "u_col");