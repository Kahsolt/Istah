#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah pre-Include Module
-- Name: ishub
-- Author: Kahsolt
-- Time: 2017-1-4
-- Version: 1.0
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
ishub = {}			-- 模块名
local _M = ishub	-- 临时模块名

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
-- Temp Var
local tmpFinName
local tmpFin, orgFin
local tmpCache

local function err(level,msg)
	iserr.what('Ishub',msg,level)
end
local function include(finname)
	local _fin, _path
	while true do
		_path=ModPath..finname..'.ish'
		_fin = io.open(_path,'r')
		if _fin then break end
		_path=PwdPath..finname
		_fin = io.open(_path,'r')
		if _fin then break end
		err(0,'No such file "'..finname..'"')
		return
	end
	if ISTAH_DBG_INCLUDE then print('Include file='.._path) end
	tmpFin:write(_fin:read('*all'))
	return true
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init()
	ModPath = ISTAH_MOD_PATH
	tmpCache = false
end
function _M.huddle(finName)
	_,_,PwdPath = string.find(finName,"(.*/)")
	if not PwdPath then PwdPath='' end
	if ISTAH_DBG_INCLUDE then print('PwdPath='..PwdPath) end

	orgFin=io.open(finName,'r')
	if not orgFin then
		err(0, 'Open source file failed')
	end
	tmpFinName=PwdPath..'.tmp.is'
	if ISTAH_DBG_INCLUDE then print('tmpFinName='..tmpFinName) end
	tmpFin=io.open(tmpFinName,'w+')
	if not tmpFin then
		err(0, 'Open tmp file failed')
	end
	local _line, _includeFin
	while true do
		_line=orgFin:read('*l')
		if not _line then break end
		_,_,_includeFin=string.find(_line,"+>%s*'(.+)'")
		if _includeFin then
			include(_includeFin,tmpFin)
			tmpCache=true
		else
			tmpFin:write(_line)
			tmpFin:write('\n')
		end
	end
	orgFin:close()
	tmpFin:close()
	if tmpCache then
		return tmpFinName
	else
		_M.clean()
		return finName
	end
end
function _M.clean()
	os.remove(tmpFinName)
end

-----------------------------------------------------------------------------
return _M
