/**
 * Context Menu - A popup menu that appears on right-click
 * Usage: var menu = new UiContextMenu(x, y, items);
 * items = [{ label: "Action", onClick: function() {}, icon: sprite }]
 */
function UiContextMenu(x, y, items) constructor {
    var _this = self;
    self.x = x;
    self.y = y;
    self.items = items;
    self.Menu = undefined;
    
    /**
     * Show the context menu at the specified position
     */
    function show() {
        // Close any existing menu first
        if (global[$ "CurrentContextMenu"] != undefined) {
            global.CurrentContextMenu.close();
        }
        
        if (self.Menu != undefined) return; // Already showing
        
        global.CurrentContextMenu = self;
        
        var _x = self.x;
        var _y = self.y;
        var _items = self.items;
        var _contextMenu = self; // Capture the UiContextMenu instance
        
        self.Menu = new UiNode({ 
            name: "UiContextMenu", 
            position: "absolute", 
            flexDirection: "column",
            paddingHorizontal: 10,
            paddingVertical: 6,
            left: _x,
            top: _y,
            minWidth: 210
        }, { pointerEvents: true });
        
        with (self.Menu) {
            self.ContextMenu = _contextMenu;
            self.initialX = _x;
            self.initialY = _y;
            self.justOpened = true;
            
            self.onStep(function() {
                // Skip first frame to avoid immediate closure
                if (self.justOpened) {
                    self.justOpened = false;
                    return;
                }
                
                // Close on click outside
                if (global.UI.mouseReleased) {
                    if (!point_in_rectangle(global.UI.mouseX, global.UI.mouseY, self.x1, self.y1, self.x2, self.y2)) {
                        self.ContextMenu.close();
                    }
                }
                
                // Close on Escape
                if (keyboard_check_pressed(vk_escape)) {
                    self.ContextMenu.close();
                }
                
                // Adjust position if menu goes off-screen
                if (self.layout.height != undefined && !self[$ "positionAdjusted"]) {
                    var adjustedY = self.initialY;
                    if (adjustedY + self.layout.height > oSceneEditor.winH) {
                        adjustedY = oSceneEditor.winH - self.layout.height - 10;
                        self.setTop(adjustedY);
                    }
                    
                    var adjustedX = self.initialX;
                    if (adjustedX + self.layout.width > oSceneEditor.winW) {
                        adjustedX = oSceneEditor.winW - self.layout.width - 10;
                        self.setLeft(adjustedX);
                    }
                    
                    self.positionAdjusted = true;
                }
            });
            
            self.onDraw = function() {
                draw_set_color(global.UI_COL_DROPDOWN_LIST_BG);
                draw_roundrect(self.x1, self.y1, self.x2, self.y2, false);
            };
            
            // Create menu items
            for (var i = 0, l = array_length(_items); i < l; i++) {
                var itemData = _items[i];
                
                // Separator
                if (itemData[$ "separator"]) {
                    var separator = new UiNode({ 
                        height: 1, 
                        marginVertical: 3,
                    });
                    separator.onDraw = method(separator, function() {
                         draw_set_color(global.UI_COL_INSPECTOR_BG);
                         var _y = floor(mean(self.y1, self.y2));
                         draw_line(self.x1, _y, self.x2, _y);
                    });
                    self.add(separator);
                    continue;
                }
                
                var menuItem = new UiNode({
                    name: "UiContextMenu.Item",
                    height: 28,
                    paddingHorizontal: 8,
                    marginBottom: 2,
                    flexDirection: "row",
                    alignItems: "center",
                    gap: 8
                });
                
                menuItem.label = itemData.label;
                menuItem.icon = itemData[$ "icon"];
                menuItem.onClick = itemData.onClick;
                menuItem.pointerEvents = true;
                menuItem.handpoint = true;
                
                with (menuItem) {
                    self.onMouseEnter(function() {
                        global.UI.requestRedraw();
                    });
                    
                    self.onMouseLeave(function() {
                        global.UI.requestRedraw();
                    });
                    
                    self.onMouseDown(method({ item: menuItem, contextMenu: _contextMenu }, function() {
                        if (mouse_check_button_pressed(mb_left)) {
                            if (self.item.onClick != undefined) {
                                self.item.onClick();
                            }
                            self.contextMenu.close();
                            return true;
                        }
                        return false;
                    }));
                    
                    self.onDraw = function() {
                        if (self.hovered) {
                            draw_set_color(global.UI_COL_INSPECTOR_BG);
                            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
                        }
                        
                        var xx = self.x1 + 15;
                        var yy = mean(self.y1, self.y2);
                        
                        // Draw icon
                        if (self.icon != undefined) {
                            draw_sprite(self.icon, 0, xx, yy);
                            xx += 20;
                        }
                        
                        // Draw label
                        draw_set_color(c_white);
                        draw_set_halign(fa_left);
                        draw_set_valign(fa_middle);
                        draw_set_font(fText);
                        draw_text(xx, yy, self.label);
                    };
                }
                
                self.add(menuItem);
            }
        }
        
        global.UI.Overlay.add(self.Menu);
    }
    
    /**
     * Close and destroy the context menu
     */
    function close() {
        if (self.Menu != undefined) {
            self.Menu.destroy();
            self.Menu = undefined;
        }
        if (global[$ "CurrentContextMenu"] == self) {
            global.CurrentContextMenu = undefined;
        }
    }
}
