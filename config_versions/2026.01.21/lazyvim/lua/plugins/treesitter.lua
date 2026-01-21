return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add jsdoc to ensure_installed
      vim.list_extend(opts.ensure_installed, {
        "jsdoc",
      })
    end,
  },
}
