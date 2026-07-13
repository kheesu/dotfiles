-- Treesitter — better syntax highlighting & indentation.
-- Add languages to ensure_installed as you need them.
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = { "lua", "c", "cpp", "python", "bash", "json", "markdown" },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}
