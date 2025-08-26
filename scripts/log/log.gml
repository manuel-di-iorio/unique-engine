/// @param ...variables
function log() {
    var str = "";
	
	for (var i =0; i < argument_count; i++) {
		var data = argument[i];
        
        if (is_struct(data)) {
            str += json_stringify(ueStructMap(data, function(key, value) {
                return __logItemToString(value);
            }), false);
            
        } else if (is_array(data)) {
            str += json_stringify(array_map(data, function(value) {
                if (is_struct(value)) {
                    return ueStructMap(value, function(_key, _value) {
                       return __logItemToString(_value); 
                    });
                    
                } else {
                    return __logItemToString(value);
                }
            }), false);
        
		} else {
			str += string(data);
		}
        
		if (i < argument_count-1) str += " ";
	}
	
	show_debug_message($"[DEBUG {date_datetime_string(date_current_datetime())}] {str}");
}

function __logItemToString(value) {
    if (is_bool(value) || is_numeric(value) || is_undefined(value)) return value;
    
    if (is_array(value)) return $"<array({array_length(value)})>";
    
    if (is_callable(value)) return $"<function>";
    
    if (is_struct(value)) {
        var constr = instanceof(value);
        if (constr == "function" || constr == "struct") return "<struct>";
        return $"<struct.{instanceof(value)}>";
    }
     
    return value;
}