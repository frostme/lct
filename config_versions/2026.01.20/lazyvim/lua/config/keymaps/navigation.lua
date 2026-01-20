return {
  -- Custom command to move cursor to specific column
  {
    "<localleader>l",
    ":Ln ",
    silent = false,
    desc = "Move to specific column",
  },

  -- Buffer navigation
  {
    "<localleader><Right>",
    ":bnext<CR>",
    desc = "Next buffer",
  },
  {
    "<localleader><Left>",
    ":bprevious<CR>",
    desc = "Previous buffer",
  },

  -- Window navigation
  {
    "<localleader><localleader><Right>",
    "<C-W>l",
    desc = "Move to right window",
  },
  {
    "<localleader><localleader><Left>",
    "<C-W>h",
    desc = "Move to left window",
  },
  {
    "<localleader><localleader><Up>",
    "<C-W>k",
    desc = "Move to upper window",
  },
  {
    "<localleader><localleader><Down>",
    "<C-W>j",
    desc = "Move to lower window",
  },

  -- Command + Right: End of line
  {
    "<D-Right>",
    "$",
    desc = "Move to end of line",
    mode = { "n", "v" },
  },
  {
    "<D-Right>",
    "<End>",
    desc = "Move to end of line",
    mode = "i",
  },

  -- Command + Left: Beginning of line
  {
    "<D-Left>",
    "^",
    desc = "Move to beginning of line",
    mode = { "n", "v" },
  },
  {
    "<D-Left>",
    "<Home>",
    desc = "Move to beginning of line",
    mode = "i",
  },
}
