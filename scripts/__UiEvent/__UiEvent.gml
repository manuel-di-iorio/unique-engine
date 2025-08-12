enum UI_EVENT {
    wheelup,
    wheeldown,
    
    mousedown,
    mouseup,
    
    mousemove,
    
    mouseover,
    mouseout,
    
    // enter/leave do not bubble
    mouseenter,
    mouseleave,
    click,
}

function UiEvent(type, target, originalEvent = undefined) constructor {
    self.type = type;
    self.target = target;
    self.currentTarget = undefined;
    self.phase = "none"; // "capture", "target", "bubble"
    self.stopped = false;
    self.originalEvent = originalEvent;
    
    function stopPropagation() {
        self.stopped = true;
    }
}
