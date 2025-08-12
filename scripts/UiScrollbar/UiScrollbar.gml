function UiScrollbar(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "__UiScrollbar");
    self.dragged = false;
    self.dragStartY = undefined;
    self.dragStartScrollTop = undefined; 
    self.maxScroll = 0;
    self.pointerEvents = true;
    
    // Create the thumb
    self.Thumb = new UiScrollbarThumb({ position: "absolute", left: 0, right: 0, top: 0, height: 0 }, { isScrollbar: true });
    self.add(self.Thumb);
    
    function onMount() {
        self.parent.onWheelUp(function(ev) {
            self.parent.scrollTop = max(0, self.parent.scrollTop - 30);
        });
        
        self.parent.onWheelDown(function(ev) {
            self.parent.scrollTop = min(self.maxScroll, self.parent.scrollTop + 30);
        });
    }
    
    function onStep() {
        var layoutHeight = self.layout.height;
        
        // Height calculation
        var contentHeight = self.parent.reduceChildren(function(height, child) {
            if (child.getName() == "__UiScrollbar") return height;
            return height + child.layout.height;
        }, 0, false);
        
        var thumbHeight = max(10, min(layoutHeight, layoutHeight * (layoutHeight / contentHeight)));

        if (thumbHeight != self.Thumb.getHeight()) {
            self.Thumb.setHeight(thumbHeight);
        }
        
        // Dragging
        if (self.dragged) {
            var currentMouseY = self.getMouseY();
            var deltaY = currentMouseY - self.dragStartY;
            
            if (self.maxScroll > 0) {
                var maxThumbPosition = layoutHeight - thumbHeight;
                
                if (maxThumbPosition > 0) {
                    // Convert thumb movement to scroll position
                    var scrollDelta = (deltaY / maxThumbPosition) * self.maxScroll;
                    self.parent.scrollTop = clamp(self.dragStartScrollTop + scrollDelta, 0, self.maxScroll);
                }
            }
        }
        
        // Compute the thumb max scroll and position
        self.maxScroll = max(0, contentHeight - self.parent.layout.height);
        
        var maxThumbPosition = layoutHeight - thumbHeight;
        var thumbPosition = (self.parent.scrollTop / self.maxScroll) * maxThumbPosition; 
        self.Thumb.setTop(thumbPosition);
    }
}

function UiScrollbarThumb(style = {}, props = {}): UiNode(style, props) constructor {
    self.pointerEvents = true;
    setName(style[$ "name"] ?? "__UiScrollbar.Thumb");
    
    onMouseDown(function(ev) {
        self.parent.dragged = true;
        self.parent.dragStartY = self.parent.getMouseY();
        self.parent.dragStartScrollTop = self.parent.parent.scrollTop;
        
        self.setWidth(12);
        self.setLeft(-3);
    });
    
    onMouseUp(function() {
        self.parent.dragged = false;
        self.setWidth(6);
        self.setLeft(0);
    });
    
    function onDraw() {
        if (getHeight() == self.parent.layout.height) return;

        draw_set_color(global.UI_COL_BOX);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    }
}