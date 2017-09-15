#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Extern Lua Call Module
-- Name: islua
-- Author: Kahsolt
-- Time: 2017-1-4
-- Version: 1.0
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
islua = {}			-- 模块名
local _M = islua	-- 临时模块名

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local function err(level,msg)
	iserr.what('Islua',msg,level)
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.call(cmd)
	cmd='lua5.3 -e "print(tostring('..tostring(cmd)..'))"'
	local _ret = io.popen(cmd)
	_ret=tostring(_ret:read('*all'))
	if tonumber(_ret) then
		return tonumber(_ret)
	else
		return string.sub(_ret,1,#_ret-1)	-- remove an extra '\n'
	end
end

-----------------------------------------------------------------------------
return _M
