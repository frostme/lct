return {
  {
    "<localleader>tn",
    '<cmd>lua require("neotest").run.run()<cr>',
    desc = "Run nearest test",
  },
  {

    "<localleader>tf",
    '<cmd>lua require("neotest").run.run(vim.fn.expand("%"))<cr>',
    desc = "Run current file tests",
  },
  {
    "<localleader>ts",
    '<cmd>lua require("neotest").run.stop()<cr>',
    desc = "Stop tests",
  },
  {
    "<localleader>to",
    '<cmd>lua require("neotest").output.open()<cr>',
    desc = "Open test output",
  },
  {
    "<localleader>tp",
    '<cmd>lua require("neotest").output_panel.toggle()<cr>',
    desc = "Toggle test output panel",
  },
  {
    "<localleader>tv",
    '<cmd>lua require("neotest").summary.toggle()<cr>',
    desc = "Toggle test summary",
  },
}
