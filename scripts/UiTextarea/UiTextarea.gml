#macro TEXTAREA_INITIAL_DELAY 400
#macro TEXTAREA_REPEAT_DELAY 50
#macro TEXTAREA_CURSOR_BLINK 500
#macro TEXTAREA_UNDO_STACK_SIZE 100

function UiTextarea(style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTextarea");
    self.label = props[$ "label"] ?? undefined;
    self.value = props[$ "value"] ?? "";
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(value, input) {};
    self.onBlur = props[$ "onBlur"] ?? function(value, input) {};
    self.maxLength = props[$ "maxLength"] ?? 4000;
    self.placeholder = props[$ "placeholder"];
    self.lineHeight = props[$ "lineHeight"] ?? 22;
    
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.column);
    
    if (self.label != undefined) {
        self.LabelNode = new UiText(self.label, { marginBottom: 8 }, { color: global.UI_COL_TEXT_MAIN });
        self.add(self.LabelNode);
    }
    
    self.Input = new UiNode({
        name: "UiTextarea.Input",
        flexGrow: 1,
        width: "100%",
        paddingHorizontal: 12,
        paddingTop: 10,
        paddingBottom: 10
    }, { pointerEvents: true, focusable: true, border: true });
    self.add(self.Input);
    
    self.pointerEvents = true;
    self.onMouseDown(function() {
        self.Input.focus();
    });
    
    with (self.Input) {
        self.pointerEvents = true;
        self.focused = false;
        self.cursorPos = 0;
        self.selectionStart = 0;
        self.selectionEnd = 0;
        self.scrollTop = 0;
        self.scrollLeft = 0;
        self.cursorBlinkTime = 0;
        self.showCursor = true;
        self.isDragging = false;
        self.dragStartPos = 0;
        self.preferredCursorX = 0;
        self.undoStack = [];
        self.redoStack = [];
        self.keyRepeat = {
            key: -1,
            initialDelay: 0,
            repeatDelay: 0,
            pressed: false
        };
        self.lastClickTime = -1;
        self.lastClickPos = -1;
        self.doubleClickThreshold = 300;
        
        self.onMouseEnter(function() {
            if (global.UI.currentCursor == cr_default) global.UI.setCursor(cr_beam);
        });
        
        self.onMouseLeave(function() {
            global.UI.setCursor(cr_default);
        });
        
        self.getInnerWidth = function() {
            return max(1, (self.x2 - self.x1) - self.layout.paddingLeft - self.layout.paddingRight);
        };
        
        self.getInnerHeight = function() {
            return max(1, (self.y2 - self.y1) - self.layout.paddingTop - self.layout.paddingBottom);
        };
        
        self.getLines = function() {
            var text = self.parent.value;
            var len = string_length(text);
            var lines = [];
            var lineStart = 0;
            
            for (var i = 1; i <= len; i++) {
                if (string_char_at(text, i) == "\n") {
                    var lineLength = (i - 1) - lineStart;
                    array_push(lines, {
                        start: lineStart,
                        length: lineLength,
                        text: string_copy(text, lineStart + 1, lineLength)
                    });
                    lineStart = i;
                }
            }
            
            array_push(lines, {
                start: lineStart,
                length: len - lineStart,
                text: string_copy(text, lineStart + 1, len - lineStart)
            });
            
            return lines;
        };
        
        self.getLineIndexFromPos = function(pos) {
            var lines = self.getLines();
            for (var i = 0; i < array_length(lines); i++) {
                var line = lines[i];
                if (pos <= line.start + line.length) return i;
            }
            return max(0, array_length(lines) - 1);
        };
        
        self.getCursorInfo = function(pos) {
            var lines = self.getLines();
            var lineIndex = self.getLineIndexFromPos(pos);
            var line = lines[lineIndex];
            var col = clamp(pos - line.start, 0, line.length);
            var before = string_copy(line.text, 1, col);
            draw_set_font(fText);
            return {
                line: lineIndex,
                col: col,
                x: string_width(before),
                y: lineIndex * self.parent.lineHeight
            };
        };
        
        self.getPosAtLineX = function(lineIndex, x) {
            var lines = self.getLines();
            lineIndex = clamp(lineIndex, 0, array_length(lines) - 1);
            var line = lines[lineIndex];
            var relativeX = max(0, x);
            
            draw_set_font(fText);
            if (relativeX >= string_width(line.text)) return line.start + line.length;
            
            var currentX = 0;
            for (var i = 0; i < line.length; i++) {
                var charEnd = string_width(string_copy(line.text, 1, i + 1));
                var charWidth = charEnd - currentX;
                if (relativeX <= currentX + (charWidth / 2)) return line.start + i;
                currentX = charEnd;
            }
            
            return line.start + line.length;
        };
        
        self.getMouseCursorPos = function(mouseX, mouseY) {
            var textX = self.x1 + self.layout.paddingLeft - self.scrollLeft;
            var textY = self.y1 + self.layout.paddingTop - self.scrollTop;
            var lines = self.getLines();
            var lineIndex = clamp(floor((mouseY - textY) / self.parent.lineHeight), 0, array_length(lines) - 1);
            return self.getPosAtLineX(lineIndex, mouseX - textX);
        };
        
        self.getMaxScrollTop = function() {
            var lines = self.getLines();
            var contentHeight = array_length(lines) * self.parent.lineHeight;
            return max(0, contentHeight - self.getInnerHeight());
        };
        
        self.getMaxScrollLeft = function() {
            var lines = self.getLines();
            var maxWidth = 0;
            draw_set_font(fText);
            for (var i = 0; i < array_length(lines); i++) {
                maxWidth = max(maxWidth, string_width(lines[i].text));
            }
            return max(0, maxWidth - self.getInnerWidth() + 8);
        };
        
        self.clampScroll = function() {
            self.scrollTop = clamp(self.scrollTop, 0, self.getMaxScrollTop());
            self.scrollLeft = clamp(self.scrollLeft, 0, self.getMaxScrollLeft());
        };
        
        self.updateScrollOffset = function() {
            global.UI.requestRedraw();
            var cursor = self.getCursorInfo(self.cursorPos);
            var margin = 4;
            var innerW = self.getInnerWidth();
            var innerH = self.getInnerHeight();
            var lineHeight = self.parent.lineHeight;
            
            if (cursor.x - self.scrollLeft > innerW - margin) {
                self.scrollLeft = cursor.x - innerW + margin;
            }
            if (cursor.x - self.scrollLeft < margin) {
                self.scrollLeft = max(0, cursor.x - margin);
            }
            if (cursor.y - self.scrollTop > innerH - lineHeight) {
                self.scrollTop = cursor.y - innerH + lineHeight;
            }
            if (cursor.y - self.scrollTop < 0) {
                self.scrollTop = cursor.y;
            }
            
            self.clampScroll();
            self.preferredCursorX = cursor.x;
            self.resetCursorBlink();
        };
        
        self.moveCursorTo = function(pos, shift) {
            self.cursorPos = clamp(pos, 0, string_length(self.parent.value));
            if (!shift) {
                self.selectionStart = self.cursorPos;
                self.selectionEnd = self.cursorPos;
            } else {
                self.selectionEnd = self.cursorPos;
            }
            self.updateScrollOffset();
        };
        
        self.moveVertical = function(direction, shift) {
            var cursor = self.getCursorInfo(self.cursorPos);
            var targetLine = cursor.line + direction;
            var lines = self.getLines();
            targetLine = clamp(targetLine, 0, array_length(lines) - 1);
            var targetCursorX = self.preferredCursorX;
            targetCursorX ??= cursor.x;
            self.cursorPos = self.getPosAtLineX(targetLine, targetCursorX);
            if (!shift) {
                self.selectionStart = self.cursorPos;
                self.selectionEnd = self.cursorPos;
            } else {
                self.selectionEnd = self.cursorPos;
            }
            self.updateScrollOffset();
            self.preferredCursorX = targetCursorX;
        };
        
        self.getLineStart = function(pos) {
            var lines = self.getLines();
            var line = lines[self.getLineIndexFromPos(pos)];
            return line.start;
        };
        
        self.getLineEnd = function(pos) {
            var lines = self.getLines();
            var line = lines[self.getLineIndexFromPos(pos)];
            return line.start + line.length;
        };
        
        self.isWordSeparator = function(char) {
            return char == " " || char == "\n" || char == "\t" || char == "." || char == "," || char == ";" || char == ":";
        };
        
        self.findWordStart = function(pos) {
            var text = self.parent.value;
            while (pos > 0 && self.isWordSeparator(string_char_at(text, pos))) pos--;
            while (pos > 0 && !self.isWordSeparator(string_char_at(text, pos))) pos--;
            return pos;
        };
        
        self.findWordEnd = function(pos) {
            var text = self.parent.value;
            var len = string_length(text);
            while (pos < len && self.isWordSeparator(string_char_at(text, pos + 1))) pos++;
            while (pos < len && !self.isWordSeparator(string_char_at(text, pos + 1))) pos++;
            return pos;
        };
        
        self.getSelectedText = function() {
            var start = min(self.selectionStart, self.selectionEnd);
            var ended = max(self.selectionStart, self.selectionEnd);
            return string_copy(self.parent.value, start + 1, ended - start);
        };
        
        self.deleteSelected = function() {
            var start = min(self.selectionStart, self.selectionEnd);
            var ended = max(self.selectionStart, self.selectionEnd);
            if (start == ended) return false;
            
            self.parent.value = string_delete(self.parent.value, start + 1, ended - start);
            self.parent.onChange(self.parent.value, self.parent);
            self.cursorPos = start;
            self.selectionStart = start;
            self.selectionEnd = start;
            return true;
        };
        
        self.saveUndoState = function() {
            var currentState = {
                text: self.parent.value,
                cursorPos: self.cursorPos,
                selectionStart: self.selectionStart,
                selectionEnd: self.selectionEnd
            };
            
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
            if (array_length(self.undoStack) > TEXTAREA_UNDO_STACK_SIZE) array_delete(self.undoStack, 0, 1);
            self.redoStack = [];
        };
        
        self.performUndo = function() {
            if (array_length(self.undoStack) <= 0) return;
            array_push(self.redoStack, {
                text: self.parent.value,
                cursorPos: self.cursorPos,
                selectionStart: self.selectionStart,
                selectionEnd: self.selectionEnd
            });
            
            var state = self.undoStack[array_length(self.undoStack) - 1];
            array_delete(self.undoStack, array_length(self.undoStack) - 1, 1);
            self.parent.value = state.text;
            self.cursorPos = state.cursorPos;
            self.selectionStart = state.selectionStart;
            self.selectionEnd = state.selectionEnd;
            self.parent.onChange(self.parent.value, self.parent);
            self.updateScrollOffset();
        };
        
        self.performRedo = function() {
            if (array_length(self.redoStack) <= 0) return;
            array_push(self.undoStack, {
                text: self.parent.value,
                cursorPos: self.cursorPos,
                selectionStart: self.selectionStart,
                selectionEnd: self.selectionEnd
            });
            
            var state = self.redoStack[array_length(self.redoStack) - 1];
            array_delete(self.redoStack, array_length(self.redoStack) - 1, 1);
            self.parent.value = state.text;
            self.cursorPos = state.cursorPos;
            self.selectionStart = state.selectionStart;
            self.selectionEnd = state.selectionEnd;
            self.parent.onChange(self.parent.value, self.parent);
            self.updateScrollOffset();
        };
        
        self.insertText = function(newText) {
            newText = string_replace_all(newText, "\r\n", "\n");
            newText = string_replace_all(newText, "\r", "\n");
            if (newText == "") return;
            
            self.saveUndoState();
            self.deleteSelected();
            
            var currentText = self.parent.value;
            var availableSpace = self.parent.maxLength - string_length(currentText);
            if (availableSpace <= 0) return;
            if (string_length(newText) > availableSpace) newText = string_copy(newText, 1, availableSpace);
            
            self.parent.value = string_insert(newText, currentText, self.cursorPos + 1);
            self.cursorPos += string_length(newText);
            self.selectionStart = self.cursorPos;
            self.selectionEnd = self.cursorPos;
            self.parent.onChange(self.parent.value, self.parent);
            self.redoStack = [];
            self.updateScrollOffset();
        };
        
        self.onMouseDown(function() {
            self.focus();
            var now = current_time;
            var mouseX = device_mouse_x_to_gui(0);
            var mouseY = device_mouse_y_to_gui(0);
            var clickPos = self.getMouseCursorPos(mouseX, mouseY);
            
            if (self.lastClickTime != -1 && now - self.lastClickTime <= self.doubleClickThreshold && clickPos == self.lastClickPos) {
                self.selectionStart = self.findWordStart(clickPos);
                self.selectionEnd = self.findWordEnd(clickPos);
                self.cursorPos = self.selectionEnd;
            } else {
                self.cursorPos = clickPos;
                self.isDragging = true;
                self.dragStartPos = self.cursorPos;
                if (!keyboard_check(vk_shift)) {
                    self.selectionStart = self.cursorPos;
                    self.selectionEnd = self.cursorPos;
                } else {
                    self.selectionEnd = self.cursorPos;
                }
            }
            
            self.lastClickTime = now;
            self.lastClickPos = clickPos;
            self.updateScrollOffset();
        });
        
        self.handleMouseDrag = function() {
            if (!self.focused || !self.isDragging || !mouse_check_button(mb_left)) return;
            
            var mouseX = device_mouse_x_to_gui(0);
            var mouseY = device_mouse_y_to_gui(0);
            var scrollMargin = 12;
            var scrollSpeed = 10;
            
            if (mouseY < self.y1 + scrollMargin) self.scrollTop -= scrollSpeed;
            if (mouseY > self.y2 - scrollMargin) self.scrollTop += scrollSpeed;
            if (mouseX < self.x1 + scrollMargin) self.scrollLeft -= scrollSpeed;
            if (mouseX > self.x2 - scrollMargin) self.scrollLeft += scrollSpeed;
            self.clampScroll();
            
            self.cursorPos = self.getMouseCursorPos(mouseX, mouseY);
            self.selectionStart = self.dragStartPos;
            self.selectionEnd = self.cursorPos;
            global.UI.requestRedraw();
        };
        
        self.handleKeyRepeat = function() {
            var currentTime = current_time;
            if (self.keyRepeat.pressed) {
                if (currentTime >= self.keyRepeat.repeatDelay) {
                    self.keyRepeat.repeatDelay = currentTime + TEXTAREA_REPEAT_DELAY;
                    return true;
                }
            } else if (currentTime >= self.keyRepeat.initialDelay) {
                self.keyRepeat.pressed = true;
                self.keyRepeat.repeatDelay = currentTime + TEXTAREA_REPEAT_DELAY;
                return true;
            }
            return false;
        };
        
        self.updateKeyRepeat = function() {
            if (!self.focused) return;
            var currentKey = -1;
            var ctrl = keyboard_check(vk_control);
            var shift = keyboard_check(vk_shift);
            
            if (keyboard_check(vk_left)) currentKey = vk_left;
            else if (keyboard_check(vk_right)) currentKey = vk_right;
            else if (keyboard_check(vk_up)) currentKey = vk_up;
            else if (keyboard_check(vk_down)) currentKey = vk_down;
            else if (keyboard_check(vk_backspace)) currentKey = vk_backspace;
            else if (keyboard_check(vk_delete)) currentKey = vk_delete;
            else if (ctrl && keyboard_check(ord("Z")) && !shift) currentKey = ord("Z");
            else if (ctrl && (keyboard_check(ord("Y")) || (keyboard_check(ord("Z")) && shift))) currentKey = ord("Y");
            else if (ctrl && keyboard_check(ord("V"))) currentKey = ord("V");
            else if (keyboard_key >= 32) currentKey = keyboard_key;
            
            if (currentKey != self.keyRepeat.key) {
                self.keyRepeat.key = currentKey;
                self.keyRepeat.pressed = false;
                if (currentKey != -1) self.keyRepeat.initialDelay = current_time + TEXTAREA_INITIAL_DELAY;
            }
        };
        
        self.handleKeyInput = function() {
            if (!self.focused) return;
            
            var ctrl = keyboard_check(vk_control);
            var shift = keyboard_check(vk_shift);
            var handledTextInput = false;
            
            if (ctrl && (keyboard_check_pressed(ord("Z")) && !shift || (self.keyRepeat.key == ord("Z") && self.handleKeyRepeat()))) {
                self.performUndo();
                return;
            }
            
            if (ctrl && ((keyboard_check_pressed(ord("Y")) || (keyboard_check_pressed(ord("Z")) && shift)) || (self.keyRepeat.key == ord("Y") && self.handleKeyRepeat()))) {
                self.performRedo();
                return;
            }
            
            if (ctrl && keyboard_check_pressed(ord("A"))) {
                self.selectionStart = 0;
                self.selectionEnd = string_length(self.parent.value);
                self.cursorPos = self.selectionEnd;
                self.updateScrollOffset();
                return;
            }
            
            if (ctrl && keyboard_check_pressed(ord("C"))) {
                var selectedText = self.getSelectedText();
                if (selectedText != "") clipboard_set_text(selectedText);
                return;
            }
            
            if (ctrl && keyboard_check_pressed(ord("X"))) {
                var selectedText = self.getSelectedText();
                if (selectedText != "") {
                    self.saveUndoState();
                    clipboard_set_text(selectedText);
                    self.deleteSelected();
                    self.updateScrollOffset();
                }
                return;
            }
            
            if (ctrl && (keyboard_check_pressed(ord("V")) || (self.keyRepeat.key == ord("V") && self.handleKeyRepeat()))) {
                var clipboardText = clipboard_get_text();
                if (clipboardText != "") self.insertText(clipboardText);
                return;
            }
            
            if (keyboard_check_pressed(vk_enter)) {
                self.insertText("\n");
                return;
            }
            
            if (keyboard_check_pressed(vk_left) || (self.keyRepeat.key == vk_left && self.handleKeyRepeat())) {
                self.moveCursorTo(ctrl ? self.findWordStart(self.cursorPos) : self.cursorPos - 1, shift);
            }
            
            if (keyboard_check_pressed(vk_right) || (self.keyRepeat.key == vk_right && self.handleKeyRepeat())) {
                self.moveCursorTo(ctrl ? self.findWordEnd(self.cursorPos) : self.cursorPos + 1, shift);
            }
            
            if (keyboard_check_pressed(vk_up) || (self.keyRepeat.key == vk_up && self.handleKeyRepeat())) {
                self.moveVertical(-1, shift);
            }
            
            if (keyboard_check_pressed(vk_down) || (self.keyRepeat.key == vk_down && self.handleKeyRepeat())) {
                self.moveVertical(1, shift);
            }
            
            if (keyboard_check_pressed(vk_home)) {
                self.moveCursorTo(ctrl ? 0 : self.getLineStart(self.cursorPos), shift);
            }
            
            if (keyboard_check_pressed(vk_end)) {
                self.moveCursorTo(ctrl ? string_length(self.parent.value) : self.getLineEnd(self.cursorPos), shift);
            }
            
            if (keyboard_check_pressed(vk_backspace) || (self.keyRepeat.key == vk_backspace && self.handleKeyRepeat())) {
                if (self.selectionStart != self.selectionEnd || self.cursorPos > 0) {
                    self.saveUndoState();
                    if (!self.deleteSelected() && self.cursorPos > 0) {
                        var newPos = ctrl ? self.findWordStart(self.cursorPos) : self.cursorPos - 1;
                        self.parent.value = string_delete(self.parent.value, newPos + 1, self.cursorPos - newPos);
                        self.cursorPos = newPos;
                        self.selectionStart = newPos;
                        self.selectionEnd = newPos;
                        self.parent.onChange(self.parent.value, self.parent);
                    }
                    self.updateScrollOffset();
                }
            }
            
            if (keyboard_check_pressed(vk_delete) || (self.keyRepeat.key == vk_delete && self.handleKeyRepeat())) {
                if (self.selectionStart != self.selectionEnd || self.cursorPos < string_length(self.parent.value)) {
                    self.saveUndoState();
                    if (!self.deleteSelected() && self.cursorPos < string_length(self.parent.value)) {
                        var newPos = ctrl ? self.findWordEnd(self.cursorPos) : self.cursorPos + 1;
                        self.parent.value = string_delete(self.parent.value, self.cursorPos + 1, newPos - self.cursorPos);
                        self.parent.onChange(self.parent.value, self.parent);
                    }
                    self.updateScrollOffset();
                }
            }
            
            if (keyboard_string != "") {
                var newText = keyboard_string;
                keyboard_string = "";
                self.insertText(newText);
                handledTextInput = true;
                keyboard_lastchar = "";
            }
            
            var isInitialPress = false;
            var isRepeatPress = (!handledTextInput && self.keyRepeat.pressed && self.keyRepeat.key >= 32 && self.handleKeyRepeat());
            if (!handledTextInput && !isRepeatPress && keyboard_key >= 32) {
                if (keyboard_check_pressed(keyboard_key)) isInitialPress = true;
            }
            
            if (isInitialPress || isRepeatPress) {
                var inputChar = keyboard_lastchar;
                if (inputChar == "" || ord(string_upper(inputChar)) != self.keyRepeat.key) {
                    if (self.keyRepeat.key >= 65 && self.keyRepeat.key <= 90) {
                        inputChar = chr(self.keyRepeat.key);
                        if (!keyboard_check(vk_shift)) inputChar = string_lower(inputChar);
                    } else if (self.keyRepeat.key >= 48 && self.keyRepeat.key <= 57) {
                        inputChar = chr(self.keyRepeat.key);
                    } else if (self.keyRepeat.key == vk_space) {
                        inputChar = " ";
                    }
                }
                if (inputChar != "" && ord(inputChar) >= 32 && ord(inputChar) != 127) {
                    self.insertText(inputChar);
                    keyboard_lastchar = "";
                }
            }
        };
        
        self.onWheelUp(function() {
            if (keyboard_check(vk_shift)) {
                self.scrollLeft -= 60;
            } else {
                self.scrollTop -= 60;
            }
            self.clampScroll();
            global.UI.requestRedraw();
            return true;
        });
        
        self.onWheelDown(function() {
            if (keyboard_check(vk_shift)) {
                self.scrollLeft += 60;
            } else {
                self.scrollTop += 60;
            }
            self.clampScroll();
            global.UI.requestRedraw();
            return true;
        });
        
        self.onStep(function() {
            if (global.UI.mouseReleased) self.isDragging = false;
            
            if (self.focused) {
                if (current_time - self.cursorBlinkTime > TEXTAREA_CURSOR_BLINK) {
                    self.showCursor = !self.showCursor;
                    self.cursorBlinkTime = current_time;
                    global.UI.requestRedraw();
                }
                
                self.updateKeyRepeat();
                self.handleKeyInput();
                self.handleMouseDrag();
            }
        });
        
        self.onDraw = function() {
            draw_set_color(global.UI_COL_BG_CARD);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, false);
            draw_set_color(self.focused ? global.UI_COL_PRIMARY : global.UI_COL_BORDER);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, true);
            
            var _scissor = gpu_get_scissor();
            var sx = self.x1 + self.layout.paddingLeft;
            var sy = self.y1 + self.layout.paddingTop;
            var sw = self.getInnerWidth();
            var sh = self.getInnerHeight();
            // Intersect with inherited parent scissor to clip inside scrollable ancestors
            var _ix1 = max(sx, _scissor.x);
            var _iy1 = max(sy, _scissor.y);
            var _ix2 = min(sx + sw, _scissor.x + _scissor.w);
            var _iy2 = min(sy + sh, _scissor.y + _scissor.h);
            __uui_set_scissor(_ix1, _iy1, max(0, _ix2 - _ix1), max(0, _iy2 - _iy1));
            
            draw_set_font(fText);
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
            
            var textX = sx - self.scrollLeft;
            var textY = sy - self.scrollTop;
            var lines = self.getLines();
            var text = self.parent.value;
            
            if (text == "" && self.parent.placeholder != undefined) {
                draw_set_color(global.UI_COL_TEXT_MAIN);
                draw_set_alpha(0.5);
                draw_text(textX, textY, self.parent.placeholder);
                draw_set_alpha(1);
            } else {
                if (self.focused && self.selectionStart != self.selectionEnd) {
                    var selStart = min(self.selectionStart, self.selectionEnd);
                    var selEnd = max(self.selectionStart, self.selectionEnd);
                    draw_set_color(global.UI_COL_SELECTION);
                    draw_set_alpha(0.3);
                    for (var i = 0; i < array_length(lines); i++) {
                        var line = lines[i];
                        var lineStart = line.start;
                        var lineEnd = line.start + line.length;
                        var start = max(selStart, lineStart);
                        var ended = min(selEnd, lineEnd);
                        if (selStart <= lineEnd && selEnd >= lineStart && start != ended) {
                            var localStart = start - lineStart;
                            var localEnd = ended - lineStart;
                            var x1 = textX + string_width(string_copy(line.text, 1, localStart));
                            var x2 = textX + string_width(string_copy(line.text, 1, localEnd));
                            var lineY = textY + i * self.parent.lineHeight;
                            draw_rectangle(x1, lineY, x2, lineY + self.parent.lineHeight, false);
                        }
                    }
                    draw_set_alpha(1);
                }
                
                draw_set_color(global.UI_COL_TEXT_MAIN);
                for (var i = 0; i < array_length(lines); i++) {
                    var lineY = textY + i * self.parent.lineHeight;
                    if (lineY + self.parent.lineHeight >= sy && lineY <= sy + sh) {
                        draw_text(textX, lineY, lines[i].text);
                    }
                }
            }
            
            if (self.focused && self.showCursor && self.selectionStart == self.selectionEnd) {
                var cursor = self.getCursorInfo(self.cursorPos);
                var cx = textX + cursor.x;
                var cy = textY + cursor.y;
                // Keep caret fully inside clipped draw area; at column 0 it can otherwise sit on the scissor edge.
                cx = clamp(cx, sx + 1, sx + sw - 1);
                draw_set_color(global.UI_COL_PRIMARY);
                draw_line(cx, cy + 2, cx, cy + self.parent.lineHeight - 2);
            }
            
            self.clampScroll();
            gpu_set_scissor(_scissor);
        };
        
        self.resetCursorBlink = function() {
            self.cursorBlinkTime = current_time;
            self.showCursor = true;
        };
        
        self.onFocus = function() {
            self.focused = true;
            self.cursorBlinkTime = current_time;
            self.showCursor = true;
            keyboard_string = "";
            keyboard_lastchar = "";
        };
        
        self.onBlur = function() {
            self.focused = false;
            self.keyRepeat.key = -1;
            self.keyRepeat.pressed = false;
            self.isDragging = false;
            global.UI.requestRedraw();
            if (self.parent.onBlur != undefined) self.parent.onBlur(self.parent.value, self.parent);
        };
    }
    
    self.onStep(function() {
        if (self.valueGetter != undefined && !self.Input.focused) self.value = self.valueGetter();
    });
}
