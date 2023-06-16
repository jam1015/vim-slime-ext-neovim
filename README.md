# vim-slime-ext-neovim

A plugin to send code from a neovim Neovim buffer to a running Neovim terminal, enhancing your development workflow. This plugin uses Neovim's built-in terminal and extends [vim-slime-ext-plugins](https://github.com/jpalardy/vim-slime-ext-plugins/).

## Example of installation and configuration using lazy.nvim

### Lua installation Configuration

```lua
{
'Klafyvel/vim-slime-ext-neovim',
dependencies = { "jpalardy/vim-slime-ext-plugins" },
config = function()
	vim.g.slime_target_send = "slime_neovim#send"
	vim.g.slime_target_config = "slime_neovim#config"

	-- allows use of pid rather than internal job_id for config see note below this codeblock
	vim.g.slime_input_pid = 1

	-- optional but useful keymaps:
	---- send text using gz as operator before motion or text object
	vim.keymap.set("n", "gz", "<Plug>SlimeMotionSend", { remap = true })
	---- send line of text
	vim.keymap.set("n", "gzz", "<Plug>SlimeLineSend", { remap = true })
	---- send visual selection
	vim.keymap.set("x", "gz", "<Plug>SlimeRegionSend", { remap = true })
end
}

```

#### Note on `g:slime_input_pid`

Used to send text using the external pid rather than Neovim's internal job id. Setting this to a nonzero value (evaluated as `true` in vimscript), as is done here, is recommended because the pid is the number displayed on the status line of a terminal buffer, making it easier to select the desired terminal. This recommended setting is not the default because neovim  uses it's internal job id to send text to a terminal; the plugin has a function that translates the pid to the inernal job id.

##### Side Note

Recall that when configuring neovim in lua, variables in the global `g:` namespace are set with `vim.g.foo = bar`.

### vimscript configuration

```vim
let g:slime_target_send = "slime_neovim#send"
let g:slime_target_config = "slime_neovim#config"

" Use external pid instead of Neovim's internal job id
let g:slime_input_pid = 1

" Key mappings:
" Send text using gz as operator before motion or text object
nmap gz <Plug>SlimeMotionSend
" Send line of text
nmap gzz <Plug>SlimeLineSend
" Send visual selection
xmap gz <Plug>SlimeRegionSend
```



## What This Is
Say you are writing code in, for example, python. One way of quickly testing code is to have a terminal where you repeatedly source commands from the terminal.  For example if your file is `hello.py` you might have an editor open in one window, and a shell open in another where you input `python hello.py` after you save changes.  Another way might be to copy and paste your code to an open python session in the terminal.

The [vim-slime](https://github.com/jpalardy/vim-slime) plugin allows the user to set keybindings to send text directly from a Vim or Neovim buffer to a running shell or window. Configuration code for each target is included in that repository.

[vim-slime-ext-plugins](https://github.com/jpalardy/vim-slime-ext-plugins/) in contrast provides infrastructure for sending text to a target, and leaves the community to develop plugins for each target.  This plugin extends `vim-slime-ext-plugins` and targets the Neovim terminal.

## How to Use

See `:h vim-slime.txt` for default keybindings to send text to a target. I repeat the suggested keymappings from the config section above:

- `gz[operator/motion]`: send text using an operator or motion.
- In visual mode `gz` can send visually selected text to the target.
- `gzz` sends the current line to the target.

Of course these are optional and you can do what you want.

When you use one of these motions, the plugin will try to find the most recently opened terminal and select it as the target. You are prompted with the identification number (`terminal_job_id`) or (`terminal_job_pid` if `g:sline_input_pid` is set to a nonzero value).  `terminal_job_pid` is easier to use because that number is displayed on the status line of each terminal buffer. `terminal_job_id` is used by default because that is that Neovim internally uses to send text to the terminals.

Call the `:SlimeConfig` function from an open buffer to reconfigure the terminal connection of that buffer.

## Capabilities Summary

At the risk of repetition, this plugin:

### Keeps Track of Multiple Terminals

It does this using the `g:slime_last_channel` variable which is an array of vimscript dictionaries containing the PIDs (external identifier) and job ids (Neovim internal identifier) of open Neovim terminals. If a connected terminal is closed, upon trying to send text again the user is prompted to pick another terminal, with the next-most recently opened terminal selected by default. If no terminals are available, or if there is misconfiguration,  a helpful message telling you to open a new terminal is displayed. If you find the messages aren't helpful enogh please leave feedback witha  repo maintainer.


### Can Use PID or internal job id for configuration

Under the hood Neovim sends text to a running a terminal using the `terminal_job_id`, which are typically low numbers.  Neovim also keeps track of the `terminal_job_pid` which is the system's identifier, and importantly *is displayed on the status line of the terinal buffer*. The default settings are that the user if prompted with a `terminal_job_id` value, because this is what is used by neovim internally to send text to a terminal.  However, because it is readily displayed for each running terminal, `terminal_job_pid` is much easier to manually configure, and that is why `vim.g.slime_input_pid=1` is included in the example configuration (the vimscript equivalent of this is `let g:slime_input_pid=1`.


