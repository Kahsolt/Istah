#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Debugger
-- Name: isdbg
-- Author: Kahsolt
-- Time: 2017-1-7
-- Version: 1.3
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

require 'isparse'

local function help()
	print('The Istah Debugger')
	print('Usage:')
	print('\tDebug lexer:\tisdbg <filename> -l')
	print('\tDebug parser:\tisdbg <filename> -p [-all|-nogc|-noset]')		-- nogc: disable gc module
																	-- noset: no quick set, use manual setting
	os.exit()
end

-----------
-- Entry --
-----------
if #arg <= 1 then
	help()
elseif arg[2] == '-l' then
	print('[Debug_LEX]')
	islex.test(arg[2])
elseif arg[2] == '-p' then
	if arg[3] == '-all' then
		print('[Debug_PARSE_ALL]')
		Istah_Mode('Debug_ALL')
	elseif arg[3] == '-nogc' then
		print('[Debug_PARSE_NO_GC]')
		Istah_Mode('Debug_NO_GC')
	elseif arg[3] == '-noset' then
		print('[Debug_PARSE_NO_SET]')
	else
		print('[Debug_PARSE]')
		Istah_Mode('Debug')
	end
	isparse.nextExecution(arg[1])
end
