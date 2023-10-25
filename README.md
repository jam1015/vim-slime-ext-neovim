# vim-slime-ext-neovim

A plugin to send code from a Neovim buffer to a running Neovim terminal by extending the base functionality of [vim-slime-ext-plugins](https://github.com/jpalardy/vim-slime-ext-plugins/).

## Introduction

Imagine that you are making quick changes to, for example, a python script.  One approach to test the changes is to copy and paste into an open python REPL (perhaps using the `+` or `*` registers which can be synced to the system clipboard).  With this plugin you can send the code directly to the REPL using Vim operator /motion+text object combinations. For example, if `SlimeMotionSend` is mapped to `gz`, `gzip` can be used to send an uninterrupted block of text (a paragraph) to the REPL. This of course works for any program running in the terminal that accepts text input.

## Example Installation Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Note that `vim-slime-ext-plugins` is necessary.

```
{
    'Klafyvel/vim-slime-ext-neovim',
    dependencies = { "jpalardy/vim-slime-ext-plugins" },
}
```

## Usage

Use the `<Plug>` mappings from `vim-slime-ext-plugins` to send text to a running Neovim terminal. Upon running them, if a terminal has not been configured as the target, the user will be prompted to select one based on either the Job Id number or the PID, or to open one if no terminal is detected.

`<Plug>SlimeRegionSend` sends a visually selected region to the terminal.
`<Plug>SlimeLineSend` sends a line to the terminal.
`<Plug>SlimeMotionSend` sends text to terminal based on motion or text-object.
`<Plug>SlimeParagraphSend` sends a paragraph to the terminal.
`<Plug>SlimeConfig` configure the target terminal for the current buffer.

## Configuration

### Variables defined by `vim-slime-ext-plugins`

```
vim.g.slime_target_config = "slime_neovim#config"
```

(defined in `vim-slime-ext-plugins`) This variable holds the function that configures which terminal text is sent to. Here we set it to the configuration function defined in this plugin. 


```
vim.g.slime_target_send = "slime_neovim#send"
```

(defined in `vim-slime-ext-plugins`) This variable holds the function that actually sends text to the terminal. We set it to the function defined in this plugin.


```
vim.g.slime_no_mappings = true
```

Do not define the default mappings from `vim-slime-ext-plugins`.  See documentation of `vim-slime-ext-plugins` for more details.


```
vim.g.slime_input_pid = 0
```

Boolean that can decides whether you specify the terminal based on the Neovim internal terminal Job ID, or based on the PID that also exists on a system level. Job ID is shorter an for that readsn might be preferred.


```
vim.g.override_status=1
```

Boolean that overraides the default status bar so that Job ID and terminal PID is displayed in the status bar. Recommended to be true (`1`)




vim.keymap.set("n", "gz", "<Plug>SlimeMotionSend", { remap = true })
vim.keymap.set("n", "gzz", "<Plug>SlimeLineSend", { remap = true })
vim.keymap.set("x", "gz", "<Plug>SlimeRegionSend", { remap = true })
```


### Note on `g:slime_input_pid`

Using the external PID instead of Neovim\'s internal job id is
recommended for ease of use. This setting isn\'t default because Neovim
internally uses its job id. However, setting this to a nonzero value
allows users to utilize the PID displayed on the terminal\'s status
line.

## Usage

Check out `:h slime.txt` for default keybindings. Here\'s a brief
summary:

-   `gz[operator/motion]`: Send text using an operator or motion.
-   In visual mode, `gz` sends the selected text.
-   `gzz` sends the current line.

When sending text, the plugin prioritizes the most recently opened
terminal. If no terminals are open, you\'ll be prompted to open one. Use
`<C-w>s` or `<C-w>v` and then `:terminal` to do so. To reconfigure a
buffer\'s terminal connection, call `:SlimeConfig`.

## Capabilities

### Multiple Terminal Tracking

The plugin tracks multiple terminals using `g:slime_last_channel`. If a
linked terminal closes, the plugin will prompt you to choose another. If
issues arise, helpful messages guide the process. Feedback is welcome!

Neovim sends text to a terminal using the `terminal_job_id`, but it also
tracks the system\'s `terminal_job_pid`. The latter is displayed on each
terminal\'s status line, making it more user-friendly for manual
configuration.

## Glossary

PID
:   Process IDentifier in Linux and MacOS. A unique number assigned to
    each process when it\'s created. Corresponds to `terminal_job_pid`
    in Neovim\'s `getbufinfo()` command.

Job ID
:   Neovim\'s internal identifier for a running terminal process.
    Referenced as `terminal_job_id` in `getbufinfo()`.
