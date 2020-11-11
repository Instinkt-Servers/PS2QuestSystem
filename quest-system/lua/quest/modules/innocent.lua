local MODULE = {}

MODULE.Class = "Innocent"
MODULE.Name = "Sag Nein zu Traitorn"
MODULE.Description = "Töte %d Traitor"
MODULE.TargetValue = 25 // This is killed traitors count to finish the quest
MODULE.RewardType = TTTQuests.RewardType.Crate // For random just define MODULE.Reward like this: {{type = 0, reward = 5000}, {type = 2, reward = "%item_class%"}}
MODULE.Reward = "Treasure Chest" // Just define it here. It'll be easily edited later

// That is useless for client. We shall be economical with RAM
if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["KilledTraitors"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["DoPlayerDeath"] = function(victim, attacker, dmginfo)
		if ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

			// Players must be valid and not bots
			if IsValid(victim)
				&& IsValid(attacker)
				&& attacker:IsPlayer()
				&& victim:IsPlayer()
				&& !attacker:IsBot()
				&& !victim:IsBot()
				&& attacker != victim then

				// Check quest status
				if TTTQuests.HasPlayerQuest(attacker, "Innocent") && !TTTQuests.IsQuestComplete(attacker, "Innocent") then

					// An attacker must be an innocent and a victim must be a traitor
					if !attacker:IsTraitor() && victim:IsTraitor() then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT KilledTraitors FROM TTTQuests_Innocent WHERE SteamID = \"%s\"", attacker:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local currentKills = row[1].KilledTraitors

							// Check our condition
							if ( currentKills + 1 >= TTTQuests.Quests["Innocent"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", attacker, "Innocent")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_Innocent SET KilledTraitors=%d WHERE SteamID = \"%s\"", currentKills + 1, attacker:SteamID() )
						end
					end
				end
			end
		end
	end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)