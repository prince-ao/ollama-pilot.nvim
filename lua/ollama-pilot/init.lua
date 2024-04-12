local ollama_pilot = {}

function ollama_pilot.setup(options)
	--[=[local ollama = require("ollama-pilot.ollama")
	require("ollama-pilot.config").setup(options)

	local ollama_instance = ollama:new()

	ollama_instance:create_user_commands()

	-- ollama:send_message("test")

	--[[local cb = vim.schedule_wrap(function()
		ollama:send_message("Hello")
	end)

	cb()]]

	-- vim.notify("this ran") ]=]
	local namespace = vim.api.nvim_create_namespace("OllamaPilotNs")

	vim.api.nvim_command(
		"highlight OllamaPilotHl ctermfg=LightGrey ctermbg=NONE cterm=italic gui=italic guifg=#545454 guibg=NONE"
	)

	local io = require("ollama-pilot.io")
	local ollama = require("ollama-pilot.ollama")
	local buffer_manip = require("ollama-pilot.buffer_manip")

	--
	--@type ollama
	-- local new_ollama = ollama:new()
	-- new_ollama:create_user_commands()

	local new_io = io:new()

	---@type buffer_manip
	local buffer_man = buffer_manip:new({ _namespace = namespace })

	vim.api.nvim_create_user_command("Testerr", function(opts)
		buffer_man:_create_virtual_line("while(1) {\n\tcout << 'under the c' << endl;\n}")
	end, {})

	vim.api.nvim_create_user_command("Testers", function(opts)
		buffer_man:_delete_virtual_line()
	end, {})

	vim.api.nvim_create_user_command("PilotStart", function(opts)
		new_io:start("what is the python programming language?")
	end, {})

	-- new_io:start("who was the first president of the US?")

	-- vim.defer_fn(function()
	-- new_io:stop()
	-- end, 17000)
end

return ollama_pilot
