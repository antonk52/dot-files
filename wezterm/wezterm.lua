local wezterm = require 'wezterm';

return {
    font = wezterm.font("Fira Code"),
    font_size = 16.0,
    font_antialias = "Greyscale",

    colors = {
        cursor_bg = "#cdcecf",
        cursor_border = "#cdcecf",
    },

    -- use RESIZE instead of NONE
    -- for Amethyst to be able to resize at will
    window_decorations = "RESIZE",

    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,

    alternate_buffer_wheel_scroll_speed = 3, -- increase scroll speed
}
