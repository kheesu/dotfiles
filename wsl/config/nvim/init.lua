-- ============================================================================
--  init.lua — a minimal, hand-rolled Neovim config (NOT a distro).
--  Structure: this file holds core options + keymaps, then bootstraps
--  lazy.nvim which loads everything under lua/plugins/.
--  Grow it by dropping new files in lua/plugins/ that return a plugin spec.
-- ============================================================================

-- Leader must be set before lazy loads so plugin keymaps pick it up.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Options ─────────────────────────────────────────────────────────────────
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"   -- share yank with the system clipboard
opt.breakindent = true
opt.undofile = true             -- persistent undo across sessions
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.inccommand = "split"        -- live preview of :substitute
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true

-- Indentation: 4 spaces, no tabs (override per-filetype later if needed).
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

-- ── Core keymaps ────────────────────────────────────────────────────────────
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")           -- clear search highlight
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

-- Window navigation with Ctrl+hjkl (matches the i3/tmux muscle memory).
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Move selected lines up/down.
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- ── Bootstrap lazy.nvim ─────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Loads every spec returned from files in lua/plugins/.
require("lazy").setup("plugins", {
    change_detection = { notify = false },
})
