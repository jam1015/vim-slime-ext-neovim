" autocmds to keep of terminal identification numbers whenever a terminal is opened or closed
augroup nvim_slime
	autocmd!
	autocmd TermOpen * call slime_neovim#SlimeAddChannel()
	autocmd TermClose * call slime_neovim#SlimeClearChannel()
	"autocmd TermOpen * setlocal statusline+=%{bufname()}%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
	autocmd TermOpen * setlocal statusline+=%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
augroup END
