return {
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    keys = {
      { "<leader>g", "<cmd>Neogit<cr>", desc = "Open Neogit" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufWinEnter", -- Lazy load when a buffer opens
    opts = {
      current_line_blame = true,
    },
  },
}
