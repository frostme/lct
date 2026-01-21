return {
  -- Save and quit
  {
    "<localleader>w",
    ":w<CR>",
    desc = "Save file",
  },
  {
    "<localleader>q",
    ":bp<bar>bd#<CR>",
    desc = "Close current buffer",
  },
  {
    "<localleader><localleader>q",
    ":q<CR>",
    desc = "Close current window",
  },
  -- Formatting with Conform.nvim
  {
    "<localleader>p",
    function()
      require("conform").format({ async = true })
    end,
    desc = "Format file with Conform",
  },

  -- Copy/Paste using CMD on MacOS
  {
    "<D-c>",
    '"+y',
    mode = "v",
    cond = function()
      return vim.fn.has("macunix") == 1
    end,
    desc = "Copy to system clipboard",
  },
  {
    "<D-v>",
    '"+p',
    mode = "n",
    cond = function()
      return vim.fn.has("macunix") == 1
    end,
    desc = "Paste from system clipboard",
  },
  {
    "<D-v>",
    '"+p',
    mode = "v",
    cond = function()
      return vim.fn.has("macunix") == 1
    end,
    desc = "Paste from system clipboard",
  },

  {
    "<localleader>f",
    ":e %:h/",
    desc = "Open file in current buffer's directory",
  },
}
