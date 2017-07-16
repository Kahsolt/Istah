#!/usr/bin/lua5.3
-----------------------------------------------------------------------------
-- Istah Public Enviroment
-- Name: isenv
-- Author: Kahsolt
-- Time: 2016-12-19
-- Version: 1.6
-- Lua Ver: 5.3
-----------------------------------------------------------------------------

-- Meta-Info Definition
TokenType={
	BAD=0,						-- Unknown Char
	LINK=100, ALIAS=101,		-- Linker
	LOCK=102, PTR=103,
	VESL=111, FUNC=112,			-- Name
	NUM=121, STR=122, CMD=123,	-- Datatype
	NUL=411, NIL=132,			-- Special Value
	WAVE=133,
	LRDBR=201, RRDBR=202,		-- Control Structure
	LAGBR=425, RAGBR=426,
	LSQBR=205, RSQBR=206,
	LCLBR=207, RCLBR=208,
	QUERY=209, SEGMT=210,
	RET=211,
	DOT=301, COMMA=302,			-- Separator
	COLON=303,
	ADD=401, SUB=402,			-- Arithmetic Operator
	MUL=403, DIV=404,
	MOD=405, PWR=406, DIV_TRUNC=407,
	NOT=411, AND=412, OR=413,	-- Logic Operator
	EQU=421, NEQ=422,			-- Comparation Operator
	ELT=423, EGT=424,
	LES=425, GRT=426,
	CONCAT=431,					-- String Operator
	DBG=500,					-- Inner Function
	INPUT=501, OUTPUT=502, WRITE=503,
	ADDR=504, INCLUDE=505,
}

-- Status Const
PwdPath		= ''				-- pwd of the init istah script
FileIn	 	= nil				-- Input file
ModPath		= 'include/'		-- Mod path
-- Status Var
Namespace	= {}				-- Name table
								-- {['var']=1,['$func']=32}
EntitySet	= {}				-- Entity table
								-- {["1"]={value="abc",chain=1},["2"]={value=3,chain=2}}
								-- {['32']={value={param={}, notch={}},chain=1}}
ENTITY_TOP	= 0					-- top index of EntitySet
Cur_Line	= 1					-- Cursor line of FileIn
Cur_Column	= 0					-- Cursor column of FileIn
-- Possible Status
Notch_While	= {}				-- a Notch for current loop
Msg_While	= ''				-- 'break' or 'continue'
Notch_Func	= {}				-- a Notch for current function
Ret_Func	= {}				-- return value
Msg_Func	= ''				-- 'return'
Notch_Include	= {}			-- a Notch for current include
-- Temp Var
Token 		= {}				-- Current token:
								-- Looks like: {type='FUNC', value='$func'} {type='NUM', value=12.345}

-- Debug Function
function ISTAH_Status()
	print("========================")
	print("Istah Interpreter Status")
	print("========================")
	print("Fin =\t"..FileIn)
	print("Loc =\t"..Cur_Line..':'..Cur_Column)
	print("Token =\t"..Token.type..':'..Token.value)
	print()
end