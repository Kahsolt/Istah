#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Garbage Collection Module
-- Name: isgc
-- Author: Kahsolt
-- Time: 2016-12-19
-- Version: 1.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
isgc = {}			-- 模块名
local _M = isgc		-- 临时模块名

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local count		-- number of entity disposed during last gc()
local function dbg()
	if ISTAH_GC_INFO then print('[Isgc Message]: #'..count..' Entity collected!') end
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.gc()
	count = 0
	for i=1,ENTITY_TOP do 	-- do not collect EntitySet[0]
		if EntitySet[i] and EntitySet[i].chain==0 then
			EntitySet[i]=nil
			count=count+1
		end
	end
	dbg()
end

-----------------------------------------------------------------------------
return _M
