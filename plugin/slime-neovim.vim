" autocmds to keep of terminal identification numbers whenever a terminal is opened or closed

augroup nvim_slime
	autocmd!
	autocmd TermOpen * call slime_neovim#SlimeAddChannel()
	autocmd TermClose * call slime_neovim#SlimeClearChannel()
	autocmd TermOpen * execute "setlocal statusline=" . (exists("g:ruled_terminal") && g:ruled_terminal ? \"%{bufname()}%=%-14.(%l,%c%V%)\ %P\ \|\ id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}" : "%{bufname()}%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}")
augroup END
