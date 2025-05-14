vim.cmd('au InsertEnter * set cul')
vim.cmd('au InsertLeave * set nocul')
vim.cmd('au BufWritePre * :%s/\\s\\+$//e') -- remove whitespace on save
vim.cmd('syntax enable')
