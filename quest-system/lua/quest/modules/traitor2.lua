local MODULE = {}

MODULE.Class = "Traitor2"
MODULE.Name = "Traitorschlacht"
MODULE.Description = "Töte %d Innocents als Traitor"
MODULE.TargetValue = 50 // This is killed innocent count to finish the quest
MODULE.RewardType = TTTQuests.RewardType.Experience // For random just define MODULE.Reward like this: {{type = 0, reward = 5000}, {type = 2, reward = "%item_class%"}}
MODULE.Reward = 50 // Just define it here. It'll be easily edited later
MODULE.Chance = 33 // Lower the chance, because we'll use 4 almost similar quests. 100 (default chance) / 4 (items)

// That is useless for client. We shall be economical with RAM
if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["KilledByTraitor2"] = 0

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
				if TTTQuests.HasPlayerQuest(attacker, "Traitor2") && !TTTQuests.IsQuestComplete(attacker, "Traitor2") then

					// An attacker must be a traitor and a victim must be an innocent
					if attacker:IsTraitor() && !victim:IsTraitor() then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT KilledByTraitor2 FROM TTTQuests_Traitor2 WHERE SteamID = \"%s\"", attacker:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local currentKills = row[1].KilledByTraitor2

							// Check our condition
							if ( currentKills + 1 >= TTTQuests.Quests["Traitor2"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", attacker, "Traitor2")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_Traitor2 SET KilledByTraitor2=%d WHERE SteamID = \"%s\"", currentKills + 1, attacker:SteamID() )
						end
					end
				end
			end
		end
	end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)