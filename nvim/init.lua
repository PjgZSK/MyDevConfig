-- ~/.config/nvim/init.lua

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
vim.opt.foldenable = true -- 启用折叠
vim.opt.foldlevel = 99 -- 默认展开所有折叠
vim.opt.foldlevelstart = 99 -- 启动时展开
vim.opt.foldnestmax = 4 -- 最大嵌套层数

-- Treesitter 折叠（需要安装 nvim-treesitter）
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- ==========================================
-- 护眼优化设置
-- =========================================

-- 降低对比度（配合柔和主题）
vim.opt.conceallevel = 0

-- 光标行柔和高亮
vim.opt.cursorline = true
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a3a", blend = 20 })

-- 行号柔和颜色
vim.api.nvim_set_hl(0, "LineNr", { fg = "#6e6a86" }) -- 灰色行号

-- 选中区域柔和
vim.api.nvim_set_hl(0, "Visual", { bg = "#3e3e5e", blend = 30 })

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
-- 在 insert 模式下，将中文句号映射为英文点号
vim.keymap.set("i", "。", ".", { noremap = true })
vim.keymap.set("n", "<Leader>u", "<C-r>")
vim.keymap.set("n", "<Esc>", "<Esc>:w<CR>", { noremap = true, silent = true })
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
vim.keymap.set("n", "<leader>q", ":q<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>Q", ":q!<CR>", { noremap = true, silent = true })
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

-- 1. 使用 Tab 键快速循环（最常用）
vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true })

-- 2. macOS 风格（Command+数字）
for i = 1, 9 do
	vim.keymap.set("n", "<D-" .. i .. ">", ":BufferLineGoToBuffer " .. i .. "<CR>", { silent = true })
end

-- 3. 新建和关闭
vim.keymap.set("n", "<D-t>", ":tabnew<CR>", { silent = true })
vim.keymap.set("n", "<D-w>", ":bdelete<CR>", { silent = true })

-- 4. Telescope 快速选择
vim.keymap.set("n", "<C-b>", ":Telescope buffers<CR>", { silent = true })

-- 5. 保留 Vim 原生风格作为备选
vim.keymap.set("n", "gt", ":BufferLineCycleNext<CR>", { silent = true })
vim.keymap.set("n", "gT", ":BufferLineCyclePrev<CR>", { silent = true })

-- ==========================================
-- 跳转与返回 - 完整配置
-- =========================================
vim.keymap.set("n", "<D-[>", "<C-o>", { desc = "Jump back" })
vim.keymap.set("n", "<D-]>", "<C-i>", { desc = "Jump forward" })
vim.keymap.set("n", "<leader>jh", ":jumps<CR>", { desc = "Jump history" })

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

-- 插件管理器: lazy.nvim
-- ==========================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
				},

				format_on_save = {
					timeout_ms = 500,
					lsp_fallback = true,
				},

				notify_on_error = true,
			})

			vim.keymap.set({ "n", "v" }, "<leader>f", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 500,
				})
			end, { desc = "Format file or range" })
		end,
	},

	{
		"AckslD/nvim-neoclip.lua",
		dependencies = {
			{ "nvim-telescope/telescope.nvim" },
			{ "kkharji/sqlite.lua", module = "sqlite" },
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
	-- 主题
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "night",
				transparent = false,
				terminal_colors = true,
			})
			vim.cmd([[colorscheme tokyonight]])
		end,
	},
	-- 选项 2：Catppuccin（非常流行）
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
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },

	-- 备选 2：Kanagawa
	{ "rebelot/kanagawa.nvim", lazy = true },

	-- 备选 3：Everforest（极柔和绿色）
	{ "sainnhe/everforest", lazy = true },

	-- 备选 4：Gruvbox Material
	{ "sainnhe/gruvbox-material", lazy = true },

	-- 状态栏
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "tokyonight",
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
		tag = "0.1.5",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
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
		priority = 1000, -- 确保最先加载
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
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"roslyn", -- C# LSP
					"netcoredbg", -- 调试器
					"csharpier", -- 格式化
				},
				auto_update = true,
				run_on_start = true,
			})
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
	install = { colorscheme = { "tokyonight" } },
	checker = { enabled = true, notify = false },
})

-- ==========================================
-- Neovim 0.11+ 原生 LSP 配置
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
	vim.keymap.set("n", "<leader>f", function()
		vim.lsp.buf.format({ async = true })
	end, opts)
	vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
	vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
	vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
end

vim.lsp.config("*", {
	capabilities = {
		textDocument = {
			completion = {
				dynamicRegistration = false,
				completionItem = {
					snippetSupport = true,
					commitCharactersSupport = true,
					documentationFormat = { "markdown", "plaintext" },
					deprecatedSupport = true,
					preselectSupport = true,
				},
			},
		},
	},
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
				library = vim.api.nvim_get_runtime_file("", true),
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
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
	},
})

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- 自动命令
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	command = "startinsert",
})

print("Neovim 配置加载完成! 🚀")
