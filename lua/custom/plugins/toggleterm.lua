return {
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = {
    direction = 'float',
    keys = {
      {
        '<leader>G',
        function()
          local Terminal = require('toggleterm.terminal').Terminal
          local lazygit = Terminal:new { cmd = 'lazygit', hidden = true }
          lazygit:toggle()
        end,
        --        '<cmd>lua Lazygit_toggle()<CR>ToggleTerm size=40 dir=~/Desktop direction=horizontal<cr>',
        { desc = 'Open a horizontal terminal at the Desktop directory' },
      },
    },
  },
}
