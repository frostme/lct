-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Encoding
vim.opt.encoding = "utf-8"
vim.g.lazyvim_pickers = "telescope"

-- Backup settings
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Performance
vim.opt.updatetime = 300

---- UI settings
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.hlsearch = true
vim.opt.guifont = "Inconsolata Nerd Font:h18"
vim.opt.background = "dark"
vim.opt.number = true

-- Window size (for GUI Neovim like Neovide)
--vim.opt.lines = 999
--vim.opt.columns = 9999

---- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- File handling
vim.opt.autoread = true

-- Viminfo/Shada
vim.opt.viminfo:prepend("h")
vim.opt.shada:prepend("h")

vim.g.prism_colorschemes = {
  "Benokai",
  "SlateDark",
  "everforest",
  "moonfly",
  "night-owl",
  "nightfly",
  "kanagawa",
  "onedark",
  "nightfox",
  "tokyonight",
}

vim.g.lazyvim_prettier_needs_config = true

-- Better root detection for monorepos
-- LazyVim uses this to decide where to run formatters/linters and which node_modules to use.
vim.g.root_spec = {
  -- Common monorepo roots
  "pnpm-workspace.yaml",
  "turbo.json",
  "nx.json",

  -- JS project roots
  "package.json",

  -- VCS fallback
  ".git",
}

-- Disable all animations
vim.g.neovide_cursor_animation_length = 0
vim.g.neovide_cursor_trail_size = 0
vim.g.neovide_scroll_animation_length = 0
vim.g.neovide_cursor_animate_command_line = false
vim.g.neovide_cursor_animate_in_insert_mode = false

-- AI Setting
-- vim.g.copilot_no_tab_map = true
-- vim.keymap.set('i', '<S-Tab>', 'copilot#Accept("\\<S-Tab>")', { expr = true, replace_keycodes = false })
