WepMgr = {}

AddCSLuaFile("sh_swepedit.lua")
AddCSLuaFile("sh_defaultweps.lua")
AddCSLuaFile("cl_swepedit.lua")
AddCSLuaFile("cl_ammoedit.lua")
include("sh_swepedit.lua")
include("sh_defaultweps.lua")

if SERVER then
	include("sv_swepedit.lua")
else
	include("cl_swepedit.lua")
	include("cl_ammoedit.lua")
end