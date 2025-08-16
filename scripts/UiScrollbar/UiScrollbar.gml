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
    
    // Create the thumb
    self.Thumb = new UiScrollbarThumb({ position: "absolute", left: 0, right: 0, top: 0, height: 0 }, { isScrollbar: true });
    self.add(self.Thumb);
    
    function onMount() {
        self.parent.onWheelUp(function(ev) {
            self.parent.scrollTop = max(0, self.parent.scrollTop - 30);
        });
        
        self.parent.onWheelDown(function(ev) {
            self.parent.scrollTop = min(self.__maxScroll, self.parent.scrollTop + 30);
        });
    }
    
    function onStep() {
        var layoutHeight = self.layout.height;
        
        if (self.updated) {
            // Height calculation
            self.__contentHeight = self.parent.reduceChildren(function(height, child) {
                if (child.isScrollbar) return height;
                return height + child.layout.height;
            }, 0, false);
            
            var _thumbHeight = max(10, min(layoutHeight, layoutHeight * (layoutHeight / __contentHeight)));
            if (_thumbHeight != self.Thumb.getHeight()) {
                self.Thumb.setHeight(_thumbHeight);
            }
            
            self.__maxThumbPosition = layoutHeight - _thumbHeight;
            self.__maxScroll = max(0, __contentHeight - self.parent.layout.height);
        } 
        
        // Dragging
        if (self.dragged) {
            var currentMouseY = self.mouseY;
            var deltaY = currentMouseY - self.dragStartY;
            
            if (self.__maxScroll > 0) {
                if (self.__maxThumbPosition > 0) {
                    // Convert thumb movement to scroll position
                    var scrollDelta = (deltaY / self.__maxThumbPosition) * self.__maxScroll;
                    self.parent.scrollTop = clamp(self.dragStartScrollTop + scrollDelta, 0, self.__maxScroll);
                }
            }
        }
        
        // Compute the thumb max scroll and position
        var thumbPosition = (self.parent.scrollTop / self.__maxScroll) * self.__maxThumbPosition; 
        if (self.Thumb.getTop() != thumbPosition) {
            self.Thumb.setTop(thumbPosition);
        }
    };
}

function UiScrollbarThumb(style = {}, props = {}): UiNode(style, props) constructor {
    self.pointerEvents = true;
    setName(style[$ "name"] ?? "__UiScrollbar.Thumb");
    
    onMouseDown(function(ev) {
        self.parent.dragged = true;
        self.parent.dragStartY = self.parent.mouseY;
        self.parent.dragStartScrollTop = self.parent.parent.scrollTop;
        
        self.setWidth(12);
        self.setLeft(-3);
    });
    
    onMouseUp(function() {
        if (self.parent.dragged) {
            self.parent.dragged = false;
            self.setWidth(6);
            self.setLeft(0);
        }
    });
    
    function onDraw() {
        if (getHeight() == self.parent.layout.height) return;

        draw_set_color(global.UI_COL_BOX);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    }
}