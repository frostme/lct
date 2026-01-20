return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")

      -- Run eslint from the project (monorepo) root
      local root = function(bufnr)
        return require("lazyvim.util").root.get({ buf = bufnr })
      end

      -- Configure eslint_d if you use it; otherwise use eslint
      -- You can keep both with eslint_d first for speed.
      lint.linters_by_ft = vim.tbl_deep_extend("force", lint.linters_by_ft or {}, {
        javascript = { "eslint_d", "eslint" },
        javascriptreact = { "eslint_d", "eslint" },
        typescript = { "eslint_d", "eslint" },
        typescriptreact = { "eslint_d", "eslint" },
        python = { "pylint" },
      })

      -- Ensure cwd is correct for monorepos
      lint.linters.eslint_d = vim.tbl_deep_extend("force", lint.linters.eslint_d or {}, {
        cwd = root,
      })
      lint.linters.eslint = vim.tbl_deep_extend("force", lint.linters.eslint or {}, {
        cwd = root,
      })
      lint.linters.pylint = vim.tbl_deep_extend("force", lint.linters.pylint or {}, {
        cwd = function(ctx)
          return smart_root(ctx.bufnr)
        end,
      })

      -- Auto-lint on common events
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
}
