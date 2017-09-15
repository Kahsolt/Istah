#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Configuration File
-- Name: iscfg
-- Author: Kahsolt
-- Time: 2016-12-21
-- Version: 1.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Boolean Setting
-----------------------------------------------------------------------------
-- switch of the gc module
ISTAH_GC		=	true
-- print gc count info
ISTAH_GC_INFO	=	false

-- debug the treeing of the parsers
ISTAH_DBG		=	true
-- debug the data parsers
ISTAH_DBG_DATA	=	false
-- debug the control parsers
ISTAH_DBG_LOGIC	=	false
-- debug the branch clause
ISTAH_DBG_BRANCH=	false
-- debug the while clause
ISTAH_DBG_WHILE	=	false
-- debug the function
ISTAH_DBG_FUNC	=	false
-- debug the lua cmd
ISTAH_DBG_CMD	=	false
-- debug the include
ISTAH_DBG_INCLUDE = false
-- debug islex
ISTAH_DBG_LEX	=	true

-----------------------------------------------------------------------------
-- String Setting
-----------------------------------------------------------------------------
ISTAH_FILEIN	=	'in.is'
ISTAH_MOD_PATH	=	'include/'

-----------------------------------------------------------------------------
-- Shortcut Function
-----------------------------------------------------------------------------
function Istah_Mode(mode)
	if mode == 'Release' then
		ISTAH_GC 		=	true
		ISTAH_GC_INFO	=	false
		ISTAH_DBG 		=	false
		ISTAH_DBG_DATA	=	false
		ISTAH_DBG_LOGIC	=	false
		ISTAH_DBG_BRANCH=	false
		ISTAH_DBG_WHILE	=	false
		ISTAH_DBG_LEX	=	false
	elseif mode == 'Debug_NO_GC' then
		ISTAH_GC 		=	false
		ISTAH_GC_INFO 	=	false
	elseif mode == 'Debug' then
		ISTAH_GC 		=	true
		ISTAH_GC_INFO 	=	true
		ISTAH_DBG 		=	true
	elseif mode == 'Debug_ALL' then
		ISTAH_GC 		=	true
		ISTAH_GC_INFO 	=	true
		ISTAH_DBG 		=	true
		ISTAH_DBG_DATA	=	true
		ISTAH_DBG_LOGIC	=	true
		ISTAH_DBG_BRANCH=	true
		ISTAH_DBG_WHILE	=	true
		ISTAH_DBG_FUNC	=	true
		ISTAH_DBG_INCLUDE =	true
		ISTAH_DBG_LEX	=	true
	end
end
