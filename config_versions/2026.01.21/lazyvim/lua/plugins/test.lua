return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-plenary",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "marilari88/neotest-vitest",
      "adrigzr/neotest-mocha",
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-python",
      "arthur944/neotest-bun",
    },
    opts = function()
      return {
        output = {
          open_on_run = true,
        },
        projects = {
          ["~/code/rocketmoney/packages/web"] = {
            adapters = {
              require("neotest-jest")({
                jestCommand = "pnpm test:integration",
                env = { SKIP_DB_MIGRATION = 1 },
                isTestFile = function(file_path)
                  if not file_path then
                    return false
                  end

                  -- normalize path separators just in case
                  local p = file_path:gsub("\\", "/")

                  -- Equivalent intent to: /\/__tests__\/.+(\.|-)itest\.[jt]sx?$/
                  -- Explanation:
                  --   /__tests__/     -> "/__tests__/"
                  --   .+              -> ".+"
                  --   (\.|-)itest      -> "[%-%.]itest"  (either '-' or '.')
                  --   \.[jt]sx?$       -> "%.[jt]sx?$"   ('.' then j or t, then s, optional x, end of string)
                  return p:match("/__tests__/.+[%-%.]itest%.[jt]sx?$") ~= nil
                end,
              }),
            },
          },
        },
        adapters = {
          -- "neotest-plenary",
          -- "neotest-vitest",
          -- "neotest-mocha",
          -- "neotest-python",
          -- "neotest-bun",
          -- "neotest-jest",
        },
      }
    end,
  },
}
