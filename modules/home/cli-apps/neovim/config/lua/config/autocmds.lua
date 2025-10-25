vim.cmd('au InsertEnter * set cul')
vim.cmd('au InsertLeave * set nocul')
vim.cmd('au BufWritePre * :%s/\\s\\+$//e') -- remove whitespace on save
vim.cmd('syntax enable')
vim.cmd('au FileType markdown set wrap')
vim.cmd('autocmd BufRead,BufNewFile *.astro set filetype=astro')
