-- ~/.config/nvim/init.lua

-- 防御性 DSR 警告过滤。
-- 注意：这个 wrap 抓不到 startup 时 _core/defaults.lua 发的那条
-- "Did not detect DSR response..."。--startuptime 测过：
--   037ms  require('vim._core.defaults')   ← defaults 在这里同步 vim.wait(100)
--   037ms  --cmd commands                  ← --cmd 也在 defaults 之后
--   ~367ms sourcing init.lua               ← 我们这条 wrap 挂上时为时已晚
-- 真正消除 startup 警告的办法是换响应 DSR 的终端（WezTerm/Alacritty/
-- Windows Terminal），或者直接到 nvim/runtime/lua/vim/_core/defaults.lua
-- 把那行 vim.notify 注释掉（每次升级 nvim 会被覆盖）。
-- 留着这层 wrap 是兜底：万一有别的代码路径之后又抛同样消息。
do
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
        if type(msg) == "string" and msg:find("Did not detect DSR response", 1, true) then
            return
        end
        return original_notify(msg, level, opts)
    end
end

local M = {}

function M.get_os()
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        return "windows"
    elseif vim.fn.has("mac") == 1 or vim.uv.os_uname().sysname == "Darwin" then
        return "macos"
    else
        return "linux"
    end
end

-- 用 current_os 避免遮蔽 Lua 标准库 os
local current_os = M.get_os()

-- ==========================================
-- 基础设置
-- ==========================================

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = true -- 持久化撤销历史，重启 nvim 还能 u 回去
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.termguicolors = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = ""
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 折叠设置
vim.opt.foldenable = true   -- 启用折叠
vim.opt.foldlevel = 99      -- 默认展开所有折叠
vim.opt.foldlevelstart = 99 -- 启动时展开
vim.opt.foldnestmax = 4     -- 最大嵌套层数

-- Treesitter 折叠：用 Neovim 原生 foldexpr（读取 parser 的 folds.scm），
-- 比 nvim-treesitter master 的 Vimscript 版 nvim_treesitter#foldexpr() 更稳。
-- 只在装了 parser 的 filetype 上开启 expr 折叠，避免无 parser buffer
-- 反复触发 foldexpr 兜底，污染 :messages。
vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
        if vim.treesitter.language.get_lang(args.match) then
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
    end,
})

-- 兜底 Neovim 0.12.x + nvim-treesitter master 的注入解析崩溃：
--   "vim/treesitter.lua:196: attempt to call method 'range' (a nil value)"
-- iter_matches() 偶尔给 capture 喂非 TSNode 值，后面 get_range 里
-- node:range 找不到方法 → 整个 highlighter / foldexpr / telescope previewer
-- 被这一条烂 capture 拖垮（异步路径冒在 vim.schedule callback，同步路径
-- 冒在 decoration provider 'start'）。
--
-- 关键：必须包 vim.treesitter.get_range 自己，而不是只包 LanguageTree._get_injection。
-- 因为 highlighter.lua 在主循环里直接调 get_range，根本不走 _get_injection；
-- _fold.lua 也直接调。只兜 _get_injection 漏掉这两条路。
do
    local ok, ts = pcall(require, "vim.treesitter")
    if ok and ts and ts.get_range then
        local orig_get_range = ts.get_range
        ts.get_range = function(node, source, metadata)
            local ok2, ret = pcall(orig_get_range, node, source, metadata)
            -- 出错就返回一个零范围：调用方继续跑（高亮/折叠跳过这一个 capture），
            -- 而不是整个 provider 抛异常出来弹窗。
            if not ok2 then return { 0, 0, 0, 0, 0, 0 } end
            return ret
        end
    end

    -- 防御性的第二层：连带把 LanguageTree._get_injection 也包上。
    -- get_range 已经兜了大头，这里只是兜万一别的注入流程抛非 get_range 的错。
    local ok_lt, LanguageTree = pcall(require, "vim.treesitter.languagetree")
    if ok_lt and LanguageTree and LanguageTree._get_injection then
        local orig = LanguageTree._get_injection
        LanguageTree._get_injection = function(self, match, metadata)
            local ok2, lang, combined, ranges = pcall(orig, self, match, metadata)
            if not ok2 then return nil, false, {} end
            return lang, combined, ranges
        end
    end
end

-- ==========================================
-- 护眼优化设置
-- =========================================

-- 降低对比度（配合柔和主题）
vim.opt.conceallevel = 0

-- 自定义 highlight 必须在 ColorScheme 之后跑，否则 `colorscheme catppuccin`
-- 触发的 `hi clear` 会把它们全擦掉。blend 字段对普通 highlight 不起作用
-- （只对 winblend/popup 生效），去掉。
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a3a" }) -- 光标行柔和
        vim.api.nvim_set_hl(0, "LineNr", { fg = "#6e6a86" })     -- 灰色行号
        vim.api.nvim_set_hl(0, "Visual", { bg = "#3e3e5e" })     -- 选中区域柔和
    end,
})

-- 减少闪烁
vim.opt.belloff = "all"

-- 平滑滚动（GUI）
if vim.g.neovide then
    vim.g.neovide_scroll_animation_length = 0.3
    vim.g.neovide_cursor_animation_length = 0.05
end

-- ==========================================
-- 快捷键映射
-- ==========================================
-- init.lua (Lua 配置)
-- 按 Esc 退出 terminal 模式
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true })
-- 在 insert 模式下，将中文句号映射为英文点号
vim.keymap.set("i", "。", ".", { noremap = true })
vim.keymap.set("n", "<Leader>u", "<C-r>")
vim.keymap.set("n", "<leader>w", ":w<CR>", { noremap = true, silent = true, desc = "Save file" })
vim.keymap.set("i", "<D-r>", "<C-r>", { noremap = true, silent = true })
vim.keymap.set("v", "<D-c>", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "<D-v>", '"+p', { noremap = true, silent = true })
vim.keymap.set("i", "<D-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set("c", "<D-v>", "<C-r>+", { noremap = true, silent = true })
vim.keymap.set("v", "<D-v>", '"+P', { noremap = true, silent = true })
-- vim.keymap.set('n', '<D-a>', 'ggVG', { noremap = true, silent = true })
-- vim.keymap.set('n', '<D-s>', ':w<CR>', { noremap = true, silent = true })
-- vim.keymap.set('i', '<D-s>', '<Esc>:w<CR>a', { noremap = true, silent = true })
vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>qq", ":q<CR>", { noremap = true, silent = true, desc = "Quit" })
vim.keymap.set("n", "<leader>QQ", ":q!<CR>", { noremap = true, silent = true, desc = "Quit without saving" })
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { noremap = true, silent = true })
vim.keymap.set(
    "n",
    "<leader>y",
    "<cmd>Telescope neoclip<CR>",
    { noremap = true, silent = true, desc = "Clipboard history" }
)
vim.keymap.set(
    "n",
    "<leader>ym",
    "<cmd>Telescope macroscope<CR>",
    { noremap = true, silent = true, desc = "Macro history" }
)

-- ==========================================
-- Tab/Buffer 切换配置（推荐组合）
-- =========================================

-- 1. 切换 buffer：不映射 <Tab>，因为终端里 <Tab> ≡ <C-i>，
--    一旦映射就把跳转前进 <C-i> 彻底打死。用 <A-Left/Right>、<D-Left/Right>
--    或下面的 gt/gT 即可。
vim.keymap.set("n", "<A-Right>", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "<A-Left>", ":BufferLineCyclePrev<CR>", { silent = true })
vim.keymap.set("n", "<D-Right>", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "<D-Left>", ":BufferLineCyclePrev<CR>", { silent = true })

-- 2. macOS 风格（Command+数字）
for i = 1, 9 do
    vim.keymap.set("n", "<D-" .. i .. ">", ":BufferLineGoToBuffer " .. i .. "<CR>", { silent = true })
end

-- 3. 新建和关闭
vim.keymap.set("n", "<D-t>", ":tabnew<CR>", { silent = true })
vim.keymap.set("n", "<D-w>", ":bdelete<CR>", { silent = true })
vim.keymap.set("n", "<A-t>", ":tabnew<CR>", { silent = true })
vim.keymap.set("n", "<A-w>", ":bdelete<CR>", { silent = true })
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { silent = true, desc = "Delete buffer" })

-- 4. Telescope 快速选择
vim.keymap.set("n", "<C-b>", ":Telescope buffers<CR>", { silent = true })
vim.keymap.set("n", "<leader>bs", ":Telescope buffers<CR>", { silent = true, desc = "Buffer search" })

-- 5. 保留 Vim 原生风格作为备选
vim.keymap.set("n", "gt", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "gT", ":BufferLineCyclePrev<CR>", { silent = true })

-- ==========================================
-- 跳转与返回 - 完整配置
-- =========================================
vim.keymap.set("n", "<D-[>", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<D-]>", "<C-i>", { desc = "Jump forward" })
vim.keymap.set("n", "<leader>jh", ":jumps<CR>", { desc = "Jump history" })
vim.keymap.set("n", "<leader>k", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<leader>j", "<C-i>", { desc = "Jump forward" })

-- ==========================================
-- 字体配置 - 完整版
-- =========================================

if vim.g.neovide then
    -- Neovide 最佳配置
    -- vim.o.guifont = "JetBrainsMono Nerd Font:h18"
    vim.o.guifont = "Fira Code:h18"
    vim.opt.linespace = 2
    vim.g.neovide_font_ligatures = true

    -- 快捷键
    vim.keymap.set("n", "<D-=>", function()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1
    end)
    vim.keymap.set("n", "<D-->", function()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1
    end)
    vim.keymap.set("n", "<D-0>", function()
        vim.g.neovide_scale_factor = 1.0
    end)
elseif vim.g.vimr then
    -- VimR 配置
    vim.o.guifont = "SF Mono:h13"
else
    -- 终端提示
    vim.api.nvim_create_user_command("FontInfo", function()
        print("Change font in your terminal (iTerm2/Alacritty/Kitty settings)")
    end, {})
end

-- ==========================================
-- LSP 共享键位 + capabilities helper
-- 必须提前到 lazy.setup 之前定义，roslyn.nvim 的 config 闭包要捕获。
-- ==========================================

local function setup_lsp_keymaps(bufnr)
    local opts = { buffer = bufnr, noremap = true, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    -- 0.11+ goto_prev/goto_next 已 deprecate，用 jump
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
end

-- LSP 共享 capabilities：在默认 protocol capabilities 上叠加 blink.cmp 提供
-- 的补全能力，让 server 知道客户端支持 snippet resolve、commit characters、
-- additional text edits 等。pcall 兜底 blink 没装的情况（理论上不会发生，
-- 但保留 fallback 让 LSP 仍可工作）。
local function get_lsp_capabilities()
    local caps = vim.lsp.protocol.make_client_capabilities()
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
        caps = blink.get_lsp_capabilities(caps)
    end
    return caps
end

-- 插件管理器: lazy.nvim
-- ==========================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- ==========================================
    -- conform.nvim - 轻量级格式化插件
    -- ==========================================
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local conform = require("conform")
            local format_on_save = false
            if current_os == "macos" then
                format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = false,
                }
            end
            conform.setup({
                formatters_by_ft = {
                    lua = { "stylua" },
                    python = { "isort", "black" },
                    -- 修复：去掉嵌套 {}，添加 stop_after_first = true
                    javascript = { "prettierd", "prettier", stop_after_first = true },
                    typescript = { "prettierd", "prettier", stop_after_first = true },
                    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
                    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
                    css = { "prettierd", "prettier", stop_after_first = true },
                    html = { "prettierd", "prettier", stop_after_first = true },
                    json = { "prettierd", "prettier", stop_after_first = true },
                    yaml = { "prettierd", "prettier", stop_after_first = true },
                    markdown = { "prettierd", "prettier", stop_after_first = true },
                    sh = { "shfmt" },
                    bash = { "shfmt" },
                    cs = { "csharpier" },
                },
                format_on_save = format_on_save,
                notify_on_error = true,
            })
        end,
    },

    {
        "AckslD/nvim-neoclip.lua",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "kkharji/sqlite.lua",           module = "sqlite" },
        },
        config = function()
            require("neoclip").setup({
                history = 1000,
                enable_persistent_history = true,
                length_limit = 1048576,
                continuous_sync = false,
                db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3",
                filter = nil,
                preview = true,
                prompt = nil,
                default_register = { '"', "+", "*" },
                default_register_macros = "q",
                enable_macro_history = true,
                content_spec_column = false,
                disable_keycodes_parsing = false,
                on_select = {
                    move_to_front = false,
                    close_telescope = true,
                },
                on_paste = {
                    set_reg = false,
                    move_to_front = false,
                    close_telescope = true,
                },
                on_replay = {
                    set_reg = false,
                    move_to_front = false,
                    close_telescope = true,
                },
                on_custom_action = {
                    close_telescope = true,
                },
                keys = {
                    telescope = {
                        i = {
                            select = "<cr>",
                            paste = "<c-p>",
                            paste_behind = "<c-k>",
                            replay = "<c-q>",
                            delete = "<c-d>",
                            edit = "<c-e>",
                            custom = {},
                        },
                        n = {
                            select = "<cr>",
                            paste = "p",
                            paste_behind = "P",
                            replay = "q",
                            delete = "d",
                            edit = "e",
                            custom = {},
                        },
                    },
                },
            })
            require("telescope").load_extension("neoclip")
        end,
    },
    -- 主题（备选，按需切换）
    {
        "folke/tokyonight.nvim",
        lazy = true,
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = false,
                terminal_colors = true,
            })
        end,
    },
    -- 启动主题：Catppuccin
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- 可选: latte, frappe, macchiato, mocha
                transparent_background = false,
            })
            vim.cmd([[colorscheme catppuccin]])
        end,
    },
    -- 备选 1：Rose Pine
    { "rose-pine/neovim",         name = "rose-pine", lazy = true },

    -- 备选 2：Kanagawa
    { "rebelot/kanagawa.nvim",    lazy = true },

    -- 备选 3：Everforest（极柔和绿色）
    { "sainnhe/everforest",       lazy = true },

    -- 备选 4：Gruvbox Material
    { "sainnhe/gruvbox-material", lazy = true },

    -- 状态栏
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto", -- 跟随当前 colorscheme 自动派生
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                },
            })
        end,
    },

    -- 缓冲区标签
    {
        "akinsho/bufferline.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    separator_style = "slant",
                    always_show_bufferline = true,
                },
            })
        end,
    },

    -- 文件树
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                sort_by = "case_sensitive",
                view = { width = 30 },
                renderer = { group_empty = true },
                filters = { dotfiles = false },
            })
            vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
        end,
    },

    -- 模糊查找
    {
        "nvim-telescope/telescope.nvim",
        -- 跟 master：lazy-lock.json 已经替我们钉住具体 commit；老 tag 0.1.5 跟
        -- master 上的 plenary.nvim 容易踩 API 漂移。
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                -- Windows 上没现成 make，走 cmake；macOS/Linux 继续用 make。
                build = vim.fn.has("win32") == 1
                    and "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release"
                    .. " && cmake --build build --config Release"
                    .. " && cmake --install build --prefix build"
                    or "make",
            },
        },
        config = function()
            -- 显式钉死 find_files 的 find_command，绕过 telescope 自动探测在
            -- Windows 上回退到 `where /r . *` 的坑（大目录或遇权限拒绝就抛异常，
            -- 看上去就是"打开 find_files 后查特定文件 nvim 报错"）。
            -- 顺序：fd > fdfind > rg > Windows cmd dir > POSIX find。
            local function detect_find_command()
                if vim.fn.executable("fd") == 1 then
                    return { "fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git" }
                elseif vim.fn.executable("fdfind") == 1 then
                    return { "fdfind", "--type", "f", "--hidden", "--follow", "--exclude", ".git" }
                elseif vim.fn.executable("rg") == 1 then
                    return { "rg", "--files", "--hidden", "--glob", "!.git" }
                elseif vim.fn.has("win32") == 1 then
                    -- /a-d 排除目录 /b 裸格式 /s 递归；stderr 重定向到 nul
                    -- 避免权限拒绝消息污染 stdout。
                    return { "cmd", "/c", "dir /a-d /b /s 2>nul" }
                else
                    return { "find", ".", "-type", "f" }
                end
            end

            require("telescope").setup({
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
                pickers = {
                    find_files = {
                        find_command = detect_find_command(),
                        hidden = true,
                    },
                },
            })
            require("telescope").load_extension("fzf")

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
        end,
    },

    -- ==========================================
    -- Treesitter - 使用 master 分支（向后兼容）
    -- ==========================================

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master", -- 锁定 master 分支，使用旧版 API
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua",
                    "python",
                    "javascript",
                    "typescript",
                    "html",
                    "css",
                    "json",
                    "markdown",
                    "bash",
                    "vim",
                    "vimdoc",
                    "c_sharp",
                },
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
            })
        end,
    },

    -- 自动补全
    {
        "saghen/blink.cmp",
        dependencies = "rafamadriz/friendly-snippets",
        version = "*",
        config = function()
            require("blink.cmp").setup({
                keymap = {
                    preset = "default",
                    ["<Tab>"] = { "select_next", "fallback" },
                    ["<S-Tab>"] = { "select_prev", "fallback" },
                    ["<CR>"] = { "accept", "fallback" },
                },
                appearance = {
                    use_nvim_cmp_as_default = true,
                    nerd_font_variant = "mono",
                },
                sources = {
                    default = { "lsp", "path", "snippets", "buffer" },
                },
            })
        end,
    },

    -- 1. 首先加载 Mason 并配置 registry
    {
        "williamboman/mason.nvim",
        lazy = false,    -- 启动时加载，让 mason/bin 进 PATH（LSP 启动要找二进制）
        priority = 1000, -- 在其他插件之前
        config = function()
            require("mason").setup({
                registries = {
                    "github:mason-org/mason-registry",
                    "github:Crashdummyy/mason-registry", -- 包含 Roslyn
                },
            })
        end,
    },

    -- 2. Mason 工具安装器（可选但推荐）
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        lazy = false, -- 启动时跑 ensure_installed 检查
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-tool-installer").setup({
                ensure_installed = {
                    -- ===== LSP servers =====
                    "lua-language-server",            -- lua_ls
                    "pyright",                        -- python
                    "typescript-language-server",     -- ts_ls
                    "bash-language-server",           -- bashls
                    "html-lsp",                       -- vscode-html-language-server
                    "css-lsp",                        -- vscode-css-language-server
                    "json-lsp",                       -- vscode-json-language-server
                    "roslyn",                         -- C#（Crashdummyy registry）

                    -- ===== Formatters =====
                    "stylua",                         -- Lua
                    "isort",                          -- Python imports
                    "black",                          -- Python
                    "prettierd",                      -- JS/TS/CSS/HTML/JSON/YAML/MD（已内置 prettier，不再单独装）
                    "shfmt",                          -- sh/bash
                    "csharpier",                      -- C#

                    -- ===== Debuggers =====
                    "netcoredbg",                     -- C#
                },
                auto_update = true,
                run_on_start = true,
            })
        end,
    },

    -- ==========================================
    -- C# / .NET 支持
    -- ==========================================

    -- Roslyn LSP 壳（处理非标准启动协议 + sln/csproj 自动发现）
    {
        "seblyng/roslyn.nvim",
        ft = "cs",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("roslyn").setup({
                config = {
                    capabilities = get_lsp_capabilities(),
                    on_attach = function(client, bufnr)
                        setup_lsp_keymaps(bufnr)
                    end,
                    settings = {
                        ["csharp|inlay_hints"] = {
                            csharp_enable_inlay_hints_for_implicit_object_creation = true,
                            csharp_enable_inlay_hints_for_implicit_variable_types = true,
                            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
                            csharp_enable_inlay_hints_for_types = true,
                        },
                        ["csharp|code_lens"] = {
                            dotnet_enable_references_code_lens = true,
                        },
                    },
                },
            })
        end,
    },

    -- 调试：DAP + UI + virtual text + C# 适配
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            { "rcarriga/nvim-dap-ui",            dependencies = { "nvim-neotest/nvim-nio" } },
            { "theHamsta/nvim-dap-virtual-text" },
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            dapui.setup()
            require("nvim-dap-virtual-text").setup()

            -- UI 自动开关
            dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
            dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
            dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

            -- C# 适配器（netcoredbg 由 Mason 安装，shim 在 PATH 上；exepath 跨平台解析）
            dap.adapters.coreclr = {
                type = "executable",
                command = vim.fn.exepath("netcoredbg"),
                args = { "--interpreter=vscode" },
            }

            dap.configurations.cs = {
                {
                    type = "coreclr",
                    name = "launch - netcoredbg",
                    request = "launch",
                    program = function()
                        return vim.fn.input(
                            "Path to dll: ",
                            vim.fn.getcwd() .. "/bin/Debug/",
                            "file"
                        )
                    end,
                },
            }

            -- 调试键位
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
            vim.keymap.set("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Condition: "))
            end, { desc = "DAP conditional breakpoint" })
            vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue / start" })
            vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
            vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
            vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
            vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL" })
            vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "DAP terminate" })
            vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
        end,
    },

    -- 自动括号
    {
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup({})
        end,
    },

    -- 快速注释
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    -- Git 集成
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "+" },
                    change = { text = "~" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                },
            })
        end,
    },

    -- 快捷键提示
    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup()
        end,
    },

    -- 缩进线
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require("ibl").setup()
        end,
    },
}, {
    install = { colorscheme = { "catppuccin" } },
    checker = { enabled = true, notify = false },
})

-- ==========================================
-- Neovim 0.11+ 原生 LSP 配置
-- ==========================================
-- 注：setup_lsp_keymaps 在 lazy.setup 之前定义（roslyn.nvim 的 config 闭包需要它）

vim.lsp.config("*", {
    capabilities = get_lsp_capabilities(),
    on_attach = function(client, bufnr)
        setup_lsp_keymaps(bufnr)
        if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_buf_create_user_command(bufnr, "LspFormat", function()
                vim.lsp.buf.format({ async = true })
            end, { desc = "Format document with LSP" })
        end
    end,
})

-- 语言服务器配置
vim.lsp.config.lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
                -- 只把 VIMRUNTIME 喂给 lua_ls，避免加载整个 runtimepath
                -- （含所有插件源码）导致启动慢、内存几百 MB。
                -- 想要 plugin API 类型补全可换 lazydev.nvim 按需注入。
                library = { vim.env.VIMRUNTIME },
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
}

vim.lsp.config.pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
            },
        },
    },
}

vim.lsp.config.ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
}

vim.lsp.config.html = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html" },
    root_markers = { ".git" },
}

vim.lsp.config.cssls = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { ".git" },
}

vim.lsp.config.jsonls = {
    cmd = { "vscode-json-language-server", "--stdio" },
    filetypes = { "json", "jsonc" },
    root_markers = { ".git" },
}

vim.lsp.config.bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "bash", "sh" },
    root_markers = { ".git" },
}

vim.lsp.enable({ "lua_ls", "pyright", "ts_ls", "html", "cssls", "jsonls", "bashls" })

-- 诊断配置
-- - source = true 取代 deprecated 的 "always"（0.10+）
-- - signs 直接在 config 里写 text 表，按 severity 索引；
--   不再用 sign_define + DiagnosticSign<Type> 那套老 API（0.10+ 已 deprecate）
vim.diagnostic.config({
    virtual_text = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN]  = " ",
            [vim.diagnostic.severity.HINT]  = " ",
            [vim.diagnostic.severity.INFO]  = " ",
        },
    },
})

-- 自动命令
vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*",
    command = "startinsert",
})

-- 不在末尾 print "配置加载完成"。原因：startup 时如果 defaults.lua 已经
-- 因为终端不响应 DSR emit 了一条警告，再叠这条 print 就总共 ≥ 2 行
-- echo，触发 hit-Enter prompt（"tip 界面"），每次打开 nvim 都要按一下键。
-- 现在只剩 defaults.lua 那一条（_truncate=true 一行就装下），不再触发。
