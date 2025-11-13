/// @description UI Focus Manager - Centralized focus management for all UI widgets
/// This manages which UI element currently has focus and handles focus transitions

function UiFocusManager() constructor {
    self.focusedElement = undefined;
    self.focusableElements = [];
    
    /**
     * Register a focusable element
     * @param {Struct} element - The UI element that can receive focus
     */
    function register(element) {
        if (array_find_index(self.focusableElements, method({ element }, function(item) {
            return item == element;
        })) == -1) {
            array_push(self.focusableElements, element);
        }
    }
    
    /**
     * Unregister a focusable element
     * @param {Struct} element - The UI element to unregister
     */
    function unregister(element) {
        var index = array_find_index(self.focusableElements, method({ element }, function(item) {
            return item == element;
        }));
        
        if (index != -1) {
            array_delete(self.focusableElements, index, 1);
        }
        
        // Clear focus if this element had it
        if (self.focusedElement == element) {
            self.focusedElement = undefined;
        }
    }
    
    /**
     * Set focus to a specific element
     * @param {Struct} element - The element to focus
     */
    function setFocus(element) {
        // Blur the currently focused element
        if (self.focusedElement != undefined && self.focusedElement != element) {
            self.blur();
        }
        
        self.focusedElement = element;
        
        // Call the element's onFocus callback if it exists
        if (element[$ "onFocus"] != undefined) {
            element.onFocus();
        }
        
        // Mark for redraw
        global.UI.needsRedraw = true;
    }
    
    /**
     * Remove focus from the currently focused element
     */
    function blur() {
        if (self.focusedElement != undefined) {
            // Call the element's onBlur callback if it exists
            if (self.focusedElement[$ "onBlur"] != undefined) {
                self.focusedElement.onBlur();
            }
            
            self.focusedElement = undefined;
            global.UI.needsRedraw = true;
        }
    }
    
    /**
     * Check if a specific element has focus
     * @param {Struct} element - The element to check
     * @return {Bool} True if the element has focus
     */
    function hasFocus(element) {
        return self.focusedElement == element;
    }
    
    /**
     * Get the currently focused element
     * @return {Struct|undefined} The focused element or undefined
     */
    function getFocused() {
        return self.focusedElement;
    }
    
    /**
     * Check if any element currently has focus
     * @return {Bool} True if any element has focus
     */
    function hasAnyFocus() {
        return self.focusedElement != undefined;
    }
    
    /**
     * Navigate to the next focusable element (Tab)
     */
    function focusNext() {
        if (array_length(self.focusableElements) == 0) return;
        
        var currentIndex = -1;
        if (self.focusedElement != undefined) {
            currentIndex = array_find_index(self.focusableElements, method({ el: self.focusedElement }, function(item) {
                return item == el;
            }));
        }
        
        var nextIndex = (currentIndex + 1) % array_length(self.focusableElements);
        var nextElement = self.focusableElements[nextIndex];
        
        // Skip invisible or disabled elements
        var attempts = 0;
        while ((nextElement[$ "visible"] == false || nextElement[$ "disabled"] == true) && 
               attempts < array_length(self.focusableElements)) {
            nextIndex = (nextIndex + 1) % array_length(self.focusableElements);
            nextElement = self.focusableElements[nextIndex];
            attempts++;
        }
        
        if (nextElement[$ "visible"] != false && nextElement[$ "disabled"] != true) {
            self.setFocus(nextElement);
        }
    }
    
    /**
     * Navigate to the previous focusable element (Shift+Tab)
     */
    function focusPrevious() {
        if (array_length(self.focusableElements) == 0) return;
        
        var currentIndex = -1;
        if (self.focusedElement != undefined) {
            currentIndex = array_find_index(self.focusableElements, method({ el: self.focusedElement }, function(item) {
                return item == el;
            }));
        }
        
        var prevIndex = currentIndex - 1;
        if (prevIndex < 0) prevIndex = array_length(self.focusableElements) - 1;
        
        var prevElement = self.focusableElements[prevIndex];
        
        // Skip invisible or disabled elements
        var attempts = 0;
        while ((prevElement[$ "visible"] == false || prevElement[$ "disabled"] == true) && 
               attempts < array_length(self.focusableElements)) {
            prevIndex--;
            if (prevIndex < 0) prevIndex = array_length(self.focusableElements) - 1;
            prevElement = self.focusableElements[prevIndex];
            attempts++;
        }
        
        if (prevElement[$ "visible"] != false && prevElement[$ "disabled"] != true) {
            self.setFocus(prevElement);
        }
    }
    
    /**
     * Clear all registered elements (useful for cleanup)
     */
    function clear() {
        self.blur();
        self.focusableElements = [];
    }
}

// Global focus manager instance
global.UiFocusManager = new UiFocusManager();
