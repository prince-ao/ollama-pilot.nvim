local function log(msg)
	local log_file = ""
	log_file = "/home/anon/test" -- Specify your log file path here
	local file = io.open(log_file, "a")
	if file then
		file:write(msg .. "\n" or "nothing\n")
		file:close()
	else
		vim.print("error")
	end
end

local io = require("ollama-pilot.io")

---@class buffer_manip
---@field _current_extmark number[]
---@field _hl_group string
---@field _namespace any|nil
local buffer_manip = { _current_extmark = {}, _hl_group = "OllamaPilotHl", _namespace = nil }

---@param lines string[]
---@return string[][]
function buffer_manip:_text_to_virtual_lines(lines)
	local virt_line_template = {}

	for _, line in ipairs(lines) do
		table.insert(virt_line_template, { { line, self._hl_group } })
	end

	return virt_line_template
end

---@param inputstr string
---@param sep string
---@return string[]
local function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

---@param text string
--@param line number
--@param col number
function buffer_manip:_create_virtual_line(text)
	local split = mysplit(text, "\n")
	local virtual_lines = self:_text_to_virtual_lines(split)

	local cursor_pos = vim.api.nvim_win_get_cursor(0)

	local buf_line, buf_col = cursor_pos[1] - 1, cursor_pos[2]
	-- log(vim.api.nvim_buf_line_count(0))

	for i, line in ipairs(virtual_lines) do
		-- log(vim.inspect(line))
		-- vim.print(i)
		local opts = {
			hl_mode = "combine",
			hl_group = self._hl_group,
			hl_eol = false,
			virt_text = line,
			virt_text_pos = "overlay",
		}
		-- vim.print(buf_line + i - 1)
		local line_number = buf_line + i - 1

		log(vim.api.nvim_buf_line_count(0))

		local total_lines = vim.api.nvim_buf_line_count(0)
		if line_number >= total_lines then
			break
		end

		local extmark_id = vim.api.nvim_buf_set_extmark(0, self._namespace, line_number, 0, opts)

		table.insert(self._current_extmark, extmark_id)
	end
end

function buffer_manip:_delete_virtual_line()
	for _, extmark_id in ipairs(self._current_extmark) do
		vim.api.nvim_buf_del_extmark(0, self._namespace, extmark_id)
	end

	self._current_extmark = {}
end

---@param data string
function buffer_manip:_update(data)
	if #self._current_extmark > 0 then
		self:_delete_virtual_line()
	end

	self:_create_virtual_line(data)
end

function buffer_manip:new(o)
	local obj = o or {}

	setmetatable(obj, self)
	self.__index = self

	local io_instance = io:new()

	io_instance:subscribe(obj)

	return obj
end

return buffer_manip
