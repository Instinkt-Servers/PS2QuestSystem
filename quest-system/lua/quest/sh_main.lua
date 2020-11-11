TTTQuests = {}
TTTQuests.Quests = {}

// Reward type enum
TTTQuests.RewardType = {}
TTTQuests.RewardType.StandardPoints = 0
TTTQuests.RewardType.PremiumPoints 	= 1
TTTQuests.RewardType.Item 			= 2
TTTQuests.RewardType.Experience 	= 3
TTTQuests.RewardType.Random 		= 4
TTTQuests.RewardType.Crate		= 5

// Define here some colors
COLOR_WHITE  = Color(255, 255, 255, 255)
COLOR_BLACK  = Color(0, 0, 0, 255)
COLOR_GREEN  = Color(0, 255, 0, 255)
COLOR_DGREEN = Color(0, 100, 0, 255)
COLOR_RED    = Color(255, 0, 0, 255)
COLOR_YELLOW = Color(200, 200, 0, 255)
COLOR_LGRAY  = Color(200, 200, 200, 255)
COLOR_BLUE   = Color(0, 0, 255, 255)
COLOR_LBLUE  = Color(0, 150, 255)
COLOR_NAVY   = Color(0, 0, 100, 255)
COLOR_PINK   = Color(255, 0, 255, 255)
COLOR_ORANGE = Color(250, 100, 0, 255)
COLOR_OLIVE  = Color(100, 100, 0, 255)

util.AddDoubleQuotes = function(str)
	return "'" .. tostring(str) .. "'"
end

table.RandomWithChance = function(tab)
	local result = {}

	for thing, percentage in pairs(tab) do
		for i = 1, percentage do
			table.insert(result, thing)
		end
	end
	return table.Random(result)
end


TTTQuests.Log = function( text, text_color, prefix, prefix_color, save )
	local realm = SERVER && "(SERVER) " || "(CLIENT) "
	text_color = !text_color && Color(0, 255, 0) || text_color;
	prefix = !prefix && "[TTTQuests] " || prefix;
	prefix_color = !prefix_color && Color(255, 0, 0) || prefix_color;

	MsgC( prefix_color, prefix, realm, text_color, text, "\n" );

	if save then
		// Create file if it does not exists
		if !file.Exists("TTTQuests_Logs.txt", "DATA") then
			file.Write("TTTQuests_Logs.txt", "")
		end

		file.Append("TTTQuests_Logs.txt", string.format("%s %s %s\n", os.date("%d/%m/%YT%H:%M:%S", os.time()), realm, text))
	end
end

TTTQuests.GetItemNameByClass = function(className)
	for _, v in pairs(Pointshop2.GetRegisteredItems()) do
		if ( v.className == className ) then
			return v.PrintName
		end
	end
	return ""
end

if ( SERVER ) then
	include("quest/sv_main.lua")
else
	include("quest/cl_main.lua")
end

TTTQuests.RegisterQuest = function(self, tab)
	if ( !tab ) then
		ErrorNoHalt("[Error] Tried to load an incorrect module!\n")
		return
	end

	local quest = table.Copy(tab)
	if ( !quest.Class ) then
		ErrorNoHalt("[Error] Tried to load a module without a class name!\n")
		return
	end

	quest.Name = quest.Name || "Unnamed"
	quest.Description = quest.Description || ""
	quest.TargetValue = quest.TargetValue || 2
	quest.RewardType = quest.RewardType || TTTQuests.RewardType.StandardPoints
	quest.Reward = quest.Reward || 10
	quest.Chance = quest.Chance || 100

	if ( self.Quests[quest.Class] ) then
		ErrorNoHalt(string.format("[Error] Quest with class name \"%s\" already exists!\n", quest.Class))
		return
	end

	if ( !quest.DBParameters && SERVER ) then 
		ErrorNoHalt(string.format("[Error] Quest %s does not have database parameters. Useless?\n", quest.Class))
		return
	end
	
	self.Quests[quest.Class] = quest

	if SERVER then
		sql.MySQLQuery("CREATE TABLE IF NOT EXISTS TTTQuests_%s(%s)", quest.Class, sql.TableToParamString(quest.DBParameters))
	end

	self.Log(string.format("Quest \"%s\" is loaded!", quest.Name), COLOR_LBLUE)
end

TTTQuests.Main = function(self)
	
	// Include our quests
	for k, f in pairs( file.Find("quest/modules/*.lua", "LUA") ) do
		if SERVER then
			AddCSLuaFile("quest/modules/" .. f)
		end
		include("quest/modules/" .. f)
	end

	if ( SERVER ) then
		sql.MySQLQuery("CREATE TABLE IF NOT EXISTS TTTQuests(SteamID TEXT, QuestsDeadline TEXT, ActiveQuests TEXT, CompleteQuests TEXT)")

		// Now let's try  to init hooks on the server realm
		for class, quest in pairs(self.Quests) do
			for hookName, func in pairs(quest.Hooks) do
				// We need to log every error in quests
				local errorHandler = function(...)
					local args = {...}
					local success, err = pcall(func, unpack(args))
					if err then
						self.Log(err, nil, nil, nil, true)
					end
				end
				hook.Add(hookName, class .. hookName, errorHandler)
			end
		end
		// This hook will initialize data for each player, when it will connected to a server
		hook.Add("PlayerInitialSpawn", "TTTQuestsSetUpTable", function(ply, transition)
			// Safety first!
			if ( IsValid(ply) && !ply:IsBot() ) then
				local row = sql.MySQLQuery("SELECT * FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())
				// If players is new, we'll select quests and store it into database
				if !row then
					local quests, timestamp = self:SelectRandomQuests()
					sql.MySQLQuery("INSERT INTO TTTQuests(SteamID, QuestsDeadline, ActiveQuests, CompleteQuests) VALUES('%s', %s, '%s', '%s')",
						ply:SteamID(),
						util.AddDoubleQuotes(timestamp),
						util.TableToJSON(quests),
						util.TableToJSON({})
					)
				
				// If player is not new, we'll check quest deadline, and update quests if nessecery
				else
					// 																					 24 hours, 60 minutes, 60 seconds
					local deadline = ( tonumber(row[1].QuestsDeadline) || 0 ) + (self.Config.QuestsDeadline * 24 * 60 * 60)
					local currentTime = os.time()
					if ( currentTime >= deadline ) then
						local quests, timestamp = self:SelectRandomQuests()
						sql.MySQLQuery("UPDATE TTTQuests SET QuestsDeadline = %s, ActiveQuests = '%s', CompleteQuests = '%s' WHERE SteamID = '%s'",
							util.AddDoubleQuotes(timestamp),
							util.TableToJSON(quests),
							util.TableToJSON({}),
							ply:SteamID()
						)
						// Reset previuos quests progress
						for class, quest in pairs(self.Quests) do
							for param, default in pairs(quest.DBParameters) do
								local row = sql.MySQLQuery("SELECT * FROM TTTQuests_%s WHERE SteamID=\"%s\"", quest.Class, ply:SteamID())
								if row && param != "SteamID" then
									sql.MySQLQuery("UPDATE TTTQuests_%s SET %s = 0 WHERE SteamID = \"%s\"", class, param, ply:SteamID())
								end
							end
						end
					end
				end
				// Initialize data for each quests
				for class, quest in pairs(self.Quests) do
					for param, default in pairs(quest.DBParameters) do
						local row = sql.MySQLQuery("SELECT * FROM TTTQuests_%s WHERE SteamID=\"%s\"", quest.Class, ply:SteamID())
						if ( !row ) then
							sql.MySQLQuery("INSERT INTO TTTQuests_%s(%s) VALUES(%s)", quest.Class, param,
								// Yeah. It's difficult to read
								// If "default"'s type is string then return string,
								// which is ply's steamid if param is SteamID else "default", if "default" is not string then return just "default"
								// Understand?
								isstring(default) && util.AddDoubleQuotes( ( param == "SteamID" && ply:SteamID() || default ) ) || default )
						end
					end
				end
			end
		end)
	end
end
TTTQuests:Main()