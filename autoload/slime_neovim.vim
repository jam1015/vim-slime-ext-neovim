" Public API for vim-slime to use with Neovim's terminal.

" Sets up the configuration for slime_neovim.
function! slime_neovim#config(config, ...)
	" Check if function is called internally or by external plugins, likely vim-slime-ext-plugins
	let internal = a:0 > 0 && a:1 == "internal"

	let config_in = a:config

	" Ensure that a previous channel exists
	if s:NotExistsLastChannel()
		if internal
			throw "Terminal not detected."
		else
			return {}
		endif
	endif

	" Validate the current configuration
	if s:NotValidConfig(config_in)
		let config_in = {}
		let config_in["neovim"]= {"jobid": str2nr(get(g:slime_last_channel, -1, "")['jobid'])}
	endif

	let id_in = 0

	" Get the jobid based on the configuration provided
	if get(g:, "slime_input_pid", 0)
		let pid_in = input("pid: ", str2nr(jobpid(config_in["neovim"]["jobid"])))
		let id_in = slime_neovim#translate_pid_to_id(pid_in)
	else
		if exists("g:slime_get_jobid")
			let id_in = g:slime_get_jobid()
		else
			if internal
			let id_in = input("[internal] jobid: ", str2nr(config_in["neovim"]["jobid"]))
		else
			let id_in = input("jobid: ", str2nr(config_in["neovim"]["jobid"]))
		endif
			let id_in = str2nr(id_in)
		endif
	endif

	" Ensure the id is valid
	if id_in == -1  "the id wasn't found translate_pid_to_id
		if internal
			throw "No matching job id for the provided pid."
		else
			return {}
		endif
	endif

	let config_in["neovim"]["jobid"] = id_in

	" Double-check the validity of the configuration
	if s:NotValidConfig(config_in)
		if internal
			throw "Channel id not valid."
		else
			return {}
		endif
	endif

	return config_in
endfunction

" Checks if the current configuration is valid.
function! s:NotValidConfig(config) abort
	let not_valid = 1

	" Ensure the config is a dictionary and a previous channel exists
	if type(a:config) != v:t_dict || !exists("g:slime_last_channel")
		return not_valid
	endif

	" Ensure the correct keys exist within the configuration
	if has_key(a:config, 'neovim') && has_key(a:config['neovim'], 'jobid') && index( slime_neovim#channel_to_array(g:slime_last_channel), a:config['neovim']['jobid']) >= 0
		let not_valid = 0
		return not_valid
	endif

	return not_valid
endfunction

" Adds a new channel to the global variable tracking channels.
function! slime_neovim#SlimeAddChannel()
	if !exists("g:slime_last_channel")
		let g:slime_last_channel = [{'jobid': &channel, 'pid': b:terminal_job_pid}]
	else
		call add(g:slime_last_channel, {'jobid': &channel, 'pid': b:terminal_job_pid})
	endif
endfunction

" Clears out channels that are no longer active.
function slime_neovim#SlimeClearChannel()
	if !exists("g:slime_last_channel")
		return
	elseif len(g:slime_last_channel) == 1
		unlet g:slime_last_channel
	else
		let bufinfo = getbufinfo()
		call filter(bufinfo, {_, val -> has_key(val['variables'], "terminal_job_id") && has_key(val['variables'], "terminal_job_pid") && !get(val['variables'],"terminal_closed",0)})
		call map(bufinfo, {_, val -> val["variables"]["terminal_job_id"] })
		call filter(g:slime_last_channel, {_, val -> index(bufinfo, val["jobid"]) >= 0})
	endif
endfunction

" Sends text to the specified channel.
function! slime_neovim#send(config, text)
	let config_in = a:config
	let not_valid = s:NotValidConfig(config_in)

	" Handle invalid configurations
	if not_valid
		try
			let b:slime_config = slime_neovim#config(config_in, "internal")
			let config_in = b:slime_config
		catch /No matching job id for the provided pid/
			echo "No matching job id for the provided pid.  Try again. "
			return
		catch /Terminal not detected./
			echo "Terminal not detected: Open a neovim terminal and try again. "
			return
		catch /Channel id not valid./
			redraw!
			echon "Channel id not valid. Try again."
			return
		finally
		endtry
	endif

	" Send the text to the channel
	call chansend(str2nr(config_in["neovim"]["jobid"]), split(a:text, "\n", 1))
endfunction

" Translates a PID to its corresponding job ID.
function! slime_neovim#translate_pid_to_id(pid)
	for ch in g:slime_last_channel
		if ch['pid'] == a:pid
			return ch['jobid']
		endif
	endfor
	return -1
endfunction

" Checks if a previous channel does not exist or is empty.
function! s:NotExistsLastChannel() abort
	return (!exists("g:slime_last_channel") || (len(g:slime_last_channel)) < 1)
endfunction

" Transforms a channel dictionary into an array of job IDs.
function! slime_neovim#channel_to_array(channel_dict)
	return map(copy(a:channel_dict), {_, val -> val["jobid"]})
endfunction

" Sets the status line if the appropriate flags are enabled.
function! slime_neovim#SetStatusline()
	if exists("g:override_status") && g:override_status
		if exists("g:ruled_status") && g:ruled_status
			setlocal statusline=%{bufname()}%=%-14.(%l,%c%V%)\ %P\ \|\ id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
		else
			setlocal statusline=%{bufname()}%=id:\ %{b:terminal_job_id}\ pid:\ %{b:terminal_job_pid}
		endif
	endif
endfunction
