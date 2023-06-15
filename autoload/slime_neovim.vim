" Public API for vim-slime to use.

function! slime_neovim#config(config, ...)
    let config_in = a:config
    if s:NotExistsLastChannel()
        throw "Terminal not detected."
    endif
    if s:NotValidConfig(config_in)
        let config_in = {}
        let config_in["neovim"]= {"jobid": str2nr(get(g:slime_last_channel, -1, "")['jobid'])}
    endif
    let id_in = 0
    if get(g:, "slime_input_pid", 0)
        let pid_in = input("pid: ", str2nr(config_in["neovim"]["jobid"]))
        let id_in = slime_neovim#translate_pid_to_id(pid_in)
    else
        if exists("g:slime_get_jobid")
            let id_in = g:slime_get_jobid()
        else
            let id_in = input("jobid: ", str2nr(config_in["neovim"]["jobid"]))
            let id_in = str2nr(id_in)
        endif
    endif
    if id_in == -1
        throw "No matching job id for the provided pid."
    endif
    let config_in["neovim"]["jobid"] = id_in
    if s:NotValidConfig(config_in)
        throw "Channel id not valid."
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


function! slime_neovim#SlimeAddChannel()
    if !exists("g:slime_last_channel")
        let g:slime_last_channel = [{'jobid': &channel, 'pid': b:terminal_job_pid}]
    else
        call add(g:slime_last_channel, {'jobid': &channel, 'pid': b:terminal_job_pid})
    endif
endfunction

function slime_neovim#SlimeClearChannel() 
    if !exists("g:slime_last_channel")
        return
    endif
    let bufinfo = getbufinfo()
    call filter(bufinfo, {_, val -> has_key(val['variables'], "terminal_job_id") && has_key(val['variables'], "terminal_job_pid")})
    let id_list = map(copy(g:slime_last_channel), {_, val -> val["jobid"]})
    call filter(g:slime_last_channel, {_, val -> index(id_list, val["jobid"]) >= 0})
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
		catch /Channel id not valid./
			echo "Channel id not valid: Open a neovim terminal and try again. "
			return
		finally
		endtry
	endif

	call chansend(str2nr(config_in["neovim"]["jobid"]), split(a:text, "\n", 1))
endfunction


function! slime_neovim#translate_pid_to_id(pid)
    for ch in g:slime_last_channel
        if ch['pid'] == a:pid
            return ch['jobid']
        endif
    endfor
    return -1
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
