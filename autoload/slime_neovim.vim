" Public API for vim-slime to use.

function! slime_neovim#config(config)
  if !exists("a:config['neovim']")
    let a:config["neovim"] = {"jobid": get(g:, "slime_last_channel", "")}
  end
  if exists("g:slime_get_jobid")
    let a:config["neovim"]["jobid"] = g:slime_get_jobid()
  else
    let a:config["neovim"]["jobid"] = input("jobid: ", a:config["neovim"]["jobid"])
  end
  return a:config
endfunction

function! slime_neovim#send(config, text)
  call chansend(str2nr(a:config["neovim"]["jobid"]), split(a:text, "\n", 1))
endfunction

