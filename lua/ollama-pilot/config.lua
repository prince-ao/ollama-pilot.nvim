---@class config
---@field options optionstype
---@alias optionstype { ollama_port: number, ollama_hostname: string, ollama_ssl: boolean, ollama_model: string, ollama_options: ollamaoptionstype }
---@alias ollamaoptionstype  { temperature: number, num_thread: number }
local config = { options = nil }

function config.defaults()
	---@type optionstype
	return {
		ollama_port = 11434,
		ollama_hostname = "localhost",
		ollama_ssl = false,
		ollama_model = "mistral",
		ollama_options = {
			temperature = 0.7,
			num_thread = 8,
		},
	}
end

function config.setup(options)
	options = options or {}

	---@type optionstype
	config.options = vim.tbl_deep_extend("force", {}, config.defaults(), options)

	return config
end

return config
