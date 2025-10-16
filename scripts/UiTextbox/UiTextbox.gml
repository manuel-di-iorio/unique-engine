#macro TEXTBOX_INITIAL_DELAY 400    /* ms before starting key repeat */
#macro TEXTBOX_REPEAT_DELAY 50      /* ms between each repeat */
#macro TEXTBOX_CURSOR_BLINK 500     /* ms for cursor blinking */
#macro TEXTBOX_UNDO_STACK_SIZE 100  /* undo/redo max items in stack size */

function UiTextbox(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTextbox");
    self.label = props[$ "label"] ?? undefined;
    self.value = props[$ "value"] ?? "";
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(value, input) {};
    self.maxLength = props[$ "maxLength"] ?? 255;
    var marginLeft = self.label == undefined ? 0 : string_width(self.label) + 15;
    self.onBlur = props[$ "onBlur"] ?? function(value, input) {};
    self.format = props[$ "format"] ?? "string"; // string, float, integer
    self.min = props[$ "min"];
    self.max = props[$ "max"];
    self.placeholder = props[$ "placeholder"];
    self.negative = props[$ "negative"] ?? false;
    
    self.Input = new UiNode({ 
        name: "UiTextbox.Input", 
        marginLeft,
        paddingLeft: 5, 
        paddingRight: 5, 
        flex: 1,
        height: "100%" 
    });
    self.add(self.Input);

    with (self.Input) {
        self.pointerEvents = true;
        
        // Text management properties
        self.focused = false;
        self.cursorPos = 0;
        self.selectionStart = 0;
        self.selectionEnd = 0;
        self.scrollOffset = 0;
        self.cursorBlinkTime = 0;
        self.showCursor = true;
        
        // Mouse drag selection management
        self.isDragging = false;
        self.dragStartPos = 0;
        
        // Sistema Undo/Redo
        self.undoStack = [];
        self.redoStack = [];
        self.lastSavedState = "";
        
        // Key repeat handling
        self.keyRepeat = {
            key: -1,
            initialDelay: 0,
            repeatDelay: 0,
            pressed: false
        };
        
        // Double click detection
        self.lastClickTime = -1;
        self.lastClickPos = -1;
        self.doubleClickThreshold = 300;
        
        // Font metrics calculation
        draw_set_font(fText);
        self.charWidth = string_width("W");
        self.textHeight = string_height("W");
        
        // Mouse cursor change on hover
        self.onMouseEnter(function() {
            if (window_get_cursor() == cr_default) {
                window_set_cursor(cr_beam);
            }
        });
        
        self.onMouseLeave(function() {
            window_set_cursor(cr_default);
        });
        
        // Save state for undo functionality
        self.saveUndoState = function() {
            var currentState = {
                text: self.parent.value,
                cursorPos: self.cursorPos,
                selectionStart: self.selectionStart,
                selectionEnd: self.selectionEnd
            };
            
            // Don't save if it's the same as the previous state
            if (array_length(self.undoStack) > 0) {
                var lastState = self.undoStack[array_length(self.undoStack) - 1];
                if (lastState.text == currentState.text && 
                    lastState.cursorPos == currentState.cursorPos &&
                    lastState.selectionStart == currentState.selectionStart &&
                    lastState.selectionEnd == currentState.selectionEnd) {
                    return;
                }
            }
            
            array_push(self.undoStack, currentState);
            
            // Limit stack size
            if (array_length(self.undoStack) > TEXTBOX_UNDO_STACK_SIZE) {
                array_delete(self.undoStack, 0, 1);
            }
            
            // Clear redo stack when making a new action
            self.redoStack = [];
        };
        
        // Perform undo operation
        self.performUndo = function() {
            if (array_length(self.undoStack) > 0) {
                // Save current state to redo stack
                var currentState = {
                    text: self.parent.value,
                    cursorPos: self.cursorPos,
                    selectionStart: self.selectionStart,
                    selectionEnd: self.selectionEnd
                };
                array_push(self.redoStack, currentState);
                
                // Restore previous state
                var state = self.undoStack[array_length(self.undoStack) - 1];
                array_delete(self.undoStack, array_length(self.undoStack) - 1, 1);
                
                self.parent.value = state.text;
                self.cursorPos = state.cursorPos;
                self.selectionStart = state.selectionStart;
                self.selectionEnd = state.selectionEnd;
                
                self.parent.onChange(self.parent.value);
                self.updateScrollOffset();
            }
        };
        
        // Perform redo operation
        self.performRedo = function() {
            if (array_length(self.redoStack) > 0) {
                // Save current state to undo stack
                var currentState = {
                    text: self.parent.value,
                    cursorPos: self.cursorPos,
                    selectionStart: self.selectionStart,
                    selectionEnd: self.selectionEnd
                };
                array_push(self.undoStack, currentState);
                
                // Restore state from redo stack
                var state = self.redoStack[array_length(self.redoStack) - 1];
                array_delete(self.redoStack, array_length(self.redoStack) - 1, 1);
                
                self.parent.value = state.text;
                self.cursorPos = state.cursorPos;
                self.selectionStart = state.selectionStart;
                self.selectionEnd = state.selectionEnd;
                
                self.parent.onChange(self.parent.value, self.parent);
                self.updateScrollOffset();
            }
        };
        
        // Calculate cursor position from mouse coordinates
        self.getMouseCursorPos = function(mouseX) {
            // Usa la stessa formula del disegno per calcolare textX
            var textX = self.x1 + self.layout.paddingLeft - self.scrollOffset;
            
            // Calcola posizione relativa del mouse rispetto al testo
            var relativeX = mouseX - textX;
            var text = self.parent.value;
            var length = string_length(text);
        
            // Se il mouse è a sinistra del testo
            if (relativeX < 0) return 0;
        
            // Calcola posizione carattere per carattere
            draw_set_font(fText); // Assicurati di usare lo stesso font
            var currentX = 0;
            
            for (var i = 0; i < length; i++) {
                var char = string_char_at(text, i + 1);
                var charWidth = string_width(char);
                
                // Se il mouse è nella prima metà del carattere, posiziona prima
                // Se è nella seconda metà, posiziona dopo
                if (relativeX <= currentX + (charWidth / 2)) {
                    return i;
                }
                
                currentX += charWidth;
            }
            
            // Se siamo oltre l'ultimo carattere
            return length;
        };
        
        // Find word boundaries for word selection
        self.findWordStart = function(pos) {
            var text = self.parent.value;
            while (pos > 0 && string_char_at(text, pos) != " ") {
                pos--;
            }
            return pos;
        };
        
        self.findWordEnd = function(pos) {
            var text = self.parent.value;
            var len = string_length(text);
            while (pos < len && string_char_at(text, pos + 1) != " ") {
                pos++;
            }
            return pos;
        };
        
        // Handle mouse down event
        self.onMouseDown(function() {
            self.focus();
            var now = current_time;
            var mouseX = device_mouse_x_to_gui(0);
            var clickPos = self.getMouseCursorPos(mouseX);
            
            // Detect double click
            if (self.lastClickTime != -1 && now - self.lastClickTime <= self.doubleClickThreshold && clickPos == self.lastClickPos) {
                if (clickPos < string_length(self.parent.value) && string_char_at(self.parent.value, clickPos + 1) != " ") {
                    self.selectionStart = self.findWordStart(clickPos);
                    self.selectionEnd = self.findWordEnd(clickPos);
                    self.cursorPos = self.selectionEnd;
                    self.updateScrollOffset(); // Just to place the cursor, not for the drag
                    self.cursorBlinkTime = current_time;
                    self.showCursor = true;
                }
            } else {
                // Single click
                self.cursorPos = clickPos;
                self.isDragging = true;
                self.dragStartPos = self.cursorPos;
                
                if (!keyboard_check(vk_shift)) {
                    self.selectionStart = self.cursorPos;
                    self.selectionEnd = self.cursorPos;
                } else {
                    self.selectionEnd = self.cursorPos;
                }
                
                // For the single click, update using updateScrollOffset 
                self.updateScrollOffset();
                self.cursorBlinkTime = current_time;
                self.showCursor = true;
            }
            
            self.lastClickTime = now;
            self.lastClickPos = clickPos;
        }); 
         
        // Set focus to textbox
        self.focus = function() {
            self.focused = true;
            self.cursorBlinkTime = current_time;
            self.showCursor = true;
            
            // Clear any pending keyboard input to prevent unwanted character insertion
            keyboard_lastchar = "";
        };
        
        // Remove focus from textbox
        self.blur = function() {
            self.focused = false;
            self.keyRepeat.key = -1;
            self.keyRepeat.pressed = false;
            self.isDragging = false;
            
            // Clean up incomplete numeric values on blur
            var format = self.parent.format;
            var value = self.parent.value;
            
            if (format == "integer" || format == "float") {
                // Remove trailing decimal point or minus sign
                if (string_char_at(value, string_length(value)) == "." || 
                    string_char_at(value, string_length(value)) == "-") {
                    value = string_copy(value, 1, string_length(value) - 1);
                }
                
                // If empty, set to 0 or min value if specified
                if (value == "") {
                    if (self.parent.min != undefined) {
                        value = string(self.parent.min);
                    } else {
                        value = "0";
                    }
                }
                
                // Clamp to min/max range
                var numValue = real(value);
                if (self.parent.min != undefined && numValue < self.parent.min) {
                    numValue = self.parent.min;
                }
                if (self.parent.max != undefined && numValue > self.parent.max) {
                    numValue = self.parent.max;
                }
                
                // Format the final value
                if (format == "integer") {
                    value = string(floor(numValue));
                } else {
                    value = string(numValue);
                }
                
                self.parent.value = value;
                self.parent.onChange(self.parent.value, self.parent);
            }
            
            global.UI.needsRedraw = true;
            
            if (self.parent.onBlur != undefined) self.parent.onBlur(self.parent.value, self.parent);
        };
        
        // Update horizontal scroll based on cursor position
        self.updateScrollOffset = function() {
            global.UI.needsRedraw = true;
            var text = self.parent.value;
            var cursorX = 0;
            
            // Calcola posizione X del cursore
            draw_set_font(fText);
            for (var i = 0; i < self.cursorPos; i++) {
                if (i < string_length(text)) {
                    cursorX += string_width(string_char_at(text, i + 1));
                }
            }
            
            var textboxWidth = self.x2 - self.x1 - 10; // Margini più stretti
            var margin = 5;
            
            // Scroll a destra se il cursore esce dalla vista
            if (cursorX - self.scrollOffset > textboxWidth - margin) {
                self.scrollOffset = cursorX - textboxWidth + margin;
            }
            
            // Scroll a sinistra se il cursore esce dalla vista
            if (cursorX - self.scrollOffset < margin) {
                self.scrollOffset = max(0, cursorX - margin);
            }
            
            // Limita scroll minimo
            if (self.scrollOffset < 0) {
                self.scrollOffset = 0;
            }
            
            // Gestione scroll massimo
            var totalTextWidth = string_width(text);
            if (totalTextWidth <= textboxWidth) {
                self.scrollOffset = 0;
            } else {
                var maxScroll = totalTextWidth - textboxWidth + margin;
                if (self.scrollOffset > maxScroll) {
                    self.scrollOffset = max(0, maxScroll);
                }
            }
            
            self.resetCursorBlink();
        };
        
        // Get the currently selected text
        self.getSelectedText = function() {
            var start = min(self.selectionStart, self.selectionEnd);
            var ended = max(self.selectionStart, self.selectionEnd);
            return string_copy(self.parent.value, start + 1, ended - start);
        };
        
        // Delete the selected text
        self.deleteSelected = function() {
            var start = min(self.selectionStart, self.selectionEnd);
            var ended = max(self.selectionStart, self.selectionEnd);
            
            if (start != ended) {
                var text = self.parent.value;
                self.parent.value = string_delete(text, start + 1, ended - start);
                self.parent.onChange(self.parent.value, self.parent);
                self.cursorPos = start;
                self.selectionStart = start;
                self.selectionEnd = start;
                return true;
            }
            return false;
        };
        
        // Insert text at cursor position with maxLength validation
        self.insertText = function(newText) {
            self.saveUndoState(); // Save state before modification
            self.deleteSelected();
            
            var currentText = self.parent.value;
            var format = self.parent.format;
            
            // Filter characters based on format
            var filteredText = "";
            for (var i = 1; i <= string_length(newText); i++) {
                var char = string_char_at(newText, i);
                var testText = string_insert(char, currentText, self.cursorPos + string_length(filteredText) + 1);
                
                if (self.isValidCharacter(char, currentText, self.cursorPos + string_length(filteredText))) {
                    // For numeric formats, also check if the resulting value would be valid
                    if (format == "integer" || format == "float") {
                        if (self.validateValue(testText)) {
                            filteredText += char;
                        }
                    } else {
                        filteredText += char;
                    }
                }
            }
            
            if (filteredText == "") return; // No valid characters to insert
            
            var newValue = string_insert(filteredText, currentText, self.cursorPos + 1);
            
            // Check maxLength constraint
            if (string_length(newValue) > self.parent.maxLength) {
                var availableSpace = self.parent.maxLength - string_length(currentText);
                if (availableSpace > 0) {
                    filteredText = string_copy(filteredText, 1, availableSpace);
                    newValue = string_insert(filteredText, currentText, self.cursorPos + 1);
                } else {
                    return; // Don't insert anything if already at limit
                }
            }
            
            // Final validation for numeric formats
            if (format == "integer" || format == "float") {
                if (!self.validateValue(newValue)) {
                    return; // Don't insert if it would violate min/max constraints
                }
            }
            
            self.parent.value = newValue;
            self.parent.onChange(self.parent.value, self.parent);
            self.cursorPos += string_length(filteredText);
            self.selectionStart = self.cursorPos;
            self.selectionEnd = self.cursorPos;
            
            self.updateScrollOffset();
        };
        
        // Handle keyboard input (only when focused)
        self.handleKeyInput = function() {
            if (!self.focused) return;
            
            var ctrl = keyboard_check(vk_control);
            var shift = keyboard_check(vk_shift);
            var alt = keyboard_check(vk_alt);
            
            // Undo/Redo handling
            if (ctrl && (keyboard_check_pressed(ord("Z")) && !shift || (self.keyRepeat.key == ord("Z") && self.handleKeyRepeat()))) {
                self.performUndo();
                return;
            }
            
            if (ctrl && ((keyboard_check_pressed(ord("Y")) || (keyboard_check_pressed(ord("Z")) && shift)) || (self.keyRepeat.key == ord("Y") && self.handleKeyRepeat()))) {
                self.performRedo();
                return;
            }
            
            // Keyboard shortcuts
            if (ctrl && keyboard_check_pressed(ord("A"))) {
                // Select all
                self.selectionStart = 0;
                self.selectionEnd = string_length(self.parent.value);
                self.cursorPos = self.selectionEnd;
                self.updateScrollOffset();
                return;
            }
            
            if (ctrl && keyboard_check_pressed(ord("C"))) {
                // Copy
                var selectedText = self.getSelectedText();
                if (selectedText != "") {
                    clipboard_set_text(selectedText);
                }
                return;
            }
            
            // Paste with repeat support
            if (ctrl && (keyboard_check_pressed(ord("V")) || (self.keyRepeat.key == ord("V") && self.handleKeyRepeat()))) {
                var clipboardText = clipboard_get_text();
                if (clipboardText != "") {
                    // Remove line breaks as this is a single-line textbox
                    clipboardText = string_replace_all(clipboardText, "\n", "");
                    clipboardText = string_replace_all(clipboardText, "\r", "");
                    self.insertText(clipboardText);
                }
                return;
            }
            
            if (ctrl && keyboard_check_pressed(ord("X"))) {
                // Cut
                var selectedText = self.getSelectedText();
                if (selectedText != "") {
                    self.saveUndoState();
                    clipboard_set_text(selectedText);
                    self.deleteSelected();
                    self.updateScrollOffset();
                }
                return;
            }
            
            // Cursor movement
            if (keyboard_check_pressed(vk_left) || (self.keyRepeat.key == vk_left && self.handleKeyRepeat())) {
                if (ctrl) {
                    // Move by word
                    self.cursorPos = self.findWordStart(self.cursorPos, -1);
                } else {
                    // Move by character
                    self.cursorPos = max(0, self.cursorPos - 1);
                }
                
                if (!shift) {
                    // Reset selection
                    self.selectionStart = self.cursorPos;
                    self.selectionEnd = self.cursorPos;
                } else {
                    // Extend selection
                    self.selectionEnd = self.cursorPos;
                }
                
                self.updateScrollOffset();
            }
            
            if (keyboard_check_pressed(vk_right) || (self.keyRepeat.key == vk_right && self.handleKeyRepeat())) {
                if (ctrl) {
                    // Move by word
                    self.cursorPos = self.findWordEnd(self.cursorPos, 1);
                } else {
                    // Move by character
                    self.cursorPos = min(string_length(self.parent.value), self.cursorPos + 1);
                }
                
                if (!shift) {
                    // Reset selection
                    self.selectionStart = self.cursorPos;
                    self.selectionEnd = self.cursorPos;
                } else {
                    // Extend selection
                    self.selectionEnd = self.cursorPos;
                }
                
                self.updateScrollOffset();
            }
            
            if (keyboard_check_pressed(vk_home)) {
                // Move to beginning
                self.cursorPos = 0;
                if (!shift) {
                    self.selectionStart = 0;
                    self.selectionEnd = 0;
                } else {
                    self.selectionEnd = 0;
                }
                self.updateScrollOffset();
            }
            
            if (keyboard_check_pressed(vk_end)) {
                // Move to end
                self.cursorPos = string_length(self.parent.value);
                if (!shift) {
                    self.selectionStart = self.cursorPos;
                    self.selectionEnd = self.cursorPos;
                } else {
                    self.selectionEnd = self.cursorPos;
                }
                self.updateScrollOffset();
            }
            
            // Text deletion
            if (keyboard_check_pressed(vk_backspace) || (self.keyRepeat.key == vk_backspace && self.handleKeyRepeat())) {
                if (self.selectionStart != self.selectionEnd || self.cursorPos > 0) {
                    self.saveUndoState();
                    
                    if (!self.deleteSelected() && self.cursorPos > 0) {
                        if (ctrl) {
                            // Delete word
                            var newPos = self.findWordBoundary(self.cursorPos, -1);
                            self.parent.value = string_delete(self.parent.value, newPos + 1, self.cursorPos - newPos);
                            self.parent.onChange(self.parent.value, self.parent);
                            self.cursorPos = newPos;
                        } else {
                            // Delete character
                            self.parent.value = string_delete(self.parent.value, self.cursorPos, 1);
                            self.parent.onChange(self.parent.value, self.parent);
                            self.cursorPos--;
                        }
                        self.selectionStart = self.cursorPos;
                        self.selectionEnd = self.cursorPos;
                    }
                    
                    self.updateScrollOffset();
                }
            }
            
            if (keyboard_check_pressed(vk_delete) || (self.keyRepeat.key == vk_delete && self.handleKeyRepeat())) {
                if (self.selectionStart != self.selectionEnd || self.cursorPos < string_length(self.parent.value)) {
                    self.saveUndoState();
                    
                    if (!self.deleteSelected() && self.cursorPos < string_length(self.parent.value)) {
                        if (ctrl) {
                            // Delete word
                            var newPos = self.findWordBoundary(self.cursorPos, 1);
                            self.parent.value = string_delete(self.parent.value, self.cursorPos + 1, newPos - self.cursorPos);
                            self.parent.onChange(self.parent.value, self.parent);
                        } else {
                            // Delete character
                            self.parent.value = string_delete(self.parent.value, self.cursorPos + 1, 1);
                            self.parent.onChange(self.parent.value, self.parent);
                        }
                    }
                    
                    self.updateScrollOffset();
                }
            }
            
            // Character input
            var inputChar = keyboard_lastchar;
            if (inputChar != "" && ord(inputChar) >= 32 && ord(inputChar) <= 126) {
                self.insertText(inputChar);
                keyboard_lastchar = "";
            }
        };
        
        // Handle mouse drag selection (only when focused and dragging)
        self.handleMouseDrag = function() {
            if (!self.focused || !self.isDragging || !mouse_check_button(mb_left)) return;
            
            var mouseX = device_mouse_x_to_gui(0);
            
            var scrollMargin = 10;
            var scrollSpeed = 8;
            
            // Auto-scroll only if the mouse if out of bounds
            var shouldScrollLeft = mouseX < (self.x1 - scrollMargin);
            var shouldScrollRight = mouseX > (self.x2 + scrollMargin);
            
            if (shouldScrollLeft) {
                self.scrollOffset = max(0, self.scrollOffset - scrollSpeed);
            } else if (shouldScrollRight) {
                var text = self.parent.value;
                var totalWidth = string_width(text);
                var textboxWidth = self.x2 - self.x1 - 10; // Margine interno ridotto
                var maxScroll = max(0, totalWidth - textboxWidth + 20);
                self.scrollOffset = min(maxScroll, self.scrollOffset + scrollSpeed);
            }
            
            // Calculate the new position of the cursor after the scroll
            var newCursorPos = self.getMouseCursorPos(mouseX);
            self.cursorPos = newCursorPos;
            
            // Update the selection
            self.selectionStart = self.dragStartPos;
            self.selectionEnd = self.cursorPos;
            
            global.UI.needsRedraw = true;
        };
        
        // Handle key repeat timing
        self.handleKeyRepeat = function() {
            var currentTime = current_time;
            
            if (self.keyRepeat.pressed) {
                if (currentTime >= self.keyRepeat.repeatDelay) {
                    self.keyRepeat.repeatDelay = currentTime + TEXTBOX_REPEAT_DELAY;
                    return true;
                }
            } else if (currentTime >= self.keyRepeat.initialDelay) {
                self.keyRepeat.pressed = true;
                self.keyRepeat.repeatDelay = currentTime + TEXTBOX_REPEAT_DELAY;
                return true;
            }
            
            return false;
        };
        
        // Update key repeat state (only when focused)
        self.updateKeyRepeat = function() {
            if (!self.focused) return;
            
            var currentKey = -1;
            var ctrl = keyboard_check(vk_control);
            var shift = keyboard_check(vk_shift);
            
            // Check which repeatable key is currently pressed
            if (keyboard_check(vk_left)) currentKey = vk_left;
            else if (keyboard_check(vk_right)) currentKey = vk_right;
            else if (keyboard_check(vk_backspace)) currentKey = vk_backspace;
            else if (keyboard_check(vk_delete)) currentKey = vk_delete;
            else if (ctrl && keyboard_check(ord("Z")) && !shift) currentKey = ord("Z"); // Undo
            else if (ctrl && (keyboard_check(ord("Y")) || (keyboard_check(ord("Z")) && shift))) currentKey = ord("Y"); // Redo
            else if (ctrl && keyboard_check(ord("V"))) currentKey = ord("V"); // Paste with repeat
            
            if (currentKey != self.keyRepeat.key) {
                self.keyRepeat.key = currentKey;
                self.keyRepeat.pressed = false;
                if (currentKey != -1) {
                    self.keyRepeat.initialDelay = current_time + TEXTBOX_INITIAL_DELAY;
                }
            }
        };
        
        // Main update loop
        self.onStep(function() {
            // Handle mouse up event
            if (global.UI.mouseLeftReleased) {
                self.isDragging = false;
            }
            
            // Only process input events when focused
            if (self.focused) {
                // Handle cursor blinking
                if (current_time - self.cursorBlinkTime > TEXTBOX_CURSOR_BLINK) {
                    self.showCursor = !self.showCursor;
                    self.cursorBlinkTime = current_time;
                    global.UI.needsRedraw = true;
                }
                
                self.updateKeyRepeat();
                self.handleKeyInput();
                self.handleMouseDrag();
                
                // Lose focus if clicking elsewhere
                if (mouse_check_button_pressed(mb_left) && !self.hovered) {
                    self.blur();
                }
            }
        });
    
        // Draw the textbox
        self.onDraw = function() {
            // Background
            draw_set_color(global.UI_COL_INPUT_BG);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            
            // Border
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
            
            // Set clipping region to prevent text overflow
            var _scissor = gpu_get_scissor();

            var _scrollableParent = self.scrollableParent;
            if (_scrollableParent == undefined) { 
                gpu_set_scissor(self.x1, self.y1, self.x2 - self.x1, self.y2 - self.y1);
            } else {
                gpu_set_scissor(self.x1, max(_scrollableParent.y1, self.y1), self.x2 - self.x1, min(_scrollableParent.y2 - _scrollableParent.y1, self.y2 - self.y1));
            }
            
            // Text drawing settings
            draw_set_color(c_white);
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            
            var text = self.parent.value;
            var textX = self.x1 + self.layout.paddingLeft - self.scrollOffset;
            var textY = floor(mean(self.y1, self.y2));
            
            // Draw selection highlight (only when focused)
            if (self.focused && self.selectionStart != self.selectionEnd) {
                var start = min(self.selectionStart, self.selectionEnd);
                var ended = max(self.selectionStart, self.selectionEnd);
                
                var startX = textX;
                var endX = textX;
                
                // Calculate X positions for selection start and end
                for (var i = 0; i < start; i++) {
                    if (i < string_length(text)) {
                        startX += string_width(string_char_at(text, i + 1));
                    }
                }
                
                for (var i = 0; i < ended; i++) {
                    if (i < string_length(text)) {
                        endX += string_width(string_char_at(text, i + 1));
                    }
                }
                
                // Draw selection rectangle
                draw_set_color(global.UI_COL_SELECTION);
                draw_set_alpha(0.3);
                draw_rectangle(startX, self.y1 + 2, endX, self.y2 - 2, false);
                draw_set_alpha(1);
            }
            
            // Draw text (always visible)
            draw_set_color(c_white); draw_set_font(fText);
            
            if (text == "" && !self.focused && self.parent.placeholder != undefined) {
                // Draw placeholder text
                draw_set_alpha(0.5); // Make placeholder semi-transparent
                draw_text(textX, textY, self.parent.placeholder);
                draw_set_alpha(1);
            } else {
                // Draw actual text
                draw_text(textX, textY, text);
            }
            
            // Draw cursor (only when focused and no selection)
            if (self.focused && self.showCursor && self.selectionStart == self.selectionEnd) {
                var cursorX = textX;
                
                // Calculate cursor X position
                for (var i = 0; i < self.cursorPos; i++) {
                    if (i < string_length(text)) {
                        cursorX += string_width(string_char_at(text, i + 1));
                    }
                }
                
                draw_set_color(c_white);
                draw_line(cursorX, self.y1 + 5, cursorX, self.y2 - 5);
            }
            
            // Restore clipping region
            gpu_set_scissor(_scissor);
        };
        
        self.resetCursorBlink = function() {
            self.cursorBlinkTime = current_time;
            self.showCursor = true; 
        };
        
        // Validate character based on format
        self.isValidCharacter = function(char, currentText, cursorPos) {
            var format = self.parent.format;
            var charCode = ord(char);
            
            switch (format) {
                case "integer":
                    // Allow digits and minus sign only at the beginning
                    if (charCode >= ord("0") && charCode <= ord("9")) {
                        return true;
                    }
                    if (char == "-" && self.parent.negative && cursorPos == 0 && string_pos("-", currentText) == 0) {
                        return true;
                    }
                    return false;
                    
                case "float":
                    // Allow digits, decimal point (only one), and minus sign at the beginning
                    if (charCode >= ord("0") && charCode <= ord("9")) {
                        return true;
                    }
                    if (char == "." && string_count(".", currentText) == 0) {
                        return true;
                    }
                    if (char == "-" && self.parent.negative && cursorPos == 0 && string_pos("-", currentText) == 0) {
                        return true;
                    }
                    return false;
                    
                case "string":
                default:
                    return true; // Allow all characters for string format
            }
        };
        
        // Validate the complete value against min/max constraints
        self.validateValue = function(value) {
            var format = self.parent.format;
            var _min = self.parent.min;
            var _max = self.parent.max;
            
            switch (format) {
                case "integer":
                    if (value == "" || (value == "-" && self.parent.negative)) return true; // Allow empty or just minus during typing
                    //var intValue = real(value);
                    //if (_min != undefined && intValue < _min) return false;
                    //if (_max != undefined && intValue > _max) return false;
                    return true;
                    
                case "float":
                    if (value == "" || (value == "-" && self.parent.negative) || value == ".") return true; // Allow partial values during typing
                    //var floatValue = real(value);
                    //if (_min != undefined && floatValue < _min) return false;
                    //if (_max != undefined && floatValue > _max) return false;
                    return true;
                    
                case "string":
                default:
                    return true;
            }
        };
    }
    
    // Update value from external source
    self.onStep(function() {
        if (self.valueGetter != undefined) self.value = self.valueGetter();
    });
    
    // Draw label if present
    function onDraw() {
        if (self.label != undefined) {
            draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_text(self.x1 + 3, ~~mean(self.y1, self.y2), self.label);
        }
    }
}
