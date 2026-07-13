-- Catppuccin Mocha — matches the kitty/i3/rofi themes elsewhere in the repo.
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- load before other plugins so nothing flashes unthemed
    config = function()
        require("catppuccin").setup({ flavour = "mocha" })
        vim.cmd.colorscheme("catppuccin")
    end,
}
