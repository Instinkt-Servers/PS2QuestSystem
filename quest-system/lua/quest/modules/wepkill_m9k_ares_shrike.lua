local MODULE = {}

MODULE.Class = "Wepkill_m9k_ares_shrike"
MODULE.Name = "Ares Shrike LMG Master"
MODULE.Description = "Töte %d Spieler mit der Ares Shrike"
MODULE.TargetValue = 50 // This is killed traitors count to finish the quest
MODULE.RewardType = TTTQuests.RewardType.Experience // For random just define MODULE.Reward like this: {{type = 0, reward = 5000}, {type = 2, reward = "%item_class%"}}
MODULE.Reward = 100 // Just define it here. It'll be easily edited later
MODULE.Chance = 10 // Lower the chance, because we'll use 4 almost similar quests. 100 (default chance) / 4 (items)
// That is useless for client. We shall be economical with RAM
if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["KilledWithAresShrike"] = 0
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
				if TTTQuests.HasPlayerQuest(attacker, "Wepkill_m9k_ares_shrike") && !TTTQuests.IsQuestComplete(attacker, "Wepkill_m9k_ares_shrike") then
					// Get attacker current weapon
					local weapon = dmginfo:GetAttacker():GetActiveWeapon()
					// Check weapon class
--					if weapon:GetClass() == string.StartWith(weapon:GetClass(), "m9k_awp_") then
					if weapon:GetClass() == "m9k_ares_shrike" && !TTTQuests.IsRDM(victim, attacker) then
						// Select a row from table
						local row = sql.MySQLQuery("SELECT KilledWithAresShrike FROM TTTQuests_Wepkill_m9k_ares_shrike WHERE SteamID = \"%s\"", attacker:SteamID() )
						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local currentKills = row[1].KilledWithAresShrike

							// Check our condition
							if ( currentKills + 1 >= TTTQuests.Quests["Wepkill_m9k_ares_shrike"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", attacker, "Wepkill_m9k_ares_shrike")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_Wepkill_m9k_ares_shrike SET KilledWithAresShrike=%d WHERE SteamID = \"%s\"", currentKills + 1, attacker:SteamID() )
						end
					end
				end
			end
		end
	end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)