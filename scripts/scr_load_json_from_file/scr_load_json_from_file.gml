/**
 * Load a json from the file
 */
function scr_load_json_from_file(path, getContentHash) {
	var f = file_text_open_read(path);
	var content = "";
	while (!file_text_eof(f)) {
		content += file_text_readln(f);
	}
	file_text_close(f);
	
	var data = { json: json_parse(content) };
	if (getContentHash) data.hash = sha1_string_utf8(content);
	
	return data;
}