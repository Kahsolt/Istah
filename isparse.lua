#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Parser Module
-- Name: isparse
-- Author: Kahsolt
-- Time: 2017-1-4
-- Version: 3.1
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
isparse = {}		-- 模块名
local _M = isparse	-- 临时模块名
dofile('isenv.lua')	-- 搭建全局环境
dofile('iscfg.lua')
require 'islex'		-- 引入模块
require 'isname'
require 'isgc'
require 'ishub'
require 'islua'
require 'iserr'

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
-- Tools
local function testToken(type)		-- test only
	return Token.type==TokenType[type]
end
local function absorbToken(type)	-- test, if match then get next token
	if Token.type==TokenType[type] then
		islex.nextToken()
		return true
	else
		return false
	end
end
local function getToken()	-- get VESL, FUNC, NUM, STR, CMD
	t=Token.value			-- get name of VESL|FUNC or value of NUM|STR|CMD
	islex.nextToken()
	return t
end
local function copyTable(from)
	local to={}
	for k,v in pairs(from) do
		if type(v)=='table' then
			to[tostring(k)]={}
			to=copyTable(v, to[tostring(k)])
		else
			to[tostring(k)]=v
		end
	end
	return to
end
local function err(level,msg)
	iserr.what('Isparse',msg,level)
end

-- Local Debug
local function dbg(func)
	if ISTAH_DBG then
		print('[Func] '..func..'\t[Token] '..(Token.type or '<NK>')..'\t'..(Token.value or '<Symbol>'))
	end
end

-- Parsers
local parseExecutionBlock, parseStatement, parseControl, parseData, parseCommand
function parseExecutionBlock()					-- <执行块>	::=	{<语句>|<控制>}
	dbg('EB')
	if Msg_While=='break' or Msg_While=='continue' or Msg_Func=='return' then return end
	while testToken('VESL') or testToken('FUNC') or testToken('RET') or testToken('ELT') or testToken('DBG') or testToken('INPUT') or testToken('OUTPUT') or testToken('WRITE') or testToken('INCLUDE') or testToken('LAGBR') or testToken('LSQBR') do
		if testToken('VESL') or testToken('FUNC') or testToken('RET') or testToken('ELT') or testToken('DBG') or testToken('INPUT') or testToken('OUTPUT') or testToken('WRITE') or testToken('INCLUDE') then
			parseStatement()
		elseif testToken('LAGBR') or testToken('LSQBR') then
			parseControl()
		end
		if Msg_While=='break' or Msg_While=='continue' or Msg_Func=='return' then return end
	end
end
function parseStatement()						-- <语句>	::=	<容器处理>|<函数处理>|<退返句>|<调试句>|<输入句>|<输出句>
	dbg('S')
	local parseStatementHandleVessel, parseStatementHandleFunction, parseStatementReturn, parseStatementBack, parseStatementDebug, parseStatementInput, parseStatementOutput
	function parseStatementHandleVessel()		-- <容器处理>	::=	<容器名>'='('!'|'.'|'''|'{}'|<数符式>|<函数处理>|<数组构造式>)|<容器名>'&='<容器名>|<容器名>:<代数式>='!'|'.'|'''|<数符式>|<容器名[:索引值]>'->'<索引值>
		dbg('SHV')
		local _vesl=getToken()
		if absorbToken('LINK') then
			if absorbToken('NUL') then
				isname.delName(_vesl)
			elseif absorbToken('NIL') then
				isname.linkNameEntity(_vesl,nil)
			elseif absorbToken('LSQBR') then		-- LIST construct
				local _list = {}
				local _idx = 1
				while not testToken('RSQBR') do
					local _val
					if absorbToken('NIL') then
						_val=nil
					else
						_val = parseData()
						if not _val then err(0,'Invalid value in List constructor') end
					end
					_list[_idx]=_val
					_idx=_idx+1
					if testToken('RSQBR') then break
					elseif testToken('COMMA') then absorbToken('COMMA')
					else err(0,'Missing Comma') end
				end
				absorbToken('RSQBR')
				isname.linkNameEntity(_vesl,_list)
			elseif testToken('FUNC') then
				parseStatementHandleFunction()		-- FUNC call, with attainment of Ret_Func
				local _ret = Ret_Func
				isname.linkNameEntity(_vesl,_ret)
			elseif testToken('CMD') then
				local _ret = parseCommand()
				isname.linkNameEntity(_vesl,_ret)
			else
				local _exp = parseData()			-- could be a LIST STRUCTURE
				if not _exp then
					err(0,'Bad Expression Value')
				else
					if ISTAH_DBG_DATA then print('_exp='.._exp) end
					isname.linkNameEntity(_vesl,_exp)
				end
			end
		elseif absorbToken('LOCK') then
			if absorbToken('NUL') then
				isname.unlockEntity(_vesl)
			else
				local _exp = parseData()	-- could be a LIST STRUCTURE
				if not _exp then
					err(0,'Must be an Expression Value')
				else
					if ISTAH_DBG_DATA then print('_exp='.._exp) end
					local LOCK = true
					isname.linkNameEntity(_vesl,_exp,false,false,LOCK)
				end
			end
		elseif absorbToken('ALIAS') then
			local _vesl_exist = getToken()
			if not isname.existName(_vesl_exist) then
				err(0,'Name "'.._vesl_exist..'" is NUL')
			elseif isname.getNameType(_vesl_exist)~='VESL' then
				err(1,'Name "'.._vesl_exist..'" is not a VESL')
			else
				isname.aliasName(_vesl_exist,_vesl)
			end
		elseif absorbToken('PTR') then
			local _addr = parseData()
			if type(_addr)~='number' or _addr%1~=0 then
				err(0,'Address index shoud be an Integer natural number')
			end
			if ISTAH_DBG_DATA then print('_addr='.._addr) end
			isname.aliasName(_addr,_vesl)
		elseif absorbToken('COLON') then
			if not isname.existName(_vesl) then
				err(0,'Name "'.._vesl..'"" is NUL')
			elseif isname.getEntityType(_vesl)~='LIST' then
				err(0,'Name "'.._vesl..'"" is NOT a List Structured Vesl')
			end
			local _idx = parseData()
			if type(_idx)~='number' then
				err(0,'List index shoud be a number')
			else
				if absorbToken('LINK') then
					local _exp = parseData()
					if not _exp then
						err(1,'Bad Expression Value')
					else
						isname.linkNameEntity(_vesl,_exp,false,_idx)	-- untyped=false, idx for LIST only
					end
				else
					err(0,'Missing a LINK')
				end
			end
		end
	end
	function parseStatementHandleFunction()		-- <函数处理>::=<函数名>'=''{'[<容器名>{','<容器名>}]'|'<执行块>'}'|<函数名>'&='<函数名>|<函数名>'{'[<数符式>{','<数符式>}]'}'
		dbg('SHF')
		local _func=getToken()
		if absorbToken('ALIAS') then
			local _func_exist = getToken()
			if not isname.existName(_func_exist) then
				err(0,'Name "'.._func_exist..'" is NUL')
			elseif isname.getNameType(_func_exist)~='FUNC' then
				err(1,'Name "'.._func_exist..'" is not a FUNC')
			else
				isname.aliasName(_func_exist,_func)
			end
		elseif absorbToken('LINK') then		
			if absorbToken('NUL') then
				isname.delName(_func)
			elseif absorbToken('NIL') then
				isname.linkNameEntity(_func,nil)
			else 									-- FUNC definition
				absorbToken('LCLBR')
				local _func_param = {}
				while testToken('VESL') do
					local _param = getToken()
					_func_param[#_func_param+1]=tostring(_param)
					if not testToken('SEGMT') then
						absorbToken('COMMA')
					end
				end
				absorbToken('SEGMT')
				local _func_notch = islex.setNotch()	-- set a Notch to go there later
				local _func_entity = {}
				_func_entity.param=_func_param
				_func_entity.notch=_func_notch
				isname.linkNameEntity(_func,_func_entity)
				local _innet_count = 0
				while true do
					if ISTAH_DBG_FUNC then print('_innet_count_func='.._innet_count) end
					if testToken('LCLBR') then			-- skip inner {}
						_innet_count=_innet_count+1
					elseif testToken('RCLBR') then
						_innet_count=_innet_count-1
						if _innet_count==-1 then break end
					end
					islex.nextToken()
				end
				absorbToken('RCLBR')
			end
		elseif testToken('LCLBR') then		-- DO FUNC CALL!!!
			if ISTAH_DBG_FUNC then print('Do FUNC Call') end
			if not isname.existName(_func) then
				err(0,'Func "'.._func..'" is NUL')
			end
			-- load params
			absorbToken('LCLBR')
			local _param = isname.getEntityValue(_func).param
			for i=1,#_param do
				local _val=parseData()
				if not _val then
					err(0,'FUNC Params Error in value or number in the call')
				else
					isname.linkNameEntity(_param[i],_val)
				end
				absorbToken('COMMA')
			end
			if not absorbToken('RCLBR') then
				err(0,'FUNC Params too much in call')
			end
			-- save main_notch, goto func_notch
			local _main_notch = islex.setNotch()	-- save current Main notch
			Notch_Func=copyTable(_main_notch)		-- carve it for ret
			local _func_notch = isname.getEntityValue(_func).notch
			islex.gotoNotch(_func_notch)
			-- do FUNC structure
			Msg_Func=''
			Ret_Func=nil
			parseExecutionBlock()	-- ends for example meets '}' or '=>'
			Msg_Func=''		-- clear message
			-- clean params
			for i=1,#_param do
				if isname.existName(_param[i]) then
					isname.delName(_param[i])
				end
			end
			isgc.gc()		-- force gc()
			-- restore notch
			islex.gotoNotch(_main_notch)
		end
	end
	function parseStatementReturn()				-- <退返句>::='=>'{<数符式>|<调用句>}
		dbg('SR')
		absorbToken('RET')
		if testToken('FUNC') then
			parseStatementHandleFunction()		-- FUNC call, with attainment of Ret_Func
			local _ret = Ret_Func
			if Notch_Func.cur then
				Ret_Func = _ret
				Msg_Func = 'return'
			else
				err(0,'Fatal: Missing a Notch to return')
			end
		elseif testToken('ADD') or testToken('SUB') or testToken('LRDBR') or testToken('NUM') or testToken('STR') or testToken('VESL') then
			local _ret=parseData()
			if Notch_Func.cur then
				Ret_Func = _ret
				Msg_Func = 'return'
			else
				err(0,'Fatal: Missing a Notch to return')
			end
		else
			if Notch_While.cur then
				Msg_While = 'break'
				-- islex.gotoNotch(Notch_While)
			else
				err(0,'Fatal: Missing a Notch to break')
			end
		end
	end
	function parseStatementBack()				-- <回车句>::='<='
		dbg('SR')
		absorbToken('ELT')
		if Notch_While.cur then
			Msg_While = 'continue'
			-- islex.gotoNotch(Notch_While)
		else
			err(0,'Fatal: Missing a Notch to continue')
		end
	end
	function parseStatementDebug()				-- <调试句>::='@'[('~'|'*'|<容器名>|<函数名>)]
		dbg('SD')
		absorbToken('DBG')
		if absorbToken('WAVE') then
			isgc.gc()
		elseif absorbToken('MUL') then
			isname.dbg()
		elseif testToken('VESL') or testToken('FUNC') then
			local _name = getToken()
			isname.dbg(_name)
		end
	end
	function parseStatementInput()				-- <输入句>::='<<'<容器名>
		dbg('SI')
		absorbToken('INPUT')
		local _vesl=getToken()
		local _value=io.read('*l')	-- read a line
		local UNTYPED = true		-- used by RAW INPUT
		isname.linkNameEntity(_vesl,_value,UNTYPED)
	end
	function parseStatementOutput()				-- <输出句>::=('>>'|'/>')<数符式>|<列表容器>|<调用句>
		dbg('SO')
		local _data
		local _list
		if absorbToken('WRITE') then		-- '/>'
			if testToken('FUNC') then
				parseStatementHandleFunction()		-- FUNC call, with attainment of Ret_Func
				local _ret = Ret_Func
				io.write(tostring(_ret) or 'NIL')
			else
				if testToken('VESL') and isname.getEntityType(Token.value)=='LIST' then
					_list=Token.value
				end
				_data = parseData()
				if type(_data)=='table' then
					local _showIndex = true
					isname.displayList(_list,_showIndex)
				else
					io.write(tostring(_data) or 'NIL')
				end
			end
		elseif absorbToken('OUTPUT') then	-- '>>'
			if testToken('FUNC') then
				parseStatementHandleFunction()		-- FUNC call, with attainment of Ret_Func
				local _ret = Ret_Func
				print(tostring(_ret) or 'NIL')
			else
				if testToken('VESL') and isname.getEntityType(Token.value)=='LIST' then
					_list=Token.value
				end
				_data = parseData()
				if type(_data)=='table' then
					local _showIndex = false
					isname.displayList(_list,_showIndex)
				else
					print(tostring(_data) or 'NIL')
				end
			end
		end
	end

	if testToken('VESL') then return parseStatementHandleVessel()
	elseif testToken('FUNC') then return parseStatementHandleFunction()
	elseif testToken('RET') then return parseStatementReturn()
	elseif testToken('ELT') then return parseStatementBack()
	elseif testToken('DBG') then return parseStatementDebug()
	elseif testToken('INPUT') then return parseStatementInput()
	elseif testToken('OUTPUT') or testToken('WRITE') then return parseStatementOutput()
	else return nil end
end
function parseControl()							-- <控制>	::=<分支结构>|<循环结构>
	dbg('C')
	local parseControlLogicExpression, parseControlLogicFactor
	local parseControlBranch, parseControlLoop
	function parseControlLogicExpression()		-- <逻辑式>::=<逻辑子>[('&&'|'||')<逻辑子>]
		dbg('CLE')
		if testToken('MUL') or testToken('NUM') or testToken('STR') or testToken('VESL') or testToken('LRDBR') or testToken('NOT') then
			local _l = parseControlLogicFactor()
			if testToken('AND') or testToken('OR') then
				local _op
				if absorbToken('AND') then _op = 'AND'
				elseif absorbToken('OR') then _op='OR'
				else err(0,'Uncoginzed Logic Operator') end
				local _r = parseControlLogicFactor()
				if ISTAH_DBG_LOGIC then  print('[Compare Expression]  _l='..tostring(_l)..'\t_r='..tostring(_r)..'\t_op='.._op) end
				if _l==nil or _r==nil then return nil
				elseif _op == 'AND' then
					return (_l and _r)
				else
					return (_l or _r)
				end
			else
				return (_l)
			end
		else
			return nil
		end
	end
	function parseControlLogicFactor()			-- <逻辑子>::='*'|'!'<逻辑子>|'('<逻辑式>')'|<数据>{('=='|'!='|'>='|'<='|'>'|'<')<数据>}
		dbg('CLF')
		if absorbToken('MUL') then 
			return true
		elseif absorbToken('NOT') then
			local _logexp = parseControlLogicFactor()
			if _logexp==nil then return nil
			else return (not _logexp) end
		elseif absorbToken('LRDBR') then
			if ISTAH_DBG_LOGIC then print('[_logexp Got into a ()]') end
			local _logexp = parseControlLogicExpression()
			absorbToken('RRDBR')
			return _logexp
		elseif testToken('SUB') or testToken('NUM') or testToken('STR') or testToken('VESL') then
			local _l = parseData()
			local _op
			if testToken('EQU') or testToken('NEQ') or testToken('ELT') or testToken('EGT') or testToken('LES') or testToken('GRT') then
				if absorbToken('EQU') then _op='EQU'
				elseif absorbToken('NEQ') then _op='NEQ'
				elseif absorbToken('ELT') then _op='ELT'
				elseif absorbToken('EGT') then _op='EGT'
				elseif absorbToken('LES') then _op='LES'
				elseif absorbToken('GRT') then _op='GRT' end
				if testToken('SUB') or testToken('NUM') or testToken('STR') or testToken('VESL') or testToken('LRDBR') then
					local _r = parseData()
					if ISTAH_DBG_LOGIC then print('[Compare Factor Type]  _l_type='..tostring(type(_l))..'\t _r_type='..tostring(type(_r))) end
					if type(_l)~=type(_r) then
						if _op=='NEQ' then
							return true
						else
							err(1,'Cannot compare between different Datatypes')
						end
					else
						if _l==nil or _r==nil then return nil end
						if ISTAH_DBG_LOGIC then print('[Compare Factor]  _l='.._l..'\t _r='.._r..'\t_op='.._op) end
						local _ret
						if _op=='EQU' then _ret=(_l==_r)
						elseif _op=='NEQ' then _ret=(_l~=_r)
						elseif _op=='ELT' then _ret=(_l<=_r)
						elseif _op=='EGT' then _ret=(_l>=_r)
						elseif _op=='LES' then _ret=(_l<_r)
						elseif _op=='GRT' then _ret=(_l>_r) end
						if ISTAH_DBG_LOGIC then print('_ret='..(tostring(_ret) or '')) end
						return _ret
					end
				end
			else return (_l~=nil) end
		else
			err(0,'Bad Logic Factor')
		end
	end
	function parseControlBranch()				-- <分支结构>::='<'<逻辑式>'?'<执行块>{'|'<逻辑式>'?'<执行块>}'>'
		dbg('CB')
		if testToken('LAGBR') then
			while absorbToken('LAGBR') or absorbToken('SEGMT') do
				local _logexp=parseControlLogicExpression()
				absorbToken('QUERY')
				if ISTAH_DBG_BRANCH then print('Branch _logexp='..tostring(_logexp)) end
				if _logexp==true then
					parseExecutionBlock()	-- then goto end
					while true do
						if testToken('RAGBR') then break end 	-- meet the end
						if testToken('LSQBR') then
							local _innet_count = 0
							while true do
								if testToken('LSQBR') then			-- skip inner []
									_innet_count=_innet_count+1
								elseif testToken('RSQBR') then
									_innet_count=_innet_count-1
									if _innet_count==0 then break end
								end
								islex.nextToken()
							end
						else
							islex.nextToken()
						end
					end
					break
				else
					while not testToken('SEGMT') and not testToken('RAGBR') do islex.nextToken() end	-- skip false execute block
				end
			end
		end
		absorbToken('RAGBR')
	end
	function parseControlLoop()					-- <循环结构>::='['<逻辑式>'?'<执行块>']'
		dbg('CL')
		absorbToken('LSQBR')
		local _Notch_While = copyTable(Notch_While)
		if ISTAH_DBG_WHILE then print('Old Cur='..(_Notch_While.cur or '')) end
								-- backup previous Notch
		local _notch = islex.setNotch()			-- set a new Notch to go back again
		Notch_While = copyTable(_notch)
		if ISTAH_DBG_WHILE then print('New Cur='..(Notch_While.cur or '')) end
								-- carve new Notch to Global
		Msg_While = '' 			-- clear message

		while true do
			if Msg_While=='break' then
				Msg_While = ''
				local _innet_count=0
				while true do
					if ISTAH_DBG_WHILE then print('_innet_count='.._innet_count) end
					if testToken('LSQBR') then			-- skip inner while
						_innet_count=_innet_count+1
					elseif testToken('RSQBR') then
						_innet_count=_innet_count-1
						if _innet_count==-1 then break end
					end
					islex.nextToken()
				end
				break
			elseif Msg_While=='continue' then
				Msg_While = '' 		-- must clear message
			end
			local _logexp = parseControlLogicExpression()
			absorbToken('QUERY')
			if ISTAH_DBG_WHILE then print('Loop _logexp='..tostring(_logexp)) end
			if _logexp then
				parseExecutionBlock()
			else
				local _innet_count=0
				while true do
					if ISTAH_DBG_WHILE then print('_innet_count='.._innet_count) end
					if testToken('LSQBR') then			-- skip inner []
						_innet_count=_innet_count+1
					elseif testToken('RSQBR') then
						_innet_count=_innet_count-1
						if _innet_count==-1 then break end
					end
					islex.nextToken()
				end
				break
			end
			islex.gotoNotch(_notch)
		end
		absorbToken('RSQBR')
		Notch_While = copyTable(_Notch_While)
								-- restore previous Notch
		if ISTAH_DBG_WHILE and Notch_While.cur then
			print('Backuped Cur='.._Notch_While.cur)
			print('Restored Cur='..Notch_While.cur)
		end
	end

	if testToken('LAGBR') then return parseControlBranch()
	elseif testToken('LSQBR') then return parseControlLoop()
	end
end
function parseData()							-- <数据>	::=<代数式>|<字串式>
	dbg('D')
	local _type
	local parseDataAlgebraExpression, parseDataAlgebraTerm, parseDataAlgebraMidware, parseDataAlgebraFactor
	local parseDataStringExpression, parseDataStringFactor
	function parseDataAlgebraExpression()		-- <代数式>::=['+'|'-']<代数项>{('+'|'-')<代数项>}
		dbg('DAE')
		local _sign = 1
		if absorbToken('SUB') then _sign = -1
		else absorbToken('ADD') end
		local _a = parseDataAlgebraTerm()
		if type(_a)~='number' then 
			if ISTAH_DBG_DATA then print('_a='..(tostring(_a) or '')) end
			return _a 
		end
		if testToken('ADD') or testToken('SUB') then
			while testToken('ADD') or testToken('SUB') do
				local _op
				if absorbToken('ADD') then _op='ADD'
				elseif absorbToken('SUB') then _op='SUB' end
				local _b = parseDataAlgebraTerm()
				-- print('ADDSUB: _a='..(_a or '<BAD>')..'\t_b='..(_b or '<BAD>'))	-- inner dbg
				if type(_a)~='number' or type(_b)~='number' then
					_a=nil
				else
					if _op=='ADD' then _a=_a+_b
					else _a=_a-_b end
				end
			end
			return (_a)
		else
			return (_a and _sign*_a)
		end
	end
	function parseDataAlgebraTerm()			-- <代数项>::=<代数件>{('*'|'/'|'//'|'%')<代数件>}
		dbg('DAM')
		local _x = parseDataAlgebraMidware()
		if type(_x)~='number' then
			if ISTAH_DBG_DATA then print('_x='..(tostring(_x) or '')) end
			return _x
		end
		if testToken('MUL') or testToken('DIV') or testToken('DIV_TRUNC') or testToken('MOD') then
			while testToken('MUL') or testToken('DIV') or testToken('DIV_TRUNC') or testToken('MOD') do 
				local _op
				if absorbToken('MUL') then _op='MUL'
				elseif absorbToken('DIV') then _op='DIV'
				elseif absorbToken('DIV_TRUNC') then _op='DIV_TRUNC'
				elseif absorbToken('MOD') then _op='MOD' end
				local _y = parseDataAlgebraMidware()
				-- print('MULDIV: _x='..(_x or '<BAD>')..'\t_y='..(_y or '<BAD>'))	-- inner dbg
				if type(_x)~='number' or type(_y)~='number' then
					_x=nil
				else
					if _op=='MUL' then _x=_x*_y
					elseif _op=='DIV' then
						if _y~=0 then _x=_x/_y
						else err(0,'Algbra Error: Divided by 0.') end
					elseif _op=='DIV_TRUNC' then
						if _y~=0 then _x=math.floor(_x/_y)
						else err(0,'Algbra Error: Divided by 0.') end
					else _x=_x%_y end
				end
			end
			return (_x)
		else
			return (_x)
		end
	end
	function parseDataAlgebraMidware()			-- <代数件>::=<代数子>{'^'<代数子>}
		local _p = parseDataAlgebraFactor()
		if type(_p)~='number' then
			if ISTAH_DBG_DATA then print('_p='..(tostring(_p) or '')) end
			return _p
		end
		if testToken('PWR') then
			while absorbToken('PWR') do 
				local _q = parseDataAlgebraFactor()
				-- print('PWR: _p='..(_p or '<BAD>')..'\t_q='..(_q or '<BAD>'))	-- inner dbg
				if type(_p)~='number' or type(_q)~='number' then
					_p=nil
				else _p=_p^_q end
			end
			return (_p)
		else
			return (_p)
		end
	end
	function parseDataAlgebraFactor()			-- <代数子>::=<容器名>[:<代数式>]|&<容器名>|<数>|'('<代数式>')'
		dbg('DAF')
		if testToken('VESL') then
			local _vesl = getToken()
			if not isname.existName(_vesl) then
				err(0, 'VESL "'.._vesl..'" is NUL')
			end
			local _value
			if absorbToken('COLON') then
				local _idx = parseData()
				if type(_idx)~='number' then
					err(0,'List index shoud be a number')
				else
					_value = isname.getEntityValue(_vesl,_idx)	-- for LIST elements
				end
			else
				_value = isname.getEntityValue(_vesl)	-- for NUM, STR and LIST STRUCTURE
			end
			if _value==nil then
				-- err(1,'Value or element in Vesl "'.._vesl..'" is NIL')
				_type='NIL'
				return nil
			elseif type(_value)=='table' then
				_type='LIST'
				return _value
			elseif tonumber(_value) then
				_value = tonumber(_value)
			elseif type(_value)=='string' then
				_type ='STR'
			end
			if ISTAH_DBG_DATA then print('_value='.._value) end
			return _value
		elseif absorbToken('ADDR') then
			local _vesl = getToken()
			if not isname.existName(_vesl) then
				err(0, 'VESL "'.._vesl..'" is NUL')
			end
			local _addr = isname.getNameRef(_vesl)
			if ISTAH_DBG_DATA then print('_addr='.._addr) end
			return tonumber(_addr)
		elseif testToken('NUM') then
			return tonumber(getToken())
		elseif absorbToken('LRDBR') then
			local _exp = parseDataAlgebraExpression()
			absorbToken('RRDBR')
			return _exp
		else
			err(0, 'parseDataAlgebraFactor failed')
		end
	end
	function parseDataStringExpression()		-- <符串式>::=<符串子>{'..'<符串子>}
		dbg('DSE')
		_type='NUM'		-- assum it is a raw number
		local _str=parseDataStringFactor()
		if ISTAH_DBG_DATA then print('_str='..(tostring(_str) or '')) end
		while absorbToken('CONCAT') do
			_type='STR'
			local _seg=parseDataStringFactor()
			_str=_str..(_seg or '')
		end
		if ISTAH_DBG_DATA then print('_type='.._type) end
		if _type=='NIL' then return nil
		elseif _type=='NUM' then return tonumber(_str)
		elseif _type=='LIST' then return _str
		else return tostring(_str) end
	end
	function parseDataStringFactor()			-- <符串子>::=<符串>|<代数式>
		dbg('DSF')
		if testToken('STR') then
			_type='STR'
			return getToken()
		else
			return parseDataAlgebraExpression()
		end
	end

	-- print('[Cur TokenType]: '..Token.type)
	if (testToken('VESL') or testToken('FUNC')) and (not isname.existName(Token.value)) then
		err(0, 'Name "'..Token.value..'" is NUL')
	elseif testToken('VESL') and isname.getEntityType(Token.value)=='NIL' then
		err(0, 'Name "'..Token.value..'" is NIL')
	end
	if testToken('ADD') or testToken('SUB') or testToken('LRDBR') or testToken('NUM') or testToken('STR') or testToken('VESL') or testToken('ADDR') then
		local _data = parseDataStringExpression()
		if ISTAH_DBG_DATA then print('_data='..(tostring(_data) or '')) end
		return _data
	else
		-- print(isname.getEntityType(Token.value))
		err(0, 'Bad Data Segment Head')
	end
end
function parseCommand()							-- <命令>	::=<命令式>
	dbg('Cm')
	local parseCommandExpression, parseCommandFactor
	function parseCommandExpression()			-- <命令式>	::=<命令子>{'~'<命令项>}
		dbg('CmE')
		local _cmd=getToken()
		if ISTAH_DBG_CMD then print('_cmd='..(tostring(_cmd) or '')) end
		while absorbToken('WAVE') do
			local _cet=parseCommandFactor()
			_cmd=_cmd..(_cet or '')
		end
		return islua.call(_cmd)
	end
	function parseCommandFactor()				-- <命令项>	::=<命令子>|<数符式>
		dbg('CmF')
		if testToken('CMD') then
			return tostring(getToken())
		else
			return tostring(parseData())
		end
	end

	if testToken('CMD') then
		local _res = parseCommandExpression()
		if ISTAH_DBG_CMD then print('_res='..(tostring(_res) or '')) end
		return _res
	end	
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init(fin)
	ishub.init()
	fin=ishub.huddle(fin)
	islex.init(fin)
	isname.init()
end
function _M.exit()
	ishub.clean()
end
function _M.nextExecution(fin)
	_M.init(fin)
	islex.nextToken()		-- Pre-read a token
	-- print('Start token type='..Token.type)
	parseExecutionBlock()
	if ISTAH_GC then
		isgc.gc()		-- default GC after every execution block
	end
	if ISTAH_DBG then
		isname.test()
	end
	_M.exit()
end

-----------------------------------------------------------------------------
return _M
