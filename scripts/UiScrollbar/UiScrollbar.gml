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
    self.__lastChildrenLength = -1;
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
            global.UI.requestRedraw();
        });
        
        self.parent.onWheelDown(function(ev) {
            self.parent.scrollTop = min(self.__maxScroll, self.parent.scrollTop + 30);
            global.UI.requestRedraw();
        });
    }
    
    self.onStep(function(layoutUpdated) {
        var layoutHeight = self.layout.height;

        var childrenChanged = (self.parent != undefined && self.parent.childrenLength != self.__lastChildrenLength);
        var shouldRecalc = layoutUpdated || childrenChanged;
        if (!shouldRecalc) {
            // Layout might have been resolved on children after we already handled layoutUpdated.
            // If we still don't have a valid content height, keep trying until it stabilizes.
            shouldRecalc = (layoutHeight > 0 && (self.__contentHeight == undefined || self.__contentHeight <= 0));
        }
        
        if (shouldRecalc) {
            if (self.parent != undefined) {
                self.__lastChildrenLength = self.parent.childrenLength;
            }
            // Height calculation
            self.__contentHeight = self.parent.reduceChildren(function(height, child) {
                if (child.isScrollbar) return height;
                return height + child.layout.height;
            }, 0, false);

            // If the layout hasn't resolved child sizes yet, retry next frame
            if (self.__contentHeight <= 0 && layoutHeight > 0) {
                self.__contentHeight = undefined;
                return;
            }
           
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
                    global.UI.requestRedraw();
                }
            }
        }
        
        // Compute the thumb max scroll and position
        if (self.__maxScroll > 0) {
            var thumbPosition = floor((self.parent.scrollTop / self.__maxScroll) * self.__maxThumbPosition); 
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
        global.UI.isScrolling = true;
        
        self.setWidth(17);
        self.setLeft(-3);
        return true;
    });
    
    self.onStep(function() {
        if (global.UI.mouseReleased) {
            if (self.parent.dragged) {
                self.parent.dragged = false;
                global.UI.isScrolling = false;
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
