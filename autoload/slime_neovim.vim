" Public API for vim-slime to use.
function! slime_neovim#config(config, ...)
	" checks if valid config exists and then tries to send text to terminal
	"debug echo "in slime_neovim#config"
	"debug echo "trying to config"


	let config_in = a:config

	if s:NotExistsLastChannel()
		throw "Terminal not detected."
	endif

	if s:NotValidConfig(config_in)
		let config_in = {}
		let config_in["neovim"]= {"jobid": str2nr(get(g:slime_last_channel, -1, ""))}
	endif

	if exists("g:slime_get_jobid")
		let config_in["neovim"]["jobid"] = g:slime_get_jobid()
	else
		let id_in = input("jobid: ", str2nr(config_in["neovim"]["jobid"]))
		let id_in = str2nr(id_in)
		let config_in["neovim"]["jobid"] = id_in
	endif


	if s:NotValidConfig(config_in)
		throw "Channel identity not valid."
	endif

	return config_in
endfunction


function! s:NotExistsConfig() abort
	return exists("b:slime_config")
endfunction

function! s:NotValidConfig(config) abort 
	"checks if the current configuration refers to an actual running terminal
	let not_valid = 1

	if type(a:config) != v:t_dict || !exists("g:slime_last_channel")
		return not_valid
	endif

	if has_key(a:config, 'neovim') && has_key(a:config['neovim'], 'jobid') && index( g:slime_last_channel, a:config['neovim']['jobid']) >= 0
		let not_valid = 0
		return not_valid
	endif



	return not_valid

endfunction

function slime_neovim#SlimeAddChannel()

	"adds terminal job id to the g:slime_last_channel variable
	if !exists("g:slime_last_channel")
		let g:slime_last_channel = [&channel]
		echo g:slime_last_channel
	else
		call add(g:slime_last_channel, &channel)
		echo g:slime_last_channel
	endif
endfunction

function slime_neovim#SlimeClearChannel() 
	" checks if slime_last_channel exists and is nonempty; then filter slime_last_channel to only have existing channels
	if !exists("g:slime_last_channel")
	elseif len(g:slime_last_channel) == 1
		unlet g:slime_last_channel
	else
		let bufinfo = getbufinfo()
		call filter(bufinfo, {_, val -> has_key(val['variables'], "terminal_job_id") })
		call map(bufinfo, {_, val -> val["variables"]["terminal_job_id"] })
		call filter(g:slime_last_channel, {_, val -> index(bufinfo, val ) >= 0 })
	endif
endfunction

function! slime_neovim#send(config, text)
	let config_in = a:config
	let not_valid = s:NotValidConfig(config_in)

	if not_valid

		try
			let b:slime_config = slime_neovim#config(config_in)
			let config_in = b:slime_config

		catch /Terminal not detected./
			echo "Terminal not detected: Open a neovim terminal and try again. "
			return
		catch /Channel identity not valid./
			echo "Channel id not valid: Open a neovim terminal and try again. "
			return
		finally
		endtry
	endif

	call chansend(str2nr(config_in["neovim"]["jobid"]), split(a:text, "\n", 1))
endfunction

function! s:NotExistsLastChannel() abort "
	" check if slime_last_channel variable exists
	let not_exists = 1

	if !exists("g:slime_last_channel") || (len(g:slime_last_channel)) < 1
		return not_exists
	endif


	let not_exists = 0
	return not_exists
endfunction
