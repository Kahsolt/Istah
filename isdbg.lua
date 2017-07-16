#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Debugger
-- Name: isdbg
-- Author: Kahsolt
-- Time: 2016-12-13
-- Version: 1.2
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

require 'isparse'

local function help()
	print('The Istah Debugger')
	print('Usage:')
	print('\tIslex Test:\tisdbg l <filename>')
	print('\tIsparse Test:\tisdbg p <filename> [-all|-nogc|-noset]')		-- nogc: disable gc module
																	-- noset: no quick set, use manual setting
	os.exit()
end

-----------
-- Entry --
-----------
if #arg < 2 then
	help()
elseif arg[1] == 'l' then
	islex.test(arg[2])
elseif arg[1] == 'p' then
	if arg[3] == '-all' then
		print('[Debug_ALL]')
		Istah_Mode('Debug_ALL')
	elseif arg[3] == '-nogc' then
		print('[Debug_NO_GC]')
		Istah_Mode('Debug_NO_GC')
	elseif arg[3] == '-noset' then
		print('[Debug_NO_SET]')
	else
		print('[Debug]')
		Istah_Mode('Debug')
	end
	isparse.nextExecution(arg[2])
end
