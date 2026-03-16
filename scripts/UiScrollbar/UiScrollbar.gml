function UiScrollbar(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "__UiScrollbar");
    self.pointerEvents = true;
    self.isScrollbar = true;
    self.thumbColor = props[$ "thumbColor"] ?? global.UI_COL_BOX;
    
    // Internal state
    self.dragged = false;
    self.dragStartY = undefined;
    self.dragStartScrollTop = undefined;
    self.__contentHeight = 0;
    self.__viewportHeight = 0;
    self.__maxScroll = 0;
    self.__maxThumbPosition = 0;
    self.__lastChildrenLength = -1;
    self.__thumbAlpha = 0;         // For fade animation
    self.__thumbAlphaTarget = 0;   // Target alpha
    self.__scrollTarget = 0;       // Smooth scroll target
    self.__isSmoothing = false;    // Whether we're mid-smooth-scroll
    
    // Constants
    self.__MIN_THUMB_HEIGHT = 24;
    self.__SCROLL_SPEED = 40;
    self.__SMOOTH_FACTOR = 0.25;   // Lerp factor for smooth scroll (higher = snappier)
    self.__FADE_SPEED = 0.12;      // Alpha lerp speed for thumb fade
    
    // Create the thumb
    self.Thumb = new UiScrollbarThumb({ position: "absolute", left: 0, right: 0, top: 0, height: 0 }, {
        isScrollbar: true, 
        thumbColor: self.thumbColor 
    });
    self.add(self.Thumb);
    
    function onMount() {
        self.parent.onWheelUp(function(ev) {
            if (self.__maxScroll <= 0) return;
            self.__scrollTarget = clamp(self.__scrollTarget - self.__SCROLL_SPEED, 0, self.__maxScroll);
            self.__isSmoothing = true;
            self.__thumbAlphaTarget = 1;
            global.UI.requestRedraw();
        });
        
        self.parent.onWheelDown(function(ev) {
            if (self.__maxScroll <= 0) return;
            self.__scrollTarget = clamp(self.__scrollTarget + self.__SCROLL_SPEED, 0, self.__maxScroll);
            self.__isSmoothing = true;
            self.__thumbAlphaTarget = 1;
            global.UI.requestRedraw();
        });
    }
    
    /// @desc Calculate total content height from parent's children (excluding scrollbar)
    function __calcContentHeight() {
        var _total = 0;
        var _parent = self.parent;
        var _children = _parent.children;
        var _len = _parent.childrenLength;
        
        for (var i = 0; i < _len; i++) {
            var _child = _children[i];
            // Skip the scrollbar itself and hidden children
            if (_child.isScrollbar) continue;
            if (!_child.display) continue;
            _total += _child.layout.height;
        }
        
        return _total;
    }
    
    self.onStep(function(layoutUpdated) {
        var _parent = self.parent;
        if (_parent == undefined) return;
        
        // Viewport = parent's layout height (the visible area)
        var _viewportHeight = _parent.layout.height;
        if (_viewportHeight <= 0) return;
        
        // Detect if we need to recalculate
        var _childrenChanged = (_parent.childrenLength != self.__lastChildrenLength);
        var _shouldRecalc = layoutUpdated || _childrenChanged;
        
        // Also recalc if content height was never computed
        if (!_shouldRecalc && self.__contentHeight <= 0) {
            _shouldRecalc = true;
        }
        
        if (_shouldRecalc) {
            self.__lastChildrenLength = _parent.childrenLength;
            self.__viewportHeight = _viewportHeight;
            
            // Calculate content height
            self.__contentHeight = self.__calcContentHeight();
            
            // Skip if content hasn't resolved yet
            if (self.__contentHeight <= 0 && _viewportHeight > 0) {
                return;
            }
            
            // Calculate max scroll
            self.__maxScroll = max(0, self.__contentHeight - _viewportHeight);
            
            // Clamp scrollTop — critical fix for stale scroll position
            if (_parent.scrollTop > self.__maxScroll) {
                _parent.scrollTop = self.__maxScroll;
                self.__scrollTarget = self.__maxScroll;
                global.UI.requestRedraw();
            }
            
            // Sync scroll target if not smoothing
            if (!self.__isSmoothing) {
                self.__scrollTarget = _parent.scrollTop;
            }
            
            // Calculate thumb size proportional to viewport/content ratio
            if (self.__maxScroll > 0) {
                var _ratio = _viewportHeight / self.__contentHeight;
                var _thumbHeight = max(self.__MIN_THUMB_HEIGHT, floor(_viewportHeight * _ratio));
                // Ensure thumb doesn't exceed viewport
                _thumbHeight = min(_thumbHeight, _viewportHeight);
                
                if (_thumbHeight != self.Thumb.getHeight()) {
                    self.Thumb.setHeight(_thumbHeight);
                }
                
                self.__maxThumbPosition = _viewportHeight - _thumbHeight;
            } else {
                // Content fits — no scrolling needed
                _parent.scrollTop = 0;
                self.__scrollTarget = 0;
                if (self.Thumb.getTop() != 0) self.Thumb.setTop(0);
                self.__thumbAlphaTarget = 0;
            }
        }
        
        // Smooth scrolling interpolation
        if (self.__isSmoothing) {
            var _diff = self.__scrollTarget - _parent.scrollTop;
            if (abs(_diff) < 0.5) {
                // Snap when close enough
                _parent.scrollTop = self.__scrollTarget;
                self.__isSmoothing = false;
            } else {
                _parent.scrollTop = _parent.scrollTop + _diff * self.__SMOOTH_FACTOR;
            }
            global.UI.requestRedraw();
            global.UI.requestUpdate();
        }
        
        // Thumb dragging
        if (self.dragged) {
            var _currentMouseY = global.UI.mouseY;
            var _deltaY = _currentMouseY - self.dragStartY;
            
            if (self.__maxScroll > 0 && self.__maxThumbPosition > 0) {
                var _scrollDelta = (_deltaY / self.__maxThumbPosition) * self.__maxScroll;
                var _newScroll = clamp(self.dragStartScrollTop + _scrollDelta, 0, self.__maxScroll);
                _parent.scrollTop = _newScroll;
                self.__scrollTarget = _newScroll;
                global.UI.requestRedraw();
            }
        }
        
        // Update thumb position based on current scrollTop
        if (self.__maxScroll > 0 && self.__maxThumbPosition > 0) {
            var _thumbPos = floor((_parent.scrollTop / self.__maxScroll) * self.__maxThumbPosition);
            if (self.Thumb.getTop() != _thumbPos) {
                self.Thumb.setTop(_thumbPos);
            }
            // Show thumb when scrollable
            self.__thumbAlphaTarget = (self.dragged || self.Thumb.hovered || self.__isSmoothing) ? 1 : 0.6;
        }
        
        // Thumb alpha fade animation
        if (self.__thumbAlpha != self.__thumbAlphaTarget) {
            var _alphaDiff = self.__thumbAlphaTarget - self.__thumbAlpha;
            if (abs(_alphaDiff) < 0.02) {
                self.__thumbAlpha = self.__thumbAlphaTarget;
            } else {
                self.__thumbAlpha += _alphaDiff * self.__FADE_SPEED;
            }
            global.UI.requestRedraw();
        }
    });

    // Track click-to-scroll: clicking on the scrollbar (not on the thumb) jumps to that position
    self.onMouseDown(function(ev) {
        if (self.__maxScroll <= 0) return false;
        
        // Calculate the target scroll ratio based on click position
        var _clickY = global.UI.mouseY - self.y1;
        var _ratio = clamp(_clickY / self.layout.height, 0, 1);
        
        // Jump scrollTop to match the clicked position
        var _newScroll = _ratio * self.__maxScroll;
        self.parent.scrollTop = _newScroll;
        self.__scrollTarget = _newScroll;
        self.__thumbAlphaTarget = 1;
        global.UI.requestRedraw();
        
        return false; // Don't stop propagation — thumb mousedown can still fire
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
        self.parent.__thumbAlphaTarget = 1;
        global.UI.isScrolling = true;
        
        self.setWidth(17);
        self.setLeft(-3);
        return true; // Stop propagation so track click doesn't also fire
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
        // Don't draw if content fits (no scrolling needed)
        if (self.parent.__maxScroll <= 0) return;
        // Don't draw if thumb fills the entire track
        if (getHeight() >= self.parent.layout.height) return;
        
        var _alpha = self.parent.__thumbAlpha;
        if (_alpha <= 0.01) return;
        
        draw_set_alpha(_alpha);
        draw_set_color(self.thumbColor);
        
        // Draw rounded-ish thumb (main body + rounded caps)
        var _x1 = self.x1 + 2;
        var _x2 = self.x2 - 5;
        var _y1 = self.y1 + 1;
        var _y2 = self.y2 - 1;
        var _radius = min(3, (_x2 - _x1) / 2, (_y2 - _y1) / 2);
        
        // Simple rectangle with slight inset for cleaner look
        draw_rectangle(_x1, _y1 + _radius, _x2, _y2 - _radius, false);
        draw_rectangle(_x1 + _radius, _y1, _x2 - _radius, _y2, false);
        
        // Fill corners
        draw_rectangle(_x1, _y1, _x1 + _radius, _y1 + _radius, false);
        draw_rectangle(_x2 - _radius, _y1, _x2, _y1 + _radius, false);
        draw_rectangle(_x1, _y2 - _radius, _x1 + _radius, _y2, false);
        draw_rectangle(_x2 - _radius, _y2 - _radius, _x2, _y2, false);
        
        draw_set_alpha(1);
    }
}
