/**
 * Save the settings to the file
 */
function scr_save_settings() {
	var f = file_text_open_write("settings.json");
	file_text_write_string(f, json_beautify(json_stringify(settings)));
	file_text_close(f);
}