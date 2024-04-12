--[[local Job = require("plenary.job")
local config = require("ollama-pilot.config")

---@class io
---@field job any
local io = { job = nil }

function io._create_generate_job(prompt, system_prompt)
	local parameters = {
		model = config.options.ollama_model,
		prompt = prompt,
		options = config.options.ollama_options,
		system = system_prompt,
	}

	local ollama_url = ""

	if config.options.ollama_ssl then
		ollama_url =
			string.format("https://%s:%d/api/generate", config.options.ollama_hostname, config.options.ollama_port)
	else
		ollama_url =
			string.format("http://%s:%d/api/generate", config.options.ollama_hostname, config.options.ollama_port)
	end

	local pending_json_string = ""

	vim.print(parameters)
	JOB = Job:new({
		command = "curl",
		args = { "-X", "POST", ollama_url, "-d", vim.json.encode(parameters) },
		on_stdout = function(_, data)
			pending_json_string = pending_json_string .. data
			vim.print("pending: " .. pending_json_string)

			local ok, decoded = pcall(vim.json.decode, pending_json_string)

			if ok then
				pending_json_string = ""

				vim.print("response: ")
				vim.print(decoded.response)
				-- append results to the users buffer for suggestion

				local cb = vim.schedule_wrap(function()
					local bnr = vim.fn.bufnr("%")
					local ns_id = vim.api.nvim_create_namespace("ollama-pilot")

					local opts = {
						end_line = 10,
						id = 1,
						virt_text = { { "ollama-pilot", decoded.response } },
						virt_text_pos = "eol",
					}

					local cursor_pos = vim.api.nvim_win_get_cursor(0)
					local line_num = cursor_pos[1]

					vim.api.nvim_buf_set_extmark(bnr, ns_id, line_num - 1, 0, opts)
				end)
				cb()
			end
		end,
	})
end

function io.start_generate(prompt, system_prompt)
	io._create_generate_job(prompt, system_prompt)
	JOB:start()
end

function io.interupt()
	if JOB then
		JOB:shutdown()
		-- remove suggestion
	end
end
1e
return io ]]

local Job = require("plenary.job")

local function log(msg, type)
	local log_file = ""
	if type == "info" then
		log_file = "/home/anon/ollama.log" -- Specify your log file path here
	else
		log_file = "/home/anon/ollama.error.log" -- Specify your log file path here
	end
	local file = io.open(log_file, "a")
	if file then
		file:write(msg or "nothing\n")
		file:close()
	end
end

---@class io
---@field _is_running boolean
---@field _job nil|any
---@field _observers any[]
---@field __instance io | nil
---@field _llm_resp string
local io = { _is_running = false, _job = nil, _observers = {}, __instance = nil, _llm_resp = "" }

function io:subscribe(observer)
	table.insert(self._observers, observer)
end

function io:_notify(data)
	for _, observer in ipairs(self._observers) do
		observer:_update(data)
	end
end

---@param data string
---@return fun()
function io:_handle_ollama_response(data)
	return function()
		local ok, decoded = pcall(vim.json.decode, data)
		if ok then
			local llm_response = decoded["response"]
			self._llm_resp = self._llm_resp .. llm_response
		end
	end
end

---@param data string
---@return fun()
function io:_handle_ollama_error(data)
	return function()
		log(data)
	end
end

---@param prompt string
---@return nil
function io:_create_job(prompt)
	local ollama_url = "http://localhost:11434/api/generate" -- get this from config
	local params = { -- get this from config
		model = "mistral",
		prompt = prompt,
		stream = true,
	}
	local json_params = vim.json.encode(params)

	self._job = Job:new({
		command = "curl",
		args = { "-X", "POST", ollama_url, "-d", json_params },
		on_stdout = function(error, data)
			local async_handle = vim.schedule_wrap(self:_handle_ollama_response(data))

			async_handle()
		end,
		on_stderr = function(error, data)
			local async_handle = vim.schedule_wrap(self:_handle_ollama_error(data))

			async_handle()
		end,
		on_exit = function()
			self._is_running = false
			self:_notify(self._llm_resp)
			self._llm_resp = ""
		end,
	})
end

---@param prompt string
---@return nil
function io:start(prompt)
	self:_create_job(prompt)

	if self._job == nil then
		vim.print("error creating job")
		return
	end

	self._job:start()

	self._is_running = true
end

function io:stop()
	if self._is_running then
		self._job:shutdown()
		log("shutdown happened\n")
		self._is_running = false
	end
end

---@return io
function io:new()
	if not io.__instance then
		io.__instance = setmetatable({}, { __index = io })
		self.__index = self
	end

	return io.__instance
end

return io
