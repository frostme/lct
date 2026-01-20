-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local wk = require("which-key")

wk.add(require("config.keymaps.utils"))
wk.add(require("config.keymaps.test"))
wk.add(require("config.keymaps.navigation"))
wk.add(require("config.keymaps.buffer"))
wk.add(require("config.keymaps.terminal"))
