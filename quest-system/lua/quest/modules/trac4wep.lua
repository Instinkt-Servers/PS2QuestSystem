local MODULE = {}

MODULE.Class = "TraWepC4"
MODULE.Name = "Boom sie alle weg!"
MODULE.Description = [[
Gehe in den Traitorshop
und kaufe das
C4 %d mal
]]
MODULE.Chance = 25 // Lower the chance, because we'll use 4 almost similar quests. 100 (default chance) / 4 (items)
MODULE.TargetValue = 25

MODULE.RewardType = TTTQuests.RewardType.StandardPoints
MODULE.Reward = 25000

if ( SERVER ) then
	// This is database parameters
	// It needs to create table in database
	// Key is name of parameter
	// Value is default value and type of parameter  
	MODULE.DBParameters = {}
	MODULE.DBParameters["SteamID"] = "\"\"" // Must have
	MODULE.DBParameters["C4Bought"] = 0

	// Hooks functions are called on a specific event
	// We shall use them to calculate quest condition
	// and give a reward to a player who fulfilled the condition
	MODULE.Hooks = {}
	MODULE.Hooks["TTTOrderedEquipment"] = function(ply, equip, is_item)
		if ( #player.GetAll() >= TTTQuests.Config.MinPlayers ) then

		// Player must be valid
		if IsValid(ply) then

			// Check quest status
			if TTTQuests.HasPlayerQuest(ply, "TraWepC4") && !TTTQuests.IsQuestComplete(ply, "TraWepC4") then

				// A player must be detective
				if ply:IsTraitor() then
					
					// Check equipment type
					if ( equip == "weapon_ttt_c4" ) then

						// Select a row from table
						local row = sql.MySQLQuery("SELECT C4Bought FROM TTTQuests_TraWepC4 WHERE SteamID = \"%s\"", ply:SteamID() )

						if row then // Just make sure the row isn't nil
							
							// Get current progress from the row
							local current = row[1].C4Bought

							// Check our condition
							if ( current + 1 >= TTTQuests.Quests["TraWepC4"].TargetValue ) then

								// Call the hook
								hook.Run("TTTQuests_QuestComplete", ply, "TraWepC4")
							end

							// Write to new progress to a database
							sql.MySQLQuery("UPDATE TTTQuests_TraWepC4 SET C4Bought=%d WHERE SteamID = \"%s\"", current + 1, ply:SteamID() )
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