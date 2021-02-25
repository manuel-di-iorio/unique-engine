/**
 * Load the settings
 */
function scr_load_settings() {
	try {
		if (file_exists("settings.json")) {
			var f = file_text_open_read("settings.json");
			var content = "";
			while (!file_text_eof(f)) {
				content += file_text_readln(f);
			}
			file_text_close(f);
			settings = json_parse(content);
			return;
		} 	
	} catch (err) {
		show_error(err.message, false);
	}
	 
	settings = {
		mouse: {
			xsens: 1,
			ysens: 1
		},
		
		grid: {
			show: true,
			xoffset: 32,
			yoffset: 32,
			//snap: true, // @todo
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
		},
		
		debug: {
			overlay: false
		}
	};
	
	scr_save_settings();
}