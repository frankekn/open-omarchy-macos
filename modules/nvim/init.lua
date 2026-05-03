vim.g.mapleader = ' '

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.pack.add({
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/MunifTanjim/nui.nvim' },
  { src = 'https://github.com/nvim-tree/nvim-web-devicons' },
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = 'v3.x' },
})

require('neo-tree').setup({
  close_if_last_window = false,
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
    filtered_items = {
      visible = true,
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
  window = {
    width = 34,
  },
})

vim.keymap.set('n', '<leader>e', ':Neotree toggle left<CR>', { silent = true })

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if vim.fn.argc() > 1 then
      return
    end

    local target = vim.fn.argc() == 1 and vim.fn.argv(0) or vim.fn.getcwd()
    if vim.fn.isdirectory(target) == 1 then
      vim.cmd('cd ' .. vim.fn.fnameescape(target))
      vim.cmd('enew')
    end

    vim.cmd('Neotree show left reveal')
    vim.cmd('wincmd l')
  end,
})
