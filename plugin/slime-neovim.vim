    augroup nvim_slime
      autocmd!
        autocmd TermOpen * call slime_neovim#SlimeAddChannel()
        autocmd TermClose * call slime_neovim#SlimeClearChannel()
     augroup END
