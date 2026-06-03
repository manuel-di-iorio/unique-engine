/// @description HTML5-style color picker with popup panel, HSV selector and hex input.

function __uui_byte_to_hex(_n) {
    _n = clamp(floor(_n), 0, 255);
    var _digits = "0123456789ABCDEF";
    return string_char_at(_digits, floor(_n / 16) + 1) + string_char_at(_digits, (_n mod 16) + 1);
}

function __uui_color_to_hex(_col) {
    return "#" + __uui_byte_to_hex(color_get_red(_col))
        + __uui_byte_to_hex(color_get_green(_col))
        + __uui_byte_to_hex(color_get_blue(_col));
}

function __uui_hex_pair_to_byte(_pair) {
    var _digits = "0123456789ABCDEF";
    var _hi = string_pos(string_char_at(_pair, 1), _digits) - 1;
    var _lo = string_pos(string_char_at(_pair, 2), _digits) - 1;
    if (_hi < 0 || _lo < 0) return -1;
    return _hi * 16 + _lo;
}

function __uui_hex_to_color(_hex) {
    var _s = string_upper(string_replace_all(string(_hex), "#", ""));
    var _len = string_length(_s);
    if (_len == 3) {
        _s = string_char_at(_s, 1) + string_char_at(_s, 1)
            + string_char_at(_s, 2) + string_char_at(_s, 2)
            + string_char_at(_s, 3) + string_char_at(_s, 3);
        _len = 6;
    }
    if (_len != 6) return undefined;
    var _r = __uui_hex_pair_to_byte(string_copy(_s, 1, 2));
    var _g = __uui_hex_pair_to_byte(string_copy(_s, 3, 2));
    var _b = __uui_hex_pair_to_byte(string_copy(_s, 5, 2));
    if (_r < 0 || _g < 0 || _b < 0) return undefined;
    return make_color_rgb(_r, _g, _b);
}

function __uui_hsv_to_rgb(_h, _s, _v) {
    if (_s <= 0) {
        var _g = _v * 255;
        return make_color_rgb(_g, _g, _g);
    }
    var _i = floor(_h * 6);
    var _f = _h * 6 - _i;
    var _p = _v * (1 - _s);
    var _q = _v * (1 - _f * _s);
    var _t = _v * (1 - (1 - _f) * _s);
    var _r = 0; var _g = 0; var _b = 0;
    switch (_i mod 6) {
        case 0: _r = _v; _g = _t; _b = _p; break;
        case 1: _r = _q; _g = _v; _b = _p; break;
        case 2: _r = _p; _g = _v; _b = _t; break;
        case 3: _r = _p; _g = _q; _b = _v; break;
        case 4: _r = _t; _g = _p; _b = _v; break;
        default: _r = _v; _g = _p; _b = _q; break;
    }
    return make_color_rgb(_r * 255, _g * 255, _b * 255);
}

function __uui_rgb_to_hsv(_col) {
    var _r = color_get_red(_col) / 255;
    var _g = color_get_green(_col) / 255;
    var _b = color_get_blue(_col) / 255;
    var _max = max(max(_r, _g), _b);
    var _min = min(min(_r, _g), _b);
    var _d = _max - _min;
    var _h = 0;
    var _s = 0;
    var _v = _max;
    if (_d > 0.0001) {
        _s = _d / _max;
        if (_max == _r) {
            _h = (_g - _b) / _d;
        } else if (_max == _g) {
            _h = (_b - _r) / _d + 2;
        } else {
            _h = (_r - _g) / _d + 4;
        }
        _h /= 6;
        if (_h < 0) _h += 1;
    }
    return { h: _h, s: _s, v: _v };
}

function UiColorPicker(style = {}, props = {}) : UiNode(style, props) constructor {
    flexpanel_node_style_set_flex_direction(self.node, flexpanel_flex_direction.row);
    flexpanel_node_style_set_align_items(self.node, flexpanel_align.center);
    
    setName(props[$ "name"] ?? "UiColorPicker");
    self.value = props[$ "value"] ?? #3B82F6;
    self.label = props[$ "label"] ?? undefined;
    self.onChange = props[$ "onChange"] ?? function(_color, _picker) {};
    self.valueGetter = props[$ "valueGetter"] ?? undefined;
    
    var _hsv = __uui_rgb_to_hsv(self.value);
    self.hue = _hsv.h;
    self.saturation = _hsv.s;
    self.brightness = _hsv.v;
    self.__syncLock = false;
    
    self.Panel = undefined;
    
    if (self.label != undefined) {
        self.LabelNode = new UiText(self.label, { marginRight: 15 }, { color: global.UI_COL_TEXT_MAIN });
        self.add(self.LabelNode);
    }
    
    self.Trigger = new UiNode({
        name: "UiColorPicker.Trigger",
        width: 40,
        height: 28,
        flexShrink: 0
    }, { pointerEvents: true, focusable: true, handpoint: true });
    self.add(self.Trigger);
    
    with (self.Trigger) {
        self.onMouseDown(function() {
            if (self.parent.Panel != undefined) {
                self.parent.closePanel();
            } else {
                self.parent.openPanel();
            }
        });
        
        self.onDraw = function() {
            var _radius = 6;
            var _col = self.parent.value;
            
            draw_set_color(_col);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, _radius, _radius, false);
            
            if (self.hovered) {
                draw_set_alpha(0.15);
                draw_set_color(c_white);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, _radius, _radius, false);
                draw_set_alpha(1);
            }
            
            draw_set_color(global.UI_COL_BORDER);
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, _radius, _radius, true);
        };
    }
    
    self.onStep(function() {
        if (self.valueGetter != undefined && !self.__syncLock) {
            var _ext = self.valueGetter();
            if (_ext != self.value) {
                self.setColor(_ext, false);
            }
        }
    });
    
    self.syncHsvFromValue = function() {
        var _hsv = __uui_rgb_to_hsv(self.value);
        self.hue = _hsv.h;
        self.saturation = _hsv.s;
        self.brightness = _hsv.v;
    };
    
    self.colorFromHsv = function() {
        return __uui_hsv_to_rgb(self.hue, self.saturation, self.brightness);
    };
    
    self.setColor = function(_col, _fireChange = true) {
        if (_col == undefined) return;
        var _changed = (self.value != _col);
        self.value = _col;
        self.syncHsvFromValue();
        if (self.Panel != undefined) {
            if (self.Panel.HexInput != undefined) {
                self.__syncLock = true;
                self.Panel.HexInput.value = __uui_color_to_hex(self.value);
                self.__syncLock = false;
            }
        }
        if (_fireChange && _changed) self.onChange(self.value, self);
        global.UI.requestRedraw();
    };
    
    self.applyHsv = function(_fireChange = true) {
        var _newCol = self.colorFromHsv();
        if (_newCol != self.value) {
            self.value = _newCol;
            if (self.Panel != undefined) {
                if (self.Panel.HexInput != undefined) {
                    self.__syncLock = true;
                    self.Panel.HexInput.value = __uui_color_to_hex(self.value);
                    self.__syncLock = false;
                }
            }
            if (_fireChange) self.onChange(self.value, self);
            global.UI.requestRedraw();
        }
    };
    
    self.openPanel = function() {
        var _Picker = self;
        var _Trigger = self.Trigger;
        
        self.Panel = new UiNode({
            name: "UiColorPicker.Panel",
            position: "absolute",
            width: 248,
            flexDirection: "column",
            padding: 10,
            left: -9999,
            top: -9999
        }, { pointerEvents: true });
        
        with (self.Panel) {
            self.Picker = _Picker;
            
            self.computePosition = function() {
                var _Picker = self.Picker;
                if (!_Picker.Trigger.isVisible()) return _Picker.closePanel();
                
                var _height = self.layout.height;
                if (!_height) return;
                
                var _Trigger = _Picker.Trigger;
                if (abs(self.x1 - _Trigger.x1) > 1) self.setLeft(_Trigger.x1);
                
                var _yy = floor(_Trigger.y2 + 6);
                if (_yy + _height > display_get_gui_height()) {
                    _yy = floor(_Trigger.y1 - 6 - _height);
                }
                if (abs(self.y1 - _yy) > 1) self.setTop(_yy);
            };
            
            self.__skipFirstRelease = true;
            
            self.onStep(function() {
                self.computePosition();
                
                if (global.UI.mouseReleased) {
                    if (self.__skipFirstRelease) {
                        self.__skipFirstRelease = false;
                        return;
                    }
                    
                    var _Picker = self.Picker;
                    var _y1 = min(self.y1, _Picker.y1);
                    var _y2 = max(self.y2, _Picker.y2);
                    var _x1 = min(self.x1, _Picker.Trigger.x1);
                    var _x2 = max(self.x2, _Picker.Trigger.x2);
                    
                    if (!point_in_rectangle(global.UI.mouseX, global.UI.mouseY, _x1, _y1, _x2, _y2)) {
                        _Picker.closePanel();
                    }
                }
            });
            
            self.onDraw = function() {
                draw_set_color(global.UI_COL_DROPDOWN_LIST_BG);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, false);
                draw_set_color(global.UI_COL_BORDER);
                draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 8, 8, true);
            };
            
            // Saturation / brightness area
            self.SvArea = new UiNode({
                name: "UiColorPicker.Panel.SvArea",
                width: "100%",
                height: 140,
                marginBottom: 10
            }, { pointerEvents: true, handpoint: true });
            self.add(self.SvArea);
            
            with (self.SvArea) {
                self.dragging = false;
                
                self.updateFromMouse = function() {
                    var _Picker = self.parent.Picker;
                    var _t = clamp((global.UI.mouseX - self.x1) / (self.x2 - self.x1), 0, 1);
                    var _v = 1 - clamp((global.UI.mouseY - self.y1) / (self.y2 - self.y1), 0, 1);
                    _Picker.saturation = _t;
                    _Picker.brightness = _v;
                    _Picker.applyHsv();
                };
                
                self.onMouseDown(function() {
                    self.dragging = true;
                    self.updateFromMouse();
                    return true;
                });
                
                self.onStep(function() {
                    if (self.dragging) {
                        if (!mouse_check_button(mb_left)) {
                            self.dragging = false;
                        } else {
                            self.updateFromMouse();
                        }
                    }
                });
                
                self.onDraw = function() {
                    var _hueCol = __uui_hsv_to_rgb(self.parent.Picker.hue, 1, 1);
                    
                    // Draw SV area with smooth primitives for better gradient
                    draw_primitive_begin(pr_trianglestrip);
                    // Top row (value = 1)
                    draw_vertex_color(self.x1, self.y1, c_white, 1);
                    draw_vertex_color(self.x2, self.y1, _hueCol, 1);
                    // Bottom row ( (value = 0)
                    draw_vertex_color(self.x1, self.y2, c_black, 1);
                    draw_vertex_color(self.x2, self.y2, c_black, 1);
                    draw_primitive_end();
                    
                    draw_set_color(global.UI_COL_BORDER);
                    draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, true);
                    
                    var _Picker = self.parent.Picker;
                    var _cx = lerp(self.x1, self.x2, _Picker.saturation);
                    var _cy = lerp(self.y2, self.y1, _Picker.brightness);
                    draw_set_color(c_white);
                    draw_circle(_cx, _cy, 6, false);
                    draw_set_color(global.UI_COL_TEXT_MAIN);
                    draw_circle(_cx, _cy, 6, true);
                };
            }
            
            // Hue slider
            self.HueBar = new UiNode({
                name: "UiColorPicker.Panel.HueBar",
                width: "100%",
                height: 14,
                marginBottom: 10
            }, { pointerEvents: true, handpoint: true });
            self.add(self.HueBar);
            
            with (self.HueBar) {
                self.dragging = false;
                
                self.updateFromMouse = function() {
                    var _Picker = self.parent.Picker;
                    _Picker.hue = clamp((global.UI.mouseX - self.x1) / (self.x2 - self.x1), 0, 1);
                    _Picker.applyHsv();
                };
                
                self.onMouseDown(function() {
                    self.dragging = true;
                    self.updateFromMouse();
                    return true;
                });
                
                self.onStep(function() {
                    if (self.dragging) {
                        if (!mouse_check_button(mb_left)) {
                            self.dragging = false;
                        } else {
                            self.updateFromMouse();
                        }
                    }
                });
                
                self.onDraw = function() {
                    var _segments = 36;
                    var _w = (self.x2 - self.x1) / _segments;
                    draw_primitive_begin(pr_trianglestrip);
                    for (var _i = 0; _i <= _segments; _i++) {
                        var _h = _i / _segments;
                        var _c = __uui_hsv_to_rgb(_h, 1, 1);
                        var _x = lerp(self.x1, self.x2, _i / _segments);
                        draw_vertex_color(_x, self.y1, _c, 1);
                        draw_vertex_color(_x, self.y2, _c, 1);
                    }
                    draw_primitive_end();
                    
                    draw_set_color(global.UI_COL_BORDER);
                    draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, true);
                    
                    var _hx = lerp(self.x1, self.x2, self.parent.Picker.hue);
                    draw_set_color(c_white);
                    draw_roundrect_ext(_hx - 3, self.y1 - 2, _hx + 3, self.y2 + 2, 2, 2, false);
                    draw_set_color(global.UI_COL_TEXT_MAIN);
                    draw_roundrect_ext(_hx - 3, self.y1 - 2, _hx + 3, self.y2 + 2, 2, 2, true);
                };
            }
            
            // Preview swatch + hex field
            self.Footer = new UiNode({
                name: "UiColorPicker.Panel.Footer",
                width: "100%",
                height: 28,
                flexDirection: "row",
                alignItems: "center"
            });
            self.add(self.Footer);
            
            self.Preview = new UiNode({
                name: "UiColorPicker.Panel.Preview",
                width: 28,
                height: 28,
                marginRight: 10,
                flexShrink: 0
            }, { pointerEvents: false });
            self.Footer.add(self.Preview);
            
            with (self.Preview) {
                self.onDraw = function() {
                    var _col = self.parent.parent.Picker.value;
                    draw_set_color(_col);
                    draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, false);
                    draw_set_color(global.UI_COL_BORDER);
                    draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 6, 6, true);
                };
            }
            
            self.HexInput = new UiTextbox({ flexGrow: 1, height: 28 }, {
                value: __uui_color_to_hex(_Picker.value),
                maxLength: 7,
                placeholder: "#RRGGBB",
                onChange: method({ _Picker }, function(_hex, _input) {
                    if (_Picker.__syncLock) return;
                    var _col = __uui_hex_to_color(_hex);
                    if (_col != undefined) {
                        _Picker.setColor(_col);
                    }
                }),
                onBlur: method({ _Picker }, function(_hex, _input) {
                    if (_Picker.__syncLock) return;
                    var _col = __uui_hex_to_color(_hex);
                    if (_col != undefined) {
                        _Picker.setColor(_col);
                        _Picker.__syncLock = true;
                        _input.value = __uui_color_to_hex(_col);
                        _Picker.__syncLock = false;
                    } else {
                        _Picker.__syncLock = true;
                        _input.value = __uui_color_to_hex(_Picker.value);
                        _Picker.__syncLock = false;
                    }
                })
            });
            self.Footer.add(self.HexInput);
        }
        
        global.UI.getOverlay().add(self.Panel);
    };
    
    self.closePanel = function() {
        if (self.Panel != undefined) {
            self.Panel.destroy();
            self.Panel = undefined;
        }
    };
}
