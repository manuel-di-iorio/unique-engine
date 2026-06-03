function UiSprite(sprite, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiSprite");
    self.sprite = sprite;
    self.subimg = 0;
    self.autoResize = props[$ "autoResize"] ?? (style[$ "width"] == undefined && style[$ "height"] == undefined) ?? true;
    self.color = props[$ "color"] ?? c_white;
    self.alpha = props[$ "alpha"] ?? 1.0;
    
    if (self.autoResize && sprite_exists(sprite)) setSize(sprite_get_width(sprite), sprite_get_height(sprite));
    
    function onDraw() {
        if (sprite_exists(self.sprite)) {
            var w = self.x2 - self.x1;
            var h = self.y2 - self.y1;
            var xscale = w / sprite_get_width(self.sprite);
            var yscale = h / sprite_get_height(self.sprite);
            var col = (typeof(self.color) == "method") ? self.color() : self.color;
            var alp = (typeof(self.alpha) == "method") ? self.alpha() : self.alpha;
            draw_sprite_ext(self.sprite, self.subimg, ~~mean(self.x1, self.x2), ~~mean(self.y1, self.y2), xscale, yscale, 0, col, alp);
        }
    }
}