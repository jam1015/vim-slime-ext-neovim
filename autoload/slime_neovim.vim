" Public API for vim-slime to use with Neovim's terminal.

function! slime_neovim#config(config, ...) abort
	" Check if function is called internally or by external plugins, likely vim-slime-ext-plugins
	echom "inside the neovim config"

	let config_in = a:config
	if empty(config_in)

		let last_pid = get(get(g:slime_last_channel, -1, {}), 'pid', '')
		let last_job = get(get(g:slime_last_channel, -1, {}), 'jobid', '')
		let config_in = {"neovim": {"jobid":  last_job, "pid": last_pid }}

	endif

	echom "echoing config contents"
	echom config_in["neovim"]["jobid"]
	echom config_in["neovim"]["pid"]


	" Get the jobid based on the configuration provided
	if exists("g:slime_input_pid") && g:slime_input_pid
		let pid_in = input("pid: ", str2nr(jobpid(config_in["neovim"]["jobid"])))
		let id_in = slime_neovim#translate_pid_to_id(pid_in)
	else
		if exists("g:slime_get_jobid")
			let id_in = g:slime_get_jobid()
		else
			echom "getting the id"
			let id_in = input("jobid: ", str2nr(config_in["neovim"]["jobid"]))
			let id_in = str2nr(id_in)
		endif
		let pid_in = slime_neovim#translate_id_to_pid(id_in)
	endif

	let config_in["neovim"]["jobid"] = id_in
	let config_in["neovim"]["pid"] = pid_in

	echom "echoing final config contents"
	echom config_in["neovim"]["jobid"]
	echom config_in["neovim"]["pid"]

	return config_in
endfunction


"evaluates whether ther is a terminal running; if there isn't then no config can be valid
function! slime_neovim#valid_env() abort
	if slime_neovim#NotExistsLastChannel()
		echo "Terminal not detected: Open a Neovim terminal and try again. "
		return 0
	endif
	return 1
endfunction

" "checks that a configuration is valid
" returns boolean of whether the supplied config is valid
function! slime_neovim#valid_config(config) abort
	echom "inside the neovim validation function"

"	echom "checking last channel"
"	if slime_neovim#NotExistsLastChannel()
"		echom "Terminal not detected: Open a neovim terminal and try again. "
"		return 0
"	endif

	echom "checking if the config exists"
	if !exists("a:config") ||  a:config is v:null
		echom "Config does not exist."
		return 0
	endif

	echom "checcking datatype of config"
	" Ensure the config is a dictionary and a previous channel exists
	if type(a:config) != v:t_dict 
		echom "Config type not valid."
		return 0
	endif

	echom "making sure the config is not empty"
	if empty(a:config)
		echom "Config is empty."
		return 0
	endif

	" Ensure the correct keys exist within the configuration

	echom "making sure the config has right fields"
	if !(has_key(a:config, 'neovim') && has_key(a:config['neovim'], 'jobid') )
		echom "Improper configuration structure Try again"
		return 0
	endif

	echom "making sure that there was an id found"
	if a:config["neovim"]["jobid"] == -1  "the id wasn't found translate_pid_to_id
		echom "No matching job id for the provided pid. Try again"
		return 0
	endif

	echom "trying to find jobid inside the last_channel variable"
	if !(index( slime_neovim#channel_to_array(g:slime_last_channel), a:config['neovim']['jobid']) >= 0)
		echom "Job ID not found. Try again."
		return 0
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

function! slime_neovim#translate_id_to_pid(id)
	let pid_out = -1
	try
		let pid_out = jobpid(a:id)
	catch /E900: Invalid channel id/
		let pid_out = -1
	endtry
	return pid_out
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
