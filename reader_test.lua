require'reader'

__api = {}

function __api.await(delay)
	local time = require("time")
	time.sleep(delay / 1000.)
end

function __api.is_close()
	return false
end

--[[ Use cases:
reader:open("access.log", "tail") -- default values
reader:open("access.log", "tail", true, 15) -- set limit
reader:open("access.log", "tail", true, -1, 3) -- set step
reader:open("access.log", "tail", false, 15) -- set limit without follow
reader:open("access.log", "tail", false, 20, 3) -- set limit and step without follow
reader:open("access.log", "head") -- default values
reader:open("access.log", "head", true, 15) -- set limit
reader:open("access.log", "head", true, -1, 3) -- set step
reader:open("access.log", "head", false, 15) -- set limit without follow
reader:open("access.log", "head", false, 20, 3) -- set limit and step without follow
]]

function reader_init()
	local reader = CReader()
	if not reader:open("access.log", "tail", true, -1, 1) then
		print("Failed to initialize file descriptor")
		os.exit(0)
	end
	return reader
end

function print_lines(lines)
	local date_marker = os.date("%Y-%m-%d %H:%M:%S ", os.time())
	date_marker = "<" .. date_marker .. "> "
	if type(lines) == "table" then
		for n = 1, #lines do
			local prefix = date_marker .. tostring(n) .. ": "
			print(prefix .. lines[n])
		end
	end
end

--[[ Inline using:
local reader = reader_init()
while not __api.is_close() do
	local lines = reader:read_line(__api.await, __api.is_close)
	if type(lines) ~= "table" then
		break
	end
	print_lines(lines)
end
]]

--[[ Inline using with callback:
local reader = reader_init()
reader:read_line_cb(print_lines, __api.await, __api.is_close)
]]

--[[ Thread using in box with callback:
local thread = require'thread'
local rth = thread.new(function (reader_init, print_lines, await, is_close)
	require'reader'
	local reader = reader_init()
	reader:read_line_cb(print_lines, await, is_close)
end, reader_init, print_lines, __api.await, __api.is_close)
rth:join()
]]

--[[ Thread using queue out of the box with callback:
local thread = require'thread'
local q = thread.queue(1)
local rth = thread.new(function (reader_init, q, await, is_close)
	require'reader'
	local reader = reader_init()
	reader:read_line_cb(function (lines) q:push(lines) end, await, is_close)
	q:push()
end, reader_init, q, __api.await, __api.is_close)

while true do
	local _, v = q:shift()
	if type(v) ~= "table" then
		break
	end
	print_lines(v)
end
q:free()
print("wait thread")
rth:join()
]]

print("done")
