-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)
--
-- HEY ME - I started modifying this for Rust

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    -- Mason should already be installed, this just seems more thorough
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add Rust debugger?
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local mason_registry = require 'mason-registry'

    local function get_package_name()
      local current_dir = vim.fn.expand '%:p:h' -- Get the directory of the current file

      while true do
        local cargo_toml_path = current_dir .. '/Cargo.toml'
        local file = io.open(cargo_toml_path, 'r')

        if file then
          local content = file:read '*a'
          file:close()
          local package_match = content:match '^%s*%[package%]'
          if package_match then
            local name_match = content:match 'name%s*=%s*"([^"]+)"'
            if name_match then
              return name_match
            end
          end
        end

        local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
        if parent_dir == current_dir then -- Reached the root without finding
          break
        end
        current_dir = parent_dir
      end

      return nil -- Couldn't find a package Cargo.toml
    end

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'codelldb',
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Configure the dap adapter for codelldb
    -- Used Google Gemini for this a lot.
    local codelldb_path = mason_registry.get_package('codelldb'):get_install_path() .. '/codelldb'

    dap.adapters.lldb = {
      type = 'executable',
      command = codelldb_path,
      name = 'codelldb',
    }

    dap.configurations.rust = {
      {
        name = 'Debug Unit Test',
        type = 'lldb', -- Now referring to codelldb
        request = 'launch',
        program = function()
          local package_name = get_package_name()
          if package_name then
            return './target/debug/' .. package_name --:gsub('-', '_') -- .. '-' .. string.sub(vim.fs.basename(vim.api.nvim_buf_get_name(0)), 1, 8)
          else
            return nil
          end
        end,
        args = { '--test', vim.fs.basename(vim.api.nvim_buf_get_name(0)):gsub('.rs', ''), '--exact', '-Z unstable-options', '--show-output' },
        cwd = '${workspaceFolder}',
        --        initCommands = {
        --          'break-style regex',
        --          'settings set target.source-map-style auto',
        --          'settings set target.process.stop-on-sharedlibrary-events true',
        --        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
