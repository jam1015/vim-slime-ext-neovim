# vim-slime-ext-neovim

A plugin to send code from a Neovim buffer to a running Neovim terminal by extending [vim-slime-ext-plugins](https://github.com/jpalardy/vim-slime-ext-plugins/).

That plugin is itself a modification of [vim-slime](https://github.com/jpalardy/vim-slime) to move platform-specific functionality to extension plugins like this one.

Even though this documentation is for vim-slime-ext-neovim, it also reviews the functionality of `vim-slime-ext-plugins` and `vim-slime`

## Introduction

Imagine that you are testing quick changes to, for example, a python script.  One approach to test the changes is to copy and paste into an open python REPL in a Neovim terminal (perhaps using the `+` or `*` registers which can be synced to the system clipboard).  With this plugin, instead of copying and pasting, you can send the code directly to the REPL using Vim operator/motion+text object combinations. For example, if `SlimeMotionSend` is mapped to `gz`, `gzip` can be used to send an uninterrupted block of text (a paragraph) to the REPL. This of course works for any program running in the terminal that accepts text input.

## Example Installation and Configuration Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Note that `vim-slime-ext-plugins` is necessary as a dependency.

Be aware that the values here are the ones preferred by the plugin author, not the defaults. The default is for the `vim.g` variables to not exist, which has the same effect as `false`.

It is recommended to use `init` to set global variables so that they are present before the plugin loads. Otherwise they might not take effect.

```lua
{
'Klafyvel/vim-slime-ext-neovim',
dependencies = { "jpalardy/vim-slime-ext-plugins" },
init = function()
	vim.g.slime_no_mappings = true -- I prefer to turn off default mappings; see below for more details
	-- these next two are essential, telling vim-slime-ext-plugins to use the functions from this plugin
	vim.g.slime_target_send = "slime_neovim#send"
	vim.g.slime_target_config = "slime_neovim#config"
	vim.g.slime_input_pid = false -- use Neovim's internal Job ID rather than PID to select a terminal
	vim.g.override_status = true -- Show the Job ID and PID in the status bar of a terminal
	vim.g.ruled_status = true  -- If override_status is true, also show the cursor position in the status bar
end,
config = function()

	vim.keymap.set("n", "gz", "<Plug>SlimeMotionSend", { remap = true, silent = false })
	vim.keymap.set("n", "gzz", "<Plug>SlimeLineSend", { remap = true, silent = false })
	vim.keymap.set("x", "gz", "<Plug>SlimeRegionSend", { remap = true, silent = false })

end,
}
```

### Vimscript Config

```vim
let g:slime_no_mappings = 1
let g:slime_target_send = "slime_neovim#send"
let g:slime_target_config = "slime_neovim#config"
let g:slime_input_pid = 0
let g:override_status = 1
let g:ruled_status = 1
map gz <Plug>SlimeMotionSend
map gzz <Plug>SlimeLineSend
xmap gz <Plug>SlimeRegionSend
```


It is recommended to use `init` instead of `config` for plugin configuration involving global variables.

## Usage

If `vim.g.slime_no_mappings = false` default mappings will be defined. If the user provides their own mappings, those specific default mappings will be disabled. 


The default mappings are:

- <C-c><C-c> send current paragraph to terminal.
- {Visual}<c-c><c-c>  Send highlighted text to terminal.
- <c-c>v configure the target terminal.

Use the `<Plug>` mappings from `vim-slime-ext-plugins` to send text to a running Neovim terminal. Upon running them, if a terminal has not been configured as the target, the user will be prompted to select one based on either the Job Id number or the PID, or to open one if no terminal is detected.

- `<Plug>SlimeConfig` configure the target terminal for the current buffer.
- `<Plug>SlimeRegionSend` sends a visually selected region to the terminal.
- `<Plug>SlimeLineSend` sends a line to the terminal.
- `<Plug>SlimeMotionSend` sends text to terminal based on motion or text-object.
- `<Plug>SlimeParagraphSend` sends a paragraph to the terminal.

For this plugin (`vim-slime-ext-neovim`) if you try to send text to a terminal when none is opened, you will be prompted to do so. If multiple terminals are opened, you are prompted to select the most recently opened terminal, but can select any terminal.

There are additionally commands available (taken from the base Slime documentation):

- `:SlimeConfig` configures the current buffer to select a terminal.
- `<range>SlimeSend` send the range of lines to the terminal. For example to send lines three through five to the terminal, `:3,5SlimeSend`.

- `:SlimeSend1 {text}` send text to terminal, with a carriage return appended. For example `:SlimeSend1 pwd`.

- `:SlimeSend0 {text in quotes}` send text to terminal, without a carriage return appended. For example `:SlimeSend0 'pwd'`  or  `:SlimeSend0 "pwd"`.


## Configuration


Global Variables (`vim.g.xxx`)  have to be created and set by the user.  By default they do not exist.


### Global Variables

---


```
vim.g.slime_target_config = "slime_neovim#config"
```

(defined in `vim-slime-ext-plugins`) This variable holds the function that configures which terminal text is sent to. Here we set it to the configuration function defined in this plugin.


---


```
vim.g.slime_target_send = "slime_neovim#send"
```

(defined in `vim-slime-ext-plugins`) This variable holds the function that actually sends text to the terminal. We set it to the function defined in this plugin.


---


```
vim.g.slime_no_mappings = true
```

Do not define the default mappings from `vim-slime-ext-plugins`. Default mappings are also turned off for `SlimeRegionSend`, `SlimeParagraphSend` and `SlimeConfig` if the user has already made their own mappings.  See documentation of `vim-slime-ext-plugins` or `vim-slime` for more details.


---


```
vim.g.slime_input_pid = false
```

Boolean that can decides whether you specify the terminal based on the Neovim internal terminal Job ID, or based on the PID that also exists on a system level. Job ID is shorter an for that reads might be preferred.


---

```
vim.g.override_status = true
```

Boolean that overrides the default status bar so that Job ID and terminal PID is displayed in the status bar. The default is `false` but it is recommended to set it to true (`1`).


---


```
vim.g.ruled_status = true
```

Boolean that, when true, shows the coordinates of the cursor in the overridden status bar set by `vim.g.override_status`. Only takes effect if `vim.g.override_status` is `true`.


### Mappings

See the Usage and Example Installation sections for available commands, functions and mapping examples.


## Glossary

### PID
   Process identifier in Linux and MacOS. A unique number assigned to
    each process when it is created. Corresponds to `terminal_job_pid`
    in Neovim's `getbufinfo()` command. Neovim also has a number analogous to PID in Windows.

    TODO: Investigate what PID means in Neovim on Windows.

### Job ID
   Neovim's internal identifier for a running terminal process.
    Referenced as `terminal_job_id` in `getbufinfo()`.
