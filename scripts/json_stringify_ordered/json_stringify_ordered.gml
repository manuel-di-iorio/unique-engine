// v1.1.1

/// @function json_stringify_ordered(value, [prettify], [compact])
/// @description Converts any value (struct, array, or primitive) to a formatted JSON string using buffers for better performance
/// @param {any} value The value to convert to JSON
/// @param {bool} [prettify=false] Whether to include pretty formatting
/// @param {real} [compact=0] Character threshold to keep arrays/objects on a single line. 0 = disabled.
/// @return {string} A properly formatted and indented JSON string
function json_stringify_ordered(value, prettify = false, compact = 0) {
  gml_pragma("forceinline");
  var buf = buffer_create(1024, buffer_grow, 1);
  __json_stringify_buffer(value, buf, 0, prettify, compact);
  var result = buffer_peek(buf, 0, buffer_text);
  buffer_delete(buf);
  return result;
}

/// @function __json_stringify_buffer(v, buf, indent, prettify, compact, is_spaced)
/// @description Serializes a value into a buffer with JSON formatting.
/// @param {any} v The value to serialize (struct, array, or primitive)
/// @param {id.buffer} buf The target buffer where the serialized data will be written
/// @param {real} [indent=0] The current indentation level for prettify-printing
/// @param {bool} [prettify] Whether to include pretty formatting
/// @param {real} [compact=0] Character threshold to keep small arrays/objects on a single line
/// @param {bool} [is_spaced=false] Whether to add spaces around elements in compact mode
/// @return {undefined}
function __json_stringify_buffer(v, buf, indent = 0, prettify, compact = 0, is_spaced = false) {
  gml_pragma("forceinline");
  
  // If compact is enabled, try to stringify the whole value on a single line if it's short
  if (prettify && compact > 0 && !is_spaced && (is_struct(v) || is_array(v))) {
     var test_buf = buffer_create(128, buffer_grow, 1);
     __json_stringify_buffer(v, test_buf, 0, false, 0, true);
     buffer_write(test_buf, buffer_u8, 0); // null terminator for buffer_peek
     var s = buffer_peek(test_buf, 0, buffer_text);
     buffer_delete(test_buf);
     
     if (string_length(s) < compact) {
        buffer_write(buf, buffer_text, s);
        return;
     }
  }

  if (is_struct(v)) __json_stringify_struct(v, buf, indent, prettify, compact, is_spaced);
  else if (is_array(v)) __json_stringify_array(v, buf, indent, prettify, compact, is_spaced);
  else __json_stringify_primitive(v, buf);
}

/// @function __json_stringify_primitive(v, buf)
/// @description Writes a primitive value to buffer in JSON format. 
///   Handles strings, handles, numbers (including int64), booleans, and special values (`undefined`, `NaN`, `Infinity`, etc.)
/// @param {any} v The primitive value to convert
/// @param {id.buffer} buf The buffer to write to
/// @private
function __json_stringify_primitive(v, buf) {
  gml_pragma("forceinline");
  if (is_string(v) || is_handle(v)) {
    buffer_write(buf, buffer_u8, ord("\""));
    buffer_write(buf, buffer_text, __json_escape_string(string(v)));
    buffer_write(buf, buffer_u8, ord("\""));
  }
  else if (is_infinity(v)) {
    buffer_write(buf, buffer_u8, ord("\""));
    buffer_write(buf, buffer_text, v > 0 ? "@@infinity$$" : "@@-infinity$$");
    buffer_write(buf, buffer_u8, ord("\""));
  }
  else if (is_int64(v)) {
    buffer_write(buf, buffer_u8, ord("\""));
    buffer_write(buf, buffer_text, "@i64@");
    buffer_write(buf, buffer_text, __int64_to_hex(v));
    buffer_write(buf, buffer_text, "$i64$");
    buffer_write(buf, buffer_u8, ord("\""));
  }
  else if (is_real(v)) {
    buffer_write(buf, buffer_text, string(v));
  }
  else if (is_bool(v)) {
    buffer_write(buf, buffer_text, v ? "true" : "false");
  }
  else if (is_undefined(v)) {
    buffer_write(buf, buffer_text, "null");
  } else if (is_nan(v)) {
    buffer_write(buf, buffer_u8, ord("\""));
    buffer_write(buf, buffer_text, "@@nan$$");
    buffer_write(buf, buffer_u8, ord("\""));
  }
}

/// @function __json_stringify_array(arr, buf, indent, prettify, compact, is_spaced)
/// @description Writes an array to buffer in JSON format with proper indentation
/// @param {array} arr The array to convert
/// @param {id.buffer} buf The buffer to write to
/// @param {real} indent The current indentation level
/// @param {bool} prettify Whether to include pretty formatting
/// @param {real} compact Whether to keep small arrays/objects on a single line
/// @param {bool} is_spaced Whether to add spaces around elements in compact mode
/// @private
function __json_stringify_array(arr, buf, indent, prettify, compact, is_spaced = false) {
  gml_pragma("forceinline");
  buffer_write(buf, buffer_u8, ord("["));
  
  var al = array_length(arr);
  if (is_spaced && !prettify && al > 0) buffer_write(buf, buffer_u8, ord(" "));
  if (prettify) buffer_write(buf, buffer_u8, 10); // newline
  
  var pad = string_repeat("  ", indent + 1);
  var pad_close = string_repeat("  ", indent);
 
  for (var i = 0; i < al; i++) {
      if (prettify) buffer_write(buf, buffer_text, pad);
      __json_stringify_buffer(arr[i], buf, indent + 1, prettify, compact, is_spaced);

      if (i < al - 1) {
          buffer_write(buf, buffer_u8, ord(","));
          if (is_spaced && !prettify) buffer_write(buf, buffer_u8, ord(" "));
      }
      if (prettify) buffer_write(buf, buffer_u8, 10); // newline
  }

  if (prettify) buffer_write(buf, buffer_text, pad_close);
  if (is_spaced && !prettify && al > 0) buffer_write(buf, buffer_u8, ord(" "));
  buffer_write(buf, buffer_u8, ord("]"));
}

/// @function __json_stringify_struct(st, buf, indent, prettify, compact, is_spaced)
/// @description Writes a struct to buffer in JSON format with proper indentation. Keys are sorted alphabetically
/// @param {struct} st The struct to convert
/// @param {id.buffer} buf The buffer to write to
/// @param {real} indent The current indentation level
/// @param {bool} prettify Whether to include pretty formatting
/// @param {real} compact Whether to keep small arrays/objects on a single line
/// @param {bool} is_spaced Whether to add spaces around elements in compact mode
/// @private
function __json_stringify_struct(st, buf, indent, prettify, compact, is_spaced = false) {
  gml_pragma("forceinline");
  var keys = variable_struct_get_names(st);
  array_sort(keys, true);

  buffer_write(buf, buffer_u8, ord("{"));
  
  var kl = array_length(keys);
  if (is_spaced && !prettify && kl > 0) buffer_write(buf, buffer_u8, ord(" "));
  if (prettify) buffer_write(buf, buffer_u8, 10); // newline
  
  var pad = string_repeat("  ", indent + 1);
  var pad_close = string_repeat("  ", indent);

  for (var i = 0; i < kl; i++) {
      var k = keys[i];
      
      if (prettify) buffer_write(buf, buffer_text, pad);
      buffer_write(buf, buffer_u8, ord("\""));
      buffer_write(buf, buffer_text, __json_escape_string(k));
      buffer_write(buf, buffer_text, (prettify || is_spaced) ? "\": " : "\":");
      
      __json_stringify_buffer(st[$ k], buf, indent + 1, prettify, compact, is_spaced);

      if (i < kl - 1) {
          buffer_write(buf, buffer_u8, ord(","));
          if (is_spaced && !prettify) buffer_write(buf, buffer_u8, ord(" "));
      }
      if (prettify) buffer_write(buf, buffer_u8, 10); // newline
  }

  if (prettify) buffer_write(buf, buffer_text, pad_close);
  if (is_spaced && !prettify && kl > 0) buffer_write(buf, buffer_u8, ord(" "));
  buffer_write(buf, buffer_u8, ord("}"));
}

/**
 * @internal: Escapes a string for JSON inclusion
 * @param {string} str The string to escape
 * @return {string} The escaped string
 */
function __json_escape_string(str) {
  gml_pragma("forceinline");
  var s = string_replace_all(str, "\\", "\\\\");
  s = string_replace_all(s, "\"", "\\\"");
  s = string_replace_all(s, "\n", "\\n");
  s = string_replace_all(s, "\r", "\\r");
  s = string_replace_all(s, "\t", "\\t");
  s = string_replace_all(s, "\b", "\\b");
  s = string_replace_all(s, "\f", "\\f");
  return s;
}

/**
 * @internal: Converts a signed int64 to a 16-character lowercase hexadecimal string.
 * @param {int64} v The signed int64 value to convert
 * @return {string} The hexadecimal representation of the int64 value
 */
function __int64_to_hex(v) {
  gml_pragma("forceinline");
  if (v == 0) return "0";
    
  var hex_digits = "0123456789abcdef";
  var hex_str = "";
  var temp = v;
  
  while (temp > 0) {
    var remainder = temp mod 16;
    hex_str = string_char_at(hex_digits, remainder + 1) + hex_str;
    temp = temp div 16;
  }
  
  return hex_str;
}
