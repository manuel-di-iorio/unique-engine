OS_CONFIG_RELEASE = os_get_config() == "release";

// Imported models standard format
vertex_format_begin(); 
vertex_format_add_position_3d();
vertex_format_add_texcoord();
vertex_format_add_normal();
vertex_format_add_color();
uniqueEngine_vformat =  vertex_format_end();

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
	selector,
	camera
}

enum Tools {
	hand,
	translate,
	rotate,
	scale
}

enum ProjectChangeType {
	objectTransformed,
	objectAdded,
	objectRenamed,
	objectDeleted
}

// Set the room background color
layer_background_blend(layer_background_get_id("Background"), settings.camera.bgcol);

// Maximize the window
window_command_run(window_command_maximize);
window_command_run(window_command_minimize);
window_command_run(window_command_maximize);

// Variables
x = 40;
y = 120;
z = 60;
cameraXT = 0;
cameraYT = 0;
cameraZT = 0;
cameraF = 0;
direction = 110;
zdir = 20;
cameraFov = settings.camera.fov;
cameraAspectRatio = view_get_wport(0)/view_get_hport(0);
stats = {
	models: 0, // Models
	drawCalls: 0, // Draw calls
    triangles: 0, // Triangles
	lights: 0, // Lights,
	audioSources: 0, // Audio sources
	selectors: 0
};

// Mouse variables
winMouseX = 0;
winMouseY = 0;
winOldMouseX = 0;
winOldMouseY = 0;
winOldW = 0;
winOldH = 0;
winMouse3DX = 0;
winMouse3DY = 0;
winMouse3DZ = 0;
winMouse3DY_planeX = 0;
winMouse3DZ_planeX = 0;
winMouse3DX_planeY = 0;
winMouse3DZ_planeY = 0;
winOldMouse3DX = 0;
winOldMouse3DY = 0;
winOldMouse3DZ = 0;
winOldMouse3DY_planeX = 0;
winOldMouse3DZ_planeX = 0;
winOldMouse3DX_planeY = 0;
winOldMouse3DZ_planeY = 0;

// Project variables
projectYypPath = "";
projectModels = [];
projectCameras = [];
projectAudioSources = [];
projectLights = [];
projectRooms = [];
projectChanges = []; // Store the changes to resync on project save

// Other variables
models = []; // List of models
pxSurface = -1;
selectedPxCol = 0;
selectionId = 1; // Object ID for the selection surface
selectors = []; // List of selectors
selectedObj = -1; // Selected object (model/selector)
selectedGizmo = -1; // Selected gizmo component
selectedTool = Tools.translate; // Selected tool
cursorSprite = -1;
history_list = ds_list_create(); // History of performed actions
history_index = 0; // Current history list position
surfHudAxis = -1; // HUD axis icon surface
surfSelectionOutline = -1; // Selection outline surface
drawGameOnly = false; // When enabled, will only draw the game objects (no GUI, selectors, etc..)

// Default light source
var tex_light = sprite_get_texture(s_light, 0);
//scr_model_add_selector(0, 0, 100, 0, tex_light);

// Audio source texture
var tex_audio_source = sprite_get_texture(s_audio, 0);

// Setup the 3D environment and projection
scr_setup_3d();

// Create the grid
gridVbuff = -1;
scr_model_build_grid();

// Create the gizmo model
scr_model_build_gizmo();

// Init the HUD axis icon
scr_hudaxis_init();

// Shaders variables
shdrReplaceCol_uCol = shader_get_uniform(shdr_replace_color,  "u_col");
shdrBlendCol_uCol = shader_get_uniform(shdr_blend_color,  "u_col");

// Resize the editor
scr_on_window_resize();

// Every tot seconds, check if the loaded project has been externally modified
alarm[2] = 1;

// Create a default cube
tex_cube = sprite_get_texture(s_cube, 0);
scr_model_add_default_cube(0, 0);

/*
// Load the default vehicle model
var vehicle_path = "";
var vehicle_sprite = sprite_add(vehicle_path + "5715.jpg", 1, 0, 0, 0, 0);
var vehicle_texture = sprite_get_texture(vehicle_sprite, 0)
//var vehicle_meshes = scr_model_load(vehicle_path + "4.obj");
var vehicle_meshes = scr_model_load_from_buffer(vehicle_path + "4.obj").meshes;

if (vehicle_meshes != -1) {
	for (var i=0; i<array_length(vehicle_meshes); i++) {
		vehicle_meshes[i].texture = vehicle_texture;	
	}
	
	var vehicle_object = { 
		type: ObjectType.model, 
		x: 50, y: -50, z: 0, xrot: 270, yrot: 0, zrot: 0, xscale: .02, yscale: .02, zscale: .02, 
		meshes: vehicle_meshes,
		meshesCount: array_length(vehicle_meshes)
	};
	scr_model_prebuild_matrix(vehicle_object);
	scr_obj_set_selection_id(vehicle_object);
	array_push(models, vehicle_object);
	stats.models++;
	stats.drawCalls += vehicle_object.meshesCount;
}