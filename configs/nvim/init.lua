-- =============================================================================
--  BOOTSTRAP: LAZY.NVIM (Auto-install Plugin Manager)
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
--  PLUGIN SETUP
-- =============================================================================
require("lazy").setup({

	-- 1. THE THEME (Fixed)
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- Load this before everything else
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- latte, frappe, macchiato, mocha
				transparent_background = false, -- Set true if you want your wallpaper to show
				term_colors = true,
			})
			-- Apply the colorscheme HERE, inside the config, to prevent errors
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- 2. FILE EXPLORER (Neo-tree)
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<leader>e", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
		},
	},

	-- 3. FUZZY FINDER (Telescope) - Like Ctrl+P in VSCode
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.6",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find Text" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffer" },
		},
	},

	-- 4. SYNTAX HIGHLIGHTING (Treesitter)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "c", "lua", "vim", "vimdoc", "python", "javascript", "bash" },
				highlight = { enable = true },
			})
		end,
	},

	-- 5. STATUS LINE (Lualine)
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({ options = { theme = "catppuccin" } })
		end,
	},

	-- 6. AUTOPAIRS (Auto close brackets)
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},
})

-- =============================================================================
--  SENSIBLE DEFAULTS
-- =============================================================================
vim.g.mapleader = " " -- Set Space as Leader Key
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers (great for jumps)
vim.opt.mouse = "a" -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard
vim.opt.breakindent = true -- Nice wrapping
vim.opt.undofile = true -- Save undo history to disk
vim.opt.ignorecase = true -- Case insensitive searching
vim.opt.smartcase = true -- ...unless you type a capital
vim.opt.updatetime = 250 -- Faster completion updates
vim.opt.timeoutlen = 300 -- Faster key combos

-- =============================================================================
--  KEYMAPS
-- =============================================================================
-- Clear search highlights with <Esc>
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Save file with Ctrl+S
vim.keymap.set("n", "<C-s>", ":w<CR>")
