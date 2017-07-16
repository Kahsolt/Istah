#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Lexer Module
-- Name: islex
-- Author: Kahsolt
-- Time: 2016-12-16
-- Version: 1.8
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module & import dependencies
-----------------------------------------------------------------------------
islex = {}			-- 模块名
local _M = islex	-- 临时模块名
dofile('isenv.lua')	-- 执行全局参数设定
dofile('iscfg.lua')
require 'iserr'

-----------------------------------------------------------------------------
-- Private variables & functions
-----------------------------------------------------------------------------
local input = ''	-- Current char
local inputs = ''	-- Current buffer

-- Judger
local function isEOF()		return not input	end
local function isNL()		return input=='\n'	end
local function isNonsense()	return input=='\0' or input==' ' or input=='' or input=='\t' or input=='\r' or input=='\n' end
local function isLetter()	return input and ('A'<=input and input<='Z' or 'a'<=input and input<='z') end
local function isDigit()	return input and ('0'<=input and input<='9') end
local function isDot()		return input=='.'	end
local function isULine()	return input=="_"	end
local function isDollar()	return input=="$"	end
local function isPound()	return input=='#'	end
local function isAt()		return input=='@'	end
local function isWave()		return input=='~'	end
local function isAdd()		return input=='+'	end
local function isSub()		return input=='-'	end
local function isMul()		return input=='*'	end
local function isDiv()		return input=='/'	end
local function isMod()		return input=='%'	end
local function isPwr()		return input=='^'	end
local function isAnd()		return input=='&'	end
local function isOr()		return input=='|'	end
local function isNot()		return input=='!'	end
local function isEqu()		return input=='='	end
local function isLes()		return input=='<'	end
local function isGrt()		return input=='>'	end
local function isQuery()	return input=='?'	end
local function isQuote()	return input=="'"	end
local function isDbQuote()	return input=='"'	end
local function isBackSlash()return input=='\\'	end
local function isComma()	return input==','	end
local function isColon()	return input==':'	end
local function isSemiColon()return input==';'	end
local function isLrdbr()	return input=='('	end
local function isRrdbr()	return input==')'	end
local function isLagbr()	return input=='<'	end
local function isRagbr()	return input=='>'	end
local function isLsqbr()	return input=='['	end
local function isRsqbr()	return input==']'	end
local function isLclbr()	return input=='{'	end
local function isRclbr()	return input=='}'	end

-- Tools
local function readInput()
	input=FileIn:read(1)		-- EOF returns nil as well
	if input=='\n' then
		Cur_Line=Cur_Line+1		-- compatible with Windows & Linux
		Cur_Column=0
	else
		Cur_Column=Cur_Column+1
	end
end
local function initInput()		-- Pre-Read: keep head char of the next token in 'input'
	while not isEOF() and isNonsense() do readInput() end
end
local function nextInput()		-- Admit & read next
	inputs = inputs..input
	readInput()
end
local function initInputs()		-- Clear the old buffer info
	inputs = ''
	Token = {type=TokenType.BAD,value=nil}
end
local function err(level,msg)
	iserr.what('Islex',msg,level)
end

-----------------------------------------------------------------------------
-- Pulic variables & functions
-----------------------------------------------------------------------------
function _M.init(fin)
	if not fin then fin = ISTAH_FILEIN end
	FileIn = io.open(fin, "r")
	Cur_Line = 1
	Cur_Column = 0
	if not FileIn then
		err(0,'Cannot open input file "'..fin..'"')
	end
	initInput()
	if ISTAH_DBG_LEX then print('Lex head letter='..input) end
	return true
end
function _M.nextToken()
	initInputs()	-- Clear old buffer info
	if isEOF() then return nil end

	-- [[REM: now 'input' is already the head char of the token to extract]] --
	-- [[REM: after extract this token successfully, set 'input' to the next char]] --
	-- print("[Head Char:] '"..input.."'")		-- current token head char
	if isLetter() or isDollar() or isULine() then	-- Get Name
		if isDollar() then
			Token.type=TokenType.FUNC
			nextInput()
		elseif isULine() then			-- psuedo Local Vesl
			Token.type=TokenType.VESL
			nextInput()
		else
			Token.type=TokenType.VESL
		end
		while isLetter() or isDigit() or isULine() do nextInput() end
		Token.value = inputs
	elseif isDigit() then		-- Get Data - NUM	-- unsigned INT & REAL
		local _dot = 0
		while isDigit() or isDot() do
			if isDot() then _dot=_dot+1 end		-- support digit omitting as: 3.(=3.0)
			nextInput()
		end
		if _dot >= 2 then
			err(0,'Bad float number')
		else
			Token.type=TokenType.NUM
			Token.value=tonumber(inputs)
		end
	elseif isQuote() then		-- Get Data - STR	-- save content only, quotes '' not!
		readInput()	-- skip begin '
		if isNL() or isEOF() then
			readInput()
			Token.type=TokenType.NIL 	-- ''' - Nil STR
		elseif isQuote() then			-- ''''
			Token.type=TokenType.STR
			Token.value=tostring('')
			readInput()		-- skip end '
		else
			while not isNL() and not isEOF() do
				if isBackSlash() then		-- '\' is the escape letter
					readInput()
					if input=='n' then readInput() inputs=inputs..'\n'
					elseif input=='r' then readInput() inputs=inputs..'\r'
					elseif input=='t' then readInput() inputs=inputs..'\t'
					elseif input=='0' then readInput() inputs=inputs..'\0'
					else nextInput()  end
					-- print('aft inputs='..inputs)
				elseif isQuote() then
					Token.type=TokenType.STR
					Token.value=tostring(inputs)
					readInput()		-- skip end '
					--print('fin inputs='..inputs)
					break
				elseif isNL() or isEOF() then
					err(0,'STR missing right quote \'\'\'')
				else
					nextInput()
				end				
			end
		end
	elseif isDbQuote() then		-- Get Cmd - CMD	-- save content only, quotes "" not!
		readInput()
		if isNL() or isEOF() then
			err(0,'Lua Cmd missing right double quote \'"\'')
		else
			while not isNL() and not isEOF() do
				if isDbQuote() then break end
				nextInput()
			end
			Token.type=TokenType.CMD
			Token.value=tostring(inputs)
			readInput()
		end 
	elseif isAt()		then Token.type,_=TokenType.DBG,readInput()			-- '@'
	elseif isWave()		then Token.type,_=TokenType.WAVE,readInput()		-- '~'
	elseif isMul()		then Token.type,_=TokenType.MUL,readInput()			-- '*'
	elseif isMod() 		then Token.type,_=TokenType.MOD,readInput()			-- '%'
	elseif isPwr() 		then Token.type,_=TokenType.PWR,readInput()			-- '^'
	elseif isComma()	then Token.type,_=TokenType.COMMA,readInput()		-- ','
	elseif isQuery()	then Token.type,_=TokenType.QUERY,readInput()		-- '?'
	elseif isLrdbr()	then Token.type,_=TokenType.LRDBR,readInput()		-- '('
	elseif isRrdbr()	then Token.type,_=TokenType.RRDBR,readInput()		-- ')'
	elseif isLsqbr()	then Token.type,_=TokenType.LSQBR,readInput()		-- '['
	elseif isRsqbr()	then Token.type,_=TokenType.RSQBR,readInput()		-- ']'
	elseif isRclbr()	then Token.type,_=TokenType.RCLBR,readInput()		-- '}'
	elseif isLclbr()	then Token.type,_=TokenType.LCLBR,readInput()		-- '{'
	elseif isPound() then
		readInput()
		while not isEOF() and not isPound() do readInput() end	-- # skip block comments #
		readInput()
		initInput()
		return _M.nextToken()	-- go on next Token
	elseif isSemiColon() then
		while not isEOF() and not isNL() do readInput() end		-- ; skip to-line-end comment
		readInput()
		initInput()
		return _M.nextToken()	-- go on next Token
	elseif isDot() then
		readInput()
		if isDot() then
			Token.type=TokenType.CONCAT		-- '..'
			readInput()
		else
			Token.type=TokenType.NIL		-- '.'	-- Nil NUM
		end
	elseif isDiv() then
		readInput()
		if isRagbr() then
			Token.type=TokenType.WRITE		-- '/>'
			readInput()
		elseif isDiv() then
			Token.type=TokenType.DIV_TRUNC	-- '//'
			readInput()
		else
			Token.type=TokenType.DIV		-- '/'
		end
	elseif isSub() then
		readInput()
		if isRagbr() then
			Token.type=TokenType.PTR		-- '->'
			readInput()
		else
			Token.type=TokenType.SUB		-- '-'
		end
	elseif isAdd() then
		readInput()
		if isRagbr() then
			Token.type=TokenType.INCLUDE	-- '+>'
			readInput()
		else
			Token.type=TokenType.ADD		-- '+'
		end
	elseif isOr() then
		readInput()
		if isOr() then
			Token.type=TokenType.OR			-- '||'
			readInput()
		elseif isRclbr() then
			Token.type=TokenType.NIL		-- '|}'		-- Nil FUNC
			readInput()
		else
			Token.type=TokenType.SEGMT		-- '|'
		end
	elseif isAnd() then
		readInput()
		if isAnd() then
			Token.type=TokenType.AND		-- '&&'
			readInput()
		elseif isEqu() then
			Token.type=TokenType.ALIAS		-- '&='
			readInput()
		else
			Token.type=TokenType.ADDR		-- '&'
		end
	elseif isColon() then
		readInput()
		if isEqu() then
			Token.type=TokenType.LOCK		-- ':='
			readInput()
		else
			Token.type=TokenType.COLON		-- ':'
		end
	elseif isNot() then
		readInput()
		if isEqu() then
			Token.type=TokenType.NEQ		-- '!='
			readInput()
		else
			Token.type=TokenType.NOT		-- '!'
		end
	elseif isEqu() then
		readInput()
		if isEqu() then
			Token.type=TokenType.EQU		-- '=='
			readInput()
		elseif isRagbr() then
			Token.type=TokenType.RET		-- '=>'
			readInput()
		else
			Token.type=TokenType.LINK		-- '='
		end
	elseif isLagbr() then
		readInput()
		if isEqu() then
			Token.type=TokenType.ELT		-- '<='
			readInput()
		elseif isLagbr() then
			Token.type=TokenType.INPUT		-- '<<'
			readInput()
		else
			Token.type=TokenType.LES		-- '<'
		end
	elseif isRagbr() then
		readInput()
		if isEqu() then
			Token.type=TokenType.EGT		-- '>='
			readInput()
		elseif isRagbr() then
			Token.type=TokenType.OUTPUT		-- '>>'
			readInput()
		else
			Token.type=TokenType.GRT		-- '>'
		end
	else
		readInput()
		err(1,'Unkown character')
		initInput()
		return _M.nextToken()
	end

	initInput()		-- Prepare for the next token
	return Token
end
function _M.setNotch()		-- used by WHILE clause
	local _notch = {}
	_notch.cur = FileIn:seek()
	_notch.input = input
	_notch.type = Token.type
	_notch.value = Token.value
	_notch.Cur_Line = Cur_Line
	_notch.Cur_Column = Cur_Column
	return _notch
end
function _M.gotoNotch(notch)		-- used by WHILE clause
	FileIn:seek('set',notch.cur)
	input = notch.input
	Token.type = notch.type
	Token.value = notch.value
	Cur_Line = notch.Cur_Line
	Cur_Column = notch.Cur_Column
end
function _M.clearToken()
	Token={}
	input=''
	inputs=''
end

-----------------------------------------------------------------------------
-- Debug Functions
-----------------------------------------------------------------------------
function _M.test(fin)
	_M.init(fin)
	print("<Type>\t<Value>")
	while true do
		t=_M.nextToken()
		if not t then break end
		if ISTAH_DBG_LEX then
			print((t['type'] or '*')..'\t'..(t['value'] or ''))
		end
	end
end

-----------------------------------------------------------------------------
return _M
