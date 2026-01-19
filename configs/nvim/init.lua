-- ==========================================
--  Lazy.nvim Bootstrap (Single File Setup)
-- ==========================================

-- 1. Install Lazy.nvim if not present
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

-- 2. Basic Editor Settings (The "Must Haves")
vim.g.mapleader = " "             -- Set Leader key to Space
vim.g.maplocalleader = " "
vim.opt.number = true             -- Line numbers
vim.opt.relativenumber = true     -- Relative line numbers (better for j/k movements)
vim.opt.clipboard = "unnamedplus" -- Copy/Paste shares with System Clipboard

-- 3. Plugin Setup
require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        term_colors = true,
      })
    end
    vim.cmd.colorscheme "catppuccin"
  }
  -- Add your plugins here later. Example:
  -- "folke/tokyonight.nvim",
  -- "nvim-telescope/telescope.nvim",
})
