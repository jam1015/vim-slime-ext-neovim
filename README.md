# vim-slime-ext-neovim
An experiment for an external neovim plugin for vim-slime

## Example of configuration using packer

```lua
  use {
    'Klafyvel/vim-slime-ext-neovim',
    config=function ()
      vim.g.slime_target_send = "slime_neovim#send"
      vim.g.slime_target_config = "slime_neovim#config"
    end
  }
```

## Keeps Track of Multiple Terminals

When you close a terminal, the next time you try to send text the plugin will try to use a different open terminal.
