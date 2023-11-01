" Public API for vim-slime to use with Neovim's terminal.

" Sets up the configuration for slime_neovim.
function! slime_neovim#ValidateConfig(config, config_provided) abort
	" config_provided generally conveys whether the user has already explicitly provided a configuration

	" Ensure that a previous channel exists
	let valid = 0

	if slime_neovim#NotExistsLastChannel()
		echo "Terminal not detected: Open a neovim terminal and try again. "
		return {"valid": 0,  "continue": 0}
	endif


	if !exists("a:config") ||  a:config == v:null
		echo "Config does not exist."
		return {"valid": 0,  "continue": 1}
	endif


	" Ensure the config is a dictionary and a previous channel exists
	if type(a:config) != v:t_dict 
		echo "Config type not valid."
		return {"valid": 0,  "continue": 1}
	endif

	if empty(a:config)
		echo "Config is empty."
		return {"valid": 0,  "continue": 1}
	endif

	if config_provided
		" Ensure the correct keys exist within the configuration
		if !(has_key(a:config, 'neovim') && has_key(a:config['neovim'], 'jobid') )
			echo "Improper configuration structure Try again"
			return {"valid": 0,  "continue": 1}
		endif

		if a:config["neovim"]["jobid"] == -1  "the id wasn't found translate_pid_to_id
			echo "No matching job id for the provided pid. Try again"
			return {"valid": 0,  "continue": 1}
		endif

		if index( slime_neovim#channel_to_array(g:slime_last_channel), a:config['neovim']['jobid']) >= 0
			throw "Job ID not found. Try again."
			return {"valid": 0,  "continue": 1}
		endif
	endif


	return {"valid": 1, "continue": 1}

endfunction

function! slime_neovim#set_config_state(just_ran, valid) abort
	"lets the config function communicate with the 'send' function
	let g:just_ran_config = {}
	if a:just_ran
		let g:just_ran_config["just_ran"] = 1
	else
		let g:just_ran_config["just_ran"] = 0
	endif

	if a:valid
		let g:just_ran_config["valid"] = 1
	else
		let g:just_ran_config["valid"] = 0
	endif
endfunction


function! slime_neovim#config(config, ...) abort
	" Check if function is called internally or by external plugins, likely vim-slime-ext-plugins

	let confg_in = a:config

	let validity_state = slime_neovim:ValidateConfig(config_in, false) "second argument iw whether the user has proovided a confiuration yeat

	if !validity_state["valid"] && !validity_state["continue"]

		if exists("b:slime_config")
			unlet b:slime_config
		endif


		if exists("g:slime_config")
			unlet g:slime_config
		endif

		call slime_neovim#set_config_state(1, 0) 
		return {}

	endif

	if !validity_state["valid"] && validity_state["continue"]
		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', 'default_value')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', 'default_value')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}
	endif




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

	let valid = slime_neovim#ValidateConfig(config_in, true)


	if !valid

		let config_in = {}
	endif

	return config_in
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

	if exists("g:just_ran_config") && g:just_ran_config["just_ran"] && g:just_ran_config["valid"]

		" Send the text to the channel
		call chansend(str2nr(config_in["neovim"]["jobid"]), split(a:text, "\n", 1))
	endif
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
