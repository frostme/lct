local term = require("floatty").setup({
  window = {
    row = function()
      return vim.o.lines - 11
    end,
    width = 1.0,
    height = 8,
  },
})

local lazygit = require("floatty").setup({
  cmd = "lazygit",
  id = vim.fn.getcwd, -- Use the current working directory as the float's ID
})

return {
  {
    "<C-t>",
    function()
      term.toggle()
    end,
    desc = "Toggle terminal",
    mode = { "n", "t" },
  },
  {
    "<C-g>",
    function()
      lazygit.toggle()
    end,
    desc = "Toggle lazygit",
    mode = { "n", "t" },
  },
}
