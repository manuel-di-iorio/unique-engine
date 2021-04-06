/**
 * Save a struct to a json file
 */
function scr_save_json_to_file(path, json) {
	var f = file_text_open_write(path);
	file_text_write_string(f, json_beautify(json_stringify(json)));
	file_text_close(f);
}