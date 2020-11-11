local MODULE = {}

MODULE.Class = "Corpse"
MODULE.Name = "Frische Luft Schnappen"
MODULE.Description = "Identifiziere %d Leichen"
MODULE.TargetValue = 100 // This is corpses count to be found to finish the quest
MODULE.RewardType = TTTQuests.RewardType.Experience // For random just define MODULE.Reward like this: {{type = 0, reward = 5000}, {type = 2, reward = "%item_class%"}}
MODULE.Reward = 50 // Just define it here. It'll be easily edited later

// That is useless for client. We shall be economical with RAM
if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["CorpsesFound"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["TTTCanIdentifyCorpse"] = function(ply, corpse, was_traitor)

		// Players on a server must be greater or equal what is specified
		if  ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

			// A player must be valid and not a bot
			if IsValid(ply) && ply:IsPlayer() then

				// Check quest status
				if ( TTTQuests.HasPlayerQuest(ply, "Corpse") && !TTTQuests.IsQuestComplete(ply, "Corpse") ) then

					// A corpse must be not identified
					if !CORPSE.GetFound(corpse) then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT CorpsesFound FROM TTTQuests_Corpse WHERE SteamID = \"%s\"", ply:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local currentCorpses = row[1].CorpsesFound

							// Check our condition
							if ( currentCorpses + 1 >= TTTQuests.Quests["Corpse"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", ply, "Corpse")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_Corpse SET CorpsesFound=%d WHERE SteamID = \"%s\"", currentCorpses + 1, ply:SteamID() )
						end
					end
				end
			end
		end
	end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)