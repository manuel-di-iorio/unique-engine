/**
 * Load the settings
 */
function scr_load_settings() {
	file_delete("settings.json"); // @todo

	try {
		if (file_exists("settings.json")) {
			settings = scr_load_json_from_file("settings.json").json;
			return;
		} 	
	} catch (err) {
		show_error(err.message, false);
	}
	 
	 // Default settings
	settings = {
		mouse: {
			xsens: 1,
			ysens: 1
		},
		
		grid: {
			show: true,
			xoffset: 32,
			yoffset: 32,
			snap: true,
		},
	
		camera: {
			bgcol: $3A2B29,
			fov: 60,
			fog: true,
			lightning: true
		},
		
		display: {
			aa: -1,
			vsync: false,
			texfilter: true,
		},
		
		debug: {
			overlay: !OS_CONFIG_RELEASE
		}
	};
	
	scr_save_json_to_file("settings.json", settings);
}