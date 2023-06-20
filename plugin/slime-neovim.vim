" autocmds to keep of terminal identification numbers whenever a terminal is opened or closed
augroup nvim_slime
	autocmd!
	autocmd TermOpen * call slime_neovim#SlimeAddChannel()
	autocmd TermClose * call slime_neovim#SlimeClearChannel()
	if &ruler
		autocmd TermOpen * setlocal statusline=%{bufname()}%=%(%c%V\ %p%%%)\ id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
	else
		autocmd TermOpen * setlocal statusline=%{bufname()}%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
	endif
augroup END
