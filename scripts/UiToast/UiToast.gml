/// @desc UiToast — notification container that spawns alerts in the top-right corner.
/// @param {Struct} style
/// @param {Struct} props
function UiToast(style = {}, props = {}) : UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiToast");
    
    // Position/layout defaults for the toast container
    flexpanel_node_style_set_position_type(self.node, flexpanel_position_type.absolute);
    if (style[$ "right"] == undefined) self.setRight(20);
    if (style[$ "top"] == undefined) self.setTop(20);
    if (style[$ "width"] == undefined) self.setWidth(320);
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.column);
    flexpanel_node_style_set_align_items(self.node, flexpanel_align.stretch);
    
    // Clicks should pass through the empty space of the container to elements below
    self.pointerEvents = false;
    
    /**
     * @desc Spawns a toast alert at the top of the stack.
     * @param {String} message The alert body text
     * @param {String} type The semantic type: "info", "success", "warning", "error" (default "info")
     * @param {String} title Optional bold title shown above the message
     * @param {Real} duration Time in milliseconds before auto-dismiss (default 4000, <=0 to disable)
     * @return {Struct} The spawned UiAlert instance
     */
    self.show = function(message, type = "info", title = undefined, duration = 4000) {
        // Ensure this container is attached to the overlay layer of the UI root
        if (self.parent == undefined && global.UI != undefined) {
            global.UI.getOverlay().add(self);
        }
        
        var alertProps = {
            type: type,
            title: title,
            dismissible: true
        };
        
        var alert = new UiAlert(message, {
            marginBottom: 10,
            width: "100%"
        }, alertProps);
        
        // When the alert is dismissed, destroy it to clean up node hierarchy and memory
        alertProps.onDismiss = method({ alert }, function() {
            alert.destroy();
            global.UI.requestUpdate();
        });
        
        // Setup automatic dismissal timer if duration is specified
        if (duration > 0) {
            var expireTime = current_time + duration;
            alert.onStep(method({ alert, expireTime }, function() {
                if (current_time >= expireTime) {
                    alert.destroy();
                    global.UI.requestUpdate();
                }
            }));
        }
        
        // Insert child at index 0 (newest on top)
        if (alert.parent != undefined) alert.parent.remove(alert);
        flexpanel_node_insert_child(self.node, alert.node, 0);
        array_insert(self.children, 0, alert);
        self.childrenLength++;
        alert.parent = self;
        self.requestUpdate();
        
        return alert;
    };
    
    /**
     * @desc Spawns a success toast alert.
     * @param {String} message The alert body text
     * @param {String} title Optional bold title shown above the message
     * @param {Real} duration Time in milliseconds before auto-dismiss
     * @return {Struct} The spawned UiAlert instance
     */
    self.success = function(message, title = undefined, duration = 4000) {
        return self.show(message, "success", title, duration);
    };
    
    /**
     * @desc Spawns an error toast alert.
     * @param {String} message The alert body text
     * @param {String} title Optional bold title shown above the message
     * @param {Real} duration Time in milliseconds before auto-dismiss
     * @return {Struct} The spawned UiAlert instance
     */
    self.error = function(message, title = undefined, duration = 4000) {
        return self.show(message, "error", title, duration);
    };
    
    /**
     * @desc Spawns a warning toast alert.
     * @param {String} message The alert body text
     * @param {String} title Optional bold title shown above the message
     * @param {Real} duration Time in milliseconds before auto-dismiss
     * @return {Struct} The spawned UiAlert instance
     */
    self.warning = function(message, title = undefined, duration = 4000) {
        return self.show(message, "warning", title, duration);
    };
    
    /**
     * @desc Spawns an info toast alert.
     * @param {String} message The alert body text
     * @param {String} title Optional bold title shown above the message
     * @param {Real} duration Time in milliseconds before auto-dismiss
     * @return {Struct} The spawned UiAlert instance
     */
    self.info = function(message, title = undefined, duration = 4000) {
        return self.show(message, "info", title, duration);
    };
}

// Global instance variable (instantiated lazily on first toast call)
global.UiToastInstance = undefined;

// ── Global Helper Functions ───────────────────────────────────────────────

/// @desc Spawns a global toast alert.
/// @param {String} message
/// @param {String} type
/// @param {String} title
/// @param {Real} duration
function ui_toast_show(message, type = "info", title = undefined, duration = 4000) {
    if (global.UiToastInstance == undefined || global.UiToastInstance.destroyed) {
        global.UiToastInstance = new UiToast();
    }
    return global.UiToastInstance.show(message, type, title, duration);
}

/// @desc Spawns a global success toast alert.
/// @param {String} message
/// @param {String} title
/// @param {Real} duration
function ui_toast_success(message, title = undefined, duration = 4000) {
    return ui_toast_show(message, "success", title, duration);
}

/// @desc Spawns a global error toast alert.
/// @param {String} message
/// @param {String} title
/// @param {Real} duration
function ui_toast_error(message, title = undefined, duration = 4000) {
    return ui_toast_show(message, "error", title, duration);
}

/// @desc Spawns a global warning toast alert.
/// @param {String} message
/// @param {String} title
/// @param {Real} duration
function ui_toast_warning(message, title = undefined, duration = 4000) {
    return ui_toast_show(message, "warning", title, duration);
}

/// @desc Spawns a global info toast alert.
/// @param {String} message
/// @param {String} title
/// @param {Real} duration
function ui_toast_info(message, title = undefined, duration = 4000) {
    return ui_toast_show(message, "info", title, duration);
}
