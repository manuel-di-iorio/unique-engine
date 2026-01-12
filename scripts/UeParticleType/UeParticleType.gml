/**
 * @description A dynamic container for particle properties.
 * It's just a struct with a helper method to set properties fluently.
 */
function UeParticleType() constructor {
    /**
     * Sets a property value.
     * @param {String} name
     * @param {Any} value
     */
    function set(name, value) {
         self[$ name] = value;
         return self;
     }

     /**
      * Helper to set a GM color as RGB array.
      */
     function setColor(color) {
         self.color = [color_get_red(color)/255, color_get_green(color)/255, color_get_blue(color)/255];
         return self;
     }
}
