local wezterm = require('wezterm')

return {
    font = wezterm.font('Fira Code', {weight = 'Regular'}),
    font_rules = {
        italic = false,
    },
    -- font = wezterm.font("Fira Code", {weight="DemiBold", stretch="Normal", style="Normal"}),

    font_size = 20.0,

    colors = {
        cursor_bg = '#cdcecf',
        cursor_border = '#cdcecf',
    },

    -- use RESIZE instead of NONE
    -- for Amethyst to be able to resize at will
    window_decorations = 'RESIZE',

    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = true,

    alternate_buffer_wheel_scroll_speed = 3, -- increase scroll speed
    -- remove window padding
    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
}
