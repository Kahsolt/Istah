#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Interpreter
-- Name: istah
-- Author: Kahsolt
-- Time: 2016-12-13
-- Version: 1.0
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

require 'isparse'

local function help()
	print('The Istah Language Interpreter')
	print('Usage:')
	--print('\tInteractive Mode:\tistah')
	--print('\tFile Execution Mode:\tistah <filename>')
	print('\tistah <filename>')
	os.exit()
end

-----------
-- Entry --
-----------
if #arg ~= 1 then
	help()
elseif arg[1] then
	Istah_Mode('Release')
	isparse.nextExecution(arg[1])
end
