function UiScrollbar(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "__UiScrollbar");
    self.dragged = false;
    self.dragStartY = undefined;
    self.dragStartScrollTop = undefined; 
    self.maxScroll = 0;
    self.pointerEvents = true;
    self.__contentHeight = undefined;
    self.__maxThumbPosition = undefined;
    self.__maxScroll = undefined;
    self.thumbColor = props[$ "thumbColor"] ?? global.UI_COL_BOX;
    
    // Create the thumb
    self.Thumb = new UiScrollbarThumb({ position: "absolute", left: 0, right: 0, top: 0, height: 0 }, {
        isScrollbar: true, 
        thumbColor: self.thumbColor 
    });
    self.add(self.Thumb);
    
    function onMount() {
        self.parent.onWheelUp(function(ev) {
            self.parent.scrollTop = max(0, self.parent.scrollTop - 30);
            global.UI.needsRedraw = true;
        });
        
        self.parent.onWheelDown(function(ev) {
            self.parent.scrollTop = min(self.__maxScroll, self.parent.scrollTop + 30);
            global.UI.needsRedraw = true;
        });
    }
    
    self.onStep(function(layoutUpdated) {
        var layoutHeight = self.layout.height;
        
        if (layoutUpdated) {
            // Height calculation
            self.__contentHeight = self.parent.reduceChildren(function(height, child) {
                if (child.isScrollbar) return height;
                return height + child.layout.height;
            }, 0, false);
           
            var _thumbHeight = ~~(max(10, min(layoutHeight, layoutHeight * (layoutHeight / __contentHeight))));
            
            if (_thumbHeight != self.Thumb.getHeight()) {
                self.Thumb.setHeight(_thumbHeight);
            }
        
            self.__maxThumbPosition = layoutHeight - _thumbHeight;
            self.__maxScroll = max(0, __contentHeight - self.parent.layout.height);

            // If content height is smaller than the visible area, reset scrollTop
            if (self.__maxScroll <= 0) {
                self.parent.scrollTop = 0;
                if (self.Thumb.getTop() != 0) self.Thumb.setTop(0);
            }
        } 
        
        // Dragging
        if (self.dragged) {
            var currentMouseY = global.UI.mouseY;
            var deltaY = currentMouseY - self.dragStartY;
            
            if (self.__maxScroll > 0) {
                if (self.__maxThumbPosition > 0) {
                    // Convert thumb movement to scroll position
                    var scrollDelta = (deltaY / self.__maxThumbPosition) * self.__maxScroll;
                    self.parent.scrollTop = clamp(self.dragStartScrollTop + scrollDelta, 0, self.__maxScroll);
                    global.UI.needsRedraw = true;
                }
            }
        }
        
        // Compute the thumb max scroll and position
        if (self.__maxScroll > 0) {
            var thumbPosition = (self.parent.scrollTop / self.__maxScroll) * self.__maxThumbPosition; 
            if (self.Thumb.getTop() != thumbPosition) {
                self.Thumb.setTop(thumbPosition);
            }
        }
    });
}

function UiScrollbarThumb(style = {}, props = {}): UiNode(style, props) constructor {
    self.pointerEvents = true;
    setName(style[$ "name"] ?? "__UiScrollbar.Thumb");
    self.thumbColor = props[$ "thumbColor"];
    
    self.onMouseDown(function(ev) {
        self.parent.dragged = true;
        self.parent.dragStartY = global.UI.mouseY;
        self.parent.dragStartScrollTop = self.parent.parent.scrollTop;
        
        self.setWidth(17);
        self.setLeft(-3);
        return true;
    });
    
    self.onStep(function() {
        if (global.UI.mouseReleased) {
            if (self.parent.dragged) {
                self.parent.dragged = false;
                self.setWidth(11);
                self.setLeft(0);
            }
        }
    });
    
    function onDraw() {
        if (getHeight() == self.parent.layout.height) return;

        draw_set_color(self.thumbColor);
        draw_rectangle(self.x1, self.y1, self.x2 - 5, self.y2, false);
    }
}
