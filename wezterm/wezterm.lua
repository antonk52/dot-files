local wezterm = require('wezterm')

return {
    font = wezterm.font('FiraCode Nerd Font', { weight = 'Regular' }),
    font_rules = {
        {
            font = wezterm.font_with_fallback({
                family = 'FiraCode Nerd Font',
            }),
            -- disable italics
            italic = false,
        },
    },

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

    enable_kitty_keyboard = true,

    alternate_buffer_wheel_scroll_speed = 3, -- increase scroll speed
    -- remove window padding
    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    keys = {
        {
            -- used to toggle comment in nvim,
            key = '-',
            mods = 'CTRL',
            action = wezterm.action.DisableDefaultAssignment,
        },
        {
            key = '+',
            mods = 'CTRL',
            action = wezterm.action.DisableDefaultAssignment,
        },
    },
}
