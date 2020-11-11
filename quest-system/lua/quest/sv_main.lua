include("quest/sv_config.lua")
include("quest/sv_mysql.lua")

util.AddNetworkString("GetPlayerQuests")
util.AddNetworkString("GetQuestsData")

// Receiver function
// It sends active quests and deadline to a player which request it
TTTQuests.SendPlayerQuests = function(len, ply)
	if IsValid(ply) then
		local row = sql.MySQLQuery("SELECT * FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())

		if row then
			net.Start("GetPlayerQuests")
			net.WriteString(row[1].ActiveQuests)
			net.WriteString(row[1].CompleteQuests)
			net.WriteUInt( tonumber(row[1].QuestsDeadline) + TTTQuests.Config.QuestsDeadline * 24 * 60 * 60, 32)
			net.Send(ply)
		end
	end
end
net.Receive("GetPlayerQuests", TTTQuests.SendPlayerQuests)

// Receiver function
// It sends current quests progress to a player which request it
TTTQuests.SendPlayerQuestsData = function(len, ply)
	if !IsValid(ply) then return end
	
	local data = {}

	for class, quest in pairs(TTTQuests.Quests) do
		local row = sql.MySQLQuery("SELECT * FROM TTTQuests_%s WHERE SteamID = \"%s\"", class, ply:SteamID())

		if row then
			row[1].SteamID = nil
			data[class] = table.ClearKeys(row[1])[1]
		end
	end
	local row2 = sql.MySQLQuery("SELECT CompleteQuests FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())
	if row2 then
		complete = row2[1].CompleteQuests
	end
	net.Start("GetQuestsData")
	net.WriteString(util.TableToJSON(data))
	net.WriteString(complete)
	net.Send(ply)
end
net.Receive("GetQuestsData", TTTQuests.SendPlayerQuestsData)

// Checks, has chosen player active quest or not
TTTQuests.HasPlayerQuest = function(ply, quest)
	// We don't need invalid player
	if IsValid(ply) then
		// Get JSON with active quests
		local row = sql.MySQLQuery("SELECT ActiveQuests FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())
		if row then
			// Convert JSON to table
			local activeQuests = util.JSONToTable(row[1].ActiveQuests)
			return table.HasValue(activeQuests, quest)
		end
	end
	return false
end
TTTQuests.RewardPlayer = function(ply, questName, rewardType, reward)
	if ( rewardType == TTTQuests.RewardType.StandardPoints ) then
		ply:PS2_AddStandardPoints( reward )
		
		// Print nice message
		Pointshop2Controller:getInstance( ):addToPointFeed( ply, string.format("%s complete", questName), reward )
	elseif ( rewardType == TTTQuests.RewardType.PremiumPoints ) then
		ply:PS2_AddPremiumPoints( reward )
		ply:ChatPrint("Du hast eine Mission abgeschlossen und " ..reward.. " Donator Punkte erhalten.")
		// Print nice message
		Pointshop2Controller:getInstance( ):addToPointFeed( ply, string.format("%s complete", questName), reward )
	elseif ( rewardType == TTTQuests.RewardType.Item ) then
		ply:PS2_EasyAddItem( reward )
		ply:ChatPrint("Du hast eine Mission abgeschlossen und " ..reward.. " erhalten.")
	elseif ( rewardType == TTTQuests.RewardType.Experience ) then
		gLevel.giveExp(ply, reward)
		ply:ChatPrint("Du hast eine Mission abgeschlossen und " ..reward.. " EXP erhalten.")
		elseif ( rewardType == TTTQuests.RewardType.Crate ) then
		GiveItemByPrintName(ply, reward)
		ply:ChatPrint("Du hast eine Mission abgeschlossen und eine " ..reward.. " erhalten.")
	elseif ( rewardType == TTTQuests.RewardType.Random ) then
		local rand = table.Random(reward)
		TTTQuests.RewardPlayer(ply, questName, rand.rewardType, rand.reward)
	end
end
// Hook function.
// It will be called everytime when a player finish a quest
TTTQuests.OnQuestComplete = function(ply, class)
	// We don't need invalid player
	if !IsValid(ply) then return end

	// Select quest class
	local Quest = TTTQuests.Quests[class]

	// Class might be invalid, so...
	if Quest then
		// Get JSON with complete quests
		local row = sql.MySQLQuery("SELECT CompleteQuests FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())

		local CompleteQuests = {}
		if row then
			// Convert JSON to table
			CompleteQuests = util.JSONToTable(row[1].CompleteQuests)
		end
		// Insert finished quest into the table
		table.insert(CompleteQuests, class)

		// Refresh data
		sql.MySQLQuery("UPDATE TTTQuests SET CompleteQuests = '%s' WHERE SteamID = \"%s\"",
				util.TableToJSON(CompleteQuests),
				ply:SteamID()
			)

		// Reward the player
		TTTQuests.RewardPlayer(ply, Quest.Name, Quest.RewardType, Quest.Reward)
	end
end
hook.Add("TTTQuests_QuestComplete", "__hook__", TTTQuests.OnQuestComplete)

TTTQuests.IsQuestComplete = function(ply, quest)
	// We don't need invalid player
	if IsValid(ply) then
		// Get JSON with complete quests
		local row = sql.MySQLQuery("SELECT CompleteQuests FROM TTTQuests WHERE SteamID = \"%s\"", ply:SteamID())
		if row then
			// Convert JSON to table
			local completeQuests = util.JSONToTable(row[1].CompleteQuests)
			return table.HasValue(completeQuests, quest)
		end
	end
	return false
end
TTTQuests.IsRDM = function(victim, attacker, dmginfo)
	if IsValid(victim) && IsValid(attacker) then
		return ( victim:IsTraitor() && attacker:IsTraitor() ) || ( !attacker:IsTraitor() && !victim:IsTraitor() )
	end
end
// Just makes table with random quests
// and returns it with creation time
TTTQuests.SelectRandomQuests = function(self)
	local result = {}
	// Just take a minimal quests count
	local questsCount = math.min(self.Config.MaxQuests, table.Count(self.Quests))
	local quests = {}
	for class, quest in pairs(TTTQuests.Quests) do
		quests[class] = quest.Chance
	end
	for i=1, questsCount do
		local rand
		repeat
			rand = table.RandomWithChance(quests)
		until !table.HasValue(result, rand) // This is dangerous, I hope this will not drag server in an infinite loop
		table.insert(result, rand)
	end
	return result, os.time()
end
TTTQuests.Log("Main module loaded!", COLOR_GREEN)

function GiveItemByPrintName( ply, printName )
        local itemClass = Pointshop2.GetItemClassByPrintName( printName )
        if not itemClass then
                error( "Invalid item " .. tostring( printName ) )
        end
        return ply:PS2_EasyAddItem( itemClass.className )
end