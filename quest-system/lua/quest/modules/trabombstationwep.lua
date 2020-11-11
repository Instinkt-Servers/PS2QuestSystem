local MODULE = {}

MODULE.Class = "TraWepBombstation"
MODULE.Name = "Antihealer!"
MODULE.Description = [[
Gehe in den Traitorshop
und kaufe die
Bombstation %d mal
]]
MODULE.Chance = 25 // Lower the chance, because we'll use 4 almost similar quests. 100 (default chance) / 4 (items)
MODULE.TargetValue = 20

MODULE.RewardType = TTTQuests.RewardType.Experience // For random just define MODULE.Reward like this: {{type = 0, reward = 5000}, {type = 2, reward = "%item_class%"}}
MODULE.Reward = 35 // Just define it here. It'll be easily edited later

if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["BombstationBought"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["TTTOrderedEquipment"] = function(ply, equip, is_item)
	
		if ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

		// Player must be valid
		if IsValid(ply) then

			// Check quest status
			if TTTQuests.HasPlayerQuest(ply, "TraWepBombstation") && !TTTQuests.IsQuestComplete(ply, "TraWepBombstation") then

				// A player must be detective
				if ply:IsTraitor() then
					
					// Check equipment type
					if ( equip == "weapon_ttt_bomb_station" ) then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT BombstationBought FROM TTTQuests_TraWepBombstation WHERE SteamID = \"%s\"", ply:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local current = row[1].BombstationBought

							// Check our condition
							if ( current + 1 >= TTTQuests.Quests["TraWepBombstation"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", ply, "TraWepBombstation")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_TraWepBombstation SET BombstationBought=%d WHERE SteamID = \"%s\"", current + 1, ply:SteamID() )
						end
					end
				end
			end
		end
	end
end
end

// Register our quest module
TTTQuests:RegisterQuest(MODULE)