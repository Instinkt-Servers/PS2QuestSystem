local MODULE = {}

MODULE.Class = "Fall"
MODULE.Name = "Wo sind meine Flügel!?"
MODULE.Description = "Stirb %d mal an Fallschaden"
MODULE.TargetValue = 10 // This is corpses count to be found to finish the quest
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
	MODULE.DBParameters["DiedByFall"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["DoPlayerDeath"] = function(victim, attacker, dmginfo)
		if ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

			// Player must be valid and not a bot
			if IsValid(victim) && victim:IsPlayer() && !victim:IsBot() then
				// Check quest status
				if TTTQuests.HasPlayerQuest(victim, "Fall") && !TTTQuests.IsQuestComplete(victim, "Fall") then

					// Check damage type
					if dmginfo:IsFallDamage() then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT DiedByFall FROM TTTQuests_Fall WHERE SteamID = \"%s\"", victim:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local currentKills = row[1].DiedByFall

							// Check our condition
							if ( currentKills + 1 >= TTTQuests.Quests["Fall"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", victim, "Fall")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_Fall SET DiedByFall=%d WHERE SteamID = \"%s\"", currentKills + 1, victim:SteamID() )
						end
					end
				end
			end
		end
	end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)