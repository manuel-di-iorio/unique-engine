/// @desc UiTabs — tab-strip that shows/hides content panels.
/// @param {Array} items   Array of structs: { label: string, content: UiNode }
/// @param {Struct} style  FlexPanel layout style
/// @param {Struct} props  Props: selectedIndex, onChange
function UiTabs(items, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiTabs");
    self.items         = items;
    self.selectedIndex = props[$ "selectedIndex"] ?? 0;
    self.onChange      = props[$ "onChange"]      ?? function(index, label) {};
    self.variant       = props[$ "variant"]       ?? "underline"; // "underline" | "pills"
    self.__fillContent = (style[$ "height"] != undefined || style[$ "flex"] != undefined || style[$ "flexGrow"] != undefined);
    
    if (style[$ "width"] == undefined) self.setWidth("100%");
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.column);
    
    // ── Tab Strip ────────────────────────────────────────────────────────────
    self.Strip = new UiNode({ width: "100%", flexDirection: "row" });
    
    if (self.variant == "underline") {
        self.Strip.onDraw = method(self.Strip, function() {
            draw_set_color(global.UI_COL_BORDER);
            draw_line(self.x1, self.y2, self.x2, self.y2);
        });
    }
    self.add_base = self.add;
    self.add_base(self.Strip);
    
    // ── Content Area ─────────────────────────────────────────────────────────
    var _contentStyle = { width: "100%", flexDirection: "column", paddingTop: 16 };
    if (self.__fillContent) _contentStyle.flex = 1;
    self.ContentArea = new UiNode(_contentStyle);
    self.add_base(self.ContentArea);
    
    // ── Build tabs ───────────────────────────────────────────────────────────
    // IMPORTANT: Strip children (buttons) are safe to destroy/recreate.
    // Content panels are owned by the caller — NEVER call destroyChildren on
    // ContentArea. Content panels are added once (tracked by __addedToTabs)
    // and only shown/hidden on subsequent calls.
    self.__buildTabs = function() {
        // Rebuild tab strip buttons only
        self.Strip.destroyChildren(true);
        
        for (var i = 0; i < array_length(self.items); i++) {
            var item     = self.items[i];
            var isActive = (i == self.selectedIndex);
            
            // Tab button
            var _tab = new UiNode({
                paddingLeft: 16, paddingRight: 16, height: 40,
                justifyContent: "center", marginRight: 2
            }, { pointerEvents: true, handpoint: true });
            
            _tab.__tabIndex = i;
            _tab.__isActive = isActive;
            
            if (self.variant == "underline") {
                _tab.onDraw = method(_tab, function() {
                    if (self.__isActive) {
                        draw_set_color(global.UI_COL_PRIMARY);
                        draw_line_width(self.x1, self.y2, self.x2, self.y2, 2);
                    } else if (self.hovered) {
                        draw_set_color(global.UI_COL_BTN_HOVER);
                        draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2 - 2, 6, 6, false);
                    }
                });
            } else { // pills
                _tab.onDraw = method(_tab, function() {
                    if (self.__isActive) {
                        draw_set_color(global.UI_COL_PRIMARY);
                        draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, false);
                    } else if (self.hovered) {
                        draw_set_color(global.UI_COL_BTN_HOVER);
                        draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, false);
                    }
                });
            }
            
            var textColor = global.UI_COL_TEXT_DIM;
            if (isActive) {
                textColor = (self.variant == "pills") ? function() { return #FFFFFF; } : global.UI_COL_PRIMARY;
            }

            _tab.add(new UiText(item.label, {}, {
                color: textColor
            }));
            
            var _tabs = self;
            _tab.onClick(method({ idx: i, tabs: _tabs }, function() {
                tabs.selectTab(idx);
            }));
            
            self.Strip.add(_tab);
            
            // Content panel: add to ContentArea ONCE, then only show/hide
            if (variable_struct_exists(item, "content") && item.content != undefined) {
                item.content.__tabIndex = i;
                if (!variable_struct_exists(item.content, "__addedToTabs")) {
                    item.content.__addedToTabs = true;
                    self.ContentArea.add(item.content);
                }
                if (isActive) {
                    item.content.show();
                } else {
                    item.content.hide();
                }
            }
        }
    };
    
    /// @desc Selects a tab by index and fires onChange.
    self.selectTab = function(index) {
        self.selectedIndex = clamp(index, 0, array_length(self.items) - 1);
        self.__buildTabs();
        self.onChange(self.selectedIndex, self.items[self.selectedIndex].label);
        global.UI.requestUpdate();
    };
    
    /// @desc Override add — adds a content UiNode for the given tab index.
    self.add = function(node, tabIndex = -1) {
        if (tabIndex >= 0 && tabIndex < array_length(self.items)) {
            self.items[tabIndex].content = node;
            self.__buildTabs();
        }
        return self;
    };
    
    self.__buildTabs();
}
