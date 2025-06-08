/// @param ...variables
function log() {
    var str = "";
	
	for (var i=0; i<argument_count; i++) {
		var data = argument[i];

		if (is_struct(data)) {
			str += json_stringify(data);
		} else {
			str += string(data);
		}
		if (i < argument_count-1) str += " ";
	}
	
	show_debug_message("[DEBUG] " + str);
}