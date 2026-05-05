return {
  -- icons
  {
    "nvim-tree/nvim-web-devicons"
  },
  -- color picker
  {
    "uga-rosa/ccc.nvim",
    config = function()
      require("ccc").setup({})
    end,
    event = "VeryLazy",
  },
  {
    "glepnir/dashboard-nvim",
    config = function ()
      require("config.dashboard")
    end
  }
}
