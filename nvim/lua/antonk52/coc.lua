local M = {}
local function has_eslint()
    for _,name in pairs({'.eslintrc.js', '.eslintrc.json', '.eslintrc'}) do
        if vim.fn.globpath('.', name) ~= '' then
            return true
        end
    end
end

function M.setup_eslint()
    local has_eslint_config = has_eslint()
    -- turn off eslint when cannot find eslintrc
    vim.fn['coc#config']('eslint.enable', has_eslint_config)
    vim.fn['coc#config']('eslint.autoFixOnSave', has_eslint_config)
end

-- get absolute flow bin
local get_flow_bin = function()
    local local_flow = 'node_modules/.bin/flow'
    if vim.fn.filereadable(local_flow) == 1 then
        return vim.fn.getcwd() .. '/' .. local_flow
    else if vim.fn.executable('flow') then
            return vim.fn.exepath('flow')
        end
    end

    return nil
end
-- lookup local flow executable
-- and turn on flow for coc is executable exists
function M.setup_flow()
    local has_flowconfig = vim.fn.filereadable('.flowconfig') == 1
    if not has_flowconfig then
        return false
    end

    local flow_bin = get_flow_bin()
    if flow_bin == nil then
        return false
    end
    local flow_config = {
        ['command'] = flow_bin,
        ['args'] = { 'lsp' },
        ['filetypes'] = { 'javascript', 'javascriptreact' },
        ['initializationOptions'] = {},
        ['requireRootPattern'] = 1,
        ['settings'] = {},
        ['rootPatterns'] = { '.flowconfig' }
    }
    vim.fn['coc#config']('languageserver.flow', flow_config)
    -- essentially avoid turning on typescript in a flow project
    vim.fn['coc#config']('tsserver.enableJavascript', 0)
    return true
end

function M.setup_hack()
    local hack_bin = vim.fn.exepath('hh_client')

    if hack_bin == '' then
        return nil
    end

    local hack_config = {
        ['command'] = hack_bin,
        ['args'] = { 'lsp' },
        ['filetypes'] = { 'php' },
        ['initializationOptions'] = {},
        ['requireRootPattern'] = 0,
        ['settings'] = {},
        ['rootPatterns'] = { '.hhconfig' }
    }
    vim.fn['coc#config']('languageserver.hack', hack_config)
end

function M.setup_mappings()
    vim.api.nvim_set_keymap(
        'n',
        '<leader>t',
        ':lua require("antonk52.coc").show_documentation()<cr>:echo<cr>',
        {noremap = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        'J',
        'coc#float#has_float() == 1 ? coc#float#scroll(1) : "J"',
        {noremap = true, expr = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        'K',
        ':lua require("antonk52.coc").show_documentation()<cr>:echo<cr>',
        {noremap = true}
    )
    vim.api.nvim_set_keymap(
        'n',
        '<leader>R',
        ':silent CocRestart<CR>',
        {noremap = true}
    )

    local mappings = {
        ['gd'] = 'definition',
        ['gy'] = 'type-definition',
        ['gi'] = 'implementation',
        ['gr'] = 'references',
        ['<leader>['] = 'diagnostic-prev',
        ['<leader>]'] = 'diagnostic-next',
        ['<leader>r'] = 'rename'
    }
    for mapping,action in pairs(mappings) do
        vim.api.nvim_set_keymap(
            'n',
            mapping,
            '<Plug>(coc-'..action..')',
            {silent = true}
        )
    end
end

function M.setup_commands()
    vim.cmd([[
        redraw!
        autocmd CursorHold * silent call CocActionAsync('highlight')
        command! Prettier call CocAction('runCommand', 'prettier.formatFile')
        " useful in untyped utilitarian corners in flow projects, sigh
        command! CocTsserverForceEnable call coc#config('tsserver.enableJavascript', 1)
        command! CocTsserverForceDisable call coc#config('tsserver.enableJavascript', 0)
    ]])
end

function M.setup()
    vim.g.coc_global_extensions = {
        'coc-css',
        'coc-cssmodules',
        'coc-eslint',
        'coc-json',
        'coc-lua',
        'coc-prettier',
        'coc-rust-analyzer',
        'coc-stylelintplus',
        'coc-tsserver',
    }

    vim.g.coc_filetype_map = {
        ['javascript.jest'] = 'javascript',
        ['javascript.jsx.jest'] = 'javascript.jsx',
        ['typescript.jest'] = 'typescript',
        ['typescript.tsx.jest'] = 'typescript.tsx',
    }

    M.setup_mappings()
    M.setup_commands()
    M.setup_flow()
    M.setup_hack()
    M.setup_eslint()
    -- lazy coc settings require restarting coc to pickup newer configuration
    vim.fn['coc#client#restart_all']()
end

function M.show_documentation()
    if vim.fn["coc#float#has_float"]() == 1 then
        vim.fn["coc#float#scroll"](0)
        return nil
    end
    if vim.o.filetype == 'vim' or vim.o.filetype == 'help' then
        vim.cmd('h '..vim.fn.expand('<cword>'))
    else
        vim.cmd('call CocAction("doHover")')
    end
end

return M
