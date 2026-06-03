function UiDropdown(style = {}, props = {}) : UiNode(style, props) constructor {
    var _this = self;
    
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.row);
    flexpanel_node_style_set_align_items(self.node, flexpanel_align.center);
    setName(props[$ "name"] ?? "UiDropdown");
    self.value = props[$ "value"];
    self.items = props[$ "items"] ?? [];
    self.itemsFull = self.items;
    self.itemsGetter = props[$ "itemsGetter"];
    self.label = props[$ "label"] ?? undefined;
    self.placeholder = props[$ "placeholder"] ?? "Select...";
    self.onChange = props[$ "onChange"] ?? function(input, value) {};
    
    if (self.label != undefined) {
        self.LabelNode = new UiText(self.label, { marginRight: 15 }, { color: global.UI_COL_TEXT_MAIN });
        self.add(self.LabelNode);
    }
    
    self.List = undefined;
    self.search = props[$ "search"];

    self.onStep(function() {
        if (self.itemsGetter != undefined) {
            self.items = self.itemsGetter("");
        }

        // Check if current value is still valid
        if (self.value != undefined) {
            var found = false;
            for (var i = 0, l = array_length(self.items); i < l; i++) {
                if (self.items[i].value == self.value) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                self.value = undefined;
                self.onChange(self, undefined);
            }
        }
    });

    // Draw the label if present
   self.onDraw = function() { };
    
    // Input
    self.Input = new UiNode({
        name: "UiDropdown.Input", 
        flexGrow: 1,
        height: "100%",
        flexDirection: "row",
        alignItems: "center",
        paddingHorizontal: 12
    }, { pointerEvents: true, focusable: true, border: true, handpoint: true });
    self.add(self.Input);
    
    with (self.Input) {
        self.onMouseDown(function() {
            var List = self.parent.List;
            if (List != undefined) {
                self.parent.closeList();
            } else {
                self.parent.createList(); 
            }
        });
        
        self.onDraw = function() {
            var radius = 6;
            draw_set_color(global.UI_COL_BG_CARD);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, false);
            
            if (self.hovered) {
                draw_set_color(global.UI_COL_BTN_HOVER);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, false);
            }
            
            draw_set_color(global.UI_COL_BORDER);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, radius, radius, true);

            // Button arrow (Modern Chevron)
            var arrowCol = self.hovered ? global.UI_COL_TEXT_MAIN : global.UI_COL_TEXT_DIM;
            var cx = self.x2 - 16;
            var cy = floor(self.y1 + self.height/2);
            var size = 3;
            var isOpen = self.parent.List != undefined;
            
            draw_set_color(arrowCol);
            if (isOpen) {
                // Up Chevron
                draw_line_width(cx - size, cy + size/2, cx, cy - size/2, 1.5);
                draw_line_width(cx, cy - size/2, cx + size, cy + size/2, 1.5);
            } else {
                // Down Chevron
                draw_line_width(cx - size, cy - size/2, cx, cy + size/2, 1.5);
                draw_line_width(cx, cy + size/2, cx + size, cy - size/2, 1.5);
            }
            
            // Selected value
            draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_color(global.UI_COL_TEXT_MAIN);
            var _val = self.parent.value;
            var _selectedIndex = array_find_index(self.parent.items, method({ value: _val }, function(item) {
                return item.value == self.value;
            }));
       
            var _text = _selectedIndex != -1 ? self.parent.items[_selectedIndex].label : self.parent.placeholder;
            
            var _scissor = gpu_get_scissor();
            __uui_set_scissor(self.x1, self.y1, self.x2 - self.x1 - 25, self.y2 - self.y1);
            draw_text(self.x1 + 8, ~~mean(self.y1, self.y2), _text);
            gpu_set_scissor(_scissor);
         };
    } 
     
    self.createList = function() { 
        var _Dropdown = self;
        var _Input = self.Input;
        self.List = new UiNode({
            name: "UiDropdown.List", position: "absolute", padding: 5, maxHeight: 500, 
            left: -9999, top: -9999
        }, { pointerEvents: true });
        
        with (self.List) {
            self.Dropdown = _Dropdown;
         
            self.computePosition = function() {
                var _Dropdown = self.Dropdown;
                if (!_Dropdown.Input.isVisible()) return _Dropdown.closeList();
                
                var _height = self.layout.height;
                if (!_height) return;
                
                var Input = _Dropdown.Input;
                if (abs(self.x1 - Input.x1) > 1) self.setLeft(Input.x1);
                if (abs(self.width - Input.width) > 1) self.setWidth(Input.width); 
                
                var yy = floor(Input.y1 + 30);
                if (yy + _height > display_get_gui_height()) {
                    yy = floor(yy - 30 - self.layout.height);
                }
                if (abs(self.y1 - yy) > 1) self.setTop(yy);
            }
    
            // Skip the first mouseReleased after opening (user might hold mouse and release outside)
            self.__skipFirstRelease = true;
            
            self.onStep(function() {
                self.computePosition();
                
                if (global.UI.mouseReleased) {
                    // Skip the first mouseReleased event after opening
                    if (self.__skipFirstRelease) {
                        self.__skipFirstRelease = false;
                        return;
                    }
                    
                    var y1 = min(self.y1, self.Dropdown.y1);
                    var y2 = max(self.y2, self.Dropdown.y2);
                    
                    if (!point_in_rectangle(global.UI.mouseX, global.UI.mouseY, self.x1, y1, self.x2, y2)) {
                        self.Dropdown.closeList();
                    }
                }
            });
            
            self.onDraw = function() {
                draw_set_color(global.UI_COL_DROPDOWN_LIST_BG);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, false);
                draw_set_color(global.UI_COL_BORDER);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, true);
            }
            
            self.createItems = function() {
                var _Dropdown = self.Dropdown;
                var _items = _Dropdown.items;
        
                if (!array_length(_items)) {
                    self.Items.add(new UiText("No items found", { marginLeft: 5 }, { color: #CBD5E1, font: fTextItalic }));
                }
        
                // Add the items
                for (var i = 0, l = array_length(_items); i < l; i++) {
                    var _item = _items[i];
                    var _itemNode = new UiNode({
                        name: "UiDropdown.List.Item",
                        width: "100%",
                        height: 25
                    }, {
                        tooltip: _item[$ "tooltip"]
                    });
                    _itemNode.label = _item.label;
                    _itemNode.value = _item.value;
                    
                    with (_itemNode) {
                        self.pointerEvents = true;
                        self.handpoint = true;
                        
                        self.onClick(method({ Dropdown: _Dropdown, itemValue: _item.value }, function() {
                            if (self.Dropdown.value != self.itemValue) {
                                self.Dropdown.value = self.itemValue;
                                self.Dropdown.onChange(self.itemValue);
                            }
                            self.Dropdown.closeList();
                        }));
                        
                        self.onMouseEnter(function() {
                            global.UI.requestRedraw();
                        });
                        
                        self.onMouseLeave(function() {
                            global.UI.requestRedraw();
                        });
                        
                        self.onDraw = method({ itemNode: _itemNode, Dropdown: _Dropdown }, function() {
                            if (self.Dropdown.value == self.itemNode.value) {
                                draw_set_color(global.UI_COL_PRIMARY);
                                draw_rectangle(self.itemNode.x1, self.itemNode.y1, self.itemNode.x2, self.itemNode.y2, false);
                            } else if (self.itemNode.hovered) {
                                draw_set_color(#334155);
                                draw_rectangle(self.itemNode.x1, self.itemNode.y1, self.itemNode.x2, self.itemNode.y2, false);
                            }
                            
                            var text_color = (self.Dropdown.value == self.itemNode.value) ? c_white : #F8FAFC;
                            draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_color(text_color);
                            draw_text(self.itemNode.x1 + 12, ~~mean(self.itemNode.y1, self.itemNode.y2), self.itemNode.label);
                        });
                    }
                    
                    self.Items.add(_itemNode);
                }
                
                self.Items.enableScrollbar(global.UI_COL_BTN_HOVER);
            }
            
            // Create the search input
            if (_Dropdown.search != undefined) {
                self.Search = new UiTextbox({ height: 25, marginBottom: 10 }, {
                    placeholder: _Dropdown.search ?? "Search..",
                    onChange: method({ _Dropdown }, function(searchValue) {
                        _Dropdown.List.Items.destroyChildren();
                        
                        if (_Dropdown.itemsGetter != undefined) {
                             _Dropdown.items = _Dropdown.itemsGetter(searchValue);
                        } else {
                             // Local filtering
                             var filtered = [];
                             var _lowerSearch = string_lower(searchValue);
                             for (var i = 0; i < array_length(_Dropdown.itemsFull); i++) {
                                 var _item = _Dropdown.itemsFull[i];
                                 if (_lowerSearch == "" || string_pos(_lowerSearch, string_lower(_item.label)) > 0) {
                                     array_push(filtered, _item);
                                 }
                             }
                             _Dropdown.items = filtered;
                        }
                        
                        _Dropdown.List.createItems();
                    })
                });
                self.add(self.Search);
            }
            
            // Create the items container
            self.Items = new UiNode({ height: "100%", maxHeight: 450 });
            self.add(self.Items);
            
            // Create the initial items
            var initialSearch = self[$ "Search"] != undefined ? self.Search.value : "";
            if (_Dropdown.itemsGetter != undefined) {
                _Dropdown.items = _Dropdown.itemsGetter(initialSearch);
            } else if (initialSearch == "") {
                _Dropdown.items = _Dropdown.itemsFull;
            }
            self.createItems(); 
        }
        
        global.UI.getOverlay().add(self.List);
        // Don't call computePosition() here - layout isn't calculated yet!
        // It will be called in the first onStep after layout is ready.
    }
    
    self.closeList = function() {
        if (self.List != undefined) {
            self.List.destroy();
            self.List = undefined;
        }
    }
}

