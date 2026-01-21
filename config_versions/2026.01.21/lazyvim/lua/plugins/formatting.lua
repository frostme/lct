return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Use local project binaries when available
      opts.formatters = opts.formatters or {}

      -- Prefer biome when present; fall back to prettier
      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        javascript = { "biome", "prettierd", "prettier" },
        javascriptreact = { "biome", "prettierd", "prettier" },
        typescript = { "biome", "prettierd", "prettier" },
        typescriptreact = { "biome", "prettierd", "prettier" },
        json = { "biome", "prettierd", "prettier" },
        jsonc = { "biome", "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        scss = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        markdown = { "prettierd", "prettier" },
        mdx = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        python = { "black" },
      })

      -- Make sure conform runs from the detected root (monorepo-aware)
      opts.cwd = function(_, ctx)
        return require("lazyvim.util").root.get({ buf = ctx.buf })
      end
    end,
  },
}
