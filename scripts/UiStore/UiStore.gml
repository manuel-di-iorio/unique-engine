/**
 * UiStore - Lightweight reactive UI state management store
 * Allows component state sharing and reactive UI binding
 */
function UiStore(initialState = {}) constructor {
    self.state = initialState;
    self.listeners = [];
    
    /**
     * Set a state key to a new value and notify subscribers.
     * @param {String} key The key to modify
     * @param {Any} value The new value
     */
    self.set = function(key, value) {
        self.state[$ key] = value;
        for (var i = 0; i < array_length(self.listeners); i++) {
            self.listeners[i](self.state);
        }
        
        // Automatically request redraw on state update if global UI exists
        if (global.UI != undefined) {
            global.UI.requestRedraw();
        }
    };
    
    /**
     * Get a state key's value.
     * @param {String} key The key to retrieve
     * @param {Any} defaultValue The default value if key is not found
     */
    self.get = function(key, defaultValue = undefined) {
        return self.state[$ key] ?? defaultValue;
    };
    
    /**
     * Subscribe to state updates.
     * @param {Function} callback Callback receiving the new state struct
     */
    self.subscribe = function(callback) {
        array_push(self.listeners, callback);
        return self;
    };
}
