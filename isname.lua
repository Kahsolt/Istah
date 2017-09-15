#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Namespace & Entity module
-- Name: isname
-- Author: Kahsolt
-- Time: 2017-1-4
-- Version: 2.5
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
isname = {}			-- 模块名
local _M = isname	-- 临时模块名

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
-- Status Var


-- Tools
local function setRef(name, ref)		-- ref==0 refers to the special NIL
	if not Namespace[name] then
		Namespace[name]=0
		EntitySet[0].chain=EntitySet[0].chain+1
	else
		EntitySet[Namespace[name]].chain=EntitySet[Namespace[name]].chain-1	-- break old link
		Namespace[name]=ref
		EntitySet[ref].chain=EntitySet[ref].chain+1	-- create new link
		return true
	end
end
local function setName(name)		-- RET: ref
	if Namespace[name] then
		return Namespace[name]
	else
		setRef(name,0)				-- 0 = NIL
		return Namespace[name]
	end
end
local function setEntity(value,const)		-- RET: index
	local _idx = 1		-- try from 1
	while EntitySet[_idx] do _idx=_idx+1 end	-- get a availabe index
	if _idx > ENTITY_TOP then ENTITY_TOP = _idx end	-- renew the top boundary
	EntitySet[_idx]={}
	if type(value)=='table' then	-- deep Copy a List
		EntitySet[_idx].value={}
		for k,v in pairs(value) do
			EntitySet[_idx].value[k]=v
		end
	else
		EntitySet[_idx].value=value		-- atomic value or a table
	end
	if const then
		EntitySet[_idx].const=true
	end
	EntitySet[_idx].chain=0
	return _idx
end

local function err(level,msg)
	iserr.what('Isname',msg,level)
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
-- Operators
function _M.init()
	ENTITY_TOP=0		-- the most high index used in EntitySet
	Namespace={}	-- Name -> ref, type
					-- {['var']=1,['list']=5,['$func']=32}
	EntitySet={}	-- Index  -> value, type, chain
					-- {['1']={value=10086, chain=2, lock=true}}
					-- {['5']={value={['1']=5,['2']=2.5,['3']='A'}, chain=1}}
					-- {['32']={value={param={}, notch={}},chain=1}}
	EntitySet[0]={value=nil, chain=0}	-- default special value
end
function _M.existName(name)
	return Namespace[name]
end
function _M.linkNameEntity(name, value, untyped, index, lock)	-- untyped for RAW_INPUT, index for LIST, const for Const
	if Namespace[name] and Namespace[name]~=0 then	-- modify Entity
		if EntitySet[Namespace[name]].lock then
			err(1,'Cannot modify a Locked Entity')
			return
		elseif value then
			if index then
				EntitySet[Namespace[name]].value[index]=value
			else
				EntitySet[Namespace[name]].value=value
			end
			if lock then
				EntitySet[Namespace[name]].lock=true	-- add Lock attribute
			end
		else
			setRef(name,0)
		end
	elseif lock and Namespace[name]==0 then
		err(1,'Cannot Lock NIL')
		return
	else
		setName(name)				-- default is NIL
		if value then
			local _idx				-- set to new Entity
			if not untyped then
				_idx=setEntity(value,lock)
			else
				if tonumber(value) then
					_idx=setEntity(tonumber(value))		-- for RAW INPUT, look as number as possible
				else
					_idx=setEntity(value)
				end
			end
			setRef(name, _idx)
			if lock then
				EntitySet[Namespace[name]].lock=true	-- add Lock attribute
			end
		end
	end
	return true
end
function _M.aliasName(name_src, name_dst)
	if type(name_src)=='string' then
		if not Namespace[name_src] then
			err(1,'Name "'..name_src..'" is NUL')
			return false
		end
		setName(name_dst)
		setRef(name_dst,Namespace[name_src])
	else
		local _addr = name_src
		if not EntitySet[_addr] then
			err(1,'Address "'.._addr..'" is NUL')
			return false
		end
		setName(name_dst)
		setRef(name_dst,_addr)
	end
	return true
end
function _M.delName(name)
	if Namespace[name] then
		EntitySet[Namespace[name]].chain=EntitySet[Namespace[name]].chain-1
		Namespace[name]=nil
	else
		err(1,'Name "'..name..'" is NUL')
		return false
	end
end
function _M.unlockEntity(name)
	if Namespace[name] then
		EntitySet[Namespace[name]].lock=nil
	else
		err(1,'Name "'..name..'" is NUL')
		return false
	end
end
function _M.getNameRef(name)
	return Namespace[name]
end
function _M.getNameType(name)
	if not Namespace[name] then return nil end
	if name:sub(1,1)=='$' then
		return 'FUNC'
	else
		return 'VESL'
	end
end
function _M.getEntityChain(name)
	return Namespace[name] and EntitySet[Namespace[name]].chain or nil
end
function _M.getEntityValue(name,index)
	if Namespace[name] and EntitySet[Namespace[name]].value then
		if index then
			return EntitySet[Namespace[name]].value[index]
		else
			return EntitySet[Namespace[name]].value
		end
	end
	return nil
end
function _M.getEntityValueParam(name)
	return Namespace[name] and EntitySet[Namespace[name]].value.param or nil
end
function _M.getEntityType(name)
	if Namespace[name] and EntitySet[Namespace[name]].value then
		if type(EntitySet[Namespace[name]].value)=='number' then
			return 'NUM'
		elseif type(EntitySet[Namespace[name]].value)=='string' then
			return 'STR'
		elseif type(EntitySet[Namespace[name]].value)=='table' then
			if EntitySet[Namespace[name]].value.notch then
				return 'FUNC'
			else
				return 'LIST'
			end
		else
			return 'NIL'
		end
	else
		return nil
	end
end
function _M.displayList(name, showIndex)
	local _value='['
	local _empty = true
	for k,v in pairs(EntitySet[Namespace[name]].value) do
		if type(v)=='string' then
			if showIndex==true then 
				_value=_value..k..':"'..v..'",'
			else
				_value=_value..'"'..v..'",'
			end
		else
			if showIndex==true then 
				_value=_value..k..':'..v..','
			else
				_value=_value..''..v..','
			end
		end
		_empty=false
	end
	if not _empty then _value=_value:sub(1,#_value-1) end
	_value=_value..']'
	print(_value)
end
function _M.dbg(name)
	if name and Namespace[tostring(name)] then	-- Debug one name
		print('['..name..']\tref: '..Namespace[name])
		if Namespace[name]~=0 then
			local _value
			if type(EntitySet[Namespace[name]].value)=='number' or type(EntitySet[Namespace[name]].value)=='string' then
				_value=(EntitySet[Namespace[name]].value or '')
			elseif not EntitySet[Namespace[name]].value.notch then		-- LIST
				_value='['
				local _empty = true
				for k,v in pairs(EntitySet[Namespace[name]].value) do
					if type(v)=='string' then
						_value=_value..k..':"'..v..'",'
					else
						_value=_value..k..':'..v..','
					end
					_empty=false
				end
				if not _empty then _value=_value:sub(1,#_value-1) end
				_value=_value..']'
			else
				_value = '{'
				local _empty = true
				for k=1,#EntitySet[Namespace[name]].value.param do
					_value=_value..tostring(EntitySet[Namespace[name]].value.param[k])..','
					_empty=false
				end
				if not _empty then _value=_value:sub(1,#_value-1) end
				_value=_value..'|}'
			end
			local ConstSigil = ''
			if EntitySet[Namespace[name]].lock then
				ConstSigil='<Locked>'
			end
			print('ref->\tchain: '.._M.getEntityChain(name)..'\ttype: '.._M.getEntityType(name)..'\tvalue: '.._value..'\t'..ConstSigil)
		else
			print('ref->\tNIL')
		end
	elseif not name then					-- Debug ALL names
		print('[Namespace]')
		print('name\tref')
		for k,v in pairs(Namespace) do
			print(k..'\t'..v)			-- k=name, v=ref
		end
		print('<EntitySet>')
		print('IDX\tchain\ttype\tvalue')
		for i=0,ENTITY_TOP do
			if EntitySet[i] then
				local _type = 'NIL'
				if type(EntitySet[i].value)=='number' then _type = 'NUM'
				elseif type(EntitySet[i].value)=='string' then _type = 'STR'
				elseif type(EntitySet[i].value)=='table' then
					if EntitySet[i].value.notch then
						_type = 'FUNC'
					else
						_type = 'LIST'
					end
				else _type = 'NIL' end
				local _value = ''
				if not EntitySet[i].value then	-- NIL
					_value=''
				elseif type(EntitySet[i].value)=='number' or type(EntitySet[i].value)=='string' then	-- NUM or STR
					_value=(EntitySet[i].value or '')
				elseif not EntitySet[i].value.notch then		-- LIST
					_value='['
					local _empty = true
					for k,v in pairs(EntitySet[i].value) do
						_value=_value..v..','
						_empty=false
					end
					if not _empty then _value=_value:sub(1,#_value-1) end
					_value=_value..']'
				else											-- FUNC
					_value = '{'
					local _empty = true
					for k=1,#EntitySet[i].value.param do
						_value=_value..tostring(EntitySet[i].value.param[k])..','
						_empty=false
					end
					if not _empty then _value=_value:sub(1,#_value-1) end
					_value=_value..'|}'
				end
				local ConstSigil = ''
				if EntitySet[i].lock then
					ConstSigil='<Locked>'
				end
				print(i..'\t'..EntitySet[i].chain..'\t'.._type..'\t'.._value..'\t'..ConstSigil)
			end
		end
	else
		err(1,'Name "'..name..'" is NUL')
	end
end

-----------------------------------------------------------------------------
-- Debug functions
-----------------------------------------------------------------------------
function _M.test()
	_M.dbg()
end

-----------------------------------------------------------------------------
return _M
