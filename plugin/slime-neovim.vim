" autocmds to keep of terminal identification numbers whenever a terminal is opened or closed
function! s:SetStatusline()
	if exists("g:ruled_terminal") && g:ruled_terminal
		setlocal statusline=%{bufname()}%=%-14.(%l,%c%V%)\ %P\ \|\ id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
	else
		setlocal statusline=%{bufname()}%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
	endif
endfunction

augroup nvim_slime
	autocmd!
	autocmd TermOpen * call slime_neovim#SlimeAddChannel()
	autocmd TermClose * call slime_neovim#SlimeClearChannel()
	autocmd TermOpen * call s:SetStatusline()
augroup END
