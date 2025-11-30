/**
 * EventDispatcher
 */
function UeEventDispatcher() constructor {
    _listeners = {};

    /**
     * Adds a listener to an event type.
     * @param {string} type The type of event to listen to.
     * @param {function} listener The function that gets called when the event is fired.
     */
    function on(type, listener) {
        var listeners = self._listeners;
        if (listeners[$ type] == undefined) {
            listeners[$ type] = [];
        }
        
        array_push(listeners[$ type], listener);
    }

    /**
     * Removes a listener from an event type.
     * @param {string} type The type of the listener that gets removed.
     * @param {function} listener The listener function that gets removed.
     */
    function off(type, listener) {
        var listeners = self._listeners;
        var listenerArray = listeners[$ type];
        if (listenerArray == undefined) return;

        var index = array_get_index(listenerArray, listener);
        if (index != -1) {
            array_delete(listenerArray, index, 1);
        }
    }

    /**
     * Fire an event type.
     * @param {struct<Event>} event The event that gets fired.
     * 
     * Event struct:
     *  - type: string
     *  - data?: any
     */
    function dispatch(event) {
        var listeners = self._listeners;
        var listenerArray = listeners[$ event.type];
        if (listenerArray == undefined) return;
        
        event.target = self;
            
        for (var i = array_length(listenerArray) - 1; i >= 0; i--) {
            listenerArray[i](event);
        }
        
        event.target = undefined;
    }

    /**
     * Adds a listener to an event type that gets removed after the first event.
     * @param {string} type The type of the event to listen to.
     * @param {function} listener The function that gets called when the event is fired.
     */
    function once(type, listener) {
        var _this = self;
        var ctx = { _this, type, listener, wrapper: undefined };
        ctx.wrapper = method(ctx, function(event) {
            _this.off(type, wrapper);
            listener(event);
        });
        self.on(type, ctx.wrapper);
    }
}
