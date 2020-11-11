if ( SERVER ) then
	AddCSLuaFile("quest/vgui/DQuestsPanel.lua")
	AddCSLuaFile("quest/vgui/DQuestItem.lua")
	AddCSLuaFile("quest/vgui/DQuestProgressBar.lua")
	AddCSLuaFile("quest/cl_main.lua")
	AddCSLuaFile("quest/sh_main.lua")
	include("quest/sh_main.lua")
else
	include("quest/sh_main.lua")
end