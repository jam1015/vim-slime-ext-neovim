" autocmds to keep of terminal identification numbers whenever a terminal is opened or closed

augroup nvim_slime
	autocmd!
	" keeping track of channels that are open
	autocmd TermOpen * call slime_neovim#SlimeAddChannel()
	" keeping track when terminals are closed
	autocmd TermClose * let b:terminal_closed = 1 | call slime_neovim#SlimeClearChannel()
	" setting status line to show job id and pid of terminal
	autocmd TermOpen * call slime_neovim#SetStatusline()
augroup END
