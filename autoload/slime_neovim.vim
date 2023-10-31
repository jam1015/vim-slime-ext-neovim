" Public API for vim-slime to use with Neovim's terminal.

" Sets up the configuration for slime_neovim.
function! slime_neovim#config(config, ...)
	" Check if function is called internally or by external plugins, likely vim-slime-ext-plugins

	let confg_in = a:config
	let valid = 0

	try
		let valid = s:ValidConfig(config_in, false) "second argument iw whether the user has proovided a confiuration yeat

	catch /Terminal not detected./
		echo "Terminal not detected: Open a neovim terminal and try again. "

		if exists("b:slime_config")
			unlet b:slime_config
		endif


		if exists("g:slime_config")
			unlet g:slime_config
		endif

		return {}

	catch /Config does not exist./
		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', 'default_value')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', 'default_value')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}
	catch /Config type not valid./

		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', 'default_value')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', 'default_value')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}
	finally

	endtry


	" Get the jobid based on the configuration provided
	if get(g:, "slime_input_pid", 0)
		let pid_in = input("pid: ", str2nr(jobpid(config_in["neovim"]["jobid"])))
		let id_in = slime_neovim#translate_pid_to_id(pid_in)
	else
		if exists("g:slime_get_jobid")
			let id_in = g:slime_get_jobid()
		else
			let id_in = input("jobid: ", str2nr(config_in["neovim"]["jobid"]))
			let id_in = str2nr(id_in)
		endif
		let pid_in = jobpid(id_in)
	endif

	let config_in["neovim"]["jobid"] = id_in
	let config_in["neovim"]["pid"] = pid_in

	try

	catch /No matching job id for the provided pid/
	catch /Terminal not detected./
		echo "Terminal not detected: Open a neovim terminal and try again. "

		if exists("b:slime_config")
			unlet b:slime_config
		endif


		if exists("g:slime_config")
			unlet g:slime_config
		endif

		return {}
	catch /Channel id not valid./
		redraw!
		echon "Channel id not valid. Try again."
		return {}
	finally

	endtry


	try
		let valid = s:ValidConfig(config_in, true)
	catch /Terminal not detected./
		echo "Terminal not detected: Open a neovim terminal and try again. "

		if exists("b:slime_config")
			unlet b:slime_config
		endif


		if exists("g:slime_config")
			unlet g:slime_config
		endif

		return

	catch /Config does not exist./
		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', 'default_value')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', 'default_value')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}
	catch /Config type not valid./

		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', 'default_value')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', 'default_value')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}

	catch /Improper configuration structure/ 
		echo "Improper configuration structure"
	catch /No matching job id for the provided pid./ 
		echo "No matching job id for the provided pid.  Try again. "
		return {}
	catch /Job ID not found./
		echo "Job ID not found.  Try again. "
		return {}
	finally
	endtry






	
	if !valid

		if exists("b:slime_config")
			unlet b:slime_config
		endif


		if exists("g:slime_config")
			unlet g:slime_config
		endif

		let config_in = {}
	endif

	return config_in
endfunction




function! s:NotValidConfig(config, config_provided) abort
	" config_provided generally conveys whether the user has already explicitly provided a configuration

	" Ensure that a previous channel exists

	if slime_neovim#NotExistsLastChannel()
		throw "Terminal not detected."
	endif


	if !exists("a:config") || empty(a:config) || a:config == v:null
		throw "Config does not exist."
	endif

	" Ensure the config is a dictionary and a previous channel exists
	if type(a:config) != v:t_dict 
		throw "Config type not valid."
	endif

	if config_provided
		" Ensure the correct keys exist within the configuration
		if !(has_key(a:config, 'neovim') && has_key(a:config['neovim'], 'jobid') )
			throw "Improper configuration structure"
		endif

		if a:config["neovim"]["jobid"] == -1  "the id wasn't found translate_pid_to_id
			throw "No matching job id for the provided pid."
		endif

		if index( slime_neovim#channel_to_array(g:slime_last_channel), a:config['neovim']['jobid']) >= 0
			throw "Job ID not found."
		endif
	endif


	return 1

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
	let valid = 0

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
function! slime_neovim#NotExistsLastChannel() abort
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
