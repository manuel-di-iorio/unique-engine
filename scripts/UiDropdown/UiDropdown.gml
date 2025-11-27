function UiDropdown(style = {}, props = {}) : UiNode(style, props) constructor {
    var _this = self;
    setName(props[$ "name"] ?? "UiDropdown");
    self.value = props[$ "value"];
    self.items = props[$ "items"] ?? [];
    self.itemsGetter = props[$ "itemsGetter"];
    self.label = props[$ "label"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(input, value) {};
    var _marginLeft = self.label == undefined ? 0 : 3 + string_width(self.label) + 20;
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
                self.onChange(undefined);
            }
        }
    });

    // Draw the label if present
    function onDraw() {
       if (self.label != undefined) {
           draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_middle);
           draw_text(self.x1 + 3, ~~mean(self.y1, self.y2), self.label);
       }
    }
    
    // Input
    self.Input = new UiButton(undefined, {
        name: "UiDropdown.Input", 
        marginLeft: _marginLeft,
        height: 25
    }, { border: true });
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
            if (self.hovered) {
                draw_set_color(global.UI_COL_BTN_HOVER);
                draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
            }
            
            // Button
            draw_sprite(sprUiDropdownArrow, 0, self.x2 - 12, self.y2 - 12);
            draw_line(self.x2 - 25, self.y1 - 1, self.x2 - 25, self.y2);
            
            // Selected value
            draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_color(c_white);
            var _selectedIndex = array_find_index(self.parent.items, method({ value: self.parent.value }, function(item) {
                return item.value == self.value;
            }));
       
            var _text = _selectedIndex != -1 ? self.parent.items[_selectedIndex].label : "Select...";
            
            // Clip text to button width
            var _scissor = gpu_get_scissor();
            gpu_set_scissor(self.x1, self.y1, self.x2 - self.x1 - 25, self.y2 - self.y1);
            draw_text(self.x1 + 5, ~~mean(self.y1, self.y2), _text);
            gpu_set_scissor(_scissor);
         };
    } 
     
    self.createList = function() { 
        var _Dropdown = self;
        var _Input = self.Input;
        self.List = new UiNode({
            name: "UiDropdown.List", position: "absolute", padding: 5, maxHeight: 500, 
            left: -9999, top: -9999
        });
        
        with (self.List) {
            self.Dropdown = _Dropdown;
         
            self.computePosition = function() {
                var _Dropdown = self.Dropdown;
                if (!_Dropdown.Input.isVisible()) return _Dropdown.closeList();
                
                var _height = self.layout.height;
                if (!_height) return;
                
                var Input = _Dropdown.Input;
                if (self.x1 != Input.x1) self.setLeft(Input.x1);
                if (self.width != Input.width) self.setWidth(Input.width); 
                
                var yy = Input.y1 + 30;
                if (yy + _height > oSceneEditor.winH) {
                    yy = yy - 30 - self.layout.height;
                }
                if (self.y1 != yy) self.setTop(yy);
            }
    
            self.onStep(function() {
                self.computePosition();
                
                if (global.UI.mouseReleased) {
                    var y1 = min(self.y1, self.Dropdown.y1);
                    var y2 = max(self.y2, self.Dropdown.y2);
                    
                    if (!point_in_rectangle(global.UI.mouseX, global.UI.mouseY, self.x1, y1, self.x2, y2)) {
                        self.Dropdown.closeList();
                    }
                }
            });
            
            self.onDraw = function() {
                draw_set_color(global.UI_COL_DROPDOWN_LIST_BG);
                draw_roundrect(self.x1, self.y1, self.x2, self.y2, false);
            }
            
            self.createItems = function() {
                var _Dropdown = self.Dropdown;
                var _items = _Dropdown.items;
        
                if (!array_length(_items)) {
                    self.Items.add(new UiText("No assets found", { marginLeft: 5 }, { color: c_ltgray, font: fTextItalic }));
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
                        
                        self.onClick(function() {
                            var Dropdown = self.parent.parent.Dropdown;
                            if (Dropdown.value != self.value) {
                                Dropdown.value = self.value;
                                Dropdown.onChange(self.value);
                            }
                            Dropdown.closeList();
                        });
                        
                        self.onMouseEnter(function() {
                            global.UI.needsRedraw = true;
                        });
                        
                        self.onMouseLeave(function() {
                            global.UI.needsRedraw = true;
                        });
                        
                        self.onDraw = function() {
                            if (self.parent.parent.Dropdown.value == self.value) {
                                draw_set_color(global.UI_COL_SELECTED);
                                draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
                            } else if (self.hovered) {
                                draw_set_color(global.UI_COL_INSPECTOR_BG);
                                draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
                            }
                            
                            draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_color(c_white);
                            draw_text(self.x1 + 5, ~~mean(self.y1, self.y2), self.label);
                        };
                    }
                    
                    self.Items.add(_itemNode);
                }
                
                self.Items.enableScrollbar(global.UI_COL_CHECKBOX_HOVER);
            }
            
            // Create the search input
            if (_Dropdown.search != undefined) {
                self.Search = new UiTextbox({ height: 25, marginBottom: 10 }, {
                    placeholder: _Dropdown.search ?? "Search..",
                    onChange: method({ _Dropdown }, function(searchValue) {
                        _Dropdown.List.Items.destroyChildren();
                        _Dropdown.items = [];
                        
                        if (_Dropdown.itemsGetter != undefined) _Dropdown.items = _Dropdown.itemsGetter(searchValue);
                        _Dropdown.List.createItems();
                    })
                });
                self.add(self.Search);
            }
            
            // Create the items container
            self.Items = new UiNode({ height: "100%", maxHeight: 450 });
            self.add(self.Items);
            
            // Create the initial items
            if (_Dropdown.itemsGetter != undefined) _Dropdown.items = _Dropdown.itemsGetter(self.Search.value);
            self.createItems(); 
        }
        
        global.UI.Overlay.add(self.List);
        self.List.computePosition();
    }
    
    self.closeList = function() {
        self.List.destroy();
        self.List = undefined;
    }
}
