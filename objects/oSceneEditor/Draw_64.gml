draw_set_font(fText);
global.UI.render(uiDebug);

draw_set_font(fTextSmall);
draw_set_halign(fa_right); draw_set_valign(fa_top); draw_set_color(c_gray);
draw_text(winW - 15, 10, $"IDE v{ideVersion}  Runtime v{global.UE_VERSION}");


//draw_text(300, 300, countUI(global.UI))