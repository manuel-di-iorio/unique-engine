/**
 * Merge the properties of the structB into the structA
 */
function ueStructMerge(structA, structB) {
  var _names = variable_struct_get_names(structB);
  
  for (var i = 0, il = array_length(_names); i < il; i++) {
    var _name = _names[i];
    structA[$ _name] = structB[$ _name];
  }
}